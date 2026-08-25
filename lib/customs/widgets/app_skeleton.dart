import 'package:flutter/material.dart';

import '../app_colors.dart';

/// Bloque gris con brillo, del tamano de lo que va a aparecer.
///
/// Toda espera de la app era un `CircularProgressIndicator` centrado: no dice
/// cuanto viene, y al llegar los datos la pantalla salta de un circulito a un
/// listado completo. Un esqueleto con la forma real reserva el espacio, evita
/// ese salto y hace que la espera se sienta mas corta aunque dure lo mismo.
class AppSkeleton extends StatefulWidget {
  const AppSkeleton({
    super.key,
    this.width,
    required this.height,
    this.radius = 8,
  });

  final double? width;
  final double height;
  final double radius;

  @override
  State<AppSkeleton> createState() => _AppSkeletonState();
}

class _AppSkeletonState extends State<AppSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Quien pidio menos animacion no deberia ver un latido constante.
    final animar = !MediaQuery.disableAnimationsOf(context);

    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final t = animar ? _c.value : 0.5;
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: Color.lerp(
              AppColors.surfaceSunken,
              AppColors.divider,
              t,
            ),
            borderRadius: BorderRadius.circular(widget.radius),
          ),
        );
      },
    );
  }
}

/// Esqueleto de la lista de trabajadores: filas de tarjetas.
class SkeletonTarjetas extends StatelessWidget {
  const SkeletonTarjetas({
    super.key,
    this.filas = 4,
    this.porFila = 3,
    this.alto = 104,
  });

  final int filas;
  final int porFila;
  final double alto;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        // Las mismas columnas que calcula la lista de verdad, para que el
        // esqueleto no cambie de forma al llegar los datos.
        var columnas = (c.maxWidth / 400).floor();
        if (columnas < 1) columnas = 1;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var f = 0; f < filas; f++)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    for (var i = 0; i < columnas; i++) ...[
                      Expanded(
                        child: AppSkeleton(height: alto, radius: 14),
                      ),
                      if (i < columnas - 1) const SizedBox(width: 10),
                    ],
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}

/// Esqueleto de una lista de filas simples, como la de asistencia.
class SkeletonFilas extends StatelessWidget {
  const SkeletonFilas({super.key, this.filas = 8});

  final int filas;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < filas; i++)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
            child: Row(
              children: [
                const AppSkeleton(width: 28, height: 28, radius: 8),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Ancho variable para que no parezca una grilla:
                      // los nombres reales tampoco miden todos igual.
                      AppSkeleton(
                        width: 140.0 + (i % 4) * 40,
                        height: 12,
                        radius: 4,
                      ),
                      const SizedBox(height: 7),
                      AppSkeleton(
                        width: 90.0 + (i % 3) * 20,
                        height: 10,
                        radius: 4,
                      ),
                    ],
                  ),
                ),
                const AppSkeleton(width: 20, height: 20, radius: 6),
              ],
            ),
          ),
      ],
    );
  }
}

/// Esqueleto de las tarjetas de metrica del dashboard.
class SkeletonMetricas extends StatelessWidget {
  const SkeletonMetricas({super.key, this.cantidad = 4});

  final int cantidad;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        for (var i = 0; i < cantidad; i++)
          const SizedBox(
              width: 240, child: AppSkeleton(height: 120, radius: 16)),
      ],
    );
  }
}
