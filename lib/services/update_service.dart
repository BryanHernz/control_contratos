import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:open_filex/open_filex.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../customs/constants_values.dart';

/// Canal de actualizacion de una plataforma.
///
/// Android y Windows tienen archivos SEPARADOS a proposito. Si compartieran
/// uno, subir la version de escritorio le ofreceria a los telefonos un
/// instalador de Windows; y como el archivo lo interpreta la app **ya
/// instalada**, ese error no se puede corregir despues publicando otra cosa.
class CanalDeActualizacion {
  const CanalDeActualizacion({
    required this.descriptor,
    required this.claveUrl,
    required this.nombreDescarga,
  });

  /// Ruta del JSON en Storage.
  final String descriptor;

  /// Campo dentro de ese JSON que trae la URL `gs://` del instalador.
  final String claveUrl;

  /// Con que nombre se guarda lo descargado en la carpeta temporal.
  final String nombreDescarga;

  static const android = CanalDeActualizacion(
    descriptor: 'updates/version.json',
    claveUrl: 'apk_url',
    nombreDescarga: 'app_update.apk',
  );

  static const windows = CanalDeActualizacion(
    descriptor: 'updates/windows.json',
    claveUrl: 'setup_url',
    nombreDescarga: 'control_contratos_setup.exe',
  );

  /// `null` en plataformas que no se actualizan solas (web, macOS, Linux).
  static CanalDeActualizacion? deLaPlataforma() {
    if (kIsWeb) return null;
    if (Platform.isAndroid) return android;
    if (Platform.isWindows) return windows;
    return null;
  }
}

class UpdateService {
  // Clave para recordar la última versión que ya se mandó a instalar
  static const String _prefKey = 'ota_installed_version';

  static Future<void> checkForUpdate() async {
    final canal = CanalDeActualizacion.deLaPlataforma();
    if (canal == null) return;
    try {
      // 1. Leer el descriptor del canal desde Firebase Storage
      final ref = FirebaseStorage.instance.ref(canal.descriptor);
      final bytes = await ref.getData();
      if (bytes == null) return;

      // `String.fromCharCodes` trata cada byte como un code unit, o sea que
      // decodifica en latin-1: el changelog llegaba con "versiÃ³n" en vez de
      // "version". `utf8.decode` es lo correcto.
      //
      // OJO al escribir el changelog en `version.json`: quien lo muestra es la
      // app YA INSTALADA, no esta. Mientras haya telefonos con una version
      // anterior a este arreglo, el texto tiene que ir sin tildes.
      final Map<String, dynamic> json = jsonDecode(utf8.decode(bytes));

      final String remoteVersion = json['version'] ?? '0.0.0';
      final String urlInstalador = json[canal.claveUrl] ?? '';
      final bool mandatory = json['mandatory'] ?? false;
      final String changelog = json['changelog'] ?? '';

      if (urlInstalador.isEmpty) return;

      // 2. Versión instalada según el SO
      final info = await PackageInfo.fromPlatform();
      final String localVersion = info.version;

      // 3. Versión que el usuario ya aceptó instalar (aunque Android
      //    no haya actualizado correctamente el packageInfo)
      final prefs = await SharedPreferences.getInstance();
      final String? alreadySent = prefs.getString(_prefKey);

      debugPrint(
          '[UpdateService] local=$localVersion  remote=$remoteVersion  alreadySent=$alreadySent');

      // Si ya mandamos a instalar esta versión O no es más nueva → salir
      if (alreadySent == remoteVersion) return;
      if (!esMasNueva(remoteVersion, localVersion)) return;

      await Get.dialog(
        _UpdateDialog(
          remoteVersion: remoteVersion,
          localVersion: localVersion,
          changelog: changelog,
          mandatory: mandatory,
          urlInstalador: urlInstalador,
          canal: canal,
          onInstalled: () async {
            // Guardar que ya enviamos esta versión al instalador
            await prefs.setString(_prefKey, remoteVersion);
          },
        ),
        barrierDismissible: !mandatory,
      );
    } catch (e) {
      debugPrint('[UpdateService] Error: $e');
    }
  }

  /// Numeros de una version, tolerando lo que venga pegado detras.
  ///
  /// `1.0.4+5` -> [1, 0, 4].
  static List<int> partesDeVersion(String v) {
    final limpio = v.trim().split('+').first.split('-').first;
    return limpio
        .split('.')
        .map((parte) => int.tryParse(parte.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0)
        .toList();
  }

  /// Si [remota] es posterior a [local].
  ///
  /// Recorta el sufijo de build (`+5`) porque **no llega igual en cada
  /// plataforma**: en Android `PackageInfo.version` devuelve el `versionName`
  /// limpio, pero en Windows sale del recurso de version del `.exe`, que
  /// Flutter rellena con el valor completo del pubspec -- `1.0.4+5`.
  ///
  /// La version anterior hacia `int.parse` directo: con `1.0.4+5` lanzaba,
  /// el `catch` devolvia false, y en Windows **no se habria ofrecido nunca
  /// una actualizacion**, en silencio y sin error visible.
  static bool esMasNueva(String remota, String local) {
    final r = partesDeVersion(remota);
    final l = partesDeVersion(local);
    final n = r.length > l.length ? r.length : l.length;
    for (var i = 0; i < n; i++) {
      final ri = i < r.length ? r[i] : 0;
      final li = i < l.length ? l[i] : 0;
      if (ri > li) return true;
      if (ri < li) return false;
    }
    return false;
  }
}

// ---------------------------------------------------------------------------
// Diálogo estilizado
// ---------------------------------------------------------------------------
class _UpdateDialog extends StatefulWidget {
  final String remoteVersion;
  final String localVersion;
  final String changelog;
  final bool mandatory;
  final String urlInstalador;
  final CanalDeActualizacion canal;
  final Future<void> Function() onInstalled;

  const _UpdateDialog({
    required this.remoteVersion,
    required this.localVersion,
    required this.changelog,
    required this.mandatory,
    required this.urlInstalador,
    required this.canal,
    required this.onInstalled,
  });

  @override
  State<_UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<_UpdateDialog> {
  double _progress = 0;
  bool _downloading = false;
  String? _errorMsg;

  Future<void> _downloadAndInstall() async {
    setState(() {
      _downloading = true;
      _errorMsg = null;
    });

    try {
      final ref = FirebaseStorage.instance.refFromURL(widget.urlInstalador);
      final downloadUrl = await ref.getDownloadURL();

      final dir = await getTemporaryDirectory();
      final rutaLocal = '${dir.path}/${widget.canal.nombreDescarga}';

      // Limpiar descarga residual anterior si existe
      final oldFile = File(rutaLocal);
      if (await oldFile.exists()) await oldFile.delete();

      await Dio().download(
        downloadUrl,
        rutaLocal,
        onReceiveProgress: (received, total) {
          if (total > 0 && mounted) {
            setState(() => _progress = received / total);
          }
        },
      );

      // Marcar como "ya enviado al instalador" ANTES de abrirlo
      await widget.onInstalled();

      if (Platform.isWindows) {
        // Windows no deja reemplazar un `.exe` que esta en uso, asi que la
        // app se cierra en cuanto lanza el instalador. `detached` es lo que
        // hace que el proceso sobreviva al `exit`: sin eso muere con nosotros
        // y la actualizacion no ocurre.
        //
        // No se pasa `/SILENT`: el instalador se ve, y quien lo lanzo entiende
        // que la app se cerro a proposito. Una app que desaparece sola de la
        // pantalla parece un cierre inesperado.
        await Process.start(rutaLocal, const [],
            mode: ProcessStartMode.detached);
        await Future<void>.delayed(const Duration(milliseconds: 400));
        exit(0);
      }

      await OpenFilex.open(rutaLocal);
      Get.back();
    } catch (e) {
      if (mounted) {
        setState(() {
          _downloading = false;
          _errorMsg = 'Error al descargar. Intenta de nuevo.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !widget.mandatory,
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        clipBehavior: Clip.antiAlias,
        child: SizedBox(
          width: 320,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Cabecera ────────────────────────────────────────────────
              Container(
                width: double.infinity,
                color: primario,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Row(
                  children: [
                    const Icon(Icons.system_update_alt,
                        color: Colors.white, size: 22),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'ACTUALIZACIÓN DISPONIBLE',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            letterSpacing: 0.5,
                          ),
                        ),
                        Text(
                          '${widget.localVersion} → ${widget.remoteVersion}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // ── Cuerpo ──────────────────────────────────────────────────
              Container(
                color: Colors.white,
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.changelog.isNotEmpty) ...[
                      Text(
                        'NOVEDADES',
                        style: TextStyle(
                          color: primario,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        widget.changelog,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    if (_downloading) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: _progress > 0 ? _progress : null,
                          backgroundColor: Colors.grey[200],
                          color: primario,
                          minHeight: 6,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _progress > 0
                            ? 'Descargando... ${(_progress * 100).toStringAsFixed(0)}%'
                            : 'Iniciando descarga...',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 8),
                    ],
                    if (_errorMsg != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(
                          _errorMsg!,
                          style:
                              const TextStyle(color: Colors.red, fontSize: 13),
                        ),
                      ),
                    if (!_downloading)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _AppButton(
                            texto: 'Actualizar',
                            cancelar: false,
                            onTap: _downloadAndInstall,
                          ),
                          if (!widget.mandatory) ...[
                            const SizedBox(height: 8),
                            _AppButton(
                              texto: 'Más tarde',
                              cancelar: true,
                              onTap: Get.back,
                            ),
                          ],
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AppButton extends StatelessWidget {
  final String texto;
  final bool cancelar;
  final VoidCallback onTap;

  const _AppButton({
    required this.texto,
    required this.cancelar,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 40,
          width: double.infinity,
          decoration: BoxDecoration(
            color: cancelar ? secundario : primario,
            borderRadius: BorderRadius.circular(5),
          ),
          child: Center(
            child: Text(
              texto,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
