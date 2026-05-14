// ignore_for_file: must_be_immutable, non_constant_identifier_names, avoid_types_as_parameter_names
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'constants_values.dart';

// Definición de la clase que reemplaza a ThousandsFormatter
class ThousandsFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: '');
    }

    final number =
        int.tryParse(newValue.text.replaceAll(RegExp(r'[^0-9]'), ''));
    if (number == null) {
      return oldValue;
    }

    final formatter = NumberFormat.decimalPattern('es_CL');
    final newString = formatter.format(number);

    return TextEditingValue(
      text: newString,
      selection: TextSelection.collapsed(offset: newString.length),
    );
  }
}

class InputTextField extends StatelessWidget {
  InputTextField(
      {super.key,
      required this.textController,
      required this.hint,
      this.passwordField,
      this.onChanged,
      this.validator,
      this.formater,
      this.prefix,
      this.onTap,
      this.money,
      this.teclado,
      this.help,
      this.helper,
      this.readOnly,
      this.decimal,
      this.suffixIcon,
      this.onFieldSubmitted});

  final TextEditingController textController;
  final String hint;
  bool? passwordField, money;
  TextInputFormatter? formater;
  Function(String)? onChanged;
  bool? helper;
  Function()? onTap;
  bool? decimal;
  String? help;
  String? Function(String?)? validator;
  String? prefix;
  TextInputType? teclado;
  bool? readOnly;
  Widget? suffixIcon;
  Function(String)? onFieldSubmitted;

  @override
  Widget build(BuildContext context) {
    helper = helper ?? false;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0.0),
      child: TextFormField(
        keyboardType: teclado,
        style: const TextStyle(
          color: Colors.black54,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        inputFormatters: [
          if (formater != null) ...[formater!],
          if (money == true && money!) ...[ThousandsFormatter()],
          if (decimal == true && decimal!) ...[
            FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))
          ],
        ],
        onTap: onTap,
        obscureText: passwordField ?? false,
        onChanged: onChanged,
        onFieldSubmitted: onFieldSubmitted,
        readOnly: readOnly ?? false,
        controller: textController,
        validator: validator,
        decoration: InputDecoration(
          suffixIcon: suffixIcon ??
              (helper!
                  ? Tooltip(
                      margin: const EdgeInsets.only(left: 60, right: 30),
                      decoration: BoxDecoration(
                          color: primario,
                          borderRadius: BorderRadius.circular(5)),
                      textStyle: const TextStyle(color: Colors.white),
                      verticalOffset: 10,
                      waitDuration: const Duration(seconds: 1),
                      message: help,
                      child: Icon(
                        CupertinoIcons.info,
                        color: secundario.withOpacity(0.3),
                        size: 16,
                      ),
                    )
                  : null),
          prefixText: prefix,
          focusedErrorBorder: OutlineInputBorder(
            borderSide: BorderSide(color: primario),
            borderRadius: BorderRadius.circular(14),
          ),
          errorBorder: OutlineInputBorder(
            borderSide: BorderSide(color: primario),
            borderRadius: BorderRadius.circular(14),
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.white.withOpacity(0.9)),
            borderRadius: BorderRadius.circular(14),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: primario.withOpacity(0.72)),
            borderRadius: BorderRadius.circular(14),
          ),
          labelText: hint,
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
          fillColor: Colors.white.withOpacity(0.62),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          filled: true,
        ),
      ),
    );
  }
}

class LogoImage extends StatelessWidget {
  const LogoImage({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Image.asset(
        'lib/images/CONTRATO.png',
        width: MediaQuery.of(context).size.width * 0.50,
        height: MediaQuery.of(context).size.height * 0.2,
      ),
    );
  }
}

class SubmitButton extends StatelessWidget {
  const SubmitButton({
    super.key,
    required this.funcion,
    required this.texto,
  });
  final VoidCallback funcion;
  final String texto;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25.0),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: funcion,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: primario,
              borderRadius: BorderRadius.circular(5),
            ),
            child: Center(
              child: Text(
                texto,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class TitleWidget extends StatelessWidget {
  const TitleWidget({
    super.key,
    required this.text,
  });

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 30,
        fontWeight: FontWeight.w800,
      ),
      textAlign: TextAlign.center,
    );
  }
}

class AppTitleWidget extends StatelessWidget {
  const AppTitleWidget({
    super.key,
    required this.text,
    this.color,
    this.align,
    this.size,
  });

  final String text;
  final Color? color;
  final TextAlign? align;
  final double? size;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
      child: Text(
        overflow: TextOverflow.fade,
        text,
        textAlign: align ?? TextAlign.center,
        style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: size ?? 15,
            color: color ?? Colors.black54),
      ),
    );
  }
}

class SubTitleWidget extends StatelessWidget {
  const SubTitleWidget({
    super.key,
    required this.text,
    this.color,
    this.align,
  });

  final String text;
  final Color? color;
  final TextAlign? align;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 25.0),
      child: Text(
        maxLines: 2,
        text,
        textAlign: align ?? TextAlign.center,
        style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: color ?? Colors.black54),
      ),
    );
  }
}

class CustomButton extends StatelessWidget {
  const CustomButton({
    super.key,
    required this.funcion,
    required this.texto,
    this.cancelar = false,
    this.icon,
    this.width,
  });
  final VoidCallback funcion;
  final String texto;
  final bool cancelar;
  final IconData? icon;
  final double? width;

  @override
  Widget build(BuildContext context) {
    final isPrimary = !cancelar;
    final backgroundColor =
        isPrimary ? primario : Colors.white.withOpacity(0.66);
    final foregroundColor = isPrimary ? Colors.white : Colors.blueGrey.shade800;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: SizedBox(
        height: 52,
        width: width ?? 150,
        child: Material(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: funcion,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isPrimary
                      ? Colors.transparent
                      : Colors.white.withOpacity(0.92),
                ),
                boxShadow: isPrimary
                    ? [
                        BoxShadow(
                          color: primario.withOpacity(0.28),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: Colors.white.withOpacity(0.75),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 18, color: foregroundColor),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    texto,
                    style: TextStyle(
                      color: foregroundColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class GlassPanel extends StatelessWidget {
  const GlassPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.borderRadius = const BorderRadius.all(Radius.circular(16)),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: double.infinity,
          padding: padding,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white.withOpacity(0.78),
                Colors.white.withOpacity(0.58),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: borderRadius,
            border: Border.all(color: Colors.white.withOpacity(0.92)),
            boxShadow: [
              BoxShadow(
                color: Colors.blueGrey.shade900.withOpacity(0.08),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class CustomButton2 extends StatelessWidget {
  const CustomButton2({
    super.key,
    required this.funcion,
    required this.texto,
    this.cancelar = false,
  });
  final VoidCallback funcion;
  final String texto;
  final bool cancelar;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: funcion,
        child: Container(
          height: 40,
          width: 200,
          padding: const EdgeInsets.symmetric(horizontal: 15),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(5),
            border: Border.all(color: primario, width: 1),
          ),
          child: Center(
            child: Text(
              texto,
              style: TextStyle(
                color: primario,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
