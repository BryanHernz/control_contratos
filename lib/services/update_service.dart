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

class UpdateService {
  static const String _versionJsonPath = 'updates/version.json';
  // Clave para recordar la última versión que ya se mandó a instalar
  static const String _prefKey = 'ota_installed_version';

  static Future<void> checkForUpdate() async {
    if (kIsWeb || !Platform.isAndroid) return;
    try {
      // 1. Leer version.json desde Firebase Storage
      final ref = FirebaseStorage.instance.ref(_versionJsonPath);
      final bytes = await ref.getData();
      if (bytes == null) return;

      final Map<String, dynamic> json = jsonDecode(String.fromCharCodes(bytes));

      final String remoteVersion = json['version'] ?? '0.0.0';
      final String apkGsUrl = json['apk_url'] ?? '';
      final bool mandatory = json['mandatory'] ?? false;
      final String changelog = json['changelog'] ?? '';

      if (apkGsUrl.isEmpty) return;

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
      if (!_isNewer(remoteVersion, localVersion)) return;

      await Get.dialog(
        _UpdateDialog(
          remoteVersion: remoteVersion,
          localVersion: localVersion,
          changelog: changelog,
          mandatory: mandatory,
          apkGsUrl: apkGsUrl,
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

  static bool _isNewer(String remote, String local) {
    try {
      final r = remote.split('.').map(int.parse).toList();
      final l = local.split('.').map(int.parse).toList();
      for (int i = 0; i < r.length; i++) {
        final li = i < l.length ? l[i] : 0;
        if (r[i] > li) return true;
        if (r[i] < li) return false;
      }
    } catch (_) {}
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
  final String apkGsUrl;
  final Future<void> Function() onInstalled;

  const _UpdateDialog({
    required this.remoteVersion,
    required this.localVersion,
    required this.changelog,
    required this.mandatory,
    required this.apkGsUrl,
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
      final ref = FirebaseStorage.instance.refFromURL(widget.apkGsUrl);
      final downloadUrl = await ref.getDownloadURL();

      final dir = await getTemporaryDirectory();
      final apkPath = '${dir.path}/app_update.apk';

      // Limpiar descarga residual anterior si existe
      final oldFile = File(apkPath);
      if (await oldFile.exists()) await oldFile.delete();

      await Dio().download(
        downloadUrl,
        apkPath,
        onReceiveProgress: (received, total) {
          if (total > 0 && mounted) {
            setState(() => _progress = received / total);
          }
        },
      );

      // Marcar como "ya enviado al instalador" ANTES de abrirlo
      await widget.onInstalled();

      await OpenFilex.open(apkPath);
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
