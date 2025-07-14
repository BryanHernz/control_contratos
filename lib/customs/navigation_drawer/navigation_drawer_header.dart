
import 'package:flutter/material.dart';

import '../widgets_custom.dart';

class NavigationDrawerHeader extends StatelessWidget {
  const NavigationDrawerHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 190,
      alignment: Alignment.center,
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Padding(
            padding: EdgeInsets.only(top: 50.0),
            child: SizedBox(height: 140, width: 140, child: LogoImage()),
          ),
        ],
      ),
    );
  }
}
