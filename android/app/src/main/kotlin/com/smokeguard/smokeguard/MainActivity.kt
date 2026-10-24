package com.smokeguard.smokeguard

import android.media.AudioAttributes
import android.media.AudioManager
import android.media.Ringtone
import android.media.RingtoneManager
import android.media.ToneGenerator
import android.os.Build
import android.os.Bundle
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import android.speech.tts.TextToSpeech
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.Locale

class MainActivity : FlutterActivity(), TextToSpeech.OnInitListener {
    private val CHANNEL = "com.smokeguard/alarm"
    private var ringtone: Ringtone? = null
    private var toneGen: ToneGenerator? = null
    private var tts: TextToSpeech? = null
    private var isTtsReady = false

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        try {
            tts = TextToSpeech(applicationContext, this)
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    override fun onInit(status: Int) {
        if (status == TextToSpeech.SUCCESS) {
            try {
                tts?.language = Locale.US
                tts?.setSpeechRate(0.92f) // Clear and authoritative warning pace
                tts?.setPitch(1.05f)
                isTtsReady = true
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "startAlarm" -> {
                    val message = call.argument<String>("message")
                        ?: "Warning! Secondhand smoke detected! Please stop smoking or keep distance!"
                    startNativeAlarm(message)
                    result.success(true)
                }
                "stopAlarm" -> {
                    stopNativeAlarm()
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun startNativeAlarm(voiceText: String) {
        try {
            stopNativeAlarm()

            // 1. Initial High-Decibel Warning Chime (Beep-Beep)
            try {
                toneGen = ToneGenerator(AudioManager.STREAM_ALARM, 100)
                toneGen?.startTone(ToneGenerator.TONE_CDMA_EMERGENCY_RINGBACK, 800)
            } catch (e: Exception) {
                e.printStackTrace()
            }

            // 2. Speak Out Loud: "Warning! Secondhand smoke detected! Please stop smoking or keep distance!"
            try {
                if (isTtsReady && tts != null) {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                        tts?.speak(voiceText, TextToSpeech.QUEUE_FLUSH, null, "SmokeGuardVoiceAlert")
                    } else {
                        @Suppress("DEPRECATION")
                        tts?.speak(voiceText, TextToSpeech.QUEUE_FLUSH, null)
                    }
                }
            } catch (e: Exception) {
                e.printStackTrace()
            }

            // 3. Heavy Physical Vibration Pulse
            try {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                    val vibratorManager = getSystemService(VIBRATOR_MANAGER_SERVICE) as VibratorManager
                    val vibrator = vibratorManager.defaultVibrator
                    vibrator.vibrate(VibrationEffect.createWaveform(longArrayOf(0, 400, 200, 400), -1))
                } else {
                    @Suppress("DEPRECATION")
                    val vibrator = getSystemService(VIBRATOR_SERVICE) as Vibrator
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                        vibrator.vibrate(VibrationEffect.createWaveform(longArrayOf(0, 400, 200, 400), -1))
                    } else {
                        vibrator.vibrate(longArrayOf(0, 400, 200, 400), -1)
                    }
                }
            } catch (e: Exception) {
                e.printStackTrace()
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    private fun stopNativeAlarm() {
        try {
            if (tts?.isSpeaking == true) {
                tts?.stop()
            }
            if (ringtone?.isPlaying == true) {
                ringtone?.stop()
            }
            ringtone = null

            toneGen?.stopTone()
            toneGen?.release()
            toneGen = null
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    override fun onDestroy() {
        stopNativeAlarm()
        try {
            tts?.shutdown()
            tts = null
        } catch (e: Exception) {
            e.printStackTrace()
        }
        super.onDestroy()
    }
}
