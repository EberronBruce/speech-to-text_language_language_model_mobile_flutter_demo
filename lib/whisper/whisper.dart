import 'whisper_flutter_bridge.dart';

class Whisper {
  Future<String> loadModelOnStartup() async {
    WhisperFlutterBridge.callRequestRecordPermission();
    // Assume you have a function to get the model path (like from assets)
    final modelPath = await getModelFilePath();

    try {
      final success = await WhisperFlutterBridge.initializeModel(modelPath);
      if (success) {
        return "Model initialized successfully";
      } else {
        return "Failed to initialize model";
      }
    } catch (e) {
      return "Error initializing model: $e";
    }
  }

  // void listenToEvents(Function(String) onEvent) {
  //   WhisperFlutterBridge.events.listen((event) {
  //     final type = event['event'];
  //     switch (type) {
  //       case 'didTranscribe':
  //         final text = event['text'] ?? '';
  //         onEvent(text);
  //         break;
  //
  //       case 'recordingFailed':
  //         final error = event['error'] ?? 'Unknown';
  //         onEvent("❌ Recording failed: $error");
  //         break;
  //
  //       case 'failedToTranscribe':
  //         final error = event['error'] ?? 'Unknown';
  //         onEvent("❌ Transcription failed: $error");
  //         break;
  //
  //       case 'didStartRecording':
  //         final recording = event['isRecording'] ?? 'Unknown';
  //         onEvent(recording);
  //         break;
  //
  //       case 'didStopRecording':
  //         final recording = event['isRecording'] ?? 'Unknown';
  //         onEvent(recording);
  //         break;
  //
  //       default:
  //         onEvent("📢 Unknown event: $event");
  //     }
  //   });
  // }

  void listenToEvents({
    void Function(String text)? onTranscribe,
    void Function(String error)? onRecordingFailed,
    void Function(String error)? onTranscriptionFailed,
    void Function()? onStartRecording,
    void Function()? onStopRecording,
    void Function()? permissionRequestNeeded,

    void Function(dynamic raw)? onUnknown,
  }) {
    WhisperFlutterBridge.events.listen((event) {
      final type = event['event'];

      switch (type) {
        case 'didTranscribe':
          final text = event['text'] ?? '';
          onTranscribe?.call(text);
          break;

        case 'recordingFailed':
          final error = event['error'] ?? 'Unknown';
          onRecordingFailed?.call(error);
          break;

        case 'failedToTranscribe':
          final error = event['error'] ?? 'Unknown';
          onTranscriptionFailed?.call(error);
          break;

        case 'didStartRecording':
          onStartRecording?.call();
          break;

        case 'didStopRecording':
          onStopRecording?.call();
          break;

        case 'permissionRequestNeeded':
          permissionRequestNeeded?.call();
          break;

        default:
          onUnknown?.call(event);
      }
    });
  }

  Future<bool> playSampleAudio() async {
    if (!await WhisperFlutterBridge.canTranscribe()) return false;
    WhisperFlutterBridge.enablePlayback(true);
    final samplePath = await getSampleAudioPath();
    await WhisperFlutterBridge.transcribeSample(samplePath);
    return true;
  }

  Future<void> toggleRecording() async {
    // if (!await WhisperFlutterBridge.canTranscribe()) {
    //   return;
    // }
    WhisperFlutterBridge.enablePlayback(false);
    await WhisperFlutterBridge.toggleRecording();
  }
}
