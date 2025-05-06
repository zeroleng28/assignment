import 'package:cloud_firestore/cloud_firestore.dart';

class HabitEntry {
  final String id;
  final String habitTitle;
  final DateTime date;
  final double value;
  final DateTime createdAt;
  final DateTime updatedAt;

  HabitEntry({
    required this.id,
    required this.habitTitle,
    required this.date,
    required this.value,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'habitTitle': habitTitle,
    'date': Timestamp.fromDate(date),
    'value': value,
    'createdAt': Timestamp.fromDate(createdAt),
    'updatedAt': Timestamp.fromDate(updatedAt),
  };

  factory HabitEntry.fromJson(Map<String, dynamic> json) => HabitEntry(
    id: json['id'] as String,
    habitTitle: json['habitTitle'] as String,
    date: (json['date'] as Timestamp).toDate(),
    value: (json['value'] as num).toDouble(),
    createdAt: (json['createdAt'] as Timestamp).toDate(),
    updatedAt: (json['updatedAt'] as Timestamp).toDate(),
  );
}
