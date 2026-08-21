import 'dart:ui';

import 'package:animated_snack_bar/animated_snack_bar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../customs/app_colors.dart';
import '../../customs/widgets/app_modal.dart';
import '../../customs/constants_values.dart';
import '../../customs/widgets/page_header.dart';
import '../../customs/widgets_custom.dart';
import '../../firebase_options.dart';
import '../../utils/user_access.dart';

class UsersPage extends StatefulWidget {
  const UsersPage({
    super.key,
    required this.canManageUsers,
  });

  final bool canManageUsers;

  @override
  State<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _displayName(Map<String, dynamic> data) {
    final name = (data['nombre'] ?? '').toString().trim();
    final lastName = (data['apellido'] ?? '').toString().trim();
    final full = '$name $lastName'.trim();
    if (full.isNotEmpty) return full.toUpperCase();
    return (data['email'] ?? '--').toString().toUpperCase();
  }

  String _initialsFrom(String displayName) {
    final words = displayName
        .split(' ')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    if (words.isEmpty) return 'U';
    final first = words.first.substring(0, 1);
    final second = words.length > 1 ? words[1].substring(0, 1) : first;
    return '$first$second'.toUpperCase();
  }

  int _enabledCount(Map<String, bool> source) {
    return source.values.where((value) => value == true).length;
  }

  String _updatedLabel(Map<String, dynamic> data) {
    final updated = data['updatedAt'];
    if (updated is Timestamp) {
      return DateFormat('dd/MM/yyyy HH:mm').format(updated.toDate());
    }
    final created = data['createdAt'];
    if (created is Timestamp) {
      return DateFormat('dd/MM/yyyy HH:mm').format(created.toDate());
    }
    return '--';
  }

  void _openCreateUserSheet() {
    showAppModal(
      context: context,
      title: 'Nuevo usuario',
      icon: Icons.person_add_alt_1_rounded,
      hint:
          'Crea un usuario con correo y contrasena y define sus accesos por vista y funcion.',
      child: const UserEditorSheet(),
    );
  }

  void _openEditUserSheet(
    String userId,
    Map<String, dynamic> userData,
  ) {
    showAppModal(
      context: context,
      title: 'Editar usuario',
      icon: Icons.edit_rounded,
      hint:
          'Actualiza datos del perfil y controla a que vistas o funciones puede acceder.',
      child: UserEditorSheet(
        userId: userId,
        userData: userData,
      ),
    );
  }

  Future<void> _toggleUserActive(
    String userId,
    bool nextValue,
    bool isCurrentUser,
  ) async {
    if (isCurrentUser && nextValue == false) {
      AnimatedSnackBar.material(
        'No puedes desactivar tu propio usuario.',
        type: AnimatedSnackBarType.warning,
      ).show(context);
      return;
    }

    await FirebaseFirestore.instance.collection('Usuarios').doc(userId).set(
      {
        'activo': nextValue,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  void _confirmDeleteProfile({
    required String userId,
    required String userName,
    required bool isCurrentUser,
  }) {
    if (isCurrentUser) {
      AnimatedSnackBar.material(
        'No puedes eliminar tu propia ficha.',
        type: AnimatedSnackBarType.warning,
      ).show(context);
      return;
    }

    showAppModal(
      context: context,
      title: 'Eliminar ficha de usuario',
      icon: Icons.delete_outline_rounded,
      danger: true,
      hint:
          'Esto elimina solo el documento en Usuarios. No elimina la cuenta de Firebase Auth.',
      maxWidth: 620,
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
                      'Se eliminara la ficha de $userName.',
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
                    funcion: () => Navigator.pop(context),
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
                        await FirebaseFirestore.instance
                            .collection('Usuarios')
                            .doc(userId)
                            .delete();
                        if (!mounted) return;
                        Navigator.pop(context);
                        AnimatedSnackBar.material(
                          'Ficha eliminada con exito.',
                          type: AnimatedSnackBarType.success,
                        ).show(context);
                      } catch (e) {
                        if (!mounted) return;
                        AnimatedSnackBar.material(
                          'No se pudo eliminar la ficha: $e',
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFF4F8FC),
              Color(0xFFEAF0F5),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const PageHeader(
              title: 'Administracion de usuarios',
              subtitle: 'Crea cuentas, edita perfiles y controla permisos',
              icon: Icons.manage_accounts_rounded,
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('Usuarios')
                    .snapshots(),
                builder: (context, usersSnapshot) {
                  if (!usersSnapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final docs = usersSnapshot.data!.docs.toList();
                  docs.sort((a, b) {
                    final aData = a.data() as Map<String, dynamic>? ?? {};
                    final bData = b.data() as Map<String, dynamic>? ?? {};
                    return _displayName(aData)
                        .toLowerCase()
                        .compareTo(_displayName(bData).toLowerCase());
                  });

                  final currentUserId = FirebaseAuth.instance.currentUser?.uid;
                  final activeCount = docs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>? ?? {};
                    return UserAccess.fromUserData(data).active;
                  }).length;
                  final search = _searchQuery.trim().toLowerCase();
                  final filteredDocs = docs.where((doc) {
                    if (search.isEmpty) return true;
                    final data = doc.data() as Map<String, dynamic>? ?? {};
                    final name = _displayName(data).toLowerCase();
                    final email =
                        (data['email'] ?? '').toString().toLowerCase();
                    return name.contains(search) || email.contains(search);
                  }).toList();

                  return LayoutBuilder(
                    builder: (context, constraints) {
                      final hasTwoColumns = constraints.maxWidth >= 980;
                      final cardWidth = hasTwoColumns
                          ? (constraints.maxWidth - 12) / 2
                          : constraints.maxWidth;
                      final toolbarInline = constraints.maxWidth >= 900;

                      return SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _UsersSummaryCard(
                              totalUsers: docs.length,
                              activeUsers: activeCount,
                              visibleUsers: filteredDocs.length,
                            ),
                            const SizedBox(height: 14),
                            _GlassPanel(
                              padding: const EdgeInsets.all(12),
                              borderRadius: BorderRadius.circular(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (toolbarInline)
                                    Row(
                                      children: [
                                        Expanded(
                                          child: TextField(
                                            controller: _searchController,
                                            onChanged: (value) {
                                              setState(
                                                  () => _searchQuery = value);
                                            },
                                            style: const TextStyle(
                                              fontSize: 13.5,
                                              fontWeight: FontWeight.w600,
                                            ),
                                            decoration: InputDecoration(
                                              hintText:
                                                  'Buscar por nombre o correo...',
                                              hintStyle: const TextStyle(
                                                color: AppColors.textFaint,
                                                fontSize: 13.5,
                                                fontWeight: FontWeight.w500,
                                              ),
                                              prefixIcon: const Icon(
                                                Icons.search_rounded,
                                                color: AppColors.iconMuted,
                                                size: 20,
                                              ),
                                              suffixIcon: _searchQuery.isEmpty
                                                  ? null
                                                  : IconButton(
                                                      onPressed: () {
                                                        _searchController
                                                            .clear();
                                                        setState(() =>
                                                            _searchQuery = '');
                                                      },
                                                      icon: Icon(
                                                        Icons.close_rounded,
                                                        color: Colors
                                                            .blueGrey.shade500,
                                                        size: 19,
                                                      ),
                                                      tooltip: 'Limpiar',
                                                    ),
                                              filled: true,
                                              fillColor: Colors.white
                                                  .withOpacity(0.62),
                                              contentPadding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 14,
                                                vertical: 13,
                                              ),
                                              enabledBorder: OutlineInputBorder(
                                                borderSide: BorderSide(
                                                  color: Colors.white
                                                      .withOpacity(0.9),
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(14),
                                              ),
                                              focusedBorder: OutlineInputBorder(
                                                borderSide: BorderSide(
                                                    color: primario
                                                        .withOpacity(0.7)),
                                                borderRadius:
                                                    BorderRadius.circular(14),
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        SizedBox(
                                          width: 230,
                                          child: CustomButton(
                                            funcion: widget.canManageUsers
                                                ? _openCreateUserSheet
                                                : () {
                                                    AnimatedSnackBar.material(
                                                      'No tienes permiso para crear usuarios.',
                                                      type: AnimatedSnackBarType
                                                          .warning,
                                                    ).show(context);
                                                  },
                                            texto: 'Nuevo usuario',
                                            icon:
                                                Icons.person_add_alt_1_rounded,
                                            width: double.infinity,
                                          ),
                                        ),
                                      ],
                                    )
                                  else ...[
                                    TextField(
                                      controller: _searchController,
                                      onChanged: (value) {
                                        setState(() => _searchQuery = value);
                                      },
                                      style: const TextStyle(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      decoration: InputDecoration(
                                        hintText:
                                            'Buscar por nombre o correo...',
                                        hintStyle: const TextStyle(
                                          color: AppColors.textFaint,
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        prefixIcon: const Icon(
                                          Icons.search_rounded,
                                          color: AppColors.iconMuted,
                                          size: 20,
                                        ),
                                        suffixIcon: _searchQuery.isEmpty
                                            ? null
                                            : IconButton(
                                                onPressed: () {
                                                  _searchController.clear();
                                                  setState(
                                                      () => _searchQuery = '');
                                                },
                                                icon: const Icon(
                                                  Icons.close_rounded,
                                                  color: AppColors.iconMuted,
                                                  size: 19,
                                                ),
                                                tooltip: 'Limpiar',
                                              ),
                                        filled: true,
                                        fillColor: Colors.white,
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                                horizontal: 14, vertical: 13),
                                        enabledBorder: OutlineInputBorder(
                                          borderSide: BorderSide(
                                              color: Colors.white
                                                  .withOpacity(0.9)),
                                          borderRadius:
                                              BorderRadius.circular(14),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderSide: BorderSide(
                                              color: primario.withOpacity(0.7)),
                                          borderRadius:
                                              BorderRadius.circular(14),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    SizedBox(
                                      width: double.maxFinite,
                                      child: CustomButton(
                                        funcion: widget.canManageUsers
                                            ? _openCreateUserSheet
                                            : () {
                                                AnimatedSnackBar.material(
                                                  'No tienes permiso para crear usuarios.',
                                                  type: AnimatedSnackBarType
                                                      .warning,
                                                ).show(context);
                                              },
                                        texto: 'Nuevo usuario',
                                        icon: Icons.person_add_alt_1_rounded,
                                        width: double.infinity,
                                      ),
                                    ),
                                  ],
                                  if (!widget.canManageUsers) ...[
                                    const SizedBox(height: 10),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: Colors.amber.shade100
                                            .withOpacity(0.5),
                                        borderRadius:
                                            BorderRadius.circular(999),
                                        border: Border.all(
                                            color: Colors.amber.shade200),
                                      ),
                                      child: Text(
                                        'Modo lectura: sin permisos de gestion',
                                        style: TextStyle(
                                          color: Colors.amber.shade900,
                                          fontSize: 11.8,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(height: 14),
                            if (docs.isEmpty)
                              const _NoUsersCard(
                                message: 'No hay usuarios para mostrar.',
                              )
                            else if (filteredDocs.isEmpty)
                              const _NoUsersCard(
                                message:
                                    'No se encontraron usuarios para ese criterio de busqueda.',
                              )
                            else
                              Wrap(
                                spacing: 12,
                                runSpacing: 12,
                                children: filteredDocs.map((userDoc) {
                                  final data =
                                      userDoc.data() as Map<String, dynamic>? ??
                                          {};
                                  final access = UserAccess.fromUserData(data);
                                  final displayName = _displayName(data);
                                  final email =
                                      (data['email'] ?? '--').toString().trim();
                                  final isCurrentUser =
                                      currentUserId == userDoc.id;
                                  final isActive = access.active;

                                  return SizedBox(
                                    width: cardWidth,
                                    child: _UserCard(
                                      displayName: displayName,
                                      email: email,
                                      initials: _initialsFrom(displayName),
                                      isActive: isActive,
                                      isCurrentUser: isCurrentUser,
                                      canManageUsers: widget.canManageUsers,
                                      enabledViews: _enabledCount(access.views),
                                      enabledActions:
                                          _enabledCount(access.actions),
                                      updatedAt: _updatedLabel(data),
                                      onEdit: () => _openEditUserSheet(
                                        userDoc.id,
                                        data,
                                      ),
                                      onToggleActive: () => _toggleUserActive(
                                        userDoc.id,
                                        !isActive,
                                        isCurrentUser,
                                      ),
                                      onDelete: () => _confirmDeleteProfile(
                                        userId: userDoc.id,
                                        userName: displayName,
                                        isCurrentUser: isCurrentUser,
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GlassPanel extends StatelessWidget {
  const _GlassPanel({
    required this.child,
    required this.padding,
    this.borderRadius,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(14);
    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: double.infinity,
          padding: padding,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Colors.white,
                Colors.white,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: radius,
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: Colors.blueGrey.shade900.withOpacity(0.08),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class _UsersSummaryCard extends StatelessWidget {
  const _UsersSummaryCard({
    required this.totalUsers,
    required this.activeUsers,
    required this.visibleUsers,
  });

  final int totalUsers;
  final int activeUsers;
  final int visibleUsers;

  @override
  Widget build(BuildContext context) {
    return _GlassPanel(
      padding: const EdgeInsets.all(14),
      borderRadius: BorderRadius.circular(16),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          _summaryChip(Icons.people_alt_rounded, '$totalUsers usuarios'),
          _summaryChip(Icons.verified_user_rounded, '$activeUsers activos'),
          _summaryChip(Icons.visibility_rounded, '$visibleUsers visibles'),
        ],
      ),
    );
  }

  Widget _summaryChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.blueGrey.shade700),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: Colors.blueGrey.shade800,
              fontWeight: FontWeight.w700,
              fontSize: 12.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _NoUsersCard extends StatelessWidget {
  const _NoUsersCard({
    required this.message,
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    return _GlassPanel(
      padding: const EdgeInsets.all(18),
      borderRadius: BorderRadius.circular(14),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: primario.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.search_off_rounded, color: primario, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: Colors.blueGrey.shade700,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _UserInfoChip extends StatelessWidget {
  const _UserInfoChip({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.blueGrey.shade600),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: Colors.blueGrey.shade700,
              fontSize: 11.8,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  const _UserCard({
    required this.displayName,
    required this.email,
    required this.initials,
    required this.isActive,
    required this.isCurrentUser,
    required this.canManageUsers,
    required this.enabledViews,
    required this.enabledActions,
    required this.updatedAt,
    required this.onEdit,
    required this.onToggleActive,
    required this.onDelete,
  });

  final String displayName;
  final String email;
  final String initials;
  final bool isActive;
  final bool isCurrentUser;
  final bool canManageUsers;
  final int enabledViews;
  final int enabledActions;
  final String updatedAt;
  final VoidCallback onEdit;
  final VoidCallback onToggleActive;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return _GlassPanel(
      padding: const EdgeInsets.all(14),
      borderRadius: BorderRadius.circular(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: primario.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    initials,
                    style: TextStyle(
                      color: primario,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14.5,
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
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _pill(
                text: isActive ? 'ACTIVO' : 'INACTIVO',
                background: isActive
                    ? Colors.green.withOpacity(0.12)
                    : Colors.red.withOpacity(0.12),
                foreground:
                    isActive ? Colors.green.shade700 : Colors.red.shade700,
              ),
              if (isCurrentUser)
                _pill(
                  text: 'USUARIO ACTUAL',
                  background: Colors.amber.withOpacity(0.15),
                  foreground: Colors.amber.shade800,
                ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _UserInfoChip(
                icon: Icons.view_quilt_rounded,
                label: '$enabledViews vistas',
              ),
              _UserInfoChip(
                icon: Icons.tune_rounded,
                label: '$enabledActions funciones',
              ),
              _UserInfoChip(
                icon: Icons.schedule_rounded,
                label: 'Actualizado $updatedAt',
              ),
            ],
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 400;
              final buttonWidth = compact
                  ? (constraints.maxWidth - 8) / 2
                  : (constraints.maxWidth - 16) / 3;

              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  SizedBox(
                    width: buttonWidth,
                    child: _actionButton(
                      label: 'Editar',
                      icon: Icons.edit_rounded,
                      onPressed: onEdit,
                      enabled: canManageUsers,
                    ),
                  ),
                  SizedBox(
                    width: buttonWidth,
                    child: _actionButton(
                      label: isActive ? 'Desactivar' : 'Activar',
                      icon: isActive
                          ? Icons.lock_open_rounded
                          : Icons.lock_rounded,
                      onPressed: onToggleActive,
                      enabled: canManageUsers,
                    ),
                  ),
                  SizedBox(
                    width: buttonWidth,
                    child: _actionButton(
                      label: 'Eliminar',
                      icon: Icons.delete_outline_rounded,
                      onPressed: onDelete,
                      enabled: canManageUsers,
                      danger: true,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _actionButton({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
    required bool enabled,
    bool danger = false,
  }) {
    final color = danger ? Colors.red.shade700 : Colors.blueGrey.shade700;
    return SizedBox(
      height: 38,
      child: OutlinedButton.icon(
        onPressed: enabled ? onPressed : null,
        icon: Icon(icon, size: 16),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          textStyle: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
          ),
          side: BorderSide(
            color: enabled
                ? (danger ? Colors.red.shade200 : Colors.blueGrey.shade200)
                : Colors.blueGrey.shade100,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          backgroundColor: Colors.white,
          disabledForegroundColor: Colors.blueGrey.shade300,
        ),
      ),
    );
  }

  Widget _pill({
    required String text,
    required Color background,
    required Color foreground,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: foreground,
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class UserEditorSheet extends StatefulWidget {
  const UserEditorSheet({
    super.key,
    this.userId,
    this.userData,
  });

  final String? userId;
  final Map<String, dynamic>? userData;

  bool get isCreate => userId == null;

  @override
  State<UserEditorSheet> createState() => _UserEditorSheetState();
}

class _UserEditorSheetState extends State<UserEditorSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _occupationController = TextEditingController();

  late Map<String, bool> _views;
  late Map<String, bool> _actions;
  bool _active = true;
  bool _saving = false;

  Map<String, bool> _defaultNewViews() {
    return {
      UserViewKeys.dashboard: true,
      UserViewKeys.workers: true,
      UserViewKeys.attendance: true,
      UserViewKeys.users: false,
      UserViewKeys.settings: false,
    };
  }

  Map<String, bool> _defaultNewActions() {
    return {
      UserActionKeys.manageUsers: false,
    };
  }

  @override
  void initState() {
    super.initState();
    final initial = widget.userData ?? <String, dynamic>{};
    final access = UserAccess.fromUserData(initial);

    _views = widget.isCreate
        ? _defaultNewViews()
        : Map<String, bool>.from(access.views);
    _actions = widget.isCreate
        ? _defaultNewActions()
        : Map<String, bool>.from(access.actions);
    _active = access.active;
    _nameController.text = (initial['nombre'] ?? '').toString();
    _lastNameController.text = (initial['apellido'] ?? '').toString();
    _emailController.text = (initial['email'] ?? '').toString();
    _phoneController.text = (initial['telefono'] ?? '').toString();
    _occupationController.text = (initial['ocupacion'] ?? '').toString();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _occupationController.dispose();
    super.dispose();
  }

  Map<String, dynamic> _permissionsPayload() {
    return {
      'views': _views,
      'actions': _actions,
    };
  }

  Future<FirebaseApp> _getSecondaryApp() async {
    const appName = 'user-admin-secondary';
    for (final app in Firebase.apps) {
      if (app.name == appName) {
        return app;
      }
    }
    return Firebase.initializeApp(
      name: appName,
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  Future<void> _save() async {
    if (_saving) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);

    try {
      if (widget.isCreate) {
        final app = await _getSecondaryApp();
        final secondaryAuth = FirebaseAuth.instanceFor(app: app);
        final credential = await secondaryAuth.createUserWithEmailAndPassword(
          email: _emailController.text.trim().toLowerCase(),
          password: _passwordController.text.trim(),
        );

        final uid = credential.user?.uid;
        if (uid == null) {
          throw Exception('No fue posible obtener el uid del nuevo usuario.');
        }

        await FirebaseFirestore.instance.collection('Usuarios').doc(uid).set({
          'uid': uid,
          'email': _emailController.text.trim().toLowerCase(),
          'nombre': _nameController.text.trim(),
          'apellido': _lastNameController.text.trim(),
          'permissions': _permissionsPayload(),
          'activo': _active,
          'telefono': _phoneController.text.trim(),
          'ocupacion': _occupationController.text.trim(),
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        await secondaryAuth.signOut();
      } else {
        await FirebaseFirestore.instance
            .collection('Usuarios')
            .doc(widget.userId)
            .set(
          {
            'nombre': _nameController.text.trim(),
            'apellido': _lastNameController.text.trim(),
            'permissions': _permissionsPayload(),
            'activo': _active,
            'telefono': _phoneController.text.trim(),
            'ocupacion': _occupationController.text.trim(),
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      }

      if (!mounted) return;
      Navigator.pop(context);
      AnimatedSnackBar.material(
        widget.isCreate
            ? 'Usuario creado con exito.'
            : 'Usuario actualizado con exito.',
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
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              InputTextField(
                textController: _nameController,
                hint: 'Nombres',
                validator: (value) => (value ?? '').trim().isEmpty
                    ? 'Ingresa los nombres.'
                    : null,
              ),
              const SizedBox(height: 12),
              InputTextField(
                textController: _lastNameController,
                hint: 'Apellidos',
                validator: (value) => (value ?? '').trim().isEmpty
                    ? 'Ingresa los apellidos.'
                    : null,
              ),
              const SizedBox(height: 12),
              InputTextField(
                textController: _emailController,
                hint: 'Correo',
                teclado: TextInputType.emailAddress,
                readOnly: !widget.isCreate,
                validator: (value) {
                  final current = (value ?? '').trim().toLowerCase();
                  final regex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
                  if (current.isEmpty) return 'Ingresa un correo.';
                  if (!regex.hasMatch(current)) return 'Correo no valido.';
                  return null;
                },
              ),
              if (widget.isCreate) ...[
                const SizedBox(height: 12),
                InputTextField(
                  textController: _passwordController,
                  hint: 'Contrasena temporal',
                  passwordField: true,
                  validator: (value) {
                    final current = (value ?? '').trim();
                    if (current.isEmpty) return 'Ingresa una contrasena.';
                    if (current.length < 6) return 'Minimo 6 caracteres.';
                    return null;
                  },
                ),
              ],
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
              const SizedBox(height: 6),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _active,
                activeColor: primario,
                title: const Text('Usuario activo'),
                subtitle: const Text(
                  'Si se desactiva, el usuario no podra ingresar.',
                  style: TextStyle(fontSize: 12),
                ),
                onChanged: (value) => setState(() => _active = value),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Vistas con acceso',
                  style: TextStyle(
                    color: Colors.blueGrey.shade800,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              ...UserViewKeys.all.map(
                (key) => SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _views[key] ?? false,
                  activeColor: primario,
                  title: Text(userViewLabels[key] ?? key),
                  onChanged: (value) {
                    setState(() => _views[key] = value);
                  },
                ),
              ),
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Funciones habilitadas',
                  style: TextStyle(
                    color: Colors.blueGrey.shade800,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              ...UserActionKeys.all.map(
                (key) => SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _actions[key] ?? false,
                  activeColor: primario,
                  title: Text(userActionLabels[key] ?? key),
                  onChanged: (value) {
                    setState(() => _actions[key] = value);
                  },
                ),
              ),
              const SizedBox(height: 10),
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
                      funcion: _saving ? () {} : _save,
                      texto: _saving ? 'Guardando...' : 'Guardar',
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
