import 'package:flutter/material.dart';

import '../app_colors.dart';

/// Sobre este ancho el modal se muestra centrado; bajo el, como hoja inferior.
const double kModalWideBreakpoint = 900;

/// Ancho maximo del modal centrado.
const double kModalMaxWidth = 920;

const double _kRadius = 24;

/// Abre un modal adaptativo.
///
/// En pantalla ancha se muestra como dialogo centrado (util para formularios de
/// varias columnas). En pantalla angosta cae a hoja inferior, que aprovecha
/// mejor el alto util del telefono.
///
/// Sustituye a los `showModalBottomSheet` sueltos que habia repetidos en cada
/// vista. Dos cosas que resuelve y que conviene no volver a romper:
///
///  1. **El borde blanco.** El header va SIN `borderRadius`: quien redondea es
///     el `ClipRRect` del contenedor, con `Clip.antiAlias`. Si el header vuelve
///     a traer su propio radio, quedan dos curvas antialiaseadas superpuestas y
///     el blanco de abajo se filtra por el arco. Medido: el pixel mas claro de
///     la esquina pasa de luminancia 107 a 152.
///  2. **El blanco no se pinta detras del header.** La superficie blanca vive
///     solo en el cuerpo, no envolviendo toda la columna, para que bajo la
///     curva superior no haya nada claro que pueda asomar.
Future<T?> showAppModal<T>({
  required BuildContext context,
  required Widget child,
  String? title,
  IconData? icon,
  String? subtitle,
  String? badge,
  String? hint,
  bool danger = false,
  bool dismissible = true,
  double maxWidth = kModalMaxWidth,

  /// Cabecera propia, para los modales que ya traen una mas rica que la
  /// estandar. Debe ir SIN `borderRadius`: redondea el clip del shell.
  Widget? header,
}) {
  // Tres modos:
  //  - `title` + `icon`  -> cabecera estandar y cuerpo blanco.
  //  - `header`          -> cabecera propia y cuerpo blanco.
  //  - ninguno de los dos -> el hijo trae cabecera y superficie propias; el
  //    shell solo recorta y acota. Es el caso del detalle de trabajador, que
  //    ya arma [cabecera oscura + cuerpo blanco] por su cuenta.
  assert(
    icon == null || title != null,
    'showAppModal: `icon` sin `title` no arma cabecera.',
  );

  final size = MediaQuery.sizeOf(context);
  final wide = size.width >= kModalWideBreakpoint;

  Widget shell(BuildContext ctx) => _AppModalShell(
        title: title,
        icon: icon,
        subtitle: subtitle,
        badge: badge,
        hint: hint,
        danger: danger,
        wide: wide,
        maxWidth: maxWidth,
        maxHeight: size.height * (wide ? 0.90 : 0.92),
        header: header,
        child: child,
      );

  if (wide) {
    return showDialog<T>(
      context: context,
      barrierDismissible: dismissible,
      builder: (ctx) => Padding(
        // Deja aire aunque el teclado este arriba.
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(ctx).bottom,
        ),
        child: Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: shell(ctx),
        ),
      ),
    );
  }

  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    isDismissible: dismissible,
    enableDrag: dismissible,
    // Transparente a proposito: la superficie la pinta el shell, para que el
    // Material de la hoja no deje un rectangulo claro bajo las esquinas.
    backgroundColor: Colors.transparent,
    builder: (ctx) => AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
      child: SafeArea(top: false, child: shell(ctx)),
    ),
  );
}

class _AppModalShell extends StatelessWidget {
  const _AppModalShell({
    required this.title,
    required this.icon,
    required this.subtitle,
    required this.badge,
    required this.hint,
    required this.danger,
    required this.wide,
    required this.maxWidth,
    required this.maxHeight,
    required this.header,
    required this.child,
  });

  final String? title;
  final IconData? icon;
  final String? subtitle;
  final String? badge;
  final String? hint;
  final bool danger;
  final bool wide;
  final double maxWidth;
  final double maxHeight;
  final Widget? header;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    // Centrado: las cuatro esquinas. Hoja: solo las de arriba.
    final radius = wide
        ? BorderRadius.circular(_kRadius)
        : const BorderRadius.vertical(top: Radius.circular(_kRadius));

    final chrome = header ??
        (title != null
            ? AppModalHeader(
                title: title!,
                icon: icon!,
                subtitle: subtitle,
                badge: badge,
                danger: danger,
                showGrabber: !wide,
                onClose: wide ? () => Navigator.of(context).maybePop() : null,
              )
            : null);

    // Cuando el hijo trae su propia cabecera y superficie, el shell no pinta
    // blanco: si lo hiciera, ese blanco quedaria bajo la curva superior y
    // volveria a asomar por el borde.
    final Widget content = chrome == null
        ? Material(color: Colors.transparent, child: child)
        : Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              chrome,
              Flexible(
                child: Material(
                  // Hace de pagina: las tarjetas de adentro van en `surface`.
                  color: AppColors.surfaceSunken,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (hint != null && hint!.trim().isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                          child: AppModalHint(text: hint!),
                        ),
                      Flexible(child: child),
                    ],
                  ),
                ),
              ),
            ],
          );

    // Sin `Align` envolvente a proposito: un Align toma todo el espacio
    // disponible, el modal deja de medir lo que mide su contenido y la capa
    // transparente resultante se come los toques destinados al barrier -- el
    // sintoma es un modal que no cierra al tocar fuera. Quien centra ya es el
    // Dialog; quien ancla abajo ya es showModalBottomSheet.
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth, maxHeight: maxHeight),
      child: ClipRRect(
        borderRadius: radius,
        clipBehavior: Clip.antiAlias,
        child: content,
      ),
    );
  }
}

/// Cabecera con gradiente de los modales.
///
/// No lleva `borderRadius` a proposito: ver la nota en [showAppModal].
class AppModalHeader extends StatelessWidget {
  const AppModalHeader({
    super.key,
    required this.title,
    required this.icon,
    this.subtitle,
    this.badge,
    this.danger = false,
    this.showGrabber = true,
    this.onClose,
  });

  final String title;
  final IconData icon;
  final String? subtitle;
  final String? badge;
  final bool danger;
  final bool showGrabber;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final colors = danger
        ? [const Color(0xFF8D2A20), const Color(0xFFB3382B)]
        : [Colors.blueGrey.shade900, Colors.blueGrey.shade700];

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -18,
            top: 10,
            child: Icon(icon, size: 92, color: Colors.white.withOpacity(0.06)),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(24, showGrabber ? 16 : 24, 24, 26),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (showGrabber) ...[
                  Center(
                    child: Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.28),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      // Sin borde, como el chip: el contorno blanco translucido
                      // sobre el gradiente no aportaba y ensuciaba la cabecera.
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(icon, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              color: AppColors.onDarkStrong,
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (subtitle != null && subtitle!.trim().isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                subtitle!,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: AppColors.onDarkMuted,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (badge != null && badge!.trim().isNotEmpty) ...[
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        // Mismo tratamiento que el chip de estado del detalle
                        // de trabajador: esquinas apenas suavizadas y sin
                        // borde.
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          badge!,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.85),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                    if (onClose != null) ...[
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: onClose,
                        icon: const Icon(Icons.close_rounded),
                        color: Colors.white,
                        tooltip: 'Cerrar',
                        splashRadius: 22,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Aviso informativo dentro de un modal.
class AppModalHint extends StatelessWidget {
  const AppModalHint({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F7FA),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.textMuted,
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Cuerpo scrolleable para el contenido de un modal.
///
/// En hoja inferior el scroll interno pelea con el gesto de arrastrar para
/// cerrar; esto lo deja en un solo scrollable con rebote controlado.
class AppModalBody extends StatelessWidget {
  const AppModalBody({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(24),
  });

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: padding,
      primary: false,
      child: child,
    );
  }
}

/// Distribuye campos en columnas segun el ancho disponible del modal.
///
/// En el modal centrado hay sitio para 2-3 columnas; en la hoja del telefono
/// cae a una sola. Evita el scroll larguisimo que quedaba antes.
class AppModalFieldGrid extends StatelessWidget {
  const AppModalFieldGrid({
    super.key,
    required this.children,
    this.minItemWidth = 320,
    this.maxColumns = 3,
    this.spacing = 16,
    this.runSpacing = 16,
  });

  final List<Widget> children;
  final double minItemWidth;
  final int maxColumns;
  final double spacing;
  final double runSpacing;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final available = constraints.maxWidth;
        var columns =
            ((available + spacing) / (minItemWidth + spacing)).floor();
        columns = columns.clamp(1, maxColumns);
        final itemWidth = (available - spacing * (columns - 1)) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: runSpacing,
          children: [
            for (final child in children)
              SizedBox(width: itemWidth, child: child),
          ],
        );
      },
    );
  }
}
