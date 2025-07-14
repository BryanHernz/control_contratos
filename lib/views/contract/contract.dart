// ignore_for_file: empty_catches

import 'package:animated_snack_bar/animated_snack_bar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:rut_utils/rut_utils.dart';
import 'package:spelling_number/spelling_number.dart';

import '../../customs/constants_values.dart';
import '../../customs/widgets_custom.dart';

class ContractPage extends StatefulWidget {
  const ContractPage({super.key});

  @override
  State<ContractPage> createState() => _ContractPageState();
}

class _ContractPageState extends State<ContractPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                .where('nombre', whereIn: ['contratosmont', 'empresadata'])
              .snapshots(),
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
                    minLeadingWidth: 60,
                    title: Text(doc['nombreempresa']),
                    subtitle: Text(doc['rut']),
                    trailing: IconButton(onPressed: (){
                      showCupertinoModalBottomSheet(
                        context: context,
                        builder: (context) => const NewEnterpriseData(),
                      );
                    }, icon: const Icon(Icons.edit_document,color: Colors.blueGrey,)),
                  );
                } else if (doc['nombre'] == 'contratosmont') {
                  return ListTile(
                    leading: const Text('Monto diario'),
                    minLeadingWidth: 60,
                    title: Text(
                      numfor.format(snapshot.data!.docs.first['montonum'],),
                    ),
                    subtitle: Text(snapshot.data!.docs.first['montotext'],),
                    trailing: IconButton(onPressed: (){
                      showCupertinoModalBottomSheet(
                        context: context,
                        builder: (context) => const NewAmount(),
                      );
                    }, icon: const Icon(Icons.edit_document,color: Colors.blueGrey,)),
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
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: const Text('Datos de la empresa'),
      ),
      body: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
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
                        cancelar: false)
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
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: const Text('Nuevo monto diario'),
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
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
                      cancelar: false)
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
