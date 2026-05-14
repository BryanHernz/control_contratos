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

import '../../customs/widgets_custom.dart';
import '../../customs/widgets/page_header.dart';
import '../../services/attendance_service.dart';
import '../../utils/normalize.dart';

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

  List<_Worker> _all = [];
  List<_Worker> _filtered = [];

  String _group = 'GENERAL';
  List<String> _activeLists = []; // always UPPERCASE

  @override
  void initState() {
    super.initState();
    _search.addListener(_onSearch);
    _listenWorkers();

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
    _search.removeListener(_onSearch);
    _search.dispose();

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

  double _sheetMaxWidth(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width > 980) return 920;
    return width * 0.96;
  }

  Future<T?> _openAttendanceSheet<T>({
    required String title,
    required IconData icon,
    required Widget child,
    String? hint,
    bool danger = false,
    double? maxWidth,
  }) async {
    final media = MediaQuery.of(context);

    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => AnimatedPadding(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
        ),
        child: SafeArea(
          top: false,
          child: Align(
            alignment: Alignment.bottomCenter,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: maxWidth ?? _sheetMaxWidth(context),
                maxHeight: media.size.height * 0.92,
              ),
              child: Container(
                decoration: const BoxDecoration(
                  color: Color(0xFFF4F7FA),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                clipBehavior: Clip.hardEdge,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _AttendanceSheetHeader(
                      title: title,
                      icon: icon,
                      danger: danger,
                    ),
                    if (hint != null && hint.trim().isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
                        child: _AttendanceHint(text: hint),
                      ),
                    Flexible(child: child),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
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

  // ignore: unused_element
  Future<bool> _confirmRemoveSheetLegacy(String displayName) async {
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

  Future<bool> _confirmRemoveSheet(String displayName) async {
    final r = await _openAttendanceSheet<bool>(
      title: 'Quitar asistencia',
      icon: Icons.person_remove_alt_1_rounded,
      hint: 'Confirma para quitar al trabajador de la asistencia del dia.',
      danger: true,
      maxWidth: 640,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Text(
                'Se quitara a ${displayName.toUpperCase()} de la lista actual.',
                style: TextStyle(
                  color: Colors.red.shade700,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: CustomButton(
                    funcion: () => Navigator.pop(context, false),
                    texto: 'Cancelar',
                    cancelar: true,
                    icon: Icons.close_rounded,
                    width: double.infinity,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade600,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      minimumSize: const Size.fromHeight(52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () => Navigator.pop(context, true),
                    icon:
                        const Icon(Icons.person_remove_alt_1_rounded, size: 18),
                    label: const Text('Quitar'),
                  ),
                ),
              ],
            ),
          ],
        ),
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

  // ignore: unused_element
  Future<bool> _confirmDeleteListTypeLegacy(String listName) async {
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
                Text('Eliminar tipo de lista',
                    style: Theme.of(ctx)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(
                    '¿Estás seguro de eliminar el tipo de lista:\n${listName.toUpperCase()}?',
                    textAlign: TextAlign.center),
                const SizedBox(height: 8),
                const Text(
                    'Esto no eliminará la asistencia histórica asociada.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Colors.grey)),
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
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red),
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('Sí, eliminar',
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

  Future<bool> _confirmDeleteListType(String listName) async {
    final r = await _openAttendanceSheet<bool>(
      title: 'Eliminar tipo de lista',
      icon: Icons.delete_outline_rounded,
      hint: 'Esta accion elimina el tipo del catalogo general.',
      danger: true,
      maxWidth: 640,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Se eliminara ${listName.toUpperCase()} del listado.',
                    style: TextStyle(
                      color: Colors.red.shade700,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'La asistencia historica no se eliminara.',
                    style: TextStyle(
                      color: Colors.red.shade600,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: CustomButton(
                    funcion: () => Navigator.pop(context, false),
                    texto: 'Cancelar',
                    cancelar: true,
                    icon: Icons.close_rounded,
                    width: double.infinity,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade600,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      minimumSize: const Size.fromHeight(52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () => Navigator.pop(context, true),
                    icon: const Icon(Icons.delete_rounded, size: 18),
                    label: const Text('Eliminar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
    return r == true;
  }

  // ignore: unused_element
  Future<void> _showActivateListsSheetLegacy() async {
    final picked = <String>{};
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width > 800
              ? 900
              : MediaQuery.of(context).size.width * 0.95),
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.0)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSt) {
            return SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(ctx).viewInsets.bottom,
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Center(
                          child: Container(
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              color: Colors.black12,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Center(
                          child: Text(
                            'Agregar listas al día',
                            style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                                fontSize: 16),
                          ),
                        ),
                        const SizedBox(height: 12),
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

                            return Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              alignment: WrapAlignment.center,
                              children: candidates.map((text) {
                                final isSelected = picked.contains(text);
                                return GestureDetector(
                                  onLongPress: () async {
                                    final confirm =
                                        await _confirmDeleteListType(text);
                                    if (confirm) {
                                      await AttendanceService.removeListType(
                                          text);
                                      // Force refresh is handled by stream builder
                                      if (context.mounted) {
                                        AnimatedSnackBar.material(
                                          'Lista "$text" eliminada correctamente.',
                                          type: AnimatedSnackBarType.success,
                                          mobileSnackBarPosition:
                                              MobileSnackBarPosition.bottom,
                                        ).show(context);
                                      }
                                    }
                                  },
                                  child: ChoiceChip(
                                    label: Text(text),
                                    selected: isSelected,
                                    selectedColor: primario,
                                    labelStyle: TextStyle(
                                      color: isSelected
                                          ? Colors.white
                                          : Colors.black,
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                                    backgroundColor: Colors.grey.shade200,
                                    onSelected: (selected) {
                                      setSt(() {
                                        if (selected) {
                                          picked.add(text);
                                        } else {
                                          picked.remove(text);
                                        }
                                      });
                                    },
                                  ),
                                );
                              }).toList(),
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
              ),
            );
          },
        );
      },
    );
  }

  // ignore: unused_element
  Future<String?> _showPickActiveListSheetLegacy() async {
    String? picked;

    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width > 800
              ? 900
              : MediaQuery.of(context).size.width * 0.95),
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                child: StatefulBuilder(
                  builder: (ctx, setSt) {
                    final actives = [..._activeLists]..sort(
                        (a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

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
                        const Text(
                          'Selecciona lista',
                          style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 16),
                        ),
                        const SizedBox(height: 12),
                        if (actives.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Text(
                                'No hay listas activas hoy. Agrega alguna.'),
                          ),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
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
                                await _showActivateListsSheet();
                                setSt(() {});
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
            ),
          ),
        );
      },
    );
  }

  // ignore: unused_element
  Future<void> _showCreateTypeSheetLegacy() async {
    final ctrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width > 800
                ? 900
                : MediaQuery.of(context).size.width * 0.95),
        backgroundColor: Colors.transparent,
        builder: (context) {
          return SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                padding: const EdgeInsets.all(16.0),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(16.0)),
                ),
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.black12,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Center(
                        child: Text(
                          'Nuevo tipo de lista',
                          style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 16),
                        ),
                      ),
                      const SizedBox(height: 16),
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
                      const SizedBox(height: 16),
                      Row(
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
                    ],
                  ),
                ),
              ),
            ),
          );
        });
  }

  Future<void> _showActivateListsSheet() async {
    final picked = <String>{};
    await _openAttendanceSheet<void>(
      title: 'Activar listas del dia',
      icon: Icons.playlist_add_check_circle_outlined,
      hint: 'Selecciona una o mas listas para dejarlas activas en esta fecha.',
      child: StatefulBuilder(
        builder: (context, setSt) {
          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
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
                      tipos.sort(
                          (a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
                      final activeSet =
                          _activeLists.map((e) => e.toUpperCase()).toSet();
                      final candidates =
                          tipos.where((t) => !activeSet.contains(t)).toList();

                      if (candidates.isEmpty) {
                        return Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 18),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.blueGrey.shade100),
                          ),
                          child: Text(
                            'No hay mas tipos disponibles. Crea uno nuevo para continuar.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.blueGrey.shade600,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        );
                      }

                      return Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        alignment: WrapAlignment.center,
                        children: candidates.map((text) {
                          final isSelected = picked.contains(text);
                          return GestureDetector(
                            onLongPress: () async {
                              final confirm =
                                  await _confirmDeleteListType(text);
                              if (confirm) {
                                await AttendanceService.removeListType(text);
                                if (context.mounted) {
                                  AnimatedSnackBar.material(
                                    'Lista "$text" eliminada correctamente.',
                                    type: AnimatedSnackBarType.success,
                                    mobileSnackBarPosition:
                                        MobileSnackBarPosition.bottom,
                                  ).show(context);
                                }
                              }
                            },
                            child: ChoiceChip(
                              label: Text(text),
                              selected: isSelected,
                              selectedColor: primario,
                              backgroundColor: Colors.white,
                              side: BorderSide(
                                color: isSelected
                                    ? primario
                                    : Colors.blueGrey.shade100,
                              ),
                              labelStyle: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : Colors.blueGrey.shade700,
                                fontWeight: FontWeight.w700,
                              ),
                              onSelected: (selected) {
                                setSt(() {
                                  if (selected) {
                                    picked.add(text);
                                  } else {
                                    picked.remove(text);
                                  }
                                });
                              },
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
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
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: CustomButton(
                          funcion: () => Navigator.of(context).pop(),
                          texto: 'Cerrar',
                          cancelar: true,
                          icon: Icons.close_rounded,
                          width: double.infinity,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: CustomButton(
                          funcion: () {
                            if (picked.isNotEmpty) {
                              _activatePickedLists(picked);
                            } else {
                              Navigator.of(context).pop();
                            }
                          },
                          texto: 'Activar',
                          cancelar: false,
                          icon: Icons.check_rounded,
                          width: double.infinity,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
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

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (actives.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.blueGrey.shade100),
                      ),
                      child: Text(
                        'No hay listas activas para hoy. Agrega al menos una lista.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.blueGrey.shade600,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  if (actives.isNotEmpty)
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final t in actives)
                          ChoiceChip(
                            label: Text(t.toUpperCase()),
                            selected: picked == t,
                            selectedColor: primario,
                            backgroundColor: Colors.white,
                            side: BorderSide(
                              color: picked == t
                                  ? primario
                                  : Colors.blueGrey.shade100,
                            ),
                            labelStyle: TextStyle(
                              color: picked == t
                                  ? Colors.white
                                  : Colors.blueGrey.shade700,
                              fontWeight: FontWeight.w700,
                            ),
                            onSelected: (sel) =>
                                setSt(() => picked = sel ? t : null),
                          ),
                      ],
                    ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
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
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: CustomButton(
                          funcion: () => Navigator.pop(context, null),
                          texto: 'Cancelar',
                          cancelar: true,
                          icon: Icons.close_rounded,
                          width: double.infinity,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: CustomButton(
                          funcion: () => Navigator.pop(context, picked),
                          texto: 'Usar lista',
                          cancelar: false,
                          icon: Icons.check_rounded,
                          width: double.infinity,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
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
      maxWidth: 760,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                InputTextField(
                  textController: ctrl,
                  hint: 'Nombre (ej: PODA, COSECHA)',
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Ingresa un nombre';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: CustomButton(
                        funcion: () => Navigator.pop(context),
                        texto: 'Cancelar',
                        cancelar: true,
                        icon: Icons.close_rounded,
                        width: double.infinity,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: CustomButton(
                        funcion: () {
                          if (formKey.currentState!.validate()) {
                            formKey.currentState!.save();
                            _submitCreateType(formKey, ctrl);
                          }
                        },
                        texto: 'Agregar',
                        cancelar: false,
                        icon: Icons.add_rounded,
                        width: double.infinity,
                      ),
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
    if (_all.isEmpty) return; // Validación de seguridad

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

      for (var w in _all) {
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
        final docSnapshot = await FirebaseFirestore.instance
            .collection('Asistencias')
            .doc(dayKey)
            .get();

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
    bool isDesktop = MediaQuery.of(context).size.width >= 800;
    final items = <String>['GENERAL', ..._activeLists];
    return DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: _group.toUpperCase(),
        dropdownColor: isDesktop ? Colors.white : primario,
        icon: Icon(
          CupertinoIcons.chevron_down,
          size: 18,
          color: isDesktop ? primario : Colors.white,
        ),
        iconEnabledColor: isDesktop ? primario : Colors.white,
        borderRadius: const BorderRadius.all(Radius.circular(10)),
        style: TextStyle(color: isDesktop ? primario : Colors.white),
        items: [
          for (final g in items)
            DropdownMenuItem(
              value: g.toUpperCase(),
              child: Text(g.toUpperCase(),
                  style: TextStyle(color: isDesktop ? primario : Colors.white)),
            ),
          DropdownMenuItem(
            value: '__add__',
            child: Text('+ AGREGAR NUEVA LISTA',
                style: TextStyle(color: isDesktop ? primario : Colors.white)),
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

  // Extraemos los controles que antes estaban en el AppBar
  Widget _buildControls(bool isDesktop) {
    final searchBox = Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F7FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blueGrey.shade100),
      ),
      child: TextField(
        controller: _search,
        style: const TextStyle(color: Colors.black87, fontSize: 16),
        decoration: InputDecoration(
          hintText: 'Buscar por nombre o apellido...',
          hintStyle: TextStyle(color: Colors.grey.shade500),
          border: InputBorder.none,
          icon: Icon(CupertinoIcons.search, color: Colors.grey.shade500),
        ),
      ),
    );

    final groupBox = Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F7FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blueGrey.shade100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            CupertinoIcons.list_bullet_below_rectangle,
            color: primario,
            size: 18,
          ),
          const SizedBox(width: 8),
          _groupDropdown(),
        ],
      ),
    );

    final exportButton = StreamBuilder<List<Map<String, dynamic>>>(
      stream: AttendanceService.listenPresents(_selectedDate, _group),
      builder: (context, snap) {
        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF4F7FA),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blueGrey.shade100),
          ),
          child: PopupMenuButton<String>(
            tooltip: 'Exportar',
            icon: Icon(CupertinoIcons.arrow_down_doc, color: primario),
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
              PopupMenuItem(value: 'download', child: Text('Descargar PDF')),
              PopupMenuItem(value: 'share', child: Text('Compartir PDF')),
            ],
          ),
        );
      },
    );

    return Container(
      color: const Color(0xFFF0F2F5),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.blueGrey.shade50),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
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
                  dayTextStyle: TextStyle(color: Colors.blueGrey.shade700),
                  monthTextStyle: TextStyle(color: Colors.blueGrey.shade700),
                  dateTextStyle:
                      TextStyle(color: Colors.blueGrey.shade900, fontSize: 18),
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
    );
  }

  // ignore: unused_element
  Widget _buildLegacyLayout(BuildContext context) {
    bool isDesktop = MediaQuery.of(context).size.width >= 800;
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      body: Column(
        children: [
          const PageHeader(
            title: 'Asistencia',
            subtitle: 'Registro y control diario de personal',
            icon: CupertinoIcons.calendar_today,
          ),
          _buildControls(isDesktop),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  if (_search.text.isNotEmpty)
                    SizedBox(
                      height: _suggestionsHeight(context),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                            color: isDesktop ? Colors.white : primario),
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
                                  hoverColor: isDesktop
                                      ? primario.withOpacity(0.08)
                                      : Colors.white.withOpacity(0.08),
                                  textColor:
                                      isDesktop ? primario : Colors.white,
                                  dense: true,
                                  visualDensity: const VisualDensity(
                                      horizontal: -2, vertical: -2),
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12),
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
                                    icon: Icon(Icons.add_outlined,
                                        color: isDesktop
                                            ? primario
                                            : Colors.white),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                  StreamBuilder<List<Map<String, dynamic>>>(
                    stream:
                        AttendanceService.listenPresents(_selectedDate, _group),
                    builder: (context, snap) {
                      if (snap.hasError) {
                        return const Center(
                            child: Text('Error cargando asistencia'));
                      }
                      if (!snap.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final entries = snap.data!;
                      if (entries.isEmpty) {
                        return const Center(
                            child:
                                Text('Aún no hay asistentes para esta lista.'));
                      }
                      entries.sort(
                          (a, b) => _sortKeyFor(a).compareTo(_sortKeyFor(b)));

                      return Material(
                        color: Colors.white,
                        child: ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
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
                            final rut =
                                (e['rut'] ?? '').toString().toUpperCase();
                            final lst =
                                (e['list'] ?? '').toString().toUpperCase();
                            return ListTile(
                              onTap: () {},
                              hoverColor: primario.withOpacity(0.06),
                              dense: true,
                              visualDensity: const VisualDensity(
                                  horizontal: -2, vertical: -2),
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
                                    await _remove(
                                        (e['workerId'] ?? '').toString());
                                  }
                                },
                                icon:
                                    Icon(Icons.delete_outline, color: primario),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 800;
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      body: Column(
        children: [
          const PageHeader(
            title: 'Asistencia',
            subtitle: 'Registro y control diario de personal',
            icon: CupertinoIcons.calendar_today,
          ),
          _buildControls(isDesktop),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.blueGrey.shade50),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                clipBehavior: Clip.hardEdge,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      if (_search.text.isNotEmpty)
                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF4F7FA),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.blueGrey.shade100),
                          ),
                          child: SizedBox(
                            height: _suggestionsHeight(context),
                            child: ListView.separated(
                              padding: EdgeInsets.zero,
                              physics: _filtered.length <= 8
                                  ? const NeverScrollableScrollPhysics()
                                  : const ClampingScrollPhysics(),
                              itemCount: _filtered.length,
                              separatorBuilder: (_, __) => Divider(
                                height: 1,
                                thickness: 0.2,
                                color: Colors.blueGrey.shade100,
                                indent: 12,
                                endIndent: 12,
                              ),
                              itemBuilder: (_, i) {
                                final w = _filtered[i];
                                return ListTile(
                                  onTap: () async => _add(w),
                                  hoverColor: primario.withOpacity(0.08),
                                  textColor: Colors.blueGrey.shade800,
                                  dense: true,
                                  visualDensity: const VisualDensity(
                                      horizontal: -2, vertical: -2),
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12),
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
                                    icon: Icon(
                                      Icons.add_outlined,
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
                            return const SizedBox(
                              height: 200,
                              child: Center(
                                child: Text('Error cargando asistencia'),
                              ),
                            );
                          }
                          if (!snap.hasData) {
                            return const SizedBox(
                              height: 220,
                              child: Center(child: CircularProgressIndicator()),
                            );
                          }
                          final entries = snap.data!;
                          if (entries.isEmpty) {
                            return SizedBox(
                              height: 220,
                              child: Center(
                                child: Text(
                                  'Aun no hay asistentes para esta lista.',
                                  style: TextStyle(
                                    color: Colors.blueGrey.shade500,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            );
                          }
                          entries.sort(
                            (a, b) => _sortKeyFor(a).compareTo(_sortKeyFor(b)),
                          );

                          return ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: entries.length,
                            separatorBuilder: (_, __) => Divider(
                              height: 1,
                              indent: 20,
                              endIndent: 20,
                              color: primario.withOpacity(0.16),
                              thickness: 0.2,
                            ),
                            itemBuilder: (_, i) {
                              final e = entries[i];
                              final name = _displayNameFor(e).toUpperCase();
                              final rut =
                                  (e['rut'] ?? '').toString().toUpperCase();
                              final lst =
                                  (e['list'] ?? '').toString().toUpperCase();
                              return ListTile(
                                hoverColor: primario.withOpacity(0.05),
                                dense: true,
                                visualDensity: const VisualDensity(
                                    horizontal: -2, vertical: -2),
                                minLeadingWidth: 28,
                                isThreeLine: true,
                                contentPadding:
                                    const EdgeInsets.symmetric(horizontal: 12),
                                leading: CircleAvatar(
                                  backgroundColor: primario.withOpacity(0.12),
                                  foregroundColor: primario,
                                  child: Text('${i + 1}'),
                                ),
                                title: Text(
                                  name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  softWrap: false,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                subtitle: Text(
                                  _group == 'GENERAL' ? '$rut · $lst' : rut,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  softWrap: false,
                                  style: TextStyle(
                                    color: Colors.blueGrey.shade600,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                trailing: IconButton(
                                  tooltip: 'Quitar',
                                  onPressed: () async {
                                    final ok = await _confirmRemoveSheet(name);
                                    if (ok) {
                                      await _remove(
                                          (e['workerId'] ?? '').toString());
                                    }
                                  },
                                  icon: Icon(Icons.delete_outline,
                                      color: primario),
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
        ],
      ),
    );
  }
}

class _AttendanceSheetHeader extends StatelessWidget {
  const _AttendanceSheetHeader({
    required this.title,
    required this.icon,
    this.danger = false,
  });

  final String title;
  final IconData icon;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        gradient: LinearGradient(
          colors: danger
              ? [Colors.red.shade700, Colors.red.shade500]
              : [Colors.blueGrey.shade900, Colors.blueGrey.shade700],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
        child: Column(
          children: [
            Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.28),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AttendanceHint extends StatelessWidget {
  const _AttendanceHint({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: primario.withOpacity(0.12)),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: primario.withOpacity(0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.tips_and_updates_outlined,
              color: primario,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.blueGrey.shade600,
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
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
