
import 'package:flutter/material.dart';

import '../../customs/navigation_drawer/navigation_drawer.dart';
import '../contract/contract.dart';
import '../workers/workers_page.dart';
import '../templates/template_editor_page.dart'; // Importar la nueva página

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedTab = 0;

  final List<Widget> _children = [
    const WorkersPage(),
    const ContractPage(),
    const TemplateEditorPage(), // Añadir la nueva página a la lista
  ];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        drawer: NavigationDrawerCustom(
          selectedTab: _selectedTab,
          tabPressed: (index) {
            setState(() {
              _selectedTab = index;
            });
          },
        ),
        body: _children[_selectedTab]);
  }
}
