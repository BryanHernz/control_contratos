import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart' hide ModalBottomSheetRoute;
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:responsive_grid_list/responsive_grid_list.dart';

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

  @override
  void initState() {
    super.initState();
    // Escuchar cambios en el campo de búsqueda
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  // --- NUEVA FUNCIÓN: Normaliza una cadena quitando tildes y a minúsculas ---
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
        _displayedWorkers = _allWorkers; // Si la búsqueda está vacía, mostrar todos
      } else {
        // Filtrar por nombre o apellido (normalizados)
        _displayedWorkers = _allWorkers.where((worker) {
          final normalizedFullName = _normalizeString('${worker.name} ${worker.lastName}');
          return normalizedFullName.contains(query);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      floatingActionButton: FloatingActionButton(
        heroTag: null,
        tooltip: 'Nuevo Trabajador',
        onPressed: () {
          showCupertinoModalBottomSheet(
            context: context,
            builder: (context) => Container(
              constraints: const BoxConstraints(maxHeight: 750),
              child: const NewWorker(),
            ),
          );
        },
        child: const Icon(Icons.person_add_outlined),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      appBar: AppBar(
        title: _buildSearchBar(), // Barra de búsqueda en el AppBar
        backgroundColor: primario,
        centerTitle: true,
        toolbarHeight: 70,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15.0),
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('Trabajadores')
              .orderBy('nombres')
              .snapshots(),
          builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
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

            // Cuando llegan nuevos datos, actualizamos _allWorkers.
            // Luego, determinamos _displayedWorkers based on the current search query.
            final List<WorkerModel> fetchedWorkers = snapshot.data!.docs
                .map((doc) => WorkerModel.fromDocumentSnapshot(doc))
                .toList();

            // Solo actualiza _allWorkers si los datos han cambiado
            // Puedes usar una comparación más robusta si necesitas,
            // pero para este caso, la longitud es un buen primer filtro.
            if (_allWorkers.length != fetchedWorkers.length || !_listEquals(_allWorkers, fetchedWorkers)) { // Agregamos _listEquals para una comparación más profunda
                 _allWorkers = fetchedWorkers;
                 // Si los datos base han cambiado, necesitamos re-evaluar _displayedWorkers
                 final query = _normalizeString(_searchController.text); // Normalizar la consulta
                 if (query.isEmpty) {
                   _displayedWorkers = _allWorkers;
                 } else {
                   _displayedWorkers = _allWorkers.where((worker) {
                     final normalizedFullName = _normalizeString('${worker.name} ${worker.lastName}');
                     return normalizedFullName.contains(query);
                   }).toList();
                 }
            }


            if (_displayedWorkers.isEmpty && _searchController.text.isNotEmpty) {
              return const Center(
                child: Text('No existen coincidencias para su búsqueda'),
              );
            }

            if (_displayedWorkers.isEmpty && _searchController.text.isEmpty) {
               return const Center(
                child: Text('No hay trabajadores registrados. ¡Toca el botón "+" para añadir uno!'),
              );
            }

            return ResponsiveGridList(
              horizontalGridMargin: 0,
              verticalGridMargin: 10,
              minItemWidth: 400,
              children: List.generate(
                _displayedWorkers.length,
                (int index) {
                  final worker = _displayedWorkers[index]; // Usa el trabajador de la lista filtrada
                  return GestureDetector(
                    onTap: () {
                      showCupertinoModalBottomSheet(
                        context: context,
                        builder: (context) => Container(
                          constraints: const BoxConstraints(maxHeight: 600),
                          child: WorkerDetails(
                            worker: worker, // Pasa el objeto WorkerModel directamente
                          ),
                        ),
                      );
                    },
                    child: Card(
                      color: primario,
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  // No es necesario normalizar aquí para la visualización
                                  '${worker.name!.toUpperCase()} ${worker.lastName!.toUpperCase()}',
                                  maxLines: 2,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                                Text(
                                  worker.rut!.toUpperCase(),
                                  maxLines: 2,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Colors.white54,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  worker.place!.toUpperCase(),
                                  maxLines: 2,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Colors.white54,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }

  // Widget para la barra de búsqueda
  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0,),
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
          icon: Icon(Icons.search, color: Colors.white),
        ),
      ),
    );
  }

  // Función de utilidad para comparar si dos listas de WorkerModel son iguales
  // (útil para evitar re-filtrados innecesarios cuando los datos de Firestore no cambian)
  bool _listEquals(List<WorkerModel> list1, List<WorkerModel> list2) {
    if (list1.length != list2.length) {
      return false;
    }
    for (int i = 0; i < list1.length; i++) {
      // Asume que el ID es suficiente para identificar un WorkerModel único
      if (list1[i].id != list2[i].id) {
        return false;
      }
    }
    return true;
  }
}