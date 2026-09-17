class VitalMeasurement {
  final int bpm;
  final String status; // 'NORMAL', 'BRADICARDIA', 'TAQUICARDIA'
  final String statusLabel;
  final double qualityScore; // 0.0 a 1.0
  final DateTime timestamp;
  final String? notes;

  const VitalMeasurement({
    required this.bpm,
    required this.status,
    required this.statusLabel,
    required this.qualityScore,
    required this.timestamp,
    this.notes,
  });

  factory VitalMeasurement.fromBpm({
    required int bpm,
    double qualityScore = 1.0,
    String? notes,
    DateTime? timestamp,
  }) {
    String status;
    String statusLabel;
    if (bpm < 60) {
      status = 'BRADICARDIA';
      statusLabel = 'Pulso bajo (<60 BPM)';
    } else if (bpm > 100) {
      status = 'TAQUICARDIA';
      statusLabel = 'Pulso elevado (>100 BPM)';
    } else {
      status = 'NORMAL';
      statusLabel = 'Ritmo normal (60-100 BPM)';
    }

    return VitalMeasurement(
      bpm: bpm,
      status: status,
      statusLabel: statusLabel,
      qualityScore: qualityScore,
      timestamp: timestamp ?? DateTime.now(),
      notes: notes,
    );
  }

  Map<String, dynamic> toJson() => {
        'bpm': bpm,
        'status': status,
        'statusLabel': statusLabel,
        'qualityScore': qualityScore,
        'timestamp': timestamp.toIso8601String(),
        'notes': notes,
      };

  factory VitalMeasurement.fromJson(Map<String, dynamic> json) => VitalMeasurement(
        bpm: (json['bpm'] as num?)?.toInt() ?? 72,
        status: json['status']?.toString() ?? 'NORMAL',
        statusLabel: json['statusLabel']?.toString() ?? 'Ritmo normal (60-100 BPM)',
        qualityScore: (json['qualityScore'] as num?)?.toDouble() ?? 1.0,
        timestamp: DateTime.tryParse(json['timestamp']?.toString() ?? '') ?? DateTime.now(),
        notes: json['notes']?.toString(),
      );
}
