// ignore_for_file: avoid_types_as_parameter_names
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../customs/app_colors.dart';
import '../../customs/constants_values.dart';
import '../../services/attendance_service.dart';
import '../../customs/charts/generic_pie_chart.dart';
import '../../customs/charts/attendance_bar_chart.dart';
import '../../customs/charts/contracts_line_chart.dart';
import '../../customs/widgets/page_header.dart';
import '../../services/firestore_db.dart';

/// Ancho maximo del contenido del dashboard.
///
/// En monitores anchos el contenido se estiraba de borde a borde: las tres
/// tarjetas de metrica quedaban larguisimas y casi vacias, y los graficos
/// desproporcionados. Debajo de este ancho no cambia nada.
const double kDashboardMaxWidth = 1400;

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  // Los streams se arman UNA vez, no dentro de build().
  //
  // Creandolos en build() se genera un Stream nuevo en cada rebuild y el
  // StreamBuilder se desuscribe del anterior para suscribirse al nuevo. Si esa
  // era la ultima escucha sobre la consulta, Firestore libera el target y la
  // siguiente escucha vuelve a leer del servidor.
  late final DateTime _now;
  late final DateTime _today;
  late final DateTime _monthStart;

  // El padron completo, para los graficos por lugar y por labor.
  //
  // Antes esto filtraba por `activo == true`, y los graficos mostraban un solo
  // registro al 100%: de los 676 trabajadores, 675 fueron creados ANTES de que
  // existiera ese campo, asi que no lo tienen y quedaban fuera de la consulta.
  // El dashboard no estaba mostrando el padron sino un registro de prueba.
  //
  // Es un `.get()` y no un `.snapshots()`: baja los documentos una vez al
  // entrar, en vez de mantener viva una escucha sobre la coleccion entera.
  late final Future<List<Map<String, dynamic>>> _padron;

  // Los dos numeros de la primera tarjeta, por agregacion: 1 lectura cada uno
  // en vez de bajar los documentos para contarlos.
  late final Future<int> _totalRegistrados;
  late final Future<int> _conContratoVigente;

  late final Stream<QuerySnapshot> _ultimosContratosStream;
  late final Stream<QuerySnapshot> _auditoriaStream;
  late final Stream<List<Map<String, dynamic>>> _presentesStream;

  // "Contratos este mes" es solo un numero. Antes se descargaban TODOS los
  // documentos del mes para hacer `.docs.length`; ahora es una agregacion
  // `.count()`, que Firestore cobra a razon de 1 lectura por cada 1000
  // documentos contados. A cambio deja de actualizarse solo: se recalcula al
  // entrar al dashboard, que para esta metrica alcanza.
  late final Future<int> _contratosDelMes;

  @override
  void initState() {
    super.initState();

    _now = DateTime.now();
    _today = DateTime(_now.year, _now.month, _now.day);
    _monthStart = DateTime(_now.year, _now.month, 1);

    final trabajadores = db.collection('Trabajadores');

    _totalRegistrados =
        trabajadores.count().get().then((s) => s.count ?? 0);
    _conContratoVigente = trabajadores
        .where('activo', isEqualTo: true)
        .count()
        .get()
        .then((s) => s.count ?? 0);

    _padron = trabajadores.get().then(
          (s) => s.docs.map((e) => e.data()).toList(),
        );

    _contratosDelMes = trabajadores
        .where('ultimoContrato',
            isGreaterThanOrEqualTo: Timestamp.fromDate(_monthStart))
        .count()
        .get()
        .then((s) => s.count ?? 0);

    _ultimosContratosStream = trabajadores
        .where('ultimoContrato', isGreaterThan: Timestamp(0, 0))
        .orderBy('ultimoContrato', descending: true)
        .limit(5)
        .snapshots();

    _auditoriaStream = db
        .collection('Auditoria')
        .orderBy('timestamp', descending: true)
        .limit(8)
        .snapshots();

    _presentesStream = AttendanceService.listenPresents(_today, 'GENERAL');
  }

  @override
  Widget build(BuildContext context) {
    final now = _now;

    // En escritorio el header queda fijo y solo scrollea el cuerpo. En el
    // telefono se va con el scroll: la pantalla es corta y 128px permanentes
    // de cabecera son mucho para repetir el nombre de la pagina en la que ya
    // estas.
    final compacta = MediaQuery.sizeOf(context).width < 800;

    return ColoredBox(
      color: AppColors.background,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!compacta) _DashboardHeader(now: now),
          Expanded(
            child: SingleChildScrollView(
              // Tope de ancho centrado: en un monitor grande el contenido se
              // estiraba de borde a borde y las tarjetas quedaban con enormes
              // huecos vacios. Bajo ese ancho ocupa todo, como antes.
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints:
                      const BoxConstraints(maxWidth: kDashboardMaxWidth),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (compacta) _DashboardHeader(now: now),
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
                                    // Dos numeros y no uno: el padron es un
                                    // registro historico de todos los que han
                                    // pasado, y "con contrato vigente" son los
                                    // que tienen uno emitido hoy. Mostrar solo
                                    // el segundo daba un 1 que parecia un
                                    // error.
                                    FutureBuilder<int>(
                                      future: _totalRegistrados,
                                      builder: (ctx, snapTotal) {
                                        return FutureBuilder<int>(
                                          future: _conContratoVigente,
                                          builder: (ctx, snapVigentes) {
                                            final total = snapTotal.data;
                                            final vigentes = snapVigentes.data;
                                            return _MetricCard(
                                              icon: Icons.people_rounded,
                                              label: 'Trabajadores registrados',
                                              value: '${total ?? '-'}',
                                              subtitle: vigentes == null
                                                  ? 'Contando...'
                                                  : '$vigentes con contrato '
                                                      'vigente',
                                              accentColor:
                                                  const Color(0xFF546E7A),
                                              fraction: 1 / crossCount,
                                              maxWidth: constraints.maxWidth,
                                            );
                                          },
                                        );
                                      },
                                    ),
                                    StreamBuilder<List<Map<String, dynamic>>>(
                                      stream: _presentesStream,
                                      builder: (ctx, snap) {
                                        final count = snap.data?.length ?? 0;
                                        return _MetricCard(
                                          icon: Icons.how_to_reg_rounded,
                                          label: 'Presentes hoy',
                                          value: '$count',
                                          subtitle:
                                              DateFormat('EEEE d MMM', 'es_CL')
                                                  .format(now),
                                          accentColor: const Color(0xFF00897B),
                                          fraction: 1 / crossCount,
                                          maxWidth: constraints.maxWidth,
                                        );
                                      },
                                    ),
                                    FutureBuilder<int>(
                                      future: _contratosDelMes,
                                      builder: (ctx, snap) {
                                        final count = snap.data;
                                        return _MetricCard(
                                          icon: Icons.description_rounded,
                                          label: 'Contratos este mes',
                                          value:
                                              count == null ? '--' : '$count',
                                          subtitle:
                                              DateFormat('MMMM yyyy', 'es_CL')
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
                            const _SectionHeader(
                              title: 'Analítica',
                              icon: Icons.bar_chart_rounded,
                            ),
                            const SizedBox(height: 14),

                            FutureBuilder<List<Map<String, dynamic>>>(
                              future: _padron,
                              builder: (ctx, snap) {
                                if (!snap.hasData) {
                                  return _ChartLoadingPlaceholder();
                                }

                                final workers = snap.data!;

                                final placesData = <String, int>{};
                                final taskData = <String, int>{};

                                for (var w in workers) {
                                  final l =
                                      (w['lugar'] ?? 'Sin asignar').toString();
                                  final t =
                                      (w['labor'] ?? 'Sin asignar').toString();
                                  placesData[l] = (placesData[l] ?? 0) + 1;
                                  taskData[t] = (taskData[t] ?? 0) + 1;
                                }

                                return LayoutBuilder(
                                  builder: (context, constraints) {
                                    final isDesktop =
                                        constraints.maxWidth >= 800;
                                    final chartWidth = isDesktop
                                        ? (constraints.maxWidth - 16) / 2
                                        : constraints.maxWidth;

                                    // Sin datos reales se muestra un vacio,
                                    // no una tabla inventada.
                                    //
                                    // Antes, cuando habia una entrada o menos,
                                    // los graficos caian a datos demo -- "Sede
                                    // Central (Demo)", "Temporera (Demo)" -- y
                                    // como `activo` solo lo tiene quien tenga
                                    // contrato vigente, caian SIEMPRE. Quien
                                    // miraba el dashboard veia ficcion
                                    // presentada como dato.

                                    return Wrap(
                                      spacing: 16,
                                      runSpacing: 16,
                                      children: [
                                        SizedBox(
                                          width: chartWidth,
                                          height: 290,
                                          child: GenericPieChart(
                                            title: 'Por Establecimiento',
                                            data: placesData,
                                          ),
                                        ),
                                        SizedBox(
                                          width: chartWidth,
                                          height: 290,
                                          child: GenericPieChart(
                                            title: 'Por Labor',
                                            data: taskData,
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
                            const _SectionHeader(
                              title: 'Últimos contratos generados',
                              icon: Icons.assignment_turned_in_outlined,
                            ),
                            const SizedBox(height: 14),

                            StreamBuilder<QuerySnapshot>(
                              stream: _ultimosContratosStream,
                              builder: (ctx, snap) {
                                if (!snap.hasData)
                                  return _ListLoadingPlaceholder();
                                if (snap.data!.docs.isEmpty) {
                                  return const _EmptyState(
                                      icon: Icons.inbox_outlined,
                                      message: 'Ningún contrato generado aún.');
                                }
                                return _StyledCard(
                                  child: ListView.separated(
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    itemCount: snap.data!.docs.length,
                                    separatorBuilder: (_, __) => Divider(
                                      height: 1,
                                      color: Colors.grey.shade100,
                                      indent: 72,
                                    ),
                                    itemBuilder: (_, i) {
                                      final doc = snap.data!.docs[i];
                                      final data =
                                          doc.data() as Map<String, dynamic>;
                                      final nombres =
                                          (data['nombres'] ?? '').toString();
                                      final apellidos =
                                          (data['apellidos'] ?? '').toString();
                                      final ts = data['ultimoContrato'];
                                      String fecha = '—';
                                      if (ts is Timestamp) {
                                        fecha = DateFormat(
                                                'dd/MM/yyyy · HH:mm', 'es')
                                            .format(ts.toDate());
                                      }
                                      return ListTile(
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                                horizontal: 24, vertical: 8),
                                        leading: _InitialsAvatar(
                                          name: nombres.isNotEmpty
                                              ? nombres
                                              : '?',
                                          color: primario,
                                        ),
                                        title: Text(
                                          '$apellidos $nombres'.toUpperCase(),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 14.5,
                                            color: AppColors.textStrong,
                                            letterSpacing: 0.3,
                                          ),
                                        ),
                                        subtitle: Padding(
                                          padding:
                                              const EdgeInsets.only(top: 3),
                                          child: Row(
                                            children: [
                                              const Icon(Icons.schedule_rounded,
                                                  size: 14,
                                                  color: AppColors.iconMuted),
                                              const SizedBox(width: 5),
                                              Text(
                                                fecha,
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w600,
                                                  color: AppColors.textMuted,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        trailing: const Icon(
                                            Icons.chevron_right_rounded,
                                            color: AppColors.iconMuted),
                                      );
                                    },
                                  ),
                                );
                              },
                            ),

                            const SizedBox(height: 32),

                            // ── Actividad reciente ────────────────────────────
                            const _SectionHeader(
                              title: 'Actividad reciente',
                              icon: Icons.history_rounded,
                            ),
                            const SizedBox(height: 14),

                            StreamBuilder<QuerySnapshot>(
                              stream: _auditoriaStream,
                              builder: (ctx, snap) {
                                if (!snap.hasData)
                                  return _ListLoadingPlaceholder();
                                if (snap.data!.docs.isEmpty) {
                                  return const _EmptyState(
                                      icon: Icons.history_rounded,
                                      message: 'Sin actividad registrada.');
                                }
                                return _StyledCard(
                                  child: ListView.separated(
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    itemCount: snap.data!.docs.length,
                                    separatorBuilder: (_, __) => Divider(
                                      height: 1,
                                      color: Colors.grey.shade100,
                                      indent: 72,
                                    ),
                                    itemBuilder: (_, i) {
                                      final doc = snap.data!.docs[i];
                                      final data =
                                          doc.data() as Map<String, dynamic>;
                                      final accion =
                                          (data['accion'] ?? '').toString();
                                      final usuario =
                                          (data['usuario'] ?? '').toString();
                                      final nombre =
                                          (data['nombre'] ?? '').toString();
                                      final ts = data['timestamp'];
                                      String fecha = '—';
                                      if (ts is Timestamp) {
                                        fecha =
                                            DateFormat('dd/MM · HH:mm', 'es')
                                                .format(ts.toDate());
                                      }
                                      return ListTile(
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                                horizontal: 24, vertical: 8),
                                        leading: CircleAvatar(
                                          backgroundColor:
                                              Colors.blueGrey.shade50,
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
                                          padding:
                                              const EdgeInsets.only(top: 2),
                                          child: Text(
                                            '$accion · $usuario',
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color: AppColors.textMuted,
                                            ),
                                          ),
                                        ),
                                        trailing: Text(
                                          fecha,
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: AppColors.textMuted,
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
              ),
            ),
          ),
        ],
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
    final diaSemana = DateFormat('EEEE', 'es_CL').format(now); // "jueves"
    final fechaCorta = DateFormat('d \'de\' MMMM, yyyy', 'es_CL').format(now);

    return PageHeader(
      title: 'Dashboard',
      subtitle: 'Control de Contratos',
      icon: Icons.dashboard_rounded,
      // Fecha plana: sin fondo, sin borde y sin esquinas redondeadas. La
      // pastilla translucida competia con el titulo sin aportar nada.
      bottomWidget: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.calendar_today_rounded,
              size: 14, color: Colors.white),
          const SizedBox(width: 8),
          Text(
            '${diaSemana[0].toUpperCase()}${diaSemana.substring(1)}, $fechaCorta',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
        ],
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
        decoration: appCardDecoration(),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(kCardRadius),
          child: Stack(
            children: [
              // El icono ampliado de fondo. Al 6% no existia y al 13% seguia
              // costando verlo sobre una superficie clara; a 0.22 se lee como
              // marca de agua sin competir con el numero.
              Positioned(
                right: -10,
                bottom: -10,
                child: Icon(
                  icon,
                  size: 96,
                  color: accentColor.withOpacity(0.22),
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
                padding: const EdgeInsets.fromLTRB(26, 24, 24, 24),
                child: Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: accentColor.withOpacity(0.16),
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
                            style: const TextStyle(
                              // Rajdhani es una fuente condensada y liviana:
                              // a 11px con w500 practicamente no se lee. Estos
                              // tamanos y pesos son el minimo utilizable.
                              fontSize: 13,
                              color: AppColors.textBody,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.2,
                            ),
                          ),
                          const SizedBox(height: 3),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 400),
                            transitionBuilder: (child, anim) => FadeTransition(
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
                                // Sin withOpacity: el accent al 70% sobre
                                // blanco quedaba en ~2.9:1, bajo el minimo AA.
                                fontSize: 12,
                                color: accentColor,
                                fontWeight: FontWeight.w600,
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
      decoration: appCardDecoration(),
      // Aire propio, igual que las tarjetas de grafico: la envoltura de
      // "Ultimos contratos generados" y "Actividad reciente" pegaba su
      // contenido al borde.
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(kCardRadius),
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
        borderRadius: BorderRadius.circular(kCardRadius),
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
            child: Icon(icon, color: AppColors.iconMuted, size: 18),
          ),
          const SizedBox(width: 14),
          Text(
            message,
            style: const TextStyle(
              color: AppColors.textMuted,
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
          (i) => const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                _ShimmerBox(width: 44, height: 44, radius: 22),
                SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _ShimmerBox(
                          width: double.infinity, height: 12, radius: 4),
                      SizedBox(height: 8),
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
      {required this.width, required this.height, this.radius = 12});

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
