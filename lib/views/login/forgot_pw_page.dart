// ignore_for_file: use_build_context_synchronously

import 'package:animated_snack_bar/animated_snack_bar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart' hide ModalBottomSheetRoute;
import 'package:get/get.dart';

import '../../customs/widgets_custom.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _emailController = TextEditingController();

  Future sendLink() async {
    try {
      await FirebaseAuth.instance
          .sendPasswordResetEmail(email: _emailController.text.trim());

      AnimatedSnackBar.material(
        'Correo enviado con éxito. revisa tu bandeja de entrada, si no aparece ahí revisa la zona de spam.',
        mobileSnackBarPosition: MobileSnackBarPosition.top,
        desktopSnackBarPosition: DesktopSnackBarPosition.bottomRight,
        type: AnimatedSnackBarType.success,
      ).show(context);

      Get.back();
    } on FirebaseAuthException catch (e) {
      String mensaje;

      if (e.message.toString() ==
          'An unknown error occurred: FirebaseError: Firebase: Error (auth/missing-email).') {
        mensaje = 'Por favor indica tu correo';
      } else {
        if (e.message.toString() ==
            'An unknown error occurred: FirebaseError: Firebase: The email address is badly formatted. (auth/invalid-email).') {
          mensaje = 'El formato del correo indicado no es correcto';
        } else {
          if (e.message.toString() ==
              'An unknown error occurred: FirebaseError: Firebase: There is no user record corresponding to this identifier. The user may have been deleted. (auth/user-not-found).') {
            mensaje =
                'No existe ningún usuario registrado con el correo indicado';
          } else {
            mensaje = e.message.toString();
          }
        }
      }

      AnimatedSnackBar.material(
        mensaje,
        mobileSnackBarPosition: MobileSnackBarPosition.top,
        desktopSnackBarPosition: DesktopSnackBarPosition.bottomRight,
        type: AnimatedSnackBarType.warning,
      ).show(context);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: OrientationBuilder(
        builder: (BuildContext context, Orientation orientation) {
          return orientation == Orientation.portrait
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20.0),
                      child: SubTitleWidget(
                          text:
                              'Ingresa tu correo para que puedas recibir un enlace de recuperación.'),
                    ),
                    const SizedBox(height: 15),
                    InputTextField(
                      textController: _emailController,
                      hint: 'Correo',
                    ),
                    const SizedBox(height: 30),
                    SubmitButton(
                      funcion: sendLink,
                      texto: 'Obtener enlace',
                    ),
                    const SizedBox(height: 15),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 30.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          GestureDetector(
                            onTap: () {
                              Get.back();
                            },
                            child: const Text(
                              'Regresar',
                              style: TextStyle(
                                color: Colors.teal,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                )
              : Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SubTitleWidget(
                        text:
                            'Ingresa tu correo para que puedas recibir un enlace de recuperación.',
                      ),
                      const SizedBox(height: 15),
                      InputTextField(
                        textController: _emailController,
                        hint: 'Correo',
                      ),
                      const SizedBox(height: 30),
                      SubmitButton(
                        funcion: sendLink,
                        texto: 'Obtener enlace',
                      ),
                      const SizedBox(height: 15),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 30.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            GestureDetector(
                              onTap: () {
                                Get.back();
                              },
                              child: const Text(
                                'Regresar',
                                style: TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
        },
      ),
    );
  }
}
