// ignore_for_file: avoid_types_as_parameter_names

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' hide ModalBottomSheetRoute;
import '../../customs/constants_values.dart';
import '../../customs/navigation_drawer/navigation_drawer.dart';
import '../attendance/attendance_page.dart';
import '../contract/contract.dart';
import '../workers/workers_page.dart';

final GlobalKey<AttendancePageState> attendanceKey =
    GlobalKey<AttendancePageState>();
final GlobalKey<WorkersPageState> workerKey = GlobalKey<WorkersPageState>();

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late PageController _tabsPageController;
  int _selectedTab = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey();
  Future<DocumentSnapshot>? _userFuture;

  @override
  void initState() {
    super.initState();
    _tabsPageController = PageController();
    var user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _userFuture =
          FirebaseFirestore.instance.collection('Usuarios').doc(user.uid).get();
    }
  }

  @override
  void dispose() {
    _tabsPageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Obtenemos un ancho estable a partir del LayoutBuilder para evitar parpadeos
        bool isDesktop = constraints.maxWidth >= 800;

        var user = FirebaseAuth.instance.currentUser;
        if (user == null || _userFuture == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return FutureBuilder<DocumentSnapshot>(
          future: _userFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Scaffold(
                backgroundColor: Colors.white,
                body: Center(
                  child: CircularProgressIndicator(color: primario),
                ),
              );
            }

            return Scaffold(
              resizeToAvoidBottomInset: false,
              key: _scaffoldKey,
              drawer: isDesktop
                  ? null
                  : NavigationDrawerCustom(
                      selectedTab: _selectedTab,
                      tabPressed: (num) {
                        setState(() {
                          _selectedTab = num;
                        });
                        _tabsPageController.animateToPage(
                          num,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      },
                    ),
              appBar: AppBar(
                title: const Text('CONTROL DE CONTRATOS'),
                centerTitle: true,
                backgroundColor: primario,
                foregroundColor: Colors.white,
                leading: isDesktop
                    ? null
                    : IconButton(
                        icon: const Icon(
                            CupertinoIcons.line_horizontal_3_decrease),
                        onPressed: () {
                          _scaffoldKey.currentState!.openDrawer();
                        },
                      ),
                actions: [
                  if (_selectedTab == 0) // Mostrar en Trabajadores
                    IconButton(
                      icon: const Icon(CupertinoIcons.doc_text,
                          color: Colors.white),
                      tooltip: 'Exportar Listado (PDF)',
                      onPressed: () => workerKey.currentState?.exportToPDF(),
                    ),
                  if (_selectedTab == 1) // Mostrar solo en Asistencia
                    IconButton(
                      icon: const Icon(CupertinoIcons.doc_chart,
                          color: Colors.white),
                      tooltip: 'Exportar Reporte Mensual (PDF)',
                      onPressed: () => attendanceKey.currentState
                          ?.exportMonthlyAttendanceToPDF(),
                    ),
                  const SizedBox(width: 8.0),
                ],
              ),
              body: SafeArea(
                child: Row(
                  children: [
                    if (isDesktop)
                      NavigationDrawerCustom(
                        selectedTab: _selectedTab,
                        tabPressed: (num) {
                          setState(() {
                            _selectedTab = num;
                          });
                          _tabsPageController.animateToPage(
                            num,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.fastLinearToSlowEaseIn,
                          );
                        },
                      ),
                    Expanded(
                      child: PageView(
                        physics: const NeverScrollableScrollPhysics(),
                        controller: _tabsPageController,
                        onPageChanged: (num) {
                          // Omitimos el setState aquí para evitar reconstrucciones
                          // conflictivas durante la animación.
                        },
                        children: [
                          WorkersPage(key: workerKey),
                          AttendancePage(key: attendanceKey),
                          const ContractPage()
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
