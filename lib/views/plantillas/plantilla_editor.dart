import 'dart:async';

import 'package:animated_snack_bar/animated_snack_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as q;

import '../../customs/app_colors.dart';
import '../../customs/constants_values.dart';
import '../../customs/widgets/app_form.dart';
import '../../customs/widgets/app_modal.dart';
import '../../customs/widgets_custom.dart';
import '../../services/plantilla_campos.dart';
import '../../services/plantilla_preview.dart';
import '../../services/plantilla_render.dart' show kMarcadorTabla;
import '../../services/plantilla_service.dart';
import 'hoja_previa.dart';

/// Alto de las tres columnas del editor, segun la pantalla.
///
/// Acotado y no infinito: ver la nota en `filaDeColumnas` mas abajo. Que salga
/// de la altura disponible y no de una constante es lo que hace que en un
/// monitor grande se vea media hoja de contrato en vez de cuatro parrafos.
double _altoColumnas(BuildContext context) {
  final alto = MediaQuery.sizeOf(context).height;
  // Deja sitio para la cabecera del modal, el aviso de version, la nota y el
  // pie de botones, que van fuera de la fila.
  return (alto * 0.56).clamp(420.0, 820.0);
}

/// Editor de una plantilla de documento.
class PlantillaEditor extends StatefulWidget {
  const PlantillaEditor({super.key, required this.tipo});

  final TipoPlantilla tipo;

  @override
  State<PlantillaEditor> createState() => _PlantillaEditorState();
}

class _PlantillaEditorState extends State<PlantillaEditor> {
  q.QuillController? _controller;
  final _focus = FocusNode();
  final _scroll = ScrollController();
  final _notaController = TextEditingController();

  VersionPlantilla? _vigente;
  bool _cargando = true;
  bool _publicando = false;
  bool _hayCambios = false;

  /// Filas de la tabla, cuando el documento lleva una.
  List<List<String>> _filas = [];

  VistaPreviaPlantilla? _preview;
  bool _generandoPreview = false;
  Timer? _debounce;

  /// Cuantas hojas ocupaba la version vigente al abrir el editor. Sirve para
  /// avisar cuando la edicion hace crecer el documento.
  int? _paginasAlAbrir;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller?.dispose();
    _focus.dispose();
    _scroll.dispose();
    _notaController.dispose();
    super.dispose();
  }

  /// Regenera la vista previa cuando el usuario deja de escribir.
  ///
  /// Con retardo y no en cada tecla: cada refresco maqueta un PDF completo, y
  /// hacerlo por caracter deja el editor a tirones.
  void _programarPreview() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 700), _generarPreview);
  }

  Future<void> _generarPreview() async {
    final c = _controller;
    if (c == null || _generandoPreview) return;
    setState(() => _generandoPreview = true);
    try {
      final r = await PlantillaPreview.generar(
        {'ops': c.document.toDelta().toJson()},
        tipo: widget.tipo,
        filas: _filas,
      );
      if (!mounted) return;
      setState(() {
        _preview = r;
        _paginasAlAbrir ??= r.paginas;
        _generandoPreview = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _generandoPreview = false);
    }
  }

  Future<void> _cargar() async {
    final vigente = await PlantillaService.obtenerVigente(widget.tipo.clave);
    if (!mounted) return;

    final doc =
        vigente == null ? q.Document() : _documentoDesdeDelta(vigente.delta);

    final controller = q.QuillController(
      document: doc,
      selection: const TextSelection.collapsed(offset: 0),
    );
    controller.addListener(() {
      if (!mounted) return;
      if (!_hayCambios) setState(() => _hayCambios = true);
      _programarPreview();
    });

    setState(() {
      _vigente = vigente;
      _controller = controller;
      _filas = [
        for (final f in vigente?.filas ?? const <List<String>>[])
          List<String>.from(f),
      ];
      _cargando = false;
    });

    _generarPreview();
  }

  q.Document _documentoDesdeDelta(Map<String, dynamic> delta) {
    try {
      final ops = delta['ops'];
      if (ops is List && ops.isNotEmpty) return q.Document.fromJson(ops);
    } catch (_) {
      // Delta ilegible: se abre en blanco en vez de dejar la pantalla rota.
    }
    return q.Document();
  }

  void _insertarMarcador(CampoPlantilla m) {
    final c = _controller;
    if (c == null) return;
    final indice = c.selection.baseOffset;
    c.replaceText(
      indice,
      c.selection.extentOffset - indice,
      m.token,
      TextSelection.collapsed(offset: indice + m.token.length),
    );
    _focus.requestFocus();
  }

  Future<void> _publicar() async {
    final c = _controller;
    if (c == null || _publicando) return;

    final texto = c.document.toPlainText().trim();
    if (texto.isEmpty) {
      _avisar('La plantilla esta vacia.', AnimatedSnackBarType.warning);
      return;
    }

    setState(() => _publicando = true);
    try {
      await PlantillaService.publicar(
        tipo: widget.tipo.clave,
        delta: {'ops': c.document.toDelta().toJson()},
        nota: _notaController.text,
        filas: _filas,
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      _avisar('Plantilla publicada.', AnimatedSnackBarType.success);
    } catch (e) {
      if (!mounted) return;
      setState(() => _publicando = false);
      _avisar('No se pudo publicar: $e', AnimatedSnackBarType.error);
    }
  }

  void _avisar(String mensaje, AnimatedSnackBarType tipo) {
    AnimatedSnackBar.material(mensaje, type: tipo).show(context);
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando || _controller == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 64),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final ancho = MediaQuery.sizeOf(context).width;

    // Tres columnas -- escribir, insertar campos y ver el resultado -- solo
    // caben de verdad en pantalla apaisada. Bajo ese ancho se apilan, porque
    // tres columnas estrechas dejan el editor y la vista previa inservibles.
    final tresColumnas = ancho >= 1150;
    final dosColumnas = ancho >= 900;

    // Las columnas comparten alto porque la fila lo tiene fijo, no por
    // `IntrinsicHeight`.
    //
    // Eso no es un detalle: todo esto vive dentro de un `SingleChildScrollView`
    // (`AppModalBody`), que da altura infinita a sus hijos. Un `Expanded` bajo
    // altura infinita no tiene nada que repartir y la maquetacion se cuelga --
    // el modal quedaba en blanco y la pestaña se congelaba. Con un alto fijo en
    // la fila, los `Expanded` de adentro vuelven a tener un maximo del que
    // repartir.
    final altoColumnas = _altoColumnas(context);

    Widget filaDeColumnas(List<Widget> columnas) => SizedBox(
          height: altoColumnas,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: columnas,
          ),
        );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: AppModalBody(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                _cabeceraVersion(),
                const SizedBox(height: 16),
                if (tresColumnas)
                  filaDeColumnas([
                    Expanded(flex: 5, child: _bloqueEditor()),
                    const SizedBox(width: 16),
                    SizedBox(
                      width: 250,
                      child: SingleChildScrollView(child: _bloqueMarcadores()),
                    ),
                    const SizedBox(width: 16),
                    Expanded(flex: 5, child: _bloqueVistaPrevia()),
                  ])
                else if (dosColumnas) ...[
                  filaDeColumnas([
                    Expanded(child: _bloqueEditor()),
                    const SizedBox(width: 16),
                    SizedBox(
                      width: 250,
                      child: SingleChildScrollView(child: _bloqueMarcadores()),
                    ),
                  ]),
                  const SizedBox(height: 16),
                  SizedBox(height: altoColumnas, child: _bloqueVistaPrevia()),
                ] else ...[
                  SizedBox(height: altoColumnas, child: _bloqueEditor()),
                  const SizedBox(height: 16),
                  _bloqueMarcadores(),
                  const SizedBox(height: 16),
                  SizedBox(height: altoColumnas, child: _bloqueVistaPrevia()),
                ],
                if (widget.tipo.llevaTabla) ...[
                  const SizedBox(height: 16),
                  _bloqueTabla(),
                ],
                const SizedBox(height: 16),
                AppFormSection(
                  title: 'Nota de la version',
                  icon: Icons.history_edu_rounded,
                  child: InputTextField(
                    textController: _notaController,
                    hint: 'Que cambio y por que',
                  ),
                ),
              ],
            ),
          ),
        ),
        AppFormFooter(
          onCancel: () => Navigator.of(context).pop(),
          onConfirm: _publicar,
          confirmText: _publicando ? 'Publicando...' : 'Publicar version',
          confirmIcon: Icons.publish_rounded,
        ),
      ],
    );
  }

  Widget _cabeceraVersion() {
    final v = _vigente;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(
            v == null ? Icons.note_add_outlined : Icons.history_rounded,
            size: 20,
            color: AppColors.iconMuted,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              v == null
                  ? 'Este documento todavia no tiene plantilla. Al publicar se '
                      'creara la version 1.'
                  : 'Vigente: version ${v.numero}'
                      '${v.creadaPor.isEmpty ? "" : ", por ${v.creadaPor}"}.'
                      ' Publicar crea la version ${v.numero + 1}; la actual se '
                      'conserva.',
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (_hayCambios) ...[
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: primario.withOpacity(0.12),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'SIN PUBLICAR',
                style: TextStyle(
                  color: primario,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _bloqueEditor() {
    return AppFormSection(
      title: 'Cuerpo del documento',
      icon: Icons.article_outlined,
      expandido: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          q.QuillSimpleToolbar(
            controller: _controller!,
            config: const q.QuillSimpleToolbarConfig(
              // Solo lo que el PDF sabe dibujar. Ofrecer colores o tamanos
              // arbitrarios seria prometer un formato que el documento no va a
              // respetar.
              showBoldButton: true,
              showItalicButton: true,
              showUnderLineButton: true,
              showListNumbers: true,
              showListBullets: true,
              showAlignmentButtons: true,
              showJustifyAlignment: true,
              showUndo: true,
              showRedo: true,
              showFontFamily: false,
              showFontSize: false,
              showColorButton: false,
              showBackgroundColorButton: false,
              showStrikeThrough: false,
              showInlineCode: false,
              showCodeBlock: false,
              showQuote: false,
              showLink: false,
              showSearchButton: false,
              showSubscript: false,
              showSuperscript: false,
              showClearFormat: true,
              showHeaderStyle: false,
              showIndent: false,
              showDividers: true,
              multiRowsDisplay: false,
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: q.QuillEditor.basic(
                controller: _controller!,
                focusNode: _focus,
                scrollController: _scroll,
                config: const q.QuillEditorConfig(
                  padding: EdgeInsets.zero,
                  placeholder: 'Escribe aqui el cuerpo del documento...',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bloqueVistaPrevia() {
    final p = _preview;
    final crecio =
        p != null && _paginasAlAbrir != null && p.paginas > _paginasAlAbrir!;

    return AppFormSection(
      title: 'Vista previa',
      icon: Icons.picture_as_pdf_outlined,
      expandido: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              _chipPaginas(p, crecio),
              const SizedBox(width: 10),
              if (_generandoPreview)
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              const Spacer(),
              const Text(
                'Con datos de ejemplo',
                style: TextStyle(
                  color: AppColors.textFaint,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          if (crecio) ...[
            const SizedBox(height: 10),
            _aviso(
              Icons.description_outlined,
              'El documento pasó de $_paginasAlAbrir a ${p.paginas} páginas.',
              Colors.orange.shade800,
              Colors.orange.shade50,
              Colors.orange.shade200,
            ),
          ],
          if (p != null && p.marcadoresSinValor.isNotEmpty) ...[
            const SizedBox(height: 10),
            _aviso(
              Icons.error_outline_rounded,
              'Campos que no existen y saldrán impresos tal cual: '
              '${p.marcadoresSinValor.join(", ")}',
              Colors.red.shade700,
              Colors.red.shade50,
              Colors.red.shade200,
            ),
          ],
          const SizedBox(height: 12),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceSunken,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              clipBehavior: Clip.antiAlias,
              child: p == null
                  ? const Center(child: CircularProgressIndicator())
                  : Padding(
                      padding: const EdgeInsets.all(14),
                      child: HojaPrevia(
                        parrafos: p.parrafos,
                        cabecera: (
                          datosDeEjemplo['empresa.nombre'] ?? '',
                          datosDeEjemplo['contrato.anio'] ?? '',
                        ),
                        pie: datosDeEjemplo['empresa.domicilio'] ?? '',
                        firmas: widget.tipo.firmas,
                        datos: datosDeEjemplo,
                        encabezadosTabla: widget.tipo.tabla,
                        filasTabla: _filas,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  /// Editor de la tabla del documento.
  ///
  /// `Derecho a saber` lleva una tabla de riesgos y `EPP` una de implementos.
  /// Son listas de registros, no prosa: se editan como filas y no dentro del
  /// editor de texto, donde manejar una tabla es una pelea constante.
  ///
  /// En el cuerpo se escribe [kMarcadorTabla] en la linea donde debe salir.
  Widget _bloqueTabla() {
    final cabeceras = widget.tipo.tabla ?? const <String>[];

    return AppFormSection(
      title: 'Tabla del documento',
      icon: Icons.table_rows_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Escribe $kMarcadorTabla en el cuerpo, en la linea donde quieras '
            'que salga esta tabla.',
            style: const TextStyle(
              color: AppColors.textFaint,
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              for (final c in cabeceras)
                Expanded(
                  flex: c == cabeceras.first ? 1 : 2,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Text(
                      c,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ),
                ),
              const SizedBox(width: 36),
            ],
          ),
          const SizedBox(height: 8),
          if (_filas.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 18),
              child: Text(
                'La tabla no tiene filas todavia.',
                style: TextStyle(
                  color: AppColors.textFaint,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          for (var i = 0; i < _filas.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var j = 0; j < cabeceras.length; j++)
                    Expanded(
                      flex: j == 0 ? 1 : 2,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: TextFormField(
                          initialValue:
                              j < _filas[i].length ? _filas[i][j] : '',
                          maxLines: null,
                          style: const TextStyle(
                            color: AppColors.textStrong,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w500,
                          ),
                          decoration: InputDecoration(
                            isDense: true,
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 10),
                            enabledBorder: OutlineInputBorder(
                              borderSide:
                                  const BorderSide(color: AppColors.border),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide:
                                  BorderSide(color: primario, width: 1.4),
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onChanged: (v) {
                            while (_filas[i].length < cabeceras.length) {
                              _filas[i].add('');
                            }
                            _filas[i][j] = v;
                            _programarPreview();
                            if (!_hayCambios) {
                              setState(() => _hayCambios = true);
                            }
                          },
                        ),
                      ),
                    ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, size: 19),
                    color: Colors.red.shade400,
                    tooltip: 'Quitar fila',
                    onPressed: () => setState(() {
                      _filas.removeAt(i);
                      _hayCambios = true;
                      _programarPreview();
                    }),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerLeft,
            child: CustomButton(
              funcion: () => setState(() {
                _filas.add(List<String>.filled(cabeceras.length, ''));
                _hayCambios = true;
                _programarPreview();
              }),
              texto: 'Agregar fila',
              cancelar: true,
              icon: Icons.add_rounded,
              width: 200,
            ),
          ),
        ],
      ),
    );
  }

  Widget _chipPaginas(VistaPreviaPlantilla? p, bool crecio) {
    final texto = p == null
        ? '...'
        : '${p.paginas} ${p.paginas == 1 ? "página" : "páginas"}';
    final color = crecio ? Colors.orange.shade800 : primario;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        texto.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
        ),
      ),
    );
  }

  Widget _aviso(
    IconData icono,
    String mensaje,
    Color texto,
    Color fondo,
    Color borde,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: fondo,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borde),
      ),
      child: Row(
        children: [
          Icon(icono, size: 18, color: texto),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              mensaje,
              style: TextStyle(
                color: texto,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bloqueMarcadores() {
    return AppFormSection(
      title: 'Campos que se rellenan solos',
      icon: Icons.data_object_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Toca uno para insertarlo donde este el cursor.',
            style: TextStyle(
              color: AppColors.textFaint,
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          for (final grupo in camposDePlantilla.entries) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                grupo.key.toUpperCase(),
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
            ),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final m in grupo.value)
                  InkWell(
                    borderRadius: BorderRadius.circular(4),
                    onTap: () => _insertarMarcador(m),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceSunken,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        m.etiqueta,
                        style: const TextStyle(
                          color: AppColors.textBody,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),
          ],
        ],
      ),
    );
  }
}

/// Abre el editor de una plantilla.
Future<void> abrirEditorDePlantilla(
  BuildContext context,
  TipoPlantilla tipo,
) {
  return showAppModal<void>(
    context: context,
    title: tipo.nombre,
    subtitle: 'Plantilla del documento',
    icon: Icons.edit_document,
    hint: 'Publicar crea una version nueva. Las anteriores se conservan, para '
        'que un documento ya emitido pueda reimprimirse tal como se firmo.',
    // El editor es la pantalla mas ancha de la app: tres columnas de trabajo
    // y una hoja carta a escala legible. El `insetPadding` del Dialog ya deja
    // el margen en pantallas chicas, asi que este tope solo actua en monitores
    // grandes.
    maxWidth: 1700,
    child: PlantillaEditor(tipo: tipo),
  );
}
