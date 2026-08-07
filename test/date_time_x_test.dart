import 'package:contagem/core/utils/date_time_x.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() => initializeDateFormatting('pt_BR', null));

  final now = DateTime(2026, 8, 7, 12, 0);

  group('DateTimeX.timeAgo', () {
    test('até 59 segundos → agora mesmo', () {
      expect(DateTimeX.timeAgo(now.subtract(const Duration(seconds: 5)), now: now),
          'agora mesmo');
      expect(DateTimeX.timeAgo(now.subtract(const Duration(seconds: 59)), now: now),
          'agora mesmo');
    });

    test('minutos', () {
      expect(DateTimeX.timeAgo(now.subtract(const Duration(minutes: 1)), now: now),
          'há 1 min');
      expect(DateTimeX.timeAgo(now.subtract(const Duration(minutes: 59)), now: now),
          'há 59 min');
    });

    test('horas', () {
      expect(DateTimeX.timeAgo(now.subtract(const Duration(hours: 1)), now: now),
          'há 1 h');
      expect(DateTimeX.timeAgo(now.subtract(const Duration(hours: 23)), now: now),
          'há 23 h');
    });

    test('um dia exato → ontem', () {
      expect(DateTimeX.timeAgo(now.subtract(const Duration(days: 1)), now: now),
          'ontem');
    });

    test('até 6 dias → X dias', () {
      expect(DateTimeX.timeAgo(now.subtract(const Duration(days: 2)), now: now),
          'há 2 dias');
      expect(DateTimeX.timeAgo(now.subtract(const Duration(days: 6)), now: now),
          'há 6 dias');
    });

    test('7+ dias → data dd/MM', () {
      final out = DateTimeX.timeAgo(now.subtract(const Duration(days: 7)), now: now);
      expect(out, matches(RegExp(r'^\d{2}/\d{2}$')));
    });
  });

  group('DateTimeX.daysLeft', () {
    test('nunca fica negativo', () {
      final past = DateTime.now().subtract(const Duration(days: 1));
      expect(DateTimeX.daysLeft(past), 0);
    });

    test('hoje → 0', () {
      expect(DateTimeX.daysLeft(DateTime.now().add(const Duration(hours: 5))), 0);
    });
  });

  group('DateTimeX.hoursLeftLabel', () {
    test('encerrado quando expirou', () {
      expect(DateTimeX.hoursLeftLabel(DateTime.now().subtract(const Duration(minutes: 1))),
          'encerrado');
    });

    test('menos de 48h mostra horas', () {
      final in10h = DateTime.now().add(
          const Duration(hours: 10, minutes: 5)); // +5min evita truncar o relógio
      expect(DateTimeX.hoursLeftLabel(in10h), '10h restantes');
    });

    test('48h+ mostra dias', () {
      // +1h além de 3 dias para não truncar por conta do tempo decorrido
      final in3d =
          DateTime.now().add(const Duration(days: 3, hours: 1));
      expect(DateTimeX.hoursLeftLabel(in3d), '3 dias restantes');
    });
  });

  group('DateTimeX.format/shortDate', () {
    test('shortDate sempre dd/MM', () {
      expect(DateTimeX.shortDate(DateTime(2026, 1, 5, 8, 0)), '05/01');
    });
  });
}