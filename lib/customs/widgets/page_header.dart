import 'package:flutter/material.dart';

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
    return Container(
      width: double.infinity,
      height: 190,
      padding: const EdgeInsets.symmetric(horizontal: 24),
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
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
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
                const SizedBox(height: 20),
                bottomWidget!,
              ]
            ],
          ),
        ],
      ),
    );
  }
}
