import 'package:cloud_functions/cloud_functions.dart';

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
