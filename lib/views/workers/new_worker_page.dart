// ignore_for_file: empty_catches

import 'package:animated_snack_bar/animated_snack_bar.dart';
import 'package:calendar_date_picker2/calendar_date_picker2.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:responsive_grid_list/responsive_grid_list.dart';
import 'package:rut_utils/rut_utils.dart';
import '../../customs/constants_values.dart';
import '../../customs/widgets_custom.dart';
import '../../models/worker_model.dart';
import '../widgets/settings_dialogs.dart';

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
    return Padding(
      padding: const EdgeInsets.all(8.0),
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
          const SubTitleWidget(text: 'Nuevo Trabajador'),
          Flexible(
            flex: 1,
            child: Form(
              key: _formKey,
              child: ResponsiveGridList(
                minItemsPerRow: 1,
                maxItemsPerRow: 2,
                horizontalGridMargin: 25,
                shrinkWrap: true,
                verticalGridMargin: 25,
                minItemWidth: 350,
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
                          isExpanded: true,
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
                            for (var child
                                in snapshot.data!.docs.first['tipos'])
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
                                  showModalBottomSheet(
                                    context: context,
                                    isScrollControlled: true,
                                    backgroundColor: Colors.white,
                                    shape: const RoundedRectangleBorder(
                                      borderRadius: BorderRadius.vertical(
                                          top: Radius.circular(16)),
                                    ),
                                    builder: (context) => Container(
                                      constraints: BoxConstraints(
                                          maxHeight: MediaQuery.of(context)
                                                  .size
                                                  .height *
                                              0.85),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const SizedBox(height: 12),
                                          Container(
                                            width: 40,
                                            height: 4,
                                            decoration: BoxDecoration(
                                              color: Colors.black12,
                                              borderRadius:
                                                  BorderRadius.circular(2),
                                            ),
                                          ),
                                          const SizedBox(height: 12),
                                          const Flexible(
                                            child: ClipRRect(
                                              borderRadius:
                                                  BorderRadius.vertical(
                                                      top: Radius.circular(16)),
                                              child: NewNacionality(),
                                            ),
                                          ),
                                        ],
                                      ),
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
                          isExpanded: true,
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
                            for (var child
                                in snapshot.data!.docs.first['tipos'])
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
                                  showModalBottomSheet(
                                    context: context,
                                    isScrollControlled: true,
                                    backgroundColor: Colors.white,
                                    shape: const RoundedRectangleBorder(
                                      borderRadius: BorderRadius.vertical(
                                          top: Radius.circular(16)),
                                    ),
                                    builder: (context) => Container(
                                      constraints: BoxConstraints(
                                          maxHeight: MediaQuery.of(context)
                                                  .size
                                                  .height *
                                              0.85),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const SizedBox(height: 12),
                                          Container(
                                            width: 40,
                                            height: 4,
                                            decoration: BoxDecoration(
                                              color: Colors.black12,
                                              borderRadius:
                                                  BorderRadius.circular(2),
                                            ),
                                          ),
                                          const SizedBox(height: 12),
                                          const Flexible(
                                            child: ClipRRect(
                                              borderRadius:
                                                  BorderRadius.vertical(
                                                      top: Radius.circular(16)),
                                              child: NewCivilState(),
                                            ),
                                          ),
                                        ],
                                      ),
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
                      final datePicked = await showCalendarDatePicker2Dialog(
                        context: context,
                        config: CalendarDatePicker2WithActionButtonsConfig(
                          calendarType: CalendarDatePicker2Type.single,
                          selectedDayHighlightColor: primario,
                          firstDate: DateTime(1950),
                          lastDate:
                              DateTime.now(), // No permitir fechas futuras
                          currentDate: DateTime.now(),
                        ),
                        dialogSize: const Size(325, 400),
                        value: _birhtController.text.isNotEmpty
                            ? [
                                DateFormat.yMMMMd('es')
                                    .parse(_birhtController.text)
                              ]
                            : [DateTime.now()],
                      );

                      if (datePicked != null && datePicked.isNotEmpty) {
                        setState(() {
                          _birhtController.text = DateFormat.yMMMMd('es')
                              .format(datePicked.first!)
                              .toString();
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
                          isExpanded: true,
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
                            for (var child
                                in snapshot.data!.docs.first['tipos'])
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
                                  showModalBottomSheet(
                                    context: context,
                                    isScrollControlled: true,
                                    backgroundColor: Colors.white,
                                    shape: const RoundedRectangleBorder(
                                      borderRadius: BorderRadius.vertical(
                                          top: Radius.circular(16)),
                                    ),
                                    builder: (context) => Container(
                                      constraints: BoxConstraints(
                                          maxHeight: MediaQuery.of(context)
                                                  .size
                                                  .height *
                                              0.85),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const SizedBox(height: 12),
                                          Container(
                                            width: 40,
                                            height: 4,
                                            decoration: BoxDecoration(
                                              color: Colors.black12,
                                              borderRadius:
                                                  BorderRadius.circular(2),
                                            ),
                                          ),
                                          const SizedBox(height: 12),
                                          const Flexible(
                                            child: ClipRRect(
                                              borderRadius:
                                                  BorderRadius.vertical(
                                                      top: Radius.circular(16)),
                                              child: NewCommune(),
                                            ),
                                          ),
                                        ],
                                      ),
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
                          isExpanded: true,
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
                            for (var child
                                in snapshot.data!.docs.first['tipos'])
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
                                  showModalBottomSheet(
                                    context: context,
                                    isScrollControlled: true,
                                    backgroundColor: Colors.white,
                                    shape: const RoundedRectangleBorder(
                                      borderRadius: BorderRadius.vertical(
                                          top: Radius.circular(16)),
                                    ),
                                    builder: (context) => Container(
                                      constraints: BoxConstraints(
                                          maxHeight: MediaQuery.of(context)
                                                  .size
                                                  .height *
                                              0.85),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const SizedBox(height: 12),
                                          Container(
                                            width: 40,
                                            height: 4,
                                            decoration: BoxDecoration(
                                              color: Colors.black12,
                                              borderRadius:
                                                  BorderRadius.circular(2),
                                            ),
                                          ),
                                          const SizedBox(height: 12),
                                          const Flexible(
                                            child: ClipRRect(
                                              borderRadius:
                                                  BorderRadius.vertical(
                                                      top: Radius.circular(16)),
                                              child: NewLabor(),
                                            ),
                                          ),
                                        ],
                                      ),
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
                          isExpanded: true,
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
                            for (var child
                                in snapshot.data!.docs.first['tipos'])
                              DropdownMenuItem<String>(
                                alignment: Alignment.center,
                                value: child,
                                child: Text(
                                  child.toString().toUpperCase(),
                                  style: const TextStyle(fontSize: 14),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            DropdownMenuItem(
                              value: '',
                              enabled: false,
                              alignment: Alignment.center,
                              child: TextButton(
                                onPressed: () {
                                  Get.back();
                                  showModalBottomSheet(
                                    context: context,
                                    isScrollControlled: true,
                                    backgroundColor: Colors.white,
                                    shape: const RoundedRectangleBorder(
                                      borderRadius: BorderRadius.vertical(
                                          top: Radius.circular(16)),
                                    ),
                                    builder: (context) => Container(
                                      constraints: BoxConstraints(
                                          maxHeight: MediaQuery.of(context)
                                                  .size
                                                  .height *
                                              0.85),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const SizedBox(height: 12),
                                          Container(
                                            width: 40,
                                            height: 4,
                                            decoration: BoxDecoration(
                                              color: Colors.black12,
                                              borderRadius:
                                                  BorderRadius.circular(2),
                                            ),
                                          ),
                                          const SizedBox(height: 12),
                                          const Flexible(
                                            child: ClipRRect(
                                              borderRadius:
                                                  BorderRadius.vertical(
                                                      top: Radius.circular(16)),
                                              child: NewPlace(),
                                            ),
                                          ),
                                        ],
                                      ),
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
                          isExpanded: true,
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
                            for (var child
                                in snapshot.data!.docs.first['tipos'])
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
                                  showModalBottomSheet(
                                    context: context,
                                    isScrollControlled: true,
                                    backgroundColor: Colors.white,
                                    shape: const RoundedRectangleBorder(
                                      borderRadius: BorderRadius.vertical(
                                          top: Radius.circular(16)),
                                    ),
                                    builder: (context) => Container(
                                      constraints: BoxConstraints(
                                          maxHeight: MediaQuery.of(context)
                                                  .size
                                                  .height *
                                              0.85),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const SizedBox(height: 12),
                                          Container(
                                            width: 40,
                                            height: 4,
                                            decoration: BoxDecoration(
                                              color: Colors.black12,
                                              borderRadius:
                                                  BorderRadius.circular(2),
                                            ),
                                          ),
                                          const SizedBox(height: 12),
                                          const Flexible(
                                            child: ClipRRect(
                                              borderRadius:
                                                  BorderRadius.vertical(
                                                      top: Radius.circular(16)),
                                              child: NewAfp(),
                                            ),
                                          ),
                                        ],
                                      ),
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
                          isExpanded: true,
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
                            for (var child
                                in snapshot.data!.docs.first['tipos'])
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
                                  showModalBottomSheet(
                                    context: context,
                                    isScrollControlled: true,
                                    backgroundColor: Colors.white,
                                    shape: const RoundedRectangleBorder(
                                      borderRadius: BorderRadius.vertical(
                                          top: Radius.circular(16)),
                                    ),
                                    builder: (context) => Container(
                                      constraints: BoxConstraints(
                                          maxHeight: MediaQuery.of(context)
                                                  .size
                                                  .height *
                                              0.85),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const SizedBox(height: 12),
                                          Container(
                                            width: 40,
                                            height: 4,
                                            decoration: BoxDecoration(
                                              color: Colors.black12,
                                              borderRadius:
                                                  BorderRadius.circular(2),
                                            ),
                                          ),
                                          const SizedBox(height: 12),
                                          const Flexible(
                                            child: ClipRRect(
                                              borderRadius:
                                                  BorderRadius.vertical(
                                                      top: Radius.circular(16)),
                                              child: NewPrevision(),
                                            ),
                                          ),
                                        ],
                                      ),
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
                      final datePicked = await showCalendarDatePicker2Dialog(
                        context: context,
                        config: CalendarDatePicker2WithActionButtonsConfig(
                          calendarType: CalendarDatePicker2Type.single,
                          selectedDayHighlightColor: primario,
                          firstDate: DateTime(2023),
                          lastDate:
                              DateTime.now().add(const Duration(days: 30)),
                          currentDate: DateTime.now(),
                        ),
                        dialogSize: const Size(325, 400),
                        value: _ingressController.text.isNotEmpty
                            ? [
                                DateFormat.yMMMMd('es')
                                    .parse(_ingressController.text)
                              ]
                            : [DateTime.now()],
                      );

                      if (datePicked != null && datePicked.isNotEmpty) {
                        setState(() {
                          _ingressController.text = DateFormat.yMMMMd('es')
                              .format(datePicked.first!)
                              .toString();
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
          ),
        ],
      ),
    );
  }
}
