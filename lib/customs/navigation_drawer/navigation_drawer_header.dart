import 'package:flutter/material.dart';

class NavigationDrawerHeader extends StatelessWidget {
  final bool isExpanded;
  final VoidCallback? onToggle;

  const NavigationDrawerHeader({
    super.key,
    this.isExpanded = true,
    this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = MediaQuery.of(context).size.width >= 800;
    final double logoSize = isExpanded ? 62 : 34;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: double.infinity,
      height: isDesktop ? (isExpanded ? 190 : 150) : null,
      padding: EdgeInsets.symmetric(horizontal: isExpanded ? 16 : 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.blueGrey.shade900,
            Colors.blueGrey.shade700,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (onToggle != null && isDesktop)
            Align(
              alignment: isExpanded ? Alignment.centerRight : Alignment.center,
              child: Padding(
                padding: EdgeInsets.only(right: isExpanded ? 8 : 0, top: 4),
                child: IconButton(
                  icon: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: Icon(
                      isExpanded ? Icons.menu_open_rounded : Icons.menu_rounded,
                      key: ValueKey(isExpanded),
                      color: Colors.white70,
                      size: 22,
                    ),
                  ),
                  onPressed: onToggle,
                  tooltip: isExpanded ? 'Colapsar menu' : 'Expandir menu',
                ),
              ),
            )
          else
            const SizedBox(height: 16),
          Padding(
            padding: EdgeInsets.only(
              top: (isDesktop && onToggle == null) ? 12 : 0,
              bottom: isExpanded ? 8 : 10,
            ),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: logoSize,
              width: logoSize,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(
                  'lib/images/CONTRATO.png',
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
          if (isExpanded)
            AnimatedOpacity(
              opacity: isExpanded ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: Column(
                children: [
                  Text(
                    'Control de',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const Text(
                    'CONTRATOS',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 4),
          if (isExpanded)
            Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 2),
              child: Divider(
                thickness: 0.5,
                color: Colors.white.withOpacity(0.15),
                height: 1,
              ),
            ),
        ],
      ),
    );
  }
}
