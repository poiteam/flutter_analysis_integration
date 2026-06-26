import 'dart:async';

import 'package:flutter/services.dart';

import '../../features/analysis/domain/models/analysis_event.dart';
import 'poi_analysis_platform.dart';

class PoiAnalysisMethodChannel implements PoiAnalysisPlatform {
  PoiAnalysisMethodChannel({
    MethodChannel? methodChannel,
    EventChannel? eventChannel,
  })  : _methodChannel = methodChannel ??
            const MethodChannel('com.poilabs.analysis/poi_analysis'),
        _eventChannel = eventChannel ??
            const EventChannel('com.poilabs.analysis/poi_events');

  final MethodChannel _methodChannel;
  final EventChannel _eventChannel;

  @override
  Stream<AnalysisEvent> get events => _eventChannel
      .receiveBroadcastStream()
      .map((event) => AnalysisEvent.fromMap(Map<dynamic, dynamic>.from(event as Map)));

  @override
  Future<String> getPlatform() async {
    final platform = await _methodChannel.invokeMethod<String>('getPlatform');
    return platform ?? 'unknown';
  }

  @override
  Future<String> getUniqueId() async {
    // Native side resolves runtime override or device/build-time fallback.
    final uniqueId = await _methodChannel.invokeMethod<String>('getUniqueId');
    return uniqueId ?? '';
  }

  @override
  Future<String> getSdkVersion() async {
    final version = await _methodChannel.invokeMethod<String>('getSdkVersion');
    return version ?? 'unknown';
  }

  @override
  Future<void> requestPermissions() {
    return _methodChannel.invokeMethod<void>('requestPermissions');
  }

  @override
  Future<void> updateUniqueId(String uniqueId) {
    return _methodChannel.invokeMethod<void>(
      'updateUniqueId',
      {'uniqueId': uniqueId},
    );
  }

  @override
  Future<void> startScan() {
    return _methodChannel.invokeMethod<void>('startScan');
  }

  @override
  Future<void> stopScan() {
    return _methodChannel.invokeMethod<void>('stopScan');
  }
}
