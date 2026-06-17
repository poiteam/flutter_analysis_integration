class AnalysisEvent {
  const AnalysisEvent({
    required this.type,
    this.nodeIds = const [],
    this.message,
    this.rawResponse,
  });

  final AnalysisEventType type;
  final List<String> nodeIds;
  final String? message;
  final String? rawResponse;

  factory AnalysisEvent.fromMap(Map<dynamic, dynamic> map) {
    final typeName = map['type'] as String? ?? 'unknown';
    final nodeIds = (map['nodeIds'] as List<dynamic>?)
            ?.map((item) => item.toString())
            .toList() ??
        const [];

    return AnalysisEvent(
      type: AnalysisEventType.fromString(typeName),
      nodeIds: nodeIds,
      message: map['message'] as String?,
      rawResponse: map['rawResponse'] as String?,
    );
  }
}

enum AnalysisEventType {
  response,
  error,
  status,
  unknown;

  static AnalysisEventType fromString(String value) {
    return AnalysisEventType.values.firstWhere(
      (type) => type.name == value,
      orElse: () => AnalysisEventType.unknown,
    );
  }
}
