import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/device_model.dart';
import '../../services/alerts/alarm_service.dart';
import '../../services/ble/ble_provider.dart';
import '../../services/ble/ble_service.dart';
import '../../services/ble/sensor_packet_parser.dart';
import '../profile/profile_controller.dart';

enum AirQualityLevel {
  clean('Clean Air', Colors.green, 'Safe levels, no immediate smoke detected'),
  moderate('Moderate / Possible Smoke', Colors.amber, 'Elevated particulates. Monitor surroundings'),
  unhealthy('Unhealthy Smoke Detected', Colors.orange, 'Secondhand smoke or combustion particles detected'),
  hazardous('Hazardous Exposure', Colors.red, 'Immediate risk. Leave area or wear protection');

  final String label;
  final Color color;
  final String description;

  const AirQualityLevel(this.label, this.color, this.description);
}

class ExposureIncident {
  final String id;
  final DateTime timestamp;
  final String title;
  final AirQualityLevel severity;
  final int peakPm25;
  final int durationMinutes;
  final String locationTag;

  const ExposureIncident({
    required this.id,
    required this.timestamp,
    required this.title,
    required this.severity,
    required this.peakPm25,
    required this.durationMinutes,
    this.locationTag = 'Indoor Environment',
  });
}

class HistoricalReading {
  final DateTime timestamp;
  final double pm25;
  final double voc;

  const HistoricalReading({
    required this.timestamp,
    required this.pm25,
    required this.voc,
  });
}

class ExposureState {
  final ParsedSensorData currentReading;
  final AirQualityLevel currentLevel;
  final String detectedSource;
  final int aiConfidencePercent;
  final double peiScore; // 0 to 100 Personal Exposure Index
  final List<HistoricalReading> recentReadings;
  final List<ExposureIncident> incidents;
  final double dailyDoseAccumulated; // ug/m3 * hours
  final bool isSpikeSimulationActive;

  const ExposureState({
    required this.currentReading,
    this.currentLevel = AirQualityLevel.clean,
    this.detectedSource = 'Ambient Air',
    this.aiConfidencePercent = 94,
    this.peiScore = 18.0,
    this.recentReadings = const [],
    this.incidents = const [],
    this.dailyDoseAccumulated = 24.5,
    this.isSpikeSimulationActive = false,
  });

  ExposureState copyWith({
    ParsedSensorData? currentReading,
    AirQualityLevel? currentLevel,
    String? detectedSource,
    int? aiConfidencePercent,
    double? peiScore,
    List<HistoricalReading>? recentReadings,
    List<ExposureIncident>? incidents,
    double? dailyDoseAccumulated,
    bool? isSpikeSimulationActive,
  }) {
    return ExposureState(
      currentReading: currentReading ?? this.currentReading,
      currentLevel: currentLevel ?? this.currentLevel,
      detectedSource: detectedSource ?? this.detectedSource,
      aiConfidencePercent: aiConfidencePercent ?? this.aiConfidencePercent,
      peiScore: peiScore ?? this.peiScore,
      recentReadings: recentReadings ?? this.recentReadings,
      incidents: incidents ?? this.incidents,
      dailyDoseAccumulated: dailyDoseAccumulated ?? this.dailyDoseAccumulated,
      isSpikeSimulationActive: isSpikeSimulationActive ?? this.isSpikeSimulationActive,
    );
  }
}

class ExposureController extends StateNotifier<ExposureState> {
  final IBleService _bleService;
  final Ref _ref;
  StreamSubscription<ParsedSensorData>? _sensorSub;
  StreamSubscription<BleConnectionStatus>? _statusSub;
  Timer? _spikeTimer;

  ExposureController(this._bleService, this._ref)
      : super(
          ExposureState(
            currentReading: const ParsedSensorData(
              pm25: 12,
              voc: 32,
              temperature: 24.2,
              humidity: 48.0,
              battery: 88,
            ),
            recentReadings: _generateInitialReadings(),
            incidents: _generateInitialIncidents(),
          ),
        ) {
    _initSensorStream();
  }

  static List<HistoricalReading> _generateInitialReadings() {
    final now = DateTime.now();
    final random = Random();
    return List.generate(24, (i) {
      final time = now.subtract(Duration(hours: 23 - i));
      final basePm = (i >= 12 && i <= 14) ? 45.0 + random.nextInt(25) : 8.0 + random.nextInt(10);
      return HistoricalReading(
        timestamp: time,
        pm25: basePm,
        voc: 25.0 + random.nextInt(20),
      );
    });
  }

  static List<ExposureIncident> _generateInitialIncidents() {
    final now = DateTime.now();
    return [
      ExposureIncident(
        id: 'inc-1',
        timestamp: now.subtract(const Duration(hours: 2, minutes: 15)),
        title: 'Secondhand Tobacco Smoke Event',
        severity: AirQualityLevel.unhealthy,
        peakPm25: 68,
        durationMinutes: 14,
        locationTag: 'Public Transit Stop',
      ),
      ExposureIncident(
        id: 'inc-2',
        timestamp: now.subtract(const Duration(hours: 5, minutes: 40)),
        title: 'High Cooking & Biomass Fumes',
        severity: AirQualityLevel.moderate,
        peakPm25: 38,
        durationMinutes: 22,
        locationTag: 'Cafeteria / Dining Area',
      ),
    ];
  }

  void _initSensorStream() {
    _statusSub = _bleService.connectionStatusStream.listen((status) {
      if (status == BleConnectionStatus.connected) {
        _subscribeToData();
      }
    });

    if (_bleService.currentStatus == BleConnectionStatus.connected) {
      _subscribeToData();
    }
  }

  void _subscribeToData() {
    _sensorSub?.cancel();
    _sensorSub = _bleService.subscribeToSensorData().listen((data) {
      _processNewReading(data);
    });
  }

  void _processNewReading(ParsedSensorData data) {
    final level = _calculateAirQuality(data.pm25, data.voc);
    final sourceInfo = _classifySmokeSource(data.pm25, data.voc);

    // Profile sensitivity adjustment
    final profile = _ref.read(profileControllerProvider).profile;
    double sensitivityFactor = 1.0;
    if (profile != null) {
      if (profile.hasAsthma || profile.hasCopd) sensitivityFactor += 0.35;
      if (profile.isPregnant) sensitivityFactor += 0.25;
      if (profile.isSmoker) sensitivityFactor += 0.15;
    }

    // Dynamic PEI Score calculation (0 to 100)
    final instantIndex = ((data.pm25 / 75.0) * 80.0 * sensitivityFactor).clamp(0.0, 100.0);
    final updatedPei = (state.peiScore * 0.9 + instantIndex * 0.1).clamp(0.0, 100.0);

    final newHistorical = List<HistoricalReading>.from(state.recentReadings)
      ..add(HistoricalReading(timestamp: DateTime.now(), pm25: data.pm25.toDouble(), voc: data.voc.toDouble()));

    if (newHistorical.length > 50) {
      newHistorical.removeAt(0);
    }

    state = state.copyWith(
      currentReading: data,
      currentLevel: level,
      detectedSource: sourceInfo.$1,
      aiConfidencePercent: sourceInfo.$2,
      peiScore: updatedPei,
      recentReadings: newHistorical,
    );

    if (level == AirQualityLevel.hazardous || level == AirQualityLevel.unhealthy) {
      _ref.read(alarmServiceProvider.notifier).triggerAlarm(
        title: '⚠️ CRITICAL: ${sourceInfo.$1.toUpperCase()}',
        message: 'PM2.5 reached ${data.pm25} µg/m³. Step into clean ventilated air immediately.',
        severity: level == AirQualityLevel.hazardous ? 2 : 1,
      );
    }
  }

  AirQualityLevel _calculateAirQuality(int pm25, int voc) {
    if (pm25 > 55 || voc > 250) {
      return AirQualityLevel.hazardous;
    } else if (pm25 > 35 || voc > 120) {
      return AirQualityLevel.unhealthy;
    } else if (pm25 > 15 || voc > 60) {
      return AirQualityLevel.moderate;
    }
    return AirQualityLevel.clean;
  }

  (String, int) _classifySmokeSource(int pm25, int voc) {
    if (pm25 > 50 && voc > 100) {
      return ('Secondhand Cigarette Smoke', 96);
    } else if (pm25 > 35 && voc < 60) {
      return ('Vape / Aerosol Emission', 91);
    } else if (pm25 > 25 && voc > 80) {
      return ('Cooking Oil & Biomass Smoke', 88);
    } else if (pm25 > 15) {
      return ('Urban Particulate Spike', 84);
    }
    return ('Clean Ambient Air', 98);
  }

  /// Trigger a 15-second simulated smoke surge for demonstration and safety drills
  void simulateSmokeSpike() {
    if (state.isSpikeSimulationActive) return;

    final originalReading = state.currentReading;
    state = state.copyWith(
      isSpikeSimulationActive: true,
      currentReading: ParsedSensorData(
        pm25: 78,
        voc: 185,
        temperature: originalReading.temperature + 0.8,
        humidity: originalReading.humidity - 4.0,
        battery: originalReading.battery,
      ),
      currentLevel: AirQualityLevel.hazardous,
      detectedSource: 'Secondhand Tobacco Smoke (Simulated)',
      aiConfidencePercent: 99,
      peiScore: min(100.0, state.peiScore + 32.0),
    );

    // Record incident
    final spikeIncident = ExposureIncident(
      id: 'sim-${DateTime.now().millisecondsSinceEpoch}',
      timestamp: DateTime.now(),
      title: 'High Smoke Exposure Drill',
      severity: AirQualityLevel.hazardous,
      peakPm25: 78,
      durationMinutes: 1,
      locationTag: 'Testing Environment',
    );

    state = state.copyWith(
      incidents: [spikeIncident, ...state.incidents],
    );

    // Trigger Audible/Haptic Alarm
    _ref.read(alarmServiceProvider.notifier).triggerAlarm(
      title: '🚨 SMOKE DRILL ALARM ACTIVATED',
      message: 'Simulated secondhand smoke spike: PM2.5 at 78 µg/m³!',
      severity: 2,
    );

    _spikeTimer?.cancel();
    _spikeTimer = Timer(const Duration(seconds: 15), () {
      _ref.read(alarmServiceProvider.notifier).dismissAlarm();
      state = state.copyWith(
        isSpikeSimulationActive: false,
        currentReading: originalReading,
        currentLevel: AirQualityLevel.clean,
        detectedSource: 'Ambient Air (Clean)',
        aiConfidencePercent: 95,
      );
    });
  }

  void clearIncidents() {
    state = state.copyWith(incidents: []);
  }

  @override
  void dispose() {
    _sensorSub?.cancel();
    _statusSub?.cancel();
    _spikeTimer?.cancel();
    super.dispose();
  }
}

final exposureControllerProvider =
    StateNotifierProvider<ExposureController, ExposureState>((ref) {
  final bleService = ref.watch(bleServiceProvider);
  return ExposureController(bleService, ref);
});
