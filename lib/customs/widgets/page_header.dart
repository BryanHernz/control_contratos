import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'menu_lateral.dart';

class PageHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Widget? bottomWidget;
  final Widget? rightWidget;

  const PageHeader({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.bottomWidget,
    this.rightWidget,
  });

  @override
  Widget build(BuildContext context) {
    // En el telefono la cabecera se compacta y absorbe el boton del menu.
    // Antes convivia con un `AppBar` que decia "CONTROL DE CONTRATOS": dos
    // barras oscuras apiladas que se comian un tercio de la pantalla para
    // decir dos veces donde estabas.
    final compacta = MediaQuery.sizeOf(context).width < 800;

    return Container(
      width: double.infinity,
      height: compacta ? (bottomWidget != null ? 168 : 128) : 190,
      padding: EdgeInsets.symmetric(horizontal: compacta ? 16 : 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.blueGrey.shade900,
            Colors.blueGrey.shade700,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        // Sin sombra ni borde inferior: el header ya se separa del cuerpo por
        // ser oscuro. La sombra que habia (blur 20, desplazada 8px) caia sobre
        // el fondo azul-gris y dejaba una franja celeste bajo el header.
      ),
      child: Stack(
        children: [
          // Ghost decoration icon
          Positioned(
            right: -10,
            top: 20,
            child: Icon(
              icon,
              size: 110,
              color: Colors.white.withOpacity(0.05),
            ),
          ),
          // Content
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (compacta && MenuLateral.disponible) ...[
                    IconButton(
                      icon: const Icon(
                        CupertinoIcons.line_horizontal_3_decrease,
                        color: Colors.white,
                      ),
                      tooltip: 'Menu',
                      onPressed: MenuLateral.abrir,
                      padding: EdgeInsets.zero,
                      constraints:
                          const BoxConstraints(minWidth: 40, minHeight: 40),
                    ),
                    const SizedBox(width: 6),
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icon, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 14),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: compacta ? 18 : 20,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.3,
                          ),
                        ),
                        Text(
                          subtitle,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.5),
                            fontSize: 11,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (rightWidget != null) rightWidget!,
                ],
              ),
              if (bottomWidget != null) ...[
                SizedBox(height: compacta ? 14 : 20),
                bottomWidget!,
              ]
            ],
          ),
        ],
      ),
    );
  }
}
