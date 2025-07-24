import 'dart:io';
import 'package:animated_snack_bar/animated_snack_bar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_doc_scanner/flutter_doc_scanner.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:get/get.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:printing/printing.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart'
    show kIsWeb; // Import for platform check
import 'package:image_picker/image_picker.dart'; // Import for image selection
import 'package:image_cropper/image_cropper.dart' as ic; // Import with prefix
import 'dart:typed_data'; // Import for Uint8List

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
  void initState() {
    super.initState();
    // Se eliminó _checkPermissions() de initState.
    // Los permisos se solicitarán cuando sean necesarios en _scanDocument.
  }

  // Este método ya no se llama en initState, su funcionalidad se integró en _verifyPermissions
  // Future<void> _checkPermissions() async {
  //   if (!kIsWeb) {
  //     await Permission.camera.request();
  //     await Permission.storage.request();
  //     if (Platform.isIOS) await Permission.photos.request();
  //   }
  // }

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
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FloatingActionButton.extended(
                  heroTag: 'add_$position',
                  onPressed:
                      _isUploading ? null : () => _scanDocument(position),
                  icon: const Icon(Icons.add_photo_alternate),
                  label: const Text('Agregar'),
                ),
              ],
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
    try {
      setState(() => _isUploading = true);

      String? imagePath;
      Uint8List? imageBytes;

      if (kIsWeb) {
        final ImagePicker picker = ImagePicker();
        final XFile? pickedFile =
            await picker.pickImage(source: ImageSource.gallery);

        if (pickedFile != null) {
          final croppedFile = await ic.ImageCropper().cropImage(
            sourcePath: pickedFile.path,
            uiSettings: [
              ic.WebUiSettings(
                context: context,
                presentStyle: ic.WebPresentStyle.dialog,
                themeData: const ic.WebThemeData(
                    // Parámetros válidos para WebThemeData (solo los disponibles en la versión que estás usando)
                    // Puedes personalizar iconos o colores específicos que estén definidos aquí.
                    ),
              ),
            ],
          );
          if (croppedFile != null) {
            imageBytes = await croppedFile.readAsBytes();
          } else {
            _showInfo('No se recortó ninguna imagen.');
            setState(() => _isUploading = false);
            return;
          }
        } else {
          _showInfo('No se seleccionó ninguna imagen.');
          setState(() => _isUploading = false);
          return;
        }
      } else {
        // En plataformas móviles, verificar permisos antes de usar flutter_doc_scanner
        if (!await _verifyPermissions()) {
          setState(() => _isUploading = false);
          return;
        }

        final List<String>? scannedImages =
            await FlutterDocScanner().getScannedDocumentAsImages();

        if (scannedImages == null || scannedImages.isEmpty) {
          _showInfo('No se seleccionó ninguna imagen.');
          setState(() => _isUploading = false);
          return;
        }

        if (scannedImages.length > 1) {
          _showInfo(
              'Se seleccionaron varias imágenes. Solo se procesará la primera.');
        }

        imagePath = await _validateFilePath(scannedImages.first);
        if (imagePath == null) {
          _showError('No se pudo procesar el documento escaneado');
          setState(() => _isUploading = false);
          return;
        }
      }

      if (kIsWeb && imageBytes != null) {
        await _uploadBytesFile(position, imageBytes);
      } else if (!kIsWeb && imagePath != null) {
        await _uploadFile(position, imagePath);
      } else {
        _showInfo('No se obtuvo una imagen para subir.');
      }

      if (!kIsWeb) {
        // Only cleanup for mobile platforms where a cache might exist
        await _cleanupScanCache();
      }
    } catch (e) {
      _showError('Error durante el escaneo: ${e.toString()}');
      debugPrint('Error details: $e');
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<String?> _validateFilePath(String fileUri) async {
    try {
      final filePath = fileUri.startsWith('file://')
          ? fileUri.replaceFirst('file://', '')
          : fileUri;

      final file = File(filePath);

      if (!await file.exists()) {
        debugPrint('Archivo no existe en la ruta: $filePath');
        return null;
      }

      return file.path;
    } catch (e) {
      debugPrint('Error validando archivo: $e');
      return null;
    }
  }

  // Método actualizado para verificar y solicitar permisos para Android/iOS
  Future<bool> _verifyPermissions() async {
    // Solicitar permisos de cámara y almacenamiento
    final cameraStatus = await Permission.camera.request();
    final photosStatus =
        await Permission.photos.request(); // Usar photos en lugar de storage

    if (cameraStatus.isGranted && photosStatus.isGranted) {
      return true;
    } else {
      _showError(
          'Se requieren permisos de cámara y acceso a fotos para esta función.');
      // Si alguno de los permisos es permanentemente denegado, guiar al usuario a la configuración
      if (cameraStatus.isPermanentlyDenied ||
          photosStatus.isPermanentlyDenied) {
        openAppSettings(); // Abre la configuración de la aplicación
      }
      return false;
    }
  }

  Future<void> _uploadFile(int position, String imagePath) async {
    try {
      final file = File(imagePath);
      if (!await file.exists()) {
        _showError('El archivo no existe');
        return;
      }

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

  // New function to upload bytes for web
  Future<void> _uploadBytesFile(int position, Uint8List imageBytes) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _showError('Usuario no autenticado');
        return;
      }

      final path =
          'WorkersIdImages/${widget.worker.rut}_${position == 1 ? 'front' : 'back'}';
      final metadata = SettableMetadata(contentType: 'image/jpeg');

      final uploadTask =
          FirebaseStorage.instance.ref(path).putData(imageBytes, metadata);
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

  Future<void> _cleanupScanCache() async {
    try {
      final tempDir = await getTemporaryDirectory();
      final scanDir = Directory('${tempDir.path}/mlkit_docscan_ui_client');
      if (await scanDir.exists()) {
        await scanDir.delete(recursive: true);
      }
    } catch (e) {
      debugPrint('Cache cleanup error: $e');
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

      await FirebaseStorage.instance.ref(path).child(fileName).delete();

      await FirebaseFirestore.instance
          .collection('Trabajadores')
          .doc(widget.worker.id)
          .update({position == 1 ? 'imagenFront' : 'imagenBack': ''});

      Get.back();
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
