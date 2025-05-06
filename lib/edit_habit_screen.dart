import 'package:flutter/material.dart';
import 'habit.dart';
import 'dart:math';

final List<TextEditingController> _quickAddCtrls = [];

class EditHabitScreen extends StatefulWidget {
  final Habit habit;

  const EditHabitScreen({super.key, required this.habit});

  @override
  State<EditHabitScreen> createState() => _EditHabitScreenState();
}

class _EditHabitScreenState extends State<EditHabitScreen> {
  late TextEditingController _titleCtrl;
  late TextEditingController _goalCtrl;
  late TextEditingController _unitCtrl;
  double _currentValue = 0.0;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.habit.title);
    _unitCtrl = TextEditingController(text: widget.habit.unit);
    _goalCtrl = TextEditingController(text: widget.habit.goal.toString());
    _currentValue = widget.habit.currentValue;
    _quickAddCtrls.clear();
    for (final val in widget.habit.quickAdds) {
      _quickAddCtrls.add(TextEditingController(text: val.toString()));
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _unitCtrl.dispose();
    _goalCtrl.dispose();
    super.dispose();
  }

  void _save() {
    final parsedGoal = double.tryParse(_goalCtrl.text) ?? widget.habit.goal;
    final clampedCurrent = _currentValue.clamp(0.0, parsedGoal);

    final updated = Habit(
      title: _titleCtrl.text,
      unit: _unitCtrl.text,
      goal: parsedGoal,
      currentValue: clampedCurrent,
      quickAdds: _quickAddCtrls
          .map((ctrl) => double.tryParse(ctrl.text) ?? 0.0)
          .toList(),
    );
    Navigator.of(context).pop(updated);
  }

  @override
  Widget build(BuildContext context) {
    final parsedGoal = double.tryParse(_goalCtrl.text) ?? widget.habit.goal;
    final maxVal = max(parsedGoal, _currentValue);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Habit'),
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text('SAVE', style: TextStyle(color: Colors.black)),
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _titleCtrl,
              decoration: const InputDecoration(labelText: 'Habit Name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _unitCtrl,
              decoration: const InputDecoration(
                  labelText: 'Unit (e.g. kg, km)'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _goalCtrl,
              decoration: const InputDecoration(labelText: 'Weekly Goal'),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                const Text('Current Value:'),
                Expanded(
                  child: Slider(
                    value: _currentValue,
                    min: 0,
                    max: maxVal,
                    divisions: 100,
                    label: _currentValue.toStringAsFixed(1),
                    onChanged: (v) => setState(() => _currentValue = v),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text('Quick Add Buttons'),
            ..._quickAddCtrls.map((ctrl) =>
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: TextField(
                    controller: ctrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Add Value'),
                  ),
                )).toList(),
            Text('${_currentValue.toStringAsFixed(1)} ${_unitCtrl.text}'),
          ],
        ),
      ),
    );
  }
}
