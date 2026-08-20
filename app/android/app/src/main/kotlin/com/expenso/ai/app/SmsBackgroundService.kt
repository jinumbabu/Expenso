package com.expenso.ai.app

import android.content.Context
import android.content.Intent
import androidx.core.app.JobIntentService
import io.flutter.FlutterInjector
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugins.GeneratedPluginRegistrant
import android.util.Log

class SmsBackgroundService : JobIntentService() {
    private var flutterEngine: FlutterEngine? = null
    private var backgroundChannel: MethodChannel? = null

    companion object {
        private const val JOB_ID = 10002
        private const val TAG = "SmsBackgroundService"

        fun enqueueWork(context: Context, intent: Intent) {
            enqueueWork(context, SmsBackgroundService::class.java, JOB_ID, intent)
        }
    }

    override fun onHandleWork(intent: Intent) {
        Log.d(TAG, "onHandleWork called")
        val sender = intent.getStringExtra("sender")
        val body = intent.getStringExtra("body")
        val timestamp = intent.getLongExtra("timestamp", 0L)

        if (body == null) {
            Log.e(TAG, "Body is null, skipping")
            return
        }

        val context = applicationContext
        val loader = FlutterInjector.instance().flutterLoader()
        
        val mainHandler = android.os.Handler(context.mainLooper)
        val lock = Object()
        var completed = false

        mainHandler.post {
            try {
                loader.startInitialization(context)
                loader.ensureInitializationComplete(context, null)

                flutterEngine = FlutterEngine(context)
                GeneratedPluginRegistrant.registerWith(flutterEngine!!)

                backgroundChannel = MethodChannel(flutterEngine!!.dartExecutor.binaryMessenger, "com.expenso.ai.app/sms_background")
                backgroundChannel?.setMethodCallHandler { call, result ->
                    when (call.method) {
                        "onBackgroundEngineReady" -> {
                            Log.d(TAG, "Dart engine reported ready. Sending SMS payload.")
                            val data = mapOf(
                                "sender" to sender,
                                "body" to body,
                                "timestamp" to timestamp
                            )
                            backgroundChannel?.invokeMethod("onBackgroundSmsReceived", data)
                            result.success(null)
                        }
                        "onBackgroundProcessingFinished" -> {
                            Log.d(TAG, "Dart processing finished.")
                            result.success(null)
                            synchronized(lock) {
                                completed = true
                                lock.notify()
                            }
                        }
                        else -> {
                            result.notImplemented()
                        }
                    }
                }

                val entrypoint = DartExecutor.DartEntrypoint(
                    loader.findAppBundlePath(),
                    "backgroundSmsCallback"
                )
                
                flutterEngine!!.dartExecutor.executeDartEntrypoint(entrypoint)

            } catch (e: Exception) {
                Log.e(TAG, "Error initializing background FlutterEngine: ${e.message}", e)
                synchronized(lock) {
                    completed = true
                    lock.notify()
                }
            }
        }

        // Wait for Dart processing to finish
        synchronized(lock) {
            while (!completed) {
                try {
                    lock.wait(20000) // 20s timeout max
                    break
                } catch (e: InterruptedException) {
                    Log.e(TAG, "Interrupted while waiting for Dart processing")
                }
            }
        }

        // Clean up on main thread
        mainHandler.post {
            flutterEngine?.destroy()
            flutterEngine = null
            backgroundChannel = null
            Log.d(TAG, "FlutterEngine destroyed and cleaned up.")
        }
        Log.d(TAG, "Work handling completed")
    }
}
