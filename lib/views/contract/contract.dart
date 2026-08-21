// ignore_for_file: empty_catches

import 'package:animated_snack_bar/animated_snack_bar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:rut_utils/rut_utils.dart';
import 'package:spelling_number/spelling_number.dart';

import '../../customs/app_colors.dart';
import '../../customs/widgets/app_modal.dart';
import '../../customs/constants_values.dart';
import '../../customs/widgets_custom.dart';
import '../../customs/widgets/page_header.dart';
import '../widgets/settings_dialogs.dart';
import '../../services/firestore_db.dart';

class ContractPage extends StatefulWidget {
  const ContractPage({super.key});

  @override
  State<ContractPage> createState() => _ContractPageState();
}

class _ContractPageState extends State<ContractPage> {
  /// Envoltura fina sobre [showAppModal]: esta pantalla abre varios modales de
  /// ajustes y todos comparten forma.
  Future<void> _openStyledSettingsSheet({
    required BuildContext context,
    required String title,
    required IconData icon,
    required Widget child,
    String? hint,
    double maxWidth = kModalMaxWidth,
    bool danger = false,
  }) {
    return showAppModal<void>(
      context: context,
      title: title,
      icon: icon,
      hint: hint,
      danger: danger,
      maxWidth: maxWidth,
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const PageHeader(
            title: 'Ajustes y Parámetros',
            subtitle: 'Configuración de datos base del sistema',
            icon: Icons.settings_rounded,
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: StreamBuilder(
                stream: db.collection('Otros').where('nombre', whereIn: [
                  'contratosmont',
                  'empresadata',
                  'lugares',
                  'lugaresHoras',
                  'labores',
                  'afps',
                  'previsiones',
                  'comunas',
                  'estadosciviles',
                  'nacionalidades'
                ]).snapshots(),
                builder: (BuildContext context,
                    AsyncSnapshot<QuerySnapshot> snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }
                  return LayoutBuilder(
                    builder: (context, constraints) {
                      final crossCount = constraints.maxWidth >= 800
                          ? 3
                          : (constraints.maxWidth >= 600 ? 2 : 1);
                      final validDocs = snapshot.data!.docs
                          .where((doc) => doc['nombre'] != 'lugaresHoras')
                          .toList();

                      final order = [
                        'empresadata',
                        'contratosmont',
                        'lugares',
                        'labores',
                        'afps',
                        'previsiones',
                        'comunas',
                        'estadosciviles',
                        'nacionalidades'
                      ];
                      validDocs.sort((a, b) => order
                          .indexOf(a['nombre'])
                          .compareTo(order.indexOf(b['nombre'])));

                      final List<Widget> settingCards =
                          validDocs.map<Widget>((doc) {
                        if (doc['nombre'] == 'empresadata') {
                          return _SettingsCard(
                            icon: Icons.business,
                            title: doc['nombreempresa'],
                            subtitle: 'RUT: ' + doc['rut'],
                            fraction: 1 / crossCount,
                            maxWidth: constraints.maxWidth,
                            onTap: () {
                              _openStyledSettingsSheet(
                                context: context,
                                title: 'Empresa',
                                icon: Icons.business_rounded,
                                hint:
                                    'Actualiza la razon social y el RUT de la empresa.',
                                child: const NewEnterpriseData(),
                              );
                            },
                          );
                        } else if (doc['nombre'] == 'contratosmont') {
                          return _SettingsCard(
                            icon: Icons.attach_money,
                            title: 'Monto diario',
                            subtitle: numfor.format(doc['montonum']),
                            fraction: 1 / crossCount,
                            maxWidth: constraints.maxWidth,
                            onTap: () {
                              _openStyledSettingsSheet(
                                context: context,
                                title: 'Monto diario',
                                icon: Icons.attach_money_rounded,
                                hint:
                                    'Define el monto base diario para los documentos.',
                                child: const NewAmount(),
                              );
                            },
                          );
                        } else if (doc['nombre'] == 'labores') {
                          final labores = doc['tipos'] as List<dynamic>;
                          return _SettingsCard(
                            icon: Icons.work_outline,
                            title: 'Labores',
                            subtitle: '${labores.length} opciones registradas',
                            fraction: 1 / crossCount,
                            maxWidth: constraints.maxWidth,
                            onTap: () {
                              _manageGenericCategory(
                                  context, 'labores', 'Labores');
                            },
                          );
                        } else if (doc['nombre'] == 'lugares') {
                          final lugares = doc['tipos'] as List<dynamic>;
                          return _SettingsCard(
                            icon: Icons.location_on,
                            title: 'Establecimientos',
                            subtitle: '${lugares.length} sedes registradas',
                            fraction: 1 / crossCount,
                            maxWidth: constraints.maxWidth,
                            onTap: () {
                              _openStyledSettingsSheet(
                                context: context,
                                title: 'Establecimientos',
                                icon: Icons.location_on_rounded,
                                hint:
                                    'Administra lugares, horarios y horas semanales.',
                                maxWidth:
                                    MediaQuery.of(context).size.width > 800
                                        ? 900
                                        : MediaQuery.of(context).size.width,
                                child: _buildPlacesManagerContent(context),
                              );
                            },
                          );
                        } else {
                          final tipos = doc['tipos'] as List<dynamic>;
                          final nombreMap = {
                            'afps': 'AFPs',
                            'previsiones': 'Previsiones',
                            'comunas': 'Comunas',
                            'estadosciviles': 'Estados Civiles',
                            'nacionalidades': 'Nacionalidades'
                          };
                          final iconMap = {
                            'afps': Icons.account_balance,
                            'previsiones': Icons.health_and_safety,
                            'comunas': Icons.map,
                            'estadosciviles': Icons.family_restroom,
                            'nacionalidades': Icons.flag,
                          };
                          final label = nombreMap[doc['nombre']] ?? 'Otros';
                          return _SettingsCard(
                            icon: iconMap[doc['nombre']] ?? Icons.category,
                            title: label,
                            subtitle: '${tipos.length} opciones disponibles',
                            fraction: 1 / crossCount,
                            maxWidth: constraints.maxWidth,
                            onTap: () {
                              _manageGenericCategory(
                                  context, doc['nombre'], label);
                            },
                          );
                        }
                      }).toList();

                      return Wrap(
                        spacing: 16,
                        runSpacing: 16,
                        children: settingCards,
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  static const List<String> _fallbackUserTypes = [
    'ADMINISTRADOR',
    'SUPERVISOR',
    'OPERADOR',
  ];

  List<String> _extractUserTypes(Map<String, dynamic>? data) {
    final raw = (data?['tipos'] as List?)?.cast<dynamic>() ?? <dynamic>[];
    final normalized = raw
        .map((e) => e.toString().trim().toUpperCase())
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList();

    if (normalized.isEmpty) {
      return List<String>.from(_fallbackUserTypes);
    }

    normalized.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return normalized;
  }

  String _safeString(dynamic value, {String fallback = '--'}) {
    final text = value?.toString().trim() ?? '';
    if (text.isEmpty) return fallback;
    return text;
  }

  String _displayUserName(Map<String, dynamic> userData) {
    final name = _safeString(userData['nombre'], fallback: '');
    final lastName = _safeString(userData['apellido'], fallback: '');
    final fullName = '$name $lastName'.trim();
    if (fullName.isNotEmpty) return fullName.toUpperCase();
    return _safeString(userData['email']).toUpperCase();
  }

  String _resolveUserType(dynamic rawType, List<String> availableTypes) {
    if (availableTypes.isEmpty) {
      return _fallbackUserTypes.first;
    }

    if (rawType is num) {
      final index = rawType.toInt() - 1;
      if (index >= 0 && index < availableTypes.length) {
        return availableTypes[index];
      }
    }

    final rawText = _safeString(rawType, fallback: '');
    if (rawText.isNotEmpty) {
      final normalized = rawText.toUpperCase();
      for (final type in availableTypes) {
        if (type.toUpperCase() == normalized) {
          return type;
        }
      }
    }

    return availableTypes.first;
  }

  String _buildUserInitials(String displayName, String email) {
    final words = displayName
        .split(' ')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    if (words.isNotEmpty) {
      final first = words.first.substring(0, 1);
      final second = words.length > 1 ? words[1].substring(0, 1) : first;
      return '$first$second'.toUpperCase();
    }

    final safeEmail = email.trim();
    if (safeEmail.isNotEmpty) {
      return safeEmail.substring(0, 1).toUpperCase();
    }
    return 'U';
  }

  Future<void> _ensureUserTypesDocument() async {
    final ref = db.collection('Otros').doc(
          'tipos_usuarios',
        );
    final snap = await ref.get();
    final existingTypes = _extractUserTypes(snap.data());

    await ref.set(
      {
        'nombre': 'tipos_usuarios',
        'tipos': existingTypes,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Future<void> _openUsersManager(BuildContext context) async {
    await _ensureUserTypesDocument();
    if (!mounted) return;

    await _openStyledSettingsSheet(
      context: context,
      title: 'Usuarios',
      icon: Icons.manage_accounts_rounded,
      hint:
          'Gestiona los datos de cada usuario y define su tipo de acceso en el sistema.',
      child: _buildUsersManagerContent(context),
    );
  }

  Future<void> _openUserTypesManager(BuildContext context) async {
    await _ensureUserTypesDocument();
    if (!mounted) return;

    await _openStyledSettingsSheet(
      context: context,
      title: 'Tipos de usuario',
      icon: Icons.admin_panel_settings_rounded,
      hint:
          'Crea y organiza los tipos de usuario que podras asignar al administrar cuentas.',
      child: _buildUserTypesManagerContent(context),
    );
  }

  void _showAddUserTypeSheet(BuildContext context) {
    _openStyledSettingsSheet(
      context: context,
      title: 'Nuevo tipo de usuario',
      icon: Icons.person_add_alt_1_rounded,
      hint: 'Crea un nuevo tipo para la administracion de usuarios.',
      child: const NewUserType(),
    );
  }

  Widget _buildUsersManagerContent(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: db.collection('Otros').doc('tipos_usuarios').snapshots(),
      builder: (context, typesSnapshot) {
        final userTypes = _extractUserTypes(
          typesSnapshot.data?.data() as Map<String, dynamic>?,
        );

        return StreamBuilder<QuerySnapshot>(
          stream: db.collection('Usuarios').snapshots(),
          builder: (context, usersSnapshot) {
            if (!usersSnapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final usersDocs = usersSnapshot.data!.docs.toList();
            usersDocs.sort((a, b) {
              final aData = a.data() as Map<String, dynamic>? ?? {};
              final bData = b.data() as Map<String, dynamic>? ?? {};
              final aName = _displayUserName(aData).toLowerCase();
              final bName = _displayUserName(bData).toLowerCase();
              return aName.compareTo(bName);
            });

            final currentUserId = FirebaseAuth.instance.currentUser?.uid;

            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (usersDocs.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.blueGrey.shade100),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.info_outline_rounded,
                            color: AppColors.iconMuted,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'No hay usuarios registrados en la coleccion.',
                              style: TextStyle(
                                color: Colors.blueGrey.shade700,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Flexible(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: usersDocs.length,
                        itemBuilder: (context, index) {
                          final doc = usersDocs[index];
                          final userData =
                              doc.data() as Map<String, dynamic>? ?? {};
                          final displayName = _displayUserName(userData);
                          final email = _safeString(userData['email']);
                          final typeName =
                              _resolveUserType(userData['tipo'], userTypes);
                          final isCurrentUser = currentUserId == doc.id;
                          final initials =
                              _buildUserInitials(displayName, email);

                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border:
                                  Border.all(color: Colors.blueGrey.shade100),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.04),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: primario.withOpacity(0.14),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Center(
                                    child: Text(
                                      initials,
                                      style: TextStyle(
                                        color: primario,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        displayName,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14.5,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        email,
                                        style: TextStyle(
                                          color: Colors.blueGrey.shade700,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 12.5,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 8,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 6,
                                            ),
                                            decoration: BoxDecoration(
                                              color: primario.withOpacity(0.12),
                                              borderRadius:
                                                  BorderRadius.circular(999),
                                            ),
                                            child: Text(
                                              typeName,
                                              style: TextStyle(
                                                color: primario,
                                                fontSize: 11.5,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ),
                                          if (isCurrentUser)
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 10,
                                                vertical: 6,
                                              ),
                                              decoration: BoxDecoration(
                                                color: Colors.green
                                                    .withOpacity(0.1),
                                                borderRadius:
                                                    BorderRadius.circular(999),
                                              ),
                                              child: Text(
                                                'USUARIO ACTUAL',
                                                style: TextStyle(
                                                  color: Colors.green.shade700,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      tooltip: 'Editar usuario',
                                      icon: const Icon(
                                        Icons.edit_rounded,
                                        color: Colors.blueGrey,
                                        size: 21,
                                      ),
                                      onPressed: () {
                                        _openStyledSettingsSheet(
                                          context: context,
                                          title: 'Editar usuario',
                                          icon: Icons.person_rounded,
                                          hint:
                                              'Actualiza nombre, contacto y tipo de acceso del usuario.',
                                          maxWidth: 760,
                                          child: EditSystemUser(
                                            userId: doc.id,
                                            userData: userData,
                                            availableTypes: userTypes,
                                          ),
                                        );
                                      },
                                    ),
                                    IconButton(
                                      tooltip: isCurrentUser
                                          ? 'No puedes eliminar tu propia ficha'
                                          : 'Eliminar usuario',
                                      icon: Icon(
                                        Icons.delete_outline_rounded,
                                        color: isCurrentUser
                                            ? Colors.blueGrey.shade200
                                            : Colors.redAccent,
                                        size: 21,
                                      ),
                                      onPressed: () {
                                        _showDeleteUserSheet(
                                          context,
                                          userId: doc.id,
                                          displayName: displayName,
                                          isCurrentUser: isCurrentUser,
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildUserTypesManagerContent(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: db.collection('Otros').doc('tipos_usuarios').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docData = snapshot.data?.data() as Map<String, dynamic>?;
        final types = _extractUserTypes(docData);

        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: types.length,
                  itemBuilder: (context, index) {
                    final currentType = types[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blueGrey.shade100),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 4,
                        ),
                        leading: CircleAvatar(
                          radius: 18,
                          backgroundColor: primario.withOpacity(0.12),
                          child: Text(
                            '${index + 1}',
                            style: TextStyle(
                              color: primario,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        title: Text(
                          currentType,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14.5,
                            color: Colors.black87,
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              tooltip: 'Editar tipo',
                              icon: const Icon(
                                Icons.edit_outlined,
                                color: Colors.blueGrey,
                                size: 21,
                              ),
                              onPressed: () {
                                _openStyledSettingsSheet(
                                  context: context,
                                  title: 'Editar tipo de usuario',
                                  icon: Icons.edit_rounded,
                                  hint:
                                      'Modifica el nombre del tipo para mantener el catalogo actualizado.',
                                  maxWidth: 620,
                                  child: EditGenericCategory(
                                    docId: 'tipos_usuarios',
                                    existingItem: currentType,
                                    title: 'Editar tipo de usuario',
                                  ),
                                );
                              },
                            ),
                            IconButton(
                              tooltip: 'Eliminar tipo',
                              icon: const Icon(
                                Icons.delete_outline_rounded,
                                color: Colors.redAccent,
                                size: 21,
                              ),
                              onPressed: () {
                                _showDeleteUserTypeSheet(
                                  context,
                                  typeName: currentType,
                                  currentTypes: types,
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primario,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    Get.back();
                    _showAddUserTypeSheet(context);
                  },
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Agregar nuevo tipo'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showDeleteUserSheet(
    BuildContext context, {
    required String userId,
    required String displayName,
    required bool isCurrentUser,
  }) {
    if (isCurrentUser) {
      AnimatedSnackBar.material(
        'No puedes eliminar tu propia ficha de usuario.',
        type: AnimatedSnackBarType.warning,
      ).show(context);
      return;
    }

    _openStyledSettingsSheet(
      context: context,
      title: 'Eliminar usuario',
      icon: Icons.delete_outline_rounded,
      hint:
          'Esta accion elimina la ficha del usuario en la coleccion Usuarios.',
      danger: true,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.redAccent,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Se eliminara la ficha de $displayName.',
                      style: TextStyle(
                        color: Colors.red.shade700,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: CustomButton(
                    funcion: () => Get.back(),
                    texto: 'Cancelar',
                    cancelar: true,
                    icon: Icons.close_rounded,
                    width: double.infinity,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade600,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      minimumSize: const Size.fromHeight(52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () async {
                      try {
                        await db.collection('Usuarios').doc(userId).delete();

                        if (!mounted) return;
                        Get.back();
                        AnimatedSnackBar.material(
                          'Usuario eliminado con exito.',
                          type: AnimatedSnackBarType.success,
                        ).show(context);
                      } catch (e) {
                        if (!mounted) return;
                        AnimatedSnackBar.material(
                          'No se pudo eliminar el usuario: $e',
                          type: AnimatedSnackBarType.error,
                        ).show(context);
                      }
                    },
                    icon: const Icon(Icons.delete_rounded, size: 18),
                    label: const Text('Eliminar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteUserTypeSheet(
    BuildContext context, {
    required String typeName,
    required List<String> currentTypes,
  }) {
    if (currentTypes.length <= 1) {
      AnimatedSnackBar.material(
        'Debe existir al menos un tipo de usuario.',
        type: AnimatedSnackBarType.warning,
      ).show(context);
      return;
    }

    _openStyledSettingsSheet(
      context: context,
      title: 'Eliminar tipo de usuario',
      icon: Icons.delete_outline_rounded,
      hint:
          'Si hay usuarios con este tipo, se reasignaran al primer tipo disponible.',
      danger: true,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.redAccent,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Se eliminara el tipo ${typeName.toUpperCase()} del catalogo.',
                      style: TextStyle(
                        color: Colors.red.shade700,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: CustomButton(
                    funcion: () => Get.back(),
                    texto: 'Cancelar',
                    cancelar: true,
                    icon: Icons.close_rounded,
                    width: double.infinity,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade600,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      minimumSize: const Size.fromHeight(52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () async {
                      final remainingTypes = currentTypes
                          .where(
                            (e) => e.toUpperCase() != typeName.toUpperCase(),
                          )
                          .toList();
                      final replacementType = remainingTypes.first;

                      try {
                        final typesRef =
                            db.collection('Otros').doc('tipos_usuarios');
                        await typesRef.set(
                          {
                            'nombre': 'tipos_usuarios',
                            'tipos': remainingTypes,
                            'updatedAt': FieldValue.serverTimestamp(),
                          },
                          SetOptions(merge: true),
                        );

                        final usersSnapshot =
                            await db.collection('Usuarios').get();

                        final batch = db.batch();
                        var hasUpdates = false;
                        for (final userDoc in usersSnapshot.docs) {
                          final userType = _resolveUserType(
                            userDoc.data()['tipo'],
                            currentTypes,
                          );
                          if (userType.toUpperCase() ==
                              typeName.toUpperCase()) {
                            batch.update(userDoc.reference, {
                              'tipo': replacementType,
                              'updatedAt': FieldValue.serverTimestamp(),
                            });
                            hasUpdates = true;
                          }
                        }

                        if (hasUpdates) {
                          await batch.commit();
                        }

                        if (!mounted) return;
                        Get.back();
                        AnimatedSnackBar.material(
                          'Tipo eliminado y usuarios reasignados.',
                          type: AnimatedSnackBarType.success,
                        ).show(context);
                      } catch (e) {
                        if (!mounted) return;
                        AnimatedSnackBar.material(
                          'No se pudo eliminar el tipo: $e',
                          type: AnimatedSnackBarType.error,
                        ).show(context);
                      }
                    },
                    icon: const Icon(Icons.delete_rounded, size: 18),
                    label: const Text('Eliminar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlacesManagerContent(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: db
          .collection('Otros')
          .where('nombre', whereIn: ['lugares', 'lugaresHoras']).snapshots(),
      builder: (context, modalSnapshot) {
        if (!modalSnapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final localDocLugares = modalSnapshot.data!.docs
            .firstWhere((element) => element['nombre'] == 'lugares');
        final localDocHoras = modalSnapshot.data!.docs
            .firstWhere((element) => element['nombre'] == 'lugaresHoras');

        final localLugares = localDocLugares['tipos'] as List<dynamic>;
        final localHorariosLunesAJueves =
            localDocHoras['lunes_jueves'] as List<dynamic>;
        final localHorariosViernes = localDocHoras['viernes'] as List<dynamic>;
        final localHoras = localDocHoras['prueba_horas'] as List<dynamic>;

        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: localLugares.length,
                  itemBuilder: (context, i) {
                    final lj = localHorariosLunesAJueves[i]
                        .toString()
                        .replaceAll('/', ' a ');
                    final v = localHorariosViernes[i]
                        .toString()
                        .replaceAll('/', ' a ');
                    final mismoHorario =
                        localHorariosLunesAJueves[i] == localHorariosViernes[i];

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: primario.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '${localHoras[i]}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: primario,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Text(
                                    'Hrs',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: primario.withOpacity(0.8),
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${localLugares[i]}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    mismoHorario
                                        ? 'L a V: $lj'
                                        : 'L-J: $lj | V: $v',
                                    style: const TextStyle(
                                      color: Colors.black54,
                                      fontSize: 13,
                                      height: 1.3,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.edit_outlined,
                                color: Colors.blueGrey,
                                size: 22,
                              ),
                              onPressed: () {
                                _openStyledSettingsSheet(
                                  context: context,
                                  title: 'Editar establecimiento',
                                  icon: Icons.edit_rounded,
                                  hint:
                                      'Ajusta horas, colacion y horarios del establecimiento.',
                                  maxWidth:
                                      MediaQuery.of(context).size.width > 800
                                          ? 900
                                          : MediaQuery.of(context).size.width,
                                  child: EditPlace(
                                    existingPlace: localLugares[i].toString(),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primario,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    _openStyledSettingsSheet(
                      context: context,
                      title: 'Nuevo establecimiento',
                      icon: Icons.add_business_rounded,
                      hint:
                          'Registra un nuevo establecimiento con sus horarios.',
                      child: const NewPlace(),
                    );
                  },
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Agregar nuevo establecimiento'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _manageGenericCategory(
      BuildContext context, String docId, String title) {
    _openStyledSettingsSheet(
      context: context,
      title: title,
      icon: Icons.tune_rounded,
      hint: 'Edita, elimina o agrega nuevos elementos de $title.',
      maxWidth: MediaQuery.of(context).size.width > 800
          ? 900
          : MediaQuery.of(context).size.width,
      child: StreamBuilder<DocumentSnapshot>(
        stream: db.collection('Otros').doc(docId).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final items = snapshot.data!['tipos'] as List<dynamic>;

          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: items.length,
                    itemBuilder: (context, i) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 4),
                          leading: CircleAvatar(
                            radius: 18,
                            backgroundColor: primario.withOpacity(0.12),
                            child: Text('${i + 1}',
                                style: TextStyle(
                                    color: primario,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14)),
                          ),
                          title: Text('${items[i]}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 15)),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_outlined,
                                    color: Colors.blueGrey, size: 22),
                                onPressed: () {
                                  _openStyledSettingsSheet(
                                    context: context,
                                    title: 'Editar $title',
                                    icon: Icons.edit_rounded,
                                    hint:
                                        'Actualiza el nombre del elemento seleccionado.',
                                    child: EditGenericCategory(
                                      docId: docId,
                                      existingItem: items[i].toString(),
                                      title: 'Editar $title',
                                    ),
                                  );
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline,
                                    color: Colors.redAccent, size: 22),
                                onPressed: () {
                                  _showDeleteCategoryItemSheet(
                                      context, docId, items[i], title);
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primario,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      Get.back();
                      _showAddCategoryItemSheet(context, docId);
                    },
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: Text('Agregar nuevo a $title'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showAddCategoryItemSheet(BuildContext context, String docId) {
    Widget addWidget;
    String modalTitle = '';
    String modalHint = '';
    IconData modalIcon = Icons.add_rounded;
    switch (docId) {
      case 'afps':
        // Reutilizamos el widget existente de new_worker_page.dart
        // Nota: Asumo que los widgets están accesibles o importados si estuvieran en archivos separados.
        // Como están en new_worker_page.dart, y este es contract.dart, si no son públicos o exportados fallará.
        // Pero en la estructura actual parece que el usuario los define en los mismos archivos o globalmente.
        // Verificando imports...
        // No hay imports de new_worker_page.dart. Debería crearlos o importarlos.
        addWidget =
            const NewAfp(); // Placeholder, veré si puedo importarlo o duplicarlo si es pequeño.
        break;
      case 'previsiones':
        addWidget = const NewPrevision();
        modalTitle = 'Nueva prevision';
        modalHint = 'Registra la institucion de salud previsional.';
        modalIcon = Icons.local_hospital_rounded;
        break;
      case 'comunas':
        addWidget = const NewCommune();
        modalTitle = 'Nueva comuna';
        modalHint = 'Ingresa una comuna valida para los trabajadores.';
        modalIcon = Icons.location_city_rounded;
        break;
      case 'estadosciviles':
        addWidget = const NewCivilState();
        modalTitle = 'Nuevo estado civil';
        modalHint = 'Agrega un estado civil al listado del sistema.';
        modalIcon = Icons.favorite_border_rounded;
        break;
      case 'nacionalidades':
        addWidget = const NewNacionality();
        modalTitle = 'Nueva nacionalidad';
        modalHint = 'Registra una nacionalidad para los formularios.';
        modalIcon = Icons.flag_rounded;
        break;
      case 'labores':
        addWidget = const NewLabor();
        modalTitle = 'Nueva labor';
        modalHint = 'Agrega una labor o cargo disponible.';
        modalIcon = Icons.construction_rounded;
        break;
      default:
        return;
    }

    if (modalTitle.isEmpty) {
      modalTitle = 'Nueva AFP';
      modalHint = 'Ingresa el nombre de la AFP para incorporarla al listado.';
      modalIcon = Icons.account_balance_rounded;
    }

    _openStyledSettingsSheet(
      context: context,
      title: modalTitle,
      icon: modalIcon,
      hint: modalHint,
      child: addWidget,
    );
  }

  void _showDeleteCategoryItemSheet(
      BuildContext context, String docId, String item, String title) {
    _openStyledSettingsSheet(
      context: context,
      title: 'Confirmar eliminacion',
      icon: Icons.delete_outline_rounded,
      hint: 'Esta accion eliminara el elemento seleccionado de $title.',
      danger: true,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.redAccent,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Se eliminara ${item.toUpperCase()} de forma permanente.',
                      style: TextStyle(
                        color: Colors.red.shade700,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: CustomButton(
                    funcion: () => Get.back(),
                    texto: 'Cancelar',
                    cancelar: true,
                    icon: Icons.close_rounded,
                    width: double.infinity,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade600,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      minimumSize: const Size.fromHeight(52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () async {
                      try {
                        await db.collection('Otros').doc(docId).update({
                          'tipos': FieldValue.arrayRemove([item])
                        });
                        if (!mounted) return;
                        Get.back();
                        AnimatedSnackBar.material(
                          'Eliminado con exito',
                          type: AnimatedSnackBarType.success,
                        ).show(context);
                      } catch (e) {
                        if (!mounted) return;
                        AnimatedSnackBar.material(
                          'Error al eliminar: $e',
                          type: AnimatedSnackBarType.error,
                        ).show(context);
                      }
                    },
                    icon: const Icon(Icons.delete_rounded, size: 18),
                    label: const Text('Eliminar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ignore: unused_element
void _confirmDeleteCategoryItem(
    BuildContext context, String docId, String item, String title) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                    color: Colors.black12,
                    borderRadius: BorderRadius.circular(2)),
              ),
              Text('Eliminar $title',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              Text(
                  '¿Estás seguro de eliminar el elemento:\\n${item.toUpperCase()}?',
                  textAlign: TextAlign.center),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style:
                          ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      onPressed: () async {
                        try {
                          await db.collection('Otros').doc(docId).update({
                            'tipos': FieldValue.arrayRemove([item])
                          });
                          if (!ctx.mounted) return;
                          Navigator.pop(ctx);
                          if (!context.mounted) return;
                          AnimatedSnackBar.material(
                            'Eliminado con éxito',
                            type: AnimatedSnackBarType.success,
                          ).show(context);
                        } catch (e) {
                          if (!context.mounted) return;
                          AnimatedSnackBar.material(
                            'Error al eliminar: $e',
                            type: AnimatedSnackBarType.error,
                          ).show(context);
                        }
                      },
                      child: const Text('Sí, eliminar',
                          style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}

class EditGenericCategory extends StatefulWidget {
  final String docId;
  final String existingItem;
  final String title;
  const EditGenericCategory(
      {super.key,
      required this.docId,
      required this.existingItem,
      required this.title});

  @override
  State<EditGenericCategory> createState() => _EditGenericCategoryState();
}

class _EditGenericCategoryState extends State<EditGenericCategory> {
  final TextEditingController _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _controller.text = widget.existingItem;
  }

  Future<void> saveEdit() async {
    try {
      DocumentSnapshot doc =
          await db.collection('Otros').doc(widget.docId).get();
      List<dynamic> types = doc['tipos'];
      int index = types.indexOf(widget.existingItem);

      if (index != -1) {
        types[index] = _controller.text.trim();
        await db.collection('Otros').doc(widget.docId).update({'tipos': types});

        if (!mounted) return;
        Navigator.pop(context);
        AnimatedSnackBar.material(
          'Editado con éxito',
          type: AnimatedSnackBarType.success,
        ).show(context);
      }
    } catch (e) {
      if (!mounted) return;
      AnimatedSnackBar.material(
        'Error al editar: $e',
        type: AnimatedSnackBarType.error,
      ).show(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            InputTextField(
              textController: _controller,
              hint: 'Nombre',
              onFieldSubmitted: (_) {
                if (_formKey.currentState!.validate()) {
                  saveEdit();
                }
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor ingrese el nombre';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: CustomButton(
                    funcion: () => Navigator.pop(context),
                    texto: 'Cancelar',
                    cancelar: true,
                    icon: Icons.close_rounded,
                    width: double.infinity,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CustomButton(
                    funcion: () {
                      if (_formKey.currentState!.validate()) {
                        saveEdit();
                      }
                    },
                    texto: 'Guardar',
                    cancelar: false,
                    icon: Icons.check_rounded,
                    width: double.infinity,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class EditSystemUser extends StatefulWidget {
  const EditSystemUser({
    super.key,
    required this.userId,
    required this.userData,
    required this.availableTypes,
  });

  final String userId;
  final Map<String, dynamic> userData;
  final List<String> availableTypes;

  @override
  State<EditSystemUser> createState() => _EditSystemUserState();
}

class _EditSystemUserState extends State<EditSystemUser> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _occupationController = TextEditingController();

  String? _selectedType;
  bool _isSeller = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameController.text = (widget.userData['nombre'] ?? '').toString();
    _lastNameController.text = (widget.userData['apellido'] ?? '').toString();
    _emailController.text = (widget.userData['email'] ?? '').toString();
    _phoneController.text = (widget.userData['telefono'] ?? '').toString();
    _occupationController.text =
        (widget.userData['ocupacion'] ?? '').toString();
    _isSeller = widget.userData['seller'] == true;
    _selectedType = _resolveInitialType();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _occupationController.dispose();
    super.dispose();
  }

  String _resolveInitialType() {
    final available = widget.availableTypes.isEmpty
        ? const ['OPERADOR']
        : widget.availableTypes;
    final raw = widget.userData['tipo'];

    if (raw is num) {
      final index = raw.toInt() - 1;
      if (index >= 0 && index < available.length) {
        return available[index];
      }
    }

    final asText = raw?.toString().trim().toUpperCase() ?? '';
    if (asText.isNotEmpty) {
      for (final type in available) {
        if (type.toUpperCase() == asText) {
          return type;
        }
      }
    }

    return available.first;
  }

  Future<void> _save() async {
    if (_saving) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);

    try {
      await db.collection('Usuarios').doc(widget.userId).set(
        {
          'uid': widget.userId,
          'nombre': _nameController.text.trim(),
          'apellido': _lastNameController.text.trim(),
          'email': _emailController.text.trim().toLowerCase(),
          'telefono': _phoneController.text.trim(),
          'ocupacion': _occupationController.text.trim(),
          'tipo': _selectedType ?? '',
          'seller': _isSeller,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      if (!mounted) return;
      Get.back();
      AnimatedSnackBar.material(
        'Usuario actualizado con exito.',
        type: AnimatedSnackBarType.success,
      ).show(context);
    } catch (e) {
      if (!mounted) return;
      AnimatedSnackBar.material(
        'No se pudo guardar el usuario: $e',
        type: AnimatedSnackBarType.error,
      ).show(context);
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final availableTypes = widget.availableTypes.isEmpty
        ? const ['OPERADOR']
        : widget.availableTypes;
    if (!availableTypes.contains(_selectedType)) {
      _selectedType = availableTypes.first;
    }

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              InputTextField(
                textController: _nameController,
                hint: 'Nombres',
                validator: (value) {
                  if ((value ?? '').trim().isEmpty) {
                    return 'Ingresa el nombre.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              InputTextField(
                textController: _lastNameController,
                hint: 'Apellidos',
                validator: (value) {
                  if ((value ?? '').trim().isEmpty) {
                    return 'Ingresa el apellido.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              InputTextField(
                textController: _emailController,
                hint: 'Correo',
                teclado: TextInputType.emailAddress,
                validator: (value) {
                  final email = (value ?? '').trim().toLowerCase();
                  if (email.isEmpty) {
                    return 'Ingresa el correo.';
                  }
                  final regex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
                  if (!regex.hasMatch(email)) {
                    return 'Ingresa un correo valido.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              InputTextField(
                textController: _phoneController,
                hint: 'Telefono',
                teclado: TextInputType.phone,
              ),
              const SizedBox(height: 12),
              InputTextField(
                textController: _occupationController,
                hint: 'Ocupacion',
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedType,
                decoration: InputDecoration(
                  labelText: 'Tipo de usuario',
                  labelStyle: const TextStyle(
                    color: Colors.black45,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  floatingLabelStyle: TextStyle(
                    color: Colors.blueGrey.shade600,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF2F5F8),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.blueGrey.shade100),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: primario),
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                borderRadius: BorderRadius.circular(14),
                items: availableTypes
                    .map(
                      (type) => DropdownMenuItem<String>(
                        value: type,
                        child: Text(
                          type,
                          style: const TextStyle(
                            color: Colors.black54,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setState(() => _selectedType = value),
              ),
              const SizedBox(height: 4),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _isSeller,
                activeColor: primario,
                title: const Text(
                  'Vendedor habilitado',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13.5,
                  ),
                ),
                onChanged: (value) => setState(() => _isSeller = value),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: CustomButton(
                      funcion: () => Get.back(),
                      texto: 'Cancelar',
                      cancelar: true,
                      icon: Icons.close_rounded,
                      width: double.infinity,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CustomButton(
                      funcion: _saving ? () {} : _save,
                      texto: _saving ? 'Guardando...' : 'Guardar',
                      cancelar: false,
                      icon: Icons.check_rounded,
                      width: double.infinity,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class NewUserType extends StatefulWidget {
  const NewUserType({super.key});

  @override
  State<NewUserType> createState() => _NewUserTypeState();
}

class _NewUserTypeState extends State<NewUserType> {
  final _formKey = GlobalKey<FormState>();
  final _controller = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final newType = _controller.text.trim().toUpperCase();
    setState(() => _saving = true);

    try {
      final ref = db.collection('Otros').doc('tipos_usuarios');
      final snap = await ref.get();
      final currentRaw =
          (snap.data()?['tipos'] as List?)?.cast<dynamic>() ?? <dynamic>[];
      final current = currentRaw
          .map((e) => e.toString().trim().toUpperCase())
          .where((e) => e.isNotEmpty)
          .toSet()
          .toList();

      if (current.contains(newType)) {
        if (!mounted) return;
        AnimatedSnackBar.material(
          'Ese tipo ya existe en el listado.',
          type: AnimatedSnackBarType.warning,
        ).show(context);
        setState(() => _saving = false);
        return;
      }

      await ref.set(
        {
          'nombre': 'tipos_usuarios',
          'tipos': FieldValue.arrayUnion([newType]),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      if (!mounted) return;
      Get.back();
      AnimatedSnackBar.material(
        'Tipo de usuario creado con exito.',
        type: AnimatedSnackBarType.success,
      ).show(context);
    } catch (e) {
      if (!mounted) return;
      AnimatedSnackBar.material(
        'No se pudo crear el tipo: $e',
        type: AnimatedSnackBarType.error,
      ).show(context);
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              InputTextField(
                textController: _controller,
                hint: 'Tipo de usuario',
                onFieldSubmitted: (_) => _save(),
                validator: (value) {
                  if ((value ?? '').trim().isEmpty) {
                    return 'Ingresa un tipo de usuario.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: CustomButton(
                      funcion: () => Get.back(),
                      texto: 'Cancelar',
                      cancelar: true,
                      icon: Icons.close_rounded,
                      width: double.infinity,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CustomButton(
                      funcion: _saving ? () {} : _save,
                      texto: _saving ? 'Guardando...' : 'Agregar',
                      cancelar: false,
                      icon: Icons.add_rounded,
                      width: double.infinity,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class NewEnterpriseData extends StatefulWidget {
  const NewEnterpriseData({super.key});

  @override
  State<NewEnterpriseData> createState() => _NewEnterpriseDataState();
}

class _NewEnterpriseDataState extends State<NewEnterpriseData> {
  final TextEditingController _empresaController = TextEditingController();
  final TextEditingController _rutController = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  void saveNewEnterpriseData() {
    try {
      db.collection('Otros').doc('empresadata').update({
        'nombreempresa': _empresaController.text,
        'rut': _rutController.text,
      });
      Get.back();
      AnimatedSnackBar.material(
        'Datos de la empresa modificados con éxito',
        mobileSnackBarPosition: MobileSnackBarPosition.top,
        desktopSnackBarPosition: DesktopSnackBarPosition.bottomRight,
        type: AnimatedSnackBarType.success,
      ).show(context);
    } catch (e) {}
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 2),
              InputTextField(
                textController: _empresaController,
                hint: 'Nombre de la empresa',
                onFieldSubmitted: (_) {
                  if (_formKey.currentState!.validate()) {
                    saveNewEnterpriseData();
                  }
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingrese el nombre de la empresa';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: InputTextField(
                    teclado: TextInputType.text,
                    textController: _rutController,
                    hint: 'Rut',
                    onFieldSubmitted: (_) {
                      if (_formKey.currentState!.validate()) {
                        _formKey.currentState!.save();
                        saveNewEnterpriseData();
                      }
                    },
                    formater: RutFormatter(),
                    validator: (value) {
                      if (value == '') {
                        return 'Por favor ingrese un rut';
                      }
                      if (value!.length < 11) {
                        return 'Por favor ingrese un rut válido';
                      }
                      if (isRutValid(value.toString()) == false) {
                        return 'Por favor ingrese un rut válido';
                      }
                      return null;
                    },
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 15.0),
                child: Row(
                  children: [
                    Expanded(
                      child: CustomButton(
                        funcion: () {
                          Get.back();
                        },
                        texto: 'Cancelar',
                        cancelar: true,
                        icon: Icons.close_rounded,
                        width: double.infinity,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: CustomButton(
                          funcion: () {
                            if (_formKey.currentState!.validate()) {
                              _formKey.currentState!.save();
                              saveNewEnterpriseData();
                            }
                          },
                          texto: 'Guardar',
                          cancelar: false,
                          icon: Icons.check_rounded,
                          width: double.infinity),
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

class NewAmount extends StatefulWidget {
  const NewAmount({super.key});

  @override
  State<NewAmount> createState() => _NewAmountState();
}

class _NewAmountState extends State<NewAmount> {
  final TextEditingController _montoController = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  void saveNewAmount() {
    try {
      db.collection('Otros').doc('contrato').update({
        'montonum': int.parse(
            _montoController.text.replaceAll(',', '').replaceAll('.', '')),
        'montotext': SpellingNumber(lang: 'es')
            .convert(int.parse(
                _montoController.text.replaceAll(',', '').replaceAll('.', '')))
            .capitalizeFirst,
      });
      Get.back();
      AnimatedSnackBar.material(
        'Monto diario modificado con éxito',
        mobileSnackBarPosition: MobileSnackBarPosition.top,
        desktopSnackBarPosition: DesktopSnackBarPosition.bottomRight,
        type: AnimatedSnackBarType.success,
      ).show(context);
    } catch (e) {}
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 2),
              InputTextField(
                teclado: TextInputType.number,
                textController: _montoController,
                formater: FilteringTextInputFormatter.digitsOnly,
                hint: 'Monto diario',
                onFieldSubmitted: (_) {
                  if (_formKey.currentState!.validate()) {
                    _formKey.currentState!.save();
                    saveNewAmount();
                  }
                },
                money: true,
                prefix: '\$',
                validator: (value) {
                  if (value!.isEmpty) {
                    return 'Por favor ingrese un precio';
                  }
                  return null;
                },
              ),
              Padding(
                padding: const EdgeInsets.only(top: 15.0),
                child: Row(
                  children: [
                    Expanded(
                      child: CustomButton(
                        funcion: () {
                          Get.back();
                        },
                        texto: 'Cancelar',
                        cancelar: true,
                        icon: Icons.close_rounded,
                        width: double.infinity,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: CustomButton(
                          funcion: () {
                            if (_formKey.currentState!.validate()) {
                              _formKey.currentState!.save();
                              saveNewAmount();
                            }
                          },
                          texto: 'Guardar',
                          cancelar: false,
                          icon: Icons.check_rounded,
                          width: double.infinity),
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

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.fraction,
    required this.maxWidth,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final double fraction;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final width = fraction == 1.0
        ? maxWidth
        : (maxWidth - (16 * (1 / fraction).round())) * fraction;
    return SizedBox(
      width: width,
      child: Material(
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.black.withOpacity(0.05), width: 1),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: primario.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: primario, size: 26),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.black54,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.right,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
