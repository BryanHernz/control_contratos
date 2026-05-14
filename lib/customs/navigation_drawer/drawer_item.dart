import 'package:flutter/material.dart';
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
              color: selected
                  ? Colors.white.withOpacity(0.65)
                  : Colors.transparent,
              border: selected
                  ? Border.all(color: Colors.white.withOpacity(0.9))
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
                  color: selected ? primario : Colors.black54,
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
                          fontSize: 15,
                          fontWeight:
                              selected ? FontWeight.w700 : FontWeight.w500,
                          color: selected ? primario : Colors.black87,
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
