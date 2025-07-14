// lib/views/templates/template_editor_page.dart
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:animated_snack_bar/animated_snack_bar.dart';
import 'package:flutter_quill/flutter_quill.dart' hide Text;

class TemplateEditorPage extends StatefulWidget {
  const TemplateEditorPage({Key? key}) : super(key: key);

  @override
  _TemplateEditorPageState createState() => _TemplateEditorPageState();
}

class _TemplateEditorPageState extends State<TemplateEditorPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _newTemplateNameController = TextEditingController();
  QuillController _quillController = QuillController.basic();
  String? _selectedTemplateId;
  List<QueryDocumentSnapshot> _templates = [];
  bool _isLoading = true;
  bool _isEditorLoading = false;
  final FocusNode _focusNode = FocusNode();


  @override
  void initState() {
    super.initState();
    _loadTemplates();
  }

  @override
  void dispose() {
    _newTemplateNameController.dispose();
    _quillController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _showSnackbar(String message, AnimatedSnackBarType type) {
    if (!mounted) return;
    AnimatedSnackBar.material(message, mobileSnackBarPosition: MobileSnackBarPosition.top, desktopSnackBarPosition: DesktopSnackBarPosition.bottomRight, type: type).show(context);
  }
  void _showSuccessSnackbar(String message) => _showSnackbar(message, AnimatedSnackBarType.success);
  void _showErrorSnackbar(String message) => _showSnackbar(message, AnimatedSnackBarType.error);
  void _showInfoSnackbar(String message) => _showSnackbar(message, AnimatedSnackBarType.info);

  Future<void> _loadTemplates() async {
    setState(() => _isLoading = true);
    try {
      final snapshot = await _firestore.collection('templates').get();
      setState(() {
        _templates = snapshot.docs;
        if (_templates.isNotEmpty) {
          _selectedTemplateId = _templates.first.id;
          _loadTemplateContent(_selectedTemplateId!);
        } else {
           _quillController = QuillController.basic();
        }
      });
    } catch (e) {
      _showErrorSnackbar('Error al cargar plantillas: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadTemplateContent(String templateId) async {
    setState(() => _isEditorLoading = true);
    try {
      final templateDoc = await _firestore.collection('templates').doc(templateId).get();
      if (templateDoc.exists && (templateDoc.data() as Map).containsKey('content')) {
        final content = (templateDoc.data() as Map<String, dynamic>)['content'] as String?;
        if (content != null && content.isNotEmpty) {
          final decodedContent = jsonDecode(content);
          _quillController = QuillController(
            document: Document.fromJson(decodedContent),
            selection: const TextSelection.collapsed(offset: 0),
          );
        } else {
          _quillController = QuillController.basic();
        }
      } else {
        _quillController = QuillController.basic();
      }
    } catch (e) {
      _showErrorSnackbar('Error al cargar contenido: $e');
      _quillController = QuillController.basic(); // Reset on error
    } finally {
      setState(() => _isEditorLoading = false);
    }
  }

  Future<void> _saveTemplateContent() async {
    if (_selectedTemplateId == null || _selectedTemplateId!.isEmpty) {
      _showInfoSnackbar('No hay plantilla seleccionada para guardar.');
      return;
    }
    try {
      final jsonContent = jsonEncode(_quillController.document.toDelta().toJson());
      await _firestore
          .collection('templates')
          .doc(_selectedTemplateId)
          .set({'content': jsonContent}, SetOptions(merge: true));
      _showSuccessSnackbar('Plantilla guardada con éxito.');
    } catch (e) {
      _showErrorSnackbar('Error al guardar plantilla: $e');
    }
  }
  
  void _showCreateTemplateDialog() {
    _newTemplateNameController.clear();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Crear Nueva Plantilla'),
          content: TextField(
            controller: _newTemplateNameController,
            decoration: InputDecoration(hintText: "Nombre de la plantilla (ej: finiquito)"),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: Text('Cancelar')),
            TextButton(
              onPressed: () {
                if (_newTemplateNameController.text.isNotEmpty) {
                  _createNewTemplate(_newTemplateNameController.text.trim());
                  Navigator.of(context).pop();
                }
              },
              child: Text('Crear'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _createNewTemplate(String newTemplateName) async {
    try {
      final doc = await _firestore.collection('templates').doc(newTemplateName).get();
      if(doc.exists) {
        _showInfoSnackbar('Ya existe una plantilla con este nombre.');
        return;
      }
      final basicJsonContent = jsonEncode([{'insert': 'Escribe aquí el contenido...'}]);
      await _firestore.collection('templates').doc(newTemplateName).set({'content': basicJsonContent});
      _showSuccessSnackbar('Plantilla "$newTemplateName" creada.');
      await _loadTemplates(); // Recargar la lista de plantillas
    } catch (e) {
      _showErrorSnackbar('Error al crear la plantilla: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Editar Plantillas')),
      floatingActionButton: FloatingActionButton.extended(onPressed: _showCreateTemplateDialog, icon: Icon(Icons.add), label: Text('Crear')),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_templates.isNotEmpty)
                    DropdownButtonFormField<String>(
                      value: _selectedTemplateId,
                      items: _templates.map((template) => DropdownMenuItem<String>(value: template.id, child: Text(template.id))).toList(),
                      onChanged: (newValue) {
                        if (newValue != null) {
                           setState(() {
                            _selectedTemplateId = newValue;
                            _loadTemplateContent(newValue);
                          });
                        }
                      },
                      decoration: InputDecoration(labelText: 'Seleccionar Plantilla', border: OutlineInputBorder()),
                    ),
                  if (_templates.isEmpty && !_isLoading)
                    Center(child: Padding(padding: const EdgeInsets.symmetric(vertical: 20.0), child: Text('No hay plantillas. Crea una nueva para comenzar.', style: TextStyle(fontSize: 16, color: Colors.grey)))),
                  SizedBox(height: 16),
                  if (!_isEditorLoading)
                    QuillToolbar.basic(
                      controller: _quillController,
                      showAlignmentButtons: true,
                    ),
                  SizedBox(height: 8),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(4)),
                      child: _isEditorLoading 
                        ? Center(child: CircularProgressIndicator())
                        : QuillEditor(
                            controller: _quillController,
                            focusNode: _focusNode,
                            scrollController: ScrollController(),
                            scrollable: true,
                            padding: EdgeInsets.all(12),
                            autoFocus: false,
                            readOnly: _selectedTemplateId == null,
                            expands: false,
                          ),
                    ),
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(onPressed: _selectedTemplateId == null ? null : _saveTemplateContent, child: Text('Guardar Plantilla'), style: ElevatedButton.styleFrom(padding: EdgeInsets.symmetric(vertical: 16))),
                ],
              ),
            ),
    );
  }
}
