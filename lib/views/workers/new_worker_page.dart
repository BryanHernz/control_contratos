// ignore_for_file: empty_catches

import 'package:animated_snack_bar/animated_snack_bar.dart';
import 'package:calendar_date_picker2/calendar_date_picker2.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
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
    return Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
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
                        'Nueva Nacionalidad',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
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
                                  saveNewNacionality();
                                }
                              },
                              texto: 'Agregar',
                              cancelar: false)
                        ],
                      ),
                    ],
                  ),
                )),
          ],
        ));
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
                        'Nuevo estado civil',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
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
                                  saveNewNacionality();
                                }
                              },
                              texto: 'Agregar',
                              cancelar: false)
                        ],
                      ),
                    ],
                  ),
                ))));
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
                        'Nueva comuna',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
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
                                  saveNewCommune();
                                }
                              },
                              texto: 'Agregar',
                              cancelar: false)
                        ],
                      ),
                    ],
                  ),
                ))));
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
                        'Nueva labor',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
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
                                  saveNewLabor();
                                }
                              },
                              texto: 'Agregar',
                              cancelar: false)
                        ],
                      ),
                    ],
                  ),
                ))));
  }
}

class NewPlace extends StatefulWidget {
  const NewPlace({super.key});

  @override
  State<NewPlace> createState() => _NewPlaceState();
}

class _NewPlaceState extends State<NewPlace> {
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

  void saveNewPlace() async {
    try {
      String nuevoLugar = _tipoController.text.trim();
      String horasLugar = _horasController.text.trim();

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

      if (horasLugar.isEmpty) horasLugar = "44";
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

        // Asegurar que los arrays tengan la misma longitud antes de agregar
        while (pruebaHoras.length < tipos.length) pruebaHoras.add("44");
        while (lunesJuevesList.length < tipos.length)
          lunesJuevesList.add("Lunes a Jueves de 8:00 a 18:00 hrs");
        while (viernesList.length < tipos.length)
          viernesList.add("Viernes de 8:00 a 17:00 hrs");
        while (sabadosList.length < tipos.length) sabadosList.add("N/A");
        while (colacionList.length < tipos.length) colacionList.add("1");

        String sabadoValue = _trabajaSabado
            ? formatOrFallback(_sDesde, _sHasta, '08:00', '12:00')
            : "N/A";
        String colacionValue = _colacionController.text.trim();
        if (colacionValue.isEmpty) colacionValue = "60";

        tipos.add(nuevoLugar);
        pruebaHoras.add(horasLugar);
        lunesJuevesList.add(lunesJueves);
        viernesList.add(viernes);
        sabadosList.add(sabadoValue);
        colacionList.add(colacionValue);

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
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          padding: const EdgeInsets.all(16.0),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16.0)),
          ),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Nuevo establecimiento',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
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
                const SizedBox(height: 16),
                // Nuevo campo para las horas semanales
                InputTextField(
                  teclado: TextInputType.number,
                  textController: _horasController,
                  hint: 'Horas Semanales (Ej: 40 o 44)',
                  validator: (value) {
                    if (value == '') {
                      return 'Por favor ingrese las horas semanales';
                    }
                    if (int.tryParse(value!) == null) {
                      return 'Debe ser un número válido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                InputTextField(
                  teclado: const TextInputType.numberWithOptions(decimal: true),
                  textController: _colacionController,
                  hint: 'Minutos de Colación (Ej: 60 o 45)',
                  validator: (value) {
                    if (value == '') {
                      return 'Por favor ingrese los minutos de colación';
                    }
                    if (int.tryParse(value!) == null) {
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
                              labelText: 'Desde', border: OutlineInputBorder()),
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
                              labelText: 'Hasta', border: OutlineInputBorder()),
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
                              labelText: 'Desde', border: OutlineInputBorder()),
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
                              labelText: 'Hasta', border: OutlineInputBorder()),
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
                            saveNewPlace();
                          }
                        },
                        texto: 'Agregar',
                        cancelar: false)
                  ],
                ),
              ],
            ),
          ),
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
                        'Nueva AFP',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
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
                                  saveNewAfp();
                                }
                              },
                              texto: 'Agregar',
                              cancelar: false)
                        ],
                      ),
                    ],
                  ),
                ))));
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
                        'Nueva prevision',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
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
                                  saveNewPrevision();
                                }
                              },
                              texto: 'Agregar',
                              cancelar: false)
                        ],
                      ),
                    ],
                  ),
                ))));
  }
}
