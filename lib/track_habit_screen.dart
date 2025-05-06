import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'habits_repository.dart';
import 'sqflite_habits_repository.dart';
import 'db_helper.dart';
import 'habit.dart';
import 'habit_entry.dart';
import 'sync_service.dart';
import 'interactive_trend_chart.dart';
import 'edit_habit_screen.dart';
import 'package:uuid/uuid.dart';

class TrackHabitScreen extends StatefulWidget {
  const TrackHabitScreen({Key? key}) : super(key: key);

  @override
  State<TrackHabitScreen> createState() => _TrackHabitScreenState();
}

class _TrackHabitScreenState extends State<TrackHabitScreen> {
  final HabitsRepository _repo = SqfliteHabitsRepository();
  List<Habit> _habits = [
    Habit(
      title: 'Reduce Plastic',
      unit: 'kg',
      goal: 5.0,
      currentValue: 0.0,
      quickAdds: [0.1, 0.5, 1.0],
    ),
    Habit(
      title: 'Short Walk',
      unit: 'km',
      goal: 20.0,
      currentValue: 0.0,
      quickAdds: [0.5, 1.0, 2.0],
    ),
  ];
  String _selectedHabitTitle = '';
  List<double> _last7Values = [];
  List<String> _last7Labels = [];
  List<HabitEntry> _monthlyTotals = [];

  @override
  void initState() {
    super.initState();
    _selectedHabitTitle = _habits.first.title;
    SyncService().start();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    await _updateCurrentValues();
    await _loadDataForSelectedHabit(_selectedHabitTitle);
  }

  Future<void> _loadDataForSelectedHabit(String habitTitle) async {
    final entries = await _repo.fetchLast7Days(habitTitle);
    final now = DateTime.now();
    final dailyMap = <String, double>{};
    for (var i = 0; i < 7; i++) {
      final day = DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(Duration(days: 6 - i));
      final key = DateFormat('yyyy-MM-dd').format(day);
      dailyMap[key] = 0.0;
    }
    for (final e in entries) {
      final key = DateFormat('yyyy-MM-dd').format(e.date);
      if (dailyMap.containsKey(key)) dailyMap[key] = dailyMap[key]! + e.value;
    }
    final monthlyEntries = await _repo.fetchMonthlyTotals(habitTitle);
    setState(() {
      _last7Labels = dailyMap.keys.toList();
      _last7Values = dailyMap.values.toList();
      _monthlyTotals = monthlyEntries;
    });
  }

  Future<void> _updateCurrentValues() async {
    for (var i = 0; i < _habits.length; i++) {
      final h = _habits[i];
      final entries = await _repo.fetchLast7Days(h.title);
      final total = entries.fold<double>(0.0, (sum, e) => sum + e.value);
      setState(() {
        _habits[i] = Habit(
          title: h.title,
          unit: h.unit,
          goal: h.goal,
          currentValue: total,
          quickAdds: h.quickAdds,
        );
      });
    }
  }

  Future<void> _onQuickAdd(int index, double val) async {
    final h = _habits[index];
    // 1) fetch existing entries for the past week
    final entries = await _repo.fetchLast7Days(h.title);
    final currentTotal = entries.fold(0.0, (sum, e) => sum + e.value);
    // 2) determine how much we can actually add
    final remaining = (h.goal - currentTotal).clamp(0.0, double.infinity);
    if (remaining <= 0) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('已到达目标，不再累加')));
      return;
    }
    final toAdd = val > remaining ? remaining : val;
    // 3) write the new entry
    await _repo.upsertEntry(HabitEntry(
      id: const Uuid().v4(),
      habitTitle: h.title,
      date: DateTime.now(),
      value: toAdd,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ));
    // 4) reload *all* habits and chart data from the DB
    await _loadAllData();
  }

  Future<void> _clearEntries() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text('Are you sure you want to delete all entries?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await DbHelper().dropAndRecreateEntriesTable();
      await _loadAllData();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('All entries cleared')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Habit Tracking'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            tooltip: 'Reset Database',
            onPressed: () async {
              await DbHelper().dropAndRecreateEntriesTable();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Database file deleted')),
              );
              // 重新打开数据库并刷新数据
              await _loadAllData();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Weekly Habits', style: theme.textTheme.titleLarge),
            const SizedBox(height: 12),
            for (var i = 0; i < _habits.length; i++) ...[
              _buildHabitCard(i, theme),
              const SizedBox(height: 16),
            ],

            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Last 7 Days Trend', style: theme.textTheme.titleLarge),
                DropdownButton<String>(
                  value: _selectedHabitTitle,
                  items:
                  _habits
                      .map(
                        (h) => DropdownMenuItem(
                      value: h.title,
                      child: Text(h.title),
                    ),
                  )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedHabitTitle = value);
                      _loadDataForSelectedHabit(value);
                    }
                  },
                ),
              ],
            ),

            const SizedBox(height: 12),
            InteractiveTrendChart(
              values: _last7Values,
              labels: _last7Labels,
              maxY:
              _habits
                  .firstWhere((h) => h.title == _selectedHabitTitle)
                  .goal,
            ),

            const SizedBox(height: 24),
            Text('Monthly Totals', style: theme.textTheme.titleLarge),
            const SizedBox(height: 12),
            ..._monthlyTotals.map(
                  (e) => Text(
                '${DateFormat('MMMM yyyy').format(e.date)}: ${e.value.toStringAsFixed(1)} ${e.habitTitle}',
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final newHabit = await Navigator.push<Habit>(
            context,
            MaterialPageRoute(
              builder:
                  (_) => EditHabitScreen(
                habit: Habit(
                  title: '',
                  unit: '',
                  goal: 1,
                  currentValue: 0,
                  quickAdds: [1.0],
                ),
              ),
            ),
          );
          if (newHabit != null) {
            setState(() {
              final idx = _habits.indexWhere((h) => h.title == newHabit.title);
              if (idx >= 0)
                _habits[idx] = newHabit;
              else
                _habits.add(newHabit);
              _selectedHabitTitle = newHabit.title;
            });
            await _loadAllData();
          }
        },
        child: const Icon(Icons.add),
        tooltip: 'Add Habit',
      ),
    );
  }

  Widget _buildHabitCard(int index, ThemeData theme) {
    final h = _habits[index];
    final progress = h.goal == 0 ? 0.0 : (h.currentValue / h.goal).clamp(0.0,1.0);

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(h.title, style: theme.textTheme.titleMedium),
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () async {
                    final oldTitle = _habits[index].title;
                    final upd = await Navigator.push<Habit>(
                      context,
                      MaterialPageRoute(builder: (_) => EditHabitScreen(habit: h)),
                    );
                    if (upd != null) {
                      // ② clear entries under the old title, not the new one
                      await _repo.clearEntriesForHabit(oldTitle);
                      // ③ insert a single “base” entry under the new name
                      await _repo.upsertEntry(HabitEntry(
                        id: const Uuid().v4(),
                        habitTitle: upd.title,
                        date: DateTime.now(),
                        value: upd.currentValue,
                        createdAt: DateTime.now(),
                        updatedAt: DateTime.now(),
                      ));
                      // ④ refresh your in-memory list and chart
                      setState(() {
                        _habits[index] = upd;
                        if (upd.title == _selectedHabitTitle) {
                          _loadDataForSelectedHabit(upd.title);
                        }
                      });
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(value: progress),
            const SizedBox(height: 8),
            Text('${h.currentValue.toStringAsFixed(1)}/${h.goal} ${h.unit}'),
            const SizedBox(height: 8),
            // 快捷加值按钮区（保持原样）
            Wrap(
              spacing: 8,
              children: h.quickAdds.map((val) {
                final disabled = h.currentValue >= h.goal;
                return ElevatedButton(
                  onPressed: disabled ? null : () => _onQuickAdd(index, val),
                  child: Text('+${val.toStringAsFixed(1)} ${h.unit}'),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
