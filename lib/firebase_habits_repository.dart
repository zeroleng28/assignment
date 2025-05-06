import 'habits_repository.dart';
import 'sync_service.dart';
import 'habit_entry.dart';

class FirebaseHabitsRepository implements HabitsRepository {
  final _sync = SyncService();

  @override
  Future<void> upsertEntry(HabitEntry entry) =>
      _sync.saveToFirestore(entry);

  @override
  Future<List<HabitEntry>> fetchLast7Days(String habitTitle) =>
      _sync.loadLast7Days(habitTitle);

  @override
  Future<Map<String, double>> fetchMonthlyTotals(String habitTitle) =>
      _sync.loadMonthlyTotals(habitTitle);
}
