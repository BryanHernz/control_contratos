// ignore_for_file: must_be_immutable, non_constant_identifier_names, avoid_types_as_parameter_names
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

    final number = int.tryParse(newValue.text.replaceAll(RegExp(r'[^0-9]'), ''));
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
      this.decimal});

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

  @override
  Widget build(BuildContext context) {
    helper = helper ?? false;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0.0),
      child: TextFormField(
        keyboardType: teclado,
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
        controller: textController,
        validator: validator,
        decoration: InputDecoration(
          suffixIcon: helper!
              ? Tooltip(
                  margin: const EdgeInsets.only(left: 60, right: 30),
                  decoration: BoxDecoration(
                      color: primario, borderRadius: BorderRadius.circular(5)),
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
              : null,
          prefixText: prefix,
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
          labelText: hint,
          fillColor: Colors.grey[200],
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
  });
  final VoidCallback funcion;
  final String texto;
  final bool cancelar;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: funcion,
      child: Container(
        height: 40,
        width: 150,
        padding: const EdgeInsets.symmetric(horizontal: 15),
        decoration: BoxDecoration(
          color: cancelar ? const Color.fromRGBO(43, 43, 43, 1) : primario,
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
    );
  }
}
