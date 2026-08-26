import 'package:animated_snack_bar/animated_snack_bar.dart';
import 'package:flutter/material.dart';

import '../../customs/app_colors.dart';
import '../../customs/widgets/app_form.dart';
import '../../customs/widgets/app_modal.dart';
import '../../customs/widgets/app_skeleton.dart';
import '../../services/duplicados.dart';
import 'edit_worker_page.dart';

/// Abre las fichas repetidas como modal.
///
/// Como modal y no como pagina: las vistas de la app viven dentro del
/// `Scaffold` de `HomePage`, que no tiene `AppBar`. Empujada como ruta, esta
/// pantalla tapaba todo sin ningun boton de volver y dejaba la app sin salida.
Future<void> mostrarFichasRepetidas(BuildContext context) {
  return showAppModal<void>(
    context: context,
    title: 'Fichas repetidas',
    subtitle: 'Trabajadores que aparecen con el mismo RUT',
    icon: Icons.join_inner_rounded,
    maxWidth: 720,
    child: const DuplicadosPage(),
  );
}

/// Fichas que comparten RUT.
///
/// La pantalla **propone**, no decide. Medido sobre las 676 fichas: de 16 RUT
/// repetidos, en 9 difiere la fecha de nacimiento, y en al menos uno los
/// nombres son de dos personas distintas. Fusionar sin mirar borraria a un
/// trabajador real, asi que aqui todo pasa por alguien que puede tener la
/// cedula a la vista.
class DuplicadosPage extends StatefulWidget {
  const DuplicadosPage({super.key});

  @override
  State<DuplicadosPage> createState() => _DuplicadosPageState();
}

class _DuplicadosPageState extends State<DuplicadosPage> {
  late Future<List<GrupoRepetido>> _grupos;

  @override
  void initState() {
    super.initState();
    _grupos = Duplicados.buscar();
  }

  void _recargar() => setState(() => _grupos = Duplicados.buscar());

  Future<void> _editar(FichaRepetida ficha) async {
    // Como modal, igual que desde el detalle del trabajador. Empujada como
    // ruta tapaba el modal de fichas repetidas sin dejar como volver.
    await showAppModal<void>(
      context: context,
      title: 'Editar trabajador',
      subtitle: ficha.nombreCompleto.toUpperCase(),
      badge: 'Ficha',
      icon: Icons.edit_note_rounded,
      child: EditWorker(worker: ficha.modelo),
    );
    if (mounted) _recargar();
  }

  Future<void> _eliminar(FichaRepetida ficha) async {
    final ok = await showAppModal<bool>(
      context: context,
      title: 'Eliminar ficha',
      icon: Icons.delete_outline_rounded,
      danger: true,
      child: AppDangerConfirmBody(
        message: 'Se elimina la ficha de "${ficha.nombreCompleto}".',
        detail: 'Las fotos de carnet NO se borran: se guardan por RUT, asi '
            'que son las mismas que usa la ficha que se conserva.\n\n'
            'Esto no se puede deshacer.',
        confirmText: 'Eliminar',
        confirmIcon: Icons.delete_outline_rounded,
        onCancel: () => Navigator.of(context).pop(false),
        onConfirm: () => Navigator.of(context).pop(true),
      ),
    );
    if (ok != true) return;
    try {
      await Duplicados.eliminar(ficha);
      if (!mounted) return;
      AnimatedSnackBar.material('Ficha eliminada.',
              type: AnimatedSnackBarType.success)
          .show(context);
      _recargar();
    } catch (e) {
      if (!mounted) return;
      AnimatedSnackBar.material('No se pudo eliminar: $e',
              type: AnimatedSnackBarType.error)
          .show(context);
    }
  }

  Future<void> _fusionar(
    GrupoRepetido grupo,
    FichaRepetida conservada,
    FichaRepetida descartada,
  ) async {
    final ok = await showAppModal<bool>(
      context: context,
      title: 'Fusionar fichas',
      icon: Icons.merge_rounded,
      danger: true,
      child: AppDangerConfirmBody(
        message: 'Se conserva "${conservada.nombreCompleto}" y se eliminan '
            'las otras ${grupo.fichas.length - 1}.',
        detail: 'Los campos que esten vacios en la ficha que se conserva se '
            'rellenan con los de la otra. Nunca se pisa un dato existente.\n\n'
            'La fecha de ingreso queda en la mas reciente de las dos.\n\n'
            'Esto no se puede deshacer.',
        confirmText: 'Fusionar',
        confirmIcon: Icons.merge_rounded,
        onCancel: () => Navigator.of(context).pop(false),
        onConfirm: () => Navigator.of(context).pop(true),
      ),
    );
    if (ok != true) return;

    try {
      // Con tres fichas se funde una por una contra la que se conserva.
      for (final otra in grupo.fichas.where((f) => f.id != conservada.id)) {
        await Duplicados.fusionar(conservada: conservada, descartada: otra);
      }
      if (!mounted) return;
      AnimatedSnackBar.material(
        'Fichas fusionadas.',
        type: AnimatedSnackBarType.success,
      ).show(context);
      _recargar();
    } catch (e) {
      if (!mounted) return;
      AnimatedSnackBar.material(
        'No se pudo fusionar: $e',
        type: AnimatedSnackBarType.error,
      ).show(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Alto acotado: el modal se adapta al contenido, y con 16 grupos la lista
    // crecerian mas que la pantalla.
    return SizedBox(
      height: (MediaQuery.sizeOf(context).height * 0.62).clamp(320.0, 620.0),
      child: Column(
        children: [
          Expanded(
            child: FutureBuilder<List<GrupoRepetido>>(
              future: _grupos,
              builder: (context, snap) {
                if (snap.hasError) {
                  return AppEmptyNotice(
                    icon: Icons.error_outline_rounded,
                    message: 'No se pudo revisar el padron',
                    detail: '${snap.error}',
                    actionLabel: 'Reintentar',
                    actionIcon: Icons.refresh_rounded,
                    onAction: _recargar,
                  );
                }
                if (!snap.hasData) {
                  return const Padding(
                    padding: EdgeInsets.all(24),
                    child: SkeletonTarjetas(filas: 3),
                  );
                }
                final grupos = snap.data!;
                if (grupos.isEmpty) {
                  return const AppEmptyNotice(
                    icon: Icons.verified_outlined,
                    message: 'No hay fichas repetidas',
                    detail: 'Ningun RUT aparece en mas de una ficha.',
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(4, 4, 4, 8),
                  itemCount: grupos.length + 1,
                  itemBuilder: (context, i) {
                    if (i == 0) return _Resumen(grupos: grupos);
                    return _TarjetaGrupo(
                      grupo: grupos[i - 1],
                      onFusionar: _fusionar,
                      onEditar: _editar,
                      onEliminar: _eliminar,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _Resumen extends StatelessWidget {
  const _Resumen({required this.grupos});

  final List<GrupoRepetido> grupos;

  @override
  Widget build(BuildContext context) {
    final sospechosos = grupos.where((g) => g.pareceOtraPersona).length;
    final fichas = grupos.fold<int>(0, (a, g) => a + g.fichas.length);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        '${grupos.length} RUT aparecen en mas de una ficha, '
        '$fichas fichas en total.'
        '${sospechosos > 0 ? '\n$sospechosos parecen personas distintas con '
            'el RUT mal escrito: esos van primero.' : ''}',
        style: const TextStyle(
          color: AppColors.textBody,
          fontSize: 14,
          height: 1.4,
        ),
      ),
    );
  }
}

class _TarjetaGrupo extends StatelessWidget {
  const _TarjetaGrupo({
    required this.grupo,
    required this.onFusionar,
    required this.onEditar,
    required this.onEliminar,
  });

  final GrupoRepetido grupo;
  final Future<void> Function(
    GrupoRepetido grupo,
    FichaRepetida conservada,
    FichaRepetida descartada,
  ) onFusionar;
  final Future<void> Function(FichaRepetida ficha) onEditar;
  final Future<void> Function(FichaRepetida ficha) onEliminar;

  @override
  Widget build(BuildContext context) {
    final conflicto = grupo.camposEnConflicto;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: appCardDecoration(),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                grupo.rut,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: AppColors.textStrong,
                  letterSpacing: 0.4,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '${grupo.fichas.length} fichas',
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          if (grupo.pareceOtraPersona) ...[
            const SizedBox(height: 10),
            const _Aviso(
              texto: 'El nombre y la fecha de nacimiento no coinciden. '
                  'Probablemente son dos personas y el RUT esta mal escrito '
                  'en una: corrigelo en vez de fusionar.',
            ),
          ],
          if (conflicto.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              'No coinciden: ${conflicto.join(', ')}',
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 12.5,
              ),
            ),
          ],
          const SizedBox(height: 12),
          for (final ficha in grupo.fichas)
            _FilaFicha(
              ficha: ficha,
              onConservar: () => onFusionar(grupo, ficha, ficha),
              onEditar: () => onEditar(ficha),
              onEliminar: () => onEliminar(ficha),
            ),
        ],
      ),
    );
  }
}

class _FilaFicha extends StatelessWidget {
  const _FilaFicha({
    required this.ficha,
    required this.onConservar,
    required this.onEditar,
    required this.onEliminar,
  });

  final FichaRepetida ficha;
  final VoidCallback onConservar;
  final VoidCallback onEditar;
  final VoidCallback onEliminar;

  @override
  Widget build(BuildContext context) {
    final ingreso = ficha.texto('ingreso');
    final nacimiento = ficha.texto('fechaNacimiento');
    final labor = ficha.texto('labor');
    final lugar = ficha.texto('lugar');
    final conFotos = ficha.texto('imagenFront').isNotEmpty &&
        ficha.texto('imagenBack').isNotEmpty;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surfaceSunken,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ficha.nombreCompleto.toUpperCase(),
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textStrong,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    [
                      if (nacimiento.isNotEmpty) 'Nacio el $nacimiento',
                      if (ingreso.isNotEmpty) 'Ingreso el $ingreso',
                      if (labor.isNotEmpty) labor,
                      if (lugar.isNotEmpty) lugar,
                      conFotos ? 'con fotos' : 'sin fotos',
                    ].join(' · '),
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12.5,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            // Las tres salidas posibles, porque no todas las fichas repetidas
            // se resuelven igual: unas se funden, otras son un RUT mal escrito
            // que hay que corregir, y otras se cargaron mal y sobran.
            PopupMenuButton<String>(
              tooltip: 'Acciones',
              icon: const Icon(Icons.more_vert_rounded,
                  size: 20, color: AppColors.iconMuted),
              onSelected: (v) {
                if (v == 'conservar') onConservar();
                if (v == 'editar') onEditar();
                if (v == 'eliminar') onEliminar();
              },
              itemBuilder: (context) => const [
                PopupMenuItem(
                  value: 'conservar',
                  child: ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.merge_rounded, size: 19),
                    title: Text('Conservar esta y fusionar'),
                  ),
                ),
                PopupMenuItem(
                  value: 'editar',
                  child: ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.edit_outlined, size: 19),
                    title: Text('Editar'),
                  ),
                ),
                PopupMenuItem(
                  value: 'eliminar',
                  child: ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.delete_outline_rounded,
                        size: 19, color: Color(0xFFB3382B)),
                    title: Text('Eliminar solo esta',
                        style: TextStyle(color: Color(0xFFB3382B))),
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

class _Aviso extends StatelessWidget {
  const _Aviso({required this.texto});

  final String texto;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: const Color(0xFFFDECEA),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.report_problem_outlined,
              size: 17, color: Color(0xFFB3382B)),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              texto,
              style: const TextStyle(
                color: Color(0xFF8C2C22),
                fontSize: 12.5,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
