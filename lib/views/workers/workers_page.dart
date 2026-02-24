import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import '../../services/pdf_contract_service.dart';
import '../../customs/constants_values.dart';
import '../../models/worker_model.dart';
import 'new_worker_page.dart';
import 'worker_details.dart';

class WorkersPage extends StatefulWidget {
  const WorkersPage({super.key});

  @override
  State<WorkersPage> createState() => _WorkersPageState();
}

class _WorkersPageState extends State<WorkersPage> {
  // Lista completa de trabajadores cargados desde Firestore
  List<WorkerModel> _allWorkers = [];
  // Lista de trabajadores que se muestra (filtrada o completa)
  List<WorkerModel> _displayedWorkers = [];
  // Controlador para el campo de texto de búsqueda
  final TextEditingController _searchController = TextEditingController();

  // Controladores para la lista posicionable
  final ItemScrollController itemScrollController = ItemScrollController();
  final ItemPositionsListener itemPositionsListener =
      ItemPositionsListener.create();

  // El alfabeto a mostrar en la barra lateral
  final List<String> alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZ".split('');

  // Letra actualmente visible o seleccionada
  String _currentLetter = 'A';

  // Filtros avanzados
  String _selectedEnterpriseFilter = 'Todas';
  String _selectedLaborFilter = 'Todos';
  String _selectedCommuneFilter = 'Todas';
  String _selectedNacionalityFilter = 'Todas';
  String _selectedAfpFilter = 'Todas';
  String _selectedPrevisionFilter = 'Todas';

  // Almacena los grupos actuales para el listener de scroll
  List<List<WorkerModel>> _currentGroupedWorkers = [];

  // --- SELECCIÓN MÚLTIPLE ---
  bool _isSelectionMode = false;
  Set<String> _selectedWorkerIds = {};

  // Para evitar que el listener de scroll sobreescriba la letra al hacer tap
  bool _isManualScrolling = false;

  late Stream<QuerySnapshot> _workersStream;

  @override
  void initState() {
    super.initState();
    // Escuchar cambios en el campo de búsqueda
    _searchController.addListener(_onSearchChanged);
    itemPositionsListener.itemPositions.addListener(_scrollListener);

    _workersStream = FirebaseFirestore.instance
        .collection('Trabajadores')
        .orderBy('nombres')
        .snapshots();
  }

  @override
  void dispose() {
    itemPositionsListener.itemPositions.removeListener(_scrollListener);
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  // --- ESCUCHADOR DE SCROLL PARA CAMBIAR LETRA ACTIVA ---
  void _scrollListener() {
    if (!mounted || _isManualScrolling) return;
    final positions = itemPositionsListener.itemPositions.value;
    if (positions.isNotEmpty) {
      // Encontrar el primer elemento visible
      final firstItem = positions
          .where((ItemPosition position) => position.itemTrailingEdge > 0)
          .reduce((ItemPosition min, ItemPosition position) =>
              position.itemLeadingEdge < min.itemLeadingEdge ? position : min);

      int visibleIndex = firstItem.index;
      if (visibleIndex >= 0 && visibleIndex < _currentGroupedWorkers.length) {
        // Obtener el primer trabajador de la fila visible
        WorkerModel firstWorkerInRow =
            _currentGroupedWorkers[visibleIndex].first;
        String firstLetter =
            _normalizeString(firstWorkerInRow.name ?? 'a')[0].toUpperCase();

        if (firstLetter != _currentLetter && alphabet.contains(firstLetter)) {
          setState(() {
            _currentLetter = firstLetter;
          });
        }
      }
    }
  } // --- NUEVA FUNCIÓN: Normaliza una cadena quitando tildes y a minúsculas ---

  String _normalizeString(String text) {
    return text
        .toLowerCase()
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('ü', 'u') // Para la diéresis
        .replaceAll('ñ', 'n'); // Para la eñe
  }

  // Método para filtrar la lista de trabajadores
  void _onSearchChanged() {
    // Normalizar la consulta de búsqueda
    final query = _normalizeString(_searchController.text);

    setState(() {
      if (query.isEmpty) {
        _displayedWorkers =
            _allWorkers; // Si la búsqueda está vacía, mostrar todos
      } else {
        // Filtrar por nombre o apellido (normalizados)
        _displayedWorkers = _allWorkers.where((worker) {
          final normalizedFullName =
              _normalizeString('${worker.name} ${worker.lastName}');
          return normalizedFullName.contains(query);
        }).toList();
      }
    });
  }

  // Función para hacer scroll a una letra
  void _scrollToLetter(
      String letter, List<List<WorkerModel>> groupedWorkers) async {
    setState(() {
      _currentLetter = letter;
      _isManualScrolling = true;
    });

    // Buscar la fila (grupo) que contenga un trabajador cuyo nombre inicie con esa letra
    for (int i = 0; i < groupedWorkers.length; i++) {
      // Obtenemos el listado de la fila actual
      final rowPlayers = groupedWorkers[i];

      // Verificamos si algún trabajador en esta fila empieza por la letra
      bool found = false;
      for (var worker in rowPlayers) {
        final normalizedName = _normalizeString(worker.name ?? '');
        if (normalizedName.startsWith(letter.toLowerCase())) {
          found = true;
          break;
        }
      }

      // Si lo encontramos, hacemos scroll a ese índice (la fila)
      if (found) {
        itemScrollController.jumpTo(index: i);
        // Esperar un breve momento para reactivar el listener tras el salto
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) {
            _isManualScrolling = false;
          }
        });
        return; // Salimos de la función
      }
    }

    // Si no encontró la letra, rehabilitar flag
    _isManualScrolling = false;
  }

  // --- FUNCIÓN PARA GENERAR CONTRATOS EN LOTE ---
  Future<void> _generateBatchContracts() async {
    if (_selectedWorkerIds.isEmpty) return;

    // Buscar los modelos completos de trabajadores elegidos
    final List<WorkerModel> selectedWorkers = _allWorkers
        .where((worker) => _selectedWorkerIds.contains(worker.id))
        .toList();

    // Invocar servicio
    await PdfContractService.generateBatchContracts(selectedWorkers);

    // Salir del modo de selección si lo deseas
    if (mounted) {
      setState(() {
        _isSelectionMode = false;
        _selectedWorkerIds.clear();
      });
    }
  }

  // --- FUNCIÓN PARA EXPORTAR TRABAJADORES MOSTRADOS A PDF ---
  Future<void> _exportToPDF() async {
    if (_displayedWorkers.isEmpty) return;

    final pdf = pw.Document();

    // Cargar fuentes
    var cambria = await rootBundle.load("lib/images/Cambria.ttf");
    var calibri = await rootBundle.load("lib/images/Calibri Regular.ttf");
    var calibriBold = await rootBundle.load("lib/images/Calibri Bold.ttf");

    // Configurar tabla
    final headers = ["RUT", "Nombres", "Cargo", "Ingreso", "Lugar", "Comuna"];

    final tableData = _displayedWorkers.map((worker) {
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
                      'Total de registros activos: ${_displayedWorkers.length}',
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
    return Scaffold(
      resizeToAvoidBottomInset: false,
      floatingActionButton: _isSelectionMode
          ? null // Esconder FAB en modo selección
          : FloatingActionButton(
              heroTag: null,
              tooltip: 'Nuevo Trabajador',
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.white,
                  shape: const RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(16)),
                  ),
                  builder: (context) => SizedBox(
                    height: MediaQuery.of(context).size.height * 0.9,
                    child: Column(
                      children: [
                        const SizedBox(height: 12),
                        Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.black12,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Expanded(
                          child: ClipRRect(
                            borderRadius:
                                BorderRadius.vertical(top: Radius.circular(16)),
                            child: NewWorker(),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
              child: const Icon(Icons.person_add_outlined),
            ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      appBar: _isSelectionMode
          ? AppBar(
              backgroundColor: primario,
              leading: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () {
                  setState(() {
                    _isSelectionMode = false;
                    _selectedWorkerIds.clear();
                  });
                },
              ),
              title: Text(
                '${_selectedWorkerIds.length} seleccionados',
                style: const TextStyle(color: Colors.white, fontSize: 18),
              ),
              actions: [
                if (_selectedWorkerIds.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
                    tooltip: 'Generar Contratos Lote',
                    onPressed: _generateBatchContracts,
                  ),
              ],
            )
          : AppBar(
              title: _buildSearchBar(), // Barra de búsqueda en el AppBar
              backgroundColor: primario,
              centerTitle: true,
              toolbarHeight: 80,
              actions: [
                Stack(
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
                const SizedBox(width: 8),
              ],
            ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15.0),
        child: StreamBuilder<QuerySnapshot>(
          stream: _workersStream,
          builder:
              (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Text('Error al cargar trabajadores: ${snapshot.error}'),
              );
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            // Cuando llegan nuevos datos, actualizamos _allWorkers incondicionalmente.
            final List<WorkerModel> fetchedWorkers = snapshot.data!.docs
                .map((doc) => WorkerModel.fromDocumentSnapshot(doc))
                .toList();

            // Siempre actualizamos _allWorkers con los datos más recientes
            _allWorkers = fetchedWorkers;

            // Aplicamos los filtros y búsqueda
            final query = _normalizeString(_searchController.text);

            _displayedWorkers = _allWorkers.where((worker) {
              // 1. Filtro de búsqueda por texto
              bool matchesSearch = true;
              if (query.isNotEmpty) {
                final normalizedFullName =
                    _normalizeString('${worker.name} ${worker.lastName}');
                matchesSearch = normalizedFullName.contains(query);
              }

              // 2. Filtro de empresa
              bool matchesEnterprise = _selectedEnterpriseFilter == 'Todas' ||
                  worker.place == _selectedEnterpriseFilter;

              // 3. Filtro de Cargo
              bool matchesLabor = _selectedLaborFilter == 'Todos' ||
                  worker.labor == _selectedLaborFilter;

              // 4. Filtro de Comuna
              bool matchesCommune = _selectedCommuneFilter == 'Todas' ||
                  worker.commune == _selectedCommuneFilter;

              // 5. Filtro de Nacionalidad
              bool matchesNacionality = _selectedNacionalityFilter == 'Todas' ||
                  worker.nacionality == _selectedNacionalityFilter;

              // 6. Filtro de AFP
              bool matchesAfp = _selectedAfpFilter == 'Todas' ||
                  worker.afp == _selectedAfpFilter;

              // 7. Filtro de Previsión
              bool matchesPrevision = _selectedPrevisionFilter == 'Todas' ||
                  worker.prevision == _selectedPrevisionFilter;

              return matchesSearch &&
                  matchesEnterprise &&
                  matchesLabor &&
                  matchesCommune &&
                  matchesNacionality &&
                  matchesAfp &&
                  matchesPrevision;
            }).toList();

            if (_displayedWorkers.isEmpty &&
                _searchController.text.isNotEmpty) {
              return const Center(
                child: Text('No existen coincidencias para su búsqueda'),
              );
            }

            if (_displayedWorkers.isEmpty && _searchController.text.isEmpty) {
              return const Center(
                child: Text(
                    'No hay trabajadores registrados. ¡Toca el botón "+" para añadir uno!'),
              );
            }

            // AGRUPAR LOS TRABAJADORES EN FILAS (SIMULANDO GRID)
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total Trabajadores: ${_displayedWorkers.length}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Colors.black54,
                          ),
                        ),
                        IconButton(
                          icon: Icon(CupertinoIcons.doc_on_clipboard,
                              color: primario),
                          tooltip: 'Exportar a PDF',
                          onPressed: () => _exportToPDF(),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      // Calcular cuantas tarjetas caben (mínimo 400 de ancho)
                      final double screenWidth = constraints.maxWidth;
                      int crossAxisCount = (screenWidth / 400).floor();
                      if (crossAxisCount < 1) crossAxisCount = 1;

                      // Crear filas
                      List<List<WorkerModel>> groupedWorkers = [];
                      for (int i = 0;
                          i < _displayedWorkers.length;
                          i += crossAxisCount) {
                        int end =
                            (i + crossAxisCount < _displayedWorkers.length)
                                ? i + crossAxisCount
                                : _displayedWorkers.length;
                        groupedWorkers.add(_displayedWorkers.sublist(i, end));
                      }

                      // Guardamos la referencia actual para el listener
                      _currentGroupedWorkers = groupedWorkers;

                      return Stack(
                        children: [
                          // ===== LISTA DE TRABAJADORES =====
                          Padding(
                            padding: EdgeInsets.only(
                                left: _searchController.text.isEmpty &&
                                        MediaQuery.of(context)
                                                .viewInsets
                                                .bottom ==
                                            0
                                    ? 20.0
                                    : 0.0), // Espacio dinámico para barra, solo si está vacía la búsqueda y el teclado cerrado
                            child: ScrollablePositionedList.builder(
                              itemCount: groupedWorkers.length,
                              itemScrollController: itemScrollController,
                              itemPositionsListener: itemPositionsListener,
                              itemBuilder: (context, index) {
                                final rowPlayers = groupedWorkers[index];

                                // Convertir el WorkersMode list a widgets de tarjeta
                                List<Widget> rowWidgets =
                                    rowPlayers.map((worker) {
                                  return Expanded(
                                    child: GestureDetector(
                                      onLongPress: () {
                                        setState(() {
                                          _isSelectionMode = true;
                                          // Toggle en LongPress
                                          if (_selectedWorkerIds
                                              .contains(worker.id)) {
                                            _selectedWorkerIds
                                                .remove(worker.id!);
                                          } else {
                                            _selectedWorkerIds.add(worker.id!);
                                          }
                                        });
                                      },
                                      onTap: () {
                                        if (_isSelectionMode) {
                                          setState(() {
                                            if (_selectedWorkerIds
                                                .contains(worker.id)) {
                                              _selectedWorkerIds
                                                  .remove(worker.id!);
                                            } else {
                                              _selectedWorkerIds
                                                  .add(worker.id!);
                                            }
                                          });
                                          return; // Bloquea la apertura del Modal detalle si estamos seleccionando
                                        }

                                        showModalBottomSheet(
                                          context: context,
                                          isScrollControlled: true,
                                          backgroundColor: Colors.white,
                                          shape: const RoundedRectangleBorder(
                                            borderRadius: BorderRadius.vertical(
                                                top: Radius.circular(16)),
                                          ),
                                          builder: (context) => SizedBox(
                                            height: MediaQuery.of(context)
                                                    .size
                                                    .height *
                                                0.9,
                                            child: Column(
                                              children: [
                                                const SizedBox(height: 12),
                                                Container(
                                                  width: 40,
                                                  height: 4,
                                                  decoration: BoxDecoration(
                                                    color: Colors.black12,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            2),
                                                  ),
                                                ),
                                                const SizedBox(height: 12),
                                                Expanded(
                                                  child: ClipRRect(
                                                    borderRadius:
                                                        const BorderRadius
                                                            .vertical(
                                                            top:
                                                                Radius.circular(
                                                                    16)),
                                                    child: WorkerDetails(
                                                        worker: worker),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                      child: Card(
                                        color: primario,
                                        margin: const EdgeInsets.all(
                                            5), // Margen estilo Grid
                                        shape: _isSelectionMode &&
                                                _selectedWorkerIds
                                                    .contains(worker.id)
                                            ? RoundedRectangleBorder(
                                                side: const BorderSide(
                                                    color: Colors.orangeAccent,
                                                    width: 3),
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              )
                                            : null,
                                        child: Padding(
                                          padding: const EdgeInsets.all(20),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.start,
                                            children: [
                                              if (_isSelectionMode)
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                          right: 12.0),
                                                  child: Icon(
                                                    _selectedWorkerIds
                                                            .contains(worker.id)
                                                        ? Icons.check_circle
                                                        : Icons.circle_outlined,
                                                    color: _selectedWorkerIds
                                                            .contains(worker.id)
                                                        ? Colors.orangeAccent
                                                        : Colors.white54,
                                                  ),
                                                ),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      '${worker.name!.toUpperCase()} ${worker.lastName!.toUpperCase()}',
                                                      maxLines: 2,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 18,
                                                      ),
                                                    ),
                                                    Text(
                                                      worker.rut!.toUpperCase(),
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style: const TextStyle(
                                                        color: Colors.white54,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 16,
                                                      ),
                                                    ),
                                                    Text(
                                                      worker.place!
                                                          .toUpperCase(),
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style: const TextStyle(
                                                        color: Colors.white54,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 16,
                                                      ),
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
                                }).toList();

                                // Completar la última fila con contenedores vacíos si hace falta (Grid Alignment)
                                while (rowWidgets.length < crossAxisCount) {
                                  rowWidgets.add(Expanded(child: Container()));
                                }

                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 10.0),
                                  child: Row(children: rowWidgets),
                                );
                              },
                            ),
                          ),

                          // ===== BARRA ALFABÉTICA LATERAL =====
                          if (_searchController.text.isEmpty &&
                              MediaQuery.of(context).viewInsets.bottom ==
                                  0) // Ocultar si hay búsqueda o si el teclado está abierto
                            Align(
                              alignment: Alignment.centerLeft,
                              child: GestureDetector(
                                onVerticalDragUpdate:
                                    (DragUpdateDetails details) {
                                  // Calcular letra basada en la posición Y
                                  RenderBox box =
                                      context.findRenderObject() as RenderBox;
                                  double localY = box
                                      .globalToLocal(details.globalPosition)
                                      .dy;

                                  // Estimamos el tamaño de la lista de letras
                                  double viewHeight = box.size.height;
                                  double letterHeight =
                                      viewHeight / alphabet.length;

                                  int index = (localY / letterHeight).floor();
                                  if (index >= 0 && index < alphabet.length) {
                                    String draggedLetter = alphabet[index];
                                    if (_currentLetter != draggedLetter) {
                                      _scrollToLetter(
                                          draggedLetter, groupedWorkers);
                                    }
                                  }
                                },
                                child: Container(
                                  width: 15,
                                  color: Colors
                                      .transparent, // Captura de gestos invisible encima de letras
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: alphabet.map((letter) {
                                      bool isActive = _currentLetter == letter;
                                      return GestureDetector(
                                        onTap: () => _scrollToLetter(
                                            letter, groupedWorkers),
                                        child: Container(
                                          height: 18,
                                          width: 18,
                                          decoration: BoxDecoration(
                                            color: isActive
                                                ? primario
                                                : Colors
                                                    .transparent, // Resalta en azul si es activa
                                            shape: BoxShape.circle,
                                          ),
                                          child: Center(
                                            child: Text(
                                              letter,
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: isActive
                                                    ? FontWeight.bold
                                                    : FontWeight.w500,
                                                color: isActive
                                                    ? Colors.white
                                                    : Colors.black54,
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ); // Fin Stack
                    },
                  ), // Fin LayoutBuilder
                ), // Fin Expanded
              ], // Fin children Column
            ); // Fin Column
          }, // Fin builder StreamBuilder
        ), // Fin StreamBuilder
      ), // Fin Padding
    ); // Fin Scaffold
  } // Fin Widget build

  // Widget para la barra de búsqueda
  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.only(
        left: 8.0,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2), // Color de fondo para la barra
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(color: Colors.white, fontSize: 18),
        decoration: const InputDecoration(
          hintText: 'Buscar por nombre o apellido...',
          hintStyle: TextStyle(color: Colors.white70),
          border: InputBorder.none,
          icon: Icon(CupertinoIcons.search, color: Colors.white),
        ),
      ),
    );
  }

  // --- MODAL DE FILTROS AVANZADOS ---
  void _showFilterSheet() {
    // Generamos las opciones únicas del modal con los datos actuales de la base
    Set<String> allEnterprises = {};
    Set<String> allLabors = {};
    Set<String> allCommunes = {};
    Set<String> allNacionalities = {};
    Set<String> allAfps = {};
    Set<String> allPrevisions = {};

    for (var worker in _allWorkers) {
      if (worker.place != null && worker.place!.isNotEmpty) {
        allEnterprises.add(worker.place!);
      }
      if (worker.labor != null && worker.labor!.isNotEmpty) {
        allLabors.add(worker.labor!);
      }
      if (worker.commune != null && worker.commune!.isNotEmpty) {
        allCommunes.add(worker.commune!);
      }
      if (worker.nacionality != null && worker.nacionality!.isNotEmpty) {
        allNacionalities.add(worker.nacionality!);
      }
      if (worker.afp != null && worker.afp!.isNotEmpty) {
        allAfps.add(worker.afp!);
      }
      if (worker.prevision != null && worker.prevision!.isNotEmpty) {
        allPrevisions.add(worker.prevision!);
      }
    }

    List<String> enterpriseList = ['Todas', ...allEnterprises.toList()..sort()];
    List<String> laborList = ['Todos', ...allLabors.toList()..sort()];
    List<String> communeList = ['Todas', ...allCommunes.toList()..sort()];
    List<String> nacionalityList = [
      'Todas',
      ...allNacionalities.toList()..sort()
    ];
    List<String> afpList = ['Todas', ...allAfps.toList()..sort()];
    List<String> previsionList = ['Todas', ...allPrevisions.toList()..sort()];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Filtros Avanzados',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const Divider(),
                    const SizedBox(height: 10),
                    const Text(
                      'Empresa / Lugar',
                      style:
                          TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                      ),
                      value: _selectedEnterpriseFilter,
                      isExpanded: true,
                      items: enterpriseList.map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (newValue) {
                        setModalState(() {
                          _selectedEnterpriseFilter = newValue!;
                        });
                        setState(() {
                          _selectedEnterpriseFilter = newValue!;
                        });
                      },
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Cargo / Especialidad',
                      style:
                          TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                      ),
                      value: _selectedLaborFilter,
                      isExpanded: true,
                      items: laborList.map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (newValue) {
                        setModalState(() {
                          _selectedLaborFilter = newValue!;
                        });
                        setState(() {
                          _selectedLaborFilter = newValue!;
                        });
                      },
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Comuna',
                      style:
                          TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                      ),
                      value: _selectedCommuneFilter,
                      isExpanded: true,
                      items: communeList.map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (newValue) {
                        setModalState(() {
                          _selectedCommuneFilter = newValue!;
                        });
                        setState(() {
                          _selectedCommuneFilter = newValue!;
                        });
                      },
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Nacionalidad',
                      style:
                          TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                      ),
                      value: _selectedNacionalityFilter,
                      isExpanded: true,
                      items: nacionalityList.map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (newValue) {
                        setModalState(() {
                          _selectedNacionalityFilter = newValue!;
                        });
                        setState(() {
                          _selectedNacionalityFilter = newValue!;
                        });
                      },
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Previsión de Salud',
                                style: TextStyle(
                                    fontWeight: FontWeight.w600, fontSize: 16),
                              ),
                              const SizedBox(height: 10),
                              DropdownButtonFormField<String>(
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10.0),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 12),
                                ),
                                value: _selectedPrevisionFilter,
                                isExpanded: true,
                                items: previsionList.map((String value) {
                                  return DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(value),
                                  );
                                }).toList(),
                                onChanged: (newValue) {
                                  setModalState(() {
                                    _selectedPrevisionFilter = newValue!;
                                  });
                                  setState(() {
                                    _selectedPrevisionFilter = newValue!;
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'AFP',
                                style: TextStyle(
                                    fontWeight: FontWeight.w600, fontSize: 16),
                              ),
                              const SizedBox(height: 10),
                              DropdownButtonFormField<String>(
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10.0),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 12),
                                ),
                                value: _selectedAfpFilter,
                                isExpanded: true,
                                items: afpList.map((String value) {
                                  return DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(value),
                                  );
                                }).toList(),
                                onChanged: (newValue) {
                                  setModalState(() {
                                    _selectedAfpFilter = newValue!;
                                  });
                                  setState(() {
                                    _selectedAfpFilter = newValue!;
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: primario, width: 2),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onPressed: () {
                              setModalState(() {
                                _selectedEnterpriseFilter = 'Todas';
                                _selectedLaborFilter = 'Todos';
                                _selectedCommuneFilter = 'Todas';
                                _selectedNacionalityFilter = 'Todas';
                                _selectedPrevisionFilter = 'Todas';
                                _selectedAfpFilter = 'Todas';
                              });
                              setState(() {
                                _selectedEnterpriseFilter = 'Todas';
                                _selectedLaborFilter = 'Todos';
                                _selectedCommuneFilter = 'Todas';
                                _selectedNacionalityFilter = 'Todas';
                                _selectedPrevisionFilter = 'Todas';
                                _selectedAfpFilter = 'Todas';
                              });
                              Navigator.pop(context);
                            },
                            child: Text('Limpiar',
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: primario)),
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
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            child: const Text('Aplicar Filtros',
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white)),
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
