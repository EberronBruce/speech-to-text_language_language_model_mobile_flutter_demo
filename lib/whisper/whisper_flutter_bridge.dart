import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

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
    if (Platform.isAndroid) {
      if (await isMicrophonePermissionGranted() == false) {
        await checkMicrophonePermission();
        await isMicrophonePermissionGranted();
      }
    } else {
      await _methodChannel.invokeMethod('callRequestRecordPermission');
    }
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
    print('toggleRecording called');
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

  static Future<bool> isMicrophonePermissionGranted() async {
    final result = await _methodChannel.invokeMethod<bool>(
      'isMicrophonePermissionGranted',
    );
    return result ?? false;
  }
}

Future<String> getModelFilePath() async {
  return await copyAssetToDocuments(
    assetPath: 'assets/models/whisper/ggml-base.en.bin',
    outputFileName: 'ggml-base.en.bin',
  );
}

Future<String> getSampleAudioPath() async {
  return await copyAssetToDocuments(
    assetPath: 'assets/models/whisper/jfk.wav',
    outputFileName: 'jfk.wav',
  );
}

Future<String> copyAssetToDocuments({
  required String assetPath,
  required String outputFileName,
}) async {
  try {
    final outputPath =
        '${(await getApplicationDocumentsDirectory()).path}/$outputFileName';
    final outFile = File(outputPath);

    if (await outFile.exists()) {
      return outputPath;
    }

    final byteData = await rootBundle.load(assetPath);
    final buffer = byteData.buffer;

    await outFile.writeAsBytes(
      buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes),
      flush: true,
    );

    return outputPath;
  } catch (e) {
    if (kDebugMode) {
      print('Error copying $outputFileName: $e');
    }
    rethrow;
  }
}

Future<void> checkMicrophonePermission() async {
  var status = await Permission.microphone.status;

  if (status.isGranted) {
    print('Microphone permission granted.');
  } else if (status.isPermanentlyDenied) {
    print('Microphone permission permanently denied. Open app settings.');
    // You can prompt the user to open app settings
    await openAppSettings();
  } else if (status.isDenied) {
    print('Microphone permission denied. Requesting now...');
    var newStatus = await Permission.microphone.request();
    if (newStatus.isGranted) {
      print('Microphone permission granted after request.');
    } else {
      print('Microphone permission still denied.');
    }
  }
}
