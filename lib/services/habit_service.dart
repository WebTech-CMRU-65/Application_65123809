import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/habit.dart';

class HabitService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user's habits
  CollectionReference get _habitsRef => _firestore
      .collection("users")
      .doc(_auth.currentUser!.uid)
      .collection("habits");

  // Get current user's habit records
  CollectionReference get _habitRecordsRef => _firestore
      .collection("users")
      .doc(_auth.currentUser!.uid)
      .collection("habit_records");

  // Create a new habit
  Future<String> createHabit(Habit habit) async {
    final docRef = await _habitsRef.add(habit.toMap());
    return docRef.id;
  }

  // Get all habits
  Stream<List<Habit>> getHabits() {
    return _habitsRef.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return Habit.fromMap(data);
      }).toList();
    });
  }

  // Update a habit
  Future<void> updateHabit(String habitId, Habit habit) async {
    await _habitsRef.doc(habitId).update(habit.toMap());
  }

  // Delete a habit
  Future<void> deleteHabit(String habitId) async {
    // Delete all records for this habit first
    final recordsQuery = await _habitRecordsRef
        .where('habitId', isEqualTo: habitId)
        .get();

    for (var doc in recordsQuery.docs) {
      await doc.reference.delete();
    }

    // Delete the habit
    await _habitsRef.doc(habitId).delete();
  }

  // Record habit completion for a specific date
  Future<void> recordHabitCompletion(
    String habitId,
    DateTime date, {
    bool completed = true,
    int? value,
    String? note,
  }) async {
    try {
      final dateStr = DateTime(
        date.year,
        date.month,
        date.day,
      ).toIso8601String();
      print(
        'Recording habit completion: habitId=$habitId, date=$dateStr, value=$value',
      );

      // Check if record already exists for this date
      final existingRecords = await _habitRecordsRef
          .where('habitId', isEqualTo: habitId)
          .where('date', isEqualTo: dateStr)
          .get();

      if (existingRecords.docs.isNotEmpty) {
        // Update existing record
        print('Updating existing record');
        await existingRecords.docs.first.reference.update({
          'completed': completed,
          'value': value,
          'note': note,
        });
      } else {
        // Create new record
        print('Creating new record');
        final record = HabitRecord(
          id: '',
          habitId: habitId,
          date: DateTime(date.year, date.month, date.day),
          completed: completed,
          value: value,
          note: note,
        );
        await _habitRecordsRef.add(record.toMap());
      }
      print('Habit completion recorded successfully');
    } catch (e) {
      print('Error recording habit completion: $e');
      rethrow;
    }
  }

  // Get habit records for a specific date range
  Future<List<HabitRecord>> getHabitRecords(
    String habitId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    final startStr = DateTime(
      startDate.year,
      startDate.month,
      startDate.day,
    ).toIso8601String();
    final endStr = DateTime(
      endDate.year,
      endDate.month,
      endDate.day,
    ).toIso8601String();

    // Get all records for this habit and filter in memory to avoid index requirement
    final querySnapshot = await _habitRecordsRef
        .where('habitId', isEqualTo: habitId)
        .get();

    final records = querySnapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      data['id'] = doc.id;
      return HabitRecord.fromMap(data);
    }).toList();

    // Filter by date range in memory
    return records.where((record) {
      final recordDateStr = DateTime(
        record.date.year,
        record.date.month,
        record.date.day,
      ).toIso8601String();
      return recordDateStr.compareTo(startStr) >= 0 &&
          recordDateStr.compareTo(endStr) <= 0;
    }).toList()..sort((a, b) => a.date.compareTo(b.date));
  }

  // Get habit completion data for the last 7 days
  Future<Map<String, bool>> getHabitCompletionLast7Days(String habitId) async {
    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(const Duration(days: 6));

    final records = await getHabitRecords(habitId, sevenDaysAgo, now);

    final Map<String, bool> completionMap = {};

    // Initialize all days as false
    for (int i = 0; i < 7; i++) {
      final date = sevenDaysAgo.add(Duration(days: i));
      final dateStr = DateTime(
        date.year,
        date.month,
        date.day,
      ).toIso8601String();
      completionMap[dateStr] = false;
    }

    // Update with actual completion data
    for (final record in records) {
      final dateStr = DateTime(
        record.date.year,
        record.date.month,
        record.date.day,
      ).toIso8601String();
      completionMap[dateStr] = record.completed;
    }

    return completionMap;
  }

  // Get habit value data for the last 7 days (for quantity-based habits)
  Future<Map<String, int>> getHabitValuesLast7Days(String habitId) async {
    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(const Duration(days: 6));

    final records = await getHabitRecords(habitId, sevenDaysAgo, now);

    final Map<String, int> valueMap = {};

    // Initialize all days as 0
    for (int i = 0; i < 7; i++) {
      final date = sevenDaysAgo.add(Duration(days: i));
      final dateStr = DateTime(
        date.year,
        date.month,
        date.day,
      ).toIso8601String();
      valueMap[dateStr] = 0;
    }

    // Update with actual values
    for (final record in records) {
      final dateStr = DateTime(
        record.date.year,
        record.date.month,
        record.date.day,
      ).toIso8601String();
      valueMap[dateStr] = record.value ?? 0;
    }

    return valueMap;
  }
}
