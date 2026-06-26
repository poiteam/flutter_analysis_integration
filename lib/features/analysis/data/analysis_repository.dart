import '../../../core/platform/poi_analysis_platform.dart';
import '../domain/models/analysis_event.dart';

class AnalysisRepository {
  AnalysisRepository(this._platform);

  final PoiAnalysisPlatform _platform;

  Stream<AnalysisEvent> watchEvents() => _platform.events;

  Future<String> getPlatform() => _platform.getPlatform();

  Future<String> getUniqueId() => _platform.getUniqueId();

  Future<String> getSdkVersion() => _platform.getSdkVersion();

  Future<void> requestPermissions() => _platform.requestPermissions();

  Future<void> updateUniqueId(String uniqueId) =>
      _platform.updateUniqueId(uniqueId);

  Future<void> startScan() => _platform.startScan();

  Future<void> stopScan() => _platform.stopScan();
}
