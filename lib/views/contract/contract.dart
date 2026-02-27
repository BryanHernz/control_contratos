// ignore_for_file: empty_catches

import 'package:animated_snack_bar/animated_snack_bar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:rut_utils/rut_utils.dart';
import 'package:spelling_number/spelling_number.dart';

import '../../customs/constants_values.dart';
import '../../customs/widgets_custom.dart';
import '../workers/new_worker_page.dart';

class ContractPage extends StatefulWidget {
  const ContractPage({super.key});

  @override
  State<ContractPage> createState() => _ContractPageState();
}

class _ContractPageState extends State<ContractPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajustes'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
        toolbarHeight: 80,
      ),
      resizeToAvoidBottomInset: true,
      /* floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showCupertinoModalBottomSheet(
            context: context,
            builder: (context) => Container(
              constraints: const BoxConstraints(maxHeight: 250),
              child: const NewAmount(),
            ),
          );
        },
        label: const Text('Editar'),
        icon: const Icon(Icons.edit_document),
      ), */
      body: SingleChildScrollView(
        child: StreamBuilder(
          stream: FirebaseFirestore.instance
              .collection('Otros')
              .where('nombre', whereIn: [
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
          builder:
              (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
            if (!snapshot.hasData) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }
            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: snapshot.data!.docs.length,
              itemBuilder: (context, index) {
                final doc = snapshot.data!.docs[index];
                if (doc['nombre'] == 'empresadata') {
                  return ListTile(
                    leading: const Text('Empresa'),
                    minLeadingWidth: 80,
                    title: Text(doc['nombreempresa']),
                    subtitle: Text(doc['rut']),
                    trailing: IconButton(
                        onPressed: () {
                          showModalBottomSheet(
                            isScrollControlled: true,
                            useSafeArea: true,
                            constraints: BoxConstraints(
                                maxWidth: MediaQuery.of(context).size.width >
                                        800
                                    ? 900
                                    : MediaQuery.of(context).size.width * 0.95),
                            backgroundColor: Colors.white,
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(16)),
                            ),
                            context: context,
                            builder: (context) => Padding(
                              padding: EdgeInsets.only(
                                  bottom:
                                      MediaQuery.of(context).viewInsets.bottom),
                              child: const NewEnterpriseData(),
                            ),
                          );
                        },
                        icon: const Icon(
                          Icons.edit_document,
                          color: Colors.blueGrey,
                        )),
                  );
                } else if (doc['nombre'] == 'contratosmont') {
                  return ListTile(
                    leading: const Text('Monto diario'),
                    minLeadingWidth: 80,
                    title: Text(
                      numfor.format(
                        doc['montonum'],
                      ),
                    ),
                    subtitle: Text(
                      doc['montotext'],
                    ),
                    trailing: IconButton(
                        onPressed: () {
                          showModalBottomSheet(
                            isScrollControlled: true,
                            useSafeArea: true,
                            constraints: BoxConstraints(
                                maxWidth: MediaQuery.of(context).size.width >
                                        800
                                    ? 900
                                    : MediaQuery.of(context).size.width * 0.95),
                            backgroundColor: Colors.white,
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(16)),
                            ),
                            context: context,
                            builder: (context) => Padding(
                              padding: EdgeInsets.only(
                                  bottom:
                                      MediaQuery.of(context).viewInsets.bottom),
                              child: const NewAmount(),
                            ),
                          );
                        },
                        icon: const Icon(
                          Icons.edit_document,
                          color: Colors.blueGrey,
                        )),
                  );
                } else if (doc['nombre'] == 'labores') {
                  final labores = doc['tipos'] as List<dynamic>;
                  return ListTile(
                    leading: const Text('Labores'),
                    minLeadingWidth: 80,
                    title: Text(
                      labores.length.toString(),
                    ),
                    subtitle: const Text(
                      'Labores disponibles',
                    ),
                    trailing: IconButton(
                        onPressed: () {
                          _manageGenericCategory(context, 'labores', 'Labores');
                        },
                        icon: const Icon(
                          Icons.edit_document,
                          color: Colors.blueGrey,
                        )),
                  );
                } else if (doc['nombre'] == 'lugares') {
                  final lugares = doc['tipos'];
                  return ListTile(
                    leading: const Text('Lugares'),
                    minLeadingWidth: 80,
                    title: Text(
                      lugares.length.toString(),
                    ),
                    subtitle: const Text(
                      'Lugares disponibles',
                    ),
                    trailing: IconButton(
                        onPressed: () {
                          showModalBottomSheet(
                            isScrollControlled: true,
                            useSafeArea: true,
                            constraints: BoxConstraints(
                                maxWidth:
                                    MediaQuery.of(context).size.width > 800
                                        ? 900
                                        : MediaQuery.of(context).size.width),
                            backgroundColor: Colors.white,
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(16)),
                            ),
                            context: context,
                            builder: (context) => StreamBuilder<QuerySnapshot>(
                              stream: FirebaseFirestore.instance
                                  .collection('Otros')
                                  .where('nombre', whereIn: [
                                'lugares',
                                'lugaresHoras'
                              ]).snapshots(),
                              builder: (context, modalSnapshot) {
                                if (!modalSnapshot.hasData) {
                                  return const Center(
                                      child: CircularProgressIndicator());
                                }

                                final localDocLugares = modalSnapshot.data!.docs
                                    .firstWhere((element) =>
                                        element['nombre'] == 'lugares');
                                final localDocHoras = modalSnapshot.data!.docs
                                    .firstWhere((element) =>
                                        element['nombre'] == 'lugaresHoras');

                                final localLugares = localDocLugares['tipos'];
                                final localHorariosLunesAJueves =
                                    localDocHoras['lunes_jueves'];
                                final localHorariosViernes =
                                    localDocHoras['viernes'];
                                final localHoras =
                                    localDocHoras['prueba_horas'];

                                return Padding(
                                  padding: EdgeInsets.only(
                                      bottom: MediaQuery.of(context)
                                          .viewInsets
                                          .bottom),
                                  child: SafeArea(
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const SizedBox(height: 12),
                                          Text(
                                            'Lugares disponibles',
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleLarge
                                                ?.copyWith(
                                                    fontWeight:
                                                        FontWeight.bold),
                                          ),
                                          const SizedBox(height: 12),
                                          Flexible(
                                            child: ListView.builder(
                                              shrinkWrap: true,
                                              itemCount: localLugares.length,
                                              itemBuilder: (context, i) {
                                                return ListTile(
                                                  title: Text(localLugares[i]),
                                                  leading: Column(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .center,
                                                    children: [
                                                      Text(localHoras[i],
                                                          style: const TextStyle(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold)),
                                                      const Text('Horas',
                                                          style: TextStyle(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold)),
                                                    ],
                                                  ),
                                                  subtitle: Text(
                                                      'Horario: Lunes a Jueves de ${localHorariosLunesAJueves[i].toString().replaceAll('/', ' a ')} - Viernes de ${localHorariosViernes[i].toString().replaceAll('/', ' a ')}'),
                                                  trailing: IconButton(
                                                    icon: const Icon(Icons.edit,
                                                        color: Colors.blueGrey),
                                                    onPressed: () {
                                                      showModalBottomSheet(
                                                        context: context,
                                                        isScrollControlled:
                                                            true,
                                                        useSafeArea: true,
                                                        constraints: BoxConstraints(
                                                            maxWidth: MediaQuery.of(
                                                                            context)
                                                                        .size
                                                                        .width >
                                                                    800
                                                                ? 900
                                                                : MediaQuery.of(
                                                                        context)
                                                                    .size
                                                                    .width),
                                                        backgroundColor:
                                                            Colors.white,
                                                        shape:
                                                            const RoundedRectangleBorder(
                                                          borderRadius:
                                                              BorderRadius.vertical(
                                                                  top: Radius
                                                                      .circular(
                                                                          16)),
                                                        ),
                                                        builder: (context) =>
                                                            Container(
                                                          padding:
                                                              const EdgeInsets
                                                                  .all(16),
                                                          constraints: BoxConstraints(
                                                              maxHeight: MediaQuery.of(
                                                                          context)
                                                                      .size
                                                                      .height *
                                                                  0.85),
                                                          child: Column(
                                                            mainAxisSize:
                                                                MainAxisSize
                                                                    .min,
                                                            children: [
                                                              const SizedBox(
                                                                  height: 12),
                                                              Container(
                                                                width: 40,
                                                                height: 4,
                                                                decoration:
                                                                    BoxDecoration(
                                                                  color: Colors
                                                                      .black12,
                                                                  borderRadius:
                                                                      BorderRadius
                                                                          .circular(
                                                                              2),
                                                                ),
                                                              ),
                                                              const SizedBox(
                                                                  height: 12),
                                                              Flexible(
                                                                child:
                                                                    ClipRRect(
                                                                  borderRadius: const BorderRadius
                                                                      .vertical(
                                                                      top: Radius
                                                                          .circular(
                                                                              16)),
                                                                  child:
                                                                      EditPlace(
                                                                    existingPlace:
                                                                        localLugares[i]
                                                                            .toString(),
                                                                  ),
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      );
                                                    },
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
                                          const SizedBox(height: 16),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                        icon: const Icon(
                          Icons.edit_document,
                          color: Colors.blueGrey,
                        )),
                  );
                } else if ([
                  'afps',
                  'previsiones',
                  'comunas',
                  'estadosciviles',
                  'nacionalidades'
                ].contains(doc['nombre'])) {
                  final tipos = doc['tipos'] as List<dynamic>;
                  final nombreMap = {
                    'afps': 'AFPs',
                    'previsiones': 'Previsiones',
                    'comunas': 'Comunas',
                    'estadosciviles': 'Estados Civiles',
                    'nacionalidades': 'Nacionalidades'
                  };
                  final label = nombreMap[doc['nombre']] ?? 'Otros';
                  return ListTile(
                    leading: Text(label),
                    minLeadingWidth: 80,
                    title: Text(tipos.length.toString()),
                    subtitle: Text('$label disponibles'),
                    trailing: IconButton(
                        onPressed: () {
                          _manageGenericCategory(context, doc['nombre'], label);
                        },
                        icon: const Icon(
                          Icons.edit_document,
                          color: Colors.blueGrey,
                        )),
                  );
                }
                return const SizedBox.shrink();
              },
            );
          },
        ),
      ),
    );
  }

  void _manageGenericCategory(
      BuildContext context, String docId, String title) {
    showModalBottomSheet(
      isScrollControlled: true,
      useSafeArea: true,
      constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width > 800
              ? 900
              : MediaQuery.of(context).size.width),
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      context: context,
      builder: (context) => StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('Otros')
            .doc(docId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final items = snapshot.data!['tipos'] as List<dynamic>;

          return Padding(
            padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 12),
                    Text(
                      '$title disponibles',
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Flexible(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: items.length,
                        itemBuilder: (context, i) {
                          return ListTile(
                            title: Text('${i + 1} - ${items[i]}'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit,
                                      color: Colors.blueGrey),
                                  onPressed: () {
                                    showModalBottomSheet(
                                      context: context,
                                      isScrollControlled: true,
                                      useSafeArea: true,
                                      backgroundColor: Colors.white,
                                      shape: const RoundedRectangleBorder(
                                        borderRadius: BorderRadius.vertical(
                                            top: Radius.circular(16)),
                                      ),
                                      builder: (context) => EditGenericCategory(
                                        docId: docId,
                                        existingItem: items[i].toString(),
                                        title: 'Editar $title',
                                      ),
                                    );
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete,
                                      color: Colors.blueGrey),
                                  onPressed: () {
                                    _confirmDeleteCategoryItem(
                                        context, docId, items[i], title);
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextButton.icon(
                      onPressed: () {
                        Get.back(); // Cierra el actual
                        _showAddCategoryItemSheet(context, docId);
                      },
                      icon: const Icon(Icons.add, size: 18),
                      label: Text('Agregar nuevo a $title'),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showAddCategoryItemSheet(BuildContext context, String docId) {
    Widget addWidget;
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
        break;
      case 'comunas':
        addWidget = const NewCommune();
        break;
      case 'estadosciviles':
        addWidget = const NewCivilState();
        break;
      case 'nacionalidades':
        addWidget = const NewNacionality();
        break;
      case 'labores':
        addWidget = const NewLabor();
        break;
      default:
        return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: addWidget,
      ),
    );
  }
}

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
                  '¿Estás seguro de eliminar el elemento:\n${item.toUpperCase()}?',
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
                          await FirebaseFirestore.instance
                              .collection('Otros')
                              .doc(docId)
                              .update({
                            'tipos': FieldValue.arrayRemove([item])
                          });
                          Navigator.pop(ctx);
                          AnimatedSnackBar.material(
                            'Eliminado con éxito',
                            type: AnimatedSnackBarType.success,
                          ).show(context);
                        } catch (e) {
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
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('Otros')
          .doc(widget.docId)
          .get();
      List<dynamic> types = doc['tipos'];
      int index = types.indexOf(widget.existingItem);

      if (index != -1) {
        types[index] = _controller.text.trim();
        await FirebaseFirestore.instance
            .collection('Otros')
            .doc(widget.docId)
            .update({'tipos': types});

        Navigator.pop(context);
        AnimatedSnackBar.material(
          'Editado con éxito',
          type: AnimatedSnackBarType.success,
        ).show(context);
      }
    } catch (e) {
      AnimatedSnackBar.material(
        'Error al editar: $e',
        type: AnimatedSnackBarType.error,
      ).show(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
              Text(
                widget.title,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              InputTextField(
                textController: _controller,
                hint: 'Nombre',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingrese el nombre';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  CustomButton(
                    funcion: () => Navigator.pop(context),
                    texto: 'Cancelar',
                    cancelar: true,
                  ),
                  CustomButton(
                    funcion: () {
                      if (_formKey.currentState!.validate()) {
                        saveEdit();
                      }
                    },
                    texto: 'Guardar',
                    cancelar: false,
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

class _NewEnterpriseDataState extends State<NewEnterpriseData> {
  final TextEditingController _empresaController = TextEditingController();
  final TextEditingController _rutController = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  void saveNewEnterpriseData() {
    try {
      FirebaseFirestore.instance.collection('Otros').doc('empresadata').update({
        'nombreempresa': _empresaController.text,
        'rut': _rutController.text,
      });
      Get.back();
      AnimatedSnackBar.material(
        'Datos de la empresa modificados con éxito',
        mobileSnackBarPosition: MobileSnackBarPosition.top,
        desktopSnackBarPosition: DesktopSnackBarPosition.bottomRight,
        type: AnimatedSnackBarType.success,
      ).show(context);
    } catch (e) {}
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.black12,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 12),
                const Center(
                  child: Text(
                    'Datos de la empresa',
                    style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 16),
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: InputTextField(
                      textController: _empresaController,
                      hint: 'Nombre de la empresa',
                      validator: (value) {
                        if (value!.isEmpty) {
                          return 'Por favor ingrese el nombre de la empresa';
                        }
                        return null;
                      },
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: InputTextField(
                      teclado: TextInputType.text,
                      textController: _rutController,
                      hint: 'Rut',
                      formater: RutFormatter(),
                      validator: (value) {
                        if (value == '') {
                          return 'Por favor ingrese un rut';
                        }
                        if (value!.length < 11) {
                          return 'Por favor ingrese un rut válido';
                        }
                        if (isRutValid(value.toString()) == false) {
                          return 'Por favor ingrese un rut válido';
                        }
                        return null;
                      },
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 15.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      CustomButton(
                        funcion: () {
                          Get.back();
                        },
                        texto: 'Cancelar',
                        cancelar: true,
                      ),
                      CustomButton(
                          funcion: () {
                            if (_formKey.currentState!.validate() &&
                                _formKey.currentState!.validate()) {
                              _formKey.currentState!.save();
                              saveNewEnterpriseData();
                            }
                          },
                          texto: 'Agregar',
                          cancelar: false),
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
      FirebaseFirestore.instance.collection('Otros').doc('contrato').update({
        'montonum': int.parse(_montoController.text.replaceAll(',', '')),
        'montotext': SpellingNumber(lang: 'es')
            .convert(int.parse(_montoController.text.replaceAll(',', '')))
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
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 12),
              const Center(
                child: Text(
                  'Nuevo monto diario',
                  style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 16),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: InputTextField(
                    teclado: TextInputType.number,
                    textController: _montoController,
                    formater: FilteringTextInputFormatter.digitsOnly,
                    hint: 'Monto diario',
                    money: true,
                    prefix: '\$',
                    validator: (value) {
                      if (value!.isEmpty) {
                        return 'Por favor ingrese un precio';
                      }
                      return null;
                    },
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 15.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    CustomButton(
                      funcion: () {
                        Get.back();
                      },
                      texto: 'Cancelar',
                      cancelar: true,
                    ),
                    CustomButton(
                        funcion: () {
                          if (_formKey.currentState!.validate() &&
                              _formKey.currentState!.validate()) {
                            _formKey.currentState!.save();
                            saveNewAmount();
                          }
                        },
                        texto: 'Agregar',
                        cancelar: false),
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

class EditPlace extends StatefulWidget {
  final String existingPlace;
  const EditPlace({super.key, required this.existingPlace});

  @override
  State<EditPlace> createState() => _EditPlaceState();
}

class _EditPlaceState extends State<EditPlace> {
  final TextEditingController _tipoController = TextEditingController();
  final TextEditingController _horasController = TextEditingController();

  TimeOfDay? _ljDesde;
  TimeOfDay? _ljHasta;
  TimeOfDay? _vDesde;
  TimeOfDay? _vHasta;
  TimeOfDay? _sDesde;
  TimeOfDay? _sHasta;
  bool _trabajaSabado = false;
  final TextEditingController _colacionController =
      TextEditingController(text: "60");

  final _formKey = GlobalKey<FormState>();

  Future<void> _selectTime(BuildContext context, TimeOfDay? initialTime,
      Function(TimeOfDay) onTimeSelected) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initialTime ?? const TimeOfDay(hour: 8, minute: 0),
    );
    if (picked != null) {
      onTimeSelected(picked);
    }
  }

  String _formatTime(TimeOfDay? time) {
    if (time == null) return '--:--';
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  TimeOfDay? _parseTime(String timeString) {
    try {
      final parts = timeString.split(':');
      if (parts.length == 2) {
        return TimeOfDay(
            hour: int.parse(parts[0]), minute: int.parse(parts[1]));
      }
    } catch (e) {}
    return null;
  }

  void _parseSchedule(String schedule, Function(TimeOfDay?) onDesde,
      Function(TimeOfDay?) onHasta, bool isFriday) {
    if (schedule.contains('/')) {
      final parts = schedule.split('/');
      if (parts.length == 2) {
        onDesde(_parseTime(parts[0]));
        onHasta(_parseTime(parts[1]));
        return;
      }
    }
    // Fallback if it's the old text format or empty
    onDesde(const TimeOfDay(hour: 8, minute: 0));
    if (isFriday) {
      onHasta(const TimeOfDay(hour: 17, minute: 0));
    } else {
      onHasta(const TimeOfDay(hour: 18, minute: 0));
    }
  }

  @override
  void initState() {
    super.initState();
    _tipoController.text = widget.existingPlace;
    _fetchExistingHours();
  }

  Future<void> _fetchExistingHours() async {
    try {
      var lugaresDoc = await FirebaseFirestore.instance
          .collection('Otros')
          .doc('lugares')
          .get();
      var horasDoc = await FirebaseFirestore.instance
          .collection('Otros')
          .doc('lugares_horas')
          .get();

      if (lugaresDoc.exists && horasDoc.exists) {
        List<String> tipos =
            List<String>.from(lugaresDoc.data()?['tipos'] ?? []);
        List<String> horas =
            List<String>.from(horasDoc.data()?['prueba_horas'] ?? []);
        List<String> lunJueList =
            List<String>.from(horasDoc.data()?['lunes_jueves'] ?? []);
        List<String> vieList =
            List<String>.from(horasDoc.data()?['viernes'] ?? []);
        List<String> sabList =
            List<String>.from(horasDoc.data()?['sabados'] ?? []);
        List<String> colList =
            List<String>.from(horasDoc.data()?['colacion'] ?? []);

        int index = tipos.indexWhere((t) =>
            t.trim().toLowerCase() ==
            widget.existingPlace.trim().toLowerCase());

        setState(() {
          if (index != -1 && index < horas.length) {
            _horasController.text = horas[index].toString();
          } else {
            _horasController.text = "44";
          }

          if (index != -1 && index < lunJueList.length) {
            _parseSchedule(lunJueList[index].toString(), (t) => _ljDesde = t,
                (t) => _ljHasta = t, false);
          } else {
            _ljDesde = const TimeOfDay(hour: 8, minute: 0);
            _ljHasta = const TimeOfDay(hour: 18, minute: 0);
          }

          if (index != -1 && index < vieList.length) {
            _parseSchedule(vieList[index].toString(), (t) => _vDesde = t,
                (t) => _vHasta = t, true);
          } else {
            _vDesde = const TimeOfDay(hour: 8, minute: 0);
            _vHasta = const TimeOfDay(hour: 17, minute: 0);
          }

          if (index != -1 && index < sabList.length) {
            String sabStr = sabList[index].toString();
            if (sabStr != "N/A") {
              _trabajaSabado = true;
              _parseSchedule(
                  sabStr, (t) => _sDesde = t, (t) => _sHasta = t, false);
            } else {
              _trabajaSabado = false;
            }
          } else {
            _trabajaSabado = false;
          }

          if (index != -1 && index < colList.length) {
            _colacionController.text = colList[index].toString();
          } else {
            _colacionController.text = "60";
          }
        });
      }
    } catch (e) {}
  }

  void saveEditPlace() async {
    try {
      String editedLugar = _tipoController.text;
      String horasStr =
          _horasController.text.isNotEmpty ? _horasController.text : "44";

      String formatOrFallback(TimeOfDay? start, TimeOfDay? end,
          String fallbackStart, String fallbackEnd) {
        if (start != null && end != null) {
          return '${_formatTime(start)}/${_formatTime(end)}';
        }
        return '$fallbackStart/$fallbackEnd';
      }

      String lunesJueves =
          formatOrFallback(_ljDesde, _ljHasta, '08:00', '18:00');
      String viernes = formatOrFallback(_vDesde, _vHasta, '08:00', '17:00');

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        DocumentReference lugaresRef =
            FirebaseFirestore.instance.collection('Otros').doc('lugares');
        DocumentReference horasRef =
            FirebaseFirestore.instance.collection('Otros').doc('lugares_horas');

        DocumentSnapshot lugaresSnapshot = await transaction.get(lugaresRef);
        DocumentSnapshot horasSnapshot = await transaction.get(horasRef);

        List<dynamic> tipos =
            lugaresSnapshot.exists && lugaresSnapshot.data() != null
                ? List.from((lugaresSnapshot.data() as Map)['tipos'] ?? [])
                : [];
        List<dynamic> pruebaHoras =
            horasSnapshot.exists && horasSnapshot.data() != null
                ? List.from((horasSnapshot.data() as Map)['prueba_horas'] ?? [])
                : [];
        List<dynamic> lunesJuevesList =
            horasSnapshot.exists && horasSnapshot.data() != null
                ? List.from((horasSnapshot.data() as Map)['lunes_jueves'] ?? [])
                : [];
        List<dynamic> viernesList =
            horasSnapshot.exists && horasSnapshot.data() != null
                ? List.from((horasSnapshot.data() as Map)['viernes'] ?? [])
                : [];
        List<dynamic> sabadosList =
            horasSnapshot.exists && horasSnapshot.data() != null
                ? List.from((horasSnapshot.data() as Map)['sabados'] ?? [])
                : [];
        List<dynamic> colacionList =
            horasSnapshot.exists && horasSnapshot.data() != null
                ? List.from((horasSnapshot.data() as Map)['colacion'] ?? [])
                : [];

        while (pruebaHoras.length < tipos.length) pruebaHoras.add("44");
        while (lunesJuevesList.length < tipos.length)
          lunesJuevesList.add("Lunes a Jueves de 8:00 a 18:00 hrs");
        while (viernesList.length < tipos.length)
          viernesList.add("Viernes de 8:00 a 17:00 hrs");
        while (sabadosList.length < tipos.length) sabadosList.add("N/A");
        while (colacionList.length < tipos.length) colacionList.add("60");

        int index = tipos.indexWhere((t) =>
            t.trim().toLowerCase() ==
            widget.existingPlace.trim().toLowerCase());

        if (index != -1) {
          tipos[index] = editedLugar;
          pruebaHoras[index] = horasStr;
          lunesJuevesList[index] = lunesJueves;
          viernesList[index] = viernes;

          String sabadoValue = _trabajaSabado
              ? formatOrFallback(_sDesde, _sHasta, '08:00', '12:00')
              : "N/A";
          String colacionValue = _colacionController.text.trim();
          if (colacionValue.isEmpty) colacionValue = "60";

          sabadosList[index] = sabadoValue;
          colacionList[index] = colacionValue;

          transaction.update(lugaresRef, {'tipos': tipos});
          transaction.set(
              horasRef,
              {
                'prueba_horas': pruebaHoras,
                'lunes_jueves': lunesJuevesList,
                'viernes': viernesList,
                'sabados': sabadosList,
                'colacion': colacionList,
              },
              SetOptions(merge: true));
        }
      });

      Get.back();
      AnimatedSnackBar.material(
        'Establecimiento editado con éxito',
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
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Container(
                padding: const EdgeInsets.all(16.0),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(16.0)),
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Editar Establecimiento',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      InputTextField(
                        textController: _tipoController,
                        hint: 'Nombre del establecimiento',
                        readOnly: true,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor ingrese un establecimiento';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      InputTextField(
                        textController: _horasController,
                        hint: 'Horas Semanales (ej: 40, 44, 45)',
                        teclado: TextInputType.number,
                        formater: FilteringTextInputFormatter.digitsOnly,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor ingrese las horas manuales';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      InputTextField(
                        teclado: const TextInputType.numberWithOptions(
                            decimal: true),
                        textController: _colacionController,
                        hint: 'Minutos de Colación (Ej: 60 o 45)',
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor ingrese los minutos de colación';
                          }
                          if (int.tryParse(value) == null) {
                            return 'Debe ser un número válido';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      const Text('Horario Lunes a Jueves',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () => _selectTime(context, _ljDesde,
                                  (time) => setState(() => _ljDesde = time)),
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                    labelText: 'Desde',
                                    border: OutlineInputBorder()),
                                child: Text(_formatTime(_ljDesde)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: InkWell(
                              onTap: () => _selectTime(context, _ljHasta,
                                  (time) => setState(() => _ljHasta = time)),
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                    labelText: 'Hasta',
                                    border: OutlineInputBorder()),
                                child: Text(_formatTime(_ljHasta)),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Text('Horario Viernes',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () => _selectTime(context, _vDesde,
                                  (time) => setState(() => _vDesde = time)),
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                    labelText: 'Desde',
                                    border: OutlineInputBorder()),
                                child: Text(_formatTime(_vDesde)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: InkWell(
                              onTap: () => _selectTime(context, _vHasta,
                                  (time) => setState(() => _vHasta = time)),
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                    labelText: 'Hasta',
                                    border: OutlineInputBorder()),
                                child: Text(_formatTime(_vHasta)),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      CheckboxListTile(
                        title: const Text('Trabaja los Sábados'),
                        value: _trabajaSabado,
                        onChanged: (bool? value) {
                          setState(() {
                            _trabajaSabado = value ?? false;
                          });
                        },
                        controlAffinity: ListTileControlAffinity.leading,
                      ),
                      if (_trabajaSabado) ...[
                        const Text('Horario Sábado',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: () => _selectTime(context, _sDesde,
                                    (time) => setState(() => _sDesde = time)),
                                child: InputDecorator(
                                  decoration: const InputDecoration(
                                      labelText: 'Desde',
                                      border: OutlineInputBorder()),
                                  child: Text(_formatTime(_sDesde)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: InkWell(
                                onTap: () => _selectTime(context, _sHasta,
                                    (time) => setState(() => _sHasta = time)),
                                child: InputDecorator(
                                  decoration: const InputDecoration(
                                      labelText: 'Hasta',
                                      border: OutlineInputBorder()),
                                  child: Text(_formatTime(_sHasta)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          CustomButton(
                            funcion: () {
                              Get.back();
                            },
                            texto: 'Cancelar',
                            cancelar: true,
                          ),
                          CustomButton(
                              funcion: () {
                                if (_formKey.currentState!.validate()) {
                                  _formKey.currentState!.save();
                                  saveEditPlace();
                                }
                              },
                              texto: 'Guardar',
                              cancelar: false)
                        ],
                      ),
                    ],
                  ),
                ))));
  }
}

// La funcionalidad de _confirmDeleteLabor y EditLabor ha sido reemplazada por genéricos
