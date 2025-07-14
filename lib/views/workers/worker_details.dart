// lib/views/workers/worker_details.dart
// ignore_for_file: empty_catches, unrelated_type_equality_checks, curly_braces_in_flow_control_structures, avoid_print, sized_box_for_whitespace

import 'dart:convert';
import 'dart:io';

import 'package:animated_snack_bar/animated_snack_bar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart' hide ModalBottomSheetRoute;
import 'package:flutter/services.dart';
import 'package:flutter_holo_date_picker/date_picker.dart';
import 'package:flutter_holo_date_picker/i18n/date_picker_i18n.dart';
import 'package:get/get.dart';
import 'package:group_button/group_button.dart';
import 'package:intl/intl.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter_html_to_pdf/flutter_html_to_pdf.dart';


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
  void dispose() {
    _exitController.dispose();
    _vacationsController.dispose();
    _totalController.dispose();
    super.dispose();
  }

  void _showSnackbar(String message, AnimatedSnackBarType type) {
    if (!mounted) return;
    AnimatedSnackBar.material(
      message,
      mobileSnackBarPosition: MobileSnackBarPosition.top,
      desktopSnackBarPosition: DesktopSnackBarPosition.bottomRight,
      type: type,
    ).show(context);
  }

  String _deltaToHtml(List<dynamic> delta) {
    final html = StringBuffer();
    for (var op in delta) {
      if (op is Map && op.containsKey('insert')) {
        String text = op['insert'];
        text = text.replaceAll('', '<br>'); // Handle newlines
        if (op.containsKey('attributes')) {
          final attributes = op['attributes'];
          if (attributes.containsKey('bold')) {
            html.write('<strong>$text</strong>');
          } else if (attributes.containsKey('italic')) html.write('<em>$text</em>');
          else if (attributes.containsKey('underline')) html.write('<u>$text</u>');
          else html.write(text);
        } else {
          html.write(text);
        }
      }
    }
    return html.toString();
  }

  Future<void> loadAndPrintDocument(String documentName, {Map<String, dynamic>? specificData}) async {
    try {
      final templateDoc = await FirebaseFirestore.instance.collection('templates').doc(documentName).get();

      if (!templateDoc.exists) {
        final message = 'Error: Plantilla "$documentName" no encontrada.';
        print(message);
        _showSnackbar(message, AnimatedSnackBarType.error);
        return;
      }
      
      final quillContentJson = (templateDoc.data() as Map<String, dynamic>)['content'] as String?;
      if (quillContentJson == null || quillContentJson.isEmpty) {
        _showSnackbar('La plantilla "$documentName" está vacía.', AnimatedSnackBarType.info);
        return;
      }
      
      final deltaJson = jsonDecode(quillContentJson);
      final htmlContent = _deltaToHtml(deltaJson);
      
      final empresaDoc = await FirebaseFirestore.instance.collection('Otros').doc('empresadata').get();
      final empresaData = empresaDoc.data() as Map<String, dynamic>;

      String completedHtml = htmlContent
          .replaceAll('{{worker.name}}', widget.worker.name?.toUpperCase() ?? '')
          .replaceAll('{{worker.lastName}}', widget.worker.lastName?.toUpperCase() ?? '')
          .replaceAll('{{worker.rut}}', widget.worker.rut ?? '')
          .replaceAll('{{worker.email}}', widget.worker.email?.toUpperCase() ?? '')
          .replaceAll('{{worker.nacionality}}', widget.worker.nacionality?.toUpperCase() ?? '')
          .replaceAll('{{worker.civilState}}', widget.worker.civilState?.toUpperCase() ?? '')
          .replaceAll('{{worker.birth}}', widget.worker.birth?.toUpperCase() ?? '')
          .replaceAll('{{worker.adress}}', widget.worker.adress?.toUpperCase() ?? '')
          .replaceAll('{{worker.commune}}', widget.worker.commune?.toUpperCase() ?? '')
          .replaceAll('{{worker.labor}}', widget.worker.labor?.toUpperCase() ?? '')
          .replaceAll('{{worker.place}}', widget.worker.place?.toUpperCase() ?? '')
          .replaceAll('{{worker.afp}}', widget.worker.afp?.toUpperCase() ?? '')
          .replaceAll('{{worker.prevision}}', widget.worker.prevision?.toUpperCase() ?? '')
          .replaceAll('{{worker.ingress}}', widget.worker.ingress?.toUpperCase() ?? '')
          .replaceAll('{{company.name}}', empresaData['nombreempresa'] ?? '')
          .replaceAll('{{company.rut}}', empresaData['rut'] ?? '');

      if (specificData != null) {
        specificData.forEach((key, value) {
          completedHtml = completedHtml.replaceAll('{{$key}}', value?.toString().toUpperCase() ?? '');
        });
      }
      
      final fullHtml = """
      <div style="display: flex; justify-content: space-between; font-family: Cambria; font-weight: bold; font-size: 12px;">
        <span>${empresaData['nombreempresa'] ?? ''}</span>
        <span>AÑO ${DateTime.now().year}</span>
      </div>
      <br><br>
      $completedHtml
      <br><br><br>
      <div style="display: flex; justify-content: space-around; font-family: Calibri; font-size: 12px; text-align: center;">
        <div>
          <p>_______________________________</p>
          <p><b>${empresaData['nombreempresa'] ?? ''}</b></p>
          <p><b>RUT N°: ${empresaData['rut'] ?? ''}</b></p>
          <p><b>EMPLEADOR</b></p>
        </div>
        <div>
          <p>_______________________________</p>
          <p><b>${widget.worker.name?.toUpperCase() ?? ''} ${widget.worker.lastName?.toUpperCase() ?? ''}</b></p>
          <p><b>RUT N°: ${widget.worker.rut ?? ''}</b></p>
          <p><b>TRABAJADOR</b></p>
        </div>
      </div>
      <br><br>
      <div style="text-align: center; font-family: Calibri; font-size: 10px; color: #9B9B9B;">
        <p>O’Higgins Pelay Lt 2 H Pc N° 2 A, Comuna San Francisco De Mostazal</p>
      </div>
      """;

      final Directory tempDir = await getTemporaryDirectory();
      // CORRECCIÓN: Separar el directorio y el nombre del archivo
      final String targetDirectory = tempDir.path;
      final String targetFileName = '${documentName}_${DateTime.now().millisecondsSinceEpoch}.pdf';
      
      final generatedPdfFile = await FlutterHtmlToPdf.convertFromHtmlContent(fullHtml, targetDirectory, targetFileName);

      await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => generatedPdfFile.readAsBytes());

    } catch (e) {
      print('Error al generar el documento: $e');
      _showSnackbar('Error al generar el documento: ${e.toString()}', AnimatedSnackBarType.error);
    }
  }


   Future<void> printCarnet() async {
     try {
       final pdf = pw.Document();
       final url1 = widget.worker.imageFront != null && widget.worker.imageFront!.isNotEmpty
           ? widget.worker.imageFront!
           : 'https://firebasestorage.googleapis.com/v0/b/contratos-control.appspot.com/o/white.jpg?alt=media&token=5ac45bdc-6b4b-4ef0-949c-a717c2bec1e7';
       final url2 = widget.worker.imageBack != null && widget.worker.imageBack!.isNotEmpty
           ? widget.worker.imageBack!
           : 'https://firebasestorage.googleapis.com/v0/b/contratos-control.appspot.com/o/white.jpg?alt=media&token=5ac45bdc-6b4b-4ef0-949c-a717c2bec1e7';

       final image1 = await networkImage(url1);
       final image2 = await networkImage(url2);

       pdf.addPage(
         pw.Page(
           pageFormat: PdfPageFormat.letter,
           margin: const pw.EdgeInsets.symmetric(vertical: 50, horizontal: 30),
           build: (pw.Context context) {
             return pw.Row(
               mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
               children: [
                 pw.ClipRRect(horizontalRadius: 10, verticalRadius: 10, child: pw.Image(image1, width: 240)),
                 pw.ClipRRect(horizontalRadius: 10, verticalRadius: 10, child: pw.Image(image2, width: 240)),
               ],
             );
           },
         ),
       );

       await Printing.layoutPdf(onLayout: (formato) async => pdf.save(), format: PdfPageFormat.letter);
     } catch (e) {
       _showSnackbar('Error al imprimir carnet.', AnimatedSnackBarType.error);
     }
   }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton.extended(
            heroTag: "finiquito_fab",
            onPressed: () => _showFiniquitoModal(),
            label: const Text('Finiquito'),
            icon: const Icon(Icons.file_copy),
          ),
          const SizedBox(width: 10),
          FloatingActionButton.extended(
            heroTag: "documentos_fab",
            onPressed: () => _showDocumentosModal(),
            label: const Text('Documentos'),
            icon: const Icon(Icons.local_print_shop),
          ),
          const SizedBox(width: 10),
          FloatingActionButton.extended(
            heroTag: "carnet_fab",
            onPressed: () {
              showCupertinoModalBottomSheet(
                context: context,
                builder: (context) => Container(
                  height: 600,
                  child: PicturesPage(worker: widget.worker),
                ),
              );
            },
            label: const Text('Carnet'),
            icon: const Icon(Icons.picture_in_picture),
          ),
        ],
      ),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        title: Text(
          '${widget.worker.name?.toUpperCase() ?? ''} ${widget.worker.lastName?.toUpperCase() ?? ''}',
          style: const TextStyle(color: Colors.black),
        ),
        leading: IconButton(
          onPressed: () => _showDeleteConfirmation(),
          icon: const Icon(Icons.delete, color: Colors.black),
        ),
        actions: [
          IconButton(
            onPressed: () {
              showCupertinoModalBottomSheet(
                context: context,
                builder: (context) => Container(
                  height: MediaQuery.of(context).size.height * 0.9,
                  child: EditWorker(worker: widget.worker),
                ),
              );
            },
            icon: const Icon(Icons.edit_document, color: Colors.black),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(25.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildInfoRow('Nombres:', widget.worker.name),
            _buildInfoRow('Apellidos:', widget.worker.lastName),
            _buildInfoRow('RUT:', widget.worker.rut),
            _buildInfoRow('Correo:', widget.worker.email),
            _buildInfoRow('Nacionalidad:', widget.worker.nacionality),
            _buildInfoRow('Estado civil:', widget.worker.civilState),
            _buildInfoRow('Fecha de nacimiento:', widget.worker.birth),
            _buildInfoRow('Dirección:', widget.worker.adress, isLongText: true),
            _buildInfoRow('Comuna:', widget.worker.commune),
            _buildInfoRow('Labor:', widget.worker.labor),
            _buildInfoRow('Establecimiento:', widget.worker.place),
            _buildInfoRow('AFP:', widget.worker.afp),
            _buildInfoRow('Previsión:', widget.worker.prevision),
            _buildInfoRow('Fecha de ingreso:', widget.worker.ingress),
          ],
        ),
      ),
    );
  }

  void _showFiniquitoModal() {
    showCupertinoModalBottomSheet(
      context: context,
      builder: (context) => Container(
        height: 480,
        child: Scaffold(
          appBar: AppBar(
            title: Text('FINIQUITO ${widget.worker.name?.toUpperCase() ?? ''}'),
            centerTitle: true,
            automaticallyImplyLeading: false,
          ),
          body: Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  InputTextField(
                    teclado: TextInputType.none,
                    textController: _exitController,
                    hint: 'Fecha de Egreso',
                    onTap: () async {
                      final datePicked = await DatePicker.showSimpleDatePicker(
                        context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2023),
                        lastDate: DateTime.now().add(const Duration(days: 30)),
                        dateFormat: "dd-MMMM-yyyy",
                        locale: DateTimePickerLocale.es,
                        looping: true,
                      );
                      if (datePicked != null) {
                        setState(() => _exitController.text = DateFormat.yMMMMd('es').format(datePicked));
                      }
                    },
                    validator: (value) => (value == null || value.isEmpty) ? 'Ingrese fecha de egreso' : null,
                  ),
                  const SizedBox(height: 16),
                  InputTextField(
                    teclado: TextInputType.number,
                    textController: _vacationsController,
                    formater: FilteringTextInputFormatter.digitsOnly,
                    hint: 'Vacaciones proporcionales',
                    money: true,
                    prefix: '\$',
                    validator: (value) => (value == null || value.isEmpty) ? 'Ingrese un monto' : null,
                  ),
                  const SizedBox(height: 16),
                  InputTextField(
                    teclado: TextInputType.number,
                    textController: _totalController,
                    formater: FilteringTextInputFormatter.digitsOnly,
                    hint: 'Total',
                    money: true,
                    prefix: '\$',
                    validator: (value) => (value == null || value.isEmpty) ? 'Ingrese un monto' : null,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      CustomButton(funcion: () => Get.back(), texto: 'Cancelar', cancelar: true),
                      CustomButton(
                        cancelar: false,
                          funcion: () {
                            if (_formKey.currentState!.validate()) {
                              loadAndPrintDocument('finiquito', specificData: {
                                'exit_date': _exitController.text,
                                'vacations_amount': _vacationsController.text,
                                'total_amount': _totalController.text,
                              });
                              Get.back();
                            }
                          },
                          texto: 'Imprimir'),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showDocumentosModal() {
    List<String> seleccionados = [];
    showCupertinoModalBottomSheet(
      context: context,
      builder: (context) => Container(
        height: 300,
        child: Scaffold(
          appBar: AppBar(
            title: Text('DOCUMENTOS ${widget.worker.name?.toUpperCase() ?? ''}'),
            centerTitle: true,
            automaticallyImplyLeading: false,
          ),
          body: Column(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              GroupButton(
                options: const GroupButtonOptions(borderRadius: BorderRadius.all(Radius.circular(10))),
                isRadio: false,
                onSelected: (button, index, isSelected) {
                  if (isSelected) {
                    seleccionados.add(button);
                  } else {
                    seleccionados.remove(button);
                  }
                },
                buttons: [
                  "Contrato",
                  "Derecho a saber",
                  "EPP",
                  "Registro",
                  if (widget.worker.imageFront != null && widget.worker.imageFront!.isNotEmpty) "Carnet",
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  CustomButton(funcion: () => Get.back(), texto: 'Cancelar', cancelar: true),
                  CustomButton(
                    cancelar: false,
                    funcion: () {
                      Get.back();
                      for (String docName in seleccionados) {
                        String templateName = '';
                        switch (docName) {
                          case 'Contrato': templateName = 'contrato'; break;
                          case 'Derecho a saber': templateName = 'derecho_saber'; break;
                          case 'EPP': templateName = 'epp'; break;
                          case 'Registro': templateName = 'registro'; break;
                          case 'Carnet': printCarnet(); break;
                        }
                        if (templateName.isNotEmpty) {
                          loadAndPrintDocument(templateName);
                        }
                      }
                    },
                    texto: 'Imprimir',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirmation() {
    showCupertinoModalBottomSheet(
      context: context,
      builder: (context) => Container(
        height: 150,
        child: Scaffold(
          appBar: AppBar(
            title: Text('¿Eliminar ${widget.worker.name?.toUpperCase() ?? ''}?'),
            centerTitle: true,
            automaticallyImplyLeading: false,
          ),
          body: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              CustomButton(funcion: () => Get.back(), texto: 'Cancelar', cancelar: true),
              CustomButton(
                cancelar: false,
                funcion: () async {
                  final String rut = widget.worker.rut ?? '';
                  final String? workerId = widget.worker.id;

                  // 1. Borrar imágenes de Storage (con manejo de errores individual)
                  if (rut.isNotEmpty) {
                    const path = 'WorkersIdImages/';
                    if (widget.worker.imageFront != null && widget.worker.imageFront!.isNotEmpty) {
                      try {
                        await FirebaseStorage.instance.ref(path).child('${rut}_front').delete();
                      } catch (e) {
                        if (e is FirebaseException && e.code == 'object-not-found') {
                          print("La imagen frontal no existía, continuando...");
                        } else {
                          print("Error al borrar imagen frontal: $e");
                        }
                      }
                    }
                    if (widget.worker.imageBack != null && widget.worker.imageBack!.isNotEmpty) {
                       try {
                        await FirebaseStorage.instance.ref(path).child('${rut}_back').delete();
                      } catch (e) {
                        if (e is FirebaseException && e.code == 'object-not-found') {
                          print("La imagen trasera no existía, continuando...");
                        } else {
                          print("Error al borrar imagen trasera: $e");
                        }
                      }
                    }
                  }

                  // 2. Borrar documento de Firestore
                  try {
                    await FirebaseFirestore.instance.collection('Trabajadores').doc(workerId).delete();
                    Get.back();
                    Get.back();
                    _showSnackbar('Trabajador eliminado con éxito', AnimatedSnackBarType.success);
                  } catch (e) {
                    _showSnackbar('Error al eliminar trabajador.', AnimatedSnackBarType.error);
                  }
                },
                texto: 'Confirmar',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String? value, {bool isLongText = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18),
          ),
          SizedBox(
            width: isLongText ? MediaQuery.of(context).size.width * 0.5 : null,
            child: Text(
              value?.toUpperCase() ?? 'N/A',
              textAlign: TextAlign.end,
              style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.bold, fontSize: 18),
            ),
          )
        ],
      ),
    );
  }
}
