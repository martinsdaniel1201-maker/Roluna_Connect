import 'package:intl/intl.dart';

class DateFormatters {
  DateFormatters._();

  static final _dataHora = DateFormat('dd/MM/yyyy \'às\' HH:mm', 'pt_BR');
  static final _dataCurta = DateFormat('dd/MM/yyyy', 'pt_BR');
  static final _diaMes = DateFormat('dd/MM', 'pt_BR');
  static final _horaCurta = DateFormat('HH:mm', 'pt_BR');

  static String dataHora(DateTime d) => _dataHora.format(d.toLocal());
  static String dataCurta(DateTime d) => _dataCurta.format(d.toLocal());
  static String diaMes(DateTime d) => _diaMes.format(d.toLocal());

  /// "há 5 min", "há 2 h", "ontem", ou data curta para itens antigos.
  static String tempoRelativo(DateTime d) {
    final agora = DateTime.now();
    final diff = agora.difference(d.toLocal());

    if (diff.inMinutes < 1) return 'agora';
    if (diff.inMinutes < 60) return 'há ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'há ${diff.inHours} h';
    if (diff.inDays == 1) return 'ontem';
    if (diff.inDays < 7) return 'há ${diff.inDays} dias';
    return _dataCurta.format(d.toLocal());
  }

  static String horaCurta(DateTime d) => _horaCurta.format(d.toLocal());
}
