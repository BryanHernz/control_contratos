import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../app_colors.dart';

class GenericPieChart extends StatefulWidget {
  final String title;
  final Map<String, int> data;

  const GenericPieChart({
    super.key,
    required this.title,
    required this.data,
  });

  @override
  State<GenericPieChart> createState() => _GenericPieChartState();
}

class _GenericPieChartState extends State<GenericPieChart> {
  int touchedIndex = -1;

  // Premium cool-toned palette complementing the app's 'primario' (blueGrey) and 'secundario' (dark tone)
  static const List<Color> colorPalette = [
    Color(0xFF26A69A), // Teal 400
    Color(0xFF5C6BC0), // Indigo 400
    Color(0xFF29B6F6), // Light Blue 400
    Color(0xFF78909C), // Blue Grey 400
    Color(0xFF4DB6AC), // Teal 300
    Color(0xFF7986CB), // Indigo 300
    Color(0xFF4FC3F7), // Light Blue 300
    Color(0xFF90A4AE), // Blue Grey 300
  ];

  @override
  Widget build(BuildContext context) {
    if (widget.data.isEmpty) {
      return _buildCard(
          child: const Center(
              child:
                  Text('Sin datos.', style: TextStyle(color: Colors.black45))));
    }

    final sorted = widget.data.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final top5 = sorted.take(5).toList();
    final othersTotal = sorted.skip(5).fold<int>(0, (sum, e) => sum + e.value);

    final displayEntries = [
      ...top5,
      if (othersTotal > 0) MapEntry('Otros', othersTotal),
    ];

    final total = displayEntries.fold<int>(0, (sum, e) => sum + e.value);

    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title with accent line
          Row(
            children: [
              Container(
                width: 4,
                height: 18,
                decoration: BoxDecoration(
                  color: colorPalette[0],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  widget.title,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Row(
              children: [
                const SizedBox(width: 15),
                // Donut with total in center
                SizedBox(
                  width: 140,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      PieChart(
                        PieChartData(
                          pieTouchData: PieTouchData(
                            touchCallback: (FlTouchEvent event, resp) {
                              setState(() {
                                if (!event.isInterestedForInteractions ||
                                    resp == null ||
                                    resp.touchedSection == null) {
                                  touchedIndex = -1;
                                  return;
                                }
                                touchedIndex =
                                    resp.touchedSection!.touchedSectionIndex;
                              });
                            },
                          ),
                          borderData: FlBorderData(show: false),
                          sectionsSpace: 3,
                          centerSpaceRadius: 36,
                          sections: _buildSections(displayEntries, total),
                        ),
                      ),
                      // Center label showing total count
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '$total',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF37474F),
                            ),
                          ),
                          const Text(
                            'total',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textMuted,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 50),
                // Legend
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: List.generate(displayEntries.length, (index) {
                      final item = displayEntries[index];
                      final isTouched = index == touchedIndex;
                      final pct = (item.value / total * 100).toStringAsFixed(0);
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        margin: const EdgeInsets.symmetric(vertical: 3),
                        padding: isTouched
                            ? const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2)
                            : EdgeInsets.zero,
                        decoration: isTouched
                            ? BoxDecoration(
                                color: colorPalette[index % colorPalette.length]
                                    .withOpacity(0.08),
                                borderRadius: BorderRadius.circular(6),
                              )
                            : null,
                        child: Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color:
                                    colorPalette[index % colorPalette.length],
                              ),
                            ),
                            const SizedBox(width: 7),
                            Expanded(
                              child: Text(
                                item.key,
                                style: TextStyle(
                                  // Rajdhani a 11px con peso normal se pierde;
                                  // la leyenda es el texto mas chico de la
                                  // vista y necesita cuerpo.
                                  fontSize: 12.5,
                                  fontWeight: isTouched
                                      ? FontWeight.w800
                                      : FontWeight.w600,
                                  color: AppColors.textBody,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '$pct%',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: isTouched
                                    ? FontWeight.w800
                                    : FontWeight.w700,
                                color:
                                    colorPalette[index % colorPalette.length],
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ),
                ),
                const SizedBox(width: 15),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<PieChartSectionData> _buildSections(
      List<MapEntry<String, int>> entries, int total) {
    return List.generate(entries.length, (i) {
      final isTouched = i == touchedIndex;
      final value = entries[i].value;
      final pct = (value / total * 100).toStringAsFixed(1);
      final baseColor = colorPalette[i % colorPalette.length];
      return PieChartSectionData(
        // Color plano. El degradado que habia iba del 95% al 15% de opacidad,
        // asi que la parte baja de cada gajo se desvanecia contra el blanco y
        // los sectores dejaban de leerse como sectores.
        color: baseColor,
        value: value.toDouble(),
        title: isTouched ? '$pct%' : '',
        radius: isTouched ? 54.0 : 46.0,
        titleStyle: const TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w800,
          color: Colors.white,
        ),
      );
    });
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: appCardDecoration(),
      child: child,
    );
  }
}
