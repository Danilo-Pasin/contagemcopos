import 'package:contagem/presentation/widgets/app_logo.dart';
import 'package:contagem/presentation/widgets/responsive_content.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppLogo', () {
    testWidgets('renderiza um container quadrado do tamanho pedido',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: Center(child: AppLogo()))),
      );
      await tester.pumpAndSettle();
      expect(find.byType(AppLogo), findsOneWidget);
      final box = tester.getSize(find.byType(Image));
      expect(box.width, closeTo(120, 0.5));
      expect(box.height, closeTo(120, 0.5));
    });

    testWidgets('aceita tamanho customizado', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: Center(child: AppLogo(size: 64))),
        ),
      );
      await tester.pumpAndSettle();
      final box = tester.getSize(find.byType(Image));
      expect(box.width, closeTo(64, 0.5));
      expect(box.height, closeTo(64, 0.5));
    });
  });

  group('ResponsiveContent', () {
    testWidgets('limita a largura por maxWidth', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ResponsiveContent(
              maxWidth: 560,
              child: const SizedBox(
                key: ValueKey('wide'),
                width: 1000,
                height: 200,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      // O ConstrainedBox deve limitar o filho a ~560px, mesmo pedindo 1000px.
      expect(tester.getSize(find.byKey(const ValueKey('wide'))).width,
          closeTo(560, 1));
    });
  });
}