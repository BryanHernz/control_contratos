import 'package:animated_snack_bar/animated_snack_bar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../customs/widgets_custom.dart';
import '../../../utils/user_access.dart';
import '../forgot_pw_page.dart';
import '../../../services/firestore_db.dart';

class LoginPage extends StatefulWidget {
  final VoidCallback showRegisterPage;
  const LoginPage({super.key, required this.showRegisterPage});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _rememberMe = false;
  bool _obscurePassword = true;
  bool _isSigningIn = false;

  @override
  void initState() {
    super.initState();
    _loadCredentials();
  }

  Future<void> _loadCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;

    setState(() {
      _rememberMe = prefs.getBool('remember_me') ?? false;
      if (_rememberMe) {
        _emailController.text = prefs.getString('saved_email') ?? '';
      }
    });
  }

  Future<void> _saveCredentials({required String email}) async {
    final prefs = await SharedPreferences.getInstance();
    if (_rememberMe) {
      await prefs.setBool('remember_me', true);
      await prefs.setString('saved_email', email);
      return;
    }

    await prefs.setBool('remember_me', false);
    await prefs.remove('saved_email');
  }

  String _authMessage(String code) {
    switch (code) {
      case 'invalid-email':
        return 'El formato del correo no es valido.';
      case 'user-not-found':
        return 'No existe una cuenta con ese correo.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Correo o contrasena incorrectos.';
      case 'user-disabled':
        return 'Esta cuenta se encuentra deshabilitada.';
      case 'too-many-requests':
        return 'Demasiados intentos. Intenta nuevamente en unos minutos.';
      case 'network-request-failed':
        return 'No hay conexion. Revisa tu internet e intenta otra vez.';
      default:
        return 'No se pudo iniciar sesion. Intenta nuevamente.';
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

  Future<void> _ensureUserProfile(User user, {required String email}) async {
    final ref = db.collection('Usuarios').doc(user.uid);
    final snap = await ref.get();

    if (!snap.exists || snap.data() == null) {
      final access = UserAccess.fromUserData(null);
      await ref.set(
        {
          'uid': user.uid,
          'email': email,
          'nombre': '',
          'apellido': '',
          'permissions': access.permissionsPayload(),
          'activo': true,
          'telefono': '',
          'ocupacion': '',
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
      return;
    }

    final data = snap.data();
    final access = UserAccess.fromUserData(data);
    await ref.set(
      {
        'uid': user.uid,
        'email': email,
        'permissions': access.permissionsPayload(),
        'activo': access.active,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    if (!access.active) {
      await FirebaseAuth.instance.signOut();
      throw Exception('inactive-user');
    }
  }

  Future<void> _submitLogin() async {
    if (_isSigningIn) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    FocusScope.of(context).unfocus();
    final email = _emailController.text.trim().toLowerCase();
    final password = _passwordController.text.trim();

    setState(() => _isSigningIn = true);

    try {
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final loggedUser = credential.user;
      if (loggedUser == null) {
        throw Exception('missing-user');
      }

      await _ensureUserProfile(loggedUser, email: email);
      await _saveCredentials(email: email);
      if (!mounted) return;
      _showMessage('Sesion iniciada con exito.', AnimatedSnackBarType.success);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      _showMessage(_authMessage(e.code), AnimatedSnackBarType.error);
    } catch (e) {
      if (!mounted) return;
      if (e.toString().contains('inactive-user')) {
        _showMessage(
          'Tu usuario esta inactivo. Contacta al administrador.',
          AnimatedSnackBarType.warning,
        );
        return;
      }
      _showMessage(
        'No se pudo iniciar sesion. Intenta nuevamente.',
        AnimatedSnackBarType.error,
      );
    } finally {
      if (mounted) {
        setState(() => _isSigningIn = false);
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
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.blueGrey.shade900,
              Colors.blueGrey.shade700,
              Colors.white,
            ],
            stops: const [0.0, 0.42, 1.0],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(24, 26, 24, 24),
                  decoration: BoxDecoration(
                    color: Colors.white,
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
                        Image.asset(
                          'lib/images/CONTRATO.png',
                          width: 210,
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'INICIAR SESION',
                          style: TextStyle(
                            color: Colors.blueGrey.shade900,
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Ingresa con tu correo y contrasena para continuar.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.blueGrey.shade600,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 24),
                        InputTextField(
                          textController: _emailController,
                          hint: 'Correo',
                          teclado: TextInputType.emailAddress,
                          onFieldSubmitted: (_) => _submitLogin(),
                          validator: (value) {
                            final current = (value ?? '').trim();
                            if (current.isEmpty) {
                              return 'Por favor ingresa un correo.';
                            }
                            if (!current.isEmail) {
                              return 'Por favor ingresa un correo valido.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),
                        InputTextField(
                          textController: _passwordController,
                          hint: 'Contrasena',
                          passwordField: _obscurePassword,
                          teclado: TextInputType.visiblePassword,
                          suffixIcon: IconButton(
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                            tooltip: _obscurePassword
                                ? 'Mostrar contrasena'
                                : 'Ocultar contrasena',
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off_rounded
                                  : Icons.visibility_rounded,
                              color: Colors.blueGrey.shade400,
                              size: 20,
                            ),
                          ),
                          onFieldSubmitted: (_) => _submitLogin(),
                          validator: (value) {
                            if ((value ?? '').trim().isEmpty) {
                              return 'Por favor ingresa tu contrasena.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Transform.scale(
                              scale: 0.92,
                              child: Checkbox(
                                value: _rememberMe,
                                activeColor: Colors.blueGrey.shade700,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                onChanged: (value) {
                                  setState(() {
                                    _rememberMe = value ?? false;
                                  });
                                },
                              ),
                            ),
                            Expanded(
                              child: InkWell(
                                borderRadius: BorderRadius.circular(8),
                                onTap: () {
                                  setState(() {
                                    _rememberMe = !_rememberMe;
                                  });
                                },
                                child: Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 8),
                                  child: Text(
                                    'Recordar correo',
                                    style: TextStyle(
                                      color: Colors.blueGrey.shade700,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13.5,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () => Get.to(const ForgotPasswordPage()),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.blueGrey.shade700,
                              textStyle: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13.5,
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                            ),
                            child: const Text('Olvidé mi contraseña'),
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton.icon(
                            onPressed: _isSigningIn ? null : _submitLogin,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blueGrey.shade700,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor:
                                  Colors.blueGrey.shade400.withOpacity(0.65),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 0,
                            ),
                            icon: _isSigningIn
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.login_rounded, size: 18),
                            label: Text(
                              _isSigningIn ? 'INGRESANDO...' : 'INGRESAR',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        /* Wrap(
                          alignment: WrapAlignment.center,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              'No tienes cuenta?',
                              style: TextStyle(
                                color: Colors.blueGrey.shade700,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            TextButton(
                              onPressed: widget.showRegisterPage,
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.blueGrey.shade900,
                                textStyle: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              child: const Text('Registrate ahora'),
                            ),
                          ],
                        ), */
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
