import 'dart:async';

import '../data/analysis_repository.dart';
import '../domain/models/analysis_event.dart';

class AnalysisController {
  AnalysisController(this._repository) {
    _subscription = _repository.watchEvents().listen(_handleEvent);
  }

  final AnalysisRepository _repository;
  late final StreamSubscription<AnalysisEvent> _subscription;

  String platform = 'loading...';
  String uniqueId = 'loading...';
  String sdkVersion = 'loading...';
  bool isScanning = false;
  String? statusMessage;
  String? lastError;
  final List<String> nodeIds = [];

  final StreamController<void> _changes = StreamController<void>.broadcast();

  Stream<void> get changes => _changes.stream;

  Future<void> initialize() async {
    // Pull diagnostic metadata first so UI can show platform/id/version immediately.
    platform = await _repository.getPlatform();
    uniqueId = await _repository.getUniqueId();
    sdkVersion = await _repository.getSdkVersion();
    await _repository.requestPermissions();
    _notify();
  }

  Future<void> startScan() async {
    isScanning = true;
    statusMessage = 'Starting scan...';
    lastError = null;
    _notify();

    await _repository.startScan();
  }

  Future<void> stopScan() async {
    await _repository.stopScan();
    isScanning = false;
    _notify();
  }

  void _handleEvent(AnalysisEvent event) {
    switch (event.type) {
      case AnalysisEventType.response:
        if (event.nodeIds.isNotEmpty) {
          nodeIds.addAll(event.nodeIds);
        } else if (event.rawResponse != null) {
          nodeIds.add(event.rawResponse!);
        }
      case AnalysisEventType.error:
        lastError = event.message;
        isScanning = false;
      case AnalysisEventType.status:
        statusMessage = event.message;
        if (event.message?.toLowerCase().contains('stopped') ?? false) {
          isScanning = false;
        }
      case AnalysisEventType.unknown:
        break;
    }
    _notify();
  }

  void clearResults() {
    nodeIds.clear();
    lastError = null;
    statusMessage = null;
    _notify();
  }

  void _notify() {
    if (!_changes.isClosed) {
      _changes.add(null);
    }
  }

  void dispose() {
    _subscription.cancel();
    _changes.close();
  }
}
