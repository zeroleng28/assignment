import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'habit_entry.dart';

class DbHelper {
  static final DbHelper _instance = DbHelper._();
  factory DbHelper() => _instance;
  DbHelper._();

  static const _dbName = 'habits.db';
  static const _dbVersion = 6;

  Future<void> deleteDatabaseFile() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);
    await deleteDatabase(path);
  }

  Database? _database;
  Future<Database> get database async {
    if (_database != null) return _database!;
    final path = join(await getDatabasesPath(), _dbName);
    _database = await openDatabase(
      path,
      version: _dbVersion,
      onConfigure: _onConfigure,
      onCreate:    _onCreate,
      onUpgrade:   _onUpgrade,
    );
    return _database!;
  }

  Future<void> clearEntriesForHabit(String habitTitle) async {
    final db = await database;
    final cutoff = DateTime.now()
        .subtract(const Duration(days: 6))
        .toIso8601String();
    await db.delete(
      'entries',
      where: 'habitTitle = ? AND date >= ?',
      whereArgs: [habitTitle, cutoff],
    );
  }

  /// Inspect existing table and migrate only if 'date' is not TEXT.
  Future<void> _onConfigure(Database db) async {
    final info = await db.rawQuery("PRAGMA table_info('entries')");
    // If table exists and date column is not TEXT, migrate:
    if (info.isNotEmpty && !info.any((c) => c['name'] == 'date' && c['type'] == 'TEXT')) {
      await db.execute('ALTER TABLE entries RENAME TO entries_old');
      await _onCreate(db, _dbVersion);
      await db.execute('''
        INSERT INTO entries (id, habitTitle, date, value, createdAt, updatedAt)
        SELECT id, habitTitle, date, value, createdAt, updatedAt
        FROM entries_old;
      ''');
      await db.execute('DROP TABLE entries_old');
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE entries (
        id         TEXT PRIMARY KEY,
        habitTitle TEXT,
        date       TEXT,
        value      REAL,
        createdAt  TEXT,
        updatedAt  TEXT
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldV, int newV) async {
    await db.execute('DROP TABLE IF EXISTS entries');
    await db.execute('''
    CREATE TABLE entries (
      id         TEXT PRIMARY KEY,
      habitTitle TEXT,
      date       TEXT,
      value      REAL,
      createdAt  TEXT,
      updatedAt  TEXT
    )
  ''');
  }


  /// Insert or replace an entry, storing all dates as ISO-8601 strings.
  Future<void> upsertEntry(HabitEntry entry) async {
    final db = await database;
    await db.insert(
      'entries',
      {
        'id':        entry.id,
        'habitTitle': entry.habitTitle,
        'date':      entry.date.toIso8601String(),
        'value':     entry.value,
        'createdAt': entry.createdAt.toIso8601String(),
        'updatedAt': entry.updatedAt.toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Fetch last 7 days for the given habit, parsing ISO strings back to DateTime.
  Future<List<HabitEntry>> fetchLast7Days(String habitTitle) async {
    final db = await database;
    final cutoff = DateTime.now()
        .subtract(const Duration(days: 6))
        .toIso8601String();

    final rows = await db.query(
      'entries',
      where: 'habitTitle = ? AND date >= ?',
      whereArgs: [habitTitle, cutoff],
      orderBy: 'date ASC',
    );

    return rows.map((r) {
      return HabitEntry(
        id:         r['id'] as String,
        habitTitle: r['habitTitle'] as String,
        date:       DateTime.parse(r['date'] as String),
        value:      (r['value'] as num).toDouble(),
        createdAt:  DateTime.parse(r['createdAt'] as String),
        updatedAt:  DateTime.parse(r['updatedAt'] as String),
      );
    }).toList();
  }

  /// Group entries by month (YYYY-MM) and sum values.
  Future<List<HabitEntry>> fetchMonthlyTotals(String habitTitle) async {
    final db = await database;
    final rows = await db.rawQuery(
      '''
      SELECT
        substr(date,1,7) AS ym,
        SUM(value)      AS total
      FROM entries
      WHERE habitTitle = ?
      GROUP BY ym
      ORDER BY ym ASC
      ''',
      [habitTitle],
    );

    return rows.map((r) {
      final ym = r['ym'] as String;      // e.g. "2025-05"
      final parts = ym.split('-');
      final year  = int.parse(parts[0]);
      final month = int.parse(parts[1]);

      return HabitEntry(
        id:         '$habitTitle-$ym',
        habitTitle: habitTitle,
        date:       DateTime(year, month),
        value:      (r['total'] as num).toDouble(),
        createdAt:  DateTime.now(),
        updatedAt:  DateTime.now(),
      );
    }).toList();
  }

  Future<void> clearEntries() async {
    final db = await database;
    await db.delete('entries');
  }

  Future<void> dropAndRecreateEntriesTable() async {
    final db = await database;
    await db.execute('DROP TABLE IF EXISTS entries');
    await db.execute('''
    CREATE TABLE entries (
      id         TEXT PRIMARY KEY,
      habitTitle TEXT,
      date       TEXT,
      value      REAL,
      createdAt  TEXT,
      updatedAt  TEXT
    )
  ''');
  }
}
