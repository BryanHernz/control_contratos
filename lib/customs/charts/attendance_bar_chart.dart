import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../app_colors.dart';
import '../../services/attendance_service.dart';
import '../../services/firestore_db.dart';

class AttendanceBarChart extends StatelessWidget {
  const AttendanceBarChart({super.key});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    // 6 days ago + today = 7 days
    final weekAgo = now.subtract(const Duration(days: 6));
    final weekAgoKey = AttendanceService.dateKeyFrom(weekAgo);

    const accentColor = Color(0xFF5C6BC0);
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
                  color: accentColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Asistencia (Últimos 7 días)',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: db
                  .collection('Asistencias')
                  .where('dateKey', isGreaterThanOrEqualTo: weekAgoKey)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                // Prepare a map of all 7 days with 0 attendance initially
                final Map<String, int> weekData = {};
                for (int i = 6; i >= 0; i--) {
                  final day = now.subtract(Duration(days: i));
                  final key = AttendanceService.dateKeyFrom(day);
                  weekData[key] = 0;
                }

                // Fill with actual data
                for (var doc in snapshot.data!.docs) {
                  final data = doc.data() as Map<String, dynamic>;
                  final dateKey = data['dateKey'] as String?;
                  if (dateKey != null && weekData.containsKey(dateKey)) {
                    final presentes = data['presentes'] as Map?;
                    weekData[dateKey] = presentes?.length ?? 0;
                  }
                }

                final entries = weekData.entries.toList();

                // Compute max Y for the chart scale
                final maxY = entries.fold<int>(
                    0, (max, e) => e.value > max ? e.value : max);

                return BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: (maxY + 5).toDouble(),
                    barTouchData: BarTouchData(
                      enabled: true,
                      touchTooltipData: BarTouchTooltipData(
                        getTooltipColor: (_) => Colors.blueGrey.shade800,
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          return BarTooltipItem(
                            '${rod.toY.toInt()} presentes',
                            const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                          );
                        },
                      ),
                    ),
                    titlesData: FlTitlesData(
                      show: true,
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (double value, TitleMeta meta) {
                            final index = value.toInt();
                            if (index < 0 || index >= entries.length) {
                              return const SizedBox.shrink();
                            }
                            // Parse 'yyyy-MM-dd' to get day of week
                            final dateKey = entries[index].key;
                            final dateParts = dateKey.split('-');
                            if (dateParts.length == 3) {
                              final dt = DateTime(
                                  int.parse(dateParts[0]),
                                  int.parse(dateParts[1]),
                                  int.parse(dateParts[2]));
                              // Mon, Tue, Wed, etc. -> L, M, M, J, V, S, D
                              final format = DateFormat('E', 'es_CL')
                                  .format(dt)
                                  .toUpperCase();
                              return Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  format.substring(
                                      0, 1), // "L" instead of "LUN"
                                  style: const TextStyle(
                                      color: AppColors.textBody,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13),
                                ),
                              );
                            }
                            return const SizedBox.shrink();
                          },
                          reservedSize: 28,
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 32,
                          getTitlesWidget: (value, meta) {
                            if (value == 0) return const SizedBox.shrink();
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
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: 5,
                      getDrawingHorizontalLine: (value) {
                        return FlLine(
                          color: Colors.grey.shade200,
                          strokeWidth: 1,
                        );
                      },
                    ),
                    borderData: FlBorderData(show: false),
                    barGroups: List.generate(entries.length, (i) {
                      return BarChartGroupData(
                        x: i,
                        barRods: [
                          BarChartRodData(
                            toY: entries[i].value.toDouble(),
                            // Color plano: el degradado hacia el claro desdibujaba
                            // la base de la barra contra el fondo.
                            color: const Color(0xFF5C6BC0),
                            width: 18,
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(6)),
                          ),
                        ],
                      );
                    }),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: appCardDecoration(),
      child: child,
    );
  }
}
