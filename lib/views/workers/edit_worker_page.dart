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
import '../../customs/app_colors.dart';
import '../../customs/widgets/app_modal.dart';
import '../../customs/constants_values.dart';
import '../../customs/widgets_custom.dart';
import '../../models/worker_model.dart';
import '../widgets/settings_dialogs.dart';

class EditWorker extends StatefulWidget {
  const EditWorker({super.key, required this.worker});

  final WorkerModel worker;

  @override
  State<EditWorker> createState() => _EditWorkerState();
}

class _EditWorkerState extends State<EditWorker> {
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

  /// Envoltura fina sobre [showAppModal] para los "crear al vuelo" (labor,
  /// lugar, comuna...) que se abren desde el formulario.
  Future<void> _openQuickCreateSheet({
    required String title,
    required IconData icon,
    required String hint,
    required Widget child,
  }) {
    return showAppModal<void>(
      context: context,
      title: title,
      icon: icon,
      hint: hint,
      maxWidth: 820,
      child: child,
    );
  }

  InputDecoration _dropdownDecoration({
    required String label,
    String? hintText,
  }) {
    return InputDecoration(
      focusedErrorBorder: OutlineInputBorder(
        borderSide: BorderSide(color: primario),
        borderRadius: BorderRadius.circular(14),
      ),
      errorBorder: OutlineInputBorder(
        borderSide: BorderSide(color: primario),
        borderRadius: BorderRadius.circular(14),
      ),
      // Mismo borde visible que InputTextField: antes el desplegable se
      // distinguia solo por el relleno gris y no parecia un campo.
      enabledBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: AppColors.border),
        borderRadius: BorderRadius.circular(14),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: primario, width: 1.6),
        borderRadius: BorderRadius.circular(14),
      ),
      labelText: label,
      labelStyle: const TextStyle(
        color: AppColors.textMuted,
        fontSize: 14.5,
        fontWeight: FontWeight.w600,
      ),
      floatingLabelBehavior: FloatingLabelBehavior.always,
      hintText: hintText,
      hintStyle: _dropdownValueStyle.copyWith(color: AppColors.textFaint),
      fillColor: Colors.white,
      filled: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    );
  }

  TextStyle get _dropdownValueStyle =>
      Theme.of(context).textTheme.titleMedium?.copyWith(
            color: AppColors.textStrong,
            fontWeight: FontWeight.w600,
          ) ??
      const TextStyle(
        color: AppColors.textStrong,
        fontWeight: FontWeight.w600,
      );

  IconStyleData _dropdownIconStyleData() => const IconStyleData(
        icon: Icon(
          Icons.keyboard_arrow_down_rounded,
          color: AppColors.iconMuted,
        ),
        iconSize: 22,
      );

  DropdownStyleData _dropdownStyleData() => DropdownStyleData(
        maxHeight: 300,
        elevation: 8,
        offset: const Offset(0, 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.blueGrey.shade100),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 14,
              offset: const Offset(0, 8),
            ),
          ],
        ),
      );

  MenuItemStyleData _dropdownMenuItemStyleData() => const MenuItemStyleData(
        height: 46,
        padding: EdgeInsets.symmetric(horizontal: 12),
      );

  Widget _buildDropdownOptionText(String option, {bool ellipsis = false}) {
    return Text(
      option.trim().toLowerCase(),
      style: _dropdownValueStyle,
      textAlign: TextAlign.left,
      maxLines: 1,
      overflow: ellipsis ? TextOverflow.ellipsis : TextOverflow.visible,
    );
  }

  static const String _createOptionPrefix = '__create__:';
  int _dropdownRefreshSeed = 0;

  String _createOptionValue(String type) => '$_createOptionPrefix$type';

  bool _isCreateOption(String? value) =>
      value?.startsWith(_createOptionPrefix) ?? false;

  List<String> _dropdownOptions(
    dynamic sourceOptions, {
    String currentValue = '',
  }) {
    if (sourceOptions is! List) return const [];
    final seen = <String>{};
    final options = <String>[];
    for (final raw in sourceOptions) {
      final option = raw.toString().trim();
      if (option.isEmpty) continue;
      final key = option.toLowerCase();
      if (seen.add(key)) {
        options.add(option);
      }
    }

    final normalizedCurrent = currentValue.trim();
    if (normalizedCurrent.isNotEmpty) {
      final exists = options.any(
        (option) =>
            option.trim().toLowerCase() == normalizedCurrent.toLowerCase(),
      );
      if (!exists) {
        options.insert(0, normalizedCurrent);
      }
    }

    return options;
  }

  String? _resolvedDropdownValue({
    required String currentValue,
    required List<String> sourceOptions,
  }) {
    final normalizedCurrent = currentValue.trim();
    if (normalizedCurrent.isEmpty) return null;

    final exactMatches =
        sourceOptions.where((option) => option == normalizedCurrent).toList();
    if (exactMatches.length == 1) {
      return exactMatches.first;
    }

    final ciMatches = sourceOptions
        .where(
          (option) =>
              option.trim().toLowerCase() == normalizedCurrent.toLowerCase(),
        )
        .toList();

    if (ciMatches.length == 1) {
      return ciMatches.first;
    }

    return null;
  }

  Future<void> _openCreateFromDropdown({
    required String title,
    required IconData icon,
    required String hint,
    required Widget child,
  }) async {
    Get.back();
    setState(() => _dropdownRefreshSeed++);
    await _openQuickCreateSheet(
      title: title,
      icon: icon,
      hint: hint,
      child: child,
    );
    if (mounted) {
      setState(() => _dropdownRefreshSeed++);
    }
  }

  Widget _buildCreateDropdownOption({
    required String text,
  }) {
    return Container(
      constraints: const BoxConstraints(minHeight: 36, maxWidth: 340),
      decoration: BoxDecoration(
        color: primario.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: primario.withOpacity(0.28)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.add_circle_outline_rounded,
            size: 17,
            color: primario,
          ),
          const SizedBox(width: 8),
          Text(
            text.toUpperCase(),
            style: TextStyle(
              color: primario,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarActionButton({
    required String text,
    required bool filled,
  }) {
    return Container(
      constraints: const BoxConstraints(minWidth: 118, minHeight: 40),
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: filled ? primario : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: filled ? primario : Colors.blueGrey.shade200,
        ),
        boxShadow: filled
            ? [
                BoxShadow(
                  color: primario.withOpacity(0.24),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          color: filled ? Colors.white : Colors.blueGrey.shade700,
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  CalendarDatePicker2WithActionButtonsConfig _buildDatePickerConfig({
    required DateTime firstDate,
    required DateTime lastDate,
    required DateTime currentDate,
  }) {
    final titleStyle = Theme.of(context).textTheme.titleMedium;
    final bodyStyle = Theme.of(context).textTheme.bodyMedium;
    final captionStyle = Theme.of(context).textTheme.bodySmall;

    return CalendarDatePicker2WithActionButtonsConfig(
      calendarType: CalendarDatePicker2Type.single,
      firstDate: firstDate,
      lastDate: lastDate,
      currentDate: currentDate,
      modePickerTextHandler: ({required monthDate, isMonthPicker}) {
        if (isMonthPicker ?? false) {
          return DateFormat.MMMM('es').format(monthDate).toUpperCase();
        }
        return DateFormat.y('es').format(monthDate).toUpperCase();
      },
      selectedDayHighlightColor: primario,
      dayBorderRadius: BorderRadius.circular(999),
      controlsTextStyle: titleStyle?.copyWith(
            color: Colors.blueGrey.shade700,
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ) ??
          TextStyle(
            color: Colors.blueGrey.shade700,
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
      weekdayLabelTextStyle: captionStyle?.copyWith(
            color: AppColors.textMuted,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ) ??
          const TextStyle(
            color: AppColors.textMuted,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
      dayTextStyle: bodyStyle?.copyWith(
            color: Colors.blueGrey.shade600,
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ) ??
          TextStyle(
            color: Colors.blueGrey.shade600,
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
      selectedDayTextStyle: bodyStyle?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ) ??
          const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
      todayTextStyle: bodyStyle?.copyWith(
            color: primario,
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ) ??
          TextStyle(
            color: primario,
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
      disabledDayTextStyle: bodyStyle?.copyWith(
            color: Colors.blueGrey.shade200,
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ) ??
          TextStyle(
            color: Colors.blueGrey.shade200,
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
      monthTextStyle: bodyStyle?.copyWith(
            color: Colors.blueGrey.shade700,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ) ??
          TextStyle(
            color: Colors.blueGrey.shade700,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
      selectedMonthTextStyle: bodyStyle?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ) ??
          const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
      yearTextStyle: bodyStyle?.copyWith(
            color: Colors.blueGrey.shade700,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ) ??
          TextStyle(
            color: Colors.blueGrey.shade700,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
      selectedYearTextStyle: bodyStyle?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ) ??
          const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
      nextMonthIcon: Icon(
        Icons.chevron_right_rounded,
        color: Colors.blueGrey.shade700,
        size: 22,
      ),
      lastMonthIcon: Icon(
        Icons.chevron_left_rounded,
        color: Colors.blueGrey.shade700,
        size: 22,
      ),
      gapBetweenCalendarAndButtons: 12,
      buttonPadding: const EdgeInsets.fromLTRB(8, 4, 8, 12),
      cancelButton: _buildCalendarActionButton(
        text: 'Cancelar',
        filled: false,
      ),
      okButton: _buildCalendarActionButton(
        text: 'Aceptar',
        filled: true,
      ),
    );
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      saveWorker(
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
  }

  void saveWorker(WorkerModel worker) {
    try {
      var user = FirebaseAuth.instance.currentUser!;
      FirebaseFirestore.instance
          .collection('Trabajadores')
          .doc(widget.worker.id)
          .update({
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
      });
      Get.back();
      Get.back();
      AnimatedSnackBar.material(
        'Trabajador modificado con éxito',
        mobileSnackBarPosition: MobileSnackBarPosition.top,
        desktopSnackBarPosition: DesktopSnackBarPosition.bottomRight,
        type: AnimatedSnackBarType.success,
      ).show(context);
    } catch (e) {}
  }

  @override
  Widget build(BuildContext context) {
    _nombresController.text = _nombresController.text.isEmpty
        ? widget.worker.name ?? ""
        : _nombresController.text;
    _apellidosController.text = _apellidosController.text.isEmpty
        ? widget.worker.lastName ?? ""
        : _apellidosController.text;
    _rutController.text = _rutController.text.isEmpty
        ? widget.worker.rut ?? ""
        : _rutController.text;
    _correoController.text = _correoController.text.isEmpty
        ? widget.worker.email ?? ""
        : _correoController.text;
    _countryController.text = _countryController.text.isEmpty
        ? widget.worker.nacionality ?? ""
        : _countryController.text;
    _birhtController.text = _birhtController.text.isEmpty
        ? widget.worker.birth ?? ""
        : _birhtController.text;
    _communeController.text = _communeController.text.isEmpty
        ? widget.worker.commune ?? ""
        : _communeController.text;
    _laborController.text = _laborController.text.isEmpty
        ? widget.worker.labor ?? ""
        : _laborController.text;
    _placeController.text = _placeController.text.isEmpty
        ? widget.worker.place ?? ""
        : _placeController.text;
    _afpController.text = _afpController.text.isEmpty
        ? widget.worker.afp ?? ""
        : _afpController.text;
    _previsionController.text = _previsionController.text.isEmpty
        ? widget.worker.prevision ?? ""
        : _previsionController.text;
    _ingressController.text = _ingressController.text.isEmpty
        ? widget.worker.ingress ?? ""
        : _ingressController.text;
    _civilStateController.text = _civilStateController.text.isEmpty
        ? widget.worker.civilState ?? ""
        : _civilStateController.text;
    _adressController.text = _adressController.text.isEmpty
        ? widget.worker.adress ?? ""
        : _adressController.text;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
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
                  onFieldSubmitted: (_) => _submitForm(),
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
                  onFieldSubmitted: (_) => _submitForm(),
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
                  onFieldSubmitted: (_) => _submitForm(),
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
                  onFieldSubmitted: (_) => _submitForm(),
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
                      final options = _dropdownOptions(
                        snapshot.data!.docs.first['tipos'],
                        currentValue: _countryController.text,
                      );

                      return DropdownButtonFormField2<String>(
                        key: ValueKey('country-$_dropdownRefreshSeed'),
                        value: _resolvedDropdownValue(
                          currentValue: _countryController.text,
                          sourceOptions: options,
                        ),
                        isExpanded: true,
                        alignment: AlignmentDirectional.centerStart,
                        decoration: _dropdownDecoration(
                          label: 'Nacionalidad',
                          hintText: widget.worker.nacionality,
                        ),
                        style: _dropdownValueStyle,
                        items: [
                          for (var child in options)
                            DropdownMenuItem<String>(
                              alignment: AlignmentDirectional.centerStart,
                              value: child,
                              child: _buildDropdownOptionText(child),
                            ),
                          DropdownMenuItem<String>(
                            value: _createOptionValue('country'),
                            alignment: AlignmentDirectional.centerStart,
                            child: _buildCreateDropdownOption(
                              text: 'Agregar nueva nacionalidad',
                            ),
                          ),
                        ],
                        onChanged: (value) {
                          if (_isCreateOption(value)) {
                            _openCreateFromDropdown(
                              title: 'Nueva nacionalidad',
                              icon: Icons.flag_outlined,
                              hint:
                                  'Ingresa la nacionalidad del trabajador para completar su informacion personal.',
                              child: const NewNacionality(),
                            );
                            return;
                          }
                          if (value == null) return;
                          setState(() {
                            _countryController.text = value;
                          });
                          //Do something when selected item is changed.
                        },
                        iconStyleData: _dropdownIconStyleData(),
                        dropdownStyleData: _dropdownStyleData(),
                        menuItemStyleData: _dropdownMenuItemStyleData(),
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
                      final options = _dropdownOptions(
                        snapshot.data!.docs.first['tipos'],
                        currentValue: _civilStateController.text,
                      );

                      return DropdownButtonFormField2<String>(
                        key: ValueKey('civil-$_dropdownRefreshSeed'),
                        value: _resolvedDropdownValue(
                          currentValue: _civilStateController.text,
                          sourceOptions: options,
                        ),
                        isExpanded: true,
                        alignment: AlignmentDirectional.centerStart,
                        decoration: _dropdownDecoration(
                          label: 'Estado civil',
                          hintText: widget.worker.civilState,
                        ),
                        style: _dropdownValueStyle,
                        items: [
                          for (var child in options)
                            DropdownMenuItem<String>(
                              alignment: AlignmentDirectional.centerStart,
                              value: child,
                              child: _buildDropdownOptionText(child),
                            ),
                          DropdownMenuItem<String>(
                            value: _createOptionValue('civil'),
                            alignment: AlignmentDirectional.centerStart,
                            child: _buildCreateDropdownOption(
                              text: 'Agregar nuevo estado civil',
                            ),
                          ),
                        ],
                        onChanged: (value) {
                          if (_isCreateOption(value)) {
                            _openCreateFromDropdown(
                              title: 'Nuevo estado civil',
                              icon: Icons.favorite_border_rounded,
                              hint:
                                  'Selecciona o crea el estado civil actual del trabajador.',
                              child: const NewCivilState(),
                            );
                            return;
                          }
                          if (value == null) return;
                          setState(() {
                            _civilStateController.text = value;
                          });
                          //Do something when selected item is changed.
                        },
                        iconStyleData: _dropdownIconStyleData(),
                        dropdownStyleData: _dropdownStyleData(),
                        menuItemStyleData: _dropdownMenuItemStyleData(),
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
                    // Lógica de DatePicker original:
                    // var datePicked = await DatePicker.showSimpleDatePicker(
                    //   context,
                    //   initialDate: DateTime.now(),
                    //   firstDate: DateTime(1950),
                    //   lastDate: DateTime.now().add(const Duration(days: 30)),
                    //   dateFormat: "dd-MMMM-yyyy",
                    //   locale: DateTimePickerLocale.es,
                    //   looping: true,
                    // );

                    // 🚀 CAMBIO: Usando calendar_date_picker2
                    DateTime initialDate;
                    try {
                      initialDate =
                          DateFormat.yMMMMd('es').parse(_birhtController.text);
                    } catch (_) {
                      initialDate = DateTime.now();
                    }

                    final datePicked = await showCalendarDatePicker2Dialog(
                      context: context,
                      config: _buildDatePickerConfig(
                        firstDate: DateTime(1950),
                        lastDate: DateTime.now().add(const Duration(days: 30)),
                        currentDate: initialDate,
                      ),
                      dialogSize: const Size(350, 420),
                      borderRadius: BorderRadius.circular(18),
                      dialogBackgroundColor: Colors.white,
                      value: [initialDate],
                    );
                    // --------------------------------------------------------

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
                  onFieldSubmitted: (_) => _submitForm(),
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
                      final options = _dropdownOptions(
                        snapshot.data!.docs.first['tipos'],
                        currentValue: _communeController.text,
                      );

                      return DropdownButtonFormField2<String>(
                        key: ValueKey('commune-$_dropdownRefreshSeed'),
                        value: _resolvedDropdownValue(
                          currentValue: _communeController.text,
                          sourceOptions: options,
                        ),
                        isExpanded: true,
                        alignment: AlignmentDirectional.centerStart,
                        decoration: _dropdownDecoration(
                          label: 'Comuna',
                          hintText: widget.worker.commune,
                        ),
                        style: _dropdownValueStyle,
                        items: [
                          for (var child in options)
                            DropdownMenuItem<String>(
                              alignment: AlignmentDirectional.centerStart,
                              value: child,
                              child: _buildDropdownOptionText(child),
                            ),
                          DropdownMenuItem<String>(
                            value: _createOptionValue('commune'),
                            alignment: AlignmentDirectional.centerStart,
                            child: _buildCreateDropdownOption(
                              text: 'Agregar nueva comuna',
                            ),
                          ),
                        ],
                        onChanged: (value) {
                          if (_isCreateOption(value)) {
                            _openCreateFromDropdown(
                              title: 'Nueva comuna',
                              icon: Icons.location_city_outlined,
                              hint:
                                  'Ingresa la comuna de residencia del trabajador.',
                              child: const NewCommune(),
                            );
                            return;
                          }
                          if (value == null) return;
                          setState(() {
                            _communeController.text = value;
                          });
                          //Do something when selected item is changed.
                        },
                        iconStyleData: _dropdownIconStyleData(),
                        dropdownStyleData: _dropdownStyleData(),
                        menuItemStyleData: _dropdownMenuItemStyleData(),
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
                      final options = _dropdownOptions(
                        snapshot.data!.docs.first['tipos'],
                        currentValue: _laborController.text,
                      );

                      return DropdownButtonFormField2<String>(
                        key: ValueKey('labor-$_dropdownRefreshSeed'),
                        value: _resolvedDropdownValue(
                          currentValue: _laborController.text,
                          sourceOptions: options,
                        ),
                        isExpanded: true,
                        alignment: AlignmentDirectional.centerStart,
                        decoration: _dropdownDecoration(
                          label: 'Labor',
                          hintText: widget.worker.labor,
                        ),
                        style: _dropdownValueStyle,
                        items: [
                          for (var child in options)
                            DropdownMenuItem<String>(
                              alignment: AlignmentDirectional.centerStart,
                              value: child,
                              child: _buildDropdownOptionText(child),
                            ),
                          DropdownMenuItem<String>(
                            value: _createOptionValue('labor'),
                            alignment: AlignmentDirectional.centerStart,
                            child: _buildCreateDropdownOption(
                              text: 'Agregar nueva labor',
                            ),
                          ),
                        ],
                        onChanged: (value) {
                          if (_isCreateOption(value)) {
                            _openCreateFromDropdown(
                              title: 'Nueva labor',
                              icon: Icons.construction_outlined,
                              hint:
                                  'Define la labor o cargo que desempenara el trabajador.',
                              child: const NewLabor(),
                            );
                            return;
                          }
                          if (value == null) return;
                          setState(() {
                            _laborController.text = value;
                          });
                          //Do something when selected item is changed.
                        },
                        iconStyleData: _dropdownIconStyleData(),
                        dropdownStyleData: _dropdownStyleData(),
                        menuItemStyleData: _dropdownMenuItemStyleData(),
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
                      final options = _dropdownOptions(
                        snapshot.data!.docs.first['tipos'],
                        currentValue: _placeController.text,
                      );

                      return DropdownButtonFormField2<String>(
                        key: ValueKey('place-$_dropdownRefreshSeed'),
                        value: _resolvedDropdownValue(
                          currentValue: _placeController.text,
                          sourceOptions: options,
                        ),
                        isExpanded: true,
                        alignment: AlignmentDirectional.centerStart,
                        decoration: _dropdownDecoration(
                          label: 'Establecimiento',
                          hintText: widget.worker.place,
                        ),
                        style: _dropdownValueStyle,
                        items: [
                          for (var child in options)
                            DropdownMenuItem<String>(
                              alignment: AlignmentDirectional.centerStart,
                              value: child,
                              child: _buildDropdownOptionText(
                                child,
                                ellipsis: true,
                              ),
                            ),
                          DropdownMenuItem<String>(
                            value: _createOptionValue('place'),
                            alignment: AlignmentDirectional.centerStart,
                            child: _buildCreateDropdownOption(
                              text: 'Agregar nuevo establecimiento',
                            ),
                          ),
                        ],
                        onChanged: (value) {
                          if (_isCreateOption(value)) {
                            _openCreateFromDropdown(
                              title: 'Nuevo establecimiento',
                              icon: Icons.business_outlined,
                              hint:
                                  'Crea el establecimiento donde el trabajador prestara servicios.',
                              child: const NewPlace(),
                            );
                            return;
                          }
                          if (value == null) return;
                          setState(() {
                            _placeController.text = value;
                          });
                          //Do something when selected item is changed.
                        },
                        iconStyleData: _dropdownIconStyleData(),
                        dropdownStyleData: _dropdownStyleData(),
                        menuItemStyleData: _dropdownMenuItemStyleData(),
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
                      final options = _dropdownOptions(
                        snapshot.data!.docs.first['tipos'],
                        currentValue: _afpController.text,
                      );

                      return DropdownButtonFormField2<String>(
                        key: ValueKey('afp-$_dropdownRefreshSeed'),
                        value: _resolvedDropdownValue(
                          currentValue: _afpController.text,
                          sourceOptions: options,
                        ),
                        isExpanded: true,
                        alignment: AlignmentDirectional.centerStart,
                        decoration: _dropdownDecoration(
                          label: 'AFP',
                          hintText: widget.worker.afp,
                        ),
                        style: _dropdownValueStyle,
                        items: [
                          for (var child in options)
                            DropdownMenuItem<String>(
                              alignment: AlignmentDirectional.centerStart,
                              value: child,
                              child: _buildDropdownOptionText(child),
                            ),
                          DropdownMenuItem<String>(
                            value: _createOptionValue('afp'),
                            alignment: AlignmentDirectional.centerStart,
                            child: _buildCreateDropdownOption(
                              text: 'Agregar nueva AFP',
                            ),
                          ),
                        ],
                        onChanged: (value) {
                          if (_isCreateOption(value)) {
                            _openCreateFromDropdown(
                              title: 'Nueva AFP',
                              icon: Icons.savings_outlined,
                              hint:
                                  'Registra la AFP correspondiente a las cotizaciones del trabajador.',
                              child: const NewAfp(),
                            );
                            return;
                          }
                          if (value == null) return;
                          setState(() {
                            _afpController.text = value;
                          });
                          //Do something when selected item is changed.
                        },
                        iconStyleData: _dropdownIconStyleData(),
                        dropdownStyleData: _dropdownStyleData(),
                        menuItemStyleData: _dropdownMenuItemStyleData(),
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
                      final options = _dropdownOptions(
                        snapshot.data!.docs.first['tipos'],
                        currentValue: _previsionController.text,
                      );

                      return DropdownButtonFormField2<String>(
                        key: ValueKey('prevision-$_dropdownRefreshSeed'),
                        value: _resolvedDropdownValue(
                          currentValue: _previsionController.text,
                          sourceOptions: options,
                        ),
                        isExpanded: true,
                        alignment: AlignmentDirectional.centerStart,
                        decoration: _dropdownDecoration(
                          label: 'Prevision',
                          hintText: widget.worker.prevision,
                        ),
                        style: _dropdownValueStyle,
                        items: [
                          for (var child in options)
                            DropdownMenuItem<String>(
                              alignment: AlignmentDirectional.centerStart,
                              value: child,
                              child: _buildDropdownOptionText(child),
                            ),
                          DropdownMenuItem<String>(
                            value: _createOptionValue('prevision'),
                            alignment: AlignmentDirectional.centerStart,
                            child: _buildCreateDropdownOption(
                              text: 'Agregar nueva prevision',
                            ),
                          ),
                        ],
                        onChanged: (value) {
                          if (_isCreateOption(value)) {
                            _openCreateFromDropdown(
                              title: 'Nueva prevision',
                              icon: Icons.local_hospital_outlined,
                              hint:
                                  'Registra la institucion de salud previsional del trabajador.',
                              child: const NewPrevision(),
                            );
                            return;
                          }
                          if (value == null) return;
                          setState(() {
                            _previsionController.text = value;
                          });
                          //Do something when selected item is changed.
                        },
                        iconStyleData: _dropdownIconStyleData(),
                        dropdownStyleData: _dropdownStyleData(),
                        menuItemStyleData: _dropdownMenuItemStyleData(),
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
                    // Lógica de DatePicker original:
                    // await DatePicker.showSimpleDatePicker(
                    //   context,
                    //   initialDate: DateTime.now(),
                    //   firstDate: DateTime(2023),
                    //   lastDate: DateTime.now().add(const Duration(days: 30)),
                    //   dateFormat: "dd-MMMM-yyyy",
                    //   locale: DateTimePickerLocale.es,
                    //   looping: true,
                    // ).then((value) => {
                    //       setState(() {
                    //         _ingressController.text =
                    //             DateFormat.yMMMMd('es').format(value!).toString();
                    //       }),
                    //     });

                    // 🚀 CAMBIO: Usando calendar_date_picker2
                    DateTime initialDate;
                    try {
                      initialDate = DateFormat.yMMMMd('es')
                          .parse(_ingressController.text);
                    } catch (_) {
                      initialDate = DateTime.now();
                    }

                    final datePicked = await showCalendarDatePicker2Dialog(
                      context: context,
                      config: _buildDatePickerConfig(
                        firstDate: DateTime(2023),
                        lastDate: DateTime.now().add(const Duration(days: 30)),
                        currentDate: initialDate,
                      ),
                      dialogSize: const Size(350, 420),
                      borderRadius: BorderRadius.circular(18),
                      dialogBackgroundColor: Colors.white,
                      value: [initialDate],
                    );

                    if (datePicked != null && datePicked.isNotEmpty) {
                      setState(() {
                        _ingressController.text = DateFormat.yMMMMd('es')
                            .format(datePicked.first!)
                            .toString();
                      });
                    }
                    // --------------------------------------------------------
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
                    children: [
                      Expanded(
                        child: CustomButton(
                          funcion: () {
                            Get.back();
                          },
                          texto: 'Cancelar',
                          cancelar: true,
                          icon: Icons.close_rounded,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: CustomButton(
                          funcion: _submitForm,
                          texto: 'Guardar',
                          cancelar: false,
                          icon: Icons.check_rounded,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
