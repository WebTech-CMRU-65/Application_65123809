class Habit {
  final String id;
  final String name;
  final String emoji;
  final String description;
  final DateTime createdAt;

  Habit({
    required this.id,
    required this.name,
    required this.emoji,
    required this.description,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'emoji': emoji,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Habit.fromMap(Map<String, dynamic> map) {
    return Habit(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      emoji: map['emoji'] ?? '',
      description: map['description'] ?? '',
      createdAt: DateTime.parse(
        map['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }
}

class HabitRecord {
  final String id;
  final String habitId;
  final DateTime date;
  final bool completed;
  final int? value; // For habits with quantities (e.g., glasses of water)
  final String? note;

  HabitRecord({
    required this.id,
    required this.habitId,
    required this.date,
    required this.completed,
    this.value,
    this.note,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'habitId': habitId,
      'date': date.toIso8601String(),
      'completed': completed,
      'value': value,
      'note': note,
    };
  }

  factory HabitRecord.fromMap(Map<String, dynamic> map) {
    return HabitRecord(
      id: map['id'] ?? '',
      habitId: map['habitId'] ?? '',
      date: DateTime.parse(map['date'] ?? DateTime.now().toIso8601String()),
      completed: map['completed'] ?? false,
      value: map['value'],
      note: map['note'],
    );
  }
}
