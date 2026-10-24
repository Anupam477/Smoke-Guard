import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// State of the active environmental alarm
class AlarmState {
  final bool isAlarming;
  final bool isMuted;
  final String title;
  final String message;
  final int severityLevel; // 1: Warning, 2: Hazardous / Critical

  const AlarmState({
    this.isAlarming = false,
    this.isMuted = false,
    this.title = '',
    this.message = '',
    this.severityLevel = 0,
  });

  AlarmState copyWith({
    bool? isAlarming,
    bool? isMuted,
    String? title,
    String? message,
    int? severityLevel,
  }) {
    return AlarmState(
      isAlarming: isAlarming ?? this.isAlarming,
      isMuted: isMuted ?? this.isMuted,
      title: title ?? this.title,
      message: message ?? this.message,
      severityLevel: severityLevel ?? this.severityLevel,
    );
  }
}

class AlarmService extends StateNotifier<AlarmState> {
  Timer? _pulseTimer;
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  bool _isNotificationInitialized = false;

  AlarmService() : super(const AlarmState()) {
    _initNotifications();
  }

  Future<void> _initNotifications() async {
    try {
      const androidInit =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const initSettings = InitializationSettings(android: androidInit);
      await _notificationsPlugin.initialize(initSettings);
      _isNotificationInitialized = true;
    } catch (e) {
      debugPrint('[AlarmService] Notification init warning: $e');
    }
  }

  /// Trigger emergency smoke/hazard alarm with sound and haptic vibration
  void triggerAlarm({
    required String title,
    required String message,
    int severity = 2,
  }) {
    if (state.isAlarming && !state.isMuted) return;

    state = AlarmState(
      isAlarming: true,
      isMuted: false,
      title: title,
      message: message,
      severityLevel: severity,
    );

    _startAlarmLoop();
    _showSystemNotification(title, message, severity);
  }

  void _startAlarmLoop() {
    _pulseTimer?.cancel();

    // Immediate first voice & haptic pulse
    _performHapticAndSound();

    // Repeat every 4.5 seconds so speech finishes cleanly while alarming
    _pulseTimer = Timer.periodic(const Duration(milliseconds: 4500), (_) {
      if (!state.isAlarming || state.isMuted) {
        _pulseTimer?.cancel();
        return;
      }
      _performHapticAndSound();
    });
  }

  static const MethodChannel _nativeAlarmChannel =
      MethodChannel('com.smokeguard/alarm');

  void _performHapticAndSound() {
    try {
      final voiceWarning = 'Warning! Smoke detected! Please stop smoking or keep distance!';

      // Trigger native Android hardware alarm & Spoken Voice Alert
      _nativeAlarmChannel.invokeMethod<bool>('startAlarm', {
        'message': voiceWarning,
      });

      // Haptic vibration feedback
      HapticFeedback.heavyImpact();
      Future.delayed(const Duration(milliseconds: 200), () {
        HapticFeedback.heavyImpact();
      });
      // System auditory chime / alert
      SystemSound.play(SystemSoundType.alert);
    } catch (e) {
      debugPrint('[AlarmService] Haptic/Sound error: $e');
    }
  }

  Future<void> _showSystemNotification(
      String title, String message, int severity) async {
    if (!_isNotificationInitialized) return;

    try {
      final androidDetails = AndroidNotificationDetails(
        'smokeguard_alerts',
        'SmokeGuard Emergency Alerts',
        channelDescription:
            'Critical smoke and environmental hazard push warnings',
        importance: Importance.max,
        priority: Priority.high,
        enableVibration: true,
        playSound: true,
        fullScreenIntent: severity >= 2,
      );

      final notificationDetails =
          NotificationDetails(android: androidDetails);

      await _notificationsPlugin.show(
        999,
        title,
        message,
        notificationDetails,
      );
    } catch (e) {
      debugPrint('[AlarmService] Push notification error: $e');
    }
  }

  /// Mute the audible and vibrating alarm while keeping banner visible
  void muteAlarm() {
    _pulseTimer?.cancel();
    try {
      _nativeAlarmChannel.invokeMethod<bool>('stopAlarm');
    } catch (_) {}
    state = state.copyWith(isMuted: true);
  }

  /// Completely silence and dismiss the alarm
  void dismissAlarm() {
    _pulseTimer?.cancel();
    try {
      _nativeAlarmChannel.invokeMethod<bool>('stopAlarm');
    } catch (_) {}
    state = const AlarmState();
    try {
      _notificationsPlugin.cancel(999);
    } catch (_) {}
  }

  @override
  void dispose() {
    _pulseTimer?.cancel();
    super.dispose();
  }
}

final alarmServiceProvider =
    StateNotifierProvider<AlarmService, AlarmState>((ref) {
  return AlarmService();
});
