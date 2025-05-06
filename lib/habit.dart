class Habit {
  String title;
  String unit;             // e.g. 'kg' or 'km'
  double goal;             // weekly target in unit
  double currentValue;     // accumulated this week
  List<double> quickAdds;  // e.g. [0.1, 0.5, 1.0]

  Habit({
    required this.title,
    required this.unit,
    required this.goal,
    required this.currentValue,
    required this.quickAdds,
  });
}
