import 'package:animated_snack_bar/animated_snack_bar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../customs/widgets_custom.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isSending = false;

  String _authMessage(String code) {
    switch (code) {
      case 'missing-email':
        return 'Por favor ingresa tu correo.';
      case 'invalid-email':
        return 'El formato del correo no es valido.';
      case 'user-not-found':
        return 'No existe una cuenta registrada con ese correo.';
      case 'too-many-requests':
        return 'Demasiados intentos. Intenta nuevamente en unos minutos.';
      case 'network-request-failed':
        return 'No hay conexion. Revisa tu internet e intenta otra vez.';
      default:
        return 'No se pudo enviar el enlace. Intenta nuevamente.';
    }
  }

  void _showMessage(String message, AnimatedSnackBarType type) {
    AnimatedSnackBar.material(
      message,
      mobileSnackBarPosition: MobileSnackBarPosition.top,
      desktopSnackBarPosition: DesktopSnackBarPosition.bottomRight,
      type: type,
    ).show(context);
  }

  Future<void> _sendLink() async {
    if (_isSending) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    FocusScope.of(context).unfocus();
    setState(() => _isSending = true);

    final email = _emailController.text.trim().toLowerCase();

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);

      if (!mounted) return;
      _showMessage(
        'Enlace enviado. Revisa tu bandeja de entrada o spam.',
        AnimatedSnackBarType.success,
      );
      Get.back();
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      _showMessage(_authMessage(e.code), AnimatedSnackBarType.warning);
    } catch (_) {
      if (!mounted) return;
      _showMessage(
        'No se pudo enviar el enlace. Intenta nuevamente.',
        AnimatedSnackBarType.error,
      );
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
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
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.blueGrey.shade900,
              Colors.blueGrey.shade700,
              const Color(0xFFF4F7FA),
            ],
            stops: const [0.0, 0.42, 1.0],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 22),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4F7FA),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white.withOpacity(0.85)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.14),
                        blurRadius: 28,
                        offset: const Offset(0, 14),
                      ),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 58,
                          height: 58,
                          decoration: BoxDecoration(
                            color: Colors.blueGrey.shade700.withOpacity(0.14),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(
                            Icons.lock_reset_rounded,
                            color: Colors.blueGrey.shade700,
                            size: 28,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'RECUPERAR CONTRASENA',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.blueGrey.shade900,
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.4,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Ingresa tu correo y te enviaremos un enlace para restablecer tu contrasena.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.blueGrey.shade600,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 22),
                        InputTextField(
                          textController: _emailController,
                          hint: 'Correo',
                          teclado: TextInputType.emailAddress,
                          onFieldSubmitted: (_) => _sendLink(),
                          validator: (value) {
                            final current = (value ?? '').trim();
                            if (current.isEmpty) {
                              return 'Por favor ingresa tu correo.';
                            }
                            if (!current.isEmail) {
                              return 'Por favor ingresa un correo valido.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton.icon(
                            onPressed: _isSending ? null : _sendLink,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blueGrey.shade700,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor:
                                  Colors.blueGrey.shade400.withOpacity(0.65),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              elevation: 0,
                            ),
                            icon: _isSending
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.send_rounded, size: 18),
                            label: Text(
                              _isSending ? 'ENVIANDO...' : 'ENVIAR ENLACE',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextButton.icon(
                          onPressed: () => Get.back(),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.blueGrey.shade700,
                            textStyle: const TextStyle(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          icon: const Icon(Icons.arrow_back_rounded, size: 18),
                          label: const Text('Volver al inicio de sesion'),
                        ),
                      ],
                    ),
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
