import 'package:flutter/material.dart';
import 'package:stt_llm_demo/whisper/whisper.dart';

import 'message_bubble.dart';

enum Sender {
  system("System"),
  whisper("Whisper");

  final String label;
  const Sender(this.label);
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key, required this.title});
  final String title;

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  bool _isLoadingModel = true;
  bool _isLoading = false;
  final List<MessageBubble> _messages = [];
  //final List<String> messages = [];
  final ScrollController scrollController =
      ScrollController(); // For auto scrolling

  final Whisper _whisper = Whisper();

  bool _isRecording = false;

  @override
  void initState() {
    super.initState();
    // if (Platform.isIOS) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initWhisper();
    });
    // } else {
    //   addMessage(
    //     message: "This app only works on iOS for now",
    //     sender: Sender.system.label,
    //     isAI: false,
    //   );
    // }
  }

  Future<void> _initWhisper() async {
    String loadedMessage = await _whisper.loadModelOnStartup();
    addMessage(
      message: loadedMessage,
      sender: Sender.system.label,
      isAI: false,
    );
    // _whisper.listenToEvents((message) {
    //   addMessage(message: message, sender: Sender.whisper.label, isAI: true);
    // });
    _whisper.listenToEvents(
      onTranscribe: (text) {
        _isLoading = false;
        addMessage(message: text, sender: Sender.whisper.label, isAI: true);
      },
      onTranscriptionFailed: (error) {
        addMessage(
          message: "[Error] $error",
          sender: Sender.system.label,
          isAI: false,
        );
      },
      onRecordingFailed: (error) {
        addMessage(
          message: "[Error] $error",
          sender: Sender.system.label,
          isAI: false,
        );
      },
      onStartRecording: () {
        setState(() {
          _isRecording = true;
        });
      },
      onStopRecording: () {
        setState(() {
          _isRecording = false;
          _isLoading = true;
        });
      },
      permissionRequestNeeded: () {
        addMessage(
          message: "Microphone access denied",
          sender: Sender.system.label,
          isAI: false,
        );
      },
      onUnknown: (event) {
        addMessage(
          message: "[Unknown event] $event",
          sender: Sender.system.label,
          isAI: false,
        );
      },
    );

    setState(() {
      _isLoadingModel = false;
    });
  }

  void addMessage({
    required String message,
    required String sender,
    bool isAI = false,
  }) {
    setState(() {
      _messages.add(MessageBubble(text: message, sender: sender, isAI: isAI));
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
    await _whisper.toggleRecording();
  }

  _transcribeSampleAudio() async {
    bool result = await _whisper.playSampleAudio();
    if (result != true) {
      addMessage(
        message: "Unable to transcribe sample audio right now",
        sender: Sender.system.label,
        isAI: false,
      );
    }
  }

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingModel) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          title: Text(widget.title),
        ),
        body: Center(
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
      body: Stack(
        children: [
          SafeArea(
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
                    child: ListView.builder(
                      controller:
                          scrollController, // Assign the scroll controller
                      itemCount:
                          _messages.length, // Number of items in our list
                      itemBuilder: (context, index) {
                        // Display each message from the list
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 4.0,
                          ), // Some spacing
                          child: _messages[index],
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
                      onPressed: _isLoading ? null : _transcribeSampleAudio,
                      icon: Icon(Icons.audiotrack),
                      label: SizedBox(
                        width: 100.0,
                        child: Center(
                          child: Text(
                            "Sample",
                            style: TextStyle(fontSize: 20.0),
                          ),
                        ),
                      ),
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
                      onPressed: _isLoading ? null : _toggleRecording,
                      icon: Icon(_isRecording ? Icons.stop : Icons.mic),
                      label: SizedBox(
                        width: 100.0,
                        child: Center(
                          child: Text(
                            _isRecording ? "Stop" : "Record",
                            style: TextStyle(fontSize: 20.0),
                          ),
                        ),
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
          // Spinner overlay
          if (_isLoading)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Transcribing.."),
                    CircularProgressIndicator(),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
