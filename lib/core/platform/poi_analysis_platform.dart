import '../../features/analysis/domain/models/analysis_event.dart';

abstract class PoiAnalysisPlatform {
  Future<String> getPlatform();

  Future<String> getSdkVersion();

  Future<void> requestPermissions();

  Future<void> updateUniqueId(String uniqueId);

  Future<void> startScan();

  Future<void> stopScan();

  Stream<AnalysisEvent> get events;
}
