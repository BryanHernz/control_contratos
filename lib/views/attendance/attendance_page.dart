import 'dart:io';
import 'dart:typed_data';
import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:date_picker_timeline/date_picker_timeline.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:intl/intl.dart';
import 'package:myapp/customs/constants_values.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_saver/file_saver.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path/path.dart' as p;

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
  final TextEditingController _newListCtrl = TextEditingController();

  List<_Worker> _all = [];
  List<_Worker> _filtered = [];

  final DatePickerController _dpCtrl = DatePickerController();

  String _group = 'GENERAL'; // lista actual
  List<String> _groups = ['GENERAL']; // disponibles

  @override
  void initState() {
    super.initState();
    _search.addListener(_onSearch);
    _listenWorkers();

    // Centrar DatePicker en la fecha seleccionada
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _dpCtrl.animateToSelection();
    });

    // Escuchar listas (grupos) del día
    AttendanceService.listenGroups(_selectedDate).listen((gs) {
      setState(() {
        _groups = gs.isEmpty ? ['GENERAL'] : gs;
        if (!_groups.contains(_group)) _group = _groups.first;
      });
    });
  }

  @override
  void dispose() {
    _search.removeListener(_onSearch);
    _search.dispose();
    _newListCtrl.dispose();
    super.dispose();
  }

  // ===== Helpers de nombres/orden =====
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

  // Altura dinámica para el dropdown de sugerencias
  double _suggestionsHeight(BuildContext context) {
    const double tileExtent = 56;
    const int maxVisible = 8;
    final int n = _filtered.length;
    final double needed = tileExtent * math.min(n, maxVisible);
    final double halfScreen = MediaQuery.of(context).size.height * 0.6;
    return math.min(needed, halfScreen);
  }

  // ===== Firestore: carga de trabajadores y filtro =====
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

  // ===== Acciones agregar / quitar =====
  Future<void> _add(_Worker w) async {
    final user = FirebaseAuth.instance.currentUser;
    final addedBy = user?.uid ?? 'manual';
    await AttendanceService.addPresent(
      normalizeDay(_selectedDate),
      group: _group,
      workerId: w.id,
      name: '${w.nombres} ${w.apellidos}'.trim(),
      rut: w.rut.toUpperCase(),
      addedBy: addedBy,
    );
  }

  Future<void> _remove(String workerId) async {
    await AttendanceService.removePresent(
      normalizeDay(_selectedDate),
      _group,
      workerId,
    );
  }

  Future<bool> _confirmRemoveSheet(String displayName) async {
    final r = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.black12,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Text(
                  'Quitar de asistencia',
                  style: Theme.of(ctx)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                    '¿Estás seguro de quitar a:\n${displayName.toUpperCase()}?',
                    textAlign: TextAlign.center),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Cancelar'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style:
                            ElevatedButton.styleFrom(backgroundColor: primario),
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('Sí, quitar',
                            style: TextStyle(color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
    return r == true;
  }

  // ===== PDF =====
  Future<Uint8List> _buildAttendancePdfBytes(
      List<Map<String, dynamic>> entries) async {
    final ordered = [...entries]
      ..sort((a, b) => _sortKeyFor(a).compareTo(_sortKeyFor(b)));

    final pdf = pw.Document();
    final fecha = DateFormat('dd/MM/yyyy').format(_selectedDate);
    final listTitle = _group.toUpperCase();

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

    final rows = List<pw.TableRow>.generate(ordered.length, (i) {
      final e = ordered[i];
      return pw.TableRow(children: [
        cell('${i + 1}'),
        cell(_displayNameFor(e).toUpperCase()),
        cell((e['rut'] ?? '').toString().toUpperCase()),
      ]);
    });

    const rowsPerPage = 27; // ajustado por footer
    List<List<pw.TableRow>> chunk(List<pw.TableRow> src, int size) {
      final r = <List<pw.TableRow>>[];
      for (var i = 0; i < src.length; i += size) {
        r.add(src.sublist(i, i + size > src.length ? src.length : i + size));
      }
      return r;
    }

    final parts = chunk(rows, rowsPerPage);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.letter,
        margin: const pw.EdgeInsets.all(24),
        header: (ctx) => pw.Center(
          child: pw.Text(
            'ASISTENCIA - DÍA $fecha – $listTitle',
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
          ),
        ),
        footer: (ctx) => pw.Column(
          mainAxisSize: pw.MainAxisSize.min,
          children: [
            pw.Divider(thickness: 0.5),
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Text(
                'Página ${ctx.pageNumber} de ${ctx.pagesCount}',
                style: const pw.TextStyle(fontSize: 10),
              ),
            ),
          ],
        ),
        build: (ctx) => [
          for (final part in parts) ...[
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
                ...part,
              ],
            ),
            pw.SizedBox(height: 12),
          ],
          pw.Align(
            alignment: pw.Alignment.centerLeft,
            child: pw.Text('Total asistentes: ${ordered.length}',
                style: const pw.TextStyle(fontSize: 10)),
          ),
        ],
      ),
    );

    return await pdf.save();
  }

  Future<void> _downloadPdfAndroid(Uint8List bytes, String fileName) async {
    final dir = await getExternalStorageDirectory();
    final path = '${dir?.path}/$fileName';
    await File(path).writeAsBytes(bytes, flush: true);
    await OpenFilex.open(path);
  }

  Future<void> _savePdfBytes(Uint8List bytes, String fileName) async {
    if (kIsWeb) {
      await Printing.sharePdf(bytes: bytes, filename: fileName);
      return;
    }
    if (Platform.isAndroid) {
      await _downloadPdfAndroid(bytes, fileName);
      return;
    }
    if (Platform.isIOS) {
      final savedPath = await _savePdfMobile(bytes, fileName);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Guardado en: $savedPath'),
          action: SnackBarAction(
              label: 'ABRIR', onPressed: () => OpenFilex.open(savedPath)),
        ),
      );
      return;
    }
    try {
      await FileSaver.instance.saveFile(
        name: fileName.replaceAll('.pdf', ''),
        ext: 'pdf',
        mimeType: MimeType.pdf,
        bytes: bytes,
      );
    } catch (_) {
      await Printing.layoutPdf(onLayout: (_) async => bytes);
    }
  }

  Future<String> _savePdfMobile(Uint8List bytes, String fileName) async {
    final dir = await getApplicationDocumentsDirectory();
    final path = p.join(dir.path, fileName);
    await File(path).writeAsBytes(bytes, flush: true);
    return path;
  }

  Future<void> _exportPdf(
    List<Map<String, dynamic>> entries, {
    required String mode, // 'download' | 'share'
  }) async {
    final bytes = await _buildAttendancePdfBytes(entries);
    final fileName =
        'asistencia_${AttendanceService.dateKeyFrom(_selectedDate)}_${_group.toLowerCase()}.pdf';

    if (mode == 'download') {
      await _savePdfBytes(bytes, fileName);
      return;
    }

    if (kIsWeb) {
      try {
        await Share.shareXFiles(
          [XFile.fromData(bytes, name: fileName, mimeType: 'application/pdf')],
          text:
              'Asistencia ${_group} del ${DateFormat('dd/MM/yyyy', 'es_CL').format(_selectedDate)}',
          subject: 'Asistencia $_group',
        );
        return;
      } catch (_) {}
      await Printing.sharePdf(bytes: bytes, filename: fileName);
      return;
    }

    final dir = await getTemporaryDirectory();
    final path = '${dir.path}/$fileName';
    await File(path).writeAsBytes(bytes, flush: true);
    await Share.shareXFiles(
      [XFile(path, mimeType: 'application/pdf')],
      text:
          'Asistencia ${_group} del ${DateFormat('dd/MM/yyyy', 'es_CL').format(_selectedDate)}',
      subject: 'Asistencia $_group',
    );
  }

  // ===== UI =====
  Future<void> _createNewGroupDialog() async {
    _newListCtrl.text = '';
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nueva lista del día'),
        content: TextField(
          controller: _newListCtrl,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Nombre de la lista',
            hintText: 'Ej: PODA, COSECHA…',
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Crear'),
          ),
        ],
      ),
    );

    if (ok != true) return;
    final name = _newListCtrl.text.trim();
    if (name.isEmpty) return;

    final g = name.toUpperCase();
    await AttendanceService.ensureGroup(_selectedDate, g);
    setState(() {
      if (!_groups.contains(g)) _groups = [..._groups, g]..sort();
      _group = g;
    });
  }

  Widget _groupSelector() {
    return Row(
      children: [
        const SizedBox(width: 12),
        const Icon(Icons.list_alt, color: Colors.white, size: 18),
        const SizedBox(width: 8),
        DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            dropdownColor: primario,
            value: _group,
            iconEnabledColor: Colors.white,
            style: const TextStyle(color: Colors.white),
            items: [
              for (final g in _groups)
                DropdownMenuItem(
                  value: g,
                  child: Text(g, style: const TextStyle(color: Colors.white)),
                ),
              const DropdownMenuItem(
                value: '__new__',
                child: Text('➕ Nueva lista',
                    style: TextStyle(color: Colors.white)),
              ),
            ],
            onChanged: (v) async {
              if (v == null) return;
              if (v == '__new__') {
                await _createNewGroupDialog();
              } else {
                setState(() => _group = v);
              }
            },
          ),
        ),
        const Spacer(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        toolbarHeight: 210, // un poco más alto para incluir el selector
        flexibleSpace: Container(
          color: primario,
          padding: const EdgeInsets.only(top: 8, bottom: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Date bar
              SizedBox(
                height: 90,
                child: ScrollConfiguration(
                  behavior: const MaterialScrollBehavior().copyWith(
                    dragDevices: {
                      PointerDeviceKind.touch,
                      PointerDeviceKind.mouse,
                      PointerDeviceKind.trackpad,
                      PointerDeviceKind.stylus,
                      PointerDeviceKind.unknown,
                    },
                  ),
                  child: DatePicker(
                    DateTime.now().subtract(const Duration(days: 100)),
                    controller: _dpCtrl,
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
              ),
              // Search
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 6, 12, 4),
                child: TextField(
                  controller: _search,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search, color: Colors.white),
                    hintText: 'Buscar por nombre o RUT…',
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                    border: const OutlineInputBorder(),
                    enabledBorder: OutlineInputBorder(
                      borderSide:
                          BorderSide(color: Colors.white.withOpacity(0.5)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide:
                          BorderSide(color: Colors.white.withOpacity(0.5)),
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
              // Group selector + Export
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  children: [
                    Expanded(child: _groupSelector()),
                    StreamBuilder<List<Map<String, dynamic>>>(
                      stream: AttendanceService.listenPresents(
                          _selectedDate, _group),
                      builder: (context, snap) {
                        final list = snap.data ?? const [];
                        return PopupMenuButton<String>(
                          tooltip: 'Exportar',
                          icon: const Icon(Icons.picture_as_pdf_outlined,
                              color: Colors.white),
                          onSelected: (v) async {
                            final data = snap.data ?? const [];
                            if (data.isEmpty) return;
                            if (v == 'download') {
                              await _exportPdf(data, mode: 'download');
                            } else {
                              await _exportPdf(data, mode: 'share');
                            }
                          },
                          itemBuilder: (context) => const [
                            PopupMenuItem(
                                value: 'download',
                                child: Text('Descargar PDF')),
                            PopupMenuItem(
                                value: 'share', child: Text('Compartir PDF')),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        backgroundColor: primario,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Sugerencias (panel) — aparece cuando hay texto
          if (_search.text.isNotEmpty)
            SizedBox(
              height: _suggestionsHeight(context),
              child: DecoratedBox(
                decoration: BoxDecoration(color: primario),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Material(
                    color: Colors.transparent,
                    child: ListView.separated(
                      padding: EdgeInsets.zero,
                      physics: _filtered.length <= 8
                          ? const NeverScrollableScrollPhysics()
                          : const ClampingScrollPhysics(),
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
                          onTap: () async {
                            await _add(w);
                            _search.clear();
                            setState(() {});
                          },
                          hoverColor: Colors.white.withOpacity(0.08),
                          textColor: Colors.white,
                          dense: true,
                          visualDensity:
                              const VisualDensity(horizontal: -2, vertical: -2),
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 12),
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
                            onPressed: () async {
                              await _add(w);
                              _search.clear();
                              setState(() {});
                            },
                            icon: const Icon(Icons.add_outlined,
                                color: Colors.white),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),

          // LISTA DEL DÍA (según _group)
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: AttendanceService.listenPresents(_selectedDate, _group),
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
                      child: Text('Aún no hay asistentes para esta lista.'));
                }

                entries
                    .sort((a, b) => _sortKeyFor(a).compareTo(_sortKeyFor(b)));

                return Material(
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
                      final name = _displayNameFor(e).toUpperCase();
                      return ListTile(
                        onTap: () {},
                        hoverColor: primario.withOpacity(0.06),
                        dense: true,
                        visualDensity:
                            const VisualDensity(horizontal: -2, vertical: -2),
                        minLeadingWidth: 28,
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 12),
                        leading: CircleAvatar(child: Text('${i + 1}')),
                        title: Row(
                          children: [
                            Text(
                              '${i + 1}. ',
                              style:
                                  const TextStyle(fontWeight: FontWeight.w600),
                              overflow: TextOverflow.visible,
                            ),
                            Expanded(
                              child: Text(
                                name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                softWrap: false,
                              ),
                            ),
                          ],
                        ),
                        subtitle: Text(
                          (e['rut'] ?? '').toString().toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          softWrap: false,
                        ),
                        trailing: IconButton(
                          tooltip: 'Quitar',
                          onPressed: () async {
                            final ok = await _confirmRemoveSheet(name);
                            if (ok)
                              await _remove((e['workerId'] ?? '').toString());
                          },
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
