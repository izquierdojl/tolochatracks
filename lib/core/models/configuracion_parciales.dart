import 'package:flutter/foundation.dart';

enum ModoParciales {
  distancia('Por distancia'),
  tiempo('Por tiempo');

  const ModoParciales(this.etiqueta);

  final String etiqueta;
}

@immutable
class ConfiguracionParciales {
  const ConfiguracionParciales._({required this.modo, required this.valor});

  factory ConfiguracionParciales.distancia(int metros) {
    if (!pasosDistanciaMetros.contains(metros)) {
      throw ArgumentError.value(
        metros,
        'metros',
        'Paso de distancia no admitido',
      );
    }
    return ConfiguracionParciales._(
      modo: ModoParciales.distancia,
      valor: metros,
    );
  }

  factory ConfiguracionParciales.tiempo(Duration duracion) {
    final segundos = duracion.inSeconds;
    if (duracion.inMilliseconds.remainder(1000) != 0 ||
        !pasosTiempoSegundos.contains(segundos)) {
      throw ArgumentError.value(
        duracion,
        'duracion',
        'Paso de tiempo no admitido',
      );
    }
    return ConfiguracionParciales._(
      modo: ModoParciales.tiempo,
      valor: segundos,
    );
  }

  static const porDefecto = ConfiguracionParciales._(
    modo: ModoParciales.distancia,
    valor: 1000,
  );
  static const porDefectoDistancia = ConfiguracionParciales._(
    modo: ModoParciales.distancia,
    valor: 1000,
  );
  static const porDefectoPorTiempo = ConfiguracionParciales._(
    modo: ModoParciales.tiempo,
    valor: 300,
  );

  static const pasosDistanciaMetros = <int>[100, 200, 500, 1000, 5000, 10000];
  static const pasosTiempoSegundos = <int>[
    60,
    300,
    600,
    900,
    1200,
    1800,
    2700,
    3600,
  ];

  final ModoParciales modo;
  final int valor;

  bool get esDistancia => modo == ModoParciales.distancia;
  double get pasoMetros => esDistancia ? valor.toDouble() : 0;
  Duration get pasoTiempo =>
      esDistancia ? Duration.zero : Duration(seconds: valor);
  List<int> get opciones =>
      esDistancia ? pasosDistanciaMetros : pasosTiempoSegundos;
  String get etiquetaPaso =>
      esDistancia ? _etiquetaDistancia(valor) : _etiquetaTiempo(valor);
  String get descripcion => 'Cada $etiquetaPaso';

  ConfiguracionParciales copyWith({ModoParciales? modo, int? valor}) {
    final nuevoModo = modo ?? this.modo;
    final nuevoValor =
        valor ??
        (nuevoModo == this.modo
            ? this.valor
            : (nuevoModo == ModoParciales.distancia ? 1000 : 300));
    return nuevoModo == ModoParciales.distancia
        ? ConfiguracionParciales.distancia(nuevoValor)
        : ConfiguracionParciales.tiempo(Duration(seconds: nuevoValor));
  }

  static ConfiguracionParciales desdeClaves(Object? modo, Object? valor) {
    final numero = valor is int
        ? valor
        : valor is num
        ? valor.toInt()
        : int.tryParse('$valor');
    if (modo == ModoParciales.distancia.name &&
        numero != null &&
        pasosDistanciaMetros.contains(numero)) {
      return ConfiguracionParciales.distancia(numero);
    }
    if (modo == ModoParciales.tiempo.name &&
        numero != null &&
        pasosTiempoSegundos.contains(numero)) {
      return ConfiguracionParciales.tiempo(Duration(seconds: numero));
    }
    return porDefecto;
  }

  static String _etiquetaDistancia(int metros) =>
      metros >= 1000 ? '${metros ~/ 1000} km' : '$metros m';

  static String _etiquetaTiempo(int segundos) {
    final minutos = segundos ~/ 60;
    if (minutos < 60) return '$minutos min';
    final horas = minutos ~/ 60;
    final resto = minutos.remainder(60);
    return resto == 0 ? '$horas h' : '$horas h $resto';
  }

  @override
  bool operator ==(Object other) =>
      other is ConfiguracionParciales &&
      other.modo == modo &&
      other.valor == valor;

  @override
  int get hashCode => Object.hash(modo, valor);

  @override
  String toString() => 'ConfiguracionParciales(${modo.name}, $valor)';
}
