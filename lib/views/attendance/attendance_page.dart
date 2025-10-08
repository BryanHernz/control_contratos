import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:date_picker_timeline/date_picker_timeline.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:group_button/group_button.dart';
import 'package:intl/intl.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:myapp/customs/constants_values.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:responsive_grid_list/responsive_grid_list.dart';
import 'package:share_plus/share_plus.dart';

import '../../customs/widgets_custom.dart';
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
  final _search = TextEditingController();
  final _dpCtrl = DatePickerController();

  StreamSubscription<List<String>>? _typesSub;
  StreamSubscription<List<String>>? _dayActiveListsSub;

  List<_Worker> _all = [];
  List<_Worker> _filtered = [];

  String _group = 'GENERAL';
  List<String> _activeLists = []; // always UPPERCASE
  List<String> _allTypes = []; // always UPPERCASE

  @override
  void initState() {
    super.initState();
    _search.addListener(_onSearch);
    _listenWorkers();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _dpCtrl.animateToDate(_selectedDate.subtract(const Duration(days: 1)));
    });

    _typesSub = AttendanceService.listenAllListTypes().listen((tipos) {
      if (!mounted) return;
      setState(() => _allTypes = tipos.map((t) => t.toUpperCase()).toList());
    });

    _subscribeDayActiveLists();
  }

  void _subscribeDayActiveLists() {
    _dayActiveListsSub?.cancel();
    _dayActiveListsSub =
        AttendanceService.listenDayActiveLists(_selectedDate).listen((ls) {
      if (!mounted) return;
      final up = ls.map((e) => e.toUpperCase()).toList();
      up.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
      setState(() {
        _activeLists = up;
        if (_group != 'GENERAL' &&
            !_activeLists.contains(_group.toUpperCase())) {
          _group = 'GENERAL';
        }
      });
    }, onError: (_) {});
  }

  @override
  void dispose() {
    _search.removeListener(_onSearch);
    _search.dispose();
    _typesSub?.cancel();
    _dayActiveListsSub?.cancel();
    super.dispose();
  }

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

  double _suggestionsHeight(BuildContext ctx) {
    const tileExtent = 56.0;
    const maxVisible = 8;
    final n = _filtered.length;
    final needed = tileExtent * math.min(n, maxVisible);
    final halfScreen = MediaQuery.of(ctx).size.height * 0.6;
    return math.min(needed, halfScreen);
  }

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
            id: d.id, nombres: nombres, apellidos: apellidos, rut: rut);
      }).toList();
      if (!mounted) return;
      setState(() {
        _all = list;
        _filtered = list;
      });
    });
  }

  void _onSearch() {
    final q = normalize(_search.text.trim());
    if (!mounted) return;
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

  Future<void> _addToList(_Worker w, String listName) async {
    final user = FirebaseAuth.instance.currentUser;
    final addedBy = user?.uid ?? 'manual';
    await AttendanceService.addOrMovePresent(
      normalizeDay(_selectedDate),
      workerId: w.id,
      name: '${w.nombres} ${w.apellidos}'.trim(),
      rut: w.rut.toUpperCase(),
      list: listName.toUpperCase(),
      addedBy: addedBy,
    );
  }

  Future<void> _add(_Worker w) async {
    if (_group == 'GENERAL') {
      final pick = await _showPickActiveListSheet();
      if (pick == null) return;
      await _addToList(w, pick);
      _search.clear();
      if (mounted) setState(() {});
    } else {
      await _addToList(w, _group);
      _search.clear();
      if (mounted) setState(() {});
    }
  }

  Future<void> _remove(String workerId) async {
    await AttendanceService.removePresent(
        normalizeDay(_selectedDate), workerId);
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
                      borderRadius: BorderRadius.circular(2)),
                ),
                Text('Quitar de asistencia',
                    style: Theme.of(ctx)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
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

  Future<void> _activatePickedLists(Set<String> picked) async {
    for (final t in picked) {
      await AttendanceService.addActiveList(_selectedDate, t.toUpperCase());
    }
    if (!mounted) return;
    setState(() {
      final s = {..._activeLists, ...picked.map((e) => e.toUpperCase())};
      _activeLists = s.toList()
        ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    });
    Get.back();
  }

  Future<void> _submitCreateType(
      GlobalKey<FormState> formKey, TextEditingController ctrl) async {
    if (!formKey.currentState!.validate()) return;
    final name = ctrl.text.trim();
    if (name.isEmpty) return;
    await AttendanceService.addListType(name);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Tipo creado. Ya puedes activarlo en el día.')),
    );
    Get.back();
  }

  Future<void> _showActivateListsSheet() async {
    final picked = <String>{};
    await showCupertinoModalBottomSheet<void>(
      context: context,
      builder: (ctx) {
        return SizedBox(
          height: 390,
          child: StatefulBuilder(
            builder: (context, setSt) {
              return Scaffold(
                appBar: AppBar(
                  automaticallyImplyLeading: false,
                  toolbarHeight: 48,
                  centerTitle: true,
                  backgroundColor: Colors.white,
                  elevation: 0,
                  title: Text(
                    'Agregar listas al día',
                    style: Theme.of(ctx)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                body: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        StreamBuilder<List<String>>(
                          stream: AttendanceService.listenAllListTypes(),
                          builder: (context, snap) {
                            final tipos = (snap.data ?? [])
                                .map((t) => t.toUpperCase())
                                .toList();
                            tipos.sort((a, b) =>
                                a.toLowerCase().compareTo(b.toLowerCase()));
                            final activeSet = _activeLists
                                .map((e) => e.toUpperCase())
                                .toSet();
                            final candidates = tipos
                                .where((t) => !activeSet.contains(t))
                                .toList();

                            if (candidates.isEmpty) {
                              return Container(
                                constraints:
                                    const BoxConstraints(minHeight: 180),
                                child: const Padding(
                                  padding: EdgeInsets.only(top: 12),
                                  child: Text(
                                    'No hay más tipos disponibles. Usa "Nuevo tipo" para crear uno.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(fontSize: 18),
                                  ),
                                ),
                              );
                            }

                            return Container(
                              constraints: const BoxConstraints(minHeight: 180),
                              child: GroupButton(
                                buttons: candidates,
                                isRadio: false,
                                options: GroupButtonOptions(
                                  spacing: 8,
                                  runSpacing: 8,
                                  direction: Axis.horizontal,
                                  unselectedColor: Colors.grey.shade200,
                                  unselectedBorderColor: Colors.transparent,
                                  selectedColor: primario,
                                  selectedTextStyle: Theme.of(ctx)
                                      .textTheme
                                      .bodyLarge
                                      ?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                  borderRadius: const BorderRadius.all(
                                      Radius.circular(8)),
                                  selectedBorderColor:
                                      primario.withOpacity(0.3),
                                ),
                                onSelected: (text, index, isSelected) =>
                                    setSt(() {
                                  final val = text.toString().toUpperCase();
                                  if (isSelected) {
                                    picked.add(val);
                                  } else {
                                    picked.remove(val);
                                  }
                                }),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            CustomButton2(
                              funcion: () async {
                                await _showCreateTypeSheet();
                                setSt(() {}); // refresh visual
                              },
                              texto: 'Nuevo tipo',
                              cancelar: true,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            CustomButton(
                              funcion: () {
                                Navigator.of(ctx).pop();
                              },
                              texto: 'Cerrar',
                              cancelar: true,
                            ),
                            CustomButton(
                              funcion: () {
                                if (picked.isNotEmpty) {
                                  _activatePickedLists(picked);
                                }
                              },
                              texto: 'Activar',
                              cancelar: false,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Future<String?> _showPickActiveListSheet() async {
    String? picked;

    return showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            child: StatefulBuilder(
              builder: (ctx, setSt) {
                // <- recalculamos ACTUALMENTE las listas activas aquí,
                // en cada reconstrucción del StatefulBuilder.
                final actives = [..._activeLists]
                  ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.black12,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Selecciona lista',
                      style: Theme.of(ctx)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    if (actives.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child:
                            Text('No hay listas activas hoy. Agrega alguna.'),
                      ),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        // ahora usamos la lista recalculada
                        for (final t in actives)
                          ChoiceChip(
                            label: Text(t.toUpperCase()),
                            selected: picked == t,
                            selectedColor: primario.withOpacity(0.15),
                            onSelected: (sel) =>
                                setSt(() => picked = sel ? t : null),
                          ),
                        ActionChip(
                          avatar: const Icon(Icons.add, size: 18),
                          label: const Text('Agregar listas del día'),
                          onPressed: () async {
                            // abrimos el sheet de activar listas; cuando regrese
                            // _activeLists ya estará actualizado por el stream y
                            // al llamar setSt(() {}) forzamos reconstrucción y
                            // recalculamos actives arriba.
                            await _showActivateListsSheet();
                            setSt(() {}); // dispara la recomputación de actives
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        CustomButton(
                          funcion: () {
                            Navigator.pop(ctx, null);
                          },
                          texto: 'Cancelar',
                          cancelar: true,
                        ),
                        CustomButton(
                          funcion: () {
                            if (picked != null) {
                              Navigator.pop(ctx, picked);
                            }
                          },
                          texto: 'Usar esta lista',
                          cancelar: false,
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  Future<void> _showCreateTypeSheet() async {
    final ctrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    await showCupertinoModalBottomSheet<bool>(
      context: context,
      builder: (context) => SizedBox(
        height: 250,
        child: Scaffold(
          resizeToAvoidBottomInset: false,
          appBar: AppBar(
            toolbarHeight: 70,
            automaticallyImplyLeading: false,
            title: Center(
              child: Text(
                'Nuevo tipo de lista',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
          ),
          body: Form(
            key: formKey,
            child: ResponsiveGridList(
              minItemsPerRow: 1,
              maxItemsPerRow: 2,
              horizontalGridMargin: 25,
              verticalGridMargin: 25,
              minItemWidth: 250,
              children: [
                InputTextField(
                  textController: ctrl,
                  hint: 'Nombre (EJ: PODA, COSECHA)',
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Ingresa un nombre';
                    }
                    return null;
                  },
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 15.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      CustomButton(
                        funcion: () {
                          Get.back(result: false);
                        },
                        texto: 'Cancelar',
                        cancelar: true,
                      ),
                      CustomButton(
                        funcion: () {
                          if (formKey.currentState!.validate()) {
                            formKey.currentState!.save();
                            _submitCreateType(formKey, ctrl);
                          }
                        },
                        texto: 'Agregar',
                        cancelar: false,
                      ),
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

  // PDF generation helpers (complete)
  Future<Uint8List> _buildPdfBytes(List<Map<String, dynamic>> entries) async {
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

    final rows = <pw.TableRow>[];
    for (var i = 0; i < ordered.length; i++) {
      final e = ordered[i];
      final num = '${i + 1}';
      final name = _displayNameFor(e).toUpperCase();
      final rut = (e['rut'] ?? '').toString().toUpperCase();
      if (_group == 'GENERAL') {
        final lst = (e['list'] ?? '').toString().toUpperCase();
        rows.add(pw.TableRow(
            children: [cell(num), cell(name), cell(rut), cell(lst)]));
      } else {
        rows.add(pw.TableRow(children: [cell(num), cell(name), cell(rut)]));
      }
    }

    const rowsPerPage = 26;
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
        header: (ctx) => pw.Column(
          mainAxisSize: pw.MainAxisSize.min,
          children: [
            pw.Center(
              child: pw.Text(
                'ASISTENCIA - DÍA $fecha - $listTitle',
                style:
                    pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
              ),
            ),
            pw.SizedBox(height: 16),
          ],
        ),
        footer: (ctx) => pw.Column(
          mainAxisSize: pw.MainAxisSize.min,
          children: [
            pw.Divider(thickness: 0.5),
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Text('Página ${ctx.pageNumber} de ${ctx.pagesCount}',
                  style: const pw.TextStyle(fontSize: 10)),
            ),
          ],
        ),
        build: (ctx) => [
          for (final part in parts) ...[
            pw.Table(
              border: pw.TableBorder.all(width: 0.5),
              columnWidths: _group == 'GENERAL'
                  ? {
                      0: const pw.FixedColumnWidth(30),
                      1: const pw.FlexColumnWidth(6),
                      2: const pw.FlexColumnWidth(2),
                      3: const pw.FlexColumnWidth(2),
                    }
                  : {
                      0: const pw.FixedColumnWidth(30),
                      1: const pw.FlexColumnWidth(6),
                      2: const pw.FlexColumnWidth(2),
                    },
              children: [
                pw.TableRow(
                    children: _group == 'GENERAL'
                        ? [
                            cell('Nº', header: true),
                            cell('Nombre', header: true),
                            cell('RUT', header: true),
                            cell('LABOR', header: true)
                          ]
                        : [
                            cell('Nº', header: true),
                            cell('Nombre', header: true),
                            cell('RUT', header: true)
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

    return pdf.save();
  }

  Future<void> _downloadPdfAndroid(Uint8List bytes, String fileName) async {
    final dir = await getExternalStorageDirectory();
    final path = '${dir?.path}/$fileName';
    final file = File(path);
    await file.writeAsBytes(bytes, flush: true);
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
      final dir = await getApplicationDocumentsDirectory();
      final path = p.join(dir.path, fileName);
      await File(path).writeAsBytes(bytes, flush: true);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Guardado en: $path'),
          action: SnackBarAction(
              label: 'ABRIR', onPressed: () => OpenFilex.open(path)),
        ),
      );
      return;
    }
    await Printing.layoutPdf(onLayout: (_) async => bytes);
  }

  Future<void> _exportPdf(List<Map<String, dynamic>> entries,
      {required String mode}) async {
    final bytes = await _buildPdfBytes(entries);
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
              'Asistencia $_group del ${DateFormat('dd/MM/yyyy', 'es_CL').format(_selectedDate)}',
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
          'Asistencia $_group del ${DateFormat('dd/MM/yyyy', 'es_CL').format(_selectedDate)}',
      subject: 'Asistencia $_group',
    );
  }

  Widget _groupDropdown() {
    final items = <String>['GENERAL', ..._activeLists];
    return DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: _group.toUpperCase(),
        dropdownColor: primario,
        icon: const Icon(
          CupertinoIcons.chevron_down,
          size: 18,
          color: Colors.white,
        ),
        iconEnabledColor: Colors.white,
        borderRadius: const BorderRadius.all(Radius.circular(10)),
        style: const TextStyle(color: Colors.white),
        items: [
          for (final g in items)
            DropdownMenuItem(
              value: g.toUpperCase(),
              child: Text(g.toUpperCase(),
                  style: const TextStyle(color: Colors.white)),
            ),
          const DropdownMenuItem(
            value: '__add__',
            child: Text('+ Agregar', style: TextStyle(color: Colors.white)),
          ),
        ],
        onChanged: (v) async {
          if (v == null) return;
          if (v == '__add__') {
            await _showActivateListsSheet();
          } else {
            setState(() => _group = v.toUpperCase());
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        toolbarHeight: 224,
        flexibleSpace: Container(
          color: primario,
          padding: const EdgeInsets.only(top: 8, bottom: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
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
                    DateTime.now().subtract(const Duration(days: 10)),
                    controller: _dpCtrl,
                    initialSelectedDate: _selectedDate,
                    selectionColor: Colors.white,
                    selectedTextColor: primario,
                    locale: "es_CL",
                    daysCount: 365 * 2,
                    onDateChange: (d) {
                      setState(() => _selectedDate = normalizeDay(d));
                      _subscribeDayActiveLists();
                    },
                    dayTextStyle: const TextStyle(color: Colors.white),
                    monthTextStyle: const TextStyle(color: Colors.white),
                    dateTextStyle:
                        const TextStyle(color: Colors.white, fontSize: 18),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 20, 12, 4),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8.0,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white
                        .withOpacity(0.2), // Color de fondo para la barra
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  child: TextField(
                    controller: _search,
                    style: const TextStyle(color: Colors.white, fontSize: 18),
                    decoration: const InputDecoration(
                      hintText: 'Buscar por nombre o apellido...',
                      hintStyle: TextStyle(color: Colors.white70),
                      border: InputBorder.none,
                      icon: Icon(CupertinoIcons.search, color: Colors.white),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  children: [
                    const SizedBox(width: 8),
                    const Icon(CupertinoIcons.list_bullet_below_rectangle,
                        color: Colors.white, size: 18),
                    const SizedBox(width: 8),
                    Expanded(child: _groupDropdown()),
                    StreamBuilder<List<Map<String, dynamic>>>(
                      stream: AttendanceService.listenPresents(
                          _selectedDate, _group),
                      builder: (context, snap) {
                        final list = snap.data ?? const [];
                        return PopupMenuButton<String>(
                          tooltip: 'Exportar',
                          icon: const Icon(CupertinoIcons.arrow_down_doc,
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
                          endIndent: 12),
                      itemBuilder: (_, i) {
                        final w = _filtered[i];
                        return ListTile(
                          onTap: () async {
                            await _add(w);
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
                              if (mounted) setState(() {});
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
                        thickness: 0.2),
                    itemBuilder: (_, i) {
                      final e = entries[i];
                      final name = _displayNameFor(e).toUpperCase();
                      final rut = (e['rut'] ?? '').toString().toUpperCase();
                      final lst = (e['list'] ?? '').toString().toUpperCase();
                      return ListTile(
                        onTap: () {},
                        hoverColor: primario.withOpacity(0.06),
                        dense: true,
                        visualDensity:
                            const VisualDensity(horizontal: -2, vertical: -2),
                        minLeadingWidth: 28,
                        isThreeLine: true,
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 12),
                        leading: CircleAvatar(child: Text('${i + 1}')),
                        title: Text(name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            softWrap: false),
                        subtitle: Text(
                            _group == 'GENERAL' ? '$rut · $lst' : rut,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            softWrap: false),
                        trailing: IconButton(
                          tooltip: 'Quitar',
                          onPressed: () async {
                            final ok = await _confirmRemoveSheet(name);
                            if (ok) {
                              await _remove((e['workerId'] ?? '').toString());
                            }
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
  _Worker(
      {required this.id,
      required this.nombres,
      required this.apellidos,
      required this.rut});
}
