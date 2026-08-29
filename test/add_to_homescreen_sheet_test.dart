import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:contagem/presentation/widgets/add_to_homescreen_prompt.dart';

Widget _host(Widget child) => MaterialApp(
      home: Scaffold(body: child),
    );

void main() {
  group('AddToHomescreenSheet', () {
    testWidgets('iOS Safari mostra passos do Compartilhar e não tem botão nativo',
        (tester) async {
      await tester.pumpWidget(_host(const AddToHomescreenSheet(iosSafari: true)));

      expect(find.text('Instale o OGS'), findsOneWidget);
      expect(find.text('Toque no botão Compartilhar'), findsOneWidget);
      expect(find.text('Role e toque em "Adicionar à Tela de Início"'),
          findsOneWidget);
      expect(find.text('Instalar app'), findsNothing);
      expect(find.text('Entendi'), findsOneWidget);
    });

    testWidgets('Android/Chrome mostra passos do menu (⋮)', (tester) async {
      await tester.pumpWidget(_host(const AddToHomescreenSheet()));

      expect(find.text('Toque no menu (⋮) do navegador'), findsOneWidget);
      expect(find.text('Toque em "Adicionar à tela inicial"'), findsOneWidget);
      expect(find.text('Entendi'), findsOneWidget);
    });

    testWidgets('com prompt nativo mostra botão Instalar + tutorial manual',
        (tester) async {
      await tester.pumpWidget(
          _host(const AddToHomescreenSheet(hasNativeInstall: true)));

      expect(find.text('Instalar app'), findsOneWidget);
      expect(find.text('Agora não'), findsOneWidget);
      expect(
          find.text('Se não aparecer a opção, siga o tutorial manual abaixo.'),
          findsOneWidget);
      // Tutorial manual continua disponível como fallback.
      expect(find.text('Toque no menu (⋮) do navegador'), findsOneWidget);
    });

    testWidgets('"Entendi" fecha a sheet sinalizando dispensa (pop true)',
        (tester) async {
      bool? result;
      await tester.pumpWidget(MaterialApp(
        home: Builder(
          builder: (context) => Center(
            child: ElevatedButton(
              onPressed: () async {
                result = await showModalBottomSheet<bool>(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) =>
                      const AddToHomescreenSheet(hasNativeInstall: false),
                );
              },
              child: const Text('abrir'),
            ),
          ),
        ),
      ));

      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Entendi'));
      await tester.pumpAndSettle();

      expect(result, isTrue);
    });
  });
}
