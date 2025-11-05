class CaregiverMessage {
  final String text;
  final String timestamp;

  CaregiverMessage({required this.text, required this.timestamp});

  Map<String, dynamic> toMap() {
    return {'text': text, 'timestamp': timestamp};
  }

  factory CaregiverMessage.fromMap(Map<String, dynamic> data) {
    return CaregiverMessage(
      text: data['text'] ?? '',
      timestamp: data['timestamp']?.toString() ?? '',
    );
  }
}
