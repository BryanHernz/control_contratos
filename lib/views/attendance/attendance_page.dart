import 'dart:io';
import 'dart:math' as math;
import 'dart:async';

import 'package:animated_snack_bar/animated_snack_bar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:date_picker_timeline/date_picker_timeline.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:myapp/customs/constants_values.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../../customs/app_colors.dart';
import '../../customs/widgets/app_form.dart';
import '../../customs/widgets/app_modal.dart';
import '../../customs/widgets/app_skeleton.dart';
import '../../customs/widgets_custom.dart';
import '../../customs/widgets/page_header.dart';
import '../home/dashboard_page.dart' show kDashboardMaxWidth;
import '../../services/attendance_service.dart';
import '../../utils/normalize.dart';
import '../../services/firestore_db.dart';
import '../../services/trabajadores_repo.dart';

DateTime normalizeDay(DateTime d) => DateTime(d.year, d.month, d.day);

class AttendancePage extends StatefulWidget {
  const AttendancePage({super.key});

  @override
  State<AttendancePage> createState() => AttendancePageState();
}

class AttendancePageState extends State<AttendancePage> {
  DateTime _selectedDate = normalizeDay(DateTime.now());
  final _search = TextEditingController();
  final _dpCtrl = DatePickerController();

  StreamSubscription<List<String>>? _dayActiveListsSub;

  /// Resultados de la busqueda del autocompletado.
  ///
  /// Antes habia ademas una lista `_all` con los 675 trabajadores, cargada en
  /// vivo con `.snapshots()` cada vez que se abria Asistencia, solo para poder
  /// filtrarla en memoria. Ahora se consulta al escribir.
  List<_Worker> _filtered = [];
  bool _buscando = false;
  Timer? _debounceBusqueda;

  String _group = 'GENERAL';
  List<String> _activeLists = []; // always UPPERCASE

  @override
  void initState() {
    super.initState();
    _search.addListener(_onSearch);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _dpCtrl.animateToDate(_selectedDate.subtract(const Duration(days: 1)));
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
    _debounceBusqueda?.cancel();
    _search.removeListener(_onSearch);
    _search.dispose();

    _dayActiveListsSub?.cancel();
    super.dispose();
  }

  /// Nombre con que quedo registrada la asistencia.
  ///
  /// Antes se buscaba el trabajador en la lista completa para mostrar su
  /// nombre actual, y solo si no aparecia se usaba el guardado. Ahora se usa
  /// directamente el guardado -- que ademas es lo correcto para un registro
  /// historico: si a alguien le corrigen el nombre en marzo, la asistencia de
  /// enero debe seguir diciendo lo que decia en enero.
  String _displayNameFor(Map<String, dynamic> e) =>
      (e['name'] ?? '').toString().trim();

  String _sortKeyFor(Map<String, dynamic> e) => normalize(_displayNameFor(e));

  double _suggestionsHeight(BuildContext ctx) {
    const tileExtent = 56.0;
    const maxVisible = 8;
    final n = _filtered.length;
    final needed = tileExtent * math.min(n, maxVisible);
    final halfScreen = MediaQuery.of(ctx).size.height * 0.6;
    return math.min(needed, halfScreen);
  }

  /// Envoltura fina sobre [showAppModal] para no repetir el `context` en cada
  /// llamada de esta pantalla.
  Future<T?> _openAttendanceSheet<T>({
    required String title,
    required IconData icon,
    required Widget child,
    String? hint,
    bool danger = false,
    double maxWidth = kModalMaxWidth,
  }) {
    return showAppModal<T>(
      context: context,
      title: title,
      icon: icon,
      hint: hint,
      danger: danger,
      maxWidth: maxWidth,
      child: child,
    );
  }

  void _onSearch() {
    _debounceBusqueda?.cancel();
    if (_search.text.trim().isEmpty) {
      if (mounted) setState(() => _filtered = []);
      return;
    }
    // Con retardo: cada tecla seria una consulta.
    _debounceBusqueda = Timer(const Duration(milliseconds: 350), _buscar);
  }

  Future<void> _buscar() async {
    final texto = _search.text.trim();
    if (texto.isEmpty) return;
    setState(() => _buscando = true);
    try {
      final pagina = await TrabajadoresRepo.pagina(
        FiltrosTrabajadores(busqueda: texto),
        limite: 20,
      );
      if (!mounted) return;
      setState(() {
        _filtered = [
          for (final w in pagina.trabajadores)
            _Worker(
              id: w.id ?? '',
              nombres: w.name ?? '',
              apellidos: w.lastName ?? '',
              rut: w.rut ?? '',
            ),
        ];
        _buscando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _filtered = [];
        _buscando = false;
      });
    }
  }

  /// Todos los trabajadores, para el libro mensual.
  ///
  /// Es la unica parte que de verdad los necesita a todos, y es una accion
  /// explicita: no se paga al entrar a la pantalla.
  Future<List<_Worker>> _todosLosTrabajadores() async {
    final todos = <_Worker>[];
    DocumentSnapshot? cursor;
    var quedan = true;
    while (quedan && todos.length < 5000) {
      final pagina = await TrabajadoresRepo.pagina(
        const FiltrosTrabajadores(),
        desde: cursor,
        limite: 200,
      );
      todos.addAll([
        for (final w in pagina.trabajadores)
          _Worker(
            id: w.id ?? '',
            nombres: w.name ?? '',
            apellidos: w.lastName ?? '',
            rut: w.rut ?? '',
          ),
      ]);
      cursor = pagina.ultimo;
      quedan = pagina.hayMas && cursor != null;
    }
    return todos;
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
    final r = await _openAttendanceSheet<bool>(
      title: 'Quitar asistencia',
      icon: Icons.person_remove_alt_1_rounded,
      hint: 'Confirma para quitar al trabajador de la asistencia del dia.',
      danger: true,
      maxWidth: 620,
      child: AppDangerConfirmBody(
        message: 'Se quitara a ${displayName.toUpperCase()} de la lista '
            'actual.',
        onCancel: () => Navigator.pop(context, false),
        onConfirm: () => Navigator.pop(context, true),
        confirmText: 'Quitar',
        confirmIcon: Icons.person_remove_alt_1_rounded,
      ),
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
    AnimatedSnackBar.material(
      'Tipo creado. Ya puedes activarlo en el día.',
      type: AnimatedSnackBarType.success,
      mobileSnackBarPosition: MobileSnackBarPosition.bottom,
    ).show(context);
    Get.back();
  }

  Future<bool> _confirmDeleteListType(String listName) async {
    final r = await _openAttendanceSheet<bool>(
      title: 'Eliminar tipo de lista',
      icon: Icons.delete_outline_rounded,
      hint: 'Esta accion elimina el tipo del catalogo general.',
      danger: true,
      maxWidth: 620,
      child: AppDangerConfirmBody(
        message: 'Se eliminara ${listName.toUpperCase()} del listado.',
        detail: 'La asistencia historica no se eliminara.',
        onCancel: () => Navigator.pop(context, false),
        onConfirm: () => Navigator.pop(context, true),
        confirmText: 'Eliminar',
        confirmIcon: Icons.delete_rounded,
      ),
    );
    return r == true;
  }

  Future<void> _showActivateListsSheet() async {
    final picked = <String>{};
    await _openAttendanceSheet<void>(
      title: 'Activar listas del dia',
      icon: Icons.playlist_add_check_circle_outlined,
      hint: 'Selecciona una o mas listas para dejarlas activas en esta fecha.',
      maxWidth: 760,
      child: StatefulBuilder(
        builder: (context, setSt) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: AppModalBody(
                  child: StreamBuilder<List<String>>(
                    stream: AttendanceService.listenAllListTypes(),
                    builder: (context, snap) {
                      final tipos = (snap.data ?? [])
                          .map((t) => t.toUpperCase())
                          .toList();
                      tipos.sort(
                          (a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
                      final activeSet =
                          _activeLists.map((e) => e.toUpperCase()).toSet();
                      final candidates =
                          tipos.where((t) => !activeSet.contains(t)).toList();

                      if (candidates.isEmpty) {
                        return const AppEmptyNotice(
                          icon: Icons.playlist_add_rounded,
                          message: 'No hay mas tipos disponibles.',
                          detail: 'Crea uno nuevo para continuar.',
                        );
                      }

                      return AppFormSection(
                        title: 'Tipos disponibles',
                        icon: Icons.list_alt_rounded,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                for (final text in candidates)
                                  _listTypeChip(
                                    label: text,
                                    selected: picked.contains(text),
                                    onSelected: (selected) => setSt(() {
                                      if (selected) {
                                        picked.add(text);
                                      } else {
                                        picked.remove(text);
                                      }
                                    }),
                                    onLongPress: () async {
                                      final confirm =
                                          await _confirmDeleteListType(text);
                                      if (!confirm) return;
                                      await AttendanceService.removeListType(
                                          text);
                                      if (!context.mounted) return;
                                      AnimatedSnackBar.material(
                                        'Lista "$text" eliminada correctamente.',
                                        type: AnimatedSnackBarType.success,
                                        mobileSnackBarPosition:
                                            MobileSnackBarPosition.bottom,
                                      ).show(context);
                                    },
                                  ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            // Borrar un tipo solo se podia con pulsacion larga
                            // y nada lo decia: con mouse era invisible.
                            const Text(
                              'Manten pulsado un tipo para eliminarlo del '
                              'catalogo.',
                              style: TextStyle(
                                color: AppColors.textFaint,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
                child: CustomButton(
                  funcion: () async {
                    await _showCreateTypeSheet();
                    setSt(() {});
                  },
                  texto: 'Crear nuevo tipo',
                  cancelar: true,
                  icon: Icons.add_rounded,
                  width: double.infinity,
                ),
              ),
              AppFormFooter(
                cancelText: 'Cerrar',
                onCancel: () => Navigator.of(context).pop(),
                onConfirm: () {
                  if (picked.isNotEmpty) {
                    _activatePickedLists(picked);
                  } else {
                    Navigator.of(context).pop();
                  }
                },
                confirmText: 'Activar',
                confirmIcon: Icons.check_rounded,
              ),
            ],
          );
        },
      ),
    );
  }

  /// Chip de tipo de lista. Esquinas apenas suavizadas y sin contorno, igual
  /// que el chip de estado del detalle de trabajador y el badge del modal.
  ///
  /// Sin seleccionar necesita fondo propio: al quitarle el borde, un chip
  /// blanco sobre la tarjeta dejaria de leerse como chip.
  Widget _listTypeChip({
    required String label,
    required bool selected,
    required ValueChanged<bool> onSelected,
    VoidCallback? onLongPress,
  }) {
    final chip = ChoiceChip(
      label: Text(label.toUpperCase()),
      selected: selected,
      selectedColor: primario,
      backgroundColor: selected ? primario : AppColors.surfaceSunken,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(4)),
      ),
      side: BorderSide.none,
      labelStyle: TextStyle(
        color: selected ? Colors.white : AppColors.textBody,
        fontWeight: FontWeight.w700,
        fontSize: 12.5,
      ),
      onSelected: onSelected,
    );

    if (onLongPress == null) return chip;
    return GestureDetector(onLongPress: onLongPress, child: chip);
  }

  Future<String?> _showPickActiveListSheet() async {
    String? picked;

    return _openAttendanceSheet<String>(
      title: 'Seleccionar lista',
      icon: Icons.playlist_play_rounded,
      hint: 'Elige la lista en la que deseas agregar al trabajador.',
      maxWidth: 760,
      child: StatefulBuilder(
        builder: (context, setSt) {
          final actives = [..._activeLists]
            ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: AppModalBody(
                  child: actives.isEmpty
                      ? const AppEmptyNotice(
                          icon: Icons.playlist_remove_rounded,
                          message: 'No hay listas activas para hoy.',
                          detail: 'Agrega al menos una para poder registrar '
                              'asistencia.',
                        )
                      : AppFormSection(
                          title: 'Listas activas del dia',
                          icon: Icons.playlist_play_rounded,
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (final t in actives)
                                _listTypeChip(
                                  label: t,
                                  selected: picked == t,
                                  onSelected: (sel) =>
                                      setSt(() => picked = sel ? t : null),
                                ),
                            ],
                          ),
                        ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
                child: CustomButton(
                  funcion: () async {
                    await _showActivateListsSheet();
                    setSt(() {});
                  },
                  texto: 'Agregar listas del dia',
                  cancelar: true,
                  icon: Icons.add_rounded,
                  width: double.infinity,
                ),
              ),
              AppFormFooter(
                onCancel: () => Navigator.pop(context, null),
                onConfirm: () => Navigator.pop(context, picked),
                confirmText: 'Usar lista',
                confirmIcon: Icons.check_rounded,
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _showCreateTypeSheet() async {
    final ctrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    await _openAttendanceSheet<bool>(
      title: 'Nuevo tipo de lista',
      icon: Icons.add_box_outlined,
      hint: 'Crea un nuevo tipo para usarlo en la asistencia diaria.',
      maxWidth: 620,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: AppModalBody(
              child: Form(
                key: formKey,
                child: InputTextField(
                  textController: ctrl,
                  hint: 'Nombre (ej: PODA, COSECHA)',
                  onFieldSubmitted: (_) {
                    if (formKey.currentState!.validate()) {
                      formKey.currentState!.save();
                      _submitCreateType(formKey, ctrl);
                    }
                  },
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Ingresa un nombre';
                    }
                    return null;
                  },
                ),
              ),
            ),
          ),
          AppFormFooter(
            onCancel: () => Navigator.pop(context),
            onConfirm: () {
              if (formKey.currentState!.validate()) {
                formKey.currentState!.save();
                _submitCreateType(formKey, ctrl);
              }
            },
            confirmText: 'Agregar',
            confirmIcon: Icons.add_rounded,
          ),
        ],
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
              fontSize: header ? 10 : 9,
              fontWeight: header ? pw.FontWeight.bold : pw.FontWeight.normal,
              color: header ? PdfColors.white : PdfColors.black,
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
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.center, children: [
              pw.Container(
                width: 5,
                height: 30,
                color: PdfColor.fromHex('#455A64'),
                margin: const pw.EdgeInsets.only(right: 15),
              ),
              pw.Text(
                'REPORTE DIARIO DE ASISTENCIA: $fecha - $listTitle',
                style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColor.fromHex('#455A64')),
              ),
            ]),
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
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
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
                    decoration:
                        pw.BoxDecoration(color: PdfColor.fromHex('#455A64')),
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
    await Share.shareXFiles(
      [XFile(path, mimeType: 'application/pdf')],
      text:
          'Asistencia $_group del ${DateFormat('dd/MM/yyyy', 'es_CL').format(_selectedDate)}',
      subject: 'Asistencia $_group',
    );
  }

  // --- EXPORTAR ASISTENCIA MENSUAL A PDF ---
  Future<void> exportMonthlyAttendanceToPDF() async {
    // Mostrar modal decarga porque esto tomará unos segundos consultando 30/31 días
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 16),
            Text(
              "Generando Libro de Asistencia...",
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            )
          ],
        ),
      ),
    );

    try {
      final selectedMonth = _selectedDate.month;
      final selectedYear = _selectedDate.year;
      final daysInMonth = DateUtils.getDaysInMonth(selectedYear, selectedMonth);

      Map<String, List<dynamic>> monthlyData = {};

      final todos = await _todosLosTrabajadores();
      for (var w in todos) {
        List<dynamic> row = [
          '${w.nombres} ${w.apellidos}'.toUpperCase(),
          w.rut.toUpperCase()
        ];
        // 31 dias vacios
        for (int i = 0; i < daysInMonth; i++) {
          row.add('');
        }
        row.add(0); // Total final
        monthlyData[w.id] = row;
      }

      for (int i = 1; i <= daysInMonth; i++) {
        final currentDayDate = DateTime(selectedYear, selectedMonth, i);
        final dayKey = AttendanceService.dateKeyFrom(currentDayDate);
        final docSnapshot =
            await db.collection('Asistencias').doc(dayKey).get();

        if (docSnapshot.exists) {
          final data = docSnapshot.data();
          final presentes =
              (data?['presentes'] as Map?)?.cast<String, dynamic>() ?? {};

          for (var entry in presentes.values) {
            final workerId = (entry['workerId'] ?? '').toString();
            if (monthlyData.containsKey(workerId)) {
              monthlyData[workerId]![1 + i] = 'X'; // Indice Nombre, Rut, + dia
              monthlyData[workerId]!.last =
                  (monthlyData[workerId]!.last as int) + 1;
            }
          }
        }
      }

      // Preparar PDF
      final pdf = pw.Document();
      var cambria = await rootBundle.load("lib/images/Cambria.ttf");
      var calibri = await rootBundle.load("lib/images/Calibri Regular.ttf");
      var calibriBold = await rootBundle.load("lib/images/Calibri Bold.ttf");

      List<String> headers = ["Trabajador", "RUT"];
      for (int i = 1; i <= daysInMonth; i++) {
        headers.add(i.toString());
      }
      headers.add("T");

      // Filtrar y preparar data array
      List<List<String>> tableData = [];
      for (var row in monthlyData.values) {
        if ((row.last as int) > 0) {
          tableData.add(row.map((e) => e.toString()).toList());
        }
      }

      final String monthName =
          DateFormat('MMMM yyyy', 'es_CL').format(_selectedDate);

      // Calcular KPIs
      int totalAsistencias = 0;
      for (var row in tableData) {
        totalAsistencias += int.parse(row.last);
      }
      double prom = daysInMonth > 0 ? totalAsistencias / daysInMonth : 0;
      String promedioAsistencias = prom.toStringAsFixed(1);

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4.landscape,
          maxPages: 1000,
          margin: const pw.EdgeInsets.all(20),
          build: (context) => [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Container(
                      width: 5,
                      height: 35,
                      color: PdfColor.fromHex('#455A64'),
                      margin: const pw.EdgeInsets.only(right: 15),
                    ),
                    pw.Header(
                      level: 0,
                      child: pw.Text(
                        'LIBRO DE ASISTENCIA: ${monthName.toUpperCase()}',
                        style: pw.TextStyle(
                          font: pw.Font.ttf(cambria),
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 14,
                          color: PdfColor.fromHex('#455A64'),
                        ),
                      ),
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('Trabajadores Activos: ${tableData.length}',
                        style: pw.TextStyle(
                            font: pw.Font.ttf(calibri),
                            fontSize: 10,
                            color: PdfColors.grey700)),
                    pw.Text('Total Asistencias: $totalAsistencias',
                        style: pw.TextStyle(
                            font: pw.Font.ttf(calibri),
                            fontSize: 10,
                            color: PdfColors.grey700)),
                    pw.Text('Promedio Diario: $promedioAsistencias',
                        style: pw.TextStyle(
                            font: pw.Font.ttf(calibri),
                            fontSize: 10,
                            color: PdfColors.grey700)),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 15),
            pw.TableHelper.fromTextArray(
                headers: headers,
                data: tableData,
                border: pw.TableBorder.all(color: PdfColors.grey300),
                headerStyle: pw.TextStyle(
                  font: pw.Font.ttf(calibriBold),
                  color: PdfColors.white,
                  fontSize: 8,
                ),
                headerDecoration:
                    pw.BoxDecoration(color: PdfColor.fromHex('#455A64')),
                cellStyle: pw.TextStyle(
                  font: pw.Font.ttf(calibri),
                  fontSize: 7,
                ),
                cellAlignment: pw.Alignment.center,
                // Forzar alineacion a la izquierda solo para el nombre y el rut
                cellAlignments: {
                  0: pw.Alignment.centerLeft,
                  1: pw.Alignment.centerLeft,
                }),
          ],
        ),
      );

      if (mounted) Navigator.pop(context); // Cerrar loader

      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
        name: 'Asistencia_$monthName.pdf',
      );
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        AnimatedSnackBar.material(
          'Error generando reporte: $e',
          type: AnimatedSnackBarType.error,
          mobileSnackBarPosition: MobileSnackBarPosition.bottom,
        ).show(context);
      }
    }
  }

  Widget _groupDropdown() {
    final items = <String>['GENERAL', ..._activeLists];
    // Antes el menu se pintaba invertido en movil (blanco sobre `primario`) y
    // normal en escritorio: el mismo control se veia distinto segun el ancho.
    const itemStyle = TextStyle(
      color: AppColors.textStrong,
      fontSize: 14,
      fontWeight: FontWeight.w700,
    );

    return DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: _group.toUpperCase(),
        isDense: true,
        dropdownColor: Colors.white,
        icon: const Icon(
          CupertinoIcons.chevron_down,
          size: 16,
          color: AppColors.iconMuted,
        ),
        borderRadius: const BorderRadius.all(Radius.circular(14)),
        style: itemStyle,
        items: [
          for (final g in items)
            DropdownMenuItem(
              value: g.toUpperCase(),
              child: Text(g.toUpperCase(), style: itemStyle),
            ),
          DropdownMenuItem(
            value: '__add__',
            child: Text(
              '+ AGREGAR NUEVA LISTA',
              style: itemStyle.copyWith(color: primario),
            ),
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

  /// Alto comun de los tres controles de la barra. Antes cada uno media lo que
  /// le salia -- el buscador por su TextField, el selector por su padding y el
  /// boton de exportar por su icono -- y quedaban escalonados.
  static const double _kControlHeight = 52;

  BoxDecoration get _controlDecoration => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      );

  // Extraemos los controles que antes estaban en el AppBar
  Widget _buildControls(bool isDesktop) {
    final searchBox = Container(
      height: _kControlHeight,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: _controlDecoration,
      // El icono y el boton de limpiar van en una Row propia, no como
      // `prefixIcon`/`suffixIcon`. Dejarselos al InputDecorator obligaba a
      // pelear con su padding vertical interno -- el texto quedaba apoyado
      // arriba del campo en vez de centrado. Con `isCollapsed` el TextField
      // mide exactamente lo que mide su texto y quien centra es la Row.
      child: Row(
        children: [
          const Icon(
            CupertinoIcons.search,
            size: 20,
            color: AppColors.iconMuted,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _search,
              textAlignVertical: TextAlignVertical.center,
              style: const TextStyle(
                color: AppColors.textStrong,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
              decoration: const InputDecoration(
                isCollapsed: true,
                border: InputBorder.none,
                hintText: 'Buscar por nombre o apellido...',
                hintStyle: TextStyle(
                  color: AppColors.textFaint,
                  fontSize: 14.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          if (_search.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.close_rounded, size: 18),
              color: AppColors.iconMuted,
              tooltip: 'Limpiar',
              onPressed: () => _search.clear(),
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            ),
        ],
      ),
    );

    final groupBox = Container(
      height: _kControlHeight,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: _controlDecoration,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            CupertinoIcons.list_bullet_below_rectangle,
            color: AppColors.iconMuted,
            size: 18,
          ),
          const SizedBox(width: 10),
          _groupDropdown(),
        ],
      ),
    );

    final exportButton = StreamBuilder<List<Map<String, dynamic>>>(
      stream: AttendanceService.listenPresents(_selectedDate, _group),
      builder: (context, snap) {
        final data = snap.data ?? const <Map<String, dynamic>>[];
        // Sin asistentes no hay nada que exportar: antes el boton se veia
        // igual de activo y al pulsarlo no pasaba nada.
        final habilitado = data.isNotEmpty;

        return Container(
          width: _kControlHeight,
          height: _kControlHeight,
          decoration: _controlDecoration,
          child: PopupMenuButton<String>(
            tooltip: habilitado ? 'Exportar' : 'No hay asistentes que exportar',
            enabled: habilitado,
            icon: Icon(
              CupertinoIcons.arrow_down_doc,
              size: 20,
              color: habilitado ? primario : AppColors.border,
            ),
            onSelected: (v) async {
              if (v == 'download') {
                await _exportPdf(data, mode: 'download');
              } else {
                await _exportPdf(data, mode: 'share');
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'download', child: Text('Descargar PDF')),
              PopupMenuItem(value: 'share', child: Text('Compartir PDF')),
            ],
          ),
        );
      },
    );

    return Container(
      color: AppColors.background,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      // El panel de controles respeta el mismo tope que el listado de abajo,
      // o en un monitor ancho quedaba estirado sobre una tabla mas angosta.
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: kDashboardMaxWidth - 32),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: appCardDecoration(),
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
                      selectionColor: primario,
                      selectedTextColor: Colors.white,
                      locale: "es_CL",
                      daysCount: 365 * 2,
                      onDateChange: (d) {
                        setState(() => _selectedDate = normalizeDay(d));
                        _subscribeDayActiveLists();
                      },
                      dayTextStyle: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                      ),
                      monthTextStyle: const TextStyle(
                        color: AppColors.textFaint,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                      ),
                      dateTextStyle: const TextStyle(
                        color: AppColors.textStrong,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                if (isDesktop)
                  Row(
                    children: [
                      Expanded(child: searchBox),
                      const SizedBox(width: 12),
                      groupBox,
                      const SizedBox(width: 8),
                      exportButton,
                    ],
                  ),
                if (!isDesktop)
                  Column(
                    children: [
                      searchBox,
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(child: groupBox),
                          const SizedBox(width: 8),
                          exportButton,
                        ],
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 800;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          PageHeader(
            title: 'Asistencia',
            subtitle: 'Registro y control diario de personal',
            icon: CupertinoIcons.calendar_today,
            rightWidget: IconButton(
              icon: const Icon(CupertinoIcons.doc_chart, color: Colors.white),
              tooltip: 'Exportar Reporte Mensual (PDF)',
              onPressed: () => exportMonthlyAttendanceToPDF(),
            ),
          ),
          _buildControls(isDesktop),
          Expanded(
            // Mismo tope de ancho que el dashboard y Trabajadores.
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: kDashboardMaxWidth),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: Container(
                    decoration: appCardDecoration(),
                    clipBehavior: Clip.antiAlias,
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          if (_search.text.isNotEmpty)
                            Container(
                              width: double.infinity,
                              margin: const EdgeInsets.fromLTRB(12, 12, 12, 4),
                              decoration: BoxDecoration(
                                // Fondo hundido: es un panel flotante sobre la
                                // tarjeta, no otra tarjeta blanca encima.
                                color: AppColors.surfaceSunken,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: AppColors.border),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: _buscando
                                  ? const Padding(
                                      padding:
                                          EdgeInsets.symmetric(vertical: 28),
                                      child: Center(
                                        child: SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2),
                                        ),
                                      ),
                                    )
                                  : _filtered.isEmpty
                                      ? const AppEmptyNotice(
                                          decorated: false,
                                          icon: Icons.search_off_rounded,
                                          message:
                                              'Ningun trabajador coincide.',
                                          detail: 'Se busca por el comienzo '
                                              'del nombre, apellido o RUT.',
                                        )
                                      : SizedBox(
                                          height: _suggestionsHeight(context),
                                          child: ListView.separated(
                                            padding: EdgeInsets.zero,
                                            physics: _filtered.length <= 8
                                                ? const NeverScrollableScrollPhysics()
                                                : const ClampingScrollPhysics(),
                                            itemCount: _filtered.length,
                                            separatorBuilder: (_, __) =>
                                                const Divider(
                                              height: 1,
                                              thickness: 1,
                                              color: AppColors.divider,
                                              indent: 12,
                                              endIndent: 12,
                                            ),
                                            itemBuilder: (_, i) {
                                              final w = _filtered[i];
                                              return ListTile(
                                                onTap: () async => _add(w),
                                                hoverColor:
                                                    primario.withOpacity(0.08),
                                                dense: true,
                                                visualDensity:
                                                    const VisualDensity(
                                                        horizontal: -2,
                                                        vertical: -2),
                                                contentPadding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 12),
                                                title: Text(
                                                  '${w.apellidos.toUpperCase()} ${w.nombres.toUpperCase()}',
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  softWrap: false,
                                                  style: const TextStyle(
                                                    color: AppColors.textStrong,
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                                subtitle: Text(
                                                  w.rut.toUpperCase(),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  softWrap: false,
                                                  style: const TextStyle(
                                                    color: AppColors.textMuted,
                                                    fontSize: 12.5,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                                trailing: IconButton(
                                                  tooltip:
                                                      'Agregar a asistencia',
                                                  onPressed: () async {
                                                    await _add(w);
                                                    _search.clear();
                                                    if (mounted) {
                                                      setState(() {});
                                                    }
                                                  },
                                                  icon: Icon(
                                                    Icons.add_rounded,
                                                    size: 20,
                                                    color: primario,
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                            ),
                          StreamBuilder<List<Map<String, dynamic>>>(
                            stream: AttendanceService.listenPresents(
                                _selectedDate, _group),
                            builder: (context, snap) {
                              if (snap.hasError) {
                                return const AppEmptyNotice(
                                  decorated: false,
                                  icon: Icons.cloud_off_rounded,
                                  message: 'No se pudo cargar la asistencia.',
                                  detail: 'Revisa la conexion y vuelve a '
                                      'intentar.',
                                );
                              }
                              if (!snap.hasData) {
                                return const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 8),
                                  child: SkeletonFilas(filas: 6),
                                );
                              }
                              final entries = snap.data!;
                              if (entries.isEmpty) {
                                // Dos vacios distintos: sin listas activas no
                                // hay donde registrar, y con lista activa lo
                                // que falta es buscar al trabajador. Antes los
                                // dos decian lo mismo.
                                return _activeLists.isEmpty
                                    ? AppEmptyNotice(
                                        decorated: false,
                                        icon: Icons.playlist_remove_rounded,
                                        message: 'No hay listas activas para '
                                            'esta fecha.',
                                        detail: 'Activa al menos una para '
                                            'poder registrar asistencia.',
                                        actionLabel: 'Activar listas',
                                        actionIcon:
                                            Icons.playlist_add_check_rounded,
                                        onAction: _showActivateListsSheet,
                                      )
                                    : const AppEmptyNotice(
                                        decorated: false,
                                        icon: Icons.person_search_rounded,
                                        message: 'Aun no hay asistentes en '
                                            'esta lista.',
                                        detail: 'Busca un trabajador por '
                                            'nombre o RUT para agregarlo.',
                                      );
                              }
                              entries.sort(
                                (a, b) =>
                                    _sortKeyFor(a).compareTo(_sortKeyFor(b)),
                              );

                              return ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: entries.length,
                                separatorBuilder: (_, __) => const Divider(
                                  height: 1,
                                  indent: 20,
                                  endIndent: 20,
                                  color: AppColors.divider,
                                  thickness: 1,
                                ),
                                itemBuilder: (_, i) {
                                  final e = entries[i];
                                  final name = _displayNameFor(e).toUpperCase();
                                  final rut =
                                      (e['rut'] ?? '').toString().toUpperCase();
                                  final lst = (e['list'] ?? '')
                                      .toString()
                                      .toUpperCase();
                                  return ListTile(
                                    hoverColor: primario.withOpacity(0.05),
                                    dense: true,
                                    visualDensity: const VisualDensity(
                                        horizontal: -2, vertical: -2),
                                    minLeadingWidth: 28,
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 6),
                                    // Chip cuadrado, igual que el indice de los
                                    // listados de ajustes. El CircleAvatar
                                    // anterior era el unico circulo de la app.
                                    leading: Container(
                                      width: 28,
                                      height: 28,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: primario.withOpacity(0.10),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        '${i + 1}',
                                        style: TextStyle(
                                          color: primario,
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                    title: Text(
                                      name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      softWrap: false,
                                      style: const TextStyle(
                                        color: AppColors.textStrong,
                                        fontSize: 14.5,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    subtitle: Text(
                                      _group == 'GENERAL' ? '$rut · $lst' : rut,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      softWrap: false,
                                      style: const TextStyle(
                                        color: AppColors.textMuted,
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    // Rojo: es la accion destructiva de la
                                    // fila y venia del mismo color que el
                                    // resto de los iconos.
                                    trailing: IconButton(
                                      tooltip: 'Quitar de la asistencia',
                                      onPressed: () async {
                                        final ok =
                                            await _confirmRemoveSheet(name);
                                        if (ok) {
                                          await _remove(
                                              (e['workerId'] ?? '').toString());
                                        }
                                      },
                                      icon: Icon(
                                        Icons.delete_outline_rounded,
                                        size: 20,
                                        color: Colors.red.shade400,
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ],
                      ),
                    ),
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
