import 'package:flutter/material.dart';
import '../constants_values.dart';

class DrawerItem extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool selected;
  final VoidCallback onPressed;
  const DrawerItem(
      {super.key,
      required this.title,
      required this.icon,
      required this.selected,
      required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 30, top: 10),
      child: GestureDetector(
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.only(top: 15.0),
          child: Container(
            height: 35,
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(
                  width: 3,
                  color: selected ? primario : Colors.transparent,
                ),
              ),
            ),
            child: Row(children: <Widget>[
              const SizedBox(
                width: 15,
              ),
              Icon(
                icon,
                size: 25,
                color: secundario,
              ),
              const SizedBox(
                width: 20,
              ),
              Text(
                title,
                style: const TextStyle(fontSize: 18),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}
