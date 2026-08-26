import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../customs/app_colors.dart';
import '../../customs/widgets/app_form.dart';
import '../../customs/widgets/app_skeleton.dart';
import '../../services/auditoria.dart';
import '../../services/firestore_db.dart';

/// Lo que le ha pasado a una ficha: documentos emitidos y cambios.
///
/// Sale de `Auditoria`, filtrada por el id del trabajador. Para las fichas
/// creadas antes de que esto existiera va a estar vacia y eso es correcto: no
/// se inventa un historial que nadie registro.
class HistorialTrabajador extends StatelessWidget {
  const HistorialTrabajador({
    super.key,
    required this.trabajadorId,
    this.ultimoContrato,
    this.fechaFiniquito,
  });

  final String trabajadorId;

  /// Fechas que la ficha guarda por su cuenta, para los documentos emitidos
  /// antes de que la auditoria dejara registro.
  final DateTime? ultimoContrato;
  final DateTime? fechaFiniquito;

  /// Como se lee cada accion, y con que icono.
  static const _titulos = <String, (String, IconData)>{
    Auditoria.crearTrabajador: ('Ficha creada', Icons.person_add_alt_1_rounded),
    Auditoria.editarTrabajador: ('Ficha editada', Icons.edit_outlined),
    Auditoria.generarContrato: ('Contrato emitido', Icons.description_outlined),
    Auditoria.generarFiniquito: (
      'Finiquito emitido',
      Icons.assignment_turned_in_outlined
    ),
  };

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      // `limit` porque una ficha con anos de uso puede acumular mucho, y esto
      // vive dentro de una hoja que no esta hecha para recorrer cien filas.
      stream: db
          .collection('Auditoria')
          .where('entidadId', isEqualTo: trabajadorId)
          .orderBy('timestamp', descending: true)
          .limit(40)
          .snapshots(),
      builder: (context, snap) {
        if (snap.hasError) {
          return AppEmptyNotice(
            icon: Icons.error_outline_rounded,
            message: 'No se pudo cargar el historial',
            // El caso tipico es que falte el indice compuesto; el mensaje de
            // Firestore trae el enlace para crearlo.
            detail: '${snap.error}',
          );
        }
        if (!snap.hasData) return const SkeletonFilas(filas: 3);

        final docs = snap.data!.docs;

        // Los documentos emitidos ANTES de que la auditoria funcionara no
        // dejaron registro, pero la ficha si guarda cuando fue el ultimo:
        // seis trabajadores tienen contrato de marzo y ninguna anotacion. Se
        // muestran desde la ficha, y solo si no hay ya un registro de esa
        // accion que dijera lo mismo.
        final acciones = docs.map((d) => d.data()['accion']).toSet();
        final desdeLaFicha = <Map<String, dynamic>>[
          if (ultimoContrato != null &&
              !acciones.contains(Auditoria.generarContrato))
            {
              'accion': Auditoria.generarContrato,
              'timestamp': Timestamp.fromDate(ultimoContrato!),
              'usuario': '',
            },
          if (fechaFiniquito != null &&
              !acciones.contains(Auditoria.generarFiniquito))
            {
              'accion': Auditoria.generarFiniquito,
              'timestamp': Timestamp.fromDate(fechaFiniquito!),
              'usuario': '',
            },
        ];

        final filas = <Map<String, dynamic>>[
          ...docs.map((d) => d.data()),
          ...desdeLaFicha,
        ]..sort((a, b) {
            final ta = a['timestamp'];
            final tb = b['timestamp'];
            if (ta is! Timestamp) return -1;
            if (tb is! Timestamp) return 1;
            return tb.compareTo(ta);
          });

        if (filas.isEmpty) {
          return const AppEmptyNotice(
            icon: Icons.history_rounded,
            message: 'Sin movimientos registrados',
            detail: 'Aqui van a aparecer los documentos que se emitan y los '
                'cambios que se hagan en la ficha.',
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final fila in filas) _Fila(datos: fila),
          ],
        );
      },
    );
  }
}

class _Fila extends StatelessWidget {
  const _Fila({required this.datos});

  final Map<String, dynamic> datos;

  @override
  Widget build(BuildContext context) {
    final accion = (datos['accion'] ?? '').toString();
    final (titulo, icono) = HistorialTrabajador._titulos[accion] ??
        (accion.replaceAll('_', ' ').toLowerCase(), Icons.circle_outlined);

    final marca = datos['timestamp'];
    final cuando = marca is Timestamp
        ? DateFormat("d 'de' MMMM 'de' y, HH:mm", 'es').format(marca.toDate())
        // Firestore resuelve `serverTimestamp` despues de confirmar la
        // escritura: entremedio llega null, y decir "hace un momento" es mas
        // honesto que dejar el hueco.
        : 'hace un momento';

    final quien = (datos['usuario'] ?? '').toString();
    final campos = (datos['campos'] as List?)?.cast<String>() ?? const [];
    final version = (datos['plantillaVersion'] ?? '').toString();

    final detalle = <String>[
      if (campos.isNotEmpty) 'Cambio: ${campos.join(', ')}',
      // Con que version de plantilla se emitio: es lo que permite reimprimir
      // un documento tal como se firmo, aunque la plantilla haya cambiado.
      if (version.isNotEmpty) 'Plantilla $version',
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: AppColors.surfaceSunken,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icono, size: 16, color: AppColors.iconMuted),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13.5,
                    color: AppColors.textStrong,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  [cuando, if (quien.isNotEmpty) quien, ...detalle].join(' · '),
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
