import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:uuid/uuid.dart';
import 'db_helper.dart';
import 'habit_entry.dart';
import 'main.dart';
import 'package:flutter/material.dart';

void _showStatus(String message) {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    final ctx = navigatorKey.currentContext;
    if (ctx != null) {
      ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(message)));
    }
  });
}

class SyncService {
  static final SyncService _instance = SyncService._();

  factory SyncService() => _instance;

  SyncService._();

  final _dbHelper = DbHelper();
  final _firestore = FirebaseFirestore.instance;
  final _connectivity = Connectivity();

  /// Call once at app startup to watch connectivity changes
  void start() {
    Future<void> _pushAllEntries() async {
      // ① use the 'database' getter
      final database = await _dbHelper.database;
      final rows = await database.query('entries');
      for (final r in rows) {
        // ② parse ISO-8601 strings back to DateTime
        final entry = HabitEntry(
          id: r['id'] as String,
          habitTitle: r['habitTitle'] as String,
          date: DateTime.parse(r['date'] as String),
          value: (r['value'] as num).toDouble(),
          createdAt: DateTime.parse(r['createdAt'] as String),
          updatedAt: DateTime.parse(r['updatedAt'] as String),
        );
        await _firestore
            .collection('entries')
            .doc(entry.id)
            .set(entry.toJson(), SetOptions(merge: true));
      }
    }

    /// Pull every document from Firestore and upsert it into SQLite
    Future<void> _pullRemoteEntries() async {
      final snapshot = await _firestore.collection('entries').get();
      for (final doc in snapshot.docs) {
        final data = doc.data();

        final entry = HabitEntry(
          id:           doc.id,                                                      // 用文档 ID
          habitTitle:   data['habitTitle']    as String?  ?? 'Unknown Habit',
          date:         (data['date']          as Timestamp?)?.toDate() ?? DateTime.now(),
          value:        (data['value']         as num?)?.toDouble()   ?? 0.0,
          createdAt:    (data['createdAt']    as Timestamp?)?.toDate() ?? DateTime.now(),
          updatedAt:    (data['updatedAt']    as Timestamp?)?.toDate() ?? DateTime.now(),
        );

        await _dbHelper.upsertEntry(entry);
      }
    }

    _connectivity.onConnectivityChanged.listen((status) {
      if (status == ConnectivityResult.none) {
        _showStatus('Offline mode');
      } else {
        _showStatus('Syncing...');
        _pushAllEntries();
        _pullRemoteEntries();
      }
    });

    /// Helper to create a new entry with UUID and timestamps
    HabitEntry createEntry(String habitTitle, DateTime date, double value) {
      final now = DateTime.now();
      return HabitEntry(
        id: const Uuid().v4(),
        habitTitle: habitTitle,
        date: date,
        value: value,
        createdAt: now,
        updatedAt: now,
      );
    }
  }
}
