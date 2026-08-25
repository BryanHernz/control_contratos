import 'package:animated_snack_bar/animated_snack_bar.dart';
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import '../../customs/app_colors.dart';
import '../../customs/widgets/app_form.dart';
import '../../customs/widgets/app_modal.dart';
import '../../customs/widgets/app_skeleton.dart';
import '../../customs/constants_values.dart';
import '../../models/worker_model.dart';
import '../../customs/widgets/page_header.dart';
import '../home/dashboard_page.dart' show kDashboardMaxWidth;
import 'new_worker_page.dart';
import 'worker_details.dart';
import '../../services/firestore_db.dart';
import '../../services/trabajadores_repo.dart';
import '../../utils/normalize.dart';

class WorkersPage extends StatefulWidget {
  const WorkersPage({super.key});

  @override
  State<WorkersPage> createState() => WorkersPageState();
}

class WorkersPageState extends State<WorkersPage> {
  /// Los trabajadores cargados hasta ahora, pagina a pagina.
  ///
  /// Antes esto eran DOS listas: `_allWorkers` con los 674 documentos de la
  /// coleccion completa, y `aExportar` con el resultado de filtrarlos
  /// en memoria. Cada visita a la pantalla costaba 674 lecturas y, por venir de
  /// un `.snapshots()`, quedaba escuchando cambios. Ahora se piden de a 50 y
  /// buscar y filtrar son consultas.
  List<WorkerModel> _workers = [];

  final TextEditingController _searchController = TextEditingController();

  final ItemScrollController itemScrollController = ItemScrollController();
  final ItemPositionsListener itemPositionsListener =
      ItemPositionsListener.create();

  final List<String> alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZ".split('');

  /// Letra resaltada en la barra lateral.
  String _currentLetter = 'A';

  // Filtros avanzados. `Todas`/`Todos` significa "sin filtrar".
  String _selectedEnterpriseFilter = 'Todas';
  String _selectedLaborFilter = 'Todos';
  String _selectedCommuneFilter = 'Todas';
  String _selectedNacionalityFilter = 'Todas';
  String _selectedAfpFilter = 'Todas';
  String _selectedPrevisionFilter = 'Todas';

  /// Cursor de la ultima pagina traida.
  DocumentSnapshot? _cursor;
  bool _hayMas = true;
  bool _cargando = true;
  bool _cargandoMas = false;
  String? _error;

  /// Cuantos hay en total con los filtros actuales.
  ///
  /// Sale de una agregacion `count()`, no de contar la lista: la lista solo
  /// tiene lo que se ha ido cargando.
  int? _total;

  /// Espera a que el usuario deje de teclear antes de consultar.
  Timer? _debounce;

  /// Opciones de los desplegables de filtro, por documento de `Otros`.
  Map<String, List<String>> _catalogos = {};

  /// Trae los catalogos una vez. Son seis documentos, no seiscientos.
  Future<void> _cargarCatalogos() async {
    const docs = [
      'lugares',
      'labores',
      'comunas',
      'nacionalidades',
      'afps',
      'previsiones',
    ];
    final resultado = <String, List<String>>{};
    for (final d in docs) {
      try {
        final snap = await db.collection('Otros').doc(d).get();
        final tipos = (snap.data()?['tipos'] as List?) ?? const [];
        resultado[d] = tipos.map((e) => e.toString()).toList();
      } catch (_) {
        resultado[d] = const [];
      }
    }
    if (mounted) setState(() => _catalogos = resultado);
  }

  FiltrosTrabajadores get _filtros => FiltrosTrabajadores(
        empresa: _selectedEnterpriseFilter == 'Todas'
            ? null
            : _selectedEnterpriseFilter,
        labor: _selectedLaborFilter == 'Todos' ? null : _selectedLaborFilter,
        comuna:
            _selectedCommuneFilter == 'Todas' ? null : _selectedCommuneFilter,
        nacionalidad: _selectedNacionalityFilter == 'Todas'
            ? null
            : _selectedNacionalityFilter,
        afp: _selectedAfpFilter == 'Todas' ? null : _selectedAfpFilter,
        prevision: _selectedPrevisionFilter == 'Todas'
            ? null
            : _selectedPrevisionFilter,
        busqueda: _searchController.text,
      );

  bool get _hayFiltrosActivos =>
      _selectedEnterpriseFilter != 'Todas' ||
      _selectedLaborFilter != 'Todos' ||
      _selectedCommuneFilter != 'Todas' ||
      _selectedNacionalityFilter != 'Todas' ||
      _selectedAfpFilter != 'Todas' ||
      _selectedPrevisionFilter != 'Todas';

  Future<void> _openNewWorker() => showAppModal(
        context: context,
        title: 'Nuevo trabajador',
        subtitle: 'Ficha de ingreso',
        icon: Icons.person_add_rounded,
        child: const NewWorker(),
      );

  /// El detalle trae su propia cabecera (avatar, editar, eliminar), asi que va
  /// sin `title`: el modal solo lo recorta y lo acota.
  ///
  /// Mas angosto que el ancho por defecto (920): con la informacion personal y
  /// la laboral en dos columnas, el contenido se compacta y 920 dejaba mucho
  /// blanco.
  Future<void> _openWorkerDetails(WorkerModel worker) => showAppModal(
        context: context,
        maxWidth: 780,
        child: WorkerDetails(worker: worker),
      );

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    itemPositionsListener.itemPositions.addListener(_alVerPosiciones);
    _recargar();
    _cargarCatalogos();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    itemPositionsListener.itemPositions.removeListener(_alVerPosiciones);
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  /// Vuelve a empezar: primera pagina con los filtros actuales.
  ///
  /// [desdeInclusivo] permite arrancar en un documento concreto, que es lo que
  /// usa el salto por letra.
  Future<void> _recargar({DocumentSnapshot? desdeInclusivo}) async {
    setState(() {
      _cargando = true;
      _error = null;
      _workers = [];
      _cursor = null;
      _hayMas = true;
    });

    try {
      final filtros = _filtros;
      final pagina = await TrabajadoresRepo.pagina(
        filtros,
        desdeInclusivo: desdeInclusivo,
      );
      final total = await TrabajadoresRepo.total(filtros);
      if (!mounted) return;
      setState(() {
        _workers = pagina.trabajadores;
        _cursor = pagina.ultimo;
        _hayMas = pagina.hayMas;
        _total = total;
        _cargando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _cargando = false;
      });
    }
  }

  /// Trae la pagina siguiente y la agrega al final.
  Future<void> _cargarMas() async {
    if (_cargandoMas || !_hayMas || _cursor == null) return;
    setState(() => _cargandoMas = true);

    try {
      final pagina = await TrabajadoresRepo.pagina(_filtros, desde: _cursor);
      if (!mounted) return;
      setState(() {
        _workers = [..._workers, ...pagina.trabajadores];
        _cursor = pagina.ultimo;
        _hayMas = pagina.hayMas;
        _cargandoMas = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _cargandoMas = false);
    }
  }

  /// Cuantas tarjetas entran por fila. Lo fija el `LayoutBuilder` al construir.
  int _porFila = 1;
  int get _filasTotales => (_workers.length / _porFila).ceil();

  /// Reacciona al scroll: resalta la letra visible y pide mas al acercarse al
  /// final de lo cargado.
  void _alVerPosiciones() {
    if (!mounted) return;
    final posiciones = itemPositionsListener.itemPositions.value;
    if (posiciones.isEmpty) return;

    final ultimoVisible =
        posiciones.map((p) => p.index).reduce((a, b) => a > b ? a : b);
    if (_hayMas && !_cargandoMas && ultimoVisible >= _filasTotales - 3) {
      _cargarMas();
    }

    var primero = posiciones.first.index;
    for (final p in posiciones) {
      if (p.itemTrailingEdge > 0 && p.index < primero) primero = p.index;
    }

    final indice = primero * _porFila;
    if (indice < 0 || indice >= _workers.length) return;
    final nombre = normalize(_workers[indice].name ?? '');
    if (nombre.isEmpty) return;
    final letra = nombre.substring(0, 1).toUpperCase();
    if (letra != _currentLetter && alphabet.contains(letra)) {
      setState(() => _currentLetter = letra);
    }
  }

  void _onSearchChanged() {
    // Con retardo: cada tecla seria una consulta a Firestore.
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (mounted) _recargar();
    });
  }

  /// Salta a la primera ficha cuyo nombre empieza con [letra].
  ///
  /// Antes recorria la lista completa en memoria buscando la posicion. Ahora
  /// es una consulta de un documento que devuelve el cursor desde donde
  /// recargar.
  Future<void> _scrollToLetter(String letra) async {
    setState(() => _currentLetter = letra);
    try {
      final cursor = await TrabajadoresRepo.cursorDeLetra(letra);
      if (!mounted || cursor == null) return;
      await _recargar(desdeInclusivo: cursor);
      if (mounted && itemScrollController.isAttached) {
        itemScrollController.jumpTo(index: 0);
      }
    } catch (_) {
      // Un salto que falla no puede tumbar la pantalla.
    }
  }

  /// Exporta a PDF **todos** los que cumplen los filtros, no solo los que
  /// estan cargados en pantalla.
  ///
  /// Con paginacion, exportar lo que hay en memoria daria un PDF de 50 lineas
  /// aunque el filtro devuelva 600. Aqui se recorren todas las paginas a
  /// proposito: es una accion explicita del usuario, no algo que pase al
  /// entrar a la pantalla.
  Future<void> exportToPDF() async {
    if (_workers.isEmpty) return;

    final filtros = _filtros;
    final todos = <WorkerModel>[];
    DocumentSnapshot? cursor;
    var quedan = true;

    try {
      while (quedan && todos.length < 5000) {
        final pagina = await TrabajadoresRepo.pagina(
          filtros,
          desde: cursor,
          limite: 200,
        );
        todos.addAll(pagina.trabajadores);
        cursor = pagina.ultimo;
        quedan = pagina.hayMas && cursor != null;
      }
    } catch (e) {
      if (!mounted) return;
      AnimatedSnackBar.material(
        'No se pudo armar el listado: $e',
        type: AnimatedSnackBarType.error,
      ).show(context);
      return;
    }

    if (todos.isEmpty) return;
    final aExportar = todos;

    final pdf = pw.Document();

    // Cargar fuentes
    var cambria = await rootBundle.load("lib/images/Cambria.ttf");
    var calibri = await rootBundle.load("lib/images/Calibri Regular.ttf");
    var calibriBold = await rootBundle.load("lib/images/Calibri Bold.ttf");

    // Configurar tabla
    final headers = ["RUT", "Nombres", "Cargo", "Ingreso", "Lugar", "Comuna"];

    final tableData = aExportar.map((worker) {
      return [
        worker.rut ?? '',
        '${worker.name ?? ''} ${worker.lastName ?? ''}'.toUpperCase(),
        worker.labor?.toUpperCase() ?? '',
        worker.ingress ?? '',
        worker.place?.toUpperCase() ?? '',
        worker.commune?.toUpperCase() ?? '',
      ];
    }).toList();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        maxPages: 1000,
        margin: const pw.EdgeInsets.all(30),
        header: (pw.Context context) {
          return pw.Container(
            margin: const pw.EdgeInsets.only(bottom: 20),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Container(
                  width: 5,
                  height: 40,
                  color: PdfColor.fromHex('#455A64'),
                  margin: const pw.EdgeInsets.only(right: 15),
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'REPORTE GENERAL DE TRABAJADORES',
                      style: pw.TextStyle(
                        font: pw.Font.ttf(cambria),
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 16,
                        color: PdfColor.fromHex('#455A64'),
                      ),
                    ),
                    pw.Text(
                      'Total de registros activos: ${aExportar.length}',
                      style: pw.TextStyle(
                        font: pw.Font.ttf(calibri),
                        fontSize: 11,
                        color: PdfColors.grey700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
        footer: (pw.Context context) {
          return pw.Container(
            alignment: pw.Alignment.centerRight,
            margin: const pw.EdgeInsets.only(top: 10),
            child: pw.Text(
              'Página ${context.pageNumber} de ${context.pagesCount}',
              style: pw.TextStyle(
                font: pw.Font.ttf(calibri),
                fontSize: 10,
                color: PdfColors.grey600,
              ),
            ),
          );
        },
        build: (pw.Context context) {
          return [
            pw.TableHelper.fromTextArray(
              headers: headers,
              data: tableData,
              border: pw.TableBorder.all(color: PdfColors.grey300),
              headerStyle: pw.TextStyle(
                font: pw.Font.ttf(calibriBold),
                color: PdfColors.white,
                fontSize: 10,
              ),
              headerDecoration:
                  pw.BoxDecoration(color: PdfColor.fromHex('#455A64')),
              cellStyle: pw.TextStyle(
                font: pw.Font.ttf(calibri),
                fontSize: 9,
              ),
              cellAlignment: pw.Alignment.centerLeft,
              columnWidths: {
                0: const pw.FixedColumnWidth(60), // RUT
                1: const pw.FlexColumnWidth(3.5), // Nombres
                2: const pw.FlexColumnWidth(2), // Cargo
                3: const pw.FixedColumnWidth(55), // Ingreso
                4: const pw.FlexColumnWidth(2), // Lugar
                5: const pw.FlexColumnWidth(1.5), // Comuna
              },
            ),
          ];
        },
      ),
    );

    try {
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
        name: 'Reporte_Trabajadores.pdf',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al generar PDF: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isDesktop = MediaQuery.of(context).size.width >= 800;
    return Scaffold(
      backgroundColor: AppColors.background,
      resizeToAvoidBottomInset: false,
      floatingActionButton: FloatingActionButton(
        heroTag: null,
        tooltip: 'Nuevo Trabajador',
        onPressed: () => _openNewWorker(),
        child: const Icon(Icons.person_add_outlined),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: Column(
        children: [
          PageHeader(
            title: 'Trabajadores',
            subtitle: 'Directorio y gestión del personal',
            icon: Icons.people_alt_rounded,
            rightWidget: Stack(
              alignment: Alignment.center,
              children: [
                IconButton(
                  icon: const Icon(CupertinoIcons.slider_horizontal_3,
                      color: Colors.white),
                  tooltip: 'Filtros Avanzados',
                  onPressed: () => _showFilterSheet(),
                ),
                if (_selectedEnterpriseFilter != 'Todas' ||
                    _selectedLaborFilter != 'Todos' ||
                    _selectedCommuneFilter != 'Todas' ||
                    _selectedNacionalityFilter != 'Todas' ||
                    _selectedAfpFilter != 'Todas' ||
                    _selectedPrevisionFilter != 'Todas')
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: Colors.amberAccent,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            bottomWidget: _buildSearchBar(),
          ),
          Expanded(
            // Mismo tope de ancho que el dashboard: en un monitor ancho se
            // llegaban a poner cinco fichas por fila y el listado se volvia
            // dificil de recorrer. Bajo ese ancho no cambia nada.
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: kDashboardMaxWidth),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15.0),
                  child: Builder(
                    builder: (context) {
                      if (_cargando) {
                        // Esqueleto con la forma de las fichas: reserva el
                        // espacio y evita el salto de un circulito a un
                        // listado completo.
                        return const Padding(
                          padding: EdgeInsets.only(top: 12),
                          child: SkeletonTarjetas(filas: 5),
                        );
                      }

                      if (_error != null) {
                        // Firestore devuelve un mensaje crudo con un enlace
                        // para crear el indice; a quien usa la app no le dice
                        // nada. Se traduce a los dos casos que de verdad
                        // pasan.
                        final e = _error!.toLowerCase();
                        final construyendo = e.contains('currently building') ||
                            e.contains('being built');
                        final faltaIndice = e.contains('index');

                        return AppEmptyNotice(
                          icon: construyendo
                              ? Icons.hourglass_top_rounded
                              : Icons.cloud_off_rounded,
                          message: construyendo
                              ? 'La busqueda todavia se esta preparando.'
                              : faltaIndice
                                  ? 'Esta combinacion de filtros no esta '
                                      'disponible.'
                                  : 'No se pudo cargar el listado.',
                          detail: construyendo
                              ? 'Firestore esta construyendo el indice de '
                                  'busqueda. Suele tardar unos minutos; el '
                                  'listado sin buscar funciona igual.'
                              : faltaIndice
                                  ? 'Falta declarar el indice en '
                                      'firestore.indexes.json.'
                                  : 'Revisa la conexion y vuelve a intentar.',
                          actionLabel: 'Reintentar',
                          actionIcon: Icons.refresh_rounded,
                          onAction: _recargar,
                        );
                      }

                      if (_workers.isEmpty) {
                        final buscando = _searchController.text.isNotEmpty;
                        return AppEmptyNotice(
                          icon: buscando || _hayFiltrosActivos
                              ? Icons.search_off_rounded
                              : Icons.people_outline_rounded,
                          message: buscando
                              ? 'Ningun trabajador coincide con la busqueda.'
                              : _hayFiltrosActivos
                                  ? 'Ningun trabajador cumple los filtros.'
                                  : 'Todavia no hay trabajadores.',
                          detail: buscando
                              ? 'Se busca por nombre, apellido o RUT, desde '
                                  'el principio del texto.'
                              : _hayFiltrosActivos
                                  ? 'Prueba quitando alguno.'
                                  : 'Toca el boton + para agregar el primero.',
                        );
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  // El total sale de un `count()`, no de la
                                  // lista: la lista solo tiene lo cargado.
                                  _total == null
                                      ? 'Mostrando ${_workers.length}'
                                      : 'Mostrando ${_workers.length} de '
                                          '$_total',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textBody,
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(CupertinoIcons.doc_on_clipboard,
                                      color: primario),
                                  tooltip: 'Exportar a PDF',
                                  onPressed: () => exportToPDF(),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                int crossAxisCount =
                                    (constraints.maxWidth / 400).floor();
                                if (crossAxisCount < 1) crossAxisCount = 1;
                                _porFila = crossAxisCount;

                                final groupedWorkers = <List<WorkerModel>>[];
                                for (var i = 0;
                                    i < _workers.length;
                                    i += crossAxisCount) {
                                  final end = (i + crossAxisCount)
                                      .clamp(0, _workers.length);
                                  groupedWorkers.add(_workers.sublist(i, end));
                                }

                                // Una fila extra al final para el indicador de
                                // "cargando mas".
                                final filas =
                                    groupedWorkers.length + (_hayMas ? 1 : 0);

                                return Stack(
                                  children: [
                                    Padding(
                                      padding: EdgeInsets.only(
                                        left: !isDesktop &&
                                                _searchController.text.isEmpty
                                            ? 20.0
                                            : 0.0,
                                        right: isDesktop &&
                                                _searchController.text.isEmpty
                                            ? 20.0
                                            : 0.0,
                                      ),
                                      child: ScrollablePositionedList.builder(
                                        itemCount: filas,
                                        itemScrollController:
                                            itemScrollController,
                                        itemPositionsListener:
                                            itemPositionsListener,
                                        itemBuilder: (context, index) {
                                          if (index >= groupedWorkers.length) {
                                            return const Padding(
                                              padding: EdgeInsets.symmetric(
                                                  vertical: 20),
                                              child: Center(
                                                child: SizedBox(
                                                  width: 22,
                                                  height: 22,
                                                  child:
                                                      CircularProgressIndicator(
                                                          strokeWidth: 2),
                                                ),
                                              ),
                                            );
                                          }

                                          final fila = groupedWorkers[index];
                                          final widgets = <Widget>[
                                            for (final worker in fila)
                                              Expanded(
                                                child: GestureDetector(
                                                  onTap: () =>
                                                      _openWorkerDetails(
                                                          worker),
                                                  child: _WorkerCard(
                                                      worker: worker),
                                                ),
                                              ),
                                            for (var i = fila.length;
                                                i < crossAxisCount;
                                                i++)
                                              const Expanded(
                                                  child: SizedBox.shrink()),
                                          ];

                                          return Padding(
                                            padding: const EdgeInsets.only(
                                                bottom: 10.0),
                                            child: Row(children: widgets),
                                          );
                                        },
                                      ),
                                    ),

                                    // ===== BARRA ALFABETICA LATERAL =====
                                    //
                                    // Se esconde al buscar: con una busqueda
                                    // activa el orden es por relevancia de
                                    // prefijo, no alfabetico, y saltar a una
                                    // letra no tendria sentido.
                                    if (_searchController.text.isEmpty &&
                                        !_hayFiltrosActivos &&
                                        MediaQuery.of(context)
                                                .viewInsets
                                                .bottom ==
                                            0)
                                      Align(
                                        alignment: isDesktop
                                            ? Alignment.centerRight
                                            : Alignment.centerLeft,
                                        child: Container(
                                          width: 18,
                                          color: Colors.transparent,
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceEvenly,
                                            children: alphabet.map((letter) {
                                              final isActive =
                                                  _currentLetter == letter;
                                              return GestureDetector(
                                                onTap: () =>
                                                    _scrollToLetter(letter),
                                                child: Container(
                                                  height: 18,
                                                  width: 18,
                                                  decoration: BoxDecoration(
                                                    color: isActive
                                                        ? primario
                                                        : Colors.transparent,
                                                    shape: BoxShape.circle,
                                                  ),
                                                  child: Center(
                                                    child: Text(
                                                      letter,
                                                      style: TextStyle(
                                                        fontSize: 12.5,
                                                        fontWeight: isActive
                                                            ? FontWeight.w800
                                                            : FontWeight.w700,
                                                        color: isActive
                                                            ? Colors.white
                                                            : AppColors
                                                                .textMuted,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              );
                                            }).toList(),
                                          ),
                                        ),
                                      ),
                                  ],
                                );
                              },
                            ),
                          ),
                        ],
                      );
                    },
                  ), // Fin Builder
                ), // Fin Padding
              ), // Fin ConstrainedBox
            ), // Fin Center
          ), // Fin Expanded
        ], // Fin children Column
      ), // Fin Column
    ); // Fin Scaffold
  } // Fin Widget build

  // Widget para la barra de búsqueda
  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.only(left: 12.0),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(color: Colors.white, fontSize: 18),
        decoration: const InputDecoration(
          hintText: 'Buscar por nombre, apellido o RUT...',
          hintStyle: TextStyle(color: Colors.white70),
          border: InputBorder.none,
          icon: Icon(CupertinoIcons.search, color: Colors.white),
        ),
      ),
    );
  }

  // --- MODAL DE FILTROS AVANZADOS ---
  void _showFilterSheet() {
    // Las opciones salen de los catalogos de Ajustes, no de recorrer los
    // trabajadores cargados: con paginacion solo habria 50 en memoria y el
    // desplegable mostraria un puñado de valores al azar. Ademas los catalogos
    // son la fuente correcta -- ahi es donde se definen.
    List<String> options(String todos, List<String> values) =>
        [todos, ...values..sort()];

    final enterpriseList = options('Todas', _catalogos['lugares'] ?? const []);
    final laborList = options('Todos', _catalogos['labores'] ?? const []);
    final communeList = options('Todas', _catalogos['comunas'] ?? const []);
    final nacionalityList =
        options('Todas', _catalogos['nacionalidades'] ?? const []);
    final afpList = options('Todas', _catalogos['afps'] ?? const []);
    final previsionList =
        options('Todas', _catalogos['previsiones'] ?? const []);

    void resetAll(StateSetter setModalState) {
      void apply() {
        _selectedEnterpriseFilter = 'Todas';
        _selectedLaborFilter = 'Todos';
        _selectedCommuneFilter = 'Todas';
        _selectedNacionalityFilter = 'Todas';
        _selectedPrevisionFilter = 'Todas';
        _selectedAfpFilter = 'Todas';
      }

      setModalState(apply);
      setState(apply);
      // Los filtros ahora son parte de la consulta, no un recorrido en
      // memoria: cambiarlos exige volver a preguntar.
      _recargar();
    }

    showAppModal(
      context: context,
      title: 'Filtros avanzados',
      subtitle: 'Acota el listado de trabajadores',
      icon: Icons.tune_rounded,
      child: StatefulBuilder(
        builder: (context, setModalState) {
          Widget filtro(
            String label,
            String value,
            List<String> items,
            void Function(String) onPick,
          ) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: AppColors.textBody,
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                  ),
                  value: value,
                  isExpanded: true,
                  items: items
                      .map((v) =>
                          DropdownMenuItem<String>(value: v, child: Text(v)))
                      .toList(),
                  onChanged: (newValue) {
                    if (newValue == null) return;
                    setModalState(() => onPick(newValue));
                    setState(() => onPick(newValue));
                    _recargar();
                  },
                ),
              ],
            );
          }

          return AppModalBody(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // En el modal centrado caben 2-3 columnas; en el telefono, 1.
                AppModalFieldGrid(
                  children: [
                    filtro('Empresa / Lugar', _selectedEnterpriseFilter,
                        enterpriseList, (v) => _selectedEnterpriseFilter = v),
                    filtro('Labor', _selectedLaborFilter, laborList,
                        (v) => _selectedLaborFilter = v),
                    filtro('Comuna', _selectedCommuneFilter, communeList,
                        (v) => _selectedCommuneFilter = v),
                    filtro('Nacionalidad', _selectedNacionalityFilter,
                        nacionalityList, (v) => _selectedNacionalityFilter = v),
                    filtro('Prevision', _selectedPrevisionFilter, previsionList,
                        (v) => _selectedPrevisionFilter = v),
                    filtro('AFP', _selectedAfpFilter, afpList,
                        (v) => _selectedAfpFilter = v),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () {
                          resetAll(setModalState);
                          Navigator.pop(context);
                        },
                        child: Text(
                          'Limpiar',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: primario,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primario,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () => Navigator.pop(context),
                        child: const Text(
                          'Aplicar Filtros',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ── Worker card ───────────────────────────────────────────────────────────
class _WorkerCard extends StatelessWidget {
  final dynamic worker; // WorkerModel
  const _WorkerCard({required this.worker});

  @override
  Widget build(BuildContext context) {
    final name = (worker.name ?? '').toString();
    final lastName = (worker.lastName ?? '').toString();
    final rut = (worker.rut ?? '').toString();
    final place = (worker.place ?? '').toString();
    final labor = (worker.labor ?? '').toString();
    final isActive = worker.activo == true;

    // Generate initials from name + lastName
    final nameParts = name.trim().split(' ');
    final lastParts = lastName.trim().split(' ');
    final initials =
        '${nameParts.isNotEmpty && nameParts[0].isNotEmpty ? nameParts[0][0] : ''}${lastParts.isNotEmpty && lastParts[0].isNotEmpty ? lastParts[0][0] : ''}'
            .toUpperCase();

    return Container(
      margin: const EdgeInsets.all(5),
      decoration: appCardDecoration(radius: 14),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Stack(
          children: [
            // Left accent bar
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: Container(
                width: 5,
                color: primario,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
              child: Row(
                children: [
                  // Initials avatar
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: primario,
                    child: Text(
                      initials.isNotEmpty ? initials : '?',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  // Name + metadata
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$name $lastName'.toUpperCase(),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.blueGrey.shade900,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          rut.toUpperCase(),
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            if (place.isNotEmpty)
                              Flexible(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    // Al 8% el chip era practicamente
                                    // invisible; con 14% se lee como chip sin
                                    // pelear con el nombre.
                                    color: primario.withOpacity(0.14),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    place.toString().toUpperCase(),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      color: primario,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                            if (place.isNotEmpty && labor.isNotEmpty)
                              const SizedBox(width: 6),
                            if (labor.isNotEmpty)
                              Flexible(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: Colors.teal.withOpacity(0.14),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    labor.toString().toUpperCase(),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      color: Colors.teal.shade800,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Status dot
                  Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: isActive
                              ? Colors.green.shade400
                              : Colors.grey.shade300,
                          shape: BoxShape.circle,
                          boxShadow: isActive
                              ? [
                                  BoxShadow(
                                    color: Colors.green.withOpacity(0.4),
                                    blurRadius: 4,
                                    spreadRadius: 1,
                                  ),
                                ]
                              : null,
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
    );
  }
}
