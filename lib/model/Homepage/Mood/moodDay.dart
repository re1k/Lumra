class MoodDay {
  final int value; // 1–5
  final bool chosen; // true if user picked, false if default
  final String date; // "YYYY-MM-DD"

  MoodDay({required this.value, required this.chosen, required this.date});

  Map<String, dynamic> toMap() => {
    'value': value,
    'chosen': chosen,
    'date': date,
  };

  factory MoodDay.fromMap(Map<String, dynamic> data) => MoodDay(
    value: data['value'] ?? 3,
    chosen: data['chosen'] ?? false,
    date: data['date'] ?? "",
  );
}
