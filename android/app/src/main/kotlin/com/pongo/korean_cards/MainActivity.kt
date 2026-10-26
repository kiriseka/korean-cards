package com.pongo.korean_cards

import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Receives Korean text from other apps — "Share → Korean Cards" (ACTION_SEND) and the text
 * selection menu (ACTION_PROCESS_TEXT) — and hands it to Flutter's look-up screen.
 */
class MainActivity : FlutterActivity() {
    private var channel: MethodChannel? = null
    private var pending: String? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "korean_cards/share").apply {
            setMethodCallHandler { call, result ->
                if (call.method == "initialText") {
                    result.success(pending)
                    pending = null
                } else {
                    result.notImplemented()
                }
            }
        }
        pending = sharedText(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        val text = sharedText(intent) ?: return
        channel?.invokeMethod("sharedText", text)
    }

    private fun sharedText(intent: Intent?): String? = when (intent?.action) {
        Intent.ACTION_SEND -> intent.getStringExtra(Intent.EXTRA_TEXT)
        Intent.ACTION_PROCESS_TEXT -> intent.getCharSequenceExtra(Intent.EXTRA_PROCESS_TEXT)?.toString()
        else -> null
    }?.takeIf { it.isNotBlank() }
}
