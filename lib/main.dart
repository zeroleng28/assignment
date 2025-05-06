import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'track_habit_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'sync_service.dart';
import 'db_helper.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  SyncService().start();
  runApp(const HabitTrackerApp());
}

class HabitTrackerApp extends StatelessWidget {
  const HabitTrackerApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EcoLife Habit Tracker',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.green,
        // ← add this so all your ElevatedButtons are green
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,       // button fill
            foregroundColor: Colors.black,       // text/icon color
          ),
        ),
      ),
      navigatorKey: navigatorKey,
      home: const TrackHabitScreen(),
    );
  }
}

Future<void> seedTestData() async {
  await FirebaseFirestore.instance
      .collection('entries')
      .add({
    'habitTitle': 'Reduce Plastic',
    'date': Timestamp.now(),
    'value': 0.42,
  });
  print('⚡️ Seeded one test entry');
}
