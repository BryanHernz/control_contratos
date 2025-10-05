import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:date_picker_timeline/date_picker_timeline.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:myapp/customs/constants_values.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../../services/attendance_service.dart';
import '../../utils/normalize.dart';

DateTime normalizeDay(DateTime d) => DateTime(d.year, d.month, d.day);

class AttendancePage extends StatefulWidget {
  const AttendancePage({super.key});

  @override
  State<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> {
  DateTime _selectedDate = normalizeDay(DateTime.now());
  final TextEditingController _search = TextEditingController();

  List<_Worker> _all = [];
  List<_Worker> _filtered = [];

  @override
  void initState() {
    super.initState();
    _search.addListener(_onSearch);
    _listenWorkers();
  }

  @override
  void dispose() {
    _search.removeListener(_onSearch);
    _search.dispose();
    super.dispose();
  }

  // Nombre a mostrar universal: "NOMBRES APELLIDOS"
  // 1) intenta por workerId (más fiable),
  // 2) luego por RUT,
  // 3) si no, usa el 'name' guardado en el doc del día.
  String _displayNameFor(Map<String, dynamic> e) {
    final wid = (e['workerId'] ?? '').toString().trim();
    if (wid.isNotEmpty) {
      final byId = _all.where((w) => w.id == wid);
      if (byId.isNotEmpty) {
        return '${byId.first.nombres} ${byId.first.apellidos}'.trim();
      }
    }

    final rut = (e['rut'] ?? '').toString().trim();
    if (rut.isNotEmpty) {
      final byRut = _all.where((w) => w.rut.trim() == rut);
      if (byRut.isNotEmpty) {
        return '${byRut.first.nombres} ${byRut.first.apellidos}'.trim();
      }
    }

    return (e['name'] ?? '').toString().trim();
  }

  String _sortKeyFor(Map<String, dynamic> e) => normalize(_displayNameFor(e));

  void _listenWorkers() {
    FirebaseFirestore.instance
        .collection('Trabajadores')
        .orderBy('apellidos')
        .snapshots()
        .listen((snap) {
      final list = snap.docs.map((d) {
        final m = d.data();
        final nombres = (m['nombres'] ?? m['name'] ?? '').toString();
        final apellidos = (m['apellidos'] ?? m['lastName'] ?? '').toString();
        final rut = (m['rut'] ?? '').toString();
        return _Worker(
          id: d.id,
          nombres: nombres,
          apellidos: apellidos,
          rut: rut,
        );
      }).toList();
      setState(() {
        _all = list;
        _filtered = list;
      });
    });
  }

  void _onSearch() {
    final q = normalize(_search.text.trim());
    setState(() {
      if (q.isEmpty) {
        _filtered = _all;
      } else {
        _filtered = _all.where((w) {
          final name = normalize('${w.nombres} ${w.apellidos}');
          final rut = normalize(w.rut);
          return name.contains(q) || rut.contains(q);
        }).toList();
      }
    });
  }

  Future<void> _add(_Worker w) async {
    final user = FirebaseAuth.instance.currentUser;
    final addedBy = user?.uid ?? 'manual';
    await AttendanceService.addPresent(
      normalizeDay(_selectedDate),
      workerId: w.id,
      name: '${w.nombres} ${w.apellidos}'.trim(), // NOMBRES APELLIDOS
      rut: w.rut.toUpperCase(),
      addedBy: addedBy,
    );
  }

  Future<void> _remove(String workerId) async {
    await AttendanceService.removePresent(
      normalizeDay(_selectedDate),
      workerId,
    );
  }

  Future<void> _exportPdf(List<Map<String, dynamic>> entries) async {
    // Ordenar por el mismo criterio que la lista
    final ordered = [...entries]
      ..sort((a, b) => _sortKeyFor(a).compareTo(_sortKeyFor(b)));

    final pdf = pw.Document();
    final fecha = DateFormat('dd/MM/yyyy').format(_selectedDate);

    pw.Widget cell(String text, {bool header = false}) => pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 6),
          child: pw.Text(
            text,
            style: pw.TextStyle(
              fontSize: header ? 12 : 11,
              fontWeight: header ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
        );

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.letter,
        margin: const pw.EdgeInsets.all(24),
        build: (ctx) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              pw.Text(
                'ASISTENCIA - DÍA $fecha',
                style:
                    pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
                textAlign: pw.TextAlign.center,
              ),
              pw.SizedBox(height: 12),
              pw.Table(
                border: pw.TableBorder.all(width: 0.5),
                columnWidths: {
                  0: const pw.FixedColumnWidth(30), // Nº
                  1: const pw.FlexColumnWidth(5), // Nombre
                  2: const pw.FlexColumnWidth(2), // RUT
                },
                children: [
                  pw.TableRow(children: [
                    cell('Nº', header: true),
                    cell('Nombre', header: true),
                    cell('RUT', header: true),
                  ]),
                  ...List.generate(ordered.length, (i) {
                    final e = ordered[i];
                    return pw.TableRow(children: [
                      cell('${i + 1}'),
                      cell(_displayNameFor(e).toUpperCase()),
                      cell((e['rut'] ?? '').toString().toUpperCase()),
                    ]);
                  })
                ],
              ),
              pw.SizedBox(height: 12),
              pw.Text('Total asistentes: ${ordered.length}',
                  style: const pw.TextStyle(fontSize: 10)),
            ],
          );
        },
      ),
    );

    final bytes = await pdf.save();
    final fileName =
        'asistencia_${AttendanceService.dateKeyFrom(_selectedDate)}.pdf';

    if (kIsWeb) {
      try {
        await Share.shareXFiles(
          [XFile.fromData(bytes, name: fileName, mimeType: 'application/pdf')],
          text:
              'Asistencia del ${DateFormat('dd/MM/yyyy', 'es_CL').format(_selectedDate)}',
          subject: 'Asistencia',
        );
        return;
      } catch (_) {}
      await Printing.sharePdf(bytes: bytes, filename: fileName);
      return;
    }

    final dir = await getTemporaryDirectory();
    final path = '${dir.path}/$fileName';
    final file = File(path);
    await file.writeAsBytes(bytes, flush: true);

    await Share.shareXFiles(
      [XFile(path, mimeType: 'application/pdf')],
      text:
          'Asistencia del ${DateFormat('dd/MM/yyyy', 'es_CL').format(_selectedDate)}',
      subject: 'Asistencia',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // fondo blanco garantizado
      appBar: AppBar(
        toolbarHeight: 105,
        flexibleSpace: Container(
          height: 105,
          color: primario,
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: DatePicker(
            DateTime.now().subtract(const Duration(days: 2)),
            initialSelectedDate: _selectedDate,
            selectionColor: Colors.white,
            selectedTextColor: primario,
            locale: "es_CL",
            daysCount: 365 * 2,
            onDateChange: (d) =>
                setState(() => _selectedDate = normalizeDay(d)),
            dayTextStyle: const TextStyle(color: Colors.white),
            monthTextStyle: const TextStyle(color: Colors.white),
            dateTextStyle: const TextStyle(color: Colors.white),
          ),
        ),
        backgroundColor: primario,
        foregroundColor: Colors.white,
        bottom: AppBar(
          toolbarHeight: 80,
          backgroundColor: primario,
          title: Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: TextField(
              controller: _search,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search, color: Colors.white),
                hintText: 'Buscar por nombre o RUT…',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                border: const OutlineInputBorder(),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.5)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.5)),
                ),
                isDense: true,
                suffixIcon: _search.text.isEmpty
                    ? null
                    : IconButton(
                        onPressed: () => _search.clear(),
                        icon: const Icon(Icons.clear, color: Colors.white),
                      ),
              ),
            ),
          ),
          actions: [
            StreamBuilder<List<Map<String, dynamic>>>(
              stream: AttendanceService.listenPresents(_selectedDate),
              builder: (context, snap) {
                final list = snap.data ?? const [];
                return IconButton(
                  tooltip: 'Exportar PDF',
                  onPressed: list.isEmpty ? null : () => _exportPdf(list),
                  icon: const Icon(Icons.picture_as_pdf_outlined,
                      color: Colors.white),
                );
              },
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // SUGERENCIAS (dropdown) — solo aparece cuando hay texto
          if (_search.text.isNotEmpty)
            Expanded(
              flex: 1,
              child: Container(
                decoration: BoxDecoration(
                  color: primario,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: ListView.separated(
                    itemCount: _filtered.length,
                    separatorBuilder: (_, __) => const Divider(
                      height: 1,
                      thickness: 0.2,
                      color: Colors.white24,
                      indent: 12,
                      endIndent: 12,
                    ),
                    itemBuilder: (_, i) {
                      final w = _filtered[i];
                      return ListTile(
                        textColor: Colors.white,
                        dense: true,
                        title: Text(
                          '${w.apellidos.toUpperCase()} ${w.nombres.toUpperCase()}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          softWrap: false,
                        ),
                        subtitle: Text(
                          w.rut.toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          softWrap: false,
                        ),
                        trailing: IconButton(
                          tooltip: 'Agregar a asistencia',
                          onPressed: () => _add(w),
                          icon: const Icon(Icons.add_outlined,
                              color: Colors.white),
                        ),
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 12),
                      );
                    },
                  ),
                ),
              ),
            ),

          // LISTA DEL DÍA (fondo siempre blanco)
          Expanded(
            flex: 2,
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: AttendanceService.listenPresents(_selectedDate),
              builder: (context, snap) {
                if (snap.hasError) {
                  return const Center(child: Text('Error cargando asistencia'));
                }
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final entries = snap.data!;
                if (entries.isEmpty) {
                  return const Center(
                      child: Text('Aún no hay asistentes para este día.'));
                }

                // Ordenar por el mismo criterio que PDF
                entries
                    .sort((a, b) => _sortKeyFor(a).compareTo(_sortKeyFor(b)));

                return ColoredBox(
                  color: Colors.white,
                  child: ListView.separated(
                    itemCount: entries.length,
                    separatorBuilder: (_, __) => Divider(
                      height: 1,
                      indent: 20,
                      endIndent: 20,
                      color: primario.withOpacity(0.2),
                      thickness: 0.2,
                    ),
                    itemBuilder: (_, i) {
                      final e = entries[i];
                      return ListTile(
                        leading: CircleAvatar(child: Text('${i + 1}')),
                        title: Text(
                          _displayNameFor(e).toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          softWrap: false,
                        ),
                        subtitle: Text(
                          (e['rut'] ?? '').toString().toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          softWrap: false,
                        ),
                        trailing: IconButton(
                          tooltip: 'Quitar',
                          onPressed: () =>
                              _remove((e['workerId'] ?? '').toString()),
                          icon: Icon(Icons.delete_outline, color: primario),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _Worker {
  final String id;
  final String nombres;
  final String apellidos;
  final String rut;

  _Worker({
    required this.id,
    required this.nombres,
    required this.apellidos,
    required this.rut,
  });
}
