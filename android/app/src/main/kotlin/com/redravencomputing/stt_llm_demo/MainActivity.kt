package com.redravencomputing.stt_llm_demo

import android.content.pm.PackageManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel


class MainActivity : FlutterActivity() {
	private val REQUEST_CODE = 1234

	private lateinit var whisperBridge: WhisperFlutterBridge

	override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
		super.configureFlutterEngine(flutterEngine)

		val whisperBridge = WhisperFlutterBridge(this)

		MethodChannel(
			flutterEngine.dartExecutor.binaryMessenger,
			"whisper_method_channel"
		).setMethodCallHandler(whisperBridge)

		EventChannel(
			flutterEngine.dartExecutor.binaryMessenger,
			"whisper_events"
		).setStreamHandler(whisperBridge)
	}

	override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray) {
		super.onRequestPermissionsResult(requestCode, permissions, grantResults)
		if (requestCode == REQUEST_CODE) {
			val granted = grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED
			// Inform your Whisper instance or Flutter about the result:
			whisperBridge.onRecordPermissionResult(granted)
			// or use MethodChannel/EventChannel to send this back to Flutter
		}
	}
}
