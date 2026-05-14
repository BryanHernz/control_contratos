import 'dart:ui';

import 'package:animated_snack_bar/animated_snack_bar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'drawer_item.dart';
import 'navigation_drawer_header.dart';

class NavigationDrawerCustom extends StatelessWidget {
  final int? selectedTab;
  final Function(int)? tabPressed;
  final bool isExpanded;
  final VoidCallback? onToggle;
  final bool showDashboard;
  final bool showWorkers;
  final bool showAttendance;
  final bool showUsers;
  final bool showSettings;

  const NavigationDrawerCustom({
    super.key,
    required this.selectedTab,
    required this.tabPressed,
    this.isExpanded = true,
    this.onToggle,
    this.showDashboard = true,
    this.showWorkers = true,
    this.showAttendance = true,
    this.showUsers = true,
    this.showSettings = true,
  });

  @override
  Widget build(BuildContext context) {
    void openTab(int tab) {
      final scaffold = Scaffold.maybeOf(context);
      if (scaffold != null && scaffold.isDrawerOpen) {
        scaffold.closeDrawer();
      }
      tabPressed?.call(tab);
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: isExpanded ? 240 : 80,
      height: MediaQuery.of(context).size.height,
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white.withOpacity(0.78),
                  Colors.white.withOpacity(0.60),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border(
                right: BorderSide(color: Colors.white.withOpacity(0.92)),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.blueGrey.shade900.withOpacity(0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    children: <Widget>[
                      NavigationDrawerHeader(
                        isExpanded: isExpanded,
                        onToggle: onToggle,
                      ),
                      const SizedBox(height: 20),
                      if (showDashboard)
                        DrawerItem(
                          title: 'Dashboard',
                          icon: CupertinoIcons.chart_bar_square,
                          selected: selectedTab == 0,
                          isExpanded: isExpanded,
                          onPressed: () => openTab(0),
                        ),
                      if (showWorkers)
                        DrawerItem(
                          title: 'Trabajadores',
                          icon: CupertinoIcons.briefcase,
                          selected: selectedTab == 1,
                          isExpanded: isExpanded,
                          onPressed: () => openTab(1),
                        ),
                      if (showAttendance)
                        DrawerItem(
                          title: 'Asistencia',
                          icon: CupertinoIcons.calendar_today,
                          selected: selectedTab == 2,
                          isExpanded: isExpanded,
                          onPressed: () => openTab(2),
                        ),
                      if (showUsers)
                        DrawerItem(
                          title: 'Usuarios',
                          icon: CupertinoIcons.person_2,
                          selected: selectedTab == 3,
                          isExpanded: isExpanded,
                          onPressed: () => openTab(3),
                        ),
                      if (showSettings)
                        DrawerItem(
                          title: 'Ajustes',
                          icon: CupertinoIcons.settings,
                          selected: selectedTab == 4,
                          isExpanded: isExpanded,
                          onPressed: () => openTab(4),
                        ),
                    ],
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      const SizedBox(height: 70),
                      Divider(
                        thickness: 0.5,
                        color: Colors.blueGrey.shade300.withOpacity(0.6),
                        indent: 50,
                        endIndent: 50,
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 20.0),
                        child: DrawerItem(
                          title: 'Cerrar Sesion',
                          icon: Icons.logout_rounded,
                          selected: false,
                          isExpanded: isExpanded,
                          onPressed: () {
                            FirebaseAuth.instance.signOut();
                            AnimatedSnackBar.material(
                              'Sesion finalizada con exito',
                              mobileSnackBarPosition:
                                  MobileSnackBarPosition.top,
                              desktopSnackBarPosition:
                                  DesktopSnackBarPosition.bottomRight,
                              type: AnimatedSnackBarType.success,
                            ).show(context);
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
