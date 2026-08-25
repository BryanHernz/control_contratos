import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myapp/customs/widgets/app_form.dart';

/// Regresiones de maquetacion del editor de plantillas.
///
/// El editor vive dentro de un `SingleChildScrollView`, que da altura infinita
/// a sus hijos. Cada vez que un `Expanded` quedo bajo esa altura sin limite, la
/// pantalla se fue en blanco y la pestaña se congelo -- dos veces seguidas, y
/// sin error visible que lo delatara. Estas pruebas reproducen exactamente esa
/// anidacion.
void main() {
  Widget envolver(Widget hijo) => MaterialApp(
        home: Scaffold(
          // El mismo contexto que `AppModalBody`: scroll vertical, o sea alto
          // sin limite para el hijo.
          body: SingleChildScrollView(child: hijo),
        ),
      );

  testWidgets(
    'una tarjeta expandida con un Expanded adentro no revienta bajo scroll',
    (tester) async {
      await tester.pumpWidget(
        envolver(
          SizedBox(
            height: 400,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: AppFormSection(
                    title: 'Cuerpo',
                    icon: Icons.article_outlined,
                    expandido: true,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('barra'),
                        Expanded(child: Container(color: Colors.white)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: AppFormSection(
                    title: 'Vista previa',
                    icon: Icons.picture_as_pdf_outlined,
                    expandido: true,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('chip'),
                        Expanded(child: Container(color: Colors.white)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Cuerpo'.toUpperCase()), findsOneWidget);
      expect(find.text('Vista previa'.toUpperCase()), findsOneWidget);
    },
  );

  testWidgets(
    'las dos tarjetas de una fila terminan con el mismo alto',
    (tester) async {
      await tester.pumpWidget(
        envolver(
          SizedBox(
            height: 400,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: AppFormSection(
                    title: 'Corta',
                    icon: Icons.article_outlined,
                    expandido: true,
                    child: const Text('una linea'),
                  ),
                ),
                Expanded(
                  child: AppFormSection(
                    title: 'Larga',
                    icon: Icons.article_outlined,
                    expandido: true,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(6, (i) => Text('linea $i')),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);

      final altos = tester
          .widgetList<AppFormSection>(find.byType(AppFormSection))
          .map((w) => tester.getSize(find.byWidget(w)).height)
          .toList();
      expect(altos, hasLength(2));
      expect(altos.first, equals(altos.last));
    },
  );

  testWidgets(
    'sin `expandido` la tarjeta sigue midiendo lo que mide su contenido',
    (tester) async {
      await tester.pumpWidget(
        envolver(
          AppFormSection(
            title: 'Normal',
            icon: Icons.article_outlined,
            child: const SizedBox(height: 40),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      final alto = tester.getSize(find.byType(AppFormSection).first).height;
      // 16 arriba + titulo + 14 + 40 + 18 abajo: bastante menos que la pantalla.
      expect(alto, lessThan(200));
    },
  );
}
