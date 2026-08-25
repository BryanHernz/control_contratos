// ignore_for_file: empty_catches, deprecated_member_use
import 'package:animated_snack_bar/animated_snack_bar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart' hide ModalBottomSheetRoute;
import '../../../customs/widgets_custom.dart';
import '../../../utils/user_access.dart';
import '../../../services/firestore_db.dart';

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

  /// Alta por cuenta propia.
  ///
  /// El enlace que lleva aqui esta comentado en la pantalla de login, asi que
  /// hoy no se alcanza desde la interfaz, pero la ficha que creaba salia con
  /// `activo: true` y -- con los defaults viejos -- con TODOS los permisos,
  /// `manageUsers` incluido. Quien llegara a esta pantalla quedaba de
  /// administrador.
  ///
  /// Ahora nace desactivada y sin permisos: un administrador la habilita desde
  /// la vista de Usuarios. Ojo que con las reglas nuevas esta escritura sera
  /// denegada de todos modos (solo `manageUsers` escribe en `Usuarios`); si se
  /// quiere reactivar el auto-registro, hay que resolverlo en el servidor.
  Future signUp() async {
    if (!passwordConfirmed()) return;
    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      await db
          .collection('Usuarios')
          .doc(FirebaseAuth.instance.currentUser!.uid.toString())
          .set({
        'email': _emailController.text.trim(),
        'nombre': _nameController.text.trim(),
        'apellido': _lastnameController.text.trim(),
        'uid': FirebaseAuth.instance.currentUser!.uid.toString(),
        'permissions': UserAccess.fromUserData(null).permissionsPayload(),
        'activo': false,
        'ocupacion': '--',
        'telefono': '--',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // El `catch` vacio de antes se tragaba hasta el permission-denied: el
      // usuario veia que "funciono" y no habia quedado nada.
      if (!mounted) return;
      AnimatedSnackBar.material(
        'No se pudo crear la cuenta. Contacta al administrador.',
        type: AnimatedSnackBarType.error,
      ).show(context);
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
