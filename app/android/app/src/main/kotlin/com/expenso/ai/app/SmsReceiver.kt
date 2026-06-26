package com.expenso.ai.app

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.provider.Telephony
import io.flutter.plugin.common.MethodChannel

class SmsReceiver : BroadcastReceiver() {
    companion object {
        var methodChannel: MethodChannel? = null
    }

    override fun onReceive(context: Context?, intent: Intent?) {
        if (intent?.action == Telephony.Sms.Intents.SMS_RECEIVED_ACTION) {
            val messages = Telephony.Sms.Intents.getMessagesFromIntent(intent)
            for (message in messages) {
                val body = message.messageBody
                val sender = message.originatingAddress
                val timestamp = message.timestampMillis

                methodChannel?.let { channel ->
                    val data = mapOf(
                        "sender" to sender,
                        "body" to body,
                        "timestamp" to timestamp
                    )
                    // MethodChannel invocations must happen on the platform's main UI thread
                    channel.invokeMethod("onSmsReceived", data)
                }
            }
        }
    }
}
