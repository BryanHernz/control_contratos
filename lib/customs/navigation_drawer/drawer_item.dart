import 'package:flutter/material.dart';
import '../app_colors.dart';
import '../constants_values.dart';

class DrawerItem extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool selected;
  final VoidCallback onPressed;
  final bool isExpanded;

  const DrawerItem({
    super.key,
    required this.title,
    required this.icon,
    required this.selected,
    required this.onPressed,
    this.isExpanded = true,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.symmetric(horizontal: isExpanded ? 12 : 8, vertical: 3),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onPressed,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            padding: EdgeInsets.symmetric(
              horizontal: isExpanded ? 14 : 0,
              vertical: 11,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              // Tinte del primario, no blanco: la barra ya es blanca, asi que
              // un seleccionado blanco sobre blanco no marcaba nada.
              color: selected ? primario.withOpacity(0.12) : Colors.transparent,
              border: selected
                  ? Border.all(color: primario.withOpacity(0.28))
                  : null,
            ),
            child: Row(
              mainAxisAlignment: isExpanded
                  ? MainAxisAlignment.start
                  : MainAxisAlignment.center,
              children: [
                // Left indicator bar
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width: 3,
                  height: 22,
                  decoration: BoxDecoration(
                    color: selected ? primario : Colors.transparent,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                SizedBox(width: isExpanded ? 12 : 5),
                Icon(
                  icon,
                  size: 22,
                  color: selected ? primario : AppColors.iconMuted,
                ),
                ClipRect(
                  child: AnimatedAlign(
                    duration: const Duration(milliseconds: 250),
                    alignment: Alignment.centerLeft,
                    widthFactor: isExpanded ? 1.0 : 0.0,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 12),
                      child: Text(
                        title,
                        style: TextStyle(
                          // El item sin seleccionar iba en w500: con Rajdhani
                          // el menu entero se leia como texto deshabilitado.
                          fontSize: 15.5,
                          fontWeight:
                              selected ? FontWeight.w800 : FontWeight.w700,
                          color: selected ? primario : AppColors.textBody,
                        ),
                        softWrap: false,
                        overflow: TextOverflow.visible,
                      ),
                    ),
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
