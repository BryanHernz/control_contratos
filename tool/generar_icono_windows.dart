// Genera los recursos graficos de la version de Windows a partir del icono de
// Android.
//
//   dart run tool/generar_icono_windows.dart
//
// Escribe:
//   windows/runner/resources/app_icon.ico     icono del ejecutable
//   windows/installer/imagenes/*.bmp          imagenes del instalador
//
// Existe porque `flutter create` deja el logo de Flutter en `app_icon.ico`, y
// ese archivo se entrega tal cual si nadie lo cambia: la app aparecia en el
// escritorio del cliente con el logotipo del framework en vez del suyo.
//
// El original es el icono de Android, no una imagen aparte, para que las dos
// plataformas no se separen con el tiempo.

import 'dart:io';

import 'package:image/image.dart';

/// El launcher de Android de mayor resolucion que hay en el repo.
const origen = 'android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png';

const destinoIcono = 'windows/runner/resources/app_icon.ico';
const carpetaImagenes = 'windows/installer/imagenes';

/// Windows elige el tamano segun donde dibuje el icono: 16 en la barra de
/// titulo, 32 en la barra de tareas, 48 en el explorador, 256 en la vista de
/// iconos grandes. Un `.ico` con una sola imagen se ve borroso en todos los
/// demas, porque entonces el escalado lo hace el sistema.
const tamanosIcono = [256, 128, 64, 48, 32, 24, 16];

/// El degradado de las cabeceras de la app: `blueGrey.900` a `blueGrey.700`.
/// El instalador lo repite para que se vea como la misma pieza de software.
const arriba = [0x26, 0x32, 0x38];
const abajo = [0x45, 0x5A, 0x64];

/// Tamanos del banner lateral del instalador, los que reconoce Inno Setup.
/// Elige el que mejor calce con la escala de pantalla del equipo.
const bannerGrande = [
  [164, 314],
  [192, 386],
  [246, 459],
  [328, 628],
  [410, 797],
];

/// Tamanos del icono de la cabecera del asistente.
const bannerChico = [
  [55, 58],
  [83, 80],
  [110, 116],
  [138, 140],
  [192, 192],
];

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

  // ------------------------------------------------------------ icono
  //
  // Un `.ico` es un contenedor de varias imagenes. El paquete `image` lo
  // expresa como los marcos de una sola: el primero es la imagen y el resto
  // se agregan con `addFrame`.
  stdout.writeln('\nIcono:');
  final icono = aLado(tamanosIcono.first);
  stdout.writeln('  ${tamanosIcono.first}x${tamanosIcono.first}');
  for (final lado in tamanosIcono.skip(1)) {
    icono.addFrame(aLado(lado));
    stdout.writeln('  ${lado}x$lado');
  }
  final salida = File(destinoIcono)..writeAsBytesSync(encodeIco(icono));
  stdout.writeln('  -> $destinoIcono  ${salida.lengthSync()} bytes');

  // -------------------------------------------------- imagenes del asistente
  Directory(carpetaImagenes).createSync(recursive: true);

  stdout.writeln('\nBanner del instalador:');
  for (final medida in bannerGrande) {
    _escribirBanner(
      original,
      ancho: medida[0],
      alto: medida[1],
      // El icono ocupa poco mas de la mitad del ancho: el banner es alto y
      // angosto, y llenarlo lo dejaria apretado contra los bordes.
      proporcionIcono: 0.55,
      ruta: '$carpetaImagenes/banner-${medida[0]}x${medida[1]}.bmp',
    );
  }

  stdout.writeln('\nIcono de cabecera del instalador:');
  for (final medida in bannerChico) {
    _escribirBanner(
      original,
      ancho: medida[0],
      alto: medida[1],
      proporcionIcono: 0.82,
      ruta: '$carpetaImagenes/cabecera-${medida[0]}x${medida[1]}.bmp',
    );
  }
}

/// Dibuja el icono centrado sobre el degradado de la app y lo guarda como BMP.
///
/// BMP y no PNG porque es lo que Inno Setup lee. Y se aplana a tres canales:
/// un BMP con canal alfa hace que Inno lo dibuje con bordes negros.
void _escribirBanner(
  Image original, {
  required int ancho,
  required int alto,
  required double proporcionIcono,
  required String ruta,
}) {
  final lienzo = Image(width: ancho, height: alto, numChannels: 3);

  // Degradado en diagonal, el mismo sentido que el de las cabeceras.
  for (var y = 0; y < alto; y++) {
    for (var x = 0; x < ancho; x++) {
      final t = ((x / ancho) + (y / alto)) / 2;
      lienzo.setPixelRgb(
        x,
        y,
        (arriba[0] + (abajo[0] - arriba[0]) * t).round(),
        (arriba[1] + (abajo[1] - arriba[1]) * t).round(),
        (arriba[2] + (abajo[2] - arriba[2]) * t).round(),
      );
    }
  }

  final lado = ((ancho < alto ? ancho : alto) * proporcionIcono).round();
  final marca = copyResize(
    original,
    width: lado,
    height: lado,
    interpolation: Interpolation.average,
  );
  compositeImage(
    lienzo,
    marca,
    dstX: ((ancho - lado) / 2).round(),
    dstY: ((alto - lado) / 2).round(),
  );

  File(ruta).writeAsBytesSync(encodeBmp(lienzo));
  stdout.writeln('  ${ancho}x$alto  -> $ruta');
}
