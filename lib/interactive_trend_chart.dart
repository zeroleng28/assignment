import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class InteractiveTrendChart extends StatefulWidget {
  final List<double> values;
  final List<String> labels;
  final double maxY;

  const InteractiveTrendChart({
    Key? key,
    required this.values,
    required this.labels,
    required this.maxY,
  })  : assert(values.length == labels.length),
        super(key: key);

  @override
  _InteractiveTrendChartState createState() => _InteractiveTrendChartState();
}

class _InteractiveTrendChartState extends State<InteractiveTrendChart> {
  int? _touchedIndex;

  @override
  Widget build(BuildContext context) {
    final spots = widget.values
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value))
        .toList();

    if (spots.isEmpty) {
      return SizedBox(height: 120, child: Center(child: Text('No data')));
    }

    return SizedBox(
      height: 120,
      child: LineChart(
        LineChartData(
          lineTouchData: LineTouchData(
            touchCallback: (evt, resp) {
              if (resp?.lineBarSpots == null) {
                setState(() => _touchedIndex = null);
              } else {
                setState(() => _touchedIndex = resp!.lineBarSpots![0].x.toInt());
              }
            },
            touchTooltipData: LineTouchTooltipData(getTooltipItems: (spots) => spots.map((spot) {
              final label = widget.labels[spot.x.toInt()];
              return LineTooltipItem(
                '$label\n${spot.y.toStringAsFixed(1)}',
                const TextStyle(fontSize: 12, color: Colors.black),
              );
            }).toList()),
          ),
          gridData: FlGridData(show: false),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final idx = value.toInt();
                  final txt = widget.labels[idx].substring(5);
                  return Text(txt, style: TextStyle(fontSize: 10));
                },
                reservedSize: 24,
                interval: 1,
              ),
            ),
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              curveSmoothness: 0.3,
              color: Colors.green,
              barWidth: 3,
              dotData: FlDotData(show: true, getDotPainter: (spot, _, __, idx) {
                final touched = _touchedIndex == idx;
                return FlDotCirclePainter(
                  radius: touched ? 6 : 3,
                  color: Colors.green,
                  strokeColor: touched ? Colors.white : Colors.transparent,
                  strokeWidth: touched ? 2 : 0,
                );
              }),
            ),
          ],
          minX: 0,
          maxX: (spots.length - 1).toDouble(),
          minY: 0,
          maxY: widget.maxY,
        ),
      ),
    );
  }
}
