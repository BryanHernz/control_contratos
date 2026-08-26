import 'package:animated_snack_bar/animated_snack_bar.dart';
import 'package:flutter/material.dart';

import '../../customs/app_colors.dart';
import '../../customs/widgets/app_form.dart';
import '../../customs/widgets/app_modal.dart';
import '../../customs/widgets/app_skeleton.dart';
import '../../customs/widgets/page_header.dart';
import '../../services/duplicados.dart';

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
        message: 'Se conserva "${conservada.nombreCompleto}" y se elimina la '
            'otra ficha.',
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
      await Duplicados.fusionar(
        conservada: conservada,
        descartada: descartada,
      );
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
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          const PageHeader(
            title: 'Fichas repetidas',
            subtitle: 'Trabajadores que aparecen con el mismo RUT',
            icon: Icons.copy_all_rounded,
          ),
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
                  padding: const EdgeInsets.all(20),
                  itemCount: grupos.length + 1,
                  itemBuilder: (context, i) {
                    if (i == 0) return _Resumen(grupos: grupos);
                    return _TarjetaGrupo(
                      grupo: grupos[i - 1],
                      onFusionar: _fusionar,
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
  const _TarjetaGrupo({required this.grupo, required this.onFusionar});

  final GrupoRepetido grupo;
  final Future<void> Function(
    GrupoRepetido grupo,
    FichaRepetida conservada,
    FichaRepetida descartada,
  ) onFusionar;

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
              grupo: grupo,
              onConservar: () {
                final otras =
                    grupo.fichas.where((f) => f.id != ficha.id).toList();
                // De a una: con tres fichas se fusiona dos veces, y en cada
                // paso se ve el resultado antes de seguir.
                onFusionar(grupo, ficha, otras.first);
              },
            ),
        ],
      ),
    );
  }
}

class _FilaFicha extends StatelessWidget {
  const _FilaFicha({
    required this.ficha,
    required this.grupo,
    required this.onConservar,
  });

  final FichaRepetida ficha;
  final GrupoRepetido grupo;
  final VoidCallback onConservar;

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
            TextButton.icon(
              onPressed: onConservar,
              icon: const Icon(Icons.check_rounded, size: 17),
              label: const Text('Conservar esta'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.textBody,
              ),
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
