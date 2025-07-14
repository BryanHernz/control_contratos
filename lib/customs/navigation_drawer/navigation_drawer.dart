
import 'package:animated_snack_bar/animated_snack_bar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'drawer_item.dart';
import 'navigation_drawer_header.dart';

class NavigationDrawerCustom extends StatelessWidget {
  final int? selectedTab;
  final Function(int)? tabPressed;
  const NavigationDrawerCustom(
      {super.key, required this.selectedTab, required this.tabPressed});

  @override
  Widget build(BuildContext context) {
    var user = FirebaseAuth.instance.currentUser;
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('Usuarios')
          .where('uid', isEqualTo: user!.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }
        return Container(
          width: 300,
          height: MediaQuery.of(context).size.height,
          decoration: const BoxDecoration(
            color: Colors.white,
            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 16)],
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  children: <Widget>[
                    const NavigationDrawerHeader(),
                    DrawerItem(
                      title: 'Trabajadores',
                      icon: Icons.work,
                      selected: selectedTab == 0 ? true : false,
                      onPressed: () {
                        Scaffold.of(context).closeDrawer();
                        tabPressed!(0);
                      },
                    ),
                    DrawerItem(
                      title: 'Contrato',
                      icon: Icons.file_copy_rounded,
                      selected: selectedTab == 1 ? true : false,
                      onPressed: () {
                        Scaffold.of(context).closeDrawer();
                        tabPressed!(1);
                      },
                    ),
                    const Divider(
                      thickness: 0.5,
                      color: Color.fromRGBO(200, 200, 200, 1),
                      indent: 20,
                      endIndent: 20,
                    ),
                    DrawerItem(
                      title: 'Editar Plantillas',
                      icon: Icons.edit_note,
                      selected: selectedTab == 2 ? true : false,
                      onPressed: () {
                        Scaffold.of(context).closeDrawer();
                        tabPressed!(2);
                      },
                    ),
                  ],
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    const SizedBox(
                      height: 70,
                    ),
                    const Divider(
                      thickness: 0.5,
                      color: Color.fromRGBO(43, 43, 43, 1),
                      indent: 50,
                      endIndent: 50,
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.max,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Row(
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(bottom: 20.0),
                              child: DrawerItem(
                                title: 'Cerrar Sesión',
                                icon: Icons.logout_rounded,
                                selected: false,
                                onPressed: () {
                                  FirebaseAuth.instance.signOut();
                                  AnimatedSnackBar.material(
                                    'Sesión finalizada con éxito',
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
                    )
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
