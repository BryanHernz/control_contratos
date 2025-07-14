// ignore_for_file: empty_catches, use_build_context_synchronously, deprecated_member_use
import 'package:animated_snack_bar/animated_snack_bar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart' hide ModalBottomSheetRoute;
import 'package:get/get.dart';
import '../../../customs/widgets_custom.dart';
import '../forgot_pw_page.dart';

class LoginPage extends StatefulWidget {
  final VoidCallback showRegisterPage;
  const LoginPage({super.key, required this.showRegisterPage});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  //Text controllers
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  Future signIn() async {
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      AnimatedSnackBar.material(
        'Sesión iniciada con éxito',
        mobileSnackBarPosition: MobileSnackBarPosition.top,
        desktopSnackBarPosition: DesktopSnackBarPosition.bottomRight,
        type: AnimatedSnackBarType.success,
      ).show(context);
    } catch (e) {
      try {
        await FirebaseFirestore.instance
            .collection('Usuarios')
            .where('email', isEqualTo: _emailController.text.trim())
            .get()
            .then((value) {
          if (value.docs.isNotEmpty) {
            AnimatedSnackBar.material(
              'Contraseña incorrecta',
              mobileSnackBarPosition: MobileSnackBarPosition.top,
              desktopSnackBarPosition: DesktopSnackBarPosition.bottomRight,
              type: AnimatedSnackBarType.error,
            ).show(context);
          } else {
            AnimatedSnackBar.material(
              'Email no registrado',
              mobileSnackBarPosition: MobileSnackBarPosition.top,
              desktopSnackBarPosition: DesktopSnackBarPosition.bottomRight,
              type: AnimatedSnackBarType.error,
            ).show(context);
          }
        });
      } catch (e) {
        AnimatedSnackBar.material(
          'No se ha podido iniciar sesión',
          mobileSnackBarPosition: MobileSnackBarPosition.top,
          desktopSnackBarPosition: DesktopSnackBarPosition.bottomRight,
          type: AnimatedSnackBarType.error,
        ).show(context);
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Form(
        key: _formKey,
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: SizedBox(
                width: 450,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const LogoImage(),
                      const SizedBox(height: 50),
                      InputTextField(
                        textController: _emailController,
                        hint: 'Correo',
                        teclado: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == '') {
                            return 'Por favor ingrese un email';
                          }
                          if (!value.toString().isEmail) {
                            return 'Por favor ingrese un email válido';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      InputTextField(
                        textController: _passwordController,
                        hint: 'Contraseña',
                        passwordField: true,
                        teclado: TextInputType.visiblePassword,
                        validator: (value) {
                          if (value == '') {
                            return 'Por favor ingrese su contraseña';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 15),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 30.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            GestureDetector(
                              onTap: () {
                                Get.to(const ForgotPasswordPage());
                              },
                              child: const Text(
                                '¿Olvidaste tu contraseña?',
                                style: TextStyle(
                                  color: Colors.teal,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 15),
                      SubmitButton(
                        funcion: () {
                          if (_formKey.currentState!.validate() &&
                              _formKey.currentState!.validate()) {
                            _formKey.currentState!.save();
                            signIn();
                          }
                        },
                        texto: 'Ingresar',
                      ),
                      const SizedBox(height: 25),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            '¿No tienes cuenta?,',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          GestureDetector(
                            onTap: widget.showRegisterPage,
                            child: const Text(
                              ' Registrate ahora',
                              style: TextStyle(
                                color: Colors.teal,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )
                        ],
                      )
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
