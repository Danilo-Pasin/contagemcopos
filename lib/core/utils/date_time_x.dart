import 'package:intl/intl.dart';

/// Utilitários de formatação de datas e tempo relativo.
class DateTimeX {
  const DateTimeX._();

  static String timeAgo(DateTime date, {DateTime? now}) {
    final n = now ?? DateTime.now();
    final diff = n.difference(date.toLocal());

    if (diff.inSeconds < 60) return 'agora mesmo';
    if (diff.inMinutes < 60) return 'há ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'há ${diff.inHours} h';
    if (diff.inDays == 1) return 'ontem';
    if (diff.inDays < 7) return 'há ${diff.inDays} dias';

    return DateFormat('dd/MM', 'pt_BR').format(date.toLocal());
  }

  static String format(DateTime date, {String pattern = 'dd/MM/yyyy HH:mm'}) {
    return DateFormat(pattern, 'pt_BR').format(date.toLocal());
  }

  static String shortDate(DateTime date) =>
      DateFormat('dd/MM', 'pt_BR').format(date.toLocal());

  static String dayMonth(DateTime date) =>
      DateFormat('d MMM', 'pt_BR').format(date.toLocal());

  /// Dias restantes até a data (mínimo 0).
  static int daysLeft(DateTime end) =>
      end.toLocal().difference(DateTime.now()).inDays.clamp(0, 999999);

  static String hoursLeftLabel(DateTime end) {
    final diff = end.toLocal().difference(DateTime.now());
    if (diff.inHours <= 0) return 'encerrado';
    if (diff.inHours < 48) return '${diff.inHours}h restantes';
    return '${diff.inDays} dias restantes';
  }
}
