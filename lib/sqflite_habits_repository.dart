import 'habits_repository.dart';
import 'db_helper.dart';
import 'habit_entry.dart';

class SqfliteHabitsRepository implements HabitsRepository {
  final DbHelper _db = DbHelper();

  @override
  Future<void> upsertEntry(HabitEntry entry) =>
      _db.upsertEntry(entry);

  @override
  Future<List<HabitEntry>> fetchLast7Days(String habitTitle) =>
      _db.fetchLast7Days(habitTitle);

  @override
  Future<List<HabitEntry>> fetchMonthlyTotals(String habitTitle) =>
      _db.fetchMonthlyTotals(habitTitle);

  @override
  Future<void> clearEntries() =>
      _db.clearEntries();

  @override
  Future<void> clearEntriesForHabit(String habitTitle) =>
      _db.clearEntriesForHabit(habitTitle);
}
