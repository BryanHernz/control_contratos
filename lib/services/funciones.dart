import 'dart:convert';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'firestore_db.dart';

/// Region de las funciones. La misma de Firestore: ponerlas en otra region
/// agrega un viaje de ida y vuelta a cada llamada.
const String kFunctionsRegion = 'southamerica-east1';

/// Emulador de funciones, cuando se quiere probar sin desplegar.
///
/// Las funciones son del PROYECTO, no de una base: desplegarlas es un cambio
/// en produccion aunque la app apunte a `pruebas`. El emulador permite
/// probarlas corriendo en la maquina, sin subir nada.
///
///   firebase emulators:start --only functions
///   flutter run --dart-define=FIRESTORE_DB=pruebas \
///               --dart-define=FUNCTIONS_EMULATOR=localhost:5001
///
/// Vacio -- lo normal -- usa las funciones desplegadas.
const String kFunctionsEmulator =
    String.fromEnvironment('FUNCTIONS_EMULATOR');

/// `true` cuando las llamadas van al emulador y no a la nube.
bool get usandoEmuladorDeFunciones => kFunctionsEmulator.isNotEmpty;

/// `true` donde **no existe** el plugin `cloud_functions`.
///
/// El paquete declara android, ios, macos y web, y nada mas. En Windows
/// `httpsCallable(...).call()` no falla con un error de red sino con
/// `MissingPluginException`, o sea que "Nuevo usuario" simplemente no
/// funcionaria en la app de escritorio.
bool get sinPluginDeFunciones =>
    !kIsWeb && defaultTargetPlatform == TargetPlatform.windows;

/// Instancia de Functions que usa toda la app.
///
/// Se accede por esta variable y no por `FirebaseFunctions.instanceFor(...)`
/// suelto, por lo mismo que con [db]: el cambio a emulador tiene que valer
/// para todas las llamadas de una sola vez, y `useFunctionsEmulator` hay que
/// llamarlo sobre la instancia antes del primer uso.
final FirebaseFunctions funciones = () {
  final f = FirebaseFunctions.instanceFor(region: kFunctionsRegion);
  if (usandoEmuladorDeFunciones) {
    final partes = kFunctionsEmulator.split(':');
    f.useFunctionsEmulator(partes.first, int.parse(partes.last));
  }
  return f;
}();

/// Error devuelto por una funcion de servidor.
///
/// Existe para que la vista atrape lo mismo venga del plugin o de la llamada
/// por HTTP. Los mensajes los redacta la funcion pensando en quien los va a
/// leer, asi que se muestran tal cual.
class ErrorDeFuncion implements Exception {
  const ErrorDeFuncion(this.codigo, this.mensaje);

  final String codigo;
  final String mensaje;

  @override
  String toString() => mensaje;
}

/// Llama a una funcion `onCall` y devuelve su resultado.
///
/// Donde hay plugin, usa el plugin. En Windows habla el protocolo HTTP de las
/// funciones callable a mano: es publico y estable -- POST con
/// `{"data": {...}}` y el token de sesion en `Authorization`, respuesta en
/// `{"result": ...}` o `{"error": {...}}`.
///
/// Se usa el endpoint clasico `<region>-<proyecto>.cloudfunctions.net/<nombre>`
/// y no la URL de Cloud Run: esta ultima lleva un hash que **cambia si la
/// funcion se vuelve a crear**, y dejaria la app de escritorio apuntando al
/// vacio sin que nadie se entere hasta que alguien intente crear un usuario.
Future<Map<String, dynamic>> llamarFuncion(
  String nombre,
  Map<String, dynamic> datos,
) async {
  if (!sinPluginDeFunciones) {
    try {
      final r = await funciones.httpsCallable(nombre).call(datos);
      final d = r.data;
      return d is Map ? Map<String, dynamic>.from(d) : <String, dynamic>{};
    } on FirebaseFunctionsException catch (e) {
      throw ErrorDeFuncion(e.code, e.message ?? 'No se pudo completar.');
    }
  }

  final proyecto = Firebase.app().options.projectId;
  final base = usandoEmuladorDeFunciones
      ? 'http://$kFunctionsEmulator/$proyecto/$kFunctionsRegion'
      : 'https://$kFunctionsRegion-$proyecto.cloudfunctions.net';

  final token = await FirebaseAuth.instance.currentUser?.getIdToken();
  if (token == null) {
    throw const ErrorDeFuncion('unauthenticated', 'Tu sesion expiro.');
  }

  final http.Response resp;
  try {
    resp = await http.post(
      Uri.parse('$base/$nombre'),
      headers: {
        'Content-Type': 'application/json; charset=utf-8',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'data': datos}),
    );
  } catch (e) {
    throw ErrorDeFuncion('unavailable', 'No se pudo conectar con el servidor.');
  }

  // `bodyBytes` con `utf8.decode`, no `resp.body`: sin charset explicito en la
  // respuesta, `http` decodifica en latin-1 y los mensajes con tilde llegan
  // rotos.
  final cuerpo = jsonDecode(utf8.decode(resp.bodyBytes));
  if (cuerpo is! Map) {
    throw const ErrorDeFuncion('internal', 'Respuesta inesperada del servidor.');
  }

  final error = cuerpo['error'];
  if (error is Map) {
    throw ErrorDeFuncion(
      (error['status'] ?? 'internal').toString(),
      (error['message'] ?? 'No se pudo completar.').toString(),
    );
  }

  final resultado = cuerpo['result'];
  return resultado is Map
      ? Map<String, dynamic>.from(resultado)
      : <String, dynamic>{};
}
