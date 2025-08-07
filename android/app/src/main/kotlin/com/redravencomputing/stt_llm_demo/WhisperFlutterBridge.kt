package com.redravencomputing.stt_llm_demo

import android.content.Context
import android.util.Log
import com.redravencomputing.whispercore.Whisper
import com.redravencomputing.whispercore.WhisperDelegate
import com.redravencomputing.whispercore.WhisperLoadError
import com.redravencomputing.whispercore.WhisperOperationError
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import java.io.File

private enum class WhisperMethods(val methodName: String) {
	Permission("callRequestRecordPermission"),
	InitializeModel("initializeModel"),
	StartRecording("startRecording"),
	StopRecording("stopRecording"),
	ToggleRecording("toggleRecording"),
	TranscribeSample("transcribeSample"),
	EnablePlayback("enablePlayback"),
	Reset("reset"),
	CanTranscribe("canTranscribe"),
	IsRecording("isRecording"),
	IsModelLoaded("isModelLoaded"),
	GetMessageLogs("getMessageLogs"),

	IsMicrophonePermissionGranted("isMicrophonePermissionGranted");

	companion object {
		fun fromMethodName(name: String): WhisperMethods? {
			return entries.find { it.methodName == name }
		}
	}
}

class WhisperFlutterBridge(context: Context) : MethodChannel.MethodCallHandler, EventChannel.StreamHandler {

	private var eventSink: EventChannel.EventSink? = null

	private fun serializeError(error: WhisperOperationError): String {
		return when (error) {
			is WhisperOperationError.MicPermissionDenied -> "Microphone access denied"
			is WhisperOperationError.MissingRecordedFile -> "Missing Recorded File"
			is WhisperOperationError.ModelNotLoaded -> "Model Not Loaded"
			is WhisperOperationError.RecordingFailed -> "Recording Failed"
			else -> "Unknown error: ${error.message}"
		}
	}

	private val whisper = Whisper(context).apply {
		delegate = object : WhisperDelegate {
			override fun didTranscribe(text: String) {
				eventSink?.success(mapOf("event" to "didTranscribe", "text" to text))
			}

			override fun recordingFailed(error: WhisperOperationError) {
				eventSink?.success(
					mapOf(
						"event" to "recordingFailed",
						"error" to serializeError(error)
					)
				)
			}

			override fun failedToTranscribe(error: WhisperOperationError) {
				eventSink?.success(
					mapOf(
						"event" to "failedToTranscribe",
						"error" to serializeError(error)
					)
				)
			}

			override fun permissionRequestNeeded() {
				eventSink?.success(mapOf("event" to "permissionRequestNeeded"))
			}

			override fun didStartRecording() {
				Log.d("WhisperFlutterBridge", "Did Start Recording")
				eventSink?.success(mapOf("event" to "didStartRecording", "isRecording" to true))
			}

			override fun didStopRecording() {
				Log.d("WhisperFlutterBridge", "Did Stop Recording")
				eventSink?.success(mapOf("event" to "didStopRecording", "isRecording" to false))
			}
		}
	}

	override fun onMethodCall(
		call: MethodCall,
		result: MethodChannel.Result
	) {
		val method = WhisperMethods.fromMethodName(call.method)
		if (method == null) {
			result.notImplemented()
			return
		}
		when(method) {
			WhisperMethods.Permission -> {
				Log.d("WhisperFlutterBridge", "Permission is being called")
				whisper.callRequestRecordPermission()
				result.success(null)
			}
			WhisperMethods.InitializeModel -> {
				val path = call.argument<String>("path")
				if (path == null) {
					result.error("BAD_ARGS", "Missing model path", null)
					return
				}
				CoroutineScope(Dispatchers.Main).launch {
					try {
						whisper.initializeModel(path, false)
						result.success(true)
					} catch (e: WhisperLoadError) {
						result.error("INIT_FAIL", e.localizedMessage, null)
					} catch (e: Exception) {
						result.error("INIT_FAIL", e.localizedMessage, null)
					}
				}
			}
			WhisperMethods.StartRecording -> {
				whisper.startRecording()
				result.success(null)
			}
			WhisperMethods.StopRecording -> {
				whisper.stopRecording()
				result.success(null)
			}
			WhisperMethods.ToggleRecording -> {
				whisper.toggleRecording()
				result.success(null)
			}
			WhisperMethods.TranscribeSample -> {
				val path = call.argument<String>("path")
				if (path == null) {
					result.error("BAD_ARGS", "Missing sample path", null)
					return
				}
				whisper.transcribeAudioFile(
					File(path))
				result.success(null)
			}
			WhisperMethods.EnablePlayback -> {
				val enabled = call.argument<Boolean>("enabled") ?: false
				whisper.enablePlayback(enabled)
				result.success(null)
			}
			WhisperMethods.Reset -> {
				whisper.reset()
				result.success(null)
			}
			WhisperMethods.CanTranscribe ->  result.success(whisper.canTranscribe)
			WhisperMethods.IsRecording ->  result.success(whisper.isRecording)
			WhisperMethods.IsModelLoaded ->  result.success(whisper.isModelLoaded)
			WhisperMethods.GetMessageLogs ->  result.success(whisper.getMessageLogs())
			WhisperMethods.IsMicrophonePermissionGranted -> result.success(whisper.isMicrophonePermissionGranted())
		}
	}

	override fun onListen(
		arguments: Any?,
		events: EventChannel.EventSink?
	) {
		eventSink = events
	}

	override fun onCancel(arguments: Any?) {
		eventSink = null
	}

	fun onRecordPermissionResult(granted: Boolean) {
		whisper.onRecordPermissionResult(granted)
	}

}