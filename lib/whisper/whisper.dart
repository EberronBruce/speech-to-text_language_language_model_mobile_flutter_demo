import 'whisper_flutter_bridge.dart';

class Whisper {
  Future<String> loadModelOnStartup() async {
    WhisperFlutterBridge.callRequestRecordPermission();
    // Assume you have a function to get the model path (like from assets)
    final modelPath = await getModelFilePath();

    try {
      final success = await WhisperFlutterBridge.initializeModel(modelPath);
      if (success) {
        print('Model initialized successfully');
        return "Model initialized successfully";
      } else {
        print('Failed to initialize model');
        return "Failed to initialize model";
      }
    } catch (e) {
      print('Error initializing model: $e');
      return "Error initializing model: $e";
    }
  }

  void listenToEvents(Function(String) onEvent) {
    WhisperFlutterBridge.events.listen((event) {
      final type = event['event'];
      switch (type) {
        case 'didTranscribe':
          final text = event['text'] ?? '';
          print("📝 Transcription: $text");
          onEvent("Transcription: $text");
          break;

        case 'recordingFailed':
          final error = event['error'] ?? 'Unknown';
          print("❌ Recording failed: $error");
          onEvent("Recording failed: $error");
          break;

        case 'failedToTranscribe':
          final error = event['error'] ?? 'Unknown';
          print("❌ Transcription failed: $error");
          onEvent("Transcription failed: $error");
          break;

        default:
          print("📢 Unknown event: $event");
          onEvent("Unknown event: $event");
      }
    });
  }

  Future<String?> playSampleAudio() async {
    if (!await WhisperFlutterBridge.canTranscribe()) return null;
    WhisperFlutterBridge.enablePlayback(true);
    final samplePath = await getSampleAudioPath();
    await WhisperFlutterBridge.transcribeSample(samplePath);
    print("Sample audio transcribed successfully");
    return "Sample audio transcribed successfully";
  }

  Future<RecordingResult> toggleRecording() async {
    if (!await WhisperFlutterBridge.canTranscribe()) {
      return RecordingResult(false, "Unable to Transcribe");
    }
    WhisperFlutterBridge.enablePlayback(false);
    await WhisperFlutterBridge.toggleRecording();
    final isRecording = await WhisperFlutterBridge.isRecording();

    return RecordingResult(isRecording);
  }
}

class RecordingResult {
  final bool isRecording;
  final String? message;

  RecordingResult(this.isRecording, [this.message]);
}
