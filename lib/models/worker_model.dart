import 'package:cloud_firestore/cloud_firestore.dart';

class WorkerModel {
  String? name,
      lastName,
      id,
      rut,
      email,
      nacionality,
      civilState,
      birth,
      adress,
      commune,
      labor,
      place,
      afp,
      prevision,
      ingress,
      imageFront,
      imageBack;

  WorkerModel(
      {this.name,
      this.lastName,
      this.id,
      this.rut,
      this.email,
      this.nacionality,
      this.civilState,
      this.birth,
      this.adress,
      this.commune,
      this.labor,
      this.place,
      this.afp,
      this.prevision,
      this.ingress,
      this.imageFront,
      this.imageBack});

  factory WorkerModel.fromDocumentSnapshot(DocumentSnapshot doc) {
    // Aseguramos que data sea un Map<String, dynamic> y que no sea nulo
    final data = doc.data() as Map<String, dynamic>?;

    if (data == null) {
      // Manejar el caso donde el documento no tiene datos (es muy raro para documentos existentes)
      // O lanzar un error, dependiendo de cómo quieras manejarlo.
      // Para este caso, podemos devolver un WorkerModel con valores predeterminados o vacíos
      return WorkerModel(
        name: '', lastName: '', id: doc.id, rut: '', email: '',
        nacionality: '', civilState: '', birth: '', adress: '',
        commune: '', labor: '', place: '', afp: '', prevision: '',
        ingress: '', imageFront: '', imageBack: '',
      );
    }

    return WorkerModel(
      name: data['nombres'] ?? '', // Usamos ?? '' para asegurar que sea String si es nulo
      lastName: data['apellidos'] ?? '',
      rut: data['rut'] ?? '',
      email: data['correo'], // Este puede ser nulo, por eso no usamos ?? ''
      nacionality: data['nacionalidad'] ?? '',
      civilState: data['estadoCivil'] ?? '',
      birth: data['fechaNacimiento'] ?? '',
      adress: data['direccion'] ?? '',
      commune: data['comuna'] ?? '',
      labor: data['labor'] ?? '',
      place: data['lugar'] ?? '',
      afp: data['afp'] ?? '',
      prevision: data['prevision'] ?? '',
      ingress: data['ingreso'] ?? '',
      imageFront: data['imagenFront'] ?? '',
      imageBack: data['imagenBack'] ?? '',
      id: doc.id, // El ID del documento se obtiene directamente de snapshot.id
    );
  }

  List<WorkerModel> dataListFromSnapshot(QuerySnapshot querySnapshot) {
    return querySnapshot.docs.map((snapshot) {
      final Map<String, dynamic> dataMap =
          snapshot.data() as Map<String, dynamic>;

      return WorkerModel(
        name: dataMap['nombres'],
        lastName: dataMap['apellidos'],
        rut: dataMap['rut'],
        email: dataMap['correo'],
        nacionality: dataMap['nacionalidad'],
        civilState: dataMap['estadoCivil'],
        birth: dataMap['fechaNacimiento'],
        adress: dataMap['direccion'],
        commune: dataMap['comuna'],
        labor: dataMap['labor'],
        place: dataMap['lugar'],
        afp: dataMap['afp'],
        prevision: dataMap['prevision'],
        ingress: dataMap['ingreso'],
        imageFront: dataMap['imagenFront'],
        imageBack: dataMap['imagenBack'],
        id: snapshot.id,
      );
    }).toList();
  }
}
