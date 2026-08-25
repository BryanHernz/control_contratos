// ignore_for_file: empty_catches

import 'package:animated_snack_bar/animated_snack_bar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:rut_utils/rut_utils.dart';
import 'package:spelling_number/spelling_number.dart';

import '../../customs/app_colors.dart';
import '../home/dashboard_page.dart' show kDashboardMaxWidth;
import '../../customs/widgets/app_form.dart';
import '../../customs/widgets/app_modal.dart';
import '../../customs/constants_values.dart';
import '../../customs/widgets_custom.dart';
import '../../customs/widgets/page_header.dart';
import '../plantillas/plantilla_editor.dart';
import '../../services/plantilla_service.dart';
import '../widgets/settings_dialogs.dart';
import '../../services/firestore_db.dart';

class ContractPage extends StatefulWidget {
  const ContractPage({super.key});

  @override
  State<ContractPage> createState() => _ContractPageState();
}

class _ContractPageState extends State<ContractPage> {
  /// Envoltura fina sobre [showAppModal]: esta pantalla abre varios modales de
  /// ajustes y todos comparten forma.
  Future<void> _openStyledSettingsSheet({
    required BuildContext context,
    required String title,
    required IconData icon,
    required Widget child,
    String? hint,
    double maxWidth = kModalMaxWidth,
    bool danger = false,
  }) {
    return showAppModal<void>(
      context: context,
      title: title,
      icon: icon,
      hint: hint,
      danger: danger,
      maxWidth: maxWidth,
      child: child,
    );
  }

  /// Cabecera de la vista.
  ///
  /// En escritorio va fija arriba; en el telefono entra al scroll, porque la
  /// pantalla es corta y no vale gastar espacio permanente en repetir donde
  /// estas.
  static const _cabecera = PageHeader(
    title: 'Ajustes y Parámetros',
    subtitle: 'Configuración de datos base del sistema',
    icon: Icons.settings_rounded,
  );

  @override
  Widget build(BuildContext context) {
    final compacta = MediaQuery.sizeOf(context).width < 800;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!compacta) _cabecera,
          Expanded(
            // Mismo tope de ancho que el resto de las vistas.
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: kDashboardMaxWidth),
                child: SingleChildScrollView(
                  // Sin padding propio: la cabecera compacta va a sangre y el
                  // margen lo pone el contenido. Con el padding aqui, el
                  // header quedaba con dos franjas claras a los lados.
                  padding: EdgeInsets.zero,
                  child: StreamBuilder(
                    stream: db.collection('Otros').where('nombre', whereIn: [
                      'contratosmont',
                      'empresadata',
                      'lugares',
                      'lugaresHoras',
                      'labores',
                      'afps',
                      'previsiones',
                      'comunas',
                      'estadosciviles',
                      'nacionalidades'
                    ]).snapshots(),
                    builder: (BuildContext context,
                        AsyncSnapshot<QuerySnapshot> snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      }
                      return LayoutBuilder(
                        builder: (context, constraints) {
                          final crossCount = constraints.maxWidth >= 800
                              ? 3
                              : (constraints.maxWidth >= 600 ? 2 : 1);
                          final validDocs = snapshot.data!.docs
                              .where((doc) => doc['nombre'] != 'lugaresHoras')
                              .toList();

                          final order = [
                            'empresadata',
                            'contratosmont',
                            'lugares',
                            'labores',
                            'afps',
                            'previsiones',
                            'comunas',
                            'estadosciviles',
                            'nacionalidades'
                          ];
                          validDocs.sort((a, b) => order
                              .indexOf(a['nombre'])
                              .compareTo(order.indexOf(b['nombre'])));

                          final List<Widget> settingCards =
                              validDocs.map<Widget>((doc) {
                            if (doc['nombre'] == 'empresadata') {
                              return _SettingsCard(
                                icon: Icons.business,
                                title: doc['nombreempresa'],
                                subtitle: 'RUT: ' + doc['rut'],
                                fraction: 1 / crossCount,
                                maxWidth: constraints.maxWidth,
                                onTap: () {
                                  _openStyledSettingsSheet(
                                    context: context,
                                    title: 'Empresa',
                                    icon: Icons.business_rounded,
                                    hint:
                                        'Actualiza la razon social y el RUT de la empresa.',
                                    child: const NewEnterpriseData(),
                                  );
                                },
                              );
                            } else if (doc['nombre'] == 'contratosmont') {
                              return _SettingsCard(
                                icon: Icons.attach_money,
                                title: 'Monto diario',
                                subtitle: numfor.format(doc['montonum']),
                                fraction: 1 / crossCount,
                                maxWidth: constraints.maxWidth,
                                onTap: () {
                                  _openStyledSettingsSheet(
                                    context: context,
                                    title: 'Monto diario',
                                    icon: Icons.attach_money_rounded,
                                    hint:
                                        'Define el monto base diario para los documentos.',
                                    child: const NewAmount(),
                                  );
                                },
                              );
                            } else if (doc['nombre'] == 'labores') {
                              final labores = doc['tipos'] as List<dynamic>;
                              return _SettingsCard(
                                icon: Icons.work_outline,
                                title: 'Labores',
                                subtitle:
                                    '${labores.length} opciones registradas',
                                fraction: 1 / crossCount,
                                maxWidth: constraints.maxWidth,
                                onTap: () {
                                  _manageGenericCategory(
                                      context, 'labores', 'Labores');
                                },
                              );
                            } else if (doc['nombre'] == 'lugares') {
                              final lugares = doc['tipos'] as List<dynamic>;
                              return _SettingsCard(
                                icon: Icons.location_on,
                                title: 'Establecimientos',
                                subtitle: '${lugares.length} sedes registradas',
                                fraction: 1 / crossCount,
                                maxWidth: constraints.maxWidth,
                                onTap: () {
                                  _openStyledSettingsSheet(
                                    context: context,
                                    title: 'Establecimientos',
                                    icon: Icons.location_on_rounded,
                                    hint:
                                        'Administra lugares, horarios y horas semanales.',
                                    maxWidth:
                                        MediaQuery.of(context).size.width > 800
                                            ? 900
                                            : MediaQuery.of(context).size.width,
                                    child: _buildPlacesManagerContent(context),
                                  );
                                },
                              );
                            } else {
                              final tipos = doc['tipos'] as List<dynamic>;
                              final nombreMap = {
                                'afps': 'AFPs',
                                'previsiones': 'Previsiones',
                                'comunas': 'Comunas',
                                'estadosciviles': 'Estados Civiles',
                                'nacionalidades': 'Nacionalidades'
                              };
                              final iconMap = {
                                'afps': Icons.account_balance,
                                'previsiones': Icons.health_and_safety,
                                'comunas': Icons.map,
                                'estadosciviles': Icons.family_restroom,
                                'nacionalidades': Icons.flag,
                              };
                              final label = nombreMap[doc['nombre']] ?? 'Otros';
                              return _SettingsCard(
                                icon: iconMap[doc['nombre']] ?? Icons.category,
                                title: label,
                                subtitle:
                                    '${tipos.length} opciones disponibles',
                                fraction: 1 / crossCount,
                                maxWidth: constraints.maxWidth,
                                onTap: () {
                                  _manageGenericCategory(
                                      context, doc['nombre'], label);
                                },
                              );
                            }
                          }).toList();

                          // Las plantillas no viven en `Otros`, asi que se
                          // agregan aparte y quedan en su propia seccion: son
                          // el texto de documentos laborales, no un catalogo
                          // de opciones como las comunas o las AFP.
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (compacta) _cabecera,
                              Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(20, 20, 20, 20),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    _tituloSeccion(
                                      'Datos base',
                                      'Catalogos que alimentan los formularios.',
                                    ),
                                    Wrap(
                                      spacing: 16,
                                      runSpacing: 16,
                                      children: settingCards,
                                    ),
                                    const SizedBox(height: 32),
                                    _tituloSeccion(
                                      'Plantillas de documentos',
                                      'El texto de cada documento que emite el '
                                          'sistema. Publicar crea una version nueva '
                                          'y conserva las anteriores.',
                                    ),
                                    Wrap(
                                      spacing: 16,
                                      runSpacing: 16,
                                      children: [
                                        for (final tipo in TipoPlantilla.todos)
                                          _SettingsCard(
                                            icon: Icons.description_outlined,
                                            title: tipo.nombre,
                                            subtitle: tipo.descripcion,
                                            fraction: 1 / crossCount,
                                            maxWidth: constraints.maxWidth,
                                            onTap: () => abrirEditorDePlantilla(
                                                context, tipo),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlacesManagerContent(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: db
          .collection('Otros')
          .where('nombre', whereIn: ['lugares', 'lugaresHoras']).snapshots(),
      builder: (context, modalSnapshot) {
        if (!modalSnapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final localDocLugares = modalSnapshot.data!.docs
            .firstWhere((element) => element['nombre'] == 'lugares');
        final localDocHoras = modalSnapshot.data!.docs
            .firstWhere((element) => element['nombre'] == 'lugaresHoras');

        final localLugares = localDocLugares['tipos'] as List<dynamic>;
        final localHorariosLunesAJueves =
            localDocHoras['lunes_jueves'] as List<dynamic>;
        final localHorariosViernes = localDocHoras['viernes'] as List<dynamic>;
        final localHoras = localDocHoras['prueba_horas'] as List<dynamic>;

        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: localLugares.length,
                  itemBuilder: (context, i) {
                    final lj = localHorariosLunesAJueves[i]
                        .toString()
                        .replaceAll('/', ' a ');
                    final v = localHorariosViernes[i]
                        .toString()
                        .replaceAll('/', ' a ');
                    final mismoHorario =
                        localHorariosLunesAJueves[i] == localHorariosViernes[i];

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: primario.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '${localHoras[i]}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: primario,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Text(
                                    'Hrs',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: primario.withOpacity(0.8),
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${localLugares[i]}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    mismoHorario
                                        ? 'L a V: $lj'
                                        : 'L-J: $lj | V: $v',
                                    style: const TextStyle(
                                      color: Colors.black54,
                                      fontSize: 13,
                                      height: 1.3,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.edit_outlined,
                                color: Colors.blueGrey,
                                size: 22,
                              ),
                              onPressed: () {
                                _openStyledSettingsSheet(
                                  context: context,
                                  title: 'Editar establecimiento',
                                  icon: Icons.edit_rounded,
                                  hint:
                                      'Ajusta horas, colacion y horarios del establecimiento.',
                                  maxWidth:
                                      MediaQuery.of(context).size.width > 800
                                          ? 900
                                          : MediaQuery.of(context).size.width,
                                  child: EditPlace(
                                    existingPlace: localLugares[i].toString(),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primario,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    _openStyledSettingsSheet(
                      context: context,
                      title: 'Nuevo establecimiento',
                      icon: Icons.add_business_rounded,
                      hint:
                          'Registra un nuevo establecimiento con sus horarios.',
                      child: const NewPlace(),
                    );
                  },
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Agregar nuevo establecimiento'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _manageGenericCategory(
      BuildContext context, String docId, String title) {
    _openStyledSettingsSheet(
      context: context,
      title: title,
      icon: Icons.tune_rounded,
      hint: 'Edita, elimina o agrega nuevos elementos de $title.',
      maxWidth: MediaQuery.of(context).size.width > 800
          ? 900
          : MediaQuery.of(context).size.width,
      child: StreamBuilder<DocumentSnapshot>(
        stream: db.collection('Otros').doc(docId).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 48),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          final data = snapshot.data!.data() as Map<String, dynamic>?;
          final items = List<String>.from(
            (data?['tipos'] as List<dynamic>? ?? const [])
                .map((e) => e.toString()),
          );

          return _CategoryManagerBody(
            title: title,
            items: items,
            onEdit: (item) => _openStyledSettingsSheet(
              context: context,
              title: 'Editar $title',
              icon: Icons.edit_rounded,
              hint: 'Actualiza el nombre del elemento seleccionado.',
              maxWidth: 620,
              child: EditGenericCategory(
                docId: docId,
                existingItem: item,
                title: 'Editar $title',
              ),
            ),
            onDelete: (item) =>
                _showDeleteCategoryItemSheet(context, docId, item, title),
            // Sin `Get.back()` antes de abrir: cerraba el gestor, asi que tras
            // agregar un elemento habia que volver a entrar para ver el
            // resultado. El listado es un stream, se refresca solo.
            onAdd: () => _showAddCategoryItemSheet(context, docId),
          );
        },
      ),
    );
  }

  void _showAddCategoryItemSheet(BuildContext context, String docId) {
    Widget addWidget;
    String modalTitle = '';
    String modalHint = '';
    IconData modalIcon = Icons.add_rounded;
    switch (docId) {
      case 'afps':
        // Reutilizamos el widget existente de new_worker_page.dart
        // Nota: Asumo que los widgets están accesibles o importados si estuvieran en archivos separados.
        // Como están en new_worker_page.dart, y este es contract.dart, si no son públicos o exportados fallará.
        // Pero en la estructura actual parece que el usuario los define en los mismos archivos o globalmente.
        // Verificando imports...
        // No hay imports de new_worker_page.dart. Debería crearlos o importarlos.
        addWidget =
            const NewAfp(); // Placeholder, veré si puedo importarlo o duplicarlo si es pequeño.
        break;
      case 'previsiones':
        addWidget = const NewPrevision();
        modalTitle = 'Nueva prevision';
        modalHint = 'Registra la institucion de salud previsional.';
        modalIcon = Icons.local_hospital_rounded;
        break;
      case 'comunas':
        addWidget = const NewCommune();
        modalTitle = 'Nueva comuna';
        modalHint = 'Ingresa una comuna valida para los trabajadores.';
        modalIcon = Icons.location_city_rounded;
        break;
      case 'estadosciviles':
        addWidget = const NewCivilState();
        modalTitle = 'Nuevo estado civil';
        modalHint = 'Agrega un estado civil al listado del sistema.';
        modalIcon = Icons.favorite_border_rounded;
        break;
      case 'nacionalidades':
        addWidget = const NewNacionality();
        modalTitle = 'Nueva nacionalidad';
        modalHint = 'Registra una nacionalidad para los formularios.';
        modalIcon = Icons.flag_rounded;
        break;
      case 'labores':
        addWidget = const NewLabor();
        modalTitle = 'Nueva labor';
        modalHint = 'Agrega una labor o cargo disponible.';
        modalIcon = Icons.construction_rounded;
        break;
      default:
        return;
    }

    if (modalTitle.isEmpty) {
      modalTitle = 'Nueva AFP';
      modalHint = 'Ingresa el nombre de la AFP para incorporarla al listado.';
      modalIcon = Icons.account_balance_rounded;
    }

    _openStyledSettingsSheet(
      context: context,
      title: modalTitle,
      icon: modalIcon,
      hint: modalHint,
      maxWidth: 620,
      child: addWidget,
    );
  }

  void _showDeleteCategoryItemSheet(
      BuildContext context, String docId, String item, String title) {
    _openStyledSettingsSheet(
      context: context,
      title: 'Confirmar eliminacion',
      icon: Icons.delete_outline_rounded,
      hint: 'Esta accion eliminara el elemento seleccionado de $title.',
      danger: true,
      maxWidth: 620,
      child: AppDangerConfirmBody(
        message: 'Se eliminara ${item.toUpperCase()} de forma permanente.',
        onCancel: () => Get.back(),
        confirmText: 'Eliminar',
        confirmIcon: Icons.delete_rounded,
        onConfirm: () async {
          try {
            await db.collection('Otros').doc(docId).update({
              'tipos': FieldValue.arrayRemove([item])
            });
            if (!mounted) return;
            Get.back();
            AnimatedSnackBar.material(
              'Eliminado con exito',
              type: AnimatedSnackBarType.success,
            ).show(context);
          } catch (e) {
            if (!mounted) return;
            AnimatedSnackBar.material(
              'Error al eliminar: $e',
              type: AnimatedSnackBarType.error,
            ).show(context);
          }
        },
      ),
    );
  }
}

// ignore: unused_element
void _confirmDeleteCategoryItem(
    BuildContext context, String docId, String item, String title) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                    color: Colors.black12,
                    borderRadius: BorderRadius.circular(2)),
              ),
              Text('Eliminar $title',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              Text(
                  '¿Estás seguro de eliminar el elemento:\\n${item.toUpperCase()}?',
                  textAlign: TextAlign.center),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style:
                          ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      onPressed: () async {
                        try {
                          await db.collection('Otros').doc(docId).update({
                            'tipos': FieldValue.arrayRemove([item])
                          });
                          if (!ctx.mounted) return;
                          Navigator.pop(ctx);
                          if (!context.mounted) return;
                          AnimatedSnackBar.material(
                            'Eliminado con éxito',
                            type: AnimatedSnackBarType.success,
                          ).show(context);
                        } catch (e) {
                          if (!context.mounted) return;
                          AnimatedSnackBar.material(
                            'Error al eliminar: $e',
                            type: AnimatedSnackBarType.error,
                          ).show(context);
                        }
                      },
                      child: const Text('Sí, eliminar',
                          style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}

class EditGenericCategory extends StatefulWidget {
  final String docId;
  final String existingItem;
  final String title;
  const EditGenericCategory(
      {super.key,
      required this.docId,
      required this.existingItem,
      required this.title});

  @override
  State<EditGenericCategory> createState() => _EditGenericCategoryState();
}

class _EditGenericCategoryState extends State<EditGenericCategory> {
  final TextEditingController _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _controller.text = widget.existingItem;
  }

  Future<void> saveEdit() async {
    try {
      DocumentSnapshot doc =
          await db.collection('Otros').doc(widget.docId).get();
      List<dynamic> types = doc['tipos'];
      int index = types.indexOf(widget.existingItem);

      if (index != -1) {
        types[index] = _controller.text.trim();
        await db.collection('Otros').doc(widget.docId).update({'tipos': types});

        if (!mounted) return;
        Navigator.pop(context);
        AnimatedSnackBar.material(
          'Editado con éxito',
          type: AnimatedSnackBarType.success,
        ).show(context);
      }
    } catch (e) {
      if (!mounted) return;
      AnimatedSnackBar.material(
        'Error al editar: $e',
        type: AnimatedSnackBarType.error,
      ).show(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            InputTextField(
              textController: _controller,
              hint: 'Nombre',
              onFieldSubmitted: (_) {
                if (_formKey.currentState!.validate()) {
                  saveEdit();
                }
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor ingrese el nombre';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: CustomButton(
                    funcion: () => Navigator.pop(context),
                    texto: 'Cancelar',
                    cancelar: true,
                    icon: Icons.close_rounded,
                    width: double.infinity,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CustomButton(
                    funcion: () {
                      if (_formKey.currentState!.validate()) {
                        saveEdit();
                      }
                    },
                    texto: 'Guardar',
                    cancelar: false,
                    icon: Icons.check_rounded,
                    width: double.infinity,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class EditSystemUser extends StatefulWidget {
  const EditSystemUser({
    super.key,
    required this.userId,
    required this.userData,
    required this.availableTypes,
  });

  final String userId;
  final Map<String, dynamic> userData;
  final List<String> availableTypes;

  @override
  State<EditSystemUser> createState() => _EditSystemUserState();
}

class _EditSystemUserState extends State<EditSystemUser> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _occupationController = TextEditingController();

  String? _selectedType;
  bool _isSeller = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameController.text = (widget.userData['nombre'] ?? '').toString();
    _lastNameController.text = (widget.userData['apellido'] ?? '').toString();
    _emailController.text = (widget.userData['email'] ?? '').toString();
    _phoneController.text = (widget.userData['telefono'] ?? '').toString();
    _occupationController.text =
        (widget.userData['ocupacion'] ?? '').toString();
    _isSeller = widget.userData['seller'] == true;
    _selectedType = _resolveInitialType();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _occupationController.dispose();
    super.dispose();
  }

  String _resolveInitialType() {
    final available = widget.availableTypes.isEmpty
        ? const ['OPERADOR']
        : widget.availableTypes;
    final raw = widget.userData['tipo'];

    if (raw is num) {
      final index = raw.toInt() - 1;
      if (index >= 0 && index < available.length) {
        return available[index];
      }
    }

    final asText = raw?.toString().trim().toUpperCase() ?? '';
    if (asText.isNotEmpty) {
      for (final type in available) {
        if (type.toUpperCase() == asText) {
          return type;
        }
      }
    }

    return available.first;
  }

  Future<void> _save() async {
    if (_saving) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);

    try {
      await db.collection('Usuarios').doc(widget.userId).set(
        {
          'uid': widget.userId,
          'nombre': _nameController.text.trim(),
          'apellido': _lastNameController.text.trim(),
          'email': _emailController.text.trim().toLowerCase(),
          'telefono': _phoneController.text.trim(),
          'ocupacion': _occupationController.text.trim(),
          'tipo': _selectedType ?? '',
          'seller': _isSeller,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      if (!mounted) return;
      Get.back();
      AnimatedSnackBar.material(
        'Usuario actualizado con exito.',
        type: AnimatedSnackBarType.success,
      ).show(context);
    } catch (e) {
      if (!mounted) return;
      AnimatedSnackBar.material(
        'No se pudo guardar el usuario: $e',
        type: AnimatedSnackBarType.error,
      ).show(context);
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final availableTypes = widget.availableTypes.isEmpty
        ? const ['OPERADOR']
        : widget.availableTypes;
    if (!availableTypes.contains(_selectedType)) {
      _selectedType = availableTypes.first;
    }

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              InputTextField(
                textController: _nameController,
                hint: 'Nombres',
                validator: (value) {
                  if ((value ?? '').trim().isEmpty) {
                    return 'Ingresa el nombre.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              InputTextField(
                textController: _lastNameController,
                hint: 'Apellidos',
                validator: (value) {
                  if ((value ?? '').trim().isEmpty) {
                    return 'Ingresa el apellido.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              InputTextField(
                textController: _emailController,
                hint: 'Correo',
                teclado: TextInputType.emailAddress,
                validator: (value) {
                  final email = (value ?? '').trim().toLowerCase();
                  if (email.isEmpty) {
                    return 'Ingresa el correo.';
                  }
                  final regex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
                  if (!regex.hasMatch(email)) {
                    return 'Ingresa un correo valido.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              InputTextField(
                textController: _phoneController,
                hint: 'Telefono',
                teclado: TextInputType.phone,
              ),
              const SizedBox(height: 12),
              InputTextField(
                textController: _occupationController,
                hint: 'Ocupacion',
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedType,
                decoration: InputDecoration(
                  labelText: 'Tipo de usuario',
                  labelStyle: const TextStyle(
                    color: Colors.black45,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  floatingLabelStyle: TextStyle(
                    color: Colors.blueGrey.shade600,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF2F5F8),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.blueGrey.shade100),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: primario),
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                borderRadius: BorderRadius.circular(14),
                items: availableTypes
                    .map(
                      (type) => DropdownMenuItem<String>(
                        value: type,
                        child: Text(
                          type,
                          style: const TextStyle(
                            color: Colors.black54,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setState(() => _selectedType = value),
              ),
              const SizedBox(height: 4),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _isSeller,
                activeColor: primario,
                title: const Text(
                  'Vendedor habilitado',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13.5,
                  ),
                ),
                onChanged: (value) => setState(() => _isSeller = value),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: CustomButton(
                      funcion: () => Get.back(),
                      texto: 'Cancelar',
                      cancelar: true,
                      icon: Icons.close_rounded,
                      width: double.infinity,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CustomButton(
                      funcion: _saving ? () {} : _save,
                      texto: _saving ? 'Guardando...' : 'Guardar',
                      cancelar: false,
                      icon: Icons.check_rounded,
                      width: double.infinity,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class NewUserType extends StatefulWidget {
  const NewUserType({super.key});

  @override
  State<NewUserType> createState() => _NewUserTypeState();
}

class _NewUserTypeState extends State<NewUserType> {
  final _formKey = GlobalKey<FormState>();
  final _controller = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final newType = _controller.text.trim().toUpperCase();
    setState(() => _saving = true);

    try {
      final ref = db.collection('Otros').doc('tipos_usuarios');
      final snap = await ref.get();
      final currentRaw =
          (snap.data()?['tipos'] as List?)?.cast<dynamic>() ?? <dynamic>[];
      final current = currentRaw
          .map((e) => e.toString().trim().toUpperCase())
          .where((e) => e.isNotEmpty)
          .toSet()
          .toList();

      if (current.contains(newType)) {
        if (!mounted) return;
        AnimatedSnackBar.material(
          'Ese tipo ya existe en el listado.',
          type: AnimatedSnackBarType.warning,
        ).show(context);
        setState(() => _saving = false);
        return;
      }

      await ref.set(
        {
          'nombre': 'tipos_usuarios',
          'tipos': FieldValue.arrayUnion([newType]),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      if (!mounted) return;
      Get.back();
      AnimatedSnackBar.material(
        'Tipo de usuario creado con exito.',
        type: AnimatedSnackBarType.success,
      ).show(context);
    } catch (e) {
      if (!mounted) return;
      AnimatedSnackBar.material(
        'No se pudo crear el tipo: $e',
        type: AnimatedSnackBarType.error,
      ).show(context);
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              InputTextField(
                textController: _controller,
                hint: 'Tipo de usuario',
                onFieldSubmitted: (_) => _save(),
                validator: (value) {
                  if ((value ?? '').trim().isEmpty) {
                    return 'Ingresa un tipo de usuario.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: CustomButton(
                      funcion: () => Get.back(),
                      texto: 'Cancelar',
                      cancelar: true,
                      icon: Icons.close_rounded,
                      width: double.infinity,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CustomButton(
                      funcion: _saving ? () {} : _save,
                      texto: _saving ? 'Guardando...' : 'Agregar',
                      cancelar: false,
                      icon: Icons.add_rounded,
                      width: double.infinity,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class NewEnterpriseData extends StatefulWidget {
  const NewEnterpriseData({super.key});

  @override
  State<NewEnterpriseData> createState() => _NewEnterpriseDataState();
}

/// Datos de la empresa que salen impresos en todos los documentos.
///
/// Antes solo pedia razon social y RUT. El representante legal, su RUT, el
/// domicilio y el correo estaban **escritos a mano dentro del generador de
/// PDF** -- cambiarlos significaba tocar el codigo y publicar la app. Ahora
/// viven aqui, que es de donde los toman las plantillas.
class _NewEnterpriseDataState extends State<NewEnterpriseData> {
  final _empresaController = TextEditingController();
  final _rutController = TextEditingController();
  final _representanteController = TextEditingController();
  final _representanteRutController = TextEditingController();
  final _domicilioController = TextEditingController();
  final _correoController = TextEditingController();

  final _formKey = GlobalKey<FormState>();
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  @override
  void dispose() {
    _empresaController.dispose();
    _rutController.dispose();
    _representanteController.dispose();
    _representanteRutController.dispose();
    _domicilioController.dispose();
    _correoController.dispose();
    super.dispose();
  }

  /// Trae lo que ya esta guardado.
  ///
  /// El formulario anterior abria en blanco y guardaba encima, asi que editar
  /// solo el RUT borraba la razon social.
  Future<void> _cargar() async {
    final snap = await db.collection('Otros').doc('empresadata').get();
    if (!mounted) return;
    final d = snap.data() ?? const <String, dynamic>{};
    String texto(String k) => (d[k] ?? '').toString();

    _empresaController.text = texto('nombreempresa');
    _rutController.text = texto('rut');
    _representanteController.text = texto('representante');
    _representanteRutController.text = texto('representante_rut');
    _domicilioController.text = texto('domicilio');
    _correoController.text = texto('correo');
    setState(() => _cargando = false);
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    try {
      await db.collection('Otros').doc('empresadata').set({
        'nombreempresa': _empresaController.text.trim(),
        'rut': _rutController.text.trim(),
        'representante': _representanteController.text.trim(),
        'representante_rut': _representanteRutController.text.trim(),
        'domicilio': _domicilioController.text.trim(),
        'correo': _correoController.text.trim(),
      }, SetOptions(merge: true));
      if (!mounted) return;
      Get.back();
      AnimatedSnackBar.material(
        'Datos de la empresa actualizados.',
        mobileSnackBarPosition: MobileSnackBarPosition.top,
        desktopSnackBarPosition: DesktopSnackBarPosition.bottomRight,
        type: AnimatedSnackBarType.success,
      ).show(context);
    } catch (e) {
      if (!mounted) return;
      AnimatedSnackBar.material(
        'No se pudo guardar: $e',
        type: AnimatedSnackBarType.error,
      ).show(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 48),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: AppModalBody(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppFormSection(
                    title: 'Identificacion',
                    icon: Icons.business_rounded,
                    child: AppModalFieldGrid(
                      minItemWidth: 260,
                      maxColumns: 2,
                      children: [
                        InputTextField(
                          textController: _empresaController,
                          hint: 'Razon social',
                          validator: (v) => (v ?? '').trim().isEmpty
                              ? 'Ingresa la razon social'
                              : null,
                        ),
                        InputTextField(
                          textController: _rutController,
                          hint: 'RUT de la empresa',
                          formater: RutFormatter(),
                          validator: (v) {
                            final t = (v ?? '').trim();
                            if (t.isEmpty) return 'Ingresa el RUT';
                            if (!isRutValid(t)) return 'RUT no valido';
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  AppFormSection(
                    title: 'Representante legal',
                    icon: Icons.badge_outlined,
                    child: AppModalFieldGrid(
                      minItemWidth: 260,
                      maxColumns: 2,
                      children: [
                        InputTextField(
                          textController: _representanteController,
                          hint: 'Nombre completo',
                          validator: (v) => (v ?? '').trim().isEmpty
                              ? 'Sale impreso en contratos y finiquitos'
                              : null,
                        ),
                        InputTextField(
                          textController: _representanteRutController,
                          hint: 'RUT del representante',
                          formater: RutFormatter(),
                          validator: (v) {
                            final t = (v ?? '').trim();
                            if (t.isEmpty) return 'Sale impreso en documentos';
                            if (!isRutValid(t)) return 'RUT no valido';
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  AppFormSection(
                    title: 'Contacto',
                    icon: Icons.place_outlined,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        InputTextField(
                          textController: _domicilioController,
                          hint: 'Domicilio',
                          help: 'Sale al pie de cada hoja y en la '
                              'comparecencia del contrato.',
                          helper: true,
                          validator: (v) => (v ?? '').trim().isEmpty
                              ? 'Sale al pie de cada documento'
                              : null,
                        ),
                        const SizedBox(height: 16),
                        InputTextField(
                          textController: _correoController,
                          hint: 'Correo',
                          teclado: TextInputType.emailAddress,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        AppFormFooter(
          onCancel: () => Get.back(),
          onConfirm: _guardar,
          confirmText: 'Guardar',
          confirmIcon: Icons.check_rounded,
        ),
      ],
    );
  }
}

class NewAmount extends StatefulWidget {
  const NewAmount({super.key});

  @override
  State<NewAmount> createState() => _NewAmountState();
}

class _NewAmountState extends State<NewAmount> {
  final TextEditingController _montoController = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  void saveNewAmount() {
    try {
      db.collection('Otros').doc('contrato').update({
        'montonum': int.parse(
            _montoController.text.replaceAll(',', '').replaceAll('.', '')),
        'montotext': SpellingNumber(lang: 'es')
            .convert(int.parse(
                _montoController.text.replaceAll(',', '').replaceAll('.', '')))
            .capitalizeFirst,
      });
      Get.back();
      AnimatedSnackBar.material(
        'Monto diario modificado con éxito',
        mobileSnackBarPosition: MobileSnackBarPosition.top,
        desktopSnackBarPosition: DesktopSnackBarPosition.bottomRight,
        type: AnimatedSnackBarType.success,
      ).show(context);
    } catch (e) {}
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 2),
              InputTextField(
                teclado: TextInputType.number,
                textController: _montoController,
                formater: FilteringTextInputFormatter.digitsOnly,
                hint: 'Monto diario',
                onFieldSubmitted: (_) {
                  if (_formKey.currentState!.validate()) {
                    _formKey.currentState!.save();
                    saveNewAmount();
                  }
                },
                money: true,
                prefix: '\$',
                validator: (value) {
                  if (value!.isEmpty) {
                    return 'Por favor ingrese un precio';
                  }
                  return null;
                },
              ),
              Padding(
                padding: const EdgeInsets.only(top: 15.0),
                child: Row(
                  children: [
                    Expanded(
                      child: CustomButton(
                        funcion: () {
                          Get.back();
                        },
                        texto: 'Cancelar',
                        cancelar: true,
                        icon: Icons.close_rounded,
                        width: double.infinity,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: CustomButton(
                          funcion: () {
                            if (_formKey.currentState!.validate()) {
                              _formKey.currentState!.save();
                              saveNewAmount();
                            }
                          },
                          texto: 'Guardar',
                          cancelar: false,
                          icon: Icons.check_rounded,
                          width: double.infinity),
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
}

/// Encabezado de un grupo de tarjetas en Ajustes.
Widget _tituloSeccion(String titulo, String bajada) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          titulo.toUpperCase(),
          style: const TextStyle(
            color: AppColors.textMuted,
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          bajada,
          style: const TextStyle(
            color: AppColors.textFaint,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    ),
  );
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.fraction,
    required this.maxWidth,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final double fraction;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final width = fraction == 1.0
        ? maxWidth
        : (maxWidth - (16 * (1 / fraction).round())) * fraction;
    return SizedBox(
      width: width,
      // Material y no Container porque necesita el InkWell del tap, pero con
      // el mismo color, radio y borde que appCardDecoration().
      child: Material(
        elevation: 0,
        color: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(kCardRadius),
          side: BorderSide(color: Colors.black.withOpacity(0.05), width: 1),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(kCardRadius),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: primario.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: primario, size: 26),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.black54,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.right,
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
  }
}

/// Listado editable de una categoria de ajustes (comunas, AFP, labores...).
///
/// Antes cada fila era un `ListTile` con avatar de radio 18 y botones de 22:
/// unos 66px por un texto de una linea, asi que con quince comunas el modal ya
/// era todo scroll. Aqui la fila mide ~50 y, pasadas ocho, aparece un buscador:
/// con listas largas recorrerlas a ojo era el unico camino.
class _CategoryManagerBody extends StatefulWidget {
  const _CategoryManagerBody({
    required this.title,
    required this.items,
    required this.onEdit,
    required this.onDelete,
    required this.onAdd,
  });

  final String title;
  final List<String> items;
  final ValueChanged<String> onEdit;
  final ValueChanged<String> onDelete;
  final VoidCallback onAdd;

  /// A partir de aqui buscar sale mas a cuenta que recorrer.
  static const int umbralBuscador = 8;

  @override
  State<_CategoryManagerBody> createState() => _CategoryManagerBodyState();
}

class _CategoryManagerBodyState extends State<_CategoryManagerBody> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Sin tildes y en minusculas: buscar "curico" tiene que encontrar "Curico"
  /// escrito con acento.
  String _normalizar(String texto) => texto
      .toLowerCase()
      .replaceAll('á', 'a')
      .replaceAll('é', 'e')
      .replaceAll('í', 'i')
      .replaceAll('ó', 'o')
      .replaceAll('ú', 'u')
      .replaceAll('ü', 'u')
      .replaceAll('ñ', 'n');

  @override
  Widget build(BuildContext context) {
    final conBuscador =
        widget.items.length >= _CategoryManagerBody.umbralBuscador;

    // El indice que se muestra es el de la lista completa, no el del filtro: si
    // busco "temuco" quiero ver que es el 10, no el 1.
    final visibles = <MapEntry<int, String>>[
      for (var i = 0; i < widget.items.length; i++)
        if (_query.isEmpty ||
            _normalizar(widget.items[i]).contains(_normalizar(_query)))
          MapEntry(i, widget.items[i]),
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (conBuscador)
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _query = value),
              style: const TextStyle(
                color: AppColors.textStrong,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
              decoration: InputDecoration(
                isDense: true,
                hintText: 'Buscar en ${widget.title.toLowerCase()}',
                hintStyle: const TextStyle(
                  color: AppColors.textFaint,
                  fontSize: 14.5,
                  fontWeight: FontWeight.w500,
                ),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  size: 20,
                  color: AppColors.iconMuted,
                ),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close_rounded, size: 18),
                        color: AppColors.iconMuted,
                        tooltip: 'Limpiar',
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                      ),
                filled: true,
                fillColor: Colors.white,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                enabledBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: AppColors.border),
                  borderRadius: BorderRadius.circular(14),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: primario, width: 1.6),
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        Flexible(
          child: AppModalBody(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
            child: visibles.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    child: Center(
                      child: Text(
                        'Sin resultados para "$_query".',
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (final entry in visibles) ...[
                        if (entry != visibles.first) const SizedBox(height: 8),
                        _CategoryItemRow(
                          index: entry.key + 1,
                          label: entry.value,
                          onEdit: () => widget.onEdit(entry.value),
                          onDelete: () => widget.onDelete(entry.value),
                        ),
                      ],
                    ],
                  ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: SizedBox(
            width: double.infinity,
            child: CustomButton(
              funcion: widget.onAdd,
              texto: 'Agregar a ${widget.title.toLowerCase()}',
              icon: Icons.add_rounded,
              width: double.infinity,
            ),
          ),
        ),
      ],
    );
  }
}

class _CategoryItemRow extends StatelessWidget {
  const _CategoryItemRow({
    required this.index,
    required this.label,
    required this.onEdit,
    required this.onDelete,
  });

  final int index;
  final String label;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      // Sin sombra propia: sobre el fondo hundido del modal la sombra que traia
      // se leia como un halo alrededor de cada fila.
      decoration: appCardDecoration(radius: 12),
      padding: const EdgeInsets.fromLTRB(12, 6, 8, 6),
      child: Row(
        children: [
          Container(
            width: 26,
            height: 26,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: primario.withOpacity(0.10),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$index',
              style: TextStyle(
                color: primario,
                fontWeight: FontWeight.w700,
                fontSize: 12.5,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textStrong,
                fontWeight: FontWeight.w600,
                fontSize: 14.5,
              ),
            ),
          ),
          _RowIconButton(
            icon: Icons.edit_outlined,
            color: AppColors.iconMuted,
            tooltip: 'Editar',
            onPressed: onEdit,
          ),
          _RowIconButton(
            icon: Icons.delete_outline_rounded,
            color: Colors.red.shade400,
            tooltip: 'Eliminar',
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}

class _RowIconButton extends StatelessWidget {
  const _RowIconButton({
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon, size: 19),
      color: color,
      tooltip: tooltip,
      onPressed: onPressed,
      visualDensity: VisualDensity.compact,
      padding: const EdgeInsets.all(6),
      constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
    );
  }
}
