// Genera el icono de la app de Windows a partir del de Android.
//
//   dart run tool/generar_icono_windows.dart
//
// Escribe `windows/runner/resources/app_icon.ico`, que es lo que usa el
// ejecutable, el acceso directo, la barra de tareas y el instalador.
//
// Existe porque `flutter create` deja ahi el logo de Flutter, y ese archivo se
// entrega tal cual si nadie lo cambia: la app aparecia en el escritorio del
// cliente con el logotipo de Flutter en vez del suyo.
//
// El original es el icono de Android, no una imagen aparte, para que las dos
// plataformas no se separen con el tiempo.

import 'dart:io';

import 'package:image/image.dart';

/// El launcher de Android de mayor resolucion que hay en el repo.
const origen = 'android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png';

const destino = 'windows/runner/resources/app_icon.ico';

/// Windows elige el tamano segun donde dibuje el icono: 16 en la barra de
/// titulo, 32 en la barra de tareas, 48 en el explorador, 256 en la vista de
/// iconos grandes. Un `.ico` con una sola imagen se ve borroso en todos los
/// demas, porque entonces el escalado lo hace el sistema.
const tamanos = [256, 128, 64, 48, 32, 24, 16];

void main() {
  final archivo = File(origen);
  if (!archivo.existsSync()) {
    stderr.writeln('No encuentro $origen');
    exit(1);
  }

  final original = decodePng(archivo.readAsBytesSync());
  if (original == null) {
    stderr.writeln('No pude leer $origen como PNG');
    exit(1);
  }
  stdout.writeln('Origen: $origen  ${original.width}x${original.height}');

  // `average` da mejor resultado que el vecino mas cercano al reducir mucho:
  // a 16 px, sin eso, el dibujo se convierte en manchas.
  Image aLado(int lado) => copyResize(
        original,
        width: lado,
        height: lado,
        interpolation: Interpolation.average,
      );

  // Un `.ico` es un contenedor de varias imagenes. El paquete `image` lo
  // expresa como los marcos de una sola: el primero es la imagen y el resto
  // se agregan con `addFrame`.
  final icono = aLado(tamanos.first);
  stdout.writeln('  ${tamanos.first}x${tamanos.first}');
  for (final lado in tamanos.skip(1)) {
    icono.addFrame(aLado(lado));
    stdout.writeln('  ${lado}x$lado');
  }

  final salida = File(destino);
  salida.writeAsBytesSync(encodeIco(icono));
  stdout.writeln('');
  stdout.writeln('Escrito: $destino  ${salida.lengthSync()} bytes');
}
