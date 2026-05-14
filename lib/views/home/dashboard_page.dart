// ignore_for_file: avoid_types_as_parameter_names
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../customs/constants_values.dart';
import '../../services/attendance_service.dart';
import '../../customs/charts/generic_pie_chart.dart';
import '../../customs/charts/attendance_bar_chart.dart';
import '../../customs/charts/contracts_line_chart.dart';
import '../../customs/widgets/page_header.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final monthStart = DateTime(now.year, now.month, 1);

    return ColoredBox(
      color: const Color(0xFFF0F2F5),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────────────────
            _DashboardHeader(now: now),

            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Métricas ─────────────────────────────────────
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isDesktop = constraints.maxWidth >= 800;
                      final crossCount = isDesktop ? 3 : 1;

                      return Wrap(
                        spacing: 16,
                        runSpacing: 16,
                        children: [
                          StreamBuilder<QuerySnapshot>(
                            stream: FirebaseFirestore.instance
                                .collection('Trabajadores')
                                .where('activo', isEqualTo: true)
                                .snapshots(),
                            builder: (ctx, snap) {
                              final total = snap.data?.docs.length ?? 0;
                              return _MetricCard(
                                icon: Icons.people_rounded,
                                label: 'Trabajadores activos',
                                value: '$total',
                                subtitle: 'Con contrato activo',
                                accentColor: const Color(0xFF546E7A),
                                fraction: 1 / crossCount,
                                maxWidth: constraints.maxWidth,
                              );
                            },
                          ),
                          StreamBuilder<List<Map<String, dynamic>>>(
                            stream: AttendanceService.listenPresents(
                                today, 'GENERAL'),
                            builder: (ctx, snap) {
                              final count = snap.data?.length ?? 0;
                              return _MetricCard(
                                icon: Icons.how_to_reg_rounded,
                                label: 'Presentes hoy',
                                value: '$count',
                                subtitle: DateFormat('EEEE d MMM', 'es_CL')
                                    .format(now),
                                accentColor: const Color(0xFF00897B),
                                fraction: 1 / crossCount,
                                maxWidth: constraints.maxWidth,
                              );
                            },
                          ),
                          StreamBuilder<QuerySnapshot>(
                            stream: FirebaseFirestore.instance
                                .collection('Trabajadores')
                                .where('ultimoContrato',
                                    isGreaterThanOrEqualTo:
                                        Timestamp.fromDate(monthStart))
                                .snapshots(),
                            builder: (ctx, snap) {
                              final count = snap.data?.docs.length ?? 0;
                              return _MetricCard(
                                icon: Icons.description_rounded,
                                label: 'Contratos este mes',
                                value: '$count',
                                subtitle: DateFormat('MMMM yyyy', 'es_CL')
                                    .format(now),
                                accentColor: const Color(0xFF5C6BC0),
                                fraction: 1 / crossCount,
                                maxWidth: constraints.maxWidth,
                              );
                            },
                          ),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 32),

                  // ── Gráficos ─────────────────────────────────────
                  _SectionHeader(
                    title: 'Analítica',
                    icon: Icons.bar_chart_rounded,
                  ),
                  const SizedBox(height: 14),

                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('Trabajadores')
                        .where('activo', isEqualTo: true)
                        .snapshots(),
                    builder: (ctx, snap) {
                      if (!snap.hasData) {
                        return _ChartLoadingPlaceholder();
                      }

                      final workers = snap.data!.docs
                          .map((e) => e.data() as Map<String, dynamic>)
                          .toList();

                      final placesData = <String, int>{};
                      final taskData = <String, int>{};

                      for (var w in workers) {
                        final l = (w['lugar'] ?? 'Sin asignar').toString();
                        final t = (w['labor'] ?? 'Sin asignar').toString();
                        placesData[l] = (placesData[l] ?? 0) + 1;
                        taskData[t] = (taskData[t] ?? 0) + 1;
                      }

                      return LayoutBuilder(
                        builder: (context, constraints) {
                          final isDesktop = constraints.maxWidth >= 800;
                          final chartWidth = isDesktop
                              ? (constraints.maxWidth - 16) / 2
                              : constraints.maxWidth;

                          final renderPlacesData = placesData.length <= 1
                              ? {
                                  'Sede Central (Demo)': 45,
                                  'Sucursal Norte (Demo)': 25,
                                  'Planta Ind. (Demo)': 15,
                                  'Oficina Sur (Demo)': 10,
                                  'Otros (Demo)': 5
                                }
                              : placesData;

                          final renderTaskData = taskData.length <= 1
                              ? {
                                  'Temporera (Demo)': 40,
                                  'Admin. (Demo)': 20,
                                  'Supervisor (Demo)': 15,
                                  'Mantención (Demo)': 15,
                                  'Logística (Demo)': 10
                                }
                              : taskData;

                          return Wrap(
                            spacing: 16,
                            runSpacing: 16,
                            children: [
                              SizedBox(
                                width: chartWidth,
                                height: 290,
                                child: GenericPieChart(
                                  title: 'Por Establecimiento',
                                  data: renderPlacesData,
                                ),
                              ),
                              SizedBox(
                                width: chartWidth,
                                height: 290,
                                child: GenericPieChart(
                                  title: 'Por Labor',
                                  data: renderTaskData,
                                ),
                              ),
                              SizedBox(
                                width: chartWidth,
                                height: 290,
                                child: ContractsLineChart(
                                  workers: workers,
                                  baseColor: Colors.teal.shade400,
                                ),
                              ),
                              SizedBox(
                                width: chartWidth,
                                height: 290,
                                child: const AttendanceBarChart(),
                              ),
                            ],
                          );
                        },
                      );
                    },
                  ),

                  const SizedBox(height: 32),

                  // ── Últimos contratos ─────────────────────────────
                  _SectionHeader(
                    title: 'Últimos contratos generados',
                    icon: Icons.assignment_turned_in_outlined,
                  ),
                  const SizedBox(height: 14),

                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('Trabajadores')
                        .where('ultimoContrato',
                            isGreaterThan: Timestamp(0, 0))
                        .orderBy('ultimoContrato', descending: true)
                        .limit(5)
                        .snapshots(),
                    builder: (ctx, snap) {
                      if (!snap.hasData) return _ListLoadingPlaceholder();
                      if (snap.data!.docs.isEmpty) {
                        return _EmptyState(
                            icon: Icons.inbox_outlined,
                            message: 'Ningún contrato generado aún.');
                      }
                      return _StyledCard(
                        child: ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: snap.data!.docs.length,
                          separatorBuilder: (_, __) => Divider(
                            height: 1,
                            color: Colors.grey.shade100,
                            indent: 72,
                          ),
                          itemBuilder: (_, i) {
                            final doc = snap.data!.docs[i];
                            final data = doc.data() as Map<String, dynamic>;
                            final nombres = (data['nombres'] ?? '').toString();
                            final apellidos =
                                (data['apellidos'] ?? '').toString();
                            final ts = data['ultimoContrato'];
                            String fecha = '—';
                            if (ts is Timestamp) {
                              fecha = DateFormat('dd/MM/yyyy · HH:mm', 'es')
                                  .format(ts.toDate());
                            }
                            return ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 6),
                              leading: _InitialsAvatar(
                                name: nombres.isNotEmpty ? nombres : '?',
                                color: primario,
                              ),
                              title: Text(
                                '$apellidos $nombres'.toUpperCase(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                  letterSpacing: 0.3,
                                ),
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 3),
                                child: Row(
                                  children: [
                                    Icon(Icons.schedule_rounded,
                                        size: 12,
                                        color: Colors.grey.shade400),
                                    const SizedBox(width: 4),
                                    Text(
                                      fecha,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              trailing: Icon(Icons.chevron_right_rounded,
                                  color: Colors.grey.shade300),
                            );
                          },
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 32),

                  // ── Actividad reciente ────────────────────────────
                  _SectionHeader(
                    title: 'Actividad reciente',
                    icon: Icons.history_rounded,
                  ),
                  const SizedBox(height: 14),

                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('Auditoria')
                        .orderBy('timestamp', descending: true)
                        .limit(8)
                        .snapshots(),
                    builder: (ctx, snap) {
                      if (!snap.hasData) return _ListLoadingPlaceholder();
                      if (snap.data!.docs.isEmpty) {
                        return _EmptyState(
                            icon: Icons.history_rounded,
                            message: 'Sin actividad registrada.');
                      }
                      return _StyledCard(
                        child: ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: snap.data!.docs.length,
                          separatorBuilder: (_, __) => Divider(
                            height: 1,
                            color: Colors.grey.shade100,
                            indent: 72,
                          ),
                          itemBuilder: (_, i) {
                            final doc = snap.data!.docs[i];
                            final data = doc.data() as Map<String, dynamic>;
                            final accion = (data['accion'] ?? '').toString();
                            final usuario = (data['usuario'] ?? '').toString();
                            final nombre = (data['nombre'] ?? '').toString();
                            final ts = data['timestamp'];
                            String fecha = '—';
                            if (ts is Timestamp) {
                              fecha = DateFormat('dd/MM · HH:mm', 'es')
                                  .format(ts.toDate());
                            }
                            return ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 6),
                              leading: CircleAvatar(
                                backgroundColor: Colors.blueGrey.shade50,
                                child: Icon(Icons.history_rounded,
                                    color: primario, size: 18),
                              ),
                              title: Text(
                                nombre.isNotEmpty ? nombre : accion,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(
                                  '$accion · $usuario',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey.shade400,
                                  ),
                                ),
                              ),
                              trailing: Text(
                                fecha,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade400,
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 36),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────
class _DashboardHeader extends StatelessWidget {
  final DateTime now;
  const _DashboardHeader({required this.now});

  @override
  Widget build(BuildContext context) {
    final diaSemana =
        DateFormat('EEEE', 'es_CL').format(now); // "jueves"
    final fechaCorta =
        DateFormat('d \'de\' MMMM, yyyy', 'es_CL').format(now);

    return PageHeader(
      title: 'Dashboard',
      subtitle: 'Control de Contratos',
      icon: Icons.dashboard_rounded,
      bottomWidget: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.15), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.calendar_today_rounded,
                size: 13, color: Colors.white.withOpacity(0.8)),
            const SizedBox(width: 7),
            Text(
              '${diaSemana[0].toUpperCase()}${diaSemana.substring(1)}, $fechaCorta',
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 12,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Section header ────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  const _SectionHeader({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: primario,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Icon(icon, color: primario, size: 18),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Colors.blueGrey.shade800,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }
}

// ── Metric card ───────────────────────────────────────────────────────────
class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.fraction,
    required this.maxWidth,
    required this.accentColor,
    this.subtitle,
  });

  final IconData icon;
  final String label;
  final String value;
  final double fraction;
  final double maxWidth;
  final Color accentColor;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final width = maxWidth >= 800 ? (maxWidth - 56) * fraction : maxWidth;
    return SizedBox(
      width: width,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.black.withOpacity(0.05), width: 1),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              // Ghost watermark icon
              Positioned(
                right: -8,
                bottom: -8,
                child: Icon(
                  icon,
                  size: 80,
                  color: accentColor.withOpacity(0.06),
                ),
              ),
              // Accent bar
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: Container(width: 5, color: accentColor),
              ),
              // Content
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 16, 18),
                child: Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: accentColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icon, color: accentColor, size: 22),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            label,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade500,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.2,
                            ),
                          ),
                          const SizedBox(height: 3),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 400),
                            transitionBuilder: (child, anim) =>
                                FadeTransition(
                                    opacity: anim,
                                    child: SlideTransition(
                                      position: Tween<Offset>(
                                        begin: const Offset(0, 0.3),
                                        end: Offset.zero,
                                      ).animate(anim),
                                      child: child,
                                    )),
                            child: Text(
                              value,
                              key: ValueKey(value),
                              style: TextStyle(
                                fontSize: 30,
                                fontWeight: FontWeight.bold,
                                color: Colors.blueGrey.shade800,
                                height: 1.0,
                              ),
                            ),
                          ),
                          if (subtitle != null) ...[
                            const SizedBox(height: 3),
                            Text(
                              subtitle!,
                              style: TextStyle(
                                fontSize: 10,
                                color: accentColor.withOpacity(0.7),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Iniciales avatar ──────────────────────────────────────────────────────
class _InitialsAvatar extends StatelessWidget {
  final String name;
  final Color color;
  const _InitialsAvatar({required this.name, required this.color});

  @override
  Widget build(BuildContext context) {
    final parts = name.trim().split(' ');
    final initials = parts.length >= 2
        ? '${parts[0][0]}${parts[1][0]}'.toUpperCase()
        : name.isNotEmpty
            ? name[0].toUpperCase()
            : '?';
    return CircleAvatar(
      backgroundColor: color,
      radius: 22,
      child: Text(
        initials,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
      ),
    );
  }
}

// ── Card con sombra ───────────────────────────────────────────────────────
class _StyledCard extends StatelessWidget {
  final Widget child;
  const _StyledCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withOpacity(0.05), width: 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: child,
      ),
    );
  }
}

// ── Estado vacío ──────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final String message;
  final IconData icon;
  const _EmptyState({required this.message, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: Colors.grey.shade100,
            child: Icon(icon, color: Colors.grey.shade400, size: 18),
          ),
          const SizedBox(width: 14),
          Text(
            message,
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Chart loading placeholder ─────────────────────────────────────────────
class _ChartLoadingPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final isDesktop = constraints.maxWidth >= 800;
      final w =
          isDesktop ? (constraints.maxWidth - 16) / 2 : constraints.maxWidth;
      return Wrap(
        spacing: 16,
        runSpacing: 16,
        children: List.generate(
          4,
          (_) => _ShimmerBox(width: w, height: 290),
        ),
      );
    });
  }
}

// ── List loading placeholder ──────────────────────────────────────────────
class _ListLoadingPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _StyledCard(
      child: Column(
        children: List.generate(
          3,
          (i) => Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                _ShimmerBox(width: 44, height: 44, radius: 22),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _ShimmerBox(
                          width: double.infinity, height: 12, radius: 4),
                      const SizedBox(height: 8),
                      _ShimmerBox(width: 120, height: 10, radius: 4),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Shimmer box ───────────────────────────────────────────────────────────
class _ShimmerBox extends StatelessWidget {
  final double width;
  final double height;
  final double radius;
  const _ShimmerBox(
      {required this.width,
      required this.height,
      this.radius = 12});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}
