import 'package:flutter/material.dart';

import '../app_colors.dart';
import '../constants_values.dart';
import '../widgets_custom.dart';
import 'app_modal.dart';

/// Piezas comunes de los formularios que viven dentro de un modal.
///
/// Cada formulario venia resolviendo lo mismo por su cuenta y con resultados
/// distintos: los titulos de seccion como `Text` suelto, las opciones como
/// `SwitchListTile`/`CheckboxListTile` pelados -- que traen su propio padding,
/// su propio color y alinean el control a un lado distinto en cada uso -- y el
/// par cancelar/guardar copiado en cada pantalla. Esto los deja en un solo
/// idioma y, sobre todo, hace que arreglar uno los arregle a todos.

/// Bloque de formulario: una tarjeta con su titulo, sobre el fondo hundido del
/// modal. Mismo tratamiento que las tarjetas del detalle de trabajador.
class AppFormSection extends StatelessWidget {
  const AppFormSection({
    super.key,
    required this.title,
    required this.icon,
    required this.child,
    this.expandido = false,
  });

  final String title;
  final IconData icon;
  final Widget child;

  /// `true` cuando la tarjeta debe ocupar todo el alto que le den.
  ///
  /// Por defecto la Column mide lo minimo, y eso deja al hijo con altura sin
  /// limite: si el hijo trae un `Expanded`, no tiene nada que repartir y la
  /// maquetacion se rompe -- la pantalla queda en blanco. Con esto la tarjeta
  /// pasa a llenar el alto y es ella quien reparte, asi el hijo no necesita su
  /// propio `Expanded`.
  ///
  /// Solo tiene sentido bajo un padre de alto acotado.
  final bool expandido;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: appCardDecoration(radius: 14),
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: expandido ? MainAxisSize.max : MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(icon, size: 17, color: AppColors.iconMuted),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title.toUpperCase(),
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (expandido) Expanded(child: child) else child,
        ],
      ),
    );
  }
}

/// Fila de opcion con casilla de verificacion.
class AppCheckRow extends StatelessWidget {
  const AppCheckRow({
    super.key,
    required this.title,
    required this.value,
    required this.onChanged,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return _OptionRow(
      title: title,
      subtitle: subtitle,
      value: value,
      onChanged: onChanged,
      leading: SizedBox(
        width: 22,
        height: 22,
        child: Checkbox(
          value: value,
          onChanged: (v) => onChanged(v ?? false),
          activeColor: primario,
          side: const BorderSide(color: AppColors.border, width: 1.6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
          ),
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.compact,
        ),
      ),
    );
  }
}

/// Fila de opcion con interruptor.
///
/// Los colores van explicitos: con el `Switch` por defecto de Material 3 el
/// estado apagado quedaba como pastilla oscura con pulgar claro y el encendido
/// como pastilla gris -- se leian al reves de lo que estaban.
class AppSwitchRow extends StatelessWidget {
  const AppSwitchRow({
    super.key,
    required this.title,
    required this.value,
    required this.onChanged,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return _OptionRow(
      title: title,
      subtitle: subtitle,
      value: value,
      onChanged: onChanged,
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? Colors.white
              : AppColors.iconMuted,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.selected) ? primario : Colors.white,
        ),
        trackOutlineColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? primario
              : AppColors.border,
        ),
      ),
    );
  }
}

class _OptionRow extends StatelessWidget {
  const _OptionRow({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    this.leading,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final Widget? leading;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => onChanged(!value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: value ? primario.withOpacity(0.07) : AppColors.surfaceSunken,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            if (leading != null) ...[
              leading!,
              const SizedBox(width: 14),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.textStrong,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (subtitle != null && subtitle!.trim().isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        subtitle!,
                        style: const TextStyle(
                          color: AppColors.textFaint,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 14),
              trailing!,
            ],
          ],
        ),
      ),
    );
  }
}

/// Estado vacio: no hay nada que mostrar todavia y conviene decir por que.
///
/// Los estados vacios eran una linea de texto gris centrada en medio de una
/// tarjeta enorme: no se distinguia "aun no hay datos" de "algo fallo".
class AppEmptyNotice extends StatelessWidget {
  const AppEmptyNotice({
    super.key,
    required this.icon,
    required this.message,
    this.detail,
    this.decorated = true,
    this.actionLabel,
    this.actionIcon,
    this.onAction,
  });

  final IconData icon;
  final String message;
  final String? detail;

  /// Salida directa desde el estado vacio. Sin esto, [detail] describe que hay
  /// que hacer pero deja al usuario buscando donde hacerlo.
  final String? actionLabel;
  final IconData? actionIcon;
  final VoidCallback? onAction;

  /// `false` cuando ya va dentro de una tarjeta: sin esto quedaba tarjeta
  /// dentro de tarjeta.
  final bool decorated;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
      decoration: decorated ? appCardDecoration(radius: 14) : null,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 52,
            height: 52,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.surfaceSunken,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, size: 26, color: AppColors.iconMuted),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textStrong,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (detail != null && detail!.trim().isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                detail!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          if (onAction != null && actionLabel != null)
            Padding(
              padding: const EdgeInsets.only(top: 20),
              child: CustomButton(
                funcion: onAction!,
                texto: actionLabel!,
                icon: actionIcon,
                width: 260,
              ),
            ),
        ],
      ),
    );
  }
}

/// Cuerpo de un modal de confirmacion destructiva: aviso rojo y el par
/// cancelar / accion roja.
///
/// Habia cuatro copias de esto -- quitar de asistencia, borrar tipo de lista,
/// borrar ficha de usuario y borrar elemento de una categoria -- y ya diferian
/// entre si en padding y en el radio del boton rojo.
///
/// Va con `danger: true` en [showAppModal], que es quien pinta la cabecera.
class AppDangerConfirmBody extends StatelessWidget {
  const AppDangerConfirmBody({
    super.key,
    required this.message,
    required this.onCancel,
    required this.onConfirm,
    required this.confirmText,
    required this.confirmIcon,
    this.detail,
  });

  final String message;

  /// Matiz bajo el aviso: que NO se pierde, hasta donde llega el borrado.
  final String? detail;
  final VoidCallback onCancel;
  final VoidCallback onConfirm;
  final String confirmText;
  final IconData confirmIcon;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppModalBody(
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        message,
                        style: TextStyle(
                          color: Colors.red.shade700,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      if (detail != null && detail!.trim().isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            detail!,
                            style: TextStyle(
                              color: Colors.red.shade600,
                              fontWeight: FontWeight.w500,
                              fontSize: 12.5,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Row(
            children: [
              Expanded(
                child: CustomButton(
                  funcion: onCancel,
                  texto: 'Cancelar',
                  cancelar: true,
                  icon: Icons.close_rounded,
                  width: double.infinity,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 52,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade600,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      // Mismo radio que CustomButton, que es su vecino.
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    onPressed: onConfirm,
                    icon: Icon(confirmIcon, size: 18),
                    label: Text(confirmText),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Pie fijo del formulario: cancelar + accion principal.
///
/// Va fuera del scroll para que los botones no se vayan de pantalla cuando el
/// formulario crece.
class AppFormFooter extends StatelessWidget {
  const AppFormFooter({
    super.key,
    required this.onCancel,
    required this.onConfirm,
    required this.confirmText,
    required this.confirmIcon,
    this.cancelText = 'Cancelar',
  });

  final VoidCallback onCancel;
  final VoidCallback onConfirm;
  final String confirmText;
  final IconData confirmIcon;
  final String cancelText;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Row(
        children: [
          Expanded(
            child: CustomButton(
              funcion: onCancel,
              texto: cancelText,
              cancelar: true,
              icon: Icons.close_rounded,
              width: double.infinity,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: CustomButton(
              funcion: onConfirm,
              texto: confirmText,
              cancelar: false,
              icon: confirmIcon,
              width: double.infinity,
            ),
          ),
        ],
      ),
    );
  }
}
