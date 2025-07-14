// ignore_for_file: empty_catches, deprecated_member_use
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart' hide ModalBottomSheetRoute;
import '../../../customs/widgets_custom.dart';

class RegisterPage extends StatefulWidget {
  final VoidCallback showLoginPage;
  const RegisterPage({
    super.key,
    required this.showLoginPage,
  });

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  //Text controllers
  final _nameController = TextEditingController();
  final _lastnameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _lastnameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future signUp() async {
    if (passwordConfirmed()) {
      try {
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
        await FirebaseFirestore.instance
            .collection('Usuarios')
            .doc(FirebaseAuth.instance.currentUser!.uid.toString())
            .set({
          'email': _emailController.text.trim(),
          'nombre': _nameController.text.trim(),
          'apellido': _lastnameController.text.trim(),
          'uid': FirebaseAuth.instance.currentUser!.uid.toString(),
          'tipo': 1,
          'ocupacion': '--',
          'telefono': '--',
          'seller': false,
        });
      } catch (e) {}
    }
  }

  bool passwordConfirmed() {
    if (_passwordController.text.trim() ==
        _confirmPasswordController.text.trim()) {
      return true;
    } else {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              height: 90,
            ),
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                /*Padding(
                  padding: EdgeInsets.only(left: 30.0),
                  child: TitleWidget(
                    text: 'Registro de usuario',
                  ),
                ),*/
                LogoImage(),
              ],
            ),
            const SizedBox(height: 25),
            InputTextField(
              textController: _nameController,
              hint: 'Nombre',
            ),
            const SizedBox(height: 20),
            InputTextField(
              textController: _lastnameController,
              hint: 'Apellido',
            ),
            const SizedBox(height: 20),
            InputTextField(
              textController: _emailController,
              hint: 'Correo',
            ),
            const SizedBox(height: 20),
            InputTextField(
              textController: _passwordController,
              hint: 'Contraseña',
              passwordField: true,
            ),
            const SizedBox(height: 20),
            InputTextField(
              textController: _confirmPasswordController,
              hint: 'Confirmar contraseña',
              passwordField: true,
            ),
            const SizedBox(height: 20),
            SubmitButton(funcion: signUp, texto: 'Registrarse'),
            const SizedBox(height: 25),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  '¿Ya tienes cuenta?,',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                GestureDetector(
                  onTap: widget.showLoginPage,
                  child: const Text(
                    ' ¡Ingresa ahora!',
                    style: TextStyle(
                      color: Colors.teal,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
              ],
            ),
            const SizedBox(
              height: 50,
            ),
          ],
        ),
      ),
    );
  }
}
