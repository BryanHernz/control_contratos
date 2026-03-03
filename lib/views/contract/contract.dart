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
import '../widgets/settings_dialogs.dart';

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
                  return InkWell(
                    onTap: () {},
                    child: ListTile(
                      // hoverColor: Colors.grey[100], // ListTile hover is limited
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
                                  maxWidth:
                                      MediaQuery.of(context).size.width > 800
                                          ? 900
                                          : MediaQuery.of(context).size.width *
                                              0.95),
                              backgroundColor: Colors.white,
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.vertical(
                                    top: Radius.circular(16)),
                              ),
                              context: context,
                              builder: (context) => Padding(
                                padding: EdgeInsets.only(
                                    bottom: MediaQuery.of(context)
                                        .viewInsets
                                        .bottom),
                                child: const NewEnterpriseData(),
                              ),
                            );
                          },
                          icon: const Icon(
                            Icons.edit_document,
                            color: Colors.blueGrey,
                          )),
                    ),
                  );
                } else if (doc['nombre'] == 'contratosmont') {
                  return InkWell(
                    onTap: () {},
                    child: ListTile(
                      // hoverColor: Colors.grey[100],
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
                                  maxWidth:
                                      MediaQuery.of(context).size.width > 800
                                          ? 900
                                          : MediaQuery.of(context).size.width *
                                              0.95),
                              backgroundColor: Colors.white,
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.vertical(
                                    top: Radius.circular(16)),
                              ),
                              context: context,
                              builder: (context) => Padding(
                                padding: EdgeInsets.only(
                                    bottom: MediaQuery.of(context)
                                        .viewInsets
                                        .bottom),
                                child: const NewAmount(),
                              ),
                            );
                          },
                          icon: const Icon(
                            Icons.edit_document,
                            color: Colors.blueGrey,
                          )),
                    ),
                  );
                } else if (doc['nombre'] == 'labores') {
                  final labores = doc['tipos'] as List<dynamic>;
                  return InkWell(
                    onTap: () {},
                    child: ListTile(
                      // hoverColor: Colors.grey[100],
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
                            _manageGenericCategory(
                                context, 'labores', 'Labores');
                          },
                          icon: const Icon(
                            Icons.edit_document,
                            color: Colors.blueGrey,
                          )),
                    ),
                  );
                } else if (doc['nombre'] == 'lugares') {
                  final lugares = doc['tipos'];
                  return InkWell(
                    onTap: () {},
                    child: ListTile(
                      // hoverColor: Colors.grey[100],
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
                              builder: (context) =>
                                  StreamBuilder<QuerySnapshot>(
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

                                  final localDocLugares = modalSnapshot
                                      .data!.docs
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
                                                    title:
                                                        Text(localLugares[i]),
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
                                                    subtitle: Builder(
                                                      builder: (ctx) {
                                                        final lj =
                                                            localHorariosLunesAJueves[
                                                                    i]
                                                                .toString()
                                                                .replaceAll(
                                                                    '/', ' a ');
                                                        final v =
                                                            localHorariosViernes[
                                                                    i]
                                                                .toString()
                                                                .replaceAll(
                                                                    '/', ' a ');
                                                        final mismoHorario =
                                                            localHorariosLunesAJueves[
                                                                    i] ==
                                                                localHorariosViernes[
                                                                    i];
                                                        return Text(
                                                          mismoHorario
                                                              ? 'Horario: Lunes a Viernes de $lj'
                                                              : 'Horario: Lunes a Jueves de $lj - Viernes de $v',
                                                        );
                                                      },
                                                    ),
                                                    trailing: IconButton(
                                                      icon: const Icon(
                                                          Icons.edit,
                                                          color:
                                                              Colors.blueGrey),
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
                                                                            .circular(2),
                                                                  ),
                                                                ),
                                                                const SizedBox(
                                                                    height: 12),
                                                                Flexible(
                                                                  child:
                                                                      ClipRRect(
                                                                    borderRadius: const BorderRadius
                                                                        .vertical(
                                                                        top: Radius.circular(
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
                                            TextButton.icon(
                                              onPressed: () {
                                                showModalBottomSheet(
                                                  context: context,
                                                  isScrollControlled: true,
                                                  useSafeArea: true,
                                                  backgroundColor: Colors.white,
                                                  shape:
                                                      const RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.vertical(
                                                            top:
                                                                Radius.circular(
                                                                    16)),
                                                  ),
                                                  builder: (context) =>
                                                      const NewPlace(),
                                                );
                                              },
                                              icon: const Icon(Icons.add,
                                                  size: 18),
                                              label: const Text(
                                                  'Agregar nuevo establecimiento'),
                                            ),
                                            const SizedBox(height: 12),
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
                    ),
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
                  return InkWell(
                    onTap: () {},
                    child: ListTile(
                      // hoverColor: Colors.grey[100],
                      leading: Text(label),
                      minLeadingWidth: 80,
                      title: Text(tipos.length.toString()),
                      subtitle: Text('$label disponibles'),
                      trailing: IconButton(
                          onPressed: () {
                            _manageGenericCategory(
                                context, doc['nombre'], label);
                          },
                          icon: const Icon(
                            Icons.edit_document,
                            color: Colors.blueGrey,
                          )),
                    ),
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
