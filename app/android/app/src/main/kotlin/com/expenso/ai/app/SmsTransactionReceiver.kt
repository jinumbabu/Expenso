package com.expenso.ai.app

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.provider.Telephony
import io.flutter.plugin.common.MethodChannel
import android.util.Log

class SmsTransactionReceiver : BroadcastReceiver() {
    companion object {
        var methodChannel: MethodChannel? = null
        private const val TAG = "SmsTransactionReceiver"
    }

    override fun onReceive(context: Context?, intent: Intent?) {
        if (intent?.action == Telephony.Sms.Intents.SMS_RECEIVED_ACTION) {
            val messages = Telephony.Sms.Intents.getMessagesFromIntent(intent)
            for (message in messages) {
                val body = message.messageBody
                val sender = message.originatingAddress
                val timestamp = message.timestampMillis

                Log.d(TAG, "SMS received from $sender")

                Log.d(TAG, "SMS received from $sender. Launching SmsBackgroundService.")
                if (context != null) {
                    val serviceIntent = Intent(context, SmsBackgroundService::class.java).apply {
                        putExtra("sender", sender)
                        putExtra("body", body)
                        putExtra("timestamp", timestamp)
                    }
                    SmsBackgroundService.enqueueWork(context, serviceIntent)
                }
            }
        }
    }
}
