// ignore_for_file: avoid_types_as_parameter_names

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' hide ModalBottomSheetRoute;
import '../../customs/constants_values.dart';
import '../../customs/navigation_drawer/navigation_drawer.dart';
import '../attendance/attendance_page.dart';
import '../contract/contract.dart';
import '../workers/workers_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late PageController _tabsPageController;
  int _selectedTab = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey();

  @override
  void initState() {
    _tabsPageController = PageController();
    super.initState();
  }

  @override
  void dispose() {
    _tabsPageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      key: _scaffoldKey,
      drawer: NavigationDrawerCustom(
        selectedTab: _selectedTab,
        tabPressed: (num) {
          _tabsPageController.jumpToPage(num);
        },
      ),
      appBar: AppBar(
        title: const Text('CONTROL DE CONTRATOS'),
        centerTitle: true,
        backgroundColor: primario,
        foregroundColor: Colors.white,
        leading: IconButton(
        icon: const Icon(CupertinoIcons.line_horizontal_3_decrease), // <-- ¡Cambie este icono!
          onPressed: () {
            // Usa el GlobalKey para abrir el Drawer
            _scaffoldKey.currentState!.openDrawer();
          },
        ),
      ),
      body: SafeArea(
        child: PageView(
          physics: const NeverScrollableScrollPhysics(),
          controller: _tabsPageController,
          onPageChanged: (num) {
            setState(() {
              _selectedTab = num;
            });
          },
          children: const [WorkersPage(), AttendancePage(), ContractPage()],
        ),
      ),
    );
  }
}
