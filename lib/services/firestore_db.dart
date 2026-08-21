import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

/// Base de Firestore contra la que corre la app.
///
/// El proyecto `contratos-control` tiene dos bases:
///
///   `(default)`  produccion, con datos reales de la empresa
///   `pruebas`    copia clonada de produccion el 2026-08-21
///
/// Se elige al compilar, sin tocar codigo:
///
///   flutter run                                  -> produccion
///   flutter run --dart-define=FIRESTORE_DB=pruebas -> base de pruebas
///
/// **Auth y Storage NO cambian.** El clon es solo de Firestore, asi que aunque
/// se apunte a `pruebas`, las cuentas y los archivos (fotos de carnet, APKs
/// del actualizador) siguen siendo los de produccion. Borrar un trabajador
/// desde la base de pruebas borra sus imagenes REALES.
const String kFirestoreDatabaseId =
    String.fromEnvironment('FIRESTORE_DB', defaultValue: '(default)');

/// `true` cuando la app NO esta apuntando a produccion.
bool get usandoBaseDePruebas => kFirestoreDatabaseId != '(default)';

/// Instancia de Firestore que usa toda la app.
///
/// Se accede por esta variable y no por `FirebaseFirestore.instance`, para que
/// el cambio de base valga para todas las consultas de una sola vez. Es `final`
/// de nivel superior, o sea perezosa: se resuelve en el primer uso, ya con
/// Firebase inicializado.
final FirebaseFirestore db = usandoBaseDePruebas
    ? FirebaseFirestore.instanceFor(
        app: Firebase.app(),
        databaseId: kFirestoreDatabaseId,
      )
    : FirebaseFirestore.instance;
