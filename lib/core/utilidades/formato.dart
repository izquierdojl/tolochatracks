import '../models/configuracion_parciales.dart';

String _numero(double valor, int decimales) =>
    valor.toStringAsFixed(decimales).replaceAll('.', ',');

String formatearDistancia(double metros) {
  if (!metros.isFinite || metros < 0) return '—';
  if (metros < 1000) return '${metros.round()} m';
  return '${_numero(metros / 1000, 2)} km';
}

String formatearDistanciaCorta(double metros) {
  if (!metros.isFinite || metros < 0) return '—';
  if (metros < 1000) return '${metros.round()} m';
  return '${_numero(metros / 1000, 1)} km';
}

String formatearDuracion(Duration duracion) {
  final horas = duracion.inHours;
  final minutos = duracion.inMinutes.remainder(60);
  final segundos = duracion.inSeconds.remainder(60);
  final mm = minutos.toString().padLeft(2, '0');
  final ss = segundos.toString().padLeft(2, '0');
  if (horas > 0) return '$horas:$mm:$ss';
  return '$mm:$ss';
}

String formatearRitmoCorto(double? metrosPorSegundo) {
  if (metrosPorSegundo == null ||
      !metrosPorSegundo.isFinite ||
      metrosPorSegundo <= 0.05) {
    return '—';
  }
  final segundosPorKm = 1000 / metrosPorSegundo;
  if (segundosPorKm > 359999) return '—';
  final duracion = Duration(milliseconds: (segundosPorKm * 1000).round());
  final minutos = duracion.inMinutes;
  final segundos = duracion.inSeconds.remainder(60).toString().padLeft(2, '0');
  return '$minutos:$segundos';
}

String formatearRitmo(double? metrosPorSegundo) {
  final corto = formatearRitmoCorto(metrosPorSegundo);
  return corto == '—' ? corto : '$corto /km';
}

String formatearVelocidadCorto(double? metrosPorSegundo) {
  if (metrosPorSegundo == null ||
      !metrosPorSegundo.isFinite ||
      metrosPorSegundo < 0) {
    return '—';
  }
  return _numero(metrosPorSegundo * 3.6, 1);
}

String formatearVelocidad(double? metrosPorSegundo) {
  final corto = formatearVelocidadCorto(metrosPorSegundo);
  return corto == '—' ? corto : '$corto km/h';
}

String formatearDesnivel(double metros) {
  if (!metros.isFinite) return '—';
  return '${metros.round()} m';
}

String formatearMetrosCorto(double? metros) {
  if (metros == null || !metros.isFinite) return '—';
  return _numero(metros, 0);
}

String formatearMetros(double metros, {int decimales = 0}) {
  if (!metros.isFinite) return '—';
  return '${_numero(metros, decimales)} m';
}

String etiquetaTramoParcial(
  ConfiguracionParciales configuracion,
  int numero, {
  bool completo = true,
}) {
  if (!completo) return 'Final';
  if (configuracion.esDistancia) {
    final metros = numero * configuracion.valor;
    if (configuracion.valor.remainder(1000) == 0) {
      return 'Km ${metros ~/ 1000}';
    }
    if (metros < 1000) return '${metros.round()} m';
    return 'Km ${_numero(metros / 1000, 1)}';
  }
  final minutos = numero * (configuracion.valor ~/ 60);
  if (minutos < 60) return '$minutos min';
  final horas = minutos ~/ 60;
  final resto = minutos.remainder(60);
  return resto == 0 ? '$horas h' : '$horas h $resto';
}

const _meses = [
  'ene',
  'feb',
  'mar',
  'abr',
  'may',
  'jun',
  'jul',
  'ago',
  'sep',
  'oct',
  'nov',
  'dic',
];

String formatearFecha(DateTime fecha) {
  final local = fecha.toLocal();
  return '${local.day} ${_meses[local.month - 1]} ${local.year}';
}

String formatearFechaHora(DateTime fecha) {
  final local = fecha.toLocal();
  final hora = local.hour.toString().padLeft(2, '0');
  final minuto = local.minute.toString().padLeft(2, '0');
  return '${formatearFecha(local)} · $hora:$minuto';
}

String formatearHora(DateTime fecha) {
  final local = fecha.toLocal();
  final hora = local.hour.toString().padLeft(2, '0');
  final minuto = local.minute.toString().padLeft(2, '0');
  return '$hora:$minuto';
}
