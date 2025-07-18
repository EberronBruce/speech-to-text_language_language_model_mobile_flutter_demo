import 'dart:async';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class WhisperFlutterBridge {
  // Method channel name — you will need to set this up on iOS native side
  static const MethodChannel _methodChannel = MethodChannel(
    'whisper_method_channel',
  );

  // Event channel name matches your Swift event channel
  static const EventChannel _eventChannel = EventChannel('whisper_events');

  static Stream<Map<String, dynamic>>? _eventsStream;

  /// Requests microphone permission
  static Future<void> callRequestRecordPermission() async {
    await _methodChannel.invokeMethod('callRequestRecordPermission');
  }

  /// Initializes the model at given path, returns true if success
  static Future<bool> initializeModel(String path) async {
    final result = await _methodChannel.invokeMethod<bool>('initializeModel', {
      'path': path,
    });
    return result ?? false;
  }

  /// Starts audio recording
  static Future<void> startRecording() async {
    await _methodChannel.invokeMethod('startRecording');
  }

  /// Stops audio recording
  static Future<void> stopRecording() async {
    await _methodChannel.invokeMethod('stopRecording');
  }

  /// Toggles recording state
  static Future<void> toggleRecording() async {
    await _methodChannel.invokeMethod('toggleRecording');
  }

  /// Transcribes a sample audio file from path
  static Future<void> transcribeSample(String path) async {
    await _methodChannel.invokeMethod('transcribeSample', {'path': path});
  }

  /// Enables or disables playback
  static Future<void> enablePlayback(bool enabled) async {
    await _methodChannel.invokeMethod('enablePlayback', {'enabled': enabled});
  }

  /// Resets the whisper engine state
  static Future<void> reset() async {
    await _methodChannel.invokeMethod('reset');
  }

  /// Checks if transcription is possible
  static Future<bool> canTranscribe() async {
    final result = await _methodChannel.invokeMethod<bool>('canTranscribe');
    return result ?? false;
  }

  /// Checks if recording is in progress
  static Future<bool> isRecording() async {
    final result = await _methodChannel.invokeMethod<bool>('isRecording');
    return result ?? false;
  }

  /// Checks if the model is loaded
  static Future<bool> isModelLoaded() async {
    final result = await _methodChannel.invokeMethod<bool>('isModelLoaded');
    return result ?? false;
  }

  /// Gets message logs as a string
  static Future<String?> getMessageLogs() async {
    final result = await _methodChannel.invokeMethod<String>('getMessageLogs');
    return result;
  }

  /// Stream of events from native side like 'didTranscribe', 'recordingFailed', etc.
  static Stream<Map<String, dynamic>> get events {
    _eventsStream ??= _eventChannel.receiveBroadcastStream().map(
      (event) => Map<String, dynamic>.from(event),
    );
    return _eventsStream!;
  }
}

Future<String> getModelFilePath() async {
  try {
    const assetPath = 'assets/models/whisper/ggml-base.en.bin';
    print('Copying model from assets to $assetPath');
    final outputPath =
        '${(await getApplicationDocumentsDirectory()).path}/ggml-base.en.bin';
    print('Output path: $outputPath');
    final outFile = File(outputPath);
    print('Output file: $outFile');

    if (await outFile.exists()) {
      print('Model already exists at $outputPath');
      return outputPath;
    }

    print('Copying model from assets to $outputPath');

    final byteData = await rootBundle.load(
      assetPath,
    ); // <-- Only this part loads to memory
    print('Model loaded from assets: $byteData');
    final buffer = byteData.buffer;
    print('Model buffer created: $buffer');
    await outFile.writeAsBytes(
      buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes),
      flush: true,
    );

    print('Model copied to $outputPath');
    print('Model copied successfully');
    return outputPath;
  } catch (e) {
    print('Error copying model: $e');
    rethrow;
  }
}

Future<String> getSampleAudioPath() async {
  try {
    const assetPath = 'assets/models/whisper/jfk.wav';
    final outputPath =
        '${(await getApplicationDocumentsDirectory()).path}/jfk.wav';
    final outFile = File(outputPath);

    if (await outFile.exists()) {
      print('Sample audio already exists at $outputPath');
      return outputPath;
    }

    print('Copying sample audio to $outputPath');

    final byteData = await rootBundle.load(assetPath);
    final buffer = byteData.buffer;

    await outFile.writeAsBytes(
      buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes),
      flush: true,
    );

    print('Sample audio copied successfully');
    return outputPath;
  } catch (e) {
    print('Error copying sample audio: $e');
    rethrow;
  }
}
