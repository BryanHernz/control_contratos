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
import 'package:printing/printing.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart'
    show kIsWeb; // Import for platform check

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
    return LayoutBuilder(
      builder: (context, constraints) {
        final baseHeight = constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : MediaQuery.of(context).size.height * 0.7;
        final imageCardHeight =
            (baseHeight * 0.34).clamp(170.0, 280.0).toDouble();

        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.max,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 18.0, bottom: 10.0),
                child: Text(
                  'Im\u00e1genes de identificaci\u00f3n',
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18.0, vertical: 6),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildImageSection(
                          imageUrl: widget.worker.imageFront,
                          position: 1,
                          label: 'frontal',
                          imageCardHeight: imageCardHeight,
                        ),
                        const SizedBox(height: 12),
                        _buildImageSection(
                          imageUrl: widget.worker.imageBack,
                          position: 2,
                          label: 'trasera',
                          imageCardHeight: imageCardHeight,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (widget.worker.imageFront != null &&
                  widget.worker.imageFront != '')
                Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.only(
                        top: 8.0, bottom: 14.0, right: 18.0),
                    child: SizedBox(
                      width: 170,
                      child: _SheetLikeActionButton(
                        label: 'Imprimir',
                        icon: Icons.print_outlined,
                        isPrimary: true,
                        onPressed: _isUploading ? null : printing,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildImageSection({
    required String? imageUrl,
    required int position,
    required String label,
    required double imageCardHeight,
  }) {
    return imageUrl == null || imageUrl.isEmpty
        ? _buildEmptyCard(position, label, imageCardHeight)
        : _buildImageCard(imageUrl, position, label, imageCardHeight);
  }

  Widget _buildEmptyCard(int position, String label, double imageCardHeight) {
    final cardWidth = (imageCardHeight * 1.58).clamp(250.0, 460.0).toDouble();
    final title = position == 1 ? 'Imagen frontal' : 'Imagen trasera';

    return Center(
      child: SizedBox(
        width: cardWidth,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.blueGrey.shade100),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 14,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: SizedBox(
            height: imageCardHeight,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: const Color(0xFF496273).withOpacity(0.10),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.badge_outlined,
                        size: 18,
                        color: Color(0xFF496273),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              color: Colors.blueGrey.shade900,
                              fontWeight: FontWeight.w700,
                              fontSize: 13.5,
                            ),
                          ),
                          Text(
                            'A\u00fan no cargada',
                            style: TextStyle(
                              color: Colors.blueGrey.shade500,
                              fontWeight: FontWeight.w500,
                              fontSize: 11.8,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF6F9FB),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.blueGrey.shade100),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.image_not_supported_outlined,
                          size: 20,
                          color: Colors.blueGrey.shade300,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'No hay imagen $label de carnet para este trabajador.',
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.blueGrey.shade500,
                            fontSize: 12,
                            height: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: _SheetLikeActionButton(
                    label:
                        _isUploading ? 'Escaneando...' : 'Escanear documento',
                    icon: _isUploading
                        ? Icons.hourglass_top_rounded
                        : Icons.add_a_photo_outlined,
                    isPrimary: true,
                    onPressed:
                        _isUploading ? null : () => _scanDocument(position),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImageCard(
    String imageUrl,
    int position,
    String label,
    double imageCardHeight,
  ) {
    final cardWidth = (imageCardHeight * 1.58).clamp(250.0, 460.0).toDouble();

    return Center(
      child: SizedBox(
        width: cardWidth,
        child: Card(
          elevation: 10,
          child: Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10.0),
                child: Image.network(
                  imageUrl,
                  width: cardWidth,
                  fit: BoxFit.fitWidth,
                  loadingBuilder: (context, child, progress) {
                    return progress == null
                        ? child
                        : AspectRatio(
                            aspectRatio: 1.58,
                            child: Container(
                              color: Colors.black.withOpacity(0.04),
                              child: const Center(
                                child: CircularProgressIndicator(),
                              ),
                            ),
                          );
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
        ),
      ),
    );
  }

  Future<void> _scanDocument(int position) async {
    if (kIsWeb) {
      _showError(
          "La funci\u00f3n de escaneo no est\u00e1 disponible en la web. Por favor, suba una imagen desde su dispositivo.");
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
        _showInfo(
            'No se seleccion\u00f3 o escane\u00f3 ning\u00fan documento.');
      }
    } catch (e) {
      _showError(
          'Ocurri\u00f3 un error con el esc\u00e1ner de documentos: ${e.toString()}');
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
    final sideLabel = position == 1 ? 'frontal' : 'trasera';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SafeArea(
        top: false,
        child: Container(
          decoration: const BoxDecoration(
            color: Color(0xFFF4F7FA),
            borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
          ),
          clipBehavior: Clip.hardEdge,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(26)),
                  gradient: LinearGradient(
                    colors: [
                      Colors.blueGrey.shade900,
                      Colors.blueGrey.shade700
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
                  child: Column(
                    children: [
                      Container(
                        width: 42,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.32),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.14),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.delete_outline_rounded,
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Eliminar imagen',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 17,
                                  ),
                                ),
                                Text(
                                  'Lado ${sideLabel.toUpperCase()} del carnet',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.78),
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w500,
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
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: Colors.blueGrey.shade100,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: const Color(0xFFD64545).withOpacity(0.10),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.warning_amber_rounded,
                              color: Color(0xFFD64545),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Esta accion no se puede deshacer',
                                  style: TextStyle(
                                    color: Colors.blueGrey.shade900,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Se eliminara la imagen $sideLabel asociada al carnet del trabajador.',
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
                    ),
                    const SizedBox(height: 14),
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
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: _SheetLikeActionButton(
                            label: 'Cancelar',
                            icon: Icons.close_rounded,
                            onPressed: () => Get.back(),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _SheetLikeActionButton(
                            label: 'Eliminar',
                            icon: Icons.delete_outline_rounded,
                            isPrimary: true,
                            primaryColor: const Color(0xFFD64545),
                            onPressed: () => _deleteImage(position),
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

      _showSuccess('Imagen eliminada con \u00e9xito');
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

class _SheetLikeActionButton extends StatelessWidget {
  const _SheetLikeActionButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.isPrimary = false,
    this.primaryColor = const Color(0xFF496273),
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool isPrimary;
  final Color primaryColor;

  @override
  Widget build(BuildContext context) {
    final isEnabled = onPressed != null;
    final backgroundColor = isPrimary
        ? (isEnabled ? primaryColor : primaryColor.withOpacity(0.35))
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
                        color: primaryColor.withOpacity(0.28),
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
