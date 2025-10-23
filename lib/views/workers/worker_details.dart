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
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:responsive_grid_list/responsive_grid_list.dart';
import 'package:rut_utils/rut_utils.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton.extended(
            heroTag: null,
            onPressed: () {
              showCupertinoModalBottomSheet(
                context: context,
                builder: (context) => Container(
                  constraints: const BoxConstraints(maxHeight: 480),
                  child: Scaffold(
                    appBar: AppBar(
                      automaticallyImplyLeading: false,
                      toolbarHeight: 70,
                      centerTitle: true,
                      title: Text(
                        'FINIQUITO ${widget.worker.name!.toUpperCase()} ${widget.worker.lastName!.toUpperCase()}',
                        maxLines: 3,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    body: Form(
                      key: _formKey, // Asumiendo que _formKey es accesible
                      child: ResponsiveGridList(
                        minItemsPerRow: 1,
                        maxItemsPerRow: 3,
                        horizontalGridMargin: 25,
                        verticalGridMargin: 25,
                        minItemWidth: 250,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: InputTextField(
                              teclado: TextInputType.none,
                              textController:
                                  _exitController, // Asumiendo que _exitController es accesible
                              hint: 'Fecha de Egreso',
                              formater:
                                  RutFormatter(), // El formater es irrelevante aquí ya que el teclado es 'none'
                              onTap: () async {
                                // 1. Determinar la fecha inicial para el calendario
                                DateTime initialDate;
                                try {
                                  // Intentar parsear el valor actual (asumiendo formato 'es')
                                  initialDate = DateFormat.yMMMMd('es')
                                      .parse(_exitController.text);
                                } catch (_) {
                                  initialDate = DateTime
                                      .now(); // Usar la fecha actual si falla
                                }

                                // 2. 🚀 Usar showCalendarDatePicker2Dialog 🚀
                                final datePicked =
                                    await showCalendarDatePicker2Dialog(
                                  context: context,
                                  config:
                                      CalendarDatePicker2WithActionButtonsConfig(
                                    calendarType:
                                        CalendarDatePicker2Type.single,
                                    selectedDayHighlightColor: primario,
                                    firstDate: DateTime(1950),
                                    lastDate: DateTime
                                        .now(), // No permitir fechas futuras
                                    currentDate: DateTime.now(),
                                  ),
                                  dialogSize: const Size(325, 400),
                                  value: _exitController.text.isNotEmpty
                                      ? [
                                          DateFormat.yMMMMd('es')
                                              .parse(_exitController.text)
                                        ]
                                      : [DateTime.now()],
                                );
                                // ----------------------------------------------------

                                if (datePicked != null &&
                                    datePicked.isNotEmpty &&
                                    datePicked.first != null) {
                                  // 3. Actualizar el controlador con el formato español
                                  setState(() {
                                    _exitController.text =
                                        DateFormat.yMMMMd('es')
                                            .format(datePicked.first!)
                                            .toString();
                                  });
                                }
                              },
                              validator: (value) {
                                if (value == '') {
                                  return 'Por favor ingrese fecha de ingreso';
                                }
                                return null;
                              },
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 0),
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: InputTextField(
                                teclado: TextInputType.number,
                                textController:
                                    _vacationsController, // Asumiendo que es accesible
                                formater:
                                    FilteringTextInputFormatter.digitsOnly,
                                hint: 'Vacaciones proporcionales',
                                money: true,
                                prefix: '\$',
                                validator: (value) {
                                  if (value!.isEmpty) {
                                    return 'Por favor ingrese un monto';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 0),
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: InputTextField(
                                teclado: TextInputType.number,
                                textController:
                                    _totalController, // Asumiendo que es accesible
                                formater:
                                    FilteringTextInputFormatter.digitsOnly,
                                hint: 'Total',
                                money: true,
                                prefix: '\$',
                                validator: (value) {
                                  if (value!.isEmpty) {
                                    return 'Por favor ingrese un monto';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 5.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                CustomButton(
                                  funcion: () {
                                    Get.back();
                                  },
                                  texto: 'Cancelar',
                                  cancelar: true,
                                ),
                                CustomButton(
                                  funcion: () {
                                    if (_formKey.currentState!.validate()) {
                                      _formKey.currentState!.save();
                                      printingEnd(); // Asumiendo que printingEnd es accesible y existe
                                      Get.back();
                                    }
                                  },
                                  texto: 'Imprimir',
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
            },
            label: const Text('Finiquito'),
            icon: const Icon(Icons.file_copy, size: 10),
          ),
          const SizedBox(
            width: 10,
          ),
          FloatingActionButton.extended(
            heroTag: null,
            onPressed: () {
              List<String> seleccionados = [];
              showCupertinoModalBottomSheet(
                context: context,
                builder: (context) => Container(
                  constraints: const BoxConstraints(maxHeight: 300),
                  child: Scaffold(
                    appBar: AppBar(
                      automaticallyImplyLeading: false,
                      toolbarHeight: 70,
                      centerTitle: true,
                      title: Text(
                        'DOCUMENTOS ${widget.worker.name!.toUpperCase()} ${widget.worker.lastName!.toUpperCase()}',
                        maxLines: 3,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    body: Padding(
                      padding: const EdgeInsets.only(top: 5.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          GroupButton(
                            options: const GroupButtonOptions(
                                borderRadius:
                                    BorderRadius.all(Radius.circular(10))),
                            isRadio: false,
                            onSelected: (buttons, index, isSelected) => {
                              if (isSelected)
                                {seleccionados.add(buttons)}
                              else
                                {seleccionados.remove(buttons)},
                            },
                            buttons: [
                              "Contrato",
                              "Derecho a saber",
                              "EPP",
                              "Registro",
                              "EPP + Registro",
                              if (widget.worker.imageFront != '') "Carnet",
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              CustomButton(
                                funcion: () {
                                  Get.back();
                                },
                                texto: 'Cancelar',
                                cancelar: true,
                              ),
                              CustomButton(
                                funcion: () {
                                  Get.back();
                                  printing(seleccionados);
                                },
                                texto: 'Imprimir',
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
            label: const Text('Documentos'),
            icon: const Icon(Icons.local_print_shop, size: 10),
          ),
          const SizedBox(
            width: 10,
          ),
          FloatingActionButton.extended(
            heroTag: null,
            onPressed: () {
              showCupertinoModalBottomSheet(
                context: context,
                builder: (context) => Container(
                  constraints: const BoxConstraints(maxHeight: 600),
                  child: PicturesPage(
                    worker: widget.worker,
                  ),
                ),
              );
            },
            label: const Text('Carnet'),
            icon: const Icon(Icons.picture_in_picture, size: 10),
          ),
        ],
      ),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        title: Text(
          '${widget.worker.name!.toUpperCase()} ${widget.worker.lastName!.toUpperCase()}',
          style: const TextStyle(color: Colors.black),
        ),
        leading: IconButton(
            onPressed: () {
              showCupertinoModalBottomSheet(
                context: context,
                builder: (context) => Container(
                  constraints: const BoxConstraints(maxHeight: 150),
                  child: Scaffold(
                    appBar: AppBar(
                      automaticallyImplyLeading: false,
                      toolbarHeight: 70,
                      centerTitle: true,
                      title: Text(
                        '¿Eliminar ${widget.worker.name!.toUpperCase()} ${widget.worker.lastName!.toUpperCase()}?',
                        maxLines: 3,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    body: Padding(
                      padding: const EdgeInsets.only(top: 5.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          CustomButton(
                            funcion: () {
                              Get.back();
                            },
                            texto: 'Cancelar',
                            cancelar: true,
                          ),
                          CustomButton(
                              funcion: () {
                                const path = 'WorkersIdImages/';

                                try {
                                  FirebaseStorage.instance
                                      .ref(path)
                                      .child('${widget.worker.rut}_front')
                                      .delete();
                                  FirebaseStorage.instance
                                      .ref(path)
                                      .child('${widget.worker.rut}_back')
                                      .delete();
                                  FirebaseFirestore.instance
                                      .collection('Trabajadores')
                                      .doc(widget.worker.id)
                                      .delete();
                                  Get.back();
                                  Get.back();
                                  AnimatedSnackBar.material(
                                    'Trabajador eliminado con éxito',
                                    mobileSnackBarPosition:
                                        MobileSnackBarPosition.top,
                                    desktopSnackBarPosition:
                                        DesktopSnackBarPosition.bottomRight,
                                    type: AnimatedSnackBarType.success,
                                  ).show(context);
                                } catch (e) {}
                              },
                              texto: 'Confirmar',
                              cancelar: false)
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
            icon: const Icon(
              Icons.delete,
              color: Colors.black,
            )),
        actions: [
          IconButton(
              onPressed: () {
                showCupertinoModalBottomSheet(
                  context: context,
                  builder: (context) => Container(
                    constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height - 100),
                    child: EditWorker(
                      worker: widget.worker,
                    ),
                  ),
                );
              },
              icon: const Icon(
                Icons.edit_document,
                color: Colors.black,
              ))
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(25.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Nombres :',
                  style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 18),
                ),
                Text(
                  widget.worker.name!.toUpperCase(),
                  style: const TextStyle(
                      color: Colors.black54,
                      fontWeight: FontWeight.bold,
                      fontSize: 18),
                )
              ],
            ),
            const SizedBox(
              height: 5,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Apellidos :',
                  style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 18),
                ),
                Text(
                  widget.worker.lastName!.toUpperCase(),
                  style: const TextStyle(
                      color: Colors.black54,
                      fontWeight: FontWeight.bold,
                      fontSize: 18),
                )
              ],
            ),
            const SizedBox(
              height: 5,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Rut :',
                  style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 18),
                ),
                Text(
                  widget.worker.rut!,
                  style: const TextStyle(
                      color: Colors.black54,
                      fontWeight: FontWeight.bold,
                      fontSize: 18),
                )
              ],
            ),
            const SizedBox(
              height: 5,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Correo :',
                  style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 18),
                ),
                Text(
                  widget.worker.email?.toUpperCase() ?? "",
                  style: const TextStyle(
                      color: Colors.black54,
                      fontWeight: FontWeight.bold,
                      fontSize: 18),
                )
              ],
            ),
            const SizedBox(
              height: 5,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Nacionalidad :',
                  style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 18),
                ),
                Text(
                  widget.worker.nacionality!.toUpperCase(),
                  style: const TextStyle(
                      color: Colors.black54,
                      fontWeight: FontWeight.bold,
                      fontSize: 18),
                )
              ],
            ),
            const SizedBox(
              height: 5,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Estado civil :',
                  style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 18),
                ),
                Text(
                  widget.worker.civilState!.toUpperCase(),
                  style: const TextStyle(
                      color: Colors.black54,
                      fontWeight: FontWeight.bold,
                      fontSize: 18),
                )
              ],
            ),
            const SizedBox(
              height: 5,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Fecha de nacimiento :',
                  style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 18),
                ),
                Text(
                  widget.worker.birth!.toUpperCase(),
                  style: const TextStyle(
                      color: Colors.black54,
                      fontWeight: FontWeight.bold,
                      fontSize: 18),
                )
              ],
            ),
            const SizedBox(
              height: 5,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Dirección :',
                  style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 18),
                ),
                SizedBox(
                  width: MediaQuery.of(context).size.width - 130,
                  child: Text(
                    widget.worker.adress!.toUpperCase(),
                    textAlign: TextAlign.end,
                    style: const TextStyle(
                        color: Colors.black54,
                        fontWeight: FontWeight.bold,
                        overflow: TextOverflow.fade,
                        fontSize: 18),
                  ),
                )
              ],
            ),
            const SizedBox(
              height: 5,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Comuna :',
                  style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 18),
                ),
                Text(
                  widget.worker.commune!.toUpperCase(),
                  style: const TextStyle(
                      color: Colors.black54,
                      fontWeight: FontWeight.bold,
                      fontSize: 18),
                )
              ],
            ),
            const SizedBox(
              height: 5,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Labor :',
                  style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 18),
                ),
                Text(
                  widget.worker.labor!.toUpperCase(),
                  style: const TextStyle(
                      color: Colors.black54,
                      fontWeight: FontWeight.bold,
                      fontSize: 18),
                )
              ],
            ),
            const SizedBox(
              height: 5,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Establecimiento :',
                  style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 18),
                ),
                Text(
                  widget.worker.place!.toUpperCase(),
                  style: const TextStyle(
                      color: Colors.black54,
                      fontWeight: FontWeight.bold,
                      fontSize: 18),
                )
              ],
            ),
            const SizedBox(
              height: 5,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'AFP :',
                  style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 18),
                ),
                Text(
                  widget.worker.afp!.toUpperCase(),
                  style: const TextStyle(
                      color: Colors.black54,
                      fontWeight: FontWeight.bold,
                      fontSize: 18),
                )
              ],
            ),
            const SizedBox(
              height: 5,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Prevision :',
                  style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 18),
                ),
                Text(
                  widget.worker.prevision!.toUpperCase(),
                  style: const TextStyle(
                      color: Colors.black54,
                      fontWeight: FontWeight.bold,
                      fontSize: 18),
                )
              ],
            ),
            const SizedBox(
              height: 5,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Fecha de ingreso :',
                  style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 18),
                ),
                Text(
                  widget.worker.ingress!.toUpperCase(),
                  style: const TextStyle(
                      color: Colors.black54,
                      fontWeight: FontWeight.bold,
                      fontSize: 18),
                )
              ],
            ),
            const SizedBox(
              height: 5,
            ),
          ],
        ),
      ),
    );
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
                        'AÑO ${DateTime.now().year}',
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
                            text: 'El “Empleador”',
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
                          if (widget.worker.email != null &&
                              widget.worker.email != '') ...[
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
                            text: '“trabajador”',
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
                                'El Empleador contrata al trabajador para ejecutar la labor de ',
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
                            text: '44 horas semanales.',
                            style: pw.TextStyle(
                              font: pw.Font.ttf(calibriBold),
                              fontSize: letterSize,
                            ),
                          ),
                          pw.TextSpan(
                            baseline: baselina,
                            text:
                                ' Lunes a Jueves de 8:00 a 18:00 hrs, Viernes de 8:00 a 17:00 hrs, con una hora de colación.',
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
                                'Se deja constancia que el trabajador ingresó el día ',
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
                        'AÑO ${DateTime.now().year}',
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
                        'AÑO ${DateTime.now().year}',
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
                            'Asimismo, se recuerda lo establecido en el articulo 68 de la Ley N° 16.744 donde se indica que “las empresas deberán proporcionar a sus trabajadores los equipos e implementos de protección necesarios, no pudiendo en caso alguno cobrarles su valor”.',
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
                        'AÑO ${DateTime.now().year}',
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
                            'RUT N°: ${widget.worker.rut}',
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
                      "O’Higgins Pelay Lt 2 H Pc N° 2 A, Comuna San Francisco De Mostazal",
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
                        'AÑO ${DateTime.now().year}',
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
                            'Asimismo, se recuerda lo establecido en el articulo 68 de la Ley N° 16.744 donde se indica que “las empresas deberán proporcionar a sus trabajadores los equipos e implementos de protección necesarios, no pudiendo en caso alguno cobrarles su valor”.',
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
                            'RUT N°: ${widget.worker.rut}',
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
                      "O’Higgins Pelay Lt 2 H Pc N° 2 A, Comuna San Francisco De Mostazal",
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
                    'AÑO ${DateTime.now().year}',
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
                        text: 'El “Empleador”',
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
                            ', prestó servicios a “${empresa['nombreempresa']}”, ejecutando la labor de ',
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
                            ', fecha esta última de terminación de los servicios por la causa del Art. 159 Inciso N° 5, “CONCLUSION DEL TRABAJO O SERVICIO QUE DIÓ ORIGEN AL CONTRATO”.',
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
                            ', deja constancia que durante el tiempo que prestó servicios a “”; recibió oportunamente el total de las remuneraciones, beneficios y demás prestaciones convenidas de acuerdo a su contrato de trabajo, clase de trabajo ejecutado y disposiciones legales pertinentes, y que en tal virtud el empleador nada le adeuda por tales conceptos, ni por horas extraordinarias, asignación familiar, feriado, indemnización por años de servicios, imposiciones previsionales, así como por ningún otro concepto, ya sea legal o contractual, derivado de la prestación de sus servicios, de su contrato de trabajo o de la terminación del mismo. En consecuencia, declara que no tiene reclamo alguno que formular en contra de “${empresa['nombreempresa']}”; renunciando a todas las acciones que pudieran emanar del contrato que los vinculó.',
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
          );
        },
      ),
    ); // Page

    await Printing.layoutPdf(
        onLayout: (formato) async => pdf.save(), format: PdfPageFormat.letter);
  }
}
