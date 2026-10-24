import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../exposure/exposure_controller.dart';

class AnalyticsPage extends ConsumerStatefulWidget {
  const AnalyticsPage({super.key});

  @override
  ConsumerState<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends ConsumerState<AnalyticsPage> {
  int _selectedPeriodIndex = 0; // 0: 24 Hours, 1: 7 Days

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final exposureState = ref.watch(exposureControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Exposure Analytics', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_outlined),
            tooltip: 'Export Report',
            onPressed: () => context.push('/reports'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Period Toggle
            SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 0, label: Text('24 Hours')),
                ButtonSegment(value: 1, label: Text('7 Days Trend')),
              ],
              selected: {_selectedPeriodIndex},
              onSelectionChanged: (set) {
                setState(() {
                  _selectedPeriodIndex = set.first;
                });
              },
            ),
            const SizedBox(height: 16),

            // Key Statistics Grid
            _buildStatsSummaryGrid(theme, exposureState),
            const SizedBox(height: 16),

            // Chart Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              child: Padding(
                padding: const EdgeInsets.all(18.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _selectedPeriodIndex == 0 ? '24-Hour PM2.5 Trend (µg/m³)' : '7-Day Daily Average Exposure',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'WHO Target: 15 µg',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.green),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 200,
                      child: _selectedPeriodIndex == 0
                          ? _buildHourlyLineChart(theme, exposureState)
                          : _buildWeeklyBarChart(theme),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Peak Exposure Windows analysis
            _buildPeakHoursAnalysis(theme),
            const SizedBox(height: 16),

            // Health Insights Recommendation
            _buildActionableAdviceCard(theme),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsSummaryGrid(ThemeData theme, ExposureState state) {
    return Row(
      children: [
        Expanded(
          child: Column(
            children: [
              _statCard(
                title: 'Peak PM2.5',
                value: '78 µg/m³',
                caption: 'Secondhand Spike',
                color: Colors.orange,
              ),
              const SizedBox(height: 10),
              _statCard(
                title: 'Safe Air Ratio',
                value: '89%',
                caption: '21.4 hrs in safe zone',
                color: Colors.green,
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            children: [
              _statCard(
                title: 'Average Exposure',
                value: '14.2 µg/m³',
                caption: 'Within safe norm',
                color: Colors.teal,
              ),
              const SizedBox(height: 10),
              _statCard(
                title: 'Smoke Events',
                value: '${state.incidents.length}',
                caption: 'Today incidents',
                color: Colors.purple,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _statCard({
    required String title,
    required String value,
    required String caption,
    required Color color,
  }) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 11, color: Colors.grey)),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
            ),
            Text(caption, style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
          ],
        ),
      ),
    );
  }

  Widget _buildHourlyLineChart(ThemeData theme, ExposureState state) {
    final readings = state.recentReadings;
    List<FlSpot> spots = [];

    for (int i = 0; i < readings.length; i++) {
      spots.add(FlSpot(i.toDouble(), readings[i].pm25));
    }

    if (spots.isEmpty) {
      spots = [const FlSpot(0, 10), const FlSpot(5, 12), const FlSpot(12, 65), const FlSpot(23, 14)];
    }

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 25,
          getDrawingHorizontalLine: (val) => FlLine(
            color: Colors.grey.withValues(alpha: 0.15),
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              interval: 25,
              getTitlesWidget: (val, meta) => Text(
                '${val.toInt()}',
                style: const TextStyle(fontSize: 10, color: Colors.grey),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 6,
              getTitlesWidget: (val, meta) {
                switch (val.toInt()) {
                  case 0:
                    return const Text('12AM', style: TextStyle(fontSize: 9, color: Colors.grey));
                  case 6:
                    return const Text('6AM', style: TextStyle(fontSize: 9, color: Colors.grey));
                  case 12:
                    return const Text('12PM', style: TextStyle(fontSize: 9, color: Colors.grey));
                  case 18:
                    return const Text('6PM', style: TextStyle(fontSize: 9, color: Colors.grey));
                  default:
                    return const SizedBox.shrink();
                }
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        minY: 0,
        maxY: 100,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: const Color(0xFF0D9488),
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFF0D9488).withValues(alpha: 0.35),
                  const Color(0xFF0D9488).withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyBarChart(ThemeData theme) {
    final dailyAverages = [12.4, 18.2, 14.0, 32.5, 11.8, 44.2, 16.0];
    final days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: 55,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 15,
          getDrawingHorizontalLine: (val) => FlLine(
            color: Colors.grey.withValues(alpha: 0.15),
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              interval: 15,
              getTitlesWidget: (val, meta) => Text(
                '${val.toInt()}',
                style: const TextStyle(fontSize: 10, color: Colors.grey),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (val, meta) {
                final idx = val.toInt();
                if (idx >= 0 && idx < days.length) {
                  return Text(days[idx], style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold));
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        barGroups: List.generate(dailyAverages.length, (i) {
          final avg = dailyAverages[i];
          final color = avg > 30 ? Colors.orange : (avg > 15 ? Colors.amber : Colors.green);
          return BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: avg,
                color: color,
                width: 16,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildPeakHoursAnalysis(ThemeData theme) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: const Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.schedule, size: 18, color: Color(0xFF0D9488)),
                SizedBox(width: 8),
                Text(
                  'Peak Smoke Vulnerability Windows',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ],
            ),
            SizedBox(height: 10),
            Text(
              'Your highest particulate spikes consistently occur between 1:00 PM – 2:30 PM (lunch transit / outdoor smoker proximity). Consider alternative transit corridors.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionableAdviceCard(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0D9488).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF0D9488).withValues(alpha: 0.3)),
      ),
      child: const Row(
        children: [
          Icon(Icons.tips_and_updates_outlined, color: Color(0xFF0D9488), size: 24),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Your average exposure decreased by 18% compared to last week. Keep maintaining distance from designated smoking zones.',
              style: TextStyle(fontSize: 12, color: Color(0xFF0D9488), fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
