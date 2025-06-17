import 'package:flutter/material.dart';

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
  final List<String> messages = [];
  final ScrollController scrollController =
      ScrollController(); // For auto scrolling

  void addMessage() {
    setState(() {
      messages.add('You hit me');
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

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Define the FAB here so we can potentially get its size if needed,
    // or just for cleaner code.
    final Widget floatingActionButton = Transform.scale(
      scale: 1.5,
      child: FloatingActionButton(
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        onPressed: addMessage,
        tooltip: 'Get Message',
        child: const Icon(Icons.record_voice_over),
      ),
    );

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Column(
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
                border: Border.all(color: Colors.grey.shade400), // Add a border
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
        ],
      ),
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
