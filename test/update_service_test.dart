import 'package:flutter_test/flutter_test.dart';

import 'package:myapp/services/update_service.dart';

/// La comparacion de versiones decide si se ofrece una actualizacion. Cuando
/// falla, no hay error ni aviso: simplemente nadie se entera de que hay una
/// version nueva. Por eso vale la pena fijarla.
void main() {
  group('esMasNueva', () {
    test('lo basico', () {
      expect(UpdateService.esMasNueva('1.0.4', '1.0.3'), isTrue);
      expect(UpdateService.esMasNueva('1.0.3', '1.0.4'), isFalse);
      expect(UpdateService.esMasNueva('1.0.4', '1.0.4'), isFalse);
      expect(UpdateService.esMasNueva('1.1.0', '1.0.9'), isTrue);
      expect(UpdateService.esMasNueva('2.0.0', '1.9.9'), isTrue);
    });

    test('EL CASO DE WINDOWS: la version local trae el sufijo de build', () {
      // `PackageInfo.version` en Windows sale del recurso de version del .exe,
      // que Flutter rellena con el valor completo del pubspec. La version
      // anterior hacia `int.parse('4+5')`, lanzaba, y el catch devolvia false:
      // en Windows no se habria ofrecido NUNCA una actualizacion.
      expect(UpdateService.esMasNueva('1.0.5', '1.0.4+5'), isTrue);
      expect(UpdateService.esMasNueva('1.0.4', '1.0.4+5'), isFalse);
      expect(UpdateService.esMasNueva('1.1.0', '1.0.4+5'), isTrue);
    });

    test('tambien tolera sufijos de preliberacion', () {
      expect(UpdateService.esMasNueva('1.0.5', '1.0.4-beta'), isTrue);
      expect(UpdateService.esMasNueva('1.0.4-rc1', '1.0.3'), isTrue);
    });

    test('versiones con distinta cantidad de partes', () {
      expect(UpdateService.esMasNueva('1.1', '1.0.9'), isTrue);
      expect(UpdateService.esMasNueva('1.0', '1.0.0'), isFalse);
      expect(UpdateService.esMasNueva('1.0.0.1', '1.0.0'), isTrue);
    });

    test('basura no provoca una actualizacion falsa', () {
      expect(UpdateService.esMasNueva('', '1.0.4'), isFalse);
      expect(UpdateService.esMasNueva('no-es-version', '1.0.4'), isFalse);
    });
  });

  group('canales', () {
    test('Android y Windows leen descriptores distintos', () {
      // Si compartieran archivo, publicar la version de escritorio le
      // ofreceria un instalador de Windows a los telefonos -- y lo interpreta
      // la app ya instalada, asi que no habria como corregirlo despues.
      expect(
        CanalDeActualizacion.android.descriptor,
        isNot(CanalDeActualizacion.windows.descriptor),
      );
      expect(CanalDeActualizacion.android.claveUrl, 'apk_url');
      expect(CanalDeActualizacion.windows.claveUrl, 'setup_url');
    });

    test('cada canal guarda la descarga con la extension que le corresponde',
        () {
      expect(CanalDeActualizacion.android.nombreDescarga, endsWith('.apk'));
      expect(CanalDeActualizacion.windows.nombreDescarga, endsWith('.exe'));
    });
  });
}
