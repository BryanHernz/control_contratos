// ignore_for_file: empty_catches

import 'package:animated_snack_bar/animated_snack_bar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_holo_date_picker/flutter_holo_date_picker.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:responsive_grid_list/responsive_grid_list.dart';
import 'package:rut_utils/rut_utils.dart';
import '../../customs/constants_values.dart';
import '../../customs/widgets_custom.dart';
import '../../models/worker_model.dart';

class NewWorker extends StatefulWidget {
  const NewWorker({super.key});

  @override
  State<NewWorker> createState() => _NewWorkerState();
}

class _NewWorkerState extends State<NewWorker> {
  final TextEditingController _nombresController = TextEditingController();
  final TextEditingController _apellidosController = TextEditingController();
  final TextEditingController _rutController = TextEditingController();
  final TextEditingController _correoController = TextEditingController();
  final TextEditingController _countryController = TextEditingController();
  final TextEditingController _birhtController = TextEditingController();
  final TextEditingController _communeController = TextEditingController();
  final TextEditingController _laborController = TextEditingController();
  final TextEditingController _placeController = TextEditingController();
  final TextEditingController _afpController = TextEditingController();
  final TextEditingController _previsionController = TextEditingController();
  final TextEditingController _ingressController = TextEditingController();
  final TextEditingController _civilStateController = TextEditingController();
  final TextEditingController _adressController = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  void saveNewWorker(WorkerModel worker) {
    try {
      var user = FirebaseAuth.instance.currentUser!;
      FirebaseFirestore.instance.collection('Trabajadores').doc().set({
        'nombres': worker.name!.trim().toLowerCase(),
        'apellidos': worker.lastName!.trim().toLowerCase(),
        'userAdd': user.uid,
        'rut': worker.rut,
        'correo': worker.email!.toLowerCase(),
        'nacionalidad': worker.nacionality!.toLowerCase(),
        'estadoCivil': worker.civilState!.toLowerCase(),
        'fechaNacimiento': worker.birth,
        'direccion': worker.adress!.toLowerCase(),
        'comuna': worker.commune!.toLowerCase(),
        'labor': worker.labor!.toLowerCase(),
        'lugar': worker.place!.toLowerCase(),
        'afp': worker.afp!.toLowerCase(),
        'prevision': worker.prevision!.toLowerCase(),
        'ingreso': worker.ingress,
        'imagenFront': '',
        'imagenBack': '',
      });
      Get.back();
      AnimatedSnackBar.material(
        'Trabajador registrado con éxito',
        mobileSnackBarPosition: MobileSnackBarPosition.top,
        desktopSnackBarPosition: DesktopSnackBarPosition.bottomRight,
        type: AnimatedSnackBarType.success,
      ).show(context);
    } catch (e) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        toolbarHeight: 70,
        automaticallyImplyLeading: false,
        title: const Center(
          child: SubTitleWidget(text: 'Nuevo Trabajador'),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ResponsiveGridList(
          minItemsPerRow: 1,
          maxItemsPerRow: 3,
          horizontalGridMargin: 25,
          verticalGridMargin: 25,
          minItemWidth: 250,
          children: [
            InputTextField(
              teclado: TextInputType.name,
              textController: _nombresController,
              hint: 'Nombres',
              validator: (value) {
                if (value == '') {
                  return 'Por favor ingrese nombres';
                }
                return null;
              },
            ),
            InputTextField(
              teclado: TextInputType.name,
              textController: _apellidosController,
              hint: 'Apellidos',
              validator: (value) {
                if (value == '') {
                  return 'Por favor ingrese apellidos';
                }
                return null;
              },
            ),
            InputTextField(
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
            InputTextField(
              teclado: TextInputType.emailAddress,
              textController: _correoController,
              hint: 'Correo',
              validator: (value) {
                if (!GetUtils.isEmail(value!) && value != '') {
                  return 'Por favor ingrese un correo válido';
                }
                return null;
              },
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 0),
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('Otros')
                    .where('nombre', isEqualTo: 'nacionalidades')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Center();

                  return DropdownButtonFormField2<String>(
                    decoration: InputDecoration(
                      focusedErrorBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: primario),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: primario),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Colors.white),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: primario),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      labelText: 'Nacionalidad',
                      fillColor: Colors.grey[200],
                      filled: true,
                    ),
                    items: [
                      for (var child in snapshot.data!.docs.first['tipos'])
                        DropdownMenuItem<String>(
                          alignment: Alignment.center,
                          value: child,
                          child: Text(
                            child.toString().toUpperCase(),
                            style: const TextStyle(
                              fontSize: 14,
                            ),
                          ),
                        ),
                      DropdownMenuItem(
                        value: '',
                        enabled: false,
                        alignment: Alignment.center,
                        child: TextButton(
                          onPressed: () {
                            Get.back();
                            showCupertinoModalBottomSheet(
                              context: context,
                              builder: (context) => const SizedBox(
                                height: 250,
                                child: NewNacionality(),
                              ),
                            );
                          },
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add,
                                size: 15,
                              ),
                              SizedBox(
                                width: 20,
                              ),
                              Text('Agregar nueva nacionalidad'),
                            ],
                          ),
                        ),
                      ),
                    ],
                    validator: (value) {
                      if (value == null) {
                        return 'Por favor selccione una nacionalidad';
                      }
                      return null;
                    },
                    onChanged: (value) {
                      setState(() {
                        _countryController.text = value!;
                      });
                      //Do something when selected item is changed.
                    },
                    iconStyleData: const IconStyleData(
                      icon: Icon(
                        Icons.arrow_drop_down,
                      ),
                      iconSize: 24,
                    ),
                    dropdownStyleData: DropdownStyleData(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    menuItemStyleData: const MenuItemStyleData(),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 0),
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('Otros')
                    .where('nombre', isEqualTo: 'estadosciviles')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Center();

                  return DropdownButtonFormField2<String>(
                    decoration: InputDecoration(
                      focusedErrorBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: primario),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: primario),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Colors.white),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: primario),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      labelText: 'Estado civil',
                      fillColor: Colors.grey[200],
                      filled: true,
                    ),
                    items: [
                      for (var child in snapshot.data!.docs.first['tipos'])
                        DropdownMenuItem<String>(
                          alignment: Alignment.center,
                          value: child,
                          child: Text(
                            child.toString().toUpperCase(),
                            style: const TextStyle(
                              fontSize: 14,
                            ),
                          ),
                        ),
                      DropdownMenuItem(
                        value: '',
                        enabled: false,
                        alignment: Alignment.center,
                        child: TextButton(
                          onPressed: () {
                            Get.back();
                            showCupertinoModalBottomSheet(
                              context: context,
                              builder: (context) => const SizedBox(
                                height: 250,
                                child: NewCivilState(),
                              ),
                            );
                          },
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add,
                                size: 15,
                              ),
                              SizedBox(
                                width: 20,
                              ),
                              Text('Agregar nuevo estado civil'),
                            ],
                          ),
                        ),
                      ),
                    ],
                    validator: (value) {
                      if (value == null) {
                        return 'Por favor selccione un estado civil';
                      }
                      return null;
                    },
                    onChanged: (value) {
                      setState(() {
                        _civilStateController.text = value!;
                      });
                      //Do something when selected item is changed.
                    },
                    iconStyleData: const IconStyleData(
                      icon: Icon(
                        Icons.arrow_drop_down,
                      ),
                      iconSize: 24,
                    ),
                    dropdownStyleData: DropdownStyleData(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    menuItemStyleData: const MenuItemStyleData(),
                  );
                },
              ),
            ),
            InputTextField(
              teclado: TextInputType.none,
              textController: _birhtController,
              hint: 'Fecha de nacimiento',
              formater: RutFormatter(),
              onTap: () async {
                var datePicked = await DatePicker.showSimpleDatePicker(
                  context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(1950),
                  lastDate: DateTime.now().add(const Duration(days: 30)),
                  dateFormat: "dd-MMMM-yyyy",
                  locale: DateTimePickerLocale.es,
                  looping: true,
                );

                if (datePicked != null) {
                  setState(() {
                    _birhtController.text =
                        DateFormat.yMMMMd('es').format(datePicked).toString();
                  });
                }
              },
              validator: (value) {
                if (value == '') {
                  return 'Por favor ingrese fecha de nacimiento';
                }
                return null;
              },
            ),
            InputTextField(
              teclado: TextInputType.streetAddress,
              textController: _adressController,
              hint: 'Dirección',
              validator: (value) {
                if (value == '') {
                  return 'Por favor ingrese una dirección';
                }
                return null;
              },
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 0),
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('Otros')
                    .where('nombre', isEqualTo: 'comunas')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Center();

                  return DropdownButtonFormField2<String>(
                    decoration: InputDecoration(
                      focusedErrorBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: primario),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: primario),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Colors.white),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: primario),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      labelText: 'Comuna',
                      fillColor: Colors.grey[200],
                      filled: true,
                    ),
                    items: [
                      for (var child in snapshot.data!.docs.first['tipos'])
                        DropdownMenuItem<String>(
                          alignment: Alignment.center,
                          value: child,
                          child: Text(
                            child.toString().toUpperCase(),
                            style: const TextStyle(
                              fontSize: 14,
                            ),
                          ),
                        ),
                      DropdownMenuItem(
                        value: '',
                        enabled: false,
                        alignment: Alignment.center,
                        child: TextButton(
                          onPressed: () {
                            Get.back();
                            showCupertinoModalBottomSheet(
                              context: context,
                              builder: (context) => const SizedBox(
                                height: 250,
                                child: NewCommune(),
                              ),
                            );
                          },
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add,
                                size: 15,
                              ),
                              SizedBox(
                                width: 20,
                              ),
                              Text('Agregar nueva comuna'),
                            ],
                          ),
                        ),
                      ),
                    ],
                    validator: (value) {
                      if (value == null) {
                        return 'Por favor selccione una comuna';
                      }
                      return null;
                    },
                    onChanged: (value) {
                      setState(() {
                        _communeController.text = value!;
                      });
                      //Do something when selected item is changed.
                    },
                    iconStyleData: const IconStyleData(
                      icon: Icon(
                        Icons.arrow_drop_down,
                      ),
                      iconSize: 24,
                    ),
                    dropdownStyleData: DropdownStyleData(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    menuItemStyleData: const MenuItemStyleData(),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 0),
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('Otros')
                    .where('nombre', isEqualTo: 'labores')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Center();

                  return DropdownButtonFormField2<String>(
                    decoration: InputDecoration(
                      focusedErrorBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: primario),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: primario),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Colors.white),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: primario),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      labelText: 'Labor',
                      fillColor: Colors.grey[200],
                      filled: true,
                    ),
                    items: [
                      for (var child in snapshot.data!.docs.first['tipos'])
                        DropdownMenuItem<String>(
                          alignment: Alignment.center,
                          value: child,
                          child: Text(
                            child.toString().toUpperCase(),
                            style: const TextStyle(
                              fontSize: 14,
                            ),
                          ),
                        ),
                      DropdownMenuItem(
                        value: '',
                        enabled: false,
                        alignment: Alignment.center,
                        child: TextButton(
                          onPressed: () {
                            Get.back();
                            showCupertinoModalBottomSheet(
                              context: context,
                              builder: (context) => const SizedBox(
                                height: 250,
                                child: NewLabor(),
                              ),
                            );
                          },
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add,
                                size: 15,
                              ),
                              SizedBox(
                                width: 20,
                              ),
                              Text('Agregar nueva labor'),
                            ],
                          ),
                        ),
                      ),
                    ],
                    validator: (value) {
                      if (value == null) {
                        return 'Por favor selccione una labor';
                      }
                      return null;
                    },
                    onChanged: (value) {
                      setState(() {
                        _laborController.text = value!;
                      });
                      //Do something when selected item is changed.
                    },
                    iconStyleData: const IconStyleData(
                      icon: Icon(
                        Icons.arrow_drop_down,
                      ),
                      iconSize: 24,
                    ),
                    dropdownStyleData: DropdownStyleData(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    menuItemStyleData: const MenuItemStyleData(),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 0),
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('Otros')
                    .where('nombre', isEqualTo: 'lugares')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Center();

                  return DropdownButtonFormField2<String>(
                    decoration: InputDecoration(
                      focusedErrorBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: primario),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: primario),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Colors.white),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: primario),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      labelText: 'Establecimiento',
                      fillColor: Colors.grey[200],
                      filled: true,
                    ),
                    items: [
                      for (var child in snapshot.data!.docs.first['tipos'])
                        DropdownMenuItem<String>(
                          alignment: Alignment.center,
                          value: child,
                          child: Text(
                            child.toString().toUpperCase(),
                            style: const TextStyle(
                              fontSize: 14,
                            ),
                          ),
                        ),
                      DropdownMenuItem(
                        value: '',
                        enabled: false,
                        alignment: Alignment.center,
                        child: TextButton(
                          onPressed: () {
                            Get.back();
                            showCupertinoModalBottomSheet(
                              context: context,
                              builder: (context) => const SizedBox(
                                height: 250,
                                child: NewPlace(),
                              ),
                            );
                          },
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add,
                                size: 15,
                              ),
                              SizedBox(
                                width: 20,
                              ),
                              Text('Agregar nuevo establecimiento'),
                            ],
                          ),
                        ),
                      ),
                    ],
                    validator: (value) {
                      if (value == null) {
                        return 'Por favor selccione un establecimiento';
                      }
                      return null;
                    },
                    onChanged: (value) {
                      setState(() {
                        _placeController.text = value!;
                      });
                      //Do something when selected item is changed.
                    },
                    iconStyleData: const IconStyleData(
                      icon: Icon(
                        Icons.arrow_drop_down,
                      ),
                      iconSize: 24,
                    ),
                    dropdownStyleData: DropdownStyleData(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    menuItemStyleData: const MenuItemStyleData(),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 0),
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('Otros')
                    .where('nombre', isEqualTo: 'afps')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Center();

                  return DropdownButtonFormField2<String>(
                    decoration: InputDecoration(
                      focusedErrorBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: primario),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: primario),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Colors.white),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: primario),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      labelText: 'AFP',
                      fillColor: Colors.grey[200],
                      filled: true,
                    ),
                    items: [
                      for (var child in snapshot.data!.docs.first['tipos'])
                        DropdownMenuItem<String>(
                          alignment: Alignment.center,
                          value: child,
                          child: Text(
                            child.toString().toUpperCase(),
                            style: const TextStyle(
                              fontSize: 14,
                            ),
                          ),
                        ),
                      DropdownMenuItem(
                        value: '',
                        enabled: false,
                        alignment: Alignment.center,
                        child: TextButton(
                          onPressed: () {
                            Get.back();
                            showCupertinoModalBottomSheet(
                              context: context,
                              builder: (context) => const SizedBox(
                                height: 250,
                                child: NewAfp(),
                              ),
                            );
                          },
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add,
                                size: 15,
                              ),
                              SizedBox(
                                width: 20,
                              ),
                              Text('Agregar nueva AFP'),
                            ],
                          ),
                        ),
                      ),
                    ],
                    validator: (value) {
                      if (value == null) {
                        return 'Por favor selccione una AFP';
                      }
                      return null;
                    },
                    onChanged: (value) {
                      setState(() {
                        _afpController.text = value!;
                      });
                      //Do something when selected item is changed.
                    },
                    iconStyleData: const IconStyleData(
                      icon: Icon(
                        Icons.arrow_drop_down,
                      ),
                      iconSize: 24,
                    ),
                    dropdownStyleData: DropdownStyleData(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    menuItemStyleData: const MenuItemStyleData(),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 0),
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('Otros')
                    .where('nombre', isEqualTo: 'previsiones')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Center();

                  return DropdownButtonFormField2<String>(
                    decoration: InputDecoration(
                      focusedErrorBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: primario),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: primario),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Colors.white),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: primario),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      labelText: 'Prevision',
                      fillColor: Colors.grey[200],
                      filled: true,
                    ),
                    items: [
                      for (var child in snapshot.data!.docs.first['tipos'])
                        DropdownMenuItem<String>(
                          alignment: Alignment.center,
                          value: child,
                          child: Text(
                            child.toString().toUpperCase(),
                            style: const TextStyle(
                              fontSize: 14,
                            ),
                          ),
                        ),
                      DropdownMenuItem(
                        value: '',
                        enabled: false,
                        alignment: Alignment.center,
                        child: TextButton(
                          onPressed: () {
                            Get.back();
                            showCupertinoModalBottomSheet(
                              context: context,
                              builder: (context) => const SizedBox(
                                height: 250,
                                child: NewPrevision(),
                              ),
                            );
                          },
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add,
                                size: 15,
                              ),
                              SizedBox(
                                width: 20,
                              ),
                              Text('Agregar nueva prevision'),
                            ],
                          ),
                        ),
                      ),
                    ],
                    validator: (value) {
                      if (value == null) {
                        return 'Por favor selccione una prevision';
                      }
                      return null;
                    },
                    onChanged: (value) {
                      setState(() {
                        _previsionController.text = value!;
                      });
                      //Do something when selected item is changed.
                    },
                    iconStyleData: const IconStyleData(
                      icon: Icon(
                        Icons.arrow_drop_down,
                      ),
                      iconSize: 24,
                    ),
                    dropdownStyleData: DropdownStyleData(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    menuItemStyleData: const MenuItemStyleData(),
                  );
                },
              ),
            ),
            InputTextField(
              teclado: TextInputType.none,
              textController: _ingressController,
              hint: 'Fecha de ingreso',
              formater: RutFormatter(),
              onTap: () async {
                var datePicked = await DatePicker.showSimpleDatePicker(
                  context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(2023),
                  lastDate: DateTime.now().add(const Duration(days: 30)),
                  dateFormat: "dd-MMMM-yyyy",
                  locale: DateTimePickerLocale.es,
                  looping: true,
                );

                if (datePicked != null) {
                  setState(() {
                    _ingressController.text =
                        DateFormat.yMMMMd('es').format(datePicked).toString();
                  });
                }
              },
              validator: (value) {
                if (value == '') {
                  return 'Por favor ingrese fecha de ingreso';
                }
                return null;
              },
            ),
            Padding(
              padding: const EdgeInsets.only(top: 5.0),
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
                          saveNewWorker(
                            WorkerModel(
                              name: _nombresController.text,
                              lastName: _apellidosController.text,
                              rut: _rutController.text,
                              email: _correoController.text,
                              nacionality: _countryController.text,
                              civilState: _civilStateController.text,
                              birth: _birhtController.text,
                              adress: _adressController.text,
                              commune: _communeController.text,
                              labor: _laborController.text,
                              place: _placeController.text,
                              afp: _afpController.text,
                              prevision: _previsionController.text,
                              ingress: _ingressController.text,
                            ),
                          );
                        }
                      },
                      texto: 'Guardar',
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

class NewNacionality extends StatefulWidget {
  const NewNacionality({super.key});

  @override
  State<NewNacionality> createState() => _NewNacionalityState();
}

class _NewNacionalityState extends State<NewNacionality> {
  final TextEditingController _tipoController = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  void saveNewNacionality() {
    try {
      FirebaseFirestore.instance
          .collection('Otros')
          .doc('nacionalidades')
          .update({
        'tipos': FieldValue.arrayUnion([_tipoController.text])
      });
      Get.back();
      AnimatedSnackBar.material(
        'Nacionalidad registrada con éxito',
        mobileSnackBarPosition: MobileSnackBarPosition.top,
        desktopSnackBarPosition: DesktopSnackBarPosition.bottomRight,
        type: AnimatedSnackBarType.success,
      ).show(context);
    } catch (e) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        toolbarHeight: 70,
        automaticallyImplyLeading: false,
        title: const Center(child: SubTitleWidget(text: 'Nueva Nacionalidad')),
      ),
      body: Form(
        key: _formKey,
        child: ResponsiveGridList(
          minItemsPerRow: 1,
          maxItemsPerRow: 2,
          horizontalGridMargin: 25,
          verticalGridMargin: 25,
          minItemWidth: 250,
          children: [
            InputTextField(
              textController: _tipoController,
              hint: 'Nacionalidad',
              validator: (value) {
                if (value == '') {
                  return 'Por favor ingrese una nacionalidad';
                }
                return null;
              },
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
                          saveNewNacionality();
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

class NewCivilState extends StatefulWidget {
  const NewCivilState({super.key});

  @override
  State<NewCivilState> createState() => _NewCivilStateState();
}

class _NewCivilStateState extends State<NewCivilState> {
  final TextEditingController _tipoController = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  void saveNewNacionality() {
    try {
      FirebaseFirestore.instance
          .collection('Otros')
          .doc('estadosciviles')
          .update({
        'tipos': FieldValue.arrayUnion([_tipoController.text])
      });
      Get.back();
      AnimatedSnackBar.material(
        'Estado civil registrado con éxito',
        mobileSnackBarPosition: MobileSnackBarPosition.top,
        desktopSnackBarPosition: DesktopSnackBarPosition.bottomRight,
        type: AnimatedSnackBarType.success,
      ).show(context);
    } catch (e) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        toolbarHeight: 70,
        automaticallyImplyLeading: false,
        title: const Center(child: SubTitleWidget(text: 'Nuevo estado civil')),
      ),
      body: Form(
        key: _formKey,
        child: ResponsiveGridList(
          minItemsPerRow: 1,
          maxItemsPerRow: 2,
          horizontalGridMargin: 25,
          verticalGridMargin: 25,
          minItemWidth: 250,
          children: [
            InputTextField(
              textController: _tipoController,
              hint: 'Estado civil',
              validator: (value) {
                if (value == '') {
                  return 'Por favor ingrese un estado civil';
                }
                return null;
              },
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
                          saveNewNacionality();
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

class NewCommune extends StatefulWidget {
  const NewCommune({super.key});

  @override
  State<NewCommune> createState() => _NewCommuneState();
}

class _NewCommuneState extends State<NewCommune> {
  final TextEditingController _tipoController = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  void saveNewCommune() {
    try {
      FirebaseFirestore.instance.collection('Otros').doc('comunas').update({
        'tipos': FieldValue.arrayUnion([_tipoController.text])
      });
      Get.back();
      AnimatedSnackBar.material(
        'Comuna registrada con éxito',
        mobileSnackBarPosition: MobileSnackBarPosition.top,
        desktopSnackBarPosition: DesktopSnackBarPosition.bottomRight,
        type: AnimatedSnackBarType.success,
      ).show(context);
    } catch (e) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        toolbarHeight: 70,
        automaticallyImplyLeading: false,
        title: const Center(child: SubTitleWidget(text: 'Nueva comuna')),
      ),
      body: Form(
        key: _formKey,
        child: ResponsiveGridList(
          minItemsPerRow: 1,
          maxItemsPerRow: 2,
          horizontalGridMargin: 25,
          verticalGridMargin: 25,
          minItemWidth: 250,
          children: [
            InputTextField(
              textController: _tipoController,
              hint: 'Comuna',
              validator: (value) {
                if (value == '') {
                  return 'Por favor ingrese una comuna';
                }
                return null;
              },
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
                          saveNewCommune();
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

class NewLabor extends StatefulWidget {
  const NewLabor({super.key});

  @override
  State<NewLabor> createState() => _NewLaborState();
}

class _NewLaborState extends State<NewLabor> {
  final TextEditingController _tipoController = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  void saveNewLabor() {
    try {
      FirebaseFirestore.instance.collection('Otros').doc('labores').update({
        'tipos': FieldValue.arrayUnion([_tipoController.text])
      });
      Get.back();
      AnimatedSnackBar.material(
        'Labor registrada con éxito',
        mobileSnackBarPosition: MobileSnackBarPosition.top,
        desktopSnackBarPosition: DesktopSnackBarPosition.bottomRight,
        type: AnimatedSnackBarType.success,
      ).show(context);
    } catch (e) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        toolbarHeight: 70,
        automaticallyImplyLeading: false,
        title: const Center(child: SubTitleWidget(text: 'Nueva labor')),
      ),
      body: Form(
        key: _formKey,
        child: ResponsiveGridList(
          minItemsPerRow: 1,
          maxItemsPerRow: 2,
          horizontalGridMargin: 25,
          verticalGridMargin: 25,
          minItemWidth: 250,
          children: [
            InputTextField(
              textController: _tipoController,
              hint: 'Labor',
              validator: (value) {
                if (value == '') {
                  return 'Por favor ingrese una labor';
                }
                return null;
              },
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
                          saveNewLabor();
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

class NewPlace extends StatefulWidget {
  const NewPlace({super.key});

  @override
  State<NewPlace> createState() => _NewPlaceState();
}

class _NewPlaceState extends State<NewPlace> {
  final TextEditingController _tipoController = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  void saveNewPlace() {
    try {
      FirebaseFirestore.instance.collection('Otros').doc('lugares').update({
        'tipos': FieldValue.arrayUnion([_tipoController.text])
      });
      Get.back();
      AnimatedSnackBar.material(
        'Establecimiento registrado con éxito',
        mobileSnackBarPosition: MobileSnackBarPosition.top,
        desktopSnackBarPosition: DesktopSnackBarPosition.bottomRight,
        type: AnimatedSnackBarType.success,
      ).show(context);
    } catch (e) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        toolbarHeight: 70,
        automaticallyImplyLeading: false,
        title:
            const Center(child: SubTitleWidget(text: 'Nuevo establecimiento')),
      ),
      body: Form(
        key: _formKey,
        child: ResponsiveGridList(
          minItemsPerRow: 1,
          maxItemsPerRow: 2,
          horizontalGridMargin: 25,
          verticalGridMargin: 25,
          minItemWidth: 250,
          children: [
            InputTextField(
              textController: _tipoController,
              hint: 'Establecimiento',
              validator: (value) {
                if (value == '') {
                  return 'Por favor ingrese un establecimiento';
                }
                return null;
              },
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
                          saveNewPlace();
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

class NewAfp extends StatefulWidget {
  const NewAfp({super.key});

  @override
  State<NewAfp> createState() => _NewAfpState();
}

class _NewAfpState extends State<NewAfp> {
  final TextEditingController _tipoController = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  void saveNewAfp() {
    try {
      FirebaseFirestore.instance.collection('Otros').doc('afps').update({
        'tipos': FieldValue.arrayUnion([_tipoController.text])
      });
      Get.back();
      AnimatedSnackBar.material(
        'AFP registrada con éxito',
        mobileSnackBarPosition: MobileSnackBarPosition.top,
        desktopSnackBarPosition: DesktopSnackBarPosition.bottomRight,
        type: AnimatedSnackBarType.success,
      ).show(context);
    } catch (e) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        toolbarHeight: 70,
        automaticallyImplyLeading: false,
        title: const Center(child: SubTitleWidget(text: 'Nueva AFP')),
      ),
      body: Form(
        key: _formKey,
        child: ResponsiveGridList(
          minItemsPerRow: 1,
          maxItemsPerRow: 2,
          horizontalGridMargin: 25,
          verticalGridMargin: 25,
          minItemWidth: 250,
          children: [
            InputTextField(
              textController: _tipoController,
              hint: 'AFP',
              validator: (value) {
                if (value == '') {
                  return 'Por favor ingrese una AFP';
                }
                return null;
              },
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
                          saveNewAfp();
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

class NewPrevision extends StatefulWidget {
  const NewPrevision({super.key});

  @override
  State<NewPrevision> createState() => _NewPrevisionState();
}

class _NewPrevisionState extends State<NewPrevision> {
  final TextEditingController _tipoController = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  void saveNewPrevision() {
    try {
      FirebaseFirestore.instance.collection('Otros').doc('previsiones').update({
        'tipos': FieldValue.arrayUnion([_tipoController.text])
      });
      Get.back();
      AnimatedSnackBar.material(
        'Prevision registrada con éxito',
        mobileSnackBarPosition: MobileSnackBarPosition.top,
        desktopSnackBarPosition: DesktopSnackBarPosition.bottomRight,
        type: AnimatedSnackBarType.success,
      ).show(context);
    } catch (e) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        toolbarHeight: 70,
        automaticallyImplyLeading: false,
        title: const Center(child: SubTitleWidget(text: 'Nueva prevision')),
      ),
      body: Form(
        key: _formKey,
        child: ResponsiveGridList(
          minItemsPerRow: 1,
          maxItemsPerRow: 2,
          horizontalGridMargin: 25,
          verticalGridMargin: 25,
          minItemWidth: 250,
          children: [
            InputTextField(
              textController: _tipoController,
              hint: 'Prevision',
              validator: (value) {
                if (value == '') {
                  return 'Por favor ingrese una prevision';
                }
                return null;
              },
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
                          saveNewPrevision();
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
