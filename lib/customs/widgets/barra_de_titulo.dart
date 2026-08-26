import 'package:flutter/material.dart';

import '../../services/ventana.dart';

/// Barra de titulo propia, para la version de escritorio.
///
/// Reemplaza la del sistema, que en Windows viene con su color y su tipografia
/// y cortaba en seco la cabecera oscura de la app. Al ocultarla hay que
/// devolver todo lo que hacia: arrastrar la ventana, maximizar con doble clic,
/// y los tres botones.
///
/// Solo se dibuja donde hay ventana que controlar. En web y en Android
/// devuelve un widget de alto cero, asi que se puede poner sin condicionales
/// en el arbol comun.
class BarraDeTitulo extends StatefulWidget {
  const BarraDeTitulo({super.key, required this.titulo});

  final String titulo;

  /// Alto de la barra. Windows 11 usa 32; 40 deja los botones mas comodos y
  /// no compite con la cabecera de la app, que mide bastante mas.
  static const double alto = 40;

  @override
  State<BarraDeTitulo> createState() => _BarraDeTituloState();
}

class _BarraDeTituloState extends State<BarraDeTitulo> {
  bool _maximizada = false;

  @override
  void initState() {
    super.initState();
    if (ControlDeVentana.disponible) {
      ControlDeVentana.escuchar(_refrescar);
      _refrescar();
    }
  }

  @override
  void dispose() {
    if (ControlDeVentana.disponible) {
      ControlDeVentana.dejarDeEscuchar(_refrescar);
    }
    super.dispose();
  }

  Future<void> _refrescar() async {
    final v = await ControlDeVentana.estaMaximizada();
    if (mounted && v != _maximizada) setState(() => _maximizada = v);
  }

  @override
  Widget build(BuildContext context) {
    if (!ControlDeVentana.disponible) return const SizedBox.shrink();

    return SizedBox(
      height: BarraDeTitulo.alto,
      // `Material` y no `ColoredBox`: sin un Material encima, Flutter dibuja
      // el texto con su estilo de aviso -- amarillo y subrayado -- porque la
      // barra vive en el `builder` de la app, por fuera de cualquier Scaffold.
      child: Material(
        // El mismo tono que la cabecera de las paginas: asi la ventana se lee
        // como una sola pieza y no como la app dentro de un marco ajeno.
        color: const Color(0xFF263238),
        child: Row(
          children: [
            Expanded(
              child: GestureDetector(
                // `translucent` para que el area vacia tambien arrastre, no
                // solo donde hay texto.
                behavior: HitTestBehavior.translucent,
                onPanStart: (_) => ControlDeVentana.arrastrar(),
                onDoubleTap: ControlDeVentana.alternarMaximizada,
                child: Row(
                  children: [
                    const SizedBox(width: 16),
                    Text(
                      widget.titulo,
                      style: const TextStyle(
                        color: Color(0xE6FFFFFF),
                        fontSize: 13,
                        letterSpacing: 0.3,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            _BotonDeVentana(
              icono: Icons.remove,
              descripcion: 'Minimizar',
              onTap: ControlDeVentana.minimizar,
            ),
            _BotonDeVentana(
              icono: _maximizada
                  ? Icons.filter_none_outlined
                  : Icons.crop_square_outlined,
              descripcion: _maximizada ? 'Restaurar' : 'Maximizar',
              // El icono de restaurar son dos cuadros superpuestos y se ve
              // mas grande de lo que mide; se compensa aqui.
              tamanoIcono: _maximizada ? 13 : 15,
              onTap: ControlDeVentana.alternarMaximizada,
            ),
            _BotonDeVentana(
              icono: Icons.close,
              descripcion: 'Cerrar',
              // El rojo de cerrar es el de Windows 11. Se respeta porque es
              // la senal que la gente ya reconoce sin leer.
              colorAlPasar: const Color(0xFFC42B1C),
              onTap: ControlDeVentana.cerrar,
            ),
          ],
        ),
      ),
    );
  }
}

class _BotonDeVentana extends StatefulWidget {
  const _BotonDeVentana({
    required this.icono,
    required this.descripcion,
    required this.onTap,
    this.colorAlPasar = const Color(0x1AFFFFFF),
    this.tamanoIcono = 15,
  });

  final IconData icono;
  final String descripcion;
  final VoidCallback onTap;
  final Color colorAlPasar;
  final double tamanoIcono;

  @override
  State<_BotonDeVentana> createState() => _BotonDeVentanaState();
}

class _BotonDeVentanaState extends State<_BotonDeVentana> {
  bool _encima = false;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: widget.descripcion,
      child: MouseRegion(
        onEnter: (_) => setState(() => _encima = true),
        onExit: (_) => setState(() => _encima = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: Container(
            // 46 de ancho es la medida de los botones de Windows: la gente
            // apunta ahi de memoria.
            width: 46,
            height: BarraDeTitulo.alto,
            color: _encima ? widget.colorAlPasar : Colors.transparent,
            child: Icon(
              widget.icono,
              size: widget.tamanoIcono,
              color: const Color(0xE6FFFFFF),
            ),
          ),
        ),
      ),
    );
  }
}
