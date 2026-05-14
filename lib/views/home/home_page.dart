// ignore_for_file: avoid_types_as_parameter_names

import 'package:animated_snack_bar/animated_snack_bar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' hide ModalBottomSheetRoute;
import 'package:shared_preferences/shared_preferences.dart';

import '../../customs/constants_values.dart';
import '../../customs/navigation_drawer/navigation_drawer.dart';
import '../../utils/user_access.dart';
import '../attendance/attendance_page.dart';
import '../contract/contract.dart';
import '../users/users_page.dart';
import '../workers/workers_page.dart';
import 'dashboard_page.dart';

final GlobalKey<AttendancePageState> attendanceKey =
    GlobalKey<AttendancePageState>();
final GlobalKey<WorkersPageState> workerKey = GlobalKey<WorkersPageState>();

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedTab = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey();
  final PageController _tabsPageController = PageController();
  late final Stream<DocumentSnapshot> _userStream;
  bool _isDrawerExpanded = true;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    _userStream = user == null
        ? const Stream.empty()
        : FirebaseFirestore.instance
            .collection('Usuarios')
            .doc(user.uid)
            .snapshots();
    _loadDrawerState();
  }

  Future<void> _loadDrawerState() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _isDrawerExpanded = prefs.getBool('drawer_expanded') ?? true;
    });
  }

  Future<void> _toggleDrawer() async {
    setState(() {
      _isDrawerExpanded = !_isDrawerExpanded;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('drawer_expanded', _isDrawerExpanded);
  }

  bool _canOpenTab(int tab, UserAccess access) {
    switch (tab) {
      case 0:
        return access.canView(UserViewKeys.dashboard);
      case 1:
        return access.canView(UserViewKeys.workers);
      case 2:
        return access.canView(UserViewKeys.attendance);
      case 3:
        return access.canView(UserViewKeys.users);
      case 4:
        return access.canView(UserViewKeys.settings);
      default:
        return false;
    }
  }

  int _firstAllowedTab(UserAccess access) {
    for (final tab in [0, 1, 2, 3, 4]) {
      if (_canOpenTab(tab, access)) return tab;
    }
    return 0;
  }

  void _openTab(
    int tab, {
    required UserAccess access,
    required BuildContext context,
  }) {
    if (!_canOpenTab(tab, access)) {
      AnimatedSnackBar.material(
        'No tienes acceso a esta vista.',
        type: AnimatedSnackBarType.warning,
      ).show(context);
      return;
    }

    if (_selectedTab == tab) return;

    setState(() => _selectedTab = tab);
    _syncPageToSelected(animate: true);
  }

  void _syncPageToSelected({bool animate = false}) {
    final targetTab = _selectedTab;

    if (!_tabsPageController.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_tabsPageController.hasClients) return;
        _tabsPageController.jumpToPage(targetTab);
      });
      return;
    }

    final currentPage =
        (_tabsPageController.page ?? _tabsPageController.initialPage.toDouble())
            .round();
    if (currentPage == targetTab) return;

    if (animate) {
      _tabsPageController.animateToPage(
        targetTab,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
      );
    } else {
      _tabsPageController.jumpToPage(targetTab);
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
        final isDesktop = constraints.maxWidth >= 800;
        final user = FirebaseAuth.instance.currentUser;

        if (user == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return StreamBuilder<DocumentSnapshot>(
          stream: _userStream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting &&
                !snapshot.hasData) {
              return Scaffold(
                backgroundColor: Colors.white,
                body: Center(
                  child: CircularProgressIndicator(color: primario),
                ),
              );
            }

            final userData = snapshot.data?.data() as Map<String, dynamic>?;
            final access = UserAccess.fromUserData(userData);

            if (!access.active) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                FirebaseAuth.instance.signOut();
              });
              return Scaffold(
                backgroundColor: Colors.white,
                body: Center(
                  child: CircularProgressIndicator(color: primario),
                ),
              );
            }

            final hasAnyView = access.canView(UserViewKeys.dashboard) ||
                access.canView(UserViewKeys.workers) ||
                access.canView(UserViewKeys.attendance) ||
                access.canView(UserViewKeys.users) ||
                access.canView(UserViewKeys.settings);

            if (!hasAnyView) {
              return Scaffold(
                backgroundColor: Colors.white,
                body: Center(
                  child: Text(
                    'Tu usuario no tiene vistas asignadas.',
                    style: TextStyle(
                      color: Colors.blueGrey.shade700,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              );
            }

            final safeSelectedTab = _canOpenTab(_selectedTab, access)
                ? _selectedTab
                : _firstAllowedTab(access);

            if (safeSelectedTab != _selectedTab) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) return;
                setState(() => _selectedTab = safeSelectedTab);
                _syncPageToSelected();
              });
            }

            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              _syncPageToSelected();
            });

            final pages = <Widget>[
              const DashboardPage(),
              WorkersPage(key: workerKey),
              AttendancePage(key: attendanceKey),
              UsersPage(
                canManageUsers: access.canAction(UserActionKeys.manageUsers),
              ),
              const ContractPage(),
            ];

            return Scaffold(
              resizeToAvoidBottomInset: false,
              key: _scaffoldKey,
              drawer: isDesktop
                  ? null
                  : NavigationDrawerCustom(
                      selectedTab: safeSelectedTab,
                      showDashboard: access.canView(UserViewKeys.dashboard),
                      showWorkers: access.canView(UserViewKeys.workers),
                      showAttendance: access.canView(UserViewKeys.attendance),
                      showUsers: access.canView(UserViewKeys.users),
                      showSettings: access.canView(UserViewKeys.settings),
                      tabPressed: (tab) => _openTab(
                        tab,
                        access: access,
                        context: context,
                      ),
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
                          CupertinoIcons.line_horizontal_3_decrease,
                        ),
                        onPressed: () {
                          _scaffoldKey.currentState!.openDrawer();
                        },
                      ),
                actions: [
                  if (safeSelectedTab == 1)
                    IconButton(
                      icon: const Icon(CupertinoIcons.doc_text,
                          color: Colors.white),
                      tooltip: 'Exportar Listado (PDF)',
                      onPressed: () => workerKey.currentState?.exportToPDF(),
                    ),
                  if (safeSelectedTab == 2)
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
                child: Stack(
                  children: [
                    Row(
                      children: [
                        if (isDesktop)
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            width: _isDrawerExpanded ? 240 : 80,
                          ),
                        Expanded(
                          child: PageView(
                            controller: _tabsPageController,
                            physics: const NeverScrollableScrollPhysics(),
                            onPageChanged: (tab) {
                              if (tab == _selectedTab) return;
                              setState(() => _selectedTab = tab);
                            },
                            children: pages,
                          ),
                        ),
                      ],
                    ),
                    if (isDesktop)
                      NavigationDrawerCustom(
                        selectedTab: safeSelectedTab,
                        isExpanded: _isDrawerExpanded,
                        onToggle: _toggleDrawer,
                        showDashboard: access.canView(UserViewKeys.dashboard),
                        showWorkers: access.canView(UserViewKeys.workers),
                        showAttendance: access.canView(UserViewKeys.attendance),
                        showUsers: access.canView(UserViewKeys.users),
                        showSettings: access.canView(UserViewKeys.settings),
                        tabPressed: (tab) => _openTab(
                          tab,
                          access: access,
                          context: context,
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
