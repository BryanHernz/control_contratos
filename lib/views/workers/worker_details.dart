// ignore_for_file: empty_catches, unrelated_type_equality_checks

import 'package:animated_snack_bar/animated_snack_bar.dart';
import 'package:calendar_date_picker2/calendar_date_picker2.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' hide ModalBottomSheetRoute;
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:group_button/group_button.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:spelling_number/spelling_number.dart';

import '../../customs/app_colors.dart';
import '../../customs/widgets/app_modal.dart';
import '../../customs/constants_values.dart';
import '../../customs/widgets_custom.dart';
import '../../models/worker_model.dart';
import '../pictures/pictures_page.dart';
import 'edit_worker_page.dart';
import '../../services/firestore_db.dart';
import '../../services/auditoria.dart';
import '../../services/plantilla_render.dart';
import '../../services/plantilla_service.dart';

class WorkerDetails extends StatefulWidget {
  const WorkerDetails({super.key, required this.worker});
  final WorkerModel worker;

  @override
  State<WorkerDetails> createState() => _WorkerDetailsState();
}

class _WorkerDetailsState extends State<WorkerDetails> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _exitController = TextEditingController();
  final TextEditingController _vacationsController = TextEditingController();
  final TextEditingController _totalController = TextEditingController();

  Widget _buildCalendarActionButton({
    required String text,
    required bool filled,
  }) {
    return Container(
      constraints: const BoxConstraints(minWidth: 118, minHeight: 40),
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: filled ? primario : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: filled ? primario : Colors.blueGrey.shade200,
        ),
        boxShadow: filled
            ? [
                BoxShadow(
                  color: primario.withOpacity(0.24),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          color: filled ? Colors.white : Colors.blueGrey.shade700,
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  CalendarDatePicker2WithActionButtonsConfig _buildDatePickerConfig({
    required DateTime firstDate,
    required DateTime lastDate,
    required DateTime currentDate,
  }) {
    final titleStyle = Theme.of(context).textTheme.titleMedium;
    final bodyStyle = Theme.of(context).textTheme.bodyMedium;
    final captionStyle = Theme.of(context).textTheme.bodySmall;

    return CalendarDatePicker2WithActionButtonsConfig(
      calendarType: CalendarDatePicker2Type.single,
      firstDate: firstDate,
      lastDate: lastDate,
      currentDate: currentDate,
      modePickerTextHandler: ({required monthDate, isMonthPicker}) {
        if (isMonthPicker ?? false) {
          return DateFormat.MMMM('es').format(monthDate).toUpperCase();
        }
        return DateFormat.y('es').format(monthDate).toUpperCase();
      },
      selectedDayHighlightColor: primario,
      dayBorderRadius: BorderRadius.circular(999),
      controlsTextStyle: titleStyle?.copyWith(
            color: Colors.blueGrey.shade700,
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ) ??
          TextStyle(
            color: Colors.blueGrey.shade700,
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
      weekdayLabelTextStyle: captionStyle?.copyWith(
            color: AppColors.textMuted,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ) ??
          const TextStyle(
            color: AppColors.textMuted,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
      dayTextStyle: bodyStyle?.copyWith(
            color: Colors.blueGrey.shade600,
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ) ??
          TextStyle(
            color: Colors.blueGrey.shade600,
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
      selectedDayTextStyle: bodyStyle?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ) ??
          const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
      todayTextStyle: bodyStyle?.copyWith(
            color: primario,
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ) ??
          TextStyle(
            color: primario,
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
      disabledDayTextStyle: bodyStyle?.copyWith(
            color: Colors.blueGrey.shade200,
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ) ??
          TextStyle(
            color: Colors.blueGrey.shade200,
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
      monthTextStyle: bodyStyle?.copyWith(
            color: Colors.blueGrey.shade700,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ) ??
          TextStyle(
            color: Colors.blueGrey.shade700,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
      selectedMonthTextStyle: bodyStyle?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ) ??
          const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
      yearTextStyle: bodyStyle?.copyWith(
            color: Colors.blueGrey.shade700,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ) ??
          TextStyle(
            color: Colors.blueGrey.shade700,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
      selectedYearTextStyle: bodyStyle?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ) ??
          const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
      nextMonthIcon: Icon(
        Icons.chevron_right_rounded,
        color: Colors.blueGrey.shade700,
        size: 22,
      ),
      lastMonthIcon: Icon(
        Icons.chevron_left_rounded,
        color: Colors.blueGrey.shade700,
        size: 22,
      ),
      gapBetweenCalendarAndButtons: 12,
      buttonPadding: const EdgeInsets.fromLTRB(8, 4, 8, 12),
      cancelButton: _buildCalendarActionButton(
        text: 'Cancelar',
        filled: false,
      ),
      okButton: _buildCalendarActionButton(
        text: 'Aceptar',
        filled: true,
      ),
    );
  }

  /// Ficha del ultimo contrato generado. Vive aparte porque se coloca dentro
  /// de la columna laboral y no como bloque suelto al final.
  Widget _ultimoContratoCard() {
    return StreamBuilder<DocumentSnapshot>(
      stream: db.collection('Trabajadores').doc(widget.worker.id).snapshots(),
      builder: (ctx, snap) {
        String val = '—';
        if (snap.hasData && snap.data!.exists) {
          final data = snap.data!.data() as Map<String, dynamic>?;
          final ts = data?['ultimoContrato'];
          if (ts is Timestamp) {
            val = DateFormat('dd/MM/yyyy – HH:mm', 'es').format(ts.toDate());
          }
        }
        return _InfoCard(
          title: 'Último contrato',
          icon: Icons.calendar_today_outlined,
          items: [
            _InfoItem(Icons.calendar_today_outlined, 'Último contrato', val),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // El recorte, el ancho y el alto los pone showAppModal. Aca solo van la
    // cabecera oscura y el cuerpo blanco; el blanco NO envuelve a la cabecera,
    // o vuelve a asomar por la curva superior.
    final wide = MediaQuery.sizeOf(context).width >= kModalWideBreakpoint;

    return Column(
      mainAxisSize: MainAxisSize.min, // Abraza el contenido
      children: [
        // ----------------------------------------------------
        // 1. REEMPLAZO DEL APPBAR (Header personalizado)
        // ----------------------------------------------------
        // ── HEADER BANNER ──────────────────────────────────────
        _ModalHeader(
          worker: widget.worker,
          onDelete: _openDeleteWorkerSheet,
          onEdit: _openEditWorkerSheet,
          onClose: () => Navigator.of(context).maybePop(),
          showGrabber: !wide,
        ),

        // ----------------------------------------------------
        // 2. CUERPO DEL DETALLE (Scrollable) + acciones al pie.
        //    Ambos van dentro del MISMO Material blanco: si el blanco cubre
        //    solo el scroll, los botones del pie quedan flotando sobre el
        //    fondo oscuro del modal.
        // ----------------------------------------------------
        Flexible(
          child: Material(
            // Hace de pagina dentro del modal: las _InfoCard van en `surface`.
            color: AppColors.surfaceSunken,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24.0, vertical: 24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // ── INFO CARD ────────────────────────────────
                        // Personal y laboral van lado a lado cuando hay ancho.
                        // Apiladas dejaban media pantalla vacia a la derecha de
                        // cada fila. Bajo 560px vuelven a una sola columna para
                        // no quedar estranguladas.
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final personal = _InfoCard(
                              title: 'Informaci\u00f3n personal',
                              icon: Icons.person_outline_rounded,
                              items: [
                                _InfoItem(Icons.badge_outlined, 'Nombres',
                                    widget.worker.name!.toUpperCase()),
                                _InfoItem(Icons.person_outline, 'Apellidos',
                                    widget.worker.lastName!.toUpperCase()),
                                _InfoItem(Icons.credit_card_outlined, 'RUT',
                                    widget.worker.rut!),
                                _InfoItem(
                                    Icons.email_outlined,
                                    'Correo',
                                    widget.worker.email?.toUpperCase() ??
                                        '\u2014'),
                                _InfoItem(Icons.flag_outlined, 'Nacionalidad',
                                    widget.worker.nacionality!.toUpperCase()),
                                _InfoItem(
                                    Icons.favorite_border_rounded,
                                    'Estado civil',
                                    widget.worker.civilState!.toUpperCase()),
                                _InfoItem(
                                    Icons.cake_outlined,
                                    'Fecha nacimiento',
                                    widget.worker.birth!.toUpperCase()),
                                _InfoItem(Icons.home_outlined, 'Direcci\u00f3n',
                                    widget.worker.adress!.toUpperCase()),
                                _InfoItem(
                                    Icons.location_city_outlined,
                                    'Comuna',
                                    widget.worker.commune!.toUpperCase()),
                              ],
                            );

                            final laboral = _InfoCard(
                              title: 'Informaci\u00f3n laboral',
                              icon: Icons.work_outline_rounded,
                              items: [
                                _InfoItem(Icons.construction_outlined, 'Labor',
                                    widget.worker.labor!.toUpperCase()),
                                _InfoItem(
                                    Icons.business_outlined,
                                    'Establecimiento',
                                    widget.worker.place!.toUpperCase()),
                                _InfoItem(Icons.savings_outlined, 'AFP',
                                    widget.worker.afp!.toUpperCase()),
                                _InfoItem(
                                    Icons.local_hospital_outlined,
                                    'Previsi\u00f3n',
                                    widget.worker.prevision!.toUpperCase()),
                                _InfoItem(
                                    Icons.calendar_today_outlined,
                                    'Fecha de ingreso',
                                    widget.worker.ingress!.toUpperCase()),
                              ],
                            );

                            // "Ultimo contrato" cuelga de la columna laboral,
                            // que es la mas corta: asi rellena el hueco que
                            // dejaba debajo en vez de irse a todo el ancho.
                            final ultimoContrato = _ultimoContratoCard();

                            if (constraints.maxWidth < 560) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  personal,
                                  const SizedBox(height: 14),
                                  laboral,
                                  const SizedBox(height: 14),
                                  ultimoContrato,
                                ],
                              );
                            }

                            // IntrinsicHeight iguala el alto de las dos
                            // columnas, y "Ultimo contrato" va en Expanded
                            // para absorber el sobrante: asi la columna
                            // derecha termina a la misma altura que la
                            // izquierda en vez de dejar un hueco abajo.
                            return IntrinsicHeight(
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Expanded(child: personal),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        laboral,
                                        const SizedBox(height: 14),
                                        Expanded(child: ultimoContrato),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                // ----------------------------------------------------
                // 3. REEMPLAZO DE LOS FLOATING ACTION BUTTONS
                // ----------------------------------------------------
                Padding(
                  padding: const EdgeInsets.only(
                      top: 0, bottom: 26.0, left: 24.0, right: 24.0),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      const spacing = 10.0;
                      final maxWidth = constraints.maxWidth;
                      final useThreeColumns = maxWidth >= 560;
                      final computedWidth = useThreeColumns
                          ? (maxWidth - (spacing * 2)) / 3
                          : (maxWidth - spacing) / 2;
                      final buttonWidth =
                          computedWidth.clamp(130.0, 220.0).toDouble();

                      return Wrap(
                        alignment: WrapAlignment.center,
                        runAlignment: WrapAlignment.center,
                        spacing: spacing,
                        runSpacing: spacing,
                        children: [
                          // Botón Finiquito
                          SizedBox(
                            width: buttonWidth,
                            child: CustomButton(
                              funcion: _openSettlementSheet,
                              texto: 'Finiquito',
                              icon: Icons.file_copy_outlined,
                            ),
                          ),

                          // Botón Documentos
                          SizedBox(
                            width: buttonWidth,
                            child: CustomButton(
                              funcion: _openDocumentsSheet,
                              texto: 'Documentos',
                              icon: Icons.local_print_shop_outlined,
                            ),
                          ),

                          // Botón Carnet
                          SizedBox(
                            width: buttonWidth,
                            child: CustomButton(
                              funcion: _openCarnetSheet,
                              texto: 'Carnet',
                              icon: Icons.badge_outlined,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String get _workerDisplayName {
    final name = (widget.worker.name ?? '').toUpperCase();
    final lastName = (widget.worker.lastName ?? '').toUpperCase();
    return '$name $lastName'.trim();
  }

  void _openEditWorkerSheet() {
    showAppModal(
      context: context,
      title: 'Editar trabajador',
      subtitle: _workerDisplayName,
      badge: 'Ficha',
      icon: Icons.edit_note_rounded,
      child: EditWorker(worker: widget.worker),
    );
  }

  void _openDeleteWorkerSheet() {
    showAppModal(
      context: context,
      title: 'Eliminar trabajador',
      subtitle: _workerDisplayName,
      badge: 'Accion',
      icon: Icons.delete_outline_rounded,
      danger: true,
      maxWidth: 560,
      child: _DeleteWorkerSheet(
        worker: widget.worker,
        onConfirm: _deleteWorker,
      ),
    );
  }

  Future<void> _deleteWorker() async {
    const path = 'WorkersIdImages/';
    final frontFile = '${widget.worker.rut}_front';
    final backFile = '${widget.worker.rut}_back';

    try {
      try {
        await FirebaseStorage.instance.ref(path).child(frontFile).delete();
      } catch (_) {}

      try {
        await FirebaseStorage.instance.ref(path).child(backFile).delete();
      } catch (_) {}

      await db.collection('Trabajadores').doc(widget.worker.id).delete();
      await Auditoria.registrar(
        Auditoria.eliminarTrabajador,
        entidadId: widget.worker.id,
        detalle: {
          'rut': widget.worker.rut,
          'nombre': '${widget.worker.name} ${widget.worker.lastName}'
              .trim()
              .toUpperCase(),
        },
      );

      Get.back();
      if (mounted) {
        AnimatedSnackBar.material(
          'Trabajador eliminado con \u00e9xito',
          mobileSnackBarPosition: MobileSnackBarPosition.top,
          desktopSnackBarPosition: DesktopSnackBarPosition.bottomRight,
          type: AnimatedSnackBarType.success,
        ).show(context);
      }
      Get.back();
    } catch (_) {
      if (mounted) {
        AnimatedSnackBar.material(
          'No se pudo eliminar el trabajador.',
          mobileSnackBarPosition: MobileSnackBarPosition.top,
          desktopSnackBarPosition: DesktopSnackBarPosition.bottomRight,
          type: AnimatedSnackBarType.error,
        ).show(context);
      }
    }
  }

  void _openDocumentsSheet() {
    showAppModal(
      context: context,
      title: 'Documentos',
      subtitle: _workerDisplayName,
      badge: 'Impresion',
      icon: Icons.description_outlined,
      maxWidth: 720,
      child: _DocumentsSheet(
        worker: widget.worker,
        onPrint: (selections) async {
          Get.back();
          await printing(selections);
        },
      ),
    );
  }

  void _openSettlementSheet() {
    showAppModal(
      context: context,
      title: 'Finiquito',
      subtitle: _workerDisplayName,
      badge: 'Documento',
      icon: Icons.file_copy_outlined,
      maxWidth: 720,
      child: _SettlementSheet(
        worker: widget.worker,
        formKey: _formKey,
        exitController: _exitController,
        vacationsController: _vacationsController,
        totalController: _totalController,
        onPickExitDate: _pickSettlementExitDate,
        onPrint: _printSettlement,
      ),
    );
  }

  void _openCarnetSheet() {
    showAppModal(
      context: context,
      title: 'Carnet',
      subtitle: _workerDisplayName,
      badge: 'Fotos',
      icon: Icons.badge_outlined,
      maxWidth: 720,
      child: _CarnetSheet(worker: widget.worker),
    );
  }

  Future<void> _pickSettlementExitDate() async {
    DateTime? initialValue;
    if (_exitController.text.isNotEmpty) {
      try {
        initialValue = DateFormat.yMMMMd('es').parse(_exitController.text);
      } catch (_) {}
    }

    final datePicked = await showCalendarDatePicker2Dialog(
      context: context,
      config: _buildDatePickerConfig(
        firstDate: DateTime(1950),
        lastDate: DateTime.now(),
        currentDate: DateTime.now(),
      ),
      dialogSize: const Size(350, 420),
      borderRadius: BorderRadius.circular(18),
      dialogBackgroundColor: Colors.white,
      value: [initialValue ?? DateTime.now()],
    );

    if (datePicked != null &&
        datePicked.isNotEmpty &&
        datePicked.first != null) {
      _exitController.text =
          DateFormat.yMMMMd('es').format(datePicked.first!).toString();
    }
  }

  void _printSettlement() {
    final formState = _formKey.currentState;
    if (formState == null) return;
    if (!formState.validate()) return;

    formState.save();
    printingEnd();
    Get.back();
  }

  Future<void> printing(List<String> selections) async {
    try {
      final pdf = pw.Document();
      var cambria = await rootBundle.load("lib/images/Cambria.ttf");
      var calibri = await rootBundle.load("lib/images/Calibri Regular.ttf");
      var calibriBold = await rootBundle.load("lib/images/Calibri Bold.ttf");

      String url1 = widget.worker.imageFront != '' &&
              widget.worker.imageFront != null
          ? widget.worker.imageFront!
          : 'https://firebasestorage.googleapis.com/v0/b/contratos-control.appspot.com/o/white.jpg?alt=media&token=5ac45bdc-6b4b-4ef0-949c-a717c2bec1e7';
      String url2 = widget.worker.imageBack != '' &&
              widget.worker.imageBack != null
          ? widget.worker.imageBack!
          : 'https://firebasestorage.googleapis.com/v0/b/contratos-control.appspot.com/o/white.jpg?alt=media&token=5ac45bdc-6b4b-4ef0-949c-a717c2bec1e7';

      final image1 = await networkImage(url1);
      final image2 = await networkImage(url2);

      var contrato = await db.collection('Otros').doc('contrato').get();
      var empresa = await db.collection('Otros').doc('empresadata').get();

      // Las plantillas se buscan aqui, antes de armar las paginas: el `build`
      // de `pw.MultiPage` es sincrono y no puede esperar a Firestore.
      final plantillas = <String, VersionPlantilla?>{};
      for (final tipo in const [
        'registro',
        'contrato',
        'derecho-a-saber',
        'epp',
        'finiquito',
      ]) {
        plantillas[tipo] = await PlantillaService.obtenerVigente(tipo);
      }

      // Fetch the places array to find the index
      var lugaresParam = await db.collection('Otros').doc('lugares').get();
      List<String> lugaresTipos = [];
      if (lugaresParam.exists && lugaresParam.data() != null) {
        var data = lugaresParam.data()!;
        if (data.containsKey('tipos')) {
          lugaresTipos = List<String>.from(data['tipos'] ?? []);
        }
      }

      // Fetch the hours configuration array
      var horasParam = await db.collection('Otros').doc('lugares_horas').get();
      List<String> pruebaHoras = [];
      List<String> lunesJuevesList = [];
      List<String> viernesList = [];
      List<String> sabadosList = [];
      List<String> colacionList = [];
      if (horasParam.exists && horasParam.data() != null) {
        var data = horasParam.data()!;
        if (data.containsKey('prueba_horas')) {
          pruebaHoras = List<String>.from(data['prueba_horas'] ?? []);
        }
        if (data.containsKey('lunes_jueves')) {
          lunesJuevesList = List<String>.from(data['lunes_jueves'] ?? []);
        }
        if (data.containsKey('viernes')) {
          viernesList = List<String>.from(data['viernes'] ?? []);
        }
        if (data.containsKey('sabados')) {
          sabadosList = List<String>.from(data['sabados'] ?? []);
        }
        if (data.containsKey('colacion')) {
          colacionList = List<String>.from(data['colacion'] ?? []);
        }
      }

      String place = widget.worker.place ?? '';
      int horasSemanales = 44; // Fallback
      String txtLunesJueves = "Lunes a Jueves de 8:00 a 18:00 hrs";
      String txtViernes = "Viernes de 8:00 a 17:00 hrs";
      String txtSabado = "";
      String txtColacion = "una hora";

      int placeIndex = lugaresTipos.indexWhere((element) =>
          element.trim().toLowerCase() == place.trim().toLowerCase());

      if (placeIndex != -1) {
        if (placeIndex < pruebaHoras.length) {
          horasSemanales =
              int.tryParse(pruebaHoras[placeIndex].toString().trim()) ?? 44;
        }

        String formatSchedule(String raw, String defaultPrefix) {
          if (raw.contains('/')) {
            final parts = raw.split('/');
            if (parts.length == 2) {
              return '$defaultPrefix de ${parts[0]} a ${parts[1]} hrs';
            }
          }
          return raw;
        }

        if (placeIndex < lunesJuevesList.length) {
          txtLunesJueves = formatSchedule(
              lunesJuevesList[placeIndex].toString().trim(), "Lunes a Jueves");
        }
        if (placeIndex < viernesList.length) {
          final ljRaw = placeIndex < lunesJuevesList.length
              ? lunesJuevesList[placeIndex].toString().trim()
              : '';
          final vRaw = viernesList[placeIndex].toString().trim();
          // Si el horario del viernes es igual al de lunes-jueves,
          // unificar en "Lunes a Viernes" y dejar txtViernes vacío
          if (ljRaw == vRaw && ljRaw.isNotEmpty) {
            txtLunesJueves = formatSchedule(ljRaw, "Lunes a Viernes");
            txtViernes = '';
          } else {
            txtViernes = formatSchedule(vRaw, "Viernes");
          }
        }
        if (placeIndex < sabadosList.length) {
          String sabVal = sabadosList[placeIndex].toString().trim();
          if (sabVal != "N/A" && sabVal != "") {
            txtSabado = formatSchedule(sabVal, "Sábado");
          }
        }
        if (placeIndex < colacionList.length) {
          String colVal = colacionList[placeIndex].toString().trim();
          if (colVal != "") {
            txtColacion = _minutesToWords(colVal);
          }
        }
      }

      double baselina = 4;
      double letterSize = 12;

      if (selections.contains('Contrato')) {
        pdf.addPage(
          pw.MultiPage(
            pageFormat: PdfPageFormat.letter,
            margin: const pw.EdgeInsets.symmetric(vertical: 40, horizontal: 60),
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            build: (pw.Context context) => [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    '${empresa['nombreempresa']}',
                    style: pw.TextStyle(
                      font: pw.Font.ttf(cambria),
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  pw.Text(
                    'AÑO ${DateTime.now().year}',
                    style: pw.TextStyle(
                      font: pw.Font.ttf(cambria),
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              // El cuerpo sale de la plantilla publicada. Si en esta base
              // todavia no hay ninguna, cae al texto que estaba en codigo.
              ..._cuerpoDeDocumento(
                plantillas['contrato'],
                _datosDePlantilla(empresa, contrato, horasSemanales,
                    txtLunesJueves, txtViernes, txtSabado, txtColacion),
                calibri,
                calibriBold,
                letterSize,
                baselina,
                () => _contratoEnCodigo(
                    empresa,
                    contrato,
                    horasSemanales,
                    txtLunesJueves,
                    txtViernes,
                    txtSabado,
                    txtColacion,
                    calibri,
                    calibriBold,
                    letterSize,
                    baselina),
                tipo: TipoPlantilla.porClave('contrato'),
              ),
              pw.SizedBox(height: 15),
              pw.Center(
                child: pw.Text(
                  "O’Higgins Pelay Lt 2 H Pc N° 2 A, Comuna San Francisco De Mostazal",
                  style: pw.TextStyle(
                      font: pw.Font.ttf(calibriBold),
                      fontSize: 10,
                      color: PdfColor.fromHex('#9B9B9B')),
                ),
              ),
            ],
          ),
        ); // Page
      }

      if (selections.contains('Derecho a saber')) {
        pdf.addPage(
          pw.MultiPage(
            pageFormat: PdfPageFormat.letter,
            margin: const pw.EdgeInsets.symmetric(vertical: 40, horizontal: 60),
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            build: (pw.Context context) => [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    '${empresa['nombreempresa']}',
                    style: pw.TextStyle(
                      font: pw.Font.ttf(cambria),
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  pw.Text(
                    'AÑO ${DateTime.now().year}',
                    style: pw.TextStyle(
                      font: pw.Font.ttf(cambria),
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              // El cuerpo sale de la plantilla publicada. Si en esta base
              // todavia no hay ninguna, cae al texto que estaba en codigo.
              ..._cuerpoDeDocumento(
                plantillas['derecho-a-saber'],
                _datosDePlantilla(empresa, contrato, horasSemanales,
                    txtLunesJueves, txtViernes, txtSabado, txtColacion),
                calibri,
                calibriBold,
                letterSize,
                baselina,
                () => _derechoASaberEnCodigo(
                    empresa, calibri, calibriBold, letterSize, baselina),
                tipo: TipoPlantilla.porClave('derecho-a-saber'),
                filas: plantillas['derecho-a-saber']?.filas ?? const [],
              ),
              pw.Center(
                child: pw.Text(
                  "O’Higgins Pelay Lt 2 H Pc N° 2 A, Comuna San Francisco De Mostazal",
                  style: pw.TextStyle(
                      font: pw.Font.ttf(calibriBold),
                      fontSize: 10,
                      color: PdfColor.fromHex('#9B9B9B')),
                ),
              ),
            ],
          ),
        ); // Page
      }

      if (selections.contains('EPP')) {
        pdf.addPage(
          pw.MultiPage(
            pageFormat: PdfPageFormat.letter,
            margin: const pw.EdgeInsets.symmetric(vertical: 40, horizontal: 60),
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            build: (pw.Context context) => [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    '${empresa['nombreempresa']} - RUT ${empresa['rut']} - EPP',
                    style: pw.TextStyle(
                      font: pw.Font.ttf(cambria),
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  pw.Text(
                    'AÑO ${DateTime.now().year}',
                    style: pw.TextStyle(
                      font: pw.Font.ttf(cambria),
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              // El cuerpo sale de la plantilla publicada. Si en esta base
              // todavia no hay ninguna, cae al texto que estaba en codigo.
              ..._cuerpoDeDocumento(
                plantillas['epp'],
                _datosDePlantilla(empresa, contrato, horasSemanales,
                    txtLunesJueves, txtViernes, txtSabado, txtColacion),
                calibri,
                calibriBold,
                letterSize,
                baselina,
                () => _eppEnCodigo(
                    empresa, calibri, calibriBold, letterSize, baselina),
                tipo: TipoPlantilla.porClave('epp'),
                filas: plantillas['epp']?.filas ?? const [],
              ),
              pw.Center(
                child: pw.Text(
                  "O’Higgins Pelay Lt 2 H Pc N° 2 A, Comuna San Francisco De Mostazal",
                  style: pw.TextStyle(
                      font: pw.Font.ttf(calibriBold),
                      fontSize: 10,
                      color: PdfColor.fromHex('#9B9B9B')),
                ),
              ),
            ],
          ),
        ); // Page
      }

      if (selections.contains('Registro')) {
        pdf.addPage(
          pw.MultiPage(
            pageFormat: PdfPageFormat.letter,
            margin: const pw.EdgeInsets.symmetric(vertical: 40, horizontal: 60),
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            build: (pw.Context context) => [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    '${empresa['nombreempresa']}',
                    style: pw.TextStyle(
                      font: pw.Font.ttf(cambria),
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  pw.Text(
                    'AÑO ${DateTime.now().year}',
                    style: pw.TextStyle(
                      font: pw.Font.ttf(cambria),
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              // El cuerpo sale de la plantilla publicada. Si en esta base
              // todavia no hay ninguna, cae al texto que estaba en codigo.
              ..._cuerpoDeDocumento(
                plantillas['registro'],
                _datosDePlantilla(empresa, contrato, horasSemanales,
                    txtLunesJueves, txtViernes, txtSabado, txtColacion),
                calibri,
                calibriBold,
                letterSize,
                baselina,
                () => _registroEnCodigo(
                    empresa, calibri, calibriBold, letterSize, baselina),
                tipo: TipoPlantilla.porClave('registro'),
              ),
              pw.SizedBox(height: 20),
              pw.Center(
                child: pw.Text(
                  "O’Higgins Pelay Lt 2 H Pc N° 2 A, Comuna San Francisco De Mostazal",
                  style: pw.TextStyle(
                      font: pw.Font.ttf(calibriBold),
                      fontSize: 10,
                      color: PdfColor.fromHex('#9B9B9B')),
                ),
              ),
            ],
          ),
        );
      }

      // «EPP + Registro» no es un documento aparte: son los dos anteriores
      // impresos en la misma hoja, porque cada uno ocupa media pagina y asi se
      // ahorra papel. Por eso se compone de sus plantillas en vez de tener
      // texto propio -- de lo contrario editar EPP no cambiaria nada aqui, y
      // el mismo parrafo habria que mantenerlo en dos lugares.
      if (selections.contains('EPP + Registro')) {
        final datos = _datosDePlantilla(empresa, contrato, horasSemanales,
            txtLunesJueves, txtViernes, txtSabado, txtColacion);

        pdf.addPage(
          pw.MultiPage(
            pageFormat: PdfPageFormat.letter,
            margin: const pw.EdgeInsets.symmetric(vertical: 40, horizontal: 60),
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            build: (pw.Context context) => [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    '${empresa['nombreempresa']}',
                    style: pw.TextStyle(
                      font: pw.Font.ttf(cambria),
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  pw.Text(
                    'AÑO ${DateTime.now().year}',
                    style: pw.TextStyle(
                      font: pw.Font.ttf(cambria),
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              ..._cuerpoDeDocumento(
                plantillas['epp'],
                datos,
                calibri,
                calibriBold,
                letterSize,
                baselina,
                () => _eppEnCodigo(
                    empresa, calibri, calibriBold, letterSize, baselina),
                tipo: TipoPlantilla.porClave('epp'),
                filas: plantillas['epp']?.filas ?? const [],
              ),
              pw.SizedBox(height: 24),
              pw.Divider(height: 1, borderStyle: pw.BorderStyle.dashed),
              pw.SizedBox(height: 24),
              ..._cuerpoDeDocumento(
                plantillas['registro'],
                datos,
                calibri,
                calibriBold,
                letterSize,
                baselina,
                () => _registroEnCodigo(
                    empresa, calibri, calibriBold, letterSize, baselina),
                tipo: TipoPlantilla.porClave('registro'),
              ),
            ],
          ),
        );
      }

      if (selections.contains('Carnet')) {
        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.letter,
            margin: const pw.EdgeInsets.symmetric(vertical: 50, horizontal: 30),
            build: (pw.Context context) {
              return pw.Padding(
                padding: const pw.EdgeInsets.all(0),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
                  children: [
                    pw.Container(
                      child: pw.ClipRRect(
                        verticalRadius: 10.0,
                        horizontalRadius: 10.0,
                        child: pw.Image(image1, width: 240),
                      ),
                    ),
                    pw.Container(
                      child: pw.ClipRRect(
                        verticalRadius: 10.0,
                        horizontalRadius: 10.0,
                        child: pw.Image(image2, width: 240),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      }

      // Registrar contrato en Firestore solo si se generó un contrato
      if (selections.contains('Contrato') && widget.worker.id != null) {
        try {
          await db.collection('Trabajadores').doc(widget.worker.id).update({
            'ultimoContrato': FieldValue.serverTimestamp(),
            'activo': true,
          });
          await Auditoria.registrar(
            Auditoria.generarContrato,
            entidadId: widget.worker.id,
            detalle: {
              'rut': widget.worker.rut,
              // Con que version de la plantilla se emitio: es lo que permite
              // reimprimirlo identico mas adelante.
              if (plantillas['contrato'] != null)
                'plantillaVersion': plantillas['contrato']!.id,
            },
          );
        } catch (_) {}
      }

      await Printing.layoutPdf(
          onLayout: (formato) async => pdf.save(),
          format: PdfPageFormat.letter);
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
    }
  }

  Future<void> printingEnd() async {
    final pdf = pw.Document();

    var cambria = await rootBundle.load("lib/images/Cambria.ttf");
    var calibri = await rootBundle.load("lib/images/Calibri Regular.ttf");
    var calibriBold = await rootBundle.load("lib/images/Calibri Bold.ttf");

    double baselina = 4;
    double letterSize = 12;

    var empresa = await db.collection('Otros').doc('empresadata').get();
    var contrato = await db.collection('Otros').doc('contrato').get();
    final plantillaFiniquito =
        await PlantillaService.obtenerVigente('finiquito');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.letter,
        margin: const pw.EdgeInsets.symmetric(vertical: 40, horizontal: 60),
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        build: (pw.Context context) => [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                '${empresa['nombreempresa']}',
                style: pw.TextStyle(
                  font: pw.Font.ttf(cambria),
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              pw.Text(
                'AÑO ${DateTime.now().year}',
                style: pw.TextStyle(
                  font: pw.Font.ttf(cambria),
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          // El cuerpo sale de la plantilla publicada. Si en esta base todavia
          // no hay ninguna, cae al texto que estaba en codigo.
          ..._cuerpoDeDocumento(
            plantillaFiniquito,
            {
              ..._datosDePlantilla(empresa, contrato, 44, '', '', '', ''),
              'finiquito.fecha_egreso': _exitController.text.toUpperCase(),
              'finiquito.vacaciones': '\$${_vacationsController.text}',
              'finiquito.total': '\$${_totalController.text}',
            },
            calibri,
            calibriBold,
            letterSize,
            baselina,
            () => _finiquitoEnCodigo(
                empresa, calibri, calibriBold, letterSize, baselina),
            tipo: TipoPlantilla.porClave('finiquito'),
          ),
          pw.SizedBox(height: 15),
          pw.Center(
            child: pw.Text(
              "O’Higgins Pelay Lt 2 H Pc N° 2 A, Comuna San Francisco De Mostazal",
              style: pw.TextStyle(
                  font: pw.Font.ttf(calibriBold),
                  fontSize: 10,
                  color: PdfColor.fromHex('#9B9B9B')),
            ),
          ),
        ],
      ),
    ); // Page

    // Un finiquito NO es un contrato.
    //
    // Antes esto tocaba `ultimoContrato`, que es el campo por el que el
    // dashboard cuenta "Contratos este mes" y ordena "Ultimos contratos
    // generados". O sea que finiquitar a alguien lo hacia aparecer como
    // contrato recien emitido, y inflaba la metrica del mes.
    try {
      if (widget.worker.id != null) {
        await db.collection('Trabajadores').doc(widget.worker.id).update({
          'fechaFiniquito': FieldValue.serverTimestamp(),
          'activo': false,
        });
        await Auditoria.registrar(
          Auditoria.generarFiniquito,
          entidadId: widget.worker.id,
          detalle: {
            'rut': widget.worker.rut,
            if (plantillaFiniquito != null)
              'plantillaVersion': plantillaFiniquito.id,
          },
        );
      }
    } catch (e) {
      // ignore
    }

    await Printing.layoutPdf(
        onLayout: (formato) async => pdf.save(), format: PdfPageFormat.letter);
  }

  String _minutesToWords(String val) {
    int? mins = int.tryParse(val);
    if (mins == null) return "una hora";

    if (mins == 60) return "una hora";
    if (mins == 30) return "media hora";
    if (mins == 90) return "una hora y media";
    if (mins == 120) return "dos horas";

    // Use spelling_number for values not in the common natural expressions
    if (mins < 60) {
      String wordMins = SpellingNumber(lang: 'es').convert(mins);
      // SpellingNumber might return "uno" instead of "un" for minutes in some contexts
      if (wordMins == "uno") wordMins = "un";
      return "$wordMins minutos";
    }

    int hours = mins ~/ 60;
    int remainingMins = mins % 60;

    String hourText = hours == 1
        ? "una hora"
        : "${SpellingNumber(lang: 'es').convert(hours)} horas";
    if (remainingMins == 0) return hourText;

    if (remainingMins == 30) return "$hourText y media";

    String minText = SpellingNumber(lang: 'es').convert(remainingMins);
    if (minText == "uno") minText = "un";

    return "$hourText y $minText minutos";
  }

  /// Valores con que se rellenan los marcadores `{{...}}` de una plantilla.
  ///
  /// Las claves son las mismas que ofrece el selector del editor. Agregar un
  /// campo aqui y en `marcadoresDisponibles` es todo lo que hace falta para
  /// poder usarlo en cualquier documento.
  Map<String, String> _datosDePlantilla(
    DocumentSnapshot empresa,
    DocumentSnapshot contrato,
    int horasSemanales,
    String txtLunesJueves,
    String txtViernes,
    String txtSabado,
    String txtColacion,
  ) {
    String texto(dynamic v) => (v ?? '').toString().trim();
    final w = widget.worker;
    final e = (empresa.data() as Map<String, dynamic>?) ?? const {};
    final c = (contrato.data() as Map<String, dynamic>?) ?? const {};

    // El codigo armaba la lista con comas y condicionales dentro del propio
    // literal; aqui se arma una vez y la plantilla solo pone el marcador.
    final horario = [
      txtLunesJueves,
      if (txtViernes.isNotEmpty) txtViernes,
      if (txtSabado.isNotEmpty) txtSabado,
    ].where((s) => s.isNotEmpty).join(', ');

    // Monto en cifras y en palabras, tal como salia impreso.
    final montoNum = c['montonum'];
    final sueldo = montoNum == null
        ? ''
        : '${numfor.format(montoNum)} (${texto(c['montotext'])})';

    return {
      'trabajador.nombre':
          '${texto(w.name).toUpperCase()} ${texto(w.lastName).toUpperCase()}'
              .trim(),
      'trabajador.rut': texto(w.rut).toUpperCase(),
      'trabajador.labor': texto(w.labor).toUpperCase(),
      'trabajador.nacionalidad': texto(w.nacionality).toUpperCase(),
      'trabajador.estado_civil': texto(w.civilState).toUpperCase(),
      // El modelo escribe `adress` con una sola d; se deja como esta para no
      // tocar los 674 documentos que ya usan ese nombre de campo.
      'trabajador.domicilio': texto(w.adress),
      'trabajador.comuna': texto(w.commune).toUpperCase(),
      'trabajador.correo': texto(w.email).toUpperCase(),
      'trabajador.afp': texto(w.afp).toUpperCase(),
      'trabajador.prevision': texto(w.prevision).toUpperCase(),
      'trabajador.nacimiento': texto(w.birth).toUpperCase(),
      'empresa.nombre': texto(e['nombreempresa']),
      'empresa.rut': texto(e['rut']),
      'empresa.representante': texto(e['representante']),
      'empresa.representante_rut': texto(e['representante_rut']),
      'empresa.domicilio': texto(e['domicilio']),
      'empresa.correo': texto(e['correo']),
      'contrato.fecha': DateFormat('dd/MM/yyyy').format(DateTime.now()),
      'contrato.anio': '${DateTime.now().year}',
      'contrato.fecha_ingreso': texto(w.ingress).toUpperCase(),
      'contrato.faena': texto(w.labor).toUpperCase(),
      'contrato.establecimiento': texto(w.place).toUpperCase(),
      'contrato.horario': horario,
      'contrato.colacion': txtColacion,
      'contrato.horas_semanales': '$horasSemanales',
      'contrato.sueldo': sueldo,
    };
  }

  /// Cuerpo de un documento a partir de su plantilla publicada.
  ///
  /// Si en esta base todavia no hay plantilla para ese tipo, devuelve el
  /// [respaldo] escrito en codigo. La migracion va documento a documento y
  /// `pruebas` va por delante de produccion; sin este camino, un documento sin
  /// plantilla saldria en blanco en vez de seguir emitiendose como siempre.
  List<pw.Widget> _cuerpoDeDocumento(
    VersionPlantilla? plantilla,
    Map<String, String> datos,
    ByteData calibri,
    ByteData calibriBold,
    double letterSize,
    double baselina,
    List<pw.Widget> Function() respaldo, {
    TipoPlantilla? tipo,
    List<List<String>> filas = const [],
  }) {
    if (plantilla == null) return respaldo();

    final cuerpo = PlantillaRenderer(
      fuenteNormal: pw.Font.ttf(calibri),
      fuenteNegrita: pw.Font.ttf(calibriBold),
      datos: datos,
      tamanoBase: letterSize,
      baseline: baselina,
      espacioAntesDelPrimero: true,
      encabezadosTabla: tipo?.tabla,
      filasTabla: filas,
    ).construir(plantilla.delta);

    // Las firmas van aqui y no escritas en cada documento: asi el PDF y la
    // vista previa las sacan del mismo descriptor y no pueden discrepar. Antes
    // cada generador armaba las suyas y la vista previa no las mostraba.
    return [...cuerpo, ..._firmasDeDocumento(tipo, datos, calibriBold)];
  }

  /// Bloque de firmas de un documento, segun lo que declare su tipo.
  List<pw.Widget> _firmasDeDocumento(
    TipoPlantilla? tipo,
    Map<String, String> datos,
    ByteData calibriBold,
  ) {
    final lineas = tipo?.firmas ?? const <LineaDeFirma>[];
    if (lineas.isEmpty) return const [];

    final fuente = pw.Font.ttf(calibriBold);
    final estilo = pw.TextStyle(
      font: fuente,
      fontWeight: pw.FontWeight.bold,
      fontSize: 12,
    );

    pw.Widget firma(LineaDeFirma f) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          mainAxisSize: pw.MainAxisSize.min,
          children: [
            pw.Text('_______________________________', style: estilo),
            pw.SizedBox(height: 8),
            pw.Text(datos[f.claveNombre] ?? '', style: estilo),
            if (f.claveRut != null)
              pw.Text('RUT N°: ${datos[f.claveRut] ?? ''}', style: estilo),
            pw.Text(f.rol, style: estilo),
            if (f.nota != null)
              pw.SizedBox(
                width: 200,
                child: pw.Text(
                  f.nota!,
                  textAlign: pw.TextAlign.center,
                  style: pw.TextStyle(font: fuente, fontSize: 10),
                ),
              ),
          ],
        );

    return [
      pw.SizedBox(height: 44),
      pw.Row(
        mainAxisAlignment: lineas.length == 1
            ? pw.MainAxisAlignment.center
            : pw.MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [for (final f in lineas) firma(f)],
      ),
    ];
  }

  /// Cuerpo del Registro tal como estaba escrito en el codigo.
  ///
  /// Respaldo mientras la migracion avanza documento a documento: si
  /// `Plantillas/registro` no existe en esta base, el documento se sigue
  /// emitiendo con este texto en vez de salir vacio. Se borra cuando la
  /// plantilla este publicada en produccion.
  List<pw.Widget> _registroEnCodigo(
    DocumentSnapshot empresa,
    ByteData calibri,
    ByteData calibriBold,
    double letterSize,
    double baselina,
  ) {
    return [
      pw.Padding(
        padding: const pw.EdgeInsets.only(top: 30),
        child: pw.Center(
          child: pw.Text(
            'REGISTRO DE ENTREGA DE REGLAMENTO DE HIGIENE Y SEGURIDAD',
            style: pw.TextStyle(
              decoration: pw.TextDecoration.underline,
              font: pw.Font.ttf(calibriBold),
              fontWeight: pw.FontWeight.bold,
              fontSize: letterSize,
            ),
          ),
        ),
      ),
      pw.Center(
        child: pw.Text(
          '(LEY 16.744 CODIGO DEL TRABAJO)',
          style: pw.TextStyle(
            decoration: pw.TextDecoration.underline,
            font: pw.Font.ttf(calibriBold),
            fontSize: letterSize,
          ),
        ),
      ),
      pw.Padding(
        padding: const pw.EdgeInsets.only(top: 20),
        child: pw.RichText(
          textAlign: pw.TextAlign.justify,
          text: pw.TextSpan(
            baseline: baselina,
            text: 'Yo: ',
            style: pw.TextStyle(
              font: pw.Font.ttf(calibri),
              fontSize: letterSize,
            ),
            children: [
              pw.TextSpan(
                baseline: baselina,
                text:
                    '${widget.worker.name!.toUpperCase()} ${widget.worker.lastName!.toUpperCase()}',
                style: pw.TextStyle(
                  font: pw.Font.ttf(calibriBold),
                  fontSize: letterSize,
                ),
              ),
              pw.TextSpan(
                baseline: baselina,
                text: ', RUT: N° ',
                style: pw.TextStyle(
                  font: pw.Font.ttf(calibri),
                  fontSize: letterSize,
                ),
              ),
              pw.TextSpan(
                baseline: baselina,
                text: widget.worker.rut,
                style: pw.TextStyle(
                  font: pw.Font.ttf(calibriBold),
                  fontSize: letterSize,
                ),
              ),
              pw.TextSpan(
                baseline: baselina,
                text: ', Cargo: ',
                style: pw.TextStyle(
                  font: pw.Font.ttf(calibri),
                  fontSize: letterSize,
                ),
              ),
              pw.TextSpan(
                baseline: baselina,
                text: widget.worker.labor!.toUpperCase(),
                style: pw.TextStyle(
                  font: pw.Font.ttf(calibriBold),
                  fontSize: letterSize,
                ),
              ),
              pw.TextSpan(
                baseline: baselina,
                text: ', con fecha: ',
                style: pw.TextStyle(
                  font: pw.Font.ttf(calibri),
                  fontSize: letterSize,
                ),
              ),
              pw.TextSpan(
                baseline: baselina,
                text: widget.worker.ingress!.toUpperCase(),
                style: pw.TextStyle(
                  font: pw.Font.ttf(calibriBold),
                  fontSize: letterSize,
                ),
              ),
            ],
          ),
        ),
      ),
      pw.Padding(
        padding: const pw.EdgeInsets.only(top: 20),
        child: pw.RichText(
          textAlign: pw.TextAlign.justify,
          text: pw.TextSpan(
            baseline: baselina,
            text:
                'Bajo mi firma declaro haber recibido un ejemplar del reglamento interno de orden higiene y seguridad de la empresa ',
            style: pw.TextStyle(
              font: pw.Font.ttf(calibri),
              fontSize: letterSize,
            ),
            children: [
              pw.TextSpan(
                baseline: baselina,
                text: '${empresa['nombreempresa']}.,',
                style: pw.TextStyle(
                  font: pw.Font.ttf(calibriBold),
                  fontSize: letterSize,
                ),
              ),
              pw.TextSpan(
                baseline: baselina,
                text: ' RUT N° ',
                style: pw.TextStyle(
                  font: pw.Font.ttf(calibri),
                  fontSize: letterSize,
                ),
              ),
              pw.TextSpan(
                baseline: baselina,
                text: '${empresa['rut']}',
                style: pw.TextStyle(
                  font: pw.Font.ttf(calibriBold),
                  fontSize: letterSize,
                ),
              ),
              pw.TextSpan(
                baseline: baselina,
                text: ', Representada por Don ',
                style: pw.TextStyle(
                  font: pw.Font.ttf(calibri),
                  fontSize: letterSize,
                ),
              ),
              pw.TextSpan(
                baseline: baselina,
                text: 'OCTAVIO ORLANDO NUNEZ MENARES',
                style: pw.TextStyle(
                  font: pw.Font.ttf(calibriBold),
                  fontSize: letterSize,
                ),
              ),
              pw.TextSpan(
                baseline: baselina,
                text: ' RUT N° ',
                style: pw.TextStyle(
                  font: pw.Font.ttf(calibri),
                  fontSize: letterSize,
                ),
              ),
              pw.TextSpan(
                baseline: baselina,
                text: '11.171.021-K',
                style: pw.TextStyle(
                  font: pw.Font.ttf(calibriBold),
                  fontSize: letterSize,
                ),
              ),
              pw.TextSpan(
                baseline: baselina,
                text:
                    ', del cual me comprometo a tomar conocimiento en su totalidad no pudiendo alegar desconocimiento de su texto a su entrega, reconociendo además en forma expresa que este reglamento interno es parte integrante del contrato de trabajo que mantengo vigente con la empresa.',
                style: pw.TextStyle(
                  font: pw.Font.ttf(calibri),
                  fontSize: letterSize,
                ),
              ),
            ],
          ),
        ),
      ),
    ];
  }

  /// Cuerpo del Contrato tal como estaba escrito en el codigo.
  ///
  /// Respaldo hasta que la plantilla este publicada en produccion. Se borra
  /// entonces.
  List<pw.Widget> _contratoEnCodigo(
    DocumentSnapshot empresa,
    DocumentSnapshot contrato,
    int horasSemanales,
    String txtLunesJueves,
    String txtViernes,
    String txtSabado,
    String txtColacion,
    ByteData calibri,
    ByteData calibriBold,
    double letterSize,
    double baselina,
  ) {
    return [
      pw.Padding(
        padding: const pw.EdgeInsets.only(top: 20),
        child: pw.Center(
          child: pw.Text(
            'CONTRATO DE TRABAJO PARA FAENA DETERMINADA',
            style: pw.TextStyle(
              decoration: pw.TextDecoration.underline,
              font: pw.Font.ttf(calibriBold),
              fontSize: letterSize,
            ),
          ),
        ),
      ),
      pw.Padding(
        padding: const pw.EdgeInsets.only(top: 20),
        child: pw.RichText(
          textAlign: pw.TextAlign.justify,
          text: pw.TextSpan(
            baseline: baselina,
            text: 'En Paine, a ',
            style: pw.TextStyle(
              font: pw.Font.ttf(calibri),
              fontSize: letterSize,
            ),
            children: [
              pw.TextSpan(
                baseline: baselina,
                text: widget.worker.ingress!.toUpperCase(),
                style: pw.TextStyle(
                  font: pw.Font.ttf(calibriBold),
                  fontSize: letterSize,
                ),
              ),
              pw.TextSpan(
                baseline: baselina,
                text: ', entre ',
                style: pw.TextStyle(
                  font: pw.Font.ttf(calibri),
                  fontSize: letterSize,
                ),
              ),
              pw.TextSpan(
                baseline: baselina,
                text: '${empresa['nombreempresa']}.,',
                style: pw.TextStyle(
                  font: pw.Font.ttf(calibriBold),
                  fontSize: letterSize,
                ),
              ),
              pw.TextSpan(
                baseline: baselina,
                text: ' RUT N° ',
                style: pw.TextStyle(
                  font: pw.Font.ttf(calibri),
                  fontSize: letterSize,
                ),
              ),
              pw.TextSpan(
                baseline: baselina,
                text: '${empresa['rut']}',
                style: pw.TextStyle(
                  font: pw.Font.ttf(calibriBold),
                  fontSize: letterSize,
                ),
              ),
              pw.TextSpan(
                baseline: baselina,
                text: ', Representada por Don ',
                style: pw.TextStyle(
                  font: pw.Font.ttf(calibri),
                  fontSize: letterSize,
                ),
              ),
              pw.TextSpan(
                baseline: baselina,
                text: 'OCTAVIO ORLANDO NUNEZ MENARES',
                style: pw.TextStyle(
                  font: pw.Font.ttf(calibriBold),
                  fontSize: letterSize,
                ),
              ),
              pw.TextSpan(
                baseline: baselina,
                text: ' RUT N° ',
                style: pw.TextStyle(
                  font: pw.Font.ttf(calibri),
                  fontSize: letterSize,
                ),
              ),
              pw.TextSpan(
                baseline: baselina,
                text: '11.171.021-K',
                style: pw.TextStyle(
                  font: pw.Font.ttf(calibriBold),
                  fontSize: letterSize,
                ),
              ),
              pw.TextSpan(
                baseline: baselina,
                text: ' correo electrónico ',
                style: pw.TextStyle(
                  font: pw.Font.ttf(calibri),
                  fontSize: letterSize,
                ),
              ),
              pw.TextSpan(
                baseline: baselina,
                text: 'MRL.ANDREA@LIVE.COM',
                style: pw.TextStyle(
                  font: pw.Font.ttf(calibriBold),
                  fontSize: letterSize,
                ),
              ),
              pw.TextSpan(
                baseline: baselina,
                text:
                    ', ambos con domicilio en O’Higgins Pelay Lt 2 H Pc N° 2 A, Comuna San Francisco De Mostazal, en lo sucesivo ',
                style: pw.TextStyle(
                  font: pw.Font.ttf(calibri),
                  fontSize: letterSize,
                ),
              ),
              pw.TextSpan(
                baseline: baselina,
                text: 'El “Empleador”',
                style: pw.TextStyle(
                  font: pw.Font.ttf(calibriBold),
                  decoration: pw.TextDecoration.underline,
                  fontSize: letterSize,
                ),
              ),
              pw.TextSpan(
                baseline: baselina,
                text: ' y Don(a): ',
                style: pw.TextStyle(
                  font: pw.Font.ttf(calibriBold),
                  fontSize: letterSize,
                ),
              ),
              pw.TextSpan(
                baseline: baselina,
                text:
                    '${widget.worker.name!.toUpperCase()} ${widget.worker.lastName!.toUpperCase()}',
                style: pw.TextStyle(
                  font: pw.Font.ttf(calibriBold),
                  fontSize: letterSize,
                ),
              ),
              pw.TextSpan(
                baseline: baselina,
                text: ', RUT N° ',
                style: pw.TextStyle(
                  font: pw.Font.ttf(calibri),
                  fontSize: letterSize,
                ),
              ),
              pw.TextSpan(
                baseline: baselina,
                text: widget.worker.rut,
                style: pw.TextStyle(
                  font: pw.Font.ttf(calibriBold),
                  fontSize: letterSize,
                ),
              ),
              if (widget.worker.email != null && widget.worker.email != '') ...[
                pw.TextSpan(
                  baseline: baselina,
                  text: ', correo electrónico ',
                  style: pw.TextStyle(
                    font: pw.Font.ttf(calibri),
                    fontSize: letterSize,
                  ),
                ),
                pw.TextSpan(
                  baseline: baselina,
                  text: widget.worker.email!.toUpperCase(),
                  style: pw.TextStyle(
                    font: pw.Font.ttf(calibriBold),
                    fontSize: letterSize,
                  ),
                ),
              ],
              pw.TextSpan(
                baseline: baselina,
                text: ', de nacionalidad ',
                style: pw.TextStyle(
                  font: pw.Font.ttf(calibri),
                  fontSize: letterSize,
                ),
              ),
              pw.TextSpan(
                baseline: baselina,
                text: widget.worker.nacionality!.toUpperCase(),
                style: pw.TextStyle(
                  font: pw.Font.ttf(calibriBold),
                  fontSize: letterSize,
                ),
              ),
              pw.TextSpan(
                baseline: baselina,
                text: ', estado civil ',
                style: pw.TextStyle(
                  font: pw.Font.ttf(calibri),
                  fontSize: letterSize,
                ),
              ),
              pw.TextSpan(
                baseline: baselina,
                text: widget.worker.civilState!.toUpperCase(),
                style: pw.TextStyle(
                  font: pw.Font.ttf(calibriBold),
                  fontSize: letterSize,
                ),
              ),
              pw.TextSpan(
                baseline: baselina,
                text: ', fecha de nacimiento ',
                style: pw.TextStyle(
                  font: pw.Font.ttf(calibri),
                  fontSize: letterSize,
                ),
              ),
              pw.TextSpan(
                baseline: baselina,
                text: widget.worker.birth!.toUpperCase(),
                style: pw.TextStyle(
                  font: pw.Font.ttf(calibriBold),
                  fontSize: letterSize,
                ),
              ),
              pw.TextSpan(
                baseline: baselina,
                text: ', con domicilio en ',
                style: pw.TextStyle(
                  font: pw.Font.ttf(calibri),
                  fontSize: letterSize,
                ),
              ),
              pw.TextSpan(
                baseline: baselina,
                text: widget.worker.adress!.toUpperCase(),
                style: pw.TextStyle(
                  font: pw.Font.ttf(calibriBold),
                  fontSize: letterSize,
                ),
              ),
              pw.TextSpan(
                baseline: baselina,
                text: ', comuna de ',
                style: pw.TextStyle(
                  font: pw.Font.ttf(calibri),
                  fontSize: letterSize,
                ),
              ),
              pw.TextSpan(
                baseline: baselina,
                text: widget.worker.commune!.toUpperCase(),
                style: pw.TextStyle(
                  font: pw.Font.ttf(calibriBold),
                  fontSize: letterSize,
                ),
              ),
              pw.TextSpan(
                baseline: baselina,
                text: ', en adelante el ',
                style: pw.TextStyle(
                  font: pw.Font.ttf(calibri),
                  fontSize: letterSize,
                ),
              ),
              pw.TextSpan(
                baseline: baselina,
                text: '“trabajador”',
                style: pw.TextStyle(
                  font: pw.Font.ttf(calibriBold),
                  decoration: pw.TextDecoration.underline,
                  fontSize: letterSize,
                ),
              ),
              pw.TextSpan(
                baseline: baselina,
                text: ' se suscribe el siguiente contrato de trabajo:',
                style: pw.TextStyle(
                  font: pw.Font.ttf(calibri),
                  fontSize: letterSize,
                ),
              ),
            ],
          ),
        ),
      ),
      pw.Padding(
        padding: const pw.EdgeInsets.only(top: 12),
        child: pw.RichText(
          textAlign: pw.TextAlign.justify,
          text: pw.TextSpan(
            baseline: baselina,
            text: 'Primero: ',
            style: pw.TextStyle(
              font: pw.Font.ttf(calibriBold),
              fontSize: letterSize,
            ),
            children: [
              pw.TextSpan(
                baseline: baselina,
                text: 'El Empleador contrata al trabajador para ejecutar ',
                style: pw.TextStyle(
                  font: pw.Font.ttf(calibri),
                  fontSize: letterSize,
                ),
              ),
              pw.TextSpan(
                baseline: baselina,
                text: widget.worker.labor!.toUpperCase(),
                style: pw.TextStyle(
                  font: pw.Font.ttf(calibriBold),
                  fontSize: letterSize,
                ),
              ),
              pw.TextSpan(
                baseline: baselina,
                text: ' en el establecimiento de ',
                style: pw.TextStyle(
                  font: pw.Font.ttf(calibri),
                  fontSize: letterSize,
                ),
              ),
              pw.TextSpan(
                baseline: baselina,
                text: widget.worker.place!.toUpperCase(),
                style: pw.TextStyle(
                  font: pw.Font.ttf(calibriBold),
                  fontSize: letterSize,
                ),
              ),
              pw.TextSpan(
                baseline: baselina,
                text: '.',
                style: pw.TextStyle(
                  font: pw.Font.ttf(calibri),
                  fontSize: letterSize,
                ),
              ),
            ],
          ),
        ),
      ),
      pw.Padding(
        padding: const pw.EdgeInsets.only(top: 12),
        child: pw.RichText(
          textAlign: pw.TextAlign.justify,
          text: pw.TextSpan(
            baseline: baselina,
            text: 'Segundo: ',
            style: pw.TextStyle(
              font: pw.Font.ttf(calibriBold),
              fontSize: letterSize,
            ),
            children: [
              pw.TextSpan(
                baseline: baselina,
                text:
                    'El empleador se compromete a remunerar al trabajador la suma de ',
                style: pw.TextStyle(
                  font: pw.Font.ttf(calibri),
                  fontSize: letterSize,
                ),
              ),
              pw.TextSpan(
                baseline: baselina,
                text:
                    '${numfor.format(contrato['montonum'])} (${contrato['montotext']})',
                style: pw.TextStyle(
                  font: pw.Font.ttf(calibriBold),
                  fontSize: letterSize,
                ),
              ),
              pw.TextSpan(
                baseline: baselina,
                text:
                    ', diarios, del monto señalado el empleador efectuara los descuentos correspondientes a las leyes sociales.',
                style: pw.TextStyle(
                  font: pw.Font.ttf(calibri),
                  fontSize: letterSize,
                ),
              ),
            ],
          ),
        ),
      ),
      pw.Padding(
        padding: const pw.EdgeInsets.only(top: 12),
        child: pw.RichText(
          textAlign: pw.TextAlign.justify,
          text: pw.TextSpan(
            baseline: baselina,
            text: 'Tercero: ',
            style: pw.TextStyle(
              font: pw.Font.ttf(calibriBold),
              fontSize: letterSize,
            ),
            children: [
              pw.TextSpan(
                baseline: baselina,
                /* La jornada de trabajo será de lunes a viernes de 8:00 hrs hasta las 12:00 hrs y de 13:00 a 17:00 hrs. El horario de trabajo podrá ser modificado de acuerdo con las necesidades del empleador. El horario de trabajo será interrumpido durante 1 hora para colación, tiempo de conformidad a la ley, no se considera como parte de la jornada de trabajo. */
                text:
                    'El trabajador se obliga a cumplir la siguiente jornada de trabajo de ',
                style: pw.TextStyle(
                  font: pw.Font.ttf(calibri),
                  fontSize: letterSize,
                ),
              ),
              pw.TextSpan(
                baseline: baselina,
                text: '$horasSemanales horas semanales.',
                style: pw.TextStyle(
                  font: pw.Font.ttf(calibriBold),
                  fontSize: letterSize,
                ),
              ),
              pw.TextSpan(
                baseline: baselina,
                text:
                    ' $txtLunesJueves,${txtViernes != "" ? " $txtViernes," : ""}${txtSabado != "" ? " $txtSabado," : ""} con $txtColacion de colación.',
                style: pw.TextStyle(
                  font: pw.Font.ttf(calibri),
                  fontSize: letterSize,
                ),
              ),
            ],
          ),
        ),
      ),
      pw.Padding(
        padding: const pw.EdgeInsets.only(top: 12),
        child: pw.RichText(
          textAlign: pw.TextAlign.justify,
          text: pw.TextSpan(
            baseline: baselina,
            text: 'Cuarto: ',
            style: pw.TextStyle(
              font: pw.Font.ttf(calibriBold),
              fontSize: letterSize,
            ),
            children: [
              pw.TextSpan(
                baseline: baselina,
                text:
                    'Queda estrictamente prohibido al trabajador realizar cualquier labor o trabajo, ya sea por cuenta propia o ajena que valla en desmedro de las obligaciones que asume, en especial en aquellas referidas al cumplimiento a las jornadas de trabajo.',
                style: pw.TextStyle(
                  font: pw.Font.ttf(calibri),
                  fontSize: letterSize,
                ),
              ),
            ],
          ),
        ),
      ),
      pw.Padding(
        padding: const pw.EdgeInsets.only(top: 12),
        child: pw.RichText(
          textAlign: pw.TextAlign.justify,
          text: pw.TextSpan(
            baseline: baselina,
            text: 'Quinto: ',
            style: pw.TextStyle(
              font: pw.Font.ttf(calibriBold),
              fontSize: letterSize,
            ),
            children: [
              pw.TextSpan(
                baseline: baselina,
                text:
                    'El presente contrato durará la faena determinada descrita anteriormente pudiendo cualquiera de las partes ponerle termino a las condiciones, las cuales establece el código del trabajo.',
                style: pw.TextStyle(
                  font: pw.Font.ttf(calibri),
                  fontSize: letterSize,
                ),
              ),
            ],
          ),
        ),
      ),
      pw.Padding(
        padding: const pw.EdgeInsets.only(top: 12),
        child: pw.RichText(
          textAlign: pw.TextAlign.justify,
          text: pw.TextSpan(
            baseline: baselina,
            text: 'Sexto: ',
            style: pw.TextStyle(
              font: pw.Font.ttf(calibriBold),
              fontSize: letterSize,
            ),
            children: [
              pw.TextSpan(
                baseline: baselina,
                text:
                    'Se hace entrega del reglamento interno de la empresa, el trabajador toma conocimiento y se compromete a cumplir las obligaciones y prohibiciones que en él se mencionan del derecho de saber.',
                style: pw.TextStyle(
                  font: pw.Font.ttf(calibri),
                  fontSize: letterSize,
                ),
              ),
            ],
          ),
        ),
      ),
      pw.Padding(
        padding: const pw.EdgeInsets.only(top: 12),
        child: pw.RichText(
          textAlign: pw.TextAlign.justify,
          text: pw.TextSpan(
            baseline: baselina,
            text: 'Séptimo: ',
            style: pw.TextStyle(
              font: pw.Font.ttf(calibriBold),
              fontSize: letterSize,
            ),
            children: [
              pw.TextSpan(
                baseline: baselina,
                text: 'El trabajador se encuentra afiliado a la AFP ',
                style: pw.TextStyle(
                  font: pw.Font.ttf(calibri),
                  fontSize: letterSize,
                ),
              ),
              pw.TextSpan(
                baseline: baselina,
                text: widget.worker.afp!.toUpperCase(),
                style: pw.TextStyle(
                  font: pw.Font.ttf(calibriBold),
                  fontSize: letterSize,
                ),
              ),
              pw.TextSpan(
                baseline: baselina,
                text:
                    '. Asimismo, se encuentra afiliado a la Previsión de Salud ',
                style: pw.TextStyle(
                  font: pw.Font.ttf(calibri),
                  fontSize: letterSize,
                ),
              ),
              pw.TextSpan(
                baseline: baselina,
                text: '${widget.worker.prevision!.toUpperCase()}.',
                style: pw.TextStyle(
                  font: pw.Font.ttf(calibriBold),
                  fontSize: letterSize,
                ),
              ),
            ],
          ),
        ),
      ),
      pw.Padding(
        padding: const pw.EdgeInsets.only(top: 12),
        child: pw.RichText(
          textAlign: pw.TextAlign.justify,
          text: pw.TextSpan(
            baseline: baselina,
            text: 'Octavo: ',
            style: pw.TextStyle(
              font: pw.Font.ttf(calibriBold),
              fontSize: letterSize,
            ),
            children: [
              pw.TextSpan(
                baseline: baselina,
                text: 'Se deja constancia que el trabajador ingresó el día ',
                style: pw.TextStyle(
                  font: pw.Font.ttf(calibri),
                  fontSize: letterSize,
                ),
              ),
              pw.TextSpan(
                baseline: baselina,
                text: widget.worker.ingress!.toUpperCase(),
                style: pw.TextStyle(
                  font: pw.Font.ttf(calibriBold),
                  fontSize: letterSize,
                ),
              ),
              pw.TextSpan(
                baseline: baselina,
                text:
                    ' y expira conjuntamente con las labores que le dieron origen, para lo cual el trabajador se da por notificado de desahucio al momento de suscribir este contrato.',
                style: pw.TextStyle(
                  font: pw.Font.ttf(calibri),
                  fontSize: letterSize,
                ),
              ),
            ],
          ),
        ),
      ),
      pw.Padding(
        padding: const pw.EdgeInsets.only(top: 12),
        child: pw.RichText(
          textAlign: pw.TextAlign.justify,
          text: pw.TextSpan(
            baseline: baselina,
            text:
                'El presente contrato se firma en dos ejemplares, quedando uno de ellos en poder del empleador y el otro en poder del trabajador, quien declara recibirlo a su entera satisfacción.',
            style: pw.TextStyle(
              font: pw.Font.ttf(calibri),
              fontSize: letterSize,
            ),
          ),
        ),
      ),
    ];
  }

  /// Cuerpo de este documento tal como estaba escrito en el codigo.
  ///
  /// Respaldo hasta que la plantilla este publicada en produccion.
  List<pw.Widget> _derechoASaberEnCodigo(
    DocumentSnapshot empresa,
    ByteData calibri,
    ByteData calibriBold,
    double letterSize,
    double baselina,
  ) {
    return [
      pw.Padding(
        padding: const pw.EdgeInsets.only(top: 20),
        child: pw.Center(
          child: pw.Text(
            'DERECHO A SABER',
            style: pw.TextStyle(
              decoration: pw.TextDecoration.underline,
              font: pw.Font.ttf(calibriBold),
              fontSize: letterSize,
            ),
          ),
        ),
      ),
      pw.Padding(
        padding: const pw.EdgeInsets.only(top: 20),
        child: pw.RichText(
          textAlign: pw.TextAlign.justify,
          text: pw.TextSpan(
            baseline: baselina,
            text: 'Nombre: ',
            style: pw.TextStyle(
              font: pw.Font.ttf(calibri),
              fontSize: letterSize,
            ),
            children: [
              pw.TextSpan(
                baseline: baselina,
                text:
                    '${widget.worker.name!.toUpperCase()} ${widget.worker.lastName!.toUpperCase()}',
                style: pw.TextStyle(
                  font: pw.Font.ttf(calibriBold),
                  fontSize: letterSize,
                ),
              ),
              pw.TextSpan(
                baseline: baselina,
                text: ', Fecha: ',
                style: pw.TextStyle(
                  font: pw.Font.ttf(calibri),
                  fontSize: letterSize,
                ),
              ),
              pw.TextSpan(
                baseline: baselina,
                text: widget.worker.ingress!.toUpperCase(),
                style: pw.TextStyle(
                  font: pw.Font.ttf(calibriBold),
                  fontSize: letterSize,
                ),
              ),
              pw.TextSpan(
                baseline: baselina,
                text: ', RUT: N° ',
                style: pw.TextStyle(
                  font: pw.Font.ttf(calibri),
                  fontSize: letterSize,
                ),
              ),
              pw.TextSpan(
                baseline: baselina,
                text: widget.worker.rut,
                style: pw.TextStyle(
                  font: pw.Font.ttf(calibriBold),
                  fontSize: letterSize,
                ),
              ),
              pw.TextSpan(
                baseline: baselina,
                text: ', Área de trabajo: ',
                style: pw.TextStyle(
                  font: pw.Font.ttf(calibri),
                  fontSize: letterSize,
                ),
              ),
              pw.TextSpan(
                baseline: baselina,
                text: widget.worker.place!.toUpperCase(),
                style: pw.TextStyle(
                  font: pw.Font.ttf(calibriBold),
                  fontSize: letterSize,
                ),
              ),
            ],
          ),
        ),
      ),
      pw.Padding(
        padding: const pw.EdgeInsets.only(top: 20),
        child: pw.RichText(
          textAlign: pw.TextAlign.justify,
          text: pw.TextSpan(
            baseline: baselina,
            text: 'A través de la presente, la empresa ',
            style: pw.TextStyle(
              font: pw.Font.ttf(calibri),
              fontSize: letterSize,
            ),
            children: [
              pw.TextSpan(
                baseline: baselina,
                text: '${empresa['nombreempresa']}.,',
                style: pw.TextStyle(
                  font: pw.Font.ttf(calibriBold),
                  fontSize: letterSize,
                ),
              ),
              pw.TextSpan(
                baseline: baselina,
                text: ' RUT N° ',
                style: pw.TextStyle(
                  font: pw.Font.ttf(calibri),
                  fontSize: letterSize,
                ),
              ),
              pw.TextSpan(
                baseline: baselina,
                text: '${empresa['rut']}',
                style: pw.TextStyle(
                  font: pw.Font.ttf(calibriBold),
                  fontSize: letterSize,
                ),
              ),
              pw.TextSpan(
                baseline: baselina,
                text: ', Representada por Don ',
                style: pw.TextStyle(
                  font: pw.Font.ttf(calibri),
                  fontSize: letterSize,
                ),
              ),
              pw.TextSpan(
                baseline: baselina,
                text: 'OCTAVIO ORLANDO NUNEZ MENARES',
                style: pw.TextStyle(
                  font: pw.Font.ttf(calibriBold),
                  fontSize: letterSize,
                ),
              ),
              pw.TextSpan(
                baseline: baselina,
                text: ' RUT N° ',
                style: pw.TextStyle(
                  font: pw.Font.ttf(calibri),
                  fontSize: letterSize,
                ),
              ),
              pw.TextSpan(
                baseline: baselina,
                text: '11.171.021-K',
                style: pw.TextStyle(
                  font: pw.Font.ttf(calibriBold),
                  fontSize: letterSize,
                ),
              ),
              pw.TextSpan(
                baseline: baselina,
                text:
                    ', declara haberme informado de los riesgos que entrañan las labores que desarrollaré en mi trabajo, así como las medidas preventivas que debo tomar para hacer de esto un método seguro de trabajo.',
                style: pw.TextStyle(
                  font: pw.Font.ttf(calibri),
                  fontSize: letterSize,
                ),
              ),
            ],
          ),
        ),
      ),
      pw.Padding(
        padding: const pw.EdgeInsets.only(top: 20),
        child: pw.Table(
          columnWidths: {
            0: const pw.FlexColumnWidth(1),
            1: const pw.FlexColumnWidth(3),
          },
          border: const pw.TableBorder(
              top: pw.BorderSide(width: 1),
              bottom: pw.BorderSide(width: 1),
              left: pw.BorderSide(width: 1),
              right: pw.BorderSide(width: 1),
              horizontalInside: pw.BorderSide(width: 1),
              verticalInside: pw.BorderSide(width: 1)),
          children: [
            pw.TableRow(
              children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.all(5),
                  child: pw.Text(
                    'RIESGOS',
                    textAlign: pw.TextAlign.center,
                    style: pw.TextStyle(
                      font: pw.Font.ttf(calibriBold),
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(5),
                  child: pw.Text(
                    'MEDIDAS DE PREVENCION',
                    textAlign: pw.TextAlign.center,
                    style: pw.TextStyle(
                      font: pw.Font.ttf(calibriBold),
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            pw.TableRow(
              children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.all(10),
                  child: pw.Text(
                    'ATROPELLAMIENTO',
                    textAlign: pw.TextAlign.center,
                    style: pw.TextStyle(
                      font: pw.Font.ttf(calibriBold),
                      fontSize: 12,
                    ),
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(10),
                  child: pw.Text(
                    '- Evite correr, transite por calles y recorridos autorizados.\n- En caminos marcados transite enfrentando al conductor.',
                    textAlign: pw.TextAlign.left,
                    style: pw.TextStyle(
                      font: pw.Font.ttf(calibriBold),
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            pw.TableRow(
              children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.all(10),
                  child: pw.Text(
                    'LESIONES OCULARES',
                    textAlign: pw.TextAlign.center,
                    style: pw.TextStyle(
                      font: pw.Font.ttf(calibriBold),
                      fontSize: 12,
                    ),
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(10),
                  child: pw.Text(
                    '- Utilice elementos oculares en todo momento para evitar golpes con ramas al transitar entre las matas o al acercarse a retirar frutas.',
                    textAlign: pw.TextAlign.left,
                    style: pw.TextStyle(
                      font: pw.Font.ttf(calibriBold),
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            pw.TableRow(
              children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.all(10),
                  child: pw.Text(
                    'CAIDAS A NIVEL Y DISTINTO NIVEL',
                    textAlign: pw.TextAlign.center,
                    style: pw.TextStyle(
                      font: pw.Font.ttf(calibriBold),
                      fontSize: 12,
                    ),
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(10),
                  child: pw.Text(
                    '- Utilice pisos y escaleras bien anclados y con responsabilidad.\n- Tener atención a las superficies de trabajo.\n- Mantener su entorno de trabajo libre de obstáculos.\n- No utilice el celular mientras camina.\n-	Cuando transite entre hileras mantenga cuidado con mangueras y ramas de podas pasadas.',
                    textAlign: pw.TextAlign.left,
                    style: pw.TextStyle(
                      font: pw.Font.ttf(calibriBold),
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            pw.TableRow(
              children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.all(10),
                  child: pw.Text(
                    'EXPOSICION A MANEJO MANUAL DE CARGA',
                    textAlign: pw.TextAlign.center,
                    style: pw.TextStyle(
                      font: pw.Font.ttf(calibriBold),
                      fontSize: 12,
                    ),
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(10),
                  child: pw.Text(
                    '- Aplicar método correcto de levantamiento de carga y de posturas correctas de trabajo, el peso máximo a mover es de 25 kg para hombres y 20 kg para mujeres, solicite ayuda si es necesario.\n- No trasladar mas de una escalera o banquillo por persona.',
                    textAlign: pw.TextAlign.left,
                    style: pw.TextStyle(
                      font: pw.Font.ttf(calibriBold),
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            pw.TableRow(
              children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.all(10),
                  child: pw.Text(
                    'EXPOSICION A PRODUCTOS FITOSANITARIOS',
                    textAlign: pw.TextAlign.center,
                    style: pw.TextStyle(
                      font: pw.Font.ttf(calibriBold),
                      fontSize: 12,
                    ),
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(10),
                  child: pw.Text(
                    '- Actuar conforme a los procedimientos de aplicación y resguardo de almacenamiento e higiene que existen para cada tipo.\n- Después de cada aplicación deberá ducharse y usar ropa distinta.\n- Respetar los plazos de resguardo a los cuarteles.',
                    textAlign: pw.TextAlign.left,
                    style: pw.TextStyle(
                      font: pw.Font.ttf(calibriBold),
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            pw.TableRow(
              children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.all(10),
                  child: pw.Text(
                    'EXPOSICION A RADIACION UV SOLAR',
                    textAlign: pw.TextAlign.center,
                    style: pw.TextStyle(
                      font: pw.Font.ttf(calibriBold),
                      fontSize: 12,
                    ),
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(10),
                  child: pw.Text(
                    '- La exposición y/o acumulación de radiación ultravioleta de fuentes naturales o artificiales deben llevar el resguardo necesario.\n- Usar los artículos necesarios para evitar la exposición (lentes con protección uv, gorros legionarios, uso y aplicación de protector solar cada 2 horas si es necesario).',
                    textAlign: pw.TextAlign.left,
                    style: pw.TextStyle(
                      font: pw.Font.ttf(calibriBold),
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      pw.SizedBox(height: 30),
      pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            mainAxisAlignment: pw.MainAxisAlignment.start,
            children: [
              pw.Text(
                '_______________________________',
                style: pw.TextStyle(
                  font: pw.Font.ttf(calibriBold),
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              pw.Text(
                'RELATOR',
                style: pw.TextStyle(
                  font: pw.Font.ttf(calibriBold),
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            mainAxisAlignment: pw.MainAxisAlignment.start,
            children: [
              pw.Text(
                '_______________________________',
                style: pw.TextStyle(
                  font: pw.Font.ttf(calibriBold),
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              pw.Text(
                'TRABAJADOR',
                style: pw.TextStyle(
                  font: pw.Font.ttf(calibriBold),
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              pw.SizedBox(
                width: 200,
                child: pw.Text(
                  'Declaro haber recibido la introducción de seguridad laboral y entender a los riesgos a los que me expongo.',
                  textAlign: pw.TextAlign.center,
                  style: pw.TextStyle(
                    font: pw.Font.ttf(calibriBold),
                    fontSize: 10,
                  ),
                ),
              )
            ],
          ),
        ],
      ),
      pw.SizedBox(height: 10),
    ];
  }

  /// Cuerpo de este documento tal como estaba escrito en el codigo.
  ///
  /// Respaldo hasta que la plantilla este publicada en produccion.
  List<pw.Widget> _eppEnCodigo(
    DocumentSnapshot empresa,
    ByteData calibri,
    ByteData calibriBold,
    double letterSize,
    double baselina,
  ) {
    return [
      pw.Padding(
        padding: const pw.EdgeInsets.only(top: 30),
        child: pw.Center(
          child: pw.Text(
            'FICHA DE ENTREGA DE ELEMENTOS DE PROTECCION',
            style: pw.TextStyle(
              decoration: pw.TextDecoration.underline,
              font: pw.Font.ttf(calibriBold),
              fontSize: letterSize,
            ),
          ),
        ),
      ),
      pw.Padding(
        padding: const pw.EdgeInsets.only(top: 30),
        child: pw.RichText(
          textAlign: pw.TextAlign.justify,
          text: pw.TextSpan(
            baseline: baselina,
            text:
                'Según lo establecido en el articulo 53 del decreto supremo 594, el empleador deberá proporcionar a sus trabajadores, libre de costo, los elementos de protección personal adecuados al riesgo a cubrir y el adiestramiento necesario para su correcto empleo, debiendo, además, mantenerlo en perfecto estado de funcionamiento. Por su parte, el trabajador deberá usarlos en forma permanente mientras se encuentre expuesto al riesgo.',
            style: pw.TextStyle(
              font: pw.Font.ttf(calibri),
              fontSize: letterSize,
            ),
          ),
        ),
      ),
      pw.Padding(
        padding: const pw.EdgeInsets.only(top: 20),
        child: pw.RichText(
          textAlign: pw.TextAlign.justify,
          text: pw.TextSpan(
            baseline: baselina,
            text:
                'Asimismo, se recuerda lo establecido en el articulo 68 de la Ley N° 16.744 donde se indica que “las empresas deberán proporcionar a sus trabajadores los equipos e implementos de protección necesarios, no pudiendo en caso alguno cobrarles su valor”.',
            style: pw.TextStyle(
              font: pw.Font.ttf(calibri),
              fontSize: letterSize,
            ),
          ),
        ),
      ),
      pw.Padding(
        padding: const pw.EdgeInsets.only(top: 30),
        child: pw.Table(
          border: const pw.TableBorder(
              top: pw.BorderSide(width: 1),
              bottom: pw.BorderSide(width: 1),
              left: pw.BorderSide(width: 1),
              right: pw.BorderSide(width: 1),
              horizontalInside: pw.BorderSide(width: 1),
              verticalInside: pw.BorderSide(width: 1)),
          children: [
            pw.TableRow(
              children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.all(5),
                  child: pw.Text(
                    'DETALLE IMPLEMENTOS',
                    textAlign: pw.TextAlign.center,
                    style: pw.TextStyle(
                      font: pw.Font.ttf(calibriBold),
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(5),
                  child: pw.Text(
                    'FECHA DE ENTREGA',
                    textAlign: pw.TextAlign.center,
                    style: pw.TextStyle(
                      font: pw.Font.ttf(calibriBold),
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(5),
                  child: pw.Text(
                    'FECHA DEVOLUCION',
                    textAlign: pw.TextAlign.center,
                    style: pw.TextStyle(
                      font: pw.Font.ttf(calibriBold),
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(5),
                  child: pw.Text(
                    'FIRMA TRABAJADOR',
                    textAlign: pw.TextAlign.center,
                    style: pw.TextStyle(
                      font: pw.Font.ttf(calibriBold),
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            pw.TableRow(
              children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.all(10),
                  child: pw.Text(
                    'GORRO LEGENDARIO',
                    textAlign: pw.TextAlign.center,
                    style: pw.TextStyle(
                      font: pw.Font.ttf(calibriBold),
                      fontSize: 12,
                    ),
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(10),
                  child: pw.Text(
                    widget.worker.ingress!.toUpperCase(),
                    textAlign: pw.TextAlign.left,
                    style: pw.TextStyle(
                      font: pw.Font.ttf(calibriBold),
                      fontSize: 10,
                    ),
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(10),
                  child: pw.Text(
                    '',
                    textAlign: pw.TextAlign.left,
                    style: pw.TextStyle(
                      font: pw.Font.ttf(calibriBold),
                      fontSize: 12,
                    ),
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(10),
                  child: pw.Text(
                    '',
                    textAlign: pw.TextAlign.left,
                    style: pw.TextStyle(
                      font: pw.Font.ttf(calibriBold),
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            pw.TableRow(
              children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.all(10),
                  child: pw.Text(
                    'ANTIPARRAS',
                    textAlign: pw.TextAlign.center,
                    style: pw.TextStyle(
                      font: pw.Font.ttf(calibriBold),
                      fontSize: 12,
                    ),
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(10),
                  child: pw.Text(
                    widget.worker.ingress!.toUpperCase(),
                    textAlign: pw.TextAlign.left,
                    style: pw.TextStyle(
                      font: pw.Font.ttf(calibriBold),
                      fontSize: 10,
                    ),
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(10),
                  child: pw.Text(
                    '',
                    textAlign: pw.TextAlign.left,
                    style: pw.TextStyle(
                      font: pw.Font.ttf(calibriBold),
                      fontSize: 12,
                    ),
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(10),
                  child: pw.Text(
                    '',
                    textAlign: pw.TextAlign.left,
                    style: pw.TextStyle(
                      font: pw.Font.ttf(calibriBold),
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            pw.TableRow(
              children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.all(10),
                  child: pw.Text(
                    'GUANTES',
                    textAlign: pw.TextAlign.center,
                    style: pw.TextStyle(
                      font: pw.Font.ttf(calibriBold),
                      fontSize: 12,
                    ),
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(10),
                  child: pw.Text(
                    widget.worker.ingress!.toUpperCase(),
                    textAlign: pw.TextAlign.left,
                    style: pw.TextStyle(
                      font: pw.Font.ttf(calibriBold),
                      fontSize: 10,
                    ),
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(10),
                  child: pw.Text(
                    '',
                    textAlign: pw.TextAlign.left,
                    style: pw.TextStyle(
                      font: pw.Font.ttf(calibriBold),
                      fontSize: 12,
                    ),
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(10),
                  child: pw.Text(
                    '',
                    textAlign: pw.TextAlign.left,
                    style: pw.TextStyle(
                      font: pw.Font.ttf(calibriBold),
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            pw.TableRow(
              children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.all(10),
                  child: pw.Text(
                    'BLOQUEADOR',
                    textAlign: pw.TextAlign.center,
                    style: pw.TextStyle(
                      font: pw.Font.ttf(calibriBold),
                      fontSize: 12,
                    ),
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(10),
                  child: pw.Text(
                    widget.worker.ingress!.toUpperCase(),
                    textAlign: pw.TextAlign.left,
                    style: pw.TextStyle(
                      font: pw.Font.ttf(calibriBold),
                      fontSize: 10,
                    ),
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(10),
                  child: pw.Text(
                    '',
                    textAlign: pw.TextAlign.left,
                    style: pw.TextStyle(
                      font: pw.Font.ttf(calibriBold),
                      fontSize: 12,
                    ),
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(10),
                  child: pw.Text(
                    '',
                    textAlign: pw.TextAlign.left,
                    style: pw.TextStyle(
                      font: pw.Font.ttf(calibriBold),
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      pw.SizedBox(height: 200),
      pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            mainAxisAlignment: pw.MainAxisAlignment.start,
            children: [
              pw.Text(
                '_______________________________',
                style: pw.TextStyle(
                  font: pw.Font.ttf(calibriBold),
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                '${widget.worker.name!.toUpperCase()} ${widget.worker.lastName!.toUpperCase()}',
                style: pw.TextStyle(
                  font: pw.Font.ttf(calibriBold),
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              pw.Text(
                'RUT N°: ${widget.worker.rut}',
                style: pw.TextStyle(
                  font: pw.Font.ttf(calibriBold),
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              pw.Text(
                'TRABAJADOR',
                style: pw.TextStyle(
                  font: pw.Font.ttf(calibriBold),
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
      pw.SizedBox(height: 20),
    ];
  }

  /// Cuerpo del finiquito tal como estaba escrito en el codigo.
  ///
  /// Respaldo hasta que la plantilla este publicada en produccion.
  List<pw.Widget> _finiquitoEnCodigo(
    DocumentSnapshot empresa,
    ByteData calibri,
    ByteData calibriBold,
    double letterSize,
    double baselina,
  ) {
    return [
      pw.Padding(
        padding: const pw.EdgeInsets.only(top: 20),
        child: pw.Center(
          child: pw.Text(
            'FINIQUITO DEL TRABAJADOR',
            style: pw.TextStyle(
              decoration: pw.TextDecoration.underline,
              font: pw.Font.ttf(calibriBold),
              fontSize: letterSize,
            ),
          ),
        ),
      ),
      pw.Padding(
        padding: const pw.EdgeInsets.only(top: 20),
        child: pw.RichText(
          textAlign: pw.TextAlign.justify,
          text: pw.TextSpan(
            baseline: baselina,
            text: 'En Paine, a ',
            style: pw.TextStyle(
              font: pw.Font.ttf(calibri),
              fontSize: letterSize,
            ),
            children: [
              pw.TextSpan(
                baseline: baselina,
                text: _exitController.text.toUpperCase(),
                style: pw.TextStyle(
                  font: pw.Font.ttf(calibriBold),
                  fontSize: letterSize,
                ),
              ),
              pw.TextSpan(
                baseline: baselina,
                text: ', entre ',
                style: pw.TextStyle(
                  font: pw.Font.ttf(calibri),
                  fontSize: letterSize,
                ),
              ),
              pw.TextSpan(
                baseline: baselina,
                text: '${empresa['nombreempresa']}.,',
                style: pw.TextStyle(
                  font: pw.Font.ttf(calibriBold),
                  fontSize: letterSize,
                ),
              ),
              pw.TextSpan(
                baseline: baselina,
                text: ' RUT N° ',
                style: pw.TextStyle(
                  font: pw.Font.ttf(calibri),
                  fontSize: letterSize,
                ),
              ),
              pw.TextSpan(
                baseline: baselina,
                text: '${empresa['rut']}',
                style: pw.TextStyle(
                  font: pw.Font.ttf(calibriBold),
                  fontSize: letterSize,
                ),
              ),
              pw.TextSpan(
                baseline: baselina,
                text: ', Representada por Don ',
                style: pw.TextStyle(
                  font: pw.Font.ttf(calibri),
                  fontSize: letterSize,
                ),
              ),
              pw.TextSpan(
                baseline: baselina,
                text: 'OCTAVIO ORLANDO NUNEZ MENARES',
                style: pw.TextStyle(
                  font: pw.Font.ttf(calibriBold),
                  fontSize: letterSize,
                ),
              ),
              pw.TextSpan(
                baseline: baselina,
                text: ' RUT N° ',
                style: pw.TextStyle(
                  font: pw.Font.ttf(calibri),
                  fontSize: letterSize,
                ),
              ),
              pw.TextSpan(
                baseline: baselina,
                text: '11.171.021-K',
                style: pw.TextStyle(
                  font: pw.Font.ttf(calibriBold),
                  fontSize: letterSize,
                ),
              ),
              pw.TextSpan(
                baseline: baselina,
                text:
                    ', ambos con domicilio en O’Higgins Pelay Lt 2 H Pc N° 2 A, Comuna San Francisco De Mostazal, en lo sucesivo ',
                style: pw.TextStyle(
                  font: pw.Font.ttf(calibri),
                  fontSize: letterSize,
                ),
              ),
              pw.TextSpan(
                baseline: baselina,
                text: 'El “Empleador”',
                style: pw.TextStyle(
                  font: pw.Font.ttf(calibriBold),
                  decoration: pw.TextDecoration.underline,
                  fontSize: letterSize,
                ),
              ),
              pw.TextSpan(
                baseline: baselina,
                text: ' y Don(a): ',
                style: pw.TextStyle(
                  font: pw.Font.ttf(calibriBold),
                  fontSize: letterSize,
                ),
              ),
              pw.TextSpan(
                baseline: baselina,
                text:
                    '${widget.worker.name!.toUpperCase()} ${widget.worker.lastName!.toUpperCase()}',
                style: pw.TextStyle(
                  font: pw.Font.ttf(calibriBold),
                  fontSize: letterSize,
                ),
              ),
              pw.TextSpan(
                baseline: baselina,
                text: ', RUT N° ',
                style: pw.TextStyle(
                  font: pw.Font.ttf(calibri),
                  fontSize: letterSize,
                ),
              ),
              pw.TextSpan(
                baseline: baselina,
                text: widget.worker.rut,
                style: pw.TextStyle(
                  font: pw.Font.ttf(calibriBold),
                  fontSize: letterSize,
                ),
              ),
              pw.TextSpan(
                baseline: baselina,
                text: ', se acuerda el siguiente finiquito:',
                style: pw.TextStyle(
                  font: pw.Font.ttf(calibri),
                  fontSize: letterSize,
                ),
              ),
            ],
          ),
        ),
      ),
      pw.Padding(
        padding: const pw.EdgeInsets.only(top: 12),
        child: pw.RichText(
          textAlign: pw.TextAlign.justify,
          text: pw.TextSpan(
            baseline: baselina,
            text: 'Primero: ',
            style: pw.TextStyle(
              font: pw.Font.ttf(calibriBold),
              fontSize: letterSize,
            ),
            children: [
              pw.TextSpan(
                baseline: baselina,
                text: 'Don(a) ',
                style: pw.TextStyle(
                  font: pw.Font.ttf(calibri),
                  fontSize: letterSize,
                ),
              ),
              pw.TextSpan(
                baseline: baselina,
                text:
                    '${widget.worker.name!.toUpperCase()} ${widget.worker.lastName!.toUpperCase()}',
                style: pw.TextStyle(
                  font: pw.Font.ttf(calibriBold),
                  fontSize: letterSize,
                ),
              ),
              pw.TextSpan(
                baseline: baselina,
                text: ', RUT N° ',
                style: pw.TextStyle(
                  font: pw.Font.ttf(calibri),
                  fontSize: letterSize,
                ),
              ),
              pw.TextSpan(
                baseline: baselina,
                text: widget.worker.rut,
                style: pw.TextStyle(
                  font: pw.Font.ttf(calibriBold),
                  fontSize: letterSize,
                ),
              ),
              pw.TextSpan(
                baseline: baselina,
                text:
                    ', prestó servicios a “${empresa['nombreempresa']}”, ejecutando ',
                style: pw.TextStyle(
                  font: pw.Font.ttf(calibri),
                  fontSize: letterSize,
                ),
              ),
              pw.TextSpan(
                baseline: baselina,
                text: widget.worker.labor!.toUpperCase(),
                style: pw.TextStyle(
                  font: pw.Font.ttf(calibriBold),
                  fontSize: letterSize,
                ),
              ),
              pw.TextSpan(
                baseline: baselina,
                text: ', desde el día ',
                style: pw.TextStyle(
                  font: pw.Font.ttf(calibri),
                  fontSize: letterSize,
                ),
              ),
              pw.TextSpan(
                baseline: baselina,
                text: widget.worker.ingress!.toUpperCase(),
                style: pw.TextStyle(
                  font: pw.Font.ttf(calibriBold),
                  fontSize: letterSize,
                ),
              ),
              pw.TextSpan(
                baseline: baselina,
                text: ' hasta el día ',
                style: pw.TextStyle(
                  font: pw.Font.ttf(calibri),
                  fontSize: letterSize,
                ),
              ),
              pw.TextSpan(
                baseline: baselina,
                text: _exitController.text.toUpperCase(),
                style: pw.TextStyle(
                  font: pw.Font.ttf(calibriBold),
                  fontSize: letterSize,
                ),
              ),
              pw.TextSpan(
                baseline: baselina,
                text:
                    ', fecha esta última de terminación de los servicios por la causa del Art. 159 Inciso N° 5, “CONCLUSION DEL TRABAJO O SERVICIO QUE DIÓ ORIGEN AL CONTRATO”.',
                style: pw.TextStyle(
                  font: pw.Font.ttf(calibri),
                  fontSize: letterSize,
                ),
              ),
            ],
          ),
        ),
      ),
      pw.Padding(
        padding: const pw.EdgeInsets.only(top: 12),
        child: pw.RichText(
          textAlign: pw.TextAlign.justify,
          text: pw.TextSpan(
            baseline: baselina,
            text: 'Segundo: ',
            style: pw.TextStyle(
              font: pw.Font.ttf(calibriBold),
              fontSize: letterSize,
            ),
            children: [
              pw.TextSpan(
                baseline: baselina,
                text: 'Don(a) ',
                style: pw.TextStyle(
                  font: pw.Font.ttf(calibri),
                  fontSize: letterSize,
                ),
              ),
              pw.TextSpan(
                baseline: baselina,
                text:
                    '${widget.worker.name!.toUpperCase()} ${widget.worker.lastName!.toUpperCase()}',
                style: pw.TextStyle(
                  font: pw.Font.ttf(calibriBold),
                  fontSize: letterSize,
                ),
              ),
              pw.TextSpan(
                baseline: baselina,
                text:
                    ', declara recibir en este acto a su entera satisfacción, de parte de ${empresa['nombreempresa']}, las sumas que a continuación se indican:',
                style: pw.TextStyle(
                  font: pw.Font.ttf(calibri),
                  fontSize: letterSize,
                ),
              ),
            ],
          ),
        ),
      ),
      pw.Padding(
        padding: const pw.EdgeInsets.only(top: 12),
        child: pw.RichText(
          textAlign: pw.TextAlign.justify,
          text: pw.TextSpan(
            baseline: baselina,
            text: 'Vacaciones proporcionales: \$${_vacationsController.text}',
            style: pw.TextStyle(
              font: pw.Font.ttf(calibriBold),
              fontSize: letterSize,
            ),
          ),
        ),
      ),
      pw.Padding(
        padding: const pw.EdgeInsets.only(top: 0),
        child: pw.RichText(
          textAlign: pw.TextAlign.justify,
          text: pw.TextSpan(
            baseline: baselina,
            text: 'Total: \$${_totalController.text}',
            style: pw.TextStyle(
              font: pw.Font.ttf(calibriBold),
              fontSize: letterSize,
            ),
          ),
        ),
      ),
      pw.Padding(
        padding: const pw.EdgeInsets.only(top: 12),
        child: pw.RichText(
          textAlign: pw.TextAlign.justify,
          text: pw.TextSpan(
            baseline: baselina,
            text: 'Tercero: ',
            style: pw.TextStyle(
              font: pw.Font.ttf(calibriBold),
              fontSize: letterSize,
            ),
            children: [
              pw.TextSpan(
                baseline: baselina,
                text: 'Don(a) ',
                style: pw.TextStyle(
                  font: pw.Font.ttf(calibri),
                  fontSize: letterSize,
                ),
              ),
              pw.TextSpan(
                baseline: baselina,
                text:
                    '${widget.worker.name!.toUpperCase()} ${widget.worker.lastName!.toUpperCase()}',
                style: pw.TextStyle(
                  font: pw.Font.ttf(calibriBold),
                  fontSize: letterSize,
                ),
              ),
              pw.TextSpan(
                baseline: baselina,
                text:
                    ', deja constancia que durante el tiempo que prestó servicios a “${empresa['nombreempresa']}”; recibió oportunamente el total de las remuneraciones, beneficios y demás prestaciones convenidas de acuerdo a su contrato de trabajo, clase de trabajo ejecutado y disposiciones legales pertinentes, y que en tal virtud el empleador nada le adeuda por tales conceptos, ni por horas extraordinarias, asignación familiar, feriado, indemnización por años de servicios, imposiciones previsionales, así como por ningún otro concepto, ya sea legal o contractual, derivado de la prestación de sus servicios, de su contrato de trabajo o de la terminación del mismo. En consecuencia, declara que no tiene reclamo alguno que formular en contra de “${empresa['nombreempresa']}”; renunciando a todas las acciones que pudieran emanar del contrato que los vinculó.',
                style: pw.TextStyle(
                  font: pw.Font.ttf(calibri),
                  fontSize: letterSize,
                ),
              ),
            ],
          ),
        ),
      ),
      pw.Padding(
        padding: const pw.EdgeInsets.only(top: 12),
        child: pw.RichText(
          textAlign: pw.TextAlign.justify,
          text: pw.TextSpan(
            baseline: baselina,
            text: 'Cuarto: ',
            style: pw.TextStyle(
              font: pw.Font.ttf(calibriBold),
              fontSize: letterSize,
            ),
            children: [
              pw.TextSpan(
                baseline: baselina,
                text:
                    'Se deja constancia de acuerdo a la ley N.º 21329 el trabajador no está afecto a la retención por pensión alimenticia.',
                style: pw.TextStyle(
                  font: pw.Font.ttf(calibri),
                  fontSize: letterSize,
                ),
              ),
            ],
          ),
        ),
      ),
      pw.Padding(
        padding: const pw.EdgeInsets.only(top: 12),
        child: pw.RichText(
          textAlign: pw.TextAlign.justify,
          text: pw.TextSpan(
            baseline: baselina,
            text:
                'Para constancia firman las partes el presente FINIQUITO en dos ejemplares, quedando uno de ellos en poder del empleador y el otro en poder del trabajador.',
            style: pw.TextStyle(
              font: pw.Font.ttf(calibri),
              fontSize: letterSize,
            ),
          ),
        ),
      ),
      pw.SizedBox(height: 100),
      pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            mainAxisAlignment: pw.MainAxisAlignment.start,
            children: [
              pw.Text(
                '_______________________________',
                style: pw.TextStyle(
                  font: pw.Font.ttf(calibriBold),
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                '${empresa['nombreempresa']}',
                style: pw.TextStyle(
                  font: pw.Font.ttf(calibriBold),
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              pw.Text(
                'RUT N°: ${empresa['rut']}',
                style: pw.TextStyle(
                  font: pw.Font.ttf(calibriBold),
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              pw.Text(
                'EMPLEADOR',
                style: pw.TextStyle(
                  font: pw.Font.ttf(calibriBold),
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            mainAxisAlignment: pw.MainAxisAlignment.start,
            children: [
              pw.Text(
                '_______________________________',
                style: pw.TextStyle(
                  font: pw.Font.ttf(calibriBold),
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                '${widget.worker.name!.toUpperCase()} ${widget.worker.lastName!.toUpperCase()}',
                style: pw.TextStyle(
                  font: pw.Font.ttf(calibriBold),
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              pw.Text(
                'RUT N°: ${widget.worker.rut}',
                style: pw.TextStyle(
                  font: pw.Font.ttf(calibriBold),
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              pw.Text(
                'TRABAJADOR',
                style: pw.TextStyle(
                  font: pw.Font.ttf(calibriBold),
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    ];
  }
}

// ── Modal Header ──────────────────────────────────────────────────────────
class _DeleteWorkerSheet extends StatelessWidget {
  const _DeleteWorkerSheet({
    required this.worker,
    required this.onConfirm,
  });

  final WorkerModel worker;
  final Future<void> Function() onConfirm;

  @override
  Widget build(BuildContext context) {
    return AppModalBody(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SheetInfoBanner(
            icon: Icons.warning_amber_rounded,
            title: 'Esta accion no se puede deshacer',
            message:
                'Se eliminaran los datos del trabajador y las imagenes asociadas al carnet.',
          ),
          const SizedBox(height: 18),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF1F0),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFFFD7D4)),
            ),
            child: const Text(
              'Confirma solo si estas seguro de continuar con la eliminacion.',
              style: TextStyle(
                color: Color(0xFF8D2A20),
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _SheetActionButton(
                  label: 'Cancelar',
                  icon: Icons.close_rounded,
                  onPressed: () => Get.back(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _DangerActionButton(
                  label: 'Eliminar',
                  icon: Icons.delete_outline_rounded,
                  onPressed: () async => onConfirm(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SettlementSheet extends StatelessWidget {
  const _SettlementSheet({
    required this.worker,
    required this.formKey,
    required this.exitController,
    required this.vacationsController,
    required this.totalController,
    required this.onPickExitDate,
    required this.onPrint,
  });

  final WorkerModel worker;
  final GlobalKey<FormState> formKey;
  final TextEditingController exitController;
  final TextEditingController vacationsController;
  final TextEditingController totalController;
  final Future<void> Function() onPickExitDate;
  final VoidCallback onPrint;

  @override
  Widget build(BuildContext context) {
    return AppModalBody(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SheetInfoBanner(
            icon: Icons.event_note_outlined,
            title: 'Datos de termino',
            message:
                'Completa fecha de egreso, vacaciones y total para generar el finiquito.',
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: Colors.blueGrey.shade50),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Form(
              key: formKey,
              child: Column(
                children: [
                  InputTextField(
                    teclado: TextInputType.none,
                    readOnly: true,
                    textController: exitController,
                    hint: 'Fecha de egreso',
                    onTap: onPickExitDate,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor ingrese fecha de egreso';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),
                  InputTextField(
                    teclado: TextInputType.number,
                    textController: vacationsController,
                    formater: FilteringTextInputFormatter.digitsOnly,
                    hint: 'Vacaciones proporcionales',
                    money: true,
                    prefix: '\$',
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor ingrese un monto';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),
                  InputTextField(
                    teclado: TextInputType.number,
                    textController: totalController,
                    formater: FilteringTextInputFormatter.digitsOnly,
                    hint: 'Total',
                    money: true,
                    prefix: '\$',
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor ingrese un monto';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _SheetActionButton(
                  label: 'Cancelar',
                  icon: Icons.close_rounded,
                  onPressed: () => Get.back(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SheetActionButton(
                  label: 'Imprimir',
                  icon: Icons.local_print_shop_outlined,
                  isPrimary: true,
                  onPressed: onPrint,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CarnetSheet extends StatelessWidget {
  const _CarnetSheet({
    required this.worker,
  });

  final WorkerModel worker;

  @override
  Widget build(BuildContext context) {
    // Sin alto forzado: el modal mide lo que mide el contenido. Antes se
    // estiraba al alto disponible y, con las dos caras del carnet lado a lado,
    // quedaba medio modal en blanco.
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SheetInfoBanner(
            icon: Icons.photo_camera_outlined,
            title: 'Gestion de imagenes',
            message:
                'Aqui puedes revisar y actualizar las fotos frontal y trasera del carnet.',
          ),
          const SizedBox(height: 14),
          Flexible(
            child: Container(
              width: double.infinity,
              decoration: appCardDecoration(),
              clipBehavior: Clip.antiAlias,
              // El pie (Cerrar + Imprimir) lo arma PicturesPage, porque
              // imprimir depende de su estado interno de subida.
              child: PicturesPage(
                worker: worker,
                onClose: () => Get.back(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DocumentsSheet extends StatefulWidget {
  const _DocumentsSheet({
    required this.worker,
    required this.onPrint,
  });

  final WorkerModel worker;
  final Future<void> Function(List<String> selections) onPrint;

  @override
  State<_DocumentsSheet> createState() => _DocumentsSheetState();
}

class _DocumentsSheetState extends State<_DocumentsSheet> {
  final List<String> _selectedDocuments = [];

  List<String> get _availableDocuments => [
        'Contrato',
        'Derecho a saber',
        'EPP',
        'Registro',
        'EPP + Registro',
        if ((widget.worker.imageFront ?? '').isNotEmpty) 'Carnet',
      ];

  void _onDocumentSelected(String document, bool isSelected) {
    setState(() {
      if (isSelected) {
        if (!_selectedDocuments.contains(document)) {
          _selectedDocuments.add(document);
        }
      } else {
        _selectedDocuments.remove(document);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppModalBody(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SheetInfoBanner(
            icon: Icons.tips_and_updates_outlined,
            title: 'Impresion rapida',
            message:
                'Selecciona uno o mas documentos para imprimirlos en un solo flujo.',
          ),
          const SizedBox(height: 18),
          Text(
            'Documentos disponibles',
            style: TextStyle(
              color: Colors.blueGrey.shade900,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Puedes combinar opciones segun lo que necesites generar para este trabajador.',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 12.5,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: Colors.blueGrey.shade50),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: GroupButton<String>(
              isRadio: false,
              buttons: _availableDocuments,
              onSelected: (value, index, isSelected) {
                _onDocumentSelected(value, isSelected);
              },
              options: GroupButtonOptions(
                groupingType: GroupingType.wrap,
                mainGroupAlignment: MainGroupAlignment.start,
                crossGroupAlignment: CrossGroupAlignment.start,
                spacing: 10,
                runSpacing: 10,
                buttonHeight: 46,
                elevation: 0,
                borderRadius: const BorderRadius.all(
                  Radius.circular(14),
                ),
                textPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                selectedColor: primario,
                unselectedColor: Colors.white,
                selectedBorderColor: primario,
                unselectedBorderColor: Colors.blueGrey.shade100,
                selectedTextStyle: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
                unselectedTextStyle: TextStyle(
                  color: Colors.blueGrey.shade700,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: _selectedDocuments.isEmpty
                ? const _EmptySelectionState()
                : Wrap(
                    key: const ValueKey('selected-documents'),
                    spacing: 8,
                    runSpacing: 8,
                    children: _selectedDocuments
                        .map(
                          (document) => _SelectedDocumentChip(label: document),
                        )
                        .toList(),
                  ),
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              Expanded(
                child: _SheetActionButton(
                  label: 'Cancelar',
                  icon: Icons.close_rounded,
                  onPressed: () => Get.back(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SheetActionButton(
                  label: 'Imprimir',
                  icon: Icons.local_print_shop_outlined,
                  isPrimary: true,
                  onPressed: _selectedDocuments.isEmpty
                      ? null
                      : () async {
                          await widget.onPrint(
                            List<String>.of(_selectedDocuments),
                          );
                        },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SheetInfoBanner extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _SheetInfoBanner({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: primario.withOpacity(0.12),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: primario.withOpacity(0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: primario, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.blueGrey.shade900,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: TextStyle(
                    color: Colors.blueGrey.shade600,
                    fontSize: 12.5,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptySelectionState extends StatelessWidget {
  const _EmptySelectionState();

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('empty-selection'),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.blueGrey.shade50,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.checklist_rtl_rounded,
            size: 18,
            color: AppColors.iconMuted,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Aun no seleccionas documentos para imprimir.',
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

class _SelectedDocumentChip extends StatelessWidget {
  final String label;

  const _SelectedDocumentChip({
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: primario.withOpacity(0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: primario.withOpacity(0.18),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_rounded, size: 16, color: primario),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: Colors.blueGrey.shade800,
              fontWeight: FontWeight.w600,
              fontSize: 12.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _DangerActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;

  const _DangerActionButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final isEnabled = onPressed != null;

    return Opacity(
      opacity: isEnabled ? 1 : 0.8,
      child: Material(
        color: isEnabled ? const Color(0xFFD64545) : const Color(0xFFD64545),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFD64545).withOpacity(0.28),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 18, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
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

class _SheetActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool isPrimary;

  const _SheetActionButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    final isEnabled = onPressed != null;
    final backgroundColor = isPrimary
        ? (isEnabled ? primario : primario.withOpacity(0.35))
        : Colors.white;
    final foregroundColor = isPrimary
        ? Colors.white
        : (isEnabled ? Colors.blueGrey.shade800 : Colors.blueGrey.shade400);

    return Opacity(
      opacity: isEnabled ? 1 : 0.8,
      child: Material(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color:
                    isPrimary ? Colors.transparent : Colors.blueGrey.shade100,
              ),
              boxShadow: isPrimary
                  ? [
                      BoxShadow(
                        color: primario.withOpacity(0.28),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 18, color: foregroundColor),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    color: foregroundColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
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

class _ModalHeader extends StatelessWidget {
  final WorkerModel worker;
  final VoidCallback onDelete;
  final VoidCallback onEdit;
  final VoidCallback onClose;
  final bool showGrabber;

  const _ModalHeader({
    required this.worker,
    required this.onDelete,
    required this.onEdit,
    required this.onClose,
    required this.showGrabber,
  });

  @override
  Widget build(BuildContext context) {
    final name = (worker.name ?? '').toUpperCase();
    final lastName = (worker.lastName ?? '').toUpperCase();
    final nameParts = name.trim().split(' ');
    final lastParts = lastName.trim().split(' ');
    final initials =
        '${nameParts.isNotEmpty && nameParts[0].isNotEmpty ? nameParts[0][0] : ''}${lastParts.isNotEmpty && lastParts[0].isNotEmpty ? lastParts[0][0] : ''}';
    final isActive = worker.activo == true;

    // Sin borderRadius a proposito: redondea el ClipRRect de showAppModal. Si
    // vuelve a traer radio propio, reaparece el fleco blanco en la curva.
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blueGrey.shade900, Colors.blueGrey.shade700],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          // Ghost icon watermark
          Positioned(
            right: -100,
            bottom: -50,
            child: Icon(Icons.person_rounded,
                size: 270, color: Colors.white.withOpacity(0.05)),
          ),
          // Cerrar, anclado a la esquina superior derecha. Va suelto y no en
          // la columna de acciones: es la salida del modal, no una accion
          // sobre el trabajador.
          // Editar y eliminar anclados abajo a la derecha del header. Van
          // sueltos en el Stack y no dentro de la fila del avatar: ahi
          // quedaban centrados con el, y su sitio es la esquina.
          Positioned(
            right: 14,
            bottom: 10,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: 'Editar',
                  icon: Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.edit_rounded,
                        color: Colors.white, size: 18),
                  ),
                  onPressed: onEdit,
                ),
                IconButton(
                  tooltip: 'Eliminar',
                  icon: Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.delete_outline_rounded,
                        color: Colors.redAccent, size: 18),
                  ),
                  onPressed: onDelete,
                ),
              ],
            ),
          ),
          Positioned(
            right: 14,
            top: 14,
            child: IconButton(
              tooltip: 'Cerrar',
              onPressed: onClose,
              icon: const Icon(Icons.close_rounded,
                  color: Colors.white, size: 22),
              splashRadius: 20,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 26),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // El tirador solo tiene sentido cuando el modal es una hoja
                // que se arrastra; en el dialogo centrado sobra.
                if (showGrabber) ...[
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ] else
                  const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Avatar
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.white.withOpacity(0.15),
                      child: Text(
                        initials.isNotEmpty ? initials : '?',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    // Name + rut + status
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$name $lastName',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 19,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            worker.rut ?? '',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.65),
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            // Esquinas apenas suavizadas y sin borde: la
                            // pastilla con radio 20 y contorno competia con el
                            // nombre que tiene al lado.
                            decoration: BoxDecoration(
                              color: isActive
                                  ? Colors.green.withOpacity(0.25)
                                  : Colors.white.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 7,
                                  height: 7,
                                  decoration: BoxDecoration(
                                    color: isActive
                                        ? Colors.green.shade300
                                        : Colors.grey.shade400,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  isActive ? 'Activo' : 'Inactivo',
                                  style: TextStyle(
                                    color: isActive
                                        ? Colors.green.shade200
                                        : Colors.white60,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Info Card (grouped section) ───────────────────────────────────────────
class _InfoCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<_InfoItem> items;

  const _InfoCard({
    required this.title,
    required this.icon,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: appCardDecoration(radius: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section title
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 16,
                  decoration: BoxDecoration(
                    color: primario,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(icon, size: 16, color: primario),
                const SizedBox(width: 6),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueGrey.shade700,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF0F2F5)),
          // Rows
          ...items.asMap().entries.map((entry) {
            final i = entry.key;
            final item = entry.value;
            return Column(
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: Row(
                    children: [
                      Icon(item.icon, size: 16, color: AppColors.iconMuted),
                      const SizedBox(width: 10),
                      Text(
                        item.label,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          item.value,
                          textAlign: TextAlign.end,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textStrong,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (i < items.length - 1)
                  Divider(
                    height: 1,
                    color: Colors.grey.shade100,
                    indent: 40,
                  ),
              ],
            );
          }),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

// ── Info Item data class ──────────────────────────────────────────────────
class _InfoItem {
  final IconData icon;
  final String label;
  final String value;
  const _InfoItem(this.icon, this.label, this.value);
}
