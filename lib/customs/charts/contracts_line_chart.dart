import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../app_colors.dart';

class ContractsLineChart extends StatelessWidget {
  final List<Map<String, dynamic>> workers;
  final Color baseColor;

  const ContractsLineChart({
    super.key,
    required this.workers,
    this.baseColor = Colors.indigo,
  });

  @override
  Widget build(BuildContext context) {
    // We want the last 6 months including current
    final now = DateTime.now();
    final Map<String, int> monthlyAgrupation = {};
    final List<String> monthKeys = []; // Format YYYY-MM

    for (int i = 5; i >= 0; i--) {
      final month = DateTime(now.year, now.month - i, 1);
      final key = DateFormat('yyyy-MM').format(month);
      monthKeys.add(key);
      monthlyAgrupation[key] = 0;
    }

    // Process workers
    for (var worker in workers) {
      final ultimoContrato = worker['ultimoContrato'];
      if (ultimoContrato is Timestamp) {
        final date = ultimoContrato.toDate();
        final key = DateFormat('yyyy-MM').format(date);
        if (monthlyAgrupation.containsKey(key)) {
          monthlyAgrupation[key] = monthlyAgrupation[key]! + 1;
        }
      }
    }

    final maxY = monthlyAgrupation.values
        .fold<int>(0, (max, count) => count > max ? count : max);

    final spots = List.generate(monthKeys.length, (index) {
      final count = monthlyAgrupation[monthKeys[index]]!;
      return FlSpot(index.toDouble(), count.toDouble());
    });

    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 18,
                decoration: BoxDecoration(
                  color: baseColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Altas de Contratos (6 Meses)',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: LineChart(
              LineChartData(
                minX: 0,
                maxX: (monthKeys.length - 1).toDouble(),
                minY: 0,
                maxY: (maxY + 5).toDouble(),
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) => Colors.blueGrey.shade800,
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        return LineTooltipItem(
                          '${spot.y.toInt()} contratos',
                          const TextStyle(
                              color: Colors.white, fontWeight: FontWeight.bold),
                        );
                      }).toList();
                    },
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.grey.shade200,
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 32,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= monthKeys.length) {
                          return const SizedBox.shrink();
                        }
                        // Format key to a short month name (e.g. "Ene", "Feb")
                        final key = monthKeys[index];
                        final parts = key.split('-');
                        final dt =
                            DateTime(int.parse(parts[0]), int.parse(parts[1]));
                        final label = DateFormat('MMM', 'es_CL').format(dt);
                        return Padding(
                          padding: const EdgeInsets.only(top: 10.0),
                          child: Text(
                            label.toUpperCase(),
                            style: const TextStyle(
                                color: AppColors.textBody,
                                fontWeight: FontWeight.w700,
                                fontSize: 12.5),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 32,
                      getTitlesWidget: (value, meta) {
                        if (value == 0) return const SizedBox.shrink();
                        // Only show integers
                        if (value % 1 != 0) return const SizedBox.shrink();
                        return Text(
                          value.toInt().toString(),
                          style: const TextStyle(
                              color: AppColors.textBody,
                              fontWeight: FontWeight.w700,
                              fontSize: 12.5),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: baseColor,
                    barWidth: 4,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 5,
                          color: Colors.white,
                          strokeWidth: 3,
                          strokeColor: baseColor,
                        );
                      },
                    ),
                    // Relleno parejo en vez de degradado: el desvanecido hacia
                    // el fondo dejaba el area a medio pintar.
                    belowBarData: BarAreaData(
                      show: true,
                      color: baseColor.withOpacity(0.18),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: appCardDecoration(),
      child: child,
    );
  }
}
