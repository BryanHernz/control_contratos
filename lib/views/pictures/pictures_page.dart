import 'dart:io';
import 'package:animated_snack_bar/animated_snack_bar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart' hide ModalBottomSheetRoute;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_mlkit_document_scanner/google_mlkit_document_scanner.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:get/get.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:printing/printing.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart'
    show kIsWeb; // Import for platform check

import '../../customs/constants_values.dart';
import '../../customs/widgets_custom.dart';
import '../../models/worker_model.dart';

class PicturesPage extends StatefulWidget {
  const PicturesPage({super.key, required this.worker});

  final WorkerModel worker;

  @override
  State<PicturesPage> createState() => _PicturesPageState();
}

class _PicturesPageState extends State<PicturesPage> {
  bool _isUploading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: widget.worker.imageFront == ''
          ? null
          : FloatingActionButton.extended(
              onPressed: _isUploading ? null : printing,
              icon: _isUploading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Icon(Icons.print),
              label: const Text('Imprimir'),
            ),
      appBar: AppBar(
        elevation: 20,
        centerTitle: true,
        backgroundColor: primario,
        automaticallyImplyLeading: false,
        title: const Text(
          'Imágenes de identificación',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 20),
          child: Center(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildImageSection(
                  imageUrl: widget.worker.imageFront,
                  position: 1,
                  label: 'frontal',
                ),
                const SizedBox(height: 10),
                _buildImageSection(
                  imageUrl: widget.worker.imageBack,
                  position: 2,
                  label: 'trasera',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImageSection({
    required String? imageUrl,
    required int position,
    required String label,
  }) {
    return imageUrl == null || imageUrl.isEmpty
        ? _buildEmptyCard(position, label)
        : _buildImageCard(imageUrl, position, label);
  }

  Widget _buildEmptyCard(int position, String label) {
    return Card(
      elevation: 5,
      child: Container(
        padding: const EdgeInsets.all(20),
        height: 200,
        width: 350,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Text(
              'No hay imagen $label de Carnet para este trabajador.',
              textAlign: TextAlign.center,
            ),
            FloatingActionButton.extended(
              heroTag: 'scan_$position',
              onPressed: _isUploading ? null : () => _scanDocument(position),
              icon: const Icon(Icons.add_a_photo),
              label: const Text('Escanear Documento'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageCard(String imageUrl, int position, String label) {
    return Card(
      elevation: 10,
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10.0),
            child: Image.network(
              imageUrl,
              height: MediaQuery.of(context).size.height / 4.5,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, progress) {
                return progress == null
                    ? child
                    : Container(
                        padding: const EdgeInsets.all(20),
                        height: 200,
                        width: 350,
                        child:
                            const Center(child: CircularProgressIndicator()));
              },
            ),
          ),
          Positioned(
            top: 6,
            right: 6,
            child: FloatingActionButton.small(
              heroTag: 'delete_$position',
              onPressed: () => _showDeleteDialog(position),
              child: const Icon(Icons.delete_outline_rounded),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _scanDocument(int position) async {
    if (kIsWeb) {
      _showError(
          "La función de escaneo no está disponible en la web. Por favor, suba una imagen desde su dispositivo.");
      return;
    }
    try {
      setState(() => _isUploading = true);

      // Corrected DocumentScannerOptions
      final DocumentScannerOptions options = DocumentScannerOptions(
        mode: ScannerMode.base,
        isGalleryImport: true,
        pageLimit: 1,
      );

      final DocumentScanner documentScanner = DocumentScanner(options: options);
      final DocumentScanningResult result =
          await documentScanner.scanDocument();

      if (result.images.isNotEmpty) {
        await _uploadFile(position, result.images.first);
      } else {
        _showInfo('No se seleccionó o escaneó ningún documento.');
      }
    } catch (e) {
      _showError(
          'Ocurrió un error con el escáner de documentos: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  Future<void> _uploadFile(int position, String imagePath) async {
    try {
      final file = File(imagePath);
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        _showError('Usuario no autenticado');
        return;
      }

      final path =
          'WorkersIdImages/${widget.worker.rut}_${position == 1 ? 'front' : 'back'}';
      final metadata = SettableMetadata(contentType: 'image/jpeg');

      final uploadTask =
          FirebaseStorage.instance.ref(path).putFile(file, metadata);
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      await FirebaseFirestore.instance
          .collection('Trabajadores')
          .doc(widget.worker.id)
          .update({position == 1 ? 'imagenFront' : 'imagenBack': downloadUrl});

      setState(() {
        if (position == 1) {
          widget.worker.imageFront = downloadUrl;
        } else {
          widget.worker.imageBack = downloadUrl;
        }
      });

      _showSuccess(
          'Imagen ${position == 1 ? 'frontal' : 'trasera'} actualizada');
    } catch (e) {
      _showError('Error al subir: ${e.toString()}');
    }
  }

  void _showDeleteDialog(int position) {
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
              '¿Eliminar la imagen ${position == 1 ? 'frontal' : 'trasera'}?',
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
                  funcion: () => Get.back(),
                  texto: 'Cancelar',
                  cancelar: true,
                ),
                CustomButton(
                  funcion: () => _deleteImage(position),
                  texto: 'Confirmar',
                  cancelar: false,
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _deleteImage(int position) async {
    try {
      const path = 'WorkersIdImages/';
      final fileName =
          '${widget.worker.rut}_${position == 1 ? 'front' : 'back'}';

      Get.back();
      await FirebaseStorage.instance.ref(path).child(fileName).delete();

      await FirebaseFirestore.instance
          .collection('Trabajadores')
          .doc(widget.worker.id)
          .update({position == 1 ? 'imagenFront' : 'imagenBack': ''});

      setState(() {
        if (position == 1) {
          widget.worker.imageFront = '';
        } else {
          widget.worker.imageBack = '';
        }
      });

      _showSuccess('Imagen eliminada con éxito');
    } catch (e) {
      _showError('Error al eliminar: ${e.toString()}');
    }
  }

  Future<void> printing() async {
    try {
      final url1 = widget.worker.imageFront?.isNotEmpty == true
          ? widget.worker.imageFront!
          : 'https://firebasestorage.googleapis.com/v0/b/contratos-control.appspot.com/o/white.jpg?alt=media&token=5ac45bdc-6b4b-4ef0-949c-a717c2bec1e7';

      final url2 = widget.worker.imageBack?.isNotEmpty == true
          ? widget.worker.imageBack!
          : 'https://firebasestorage.googleapis.com/v0/b/contratos-control.appspot.com/o/white.jpg?alt=media&token=5ac45bdc-6b4b-4ef0-949c-a717c2bec1e7';

      final pdf = pw.Document();
      final image1 = await _loadImage(url1);
      final image2 = await _loadImage(url2);
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

      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
        format: PdfPageFormat.letter,
        usePrinterSettings: true,
      );
    } catch (e) {
      _showError('Error al generar PDF: ${e.toString()}');
    }
  }

  Future<pw.ImageProvider> _loadImage(String url) async {
    final response = await http.get(Uri.parse(url));
    return pw.MemoryImage(response.bodyBytes);
  }

  void _showError(String message) {
    if (!mounted) return;
    AnimatedSnackBar.material(
      message,
      type: AnimatedSnackBarType.error,
    ).show(context);
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    AnimatedSnackBar.material(
      message,
      type: AnimatedSnackBarType.success,
    ).show(context);
  }

  void _showInfo(String message) {
    if (!mounted) return;
    AnimatedSnackBar.material(
      message,
      type: AnimatedSnackBarType.info,
    ).show(context);
  }
}
