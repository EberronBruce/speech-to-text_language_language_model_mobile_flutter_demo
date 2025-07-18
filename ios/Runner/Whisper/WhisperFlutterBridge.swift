//
//  WhisperFlutterBridge.swift
//  Runner
//
//  Created by Bruce Burgess on 7/16/25.
//

import Foundation
import Flutter
import WhisperCore

fileprivate enum WhisperMethods: String {
    case permission = "callRequestRecordPermission"
    case initialzeModel = "initializeModel"
    case startRecording = "startRecording"
    case stopRecording = "stopRecording"
    case toggleRecording = "toggleRecording"
    case transcribeSample = "transcribeSample"
    case enablePlayback = "enablePlayback"
    case reset = "reset"
    case canTranscribe = "canTranscribe"
    case isRecording = "isRecording"
    case isModelLoaded = "isModelLoaded"
    case getMessageLogs = "getMessageLogs"
}

@MainActor
class WhisperFlutterBridge: NSObject, WhisperDelegate {
    static let shared = WhisperFlutterBridge()
    
    private let whisper = Whisper()
    private var eventSink: FlutterEventSink?
    
    override init() {
        super.init()
        whisper.delegate = self
    }
    
    func handleMethodCall(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let method  = WhisperMethods(rawValue: call.method) else {
            result(FlutterMethodNotImplemented)
            return
        }
        
        switch method {
        case .permission:
              whisper.callRequestRecordPermission()
              result(nil)
              
          case .initialzeModel:
              guard let args = call.arguments as? [String: Any],
                    let path = args["path"] as? String else {
                  result(FlutterError(code: "BAD_ARGS", message: "Missing model path", details: nil))
                  return
              }

            print("Checking if model exists at path: \(path)")
            guard FileManager.default.fileExists(atPath: path) else {
                result(FlutterError(code: "FILE_NOT_FOUND", message: "Model file does not exist at path: \(path)", details: nil))
                return
            }
                
              Task {
                  do {
                      try await whisper.initializeModel(at: path)
                      result(true)
                  } catch {
                      result(FlutterError(code: "INIT_FAIL", message: error.localizedDescription, details: nil))
                  }
              }

          case .startRecording:
              Task {
                  await whisper.startRecording()
                  result(nil)
              }

          case .stopRecording:
              Task {
                  await whisper.stopRecording()
                  result(nil)
              }

          case .toggleRecording:
              Task {
                  await whisper.toggleRecording()
                  result(nil)
              }

          case .transcribeSample:
              guard let args = call.arguments as? [String: Any],
                    let path = args["path"] as? String else {
                  result(FlutterError(code: "BAD_ARGS", message: "Missing sample path", details: nil))
                  return
              }
              let url = URL(fileURLWithPath: path)
              Task {
                  await whisper.transcribeSample(from: url)
                  result(nil)
              }

          case .enablePlayback:
              guard let args = call.arguments as? [String: Any],
                    let enabled = args["enabled"] as? Bool else {
                  result(FlutterError(code: "BAD_ARGS", message: "Missing enabled flag", details: nil))
                  return
              }
              whisper.enablePlayback(enabled)
              result(nil)

          case .reset:
              whisper.reset()
              result(nil)

          case .canTranscribe:
              result(whisper.canTranscribe())

          case .isRecording:
              result(whisper.isRecording())

          case .isModelLoaded:
              result(whisper.isModelLoaded())

          case .getMessageLogs:
              result(whisper.getMessageLogs())
          }
    }
    
    // Called when transcription is complete
    nonisolated func didTranscribe(_ text: String) {
        Task { @MainActor in
            eventSink?(["event": "didTranscribe", "text": text])
        }
        
    }

    // Called when recording fails
    nonisolated func recordingFailed(_ error: Error) {
        Task { @MainActor in
            eventSink?(["event": "recordingFailed", "error": error.localizedDescription])
        }
    }

    // Called when transcription fails
    nonisolated func failedToTranscribe(_ error: Error) {
        Task { @MainActor in
            eventSink?(["event": "failedToTranscribe", "error": error.localizedDescription])
        }
    }

}

extension WhisperFlutterBridge: FlutterStreamHandler {
    nonisolated func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        Task { @MainActor in
            self.eventSink = events
        }
        return nil
    }

    nonisolated func onCancel(withArguments arguments: Any?) -> FlutterError? {
        Task { @MainActor in
            self.eventSink = nil
        }
        return nil
    }
}

