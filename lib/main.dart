import 'package:flutter/material.dart';
import 'package:stt_llm_demo/whisper/whisper.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'STT -> LLM Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueGrey),
      ),
      home: const MyHomePage(title: 'STT -> LLM Demo'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  bool _isLoading = true;
  final List<String> messages = [];
  final ScrollController scrollController =
      ScrollController(); // For auto scrolling

  final Whisper _whisper = Whisper();

  bool _isRecording = false;

  @override
  void initState() {
    super.initState();
    _initWhisper();
  }

  Future<void> _initWhisper() async {
    String loadedMessage = await _whisper.loadModelOnStartup();
    addMessage(loadedMessage);
    _whisper.listenToEvents((message) {
      addMessage(message);
    });
    setState(() {
      _isLoading = false;
    });
  }

  void addMessage(String message) {
    setState(() {
      messages.add(message);
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scrollController.hasClients &&
          scrollController.position.maxScrollExtent > 0) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(microseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  _toggleRecording() async {
    print("_toggleRecording() called");
    final result = await _whisper.toggleRecording();
    setState(() {
      _isRecording = result.isRecording;
    });
  }

  _transcribeSampleAudio() async {
    print("_transcribeSampleAudio() called");
    String? result = await _whisper.playSampleAudio();
    if (result != null) {
      addMessage(result);
    } else {
      addMessage("Unable to transcribe sample audio right now");
    }
  }

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          title: Text(widget.title),
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("Models are Loading...", style: TextStyle(fontSize: 25.0)),
              CircularProgressIndicator(),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: SafeArea(
        child: Column(
          // Use a Column to separate the text box from other potential UI elements
          children: [
            Expanded(
              // Make the text box take available space
              child: Container(
                margin: const EdgeInsets.all(
                  16.0,
                ), // Add some margin around the box
                padding: const EdgeInsets.all(
                  8.0,
                ), // Add some padding inside the box
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.grey.shade400,
                  ), // Add a border
                  borderRadius: BorderRadius.circular(8.0), // Rounded corners
                ),
                child: ListView.builder(
                  controller: scrollController, // Assign the scroll controller
                  itemCount: messages.length, // Number of items in our list
                  itemBuilder: (context, index) {
                    // Display each message from the list
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 4.0,
                      ), // Some spacing
                      child: Text(
                        messages[index],
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    );
                  },
                ),
              ),
            ),
            // You could add other widgets here if needed, below the text box
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: _transcribeSampleAudio,
                  icon: Icon(Icons.audiotrack),
                  label: Text("Sample", style: TextStyle(fontSize: 20.0)),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(
                      horizontal: 24.0,
                      vertical: 20.0,
                    ),
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _toggleRecording,
                  icon: Icon(_isRecording ? Icons.stop : Icons.mic),
                  label: Text(
                    _isRecording ? "Stop" : "Record",
                    style: TextStyle(fontSize: 20.0),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(
                      horizontal: 24.0,
                      vertical: 20.0,
                    ),
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
