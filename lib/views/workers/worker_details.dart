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

import '../../customs/constants_values.dart';
import '../../customs/widgets_custom.dart';
import '../../models/worker_model.dart';
import '../pictures/pictures_page.dart';
import 'edit_worker_page.dart';

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
            color: Colors.blueGrey.shade400,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ) ??
          TextStyle(
            color: Colors.blueGrey.shade400,
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

  @override
  Widget build(BuildContext context) {
    // Envolvemos todo en Material para que los estilos de texto no se rompan
    // al no tener un Scaffold padre.
    return Material(
      color: Colors.transparent,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          clipBehavior: Clip.hardEdge,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min, // Abraza el contenido
            children: [
              // ----------------------------------------------------
              // 1. REEMPLAZO DEL APPBAR (Header personalizado)
              // ----------------------------------------------------
              // â”€â”€ HEADER BANNER â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
              _ModalHeader(
                worker: widget.worker,
                onDelete: _openDeleteWorkerSheet,
                onEdit: _openEditWorkerSheet,
              ),

              // ----------------------------------------------------
              // 2. CUERPO DEL DETALLE (Scrollable)
              // ----------------------------------------------------
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 25.0, vertical: 10.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // â”€â”€ INFO CARD â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                      _InfoCard(
                        title: 'Informaci\u00f3n personal',
                        icon: Icons.person_outline_rounded,
                        items: [
                          _InfoItem(Icons.badge_outlined, 'Nombres',
                              widget.worker.name!.toUpperCase()),
                          _InfoItem(Icons.person_outline, 'Apellidos',
                              widget.worker.lastName!.toUpperCase()),
                          _InfoItem(Icons.credit_card_outlined, 'RUT',
                              widget.worker.rut!),
                          _InfoItem(Icons.email_outlined, 'Correo',
                              widget.worker.email?.toUpperCase() ?? '\u2014'),
                          _InfoItem(Icons.flag_outlined, 'Nacionalidad',
                              widget.worker.nacionality!.toUpperCase()),
                          _InfoItem(
                              Icons.favorite_border_rounded,
                              'Estado civil',
                              widget.worker.civilState!.toUpperCase()),
                          _InfoItem(Icons.cake_outlined, 'Fecha nacimiento',
                              widget.worker.birth!.toUpperCase()),
                          _InfoItem(Icons.home_outlined, 'Direcci\u00f3n',
                              widget.worker.adress!.toUpperCase()),
                          _InfoItem(Icons.location_city_outlined, 'Comuna',
                              widget.worker.commune!.toUpperCase()),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _InfoCard(
                        title: 'Informaci\u00f3n laboral',
                        icon: Icons.work_outline_rounded,
                        items: [
                          _InfoItem(Icons.construction_outlined, 'Labor',
                              widget.worker.labor!.toUpperCase()),
                          _InfoItem(Icons.business_outlined, 'Establecimiento',
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
                      ),
                      const SizedBox(height: 14),

                      // MEJORA 4: Ultimo contrato generado
                      StreamBuilder<DocumentSnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('Trabajadores')
                            .doc(widget.worker.id)
                            .snapshots(),
                        builder: (ctx, snap) {
                          String val = '\u2014';
                          if (snap.hasData && snap.data!.exists) {
                            final data =
                                snap.data!.data() as Map<String, dynamic>?;
                            final ts = data?['ultimoContrato'];
                            if (ts is Timestamp) {
                              val = DateFormat('dd/MM/yyyy \u2013 HH:mm', 'es')
                                  .format(ts.toDate());
                            }
                          }
                          return _InfoCard(
                              title: '\u00daltimo contrato',
                              icon: Icons.calendar_today_outlined,
                              items: [
                                _InfoItem(Icons.calendar_today_outlined,
                                    '\u00daltimo contrato', val),
                              ]);
                          /* Padding(
                            padding: const EdgeInsets.only(bottom: 5.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  '\u00daltimo contrato :',
                                  style: TextStyle(
                                      color: Colors.black,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    val,
                                    textAlign: TextAlign.end,
                                    maxLines: 1,
                                    softWrap: false,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        color: Colors.black54,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18),
                                  ),
                                ),
                              ],
                            ),
                          ); */
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
                    top: 15.0, bottom: 25.0, left: 10.0, right: 10.0),
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
                        // BotÃ³n Finiquito
                        SizedBox(
                          width: buttonWidth,
                          child: CustomButton(
                            funcion: _openSettlementSheet,
                            texto: 'Finiquito',
                            icon: Icons.file_copy_outlined,
                          ),
                        ),

                        // BotÃ³n Documentos
                        SizedBox(
                          width: buttonWidth,
                          child: CustomButton(
                            funcion: _openDocumentsSheet,
                            texto: 'Documentos',
                            icon: Icons.local_print_shop_outlined,
                          ),
                        ),

                        // BotÃ³n Carnet
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
    );
  }

  double _sheetMaxWidth(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width > 980) return 920;
    return width * 0.96;
  }

  void _openEditWorkerSheet() {
    final media = MediaQuery.of(context);
    showModalBottomSheet(
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
                maxWidth: _sheetMaxWidth(context),
                maxHeight: media.size.height * 0.92,
              ),
              child: Container(
                decoration: const BoxDecoration(
                  color: Color(0xFFF4F7FA),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                clipBehavior: Clip.hardEdge,
                child: EditWorker(worker: widget.worker),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _openDeleteWorkerSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _DeleteWorkerSheet(
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

      await FirebaseFirestore.instance
          .collection('Trabajadores')
          .doc(widget.worker.id)
          .delete();

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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _DocumentsSheet(
        worker: widget.worker,
        onPrint: (selections) async {
          Get.back();
          await printing(selections);
        },
      ),
    );
  }

  void _openSettlementSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _SettlementSheet(
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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CarnetSheet(worker: widget.worker),
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
      dialogBackgroundColor: const Color(0xFFF4F7FA),
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

      var contrato = await FirebaseFirestore.instance
          .collection('Otros')
          .doc('contrato')
          .get();
      var empresa = await FirebaseFirestore.instance
          .collection('Otros')
          .doc('empresadata')
          .get();

      // Fetch the places array to find the index
      var lugaresParam = await FirebaseFirestore.instance
          .collection('Otros')
          .doc('lugares')
          .get();
      List<String> lugaresTipos = [];
      if (lugaresParam.exists && lugaresParam.data() != null) {
        var data = lugaresParam.data()!;
        if (data.containsKey('tipos')) {
          lugaresTipos = List<String>.from(data['tipos'] ?? []);
        }
      }

      // Fetch the hours configuration array
      var horasParam = await FirebaseFirestore.instance
          .collection('Otros')
          .doc('lugares_horas')
          .get();
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
          // unificar en "Lunes a Viernes" y dejar txtViernes vacÃ­o
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
            txtSabado = formatSchedule(sabVal, "SÃ¡bado");
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
          pw.Page(
            pageFormat: PdfPageFormat.letter,
            margin: const pw.EdgeInsets.symmetric(vertical: 40, horizontal: 60),
            build: (pw.Context context) {
              return pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                children: [
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
                        'AÃƒÆ’â€˜O ${DateTime.now().year}',
                        style: pw.TextStyle(
                          font: pw.Font.ttf(cambria),
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
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
                            text: ' RUT NÂ° ',
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
                            text: ' RUT NÂ° ',
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
                            text: ' correo electrÃ³nico ',
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
                                ', ambos con domicilio en Oâ€™Higgins Pelay Lt 2 H Pc NÂ° 2 A, Comuna San Francisco De Mostazal, en lo sucesivo ',
                            style: pw.TextStyle(
                              font: pw.Font.ttf(calibri),
                              fontSize: letterSize,
                            ),
                          ),
                          pw.TextSpan(
                            baseline: baselina,
                            text: 'El â€œEmpleadorÃƒÂ¢Ã¢â€šÂ¬Ã‚Â',
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
                            text: ', RUT NÂ° ',
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
                          if (widget.worker.email != null &&
                              widget.worker.email != '') ...[
                            pw.TextSpan(
                              baseline: baselina,
                              text: ', correo electrÃ³nico ',
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
                            text: 'â€œtrabajadorÃƒÂ¢Ã¢â€šÂ¬Ã‚Â',
                            style: pw.TextStyle(
                              font: pw.Font.ttf(calibriBold),
                              decoration: pw.TextDecoration.underline,
                              fontSize: letterSize,
                            ),
                          ),
                          pw.TextSpan(
                            baseline: baselina,
                            text:
                                ' se suscribe el siguiente contrato de trabajo:',
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
                            text:
                                'El Empleador contrata al trabajador para ejecutar ',
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
                                ', diarios, del monto seÃ±alado el empleador efectuara los descuentos correspondientes a las leyes sociales.',
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
                            /* La jornada de trabajo serÃ¡ de lunes a viernes de 8:00 hrs hasta las 12:00 hrs y de 13:00 a 17:00 hrs. El horario de trabajo podrÃ¡ ser modificado de acuerdo con las necesidades del empleador. El horario de trabajo serÃ¡ interrumpido durante 1 hora para colaciÃ³n, tiempo de conformidad a la ley, no se considera como parte de la jornada de trabajo. */
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
                                ' $txtLunesJueves,${txtViernes != "" ? " $txtViernes," : ""}${txtSabado != "" ? " $txtSabado," : ""} con $txtColacion de colaciÃ³n.',
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
                                'El presente contrato durarÃ¡ la faena determinada descrita anteriormente pudiendo cualquiera de las partes ponerle termino a las condiciones, las cuales establece el cÃ³digo del trabajo.',
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
                                'Se hace entrega del reglamento interno de la empresa, el trabajador toma conocimiento y se compromete a cumplir las obligaciones y prohibiciones que en Ã©l se mencionan del derecho de saber.',
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
                        text: 'SÃ©ptimo: ',
                        style: pw.TextStyle(
                          font: pw.Font.ttf(calibriBold),
                          fontSize: letterSize,
                        ),
                        children: [
                          pw.TextSpan(
                            baseline: baselina,
                            text:
                                'El trabajador se encuentra afiliado a la AFP ',
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
                            text:
                                'Se deja constancia que el trabajador ingresÃ³ el dÃ­a ',
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
                            'El presente contrato se firma en dos ejemplares, quedando uno de ellos en poder del empleador y el otro en poder del trabajador, quien declara recibirlo a su entera satisfacciÃ³n.',
                        style: pw.TextStyle(
                          font: pw.Font.ttf(calibri),
                          fontSize: letterSize,
                        ),
                      ),
                    ),
                  ),
                  pw.SizedBox(height: 50),
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
                            'RUT NÂ°: ${empresa['rut']}',
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
                            'RUT NÂ°: ${widget.worker.rut}',
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
                  pw.SizedBox(height: 15),
                  pw.Center(
                    child: pw.Text(
                      "Oâ€™Higgins Pelay Lt 2 H Pc NÂ° 2 A, Comuna San Francisco De Mostazal",
                      style: pw.TextStyle(
                          font: pw.Font.ttf(calibriBold),
                          fontSize: 10,
                          color: PdfColor.fromHex('#9B9B9B')),
                    ),
                  ),
                ],
              );
            },
          ),
        ); // Page
      }

      if (selections.contains('Derecho a saber')) {
        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.letter,
            margin: const pw.EdgeInsets.symmetric(vertical: 40, horizontal: 60),
            build: (pw.Context context) {
              return pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                children: [
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
                        'AÃƒÆ’â€˜O ${DateTime.now().year}',
                        style: pw.TextStyle(
                          font: pw.Font.ttf(cambria),
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
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
                            text: ', RUT: NÂ° ',
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
                            text: ', Ãrea de trabajo: ',
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
                        text: 'A travÃ©s de la presente, la empresa ',
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
                            text: ' RUT NÂ° ',
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
                            text: ' RUT NÂ° ',
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
                                ', declara haberme informado de los riesgos que entraÃ±an las labores que desarrollarÃ© en mi trabajo, asÃ­ como las medidas preventivas que debo tomar para hacer de esto un mÃ©todo seguro de trabajo.',
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
                                '- Utilice pisos y escaleras bien anclados y con responsabilidad.\n- Tener atenciÃ³n a las superficies de trabajo.\n- Mantener su entorno de trabajo libre de obstÃ¡culos.\n- No utilice el celular mientras camina.\n-	Cuando transite entre hileras mantenga cuidado con mangueras y ramas de podas pasadas.',
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
                                '- Aplicar mÃ©todo correcto de levantamiento de carga y de posturas correctas de trabajo, el peso mÃ¡ximo a mover es de 25 kg para hombres y 20 kg para mujeres, solicite ayuda si es necesario.\n- No trasladar mas de una escalera o banquillo por persona.',
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
                                '- Actuar conforme a los procedimientos de aplicaciÃ³n y resguardo de almacenamiento e higiene que existen para cada tipo.\n- DespuÃ©s de cada aplicaciÃ³n deberÃ¡ ducharse y usar ropa distinta.\n- Respetar los plazos de resguardo a los cuarteles.',
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
                                '- La exposiciÃ³n y/o acumulaciÃ³n de radiaciÃ³n ultravioleta de fuentes naturales o artificiales deben llevar el resguardo necesario.\n- Usar los artÃ­culos necesarios para evitar la exposiciÃ³n (lentes con protecciÃ³n uv, gorros legionarios, uso y aplicaciÃ³n de protector solar cada 2 horas si es necesario).',
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
                              'Declaro haber recibido la introducciÃ³n de seguridad laboral y entender a los riesgos a los que me expongo.',
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
                  pw.Center(
                    child: pw.Text(
                      "Oâ€™Higgins Pelay Lt 2 H Pc NÂ° 2 A, Comuna San Francisco De Mostazal",
                      style: pw.TextStyle(
                          font: pw.Font.ttf(calibriBold),
                          fontSize: 10,
                          color: PdfColor.fromHex('#9B9B9B')),
                    ),
                  ),
                ],
              );
            },
          ),
        ); // Page
      }

      if (selections.contains('EPP')) {
        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.letter,
            margin: const pw.EdgeInsets.symmetric(vertical: 40, horizontal: 60),
            build: (pw.Context context) {
              return pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                children: [
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
                        'AÃƒÆ’â€˜O ${DateTime.now().year}',
                        style: pw.TextStyle(
                          font: pw.Font.ttf(cambria),
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
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
                            'SegÃºn lo establecido en el articulo 53 del decreto supremo 594, el empleador deberÃ¡ proporcionar a sus trabajadores, libre de costo, los elementos de protecciÃ³n personal adecuados al riesgo a cubrir y el adiestramiento necesario para su correcto empleo, debiendo, ademÃ¡s, mantenerlo en perfecto estado de funcionamiento. Por su parte, el trabajador deberÃ¡ usarlos en forma permanente mientras se encuentre expuesto al riesgo.',
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
                            'Asimismo, se recuerda lo establecido en el articulo 68 de la Ley NÂ° 16.744 donde se indica que â€œlas empresas deberÃ¡n proporcionar a sus trabajadores los equipos e implementos de protecciÃ³n necesarios, no pudiendo en caso alguno cobrarles su valorÃƒÂ¢Ã¢â€šÂ¬Ã‚Â.',
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
                            'RUT NÂ°: ${widget.worker.rut}',
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
                  pw.Center(
                    child: pw.Text(
                      "Oâ€™Higgins Pelay Lt 2 H Pc NÂ° 2 A, Comuna San Francisco De Mostazal",
                      style: pw.TextStyle(
                          font: pw.Font.ttf(calibriBold),
                          fontSize: 10,
                          color: PdfColor.fromHex('#9B9B9B')),
                    ),
                  ),
                ],
              );
            },
          ),
        ); // Page
      }

      if (selections.contains('Registro')) {
        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.letter,
            margin: const pw.EdgeInsets.symmetric(vertical: 40, horizontal: 60),
            build: (pw.Context context) {
              return pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                children: [
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
                        'AÃƒÆ’â€˜O ${DateTime.now().year}',
                        style: pw.TextStyle(
                          font: pw.Font.ttf(cambria),
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
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
                            text: ', RUT: NÂ° ',
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
                            text: ' RUT NÂ° ',
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
                            text: ' RUT NÂ° ',
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
                                ', del cual me comprometo a tomar conocimiento en su totalidad no pudiendo alegar desconocimiento de su texto a su entrega, reconociendo ademÃ¡s en forma expresa que este reglamento interno es parte integrante del contrato de trabajo que mantengo vigente con la empresa.',
                            style: pw.TextStyle(
                              font: pw.Font.ttf(calibri),
                              fontSize: letterSize,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  pw.SizedBox(height: 400),
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
                            'RUT NÂ°: ${widget.worker.rut}',
                            style: pw.TextStyle(
                              font: pw.Font.ttf(calibriBold),
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          pw.Text(
                            'FIRMA TRABAJADOR',
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
                  pw.Center(
                    child: pw.Text(
                      "Oâ€™Higgins Pelay Lt 2 H Pc NÂ° 2 A, Comuna San Francisco De Mostazal",
                      style: pw.TextStyle(
                          font: pw.Font.ttf(calibriBold),
                          fontSize: 10,
                          color: PdfColor.fromHex('#9B9B9B')),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      }

      if (selections.contains('EPP + Registro')) {
        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.letter,
            margin: const pw.EdgeInsets.symmetric(vertical: 40, horizontal: 60),
            build: (pw.Context context) {
              return pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                children: [
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
                        'AÃƒÆ’â€˜O ${DateTime.now().year}',
                        style: pw.TextStyle(
                          font: pw.Font.ttf(cambria),
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
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
                            'SegÃºn lo establecido en el articulo 53 del decreto supremo 594, el empleador deberÃ¡ proporcionar a sus trabajadores, libre de costo, los elementos de protecciÃ³n personal adecuados al riesgo a cubrir y el adiestramiento necesario para su correcto empleo, debiendo, ademÃ¡s, mantenerlo en perfecto estado de funcionamiento. Por su parte, el trabajador deberÃ¡ usarlos en forma permanente mientras se encuentre expuesto al riesgo.',
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
                            'Asimismo, se recuerda lo establecido en el articulo 68 de la Ley NÂ° 16.744 donde se indica que â€œlas empresas deberÃ¡n proporcionar a sus trabajadores los equipos e implementos de protecciÃ³n necesarios, no pudiendo en caso alguno cobrarles su valorÃƒÂ¢Ã¢â€šÂ¬Ã‚Â.',
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
                  pw.SizedBox(height: 20),
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
                            text: ', RUT: NÂ° ',
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
                            text: ' RUT NÂ° ',
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
                            text: ' RUT NÂ° ',
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
                                ', del cual me comprometo a tomar conocimiento en su totalidad no pudiendo alegar desconocimiento de su texto a su entrega, reconociendo ademÃ¡s en forma expresa que este reglamento interno es parte integrante del contrato de trabajo que mantengo vigente con la empresa.',
                            style: pw.TextStyle(
                              font: pw.Font.ttf(calibri),
                              fontSize: letterSize,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  pw.SizedBox(height: 45),
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
                            'RUT NÂ°: ${widget.worker.rut}',
                            style: pw.TextStyle(
                              font: pw.Font.ttf(calibriBold),
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          pw.Text(
                            'FIRMA TRABAJADOR',
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
                  pw.Center(
                    child: pw.Text(
                      "Oâ€™Higgins Pelay Lt 2 H Pc NÂ° 2 A, Comuna San Francisco De Mostazal",
                      style: pw.TextStyle(
                          font: pw.Font.ttf(calibriBold),
                          fontSize: 10,
                          color: PdfColor.fromHex('#9B9B9B')),
                    ),
                  ),
                ],
              );
            },
          ),
        ); // Page
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

      // Registrar contrato en Firestore solo si se generÃ³ un contrato
      if (selections.contains('Contrato') && widget.worker.id != null) {
        try {
          await FirebaseFirestore.instance
              .collection('Trabajadores')
              .doc(widget.worker.id)
              .update({
            'ultimoContrato': FieldValue.serverTimestamp(),
            'activo': true,
          });
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

    var empresa = await FirebaseFirestore.instance
        .collection('Otros')
        .doc('empresadata')
        .get();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.letter,
        margin: const pw.EdgeInsets.symmetric(vertical: 40, horizontal: 60),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
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
                    'AÃƒÆ’â€˜O ${DateTime.now().year}',
                    style: pw.TextStyle(
                      font: pw.Font.ttf(cambria),
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
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
                        text: ' RUT NÂ° ',
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
                        text: ' RUT NÂ° ',
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
                            ', ambos con domicilio en Oâ€™Higgins Pelay Lt 2 H Pc NÂ° 2 A, Comuna San Francisco De Mostazal, en lo sucesivo ',
                        style: pw.TextStyle(
                          font: pw.Font.ttf(calibri),
                          fontSize: letterSize,
                        ),
                      ),
                      pw.TextSpan(
                        baseline: baselina,
                        text: 'El â€œEmpleadorÃƒÂ¢Ã¢â€šÂ¬Ã‚Â',
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
                        text: ', RUT NÂ° ',
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
                        text: ', RUT NÂ° ',
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
                            ', prestÃ³ servicios a â€œ${empresa['nombreempresa']}ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â, ejecutando ',
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
                        text: ', desde el dÃ­a ',
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
                        text: ' hasta el dÃ­a ',
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
                            ', fecha esta Ãºltima de terminaciÃ³n de los servicios por la causa del Art. 159 Inciso NÂ° 5, â€œCONCLUSION DEL TRABAJO O SERVICIO QUE DIÃƒÆ’â€œ ORIGEN AL CONTRATOÃƒÂ¢Ã¢â€šÂ¬Ã‚Â.',
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
                            ', declara recibir en este acto a su entera satisfacciÃ³n, de parte de ${empresa['nombreempresa']}, las sumas que a continuaciÃ³n se indican:',
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
                        'Vacaciones proporcionales: \$${_vacationsController.text}',
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
                            'Se deja constancia de acuerdo a la ley N.Âº 21329 el trabajador no estÃ¡ afecto a la retenciÃ³n por pensiÃ³n alimenticia.',
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
                        'RUT NÂ°: ${empresa['rut']}',
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
                        'RUT NÂ°: ${widget.worker.rut}',
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
              pw.SizedBox(height: 15),
              pw.Center(
                child: pw.Text(
                  "Oâ€™Higgins Pelay Lt 2 H Pc NÂ° 2 A, Comuna San Francisco De Mostazal",
                  style: pw.TextStyle(
                      font: pw.Font.ttf(calibriBold),
                      fontSize: 10,
                      color: PdfColor.fromHex('#9B9B9B')),
                ),
              ),
            ],
          );
        },
      ),
    ); // Page

    // MEJORA 4: Registrar fecha de generaciÃ³n del contrato ANTES del await pdf
    try {
      if (widget.worker.id != null) {
        await FirebaseFirestore.instance
            .collection('Trabajadores')
            .doc(widget.worker.id)
            .update({
          'ultimoContrato': FieldValue.serverTimestamp(),
          'activo': false,
        });
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
}

// â”€â”€ Modal Header â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _DeleteWorkerSheet extends StatelessWidget {
  const _DeleteWorkerSheet({
    required this.worker,
    required this.onConfirm,
  });

  final WorkerModel worker;
  final Future<void> Function() onConfirm;

  String get _workerDisplayName {
    final name = (worker.name ?? '').toUpperCase();
    final lastName = (worker.lastName ?? '').toUpperCase();
    return '$name $lastName'.trim();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        top: false,
        child: Container(
          decoration: const BoxDecoration(
            color: Color(0xFFF4F7FA),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          clipBehavior: Clip.hardEdge,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _WorkerSheetHeroHeader(
                icon: Icons.delete_outline_rounded,
                title: 'Eliminar trabajador',
                subtitle: _workerDisplayName,
                badge: 'Accion',
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
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
              ),
            ],
          ),
        ),
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

  String get _workerDisplayName {
    final name = (worker.name ?? '').toUpperCase();
    final lastName = (worker.lastName ?? '').toUpperCase();
    return '$name $lastName'.trim();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Container(
            decoration: const BoxDecoration(
              color: Color(0xFFF4F7FA),
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            clipBehavior: Clip.hardEdge,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _WorkerSheetHeroHeader(
                  icon: Icons.file_copy_outlined,
                  title: 'Finiquito',
                  subtitle: _workerDisplayName,
                  badge: 'Documento',
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
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
                                formater:
                                    FilteringTextInputFormatter.digitsOnly,
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
                                formater:
                                    FilteringTextInputFormatter.digitsOnly,
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
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CarnetSheet extends StatelessWidget {
  const _CarnetSheet({
    required this.worker,
  });

  final WorkerModel worker;

  String get _workerDisplayName {
    final name = (worker.name ?? '').toUpperCase();
    final lastName = (worker.lastName ?? '').toUpperCase();
    return '$name $lastName'.trim();
  }

  @override
  Widget build(BuildContext context) {
    final modalHeight = (MediaQuery.of(context).size.height * 0.92)
        .clamp(560.0, 860.0)
        .toDouble();

    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: modalHeight,
          child: Container(
            decoration: const BoxDecoration(
              color: Color(0xFFF4F7FA),
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            clipBehavior: Clip.hardEdge,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _WorkerSheetHeroHeader(
                  icon: Icons.badge_outlined,
                  title: 'Carnet',
                  subtitle: _workerDisplayName,
                  badge: 'Fotos',
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _SheetInfoBanner(
                          icon: Icons.photo_camera_outlined,
                          title: 'Gestion de imagenes',
                          message:
                              'Aqui puedes revisar y actualizar las fotos frontal y trasera del carnet.',
                        ),
                        const SizedBox(height: 14),
                        Expanded(
                          child: Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(22),
                              border:
                                  Border.all(color: Colors.blueGrey.shade50),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 16,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: PicturesPage(worker: worker),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: _SheetActionButton(
                            label: 'Cerrar',
                            icon: Icons.check_rounded,
                            onPressed: () => Get.back(),
                          ),
                        ),
                      ],
                    ),
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

  String get _workerDisplayName {
    final name = (widget.worker.name ?? '').toUpperCase();
    final lastName = (widget.worker.lastName ?? '').toUpperCase();
    return '$name $lastName'.trim();
  }

  String get _selectionSummary {
    final count = _selectedDocuments.length;
    if (count == 1) return '1 seleccionado';
    return '$count seleccionados';
  }

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
    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Container(
            decoration: const BoxDecoration(
              color: Color(0xFFF4F7FA),
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            clipBehavior: Clip.hardEdge,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _WorkerSheetHeroHeader(
                  icon: Icons.description_outlined,
                  title: 'Documentos',
                  subtitle: _workerDisplayName,
                  badge: _selectionSummary,
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
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
                      Text(
                        'Puedes combinar opciones segun lo que necesites generar para este trabajador.',
                        style: TextStyle(
                          color: Colors.blueGrey.shade500,
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
                                      (document) => _SelectedDocumentChip(
                                          label: document),
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
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _WorkerSheetHeroHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String badge;

  const _WorkerSheetHeroHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        gradient: LinearGradient(
          colors: [Colors.blueGrey.shade900, Colors.blueGrey.shade700],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -18,
            top: 12,
            child: Icon(
              icon,
              size: 92,
              color: Colors.white.withOpacity(0.06),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.28),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.12),
                        ),
                      ),
                      child: Icon(icon, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            subtitle,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.72),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.14),
                        ),
                      ),
                      child: Text(
                        badge,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
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
          Icon(
            Icons.checklist_rtl_rounded,
            size: 18,
            color: Colors.blueGrey.shade400,
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

  const _ModalHeader({
    required this.worker,
    required this.onDelete,
    required this.onEdit,
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

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blueGrey.shade900, Colors.blueGrey.shade700],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
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
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 14, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Drag handle
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
                            decoration: BoxDecoration(
                              color: isActive
                                  ? Colors.green.withOpacity(0.25)
                                  : Colors.white.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isActive
                                    ? Colors.green.shade300.withOpacity(0.6)
                                    : Colors.white.withOpacity(0.2),
                              ),
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
                    // Action buttons column
                    Column(
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

// â”€â”€ Info Card (grouped section) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
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
                      Icon(item.icon,
                          size: 16, color: Colors.blueGrey.shade400),
                      const SizedBox(width: 10),
                      Text(
                        item.label,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.blueGrey.shade500,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          item.value,
                          textAlign: TextAlign.end,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Colors.blueGrey.shade800,
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

// â”€â”€ Info Item data class â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _InfoItem {
  final IconData icon;
  final String label;
  final String value;
  const _InfoItem(this.icon, this.label, this.value);
}
