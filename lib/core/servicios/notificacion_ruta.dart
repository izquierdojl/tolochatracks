import 'dart:async';

import 'package:flutter/services.dart';

enum AccionNotificacion { pausar, reanudar, detener }

abstract interface class ServicioNotificacionRuta {
  Stream<AccionNotificacion> get acciones;

  Future<void> iniciar();

  Future<void> actualizar({required bool pausado});

  Future<void> detener();

  Future<void> dispose();
}

class ServicioNotificacionRutaCanal implements ServicioNotificacionRuta {
  ServicioNotificacionRutaCanal() {
    _canal.setMethodCallHandler(_manejar);
  }

  static const _canal = MethodChannel('com.izquierdojl.tolochatracks/ruta');
  final StreamController<AccionNotificacion> _acciones =
      StreamController<AccionNotificacion>.broadcast();

  @override
  Stream<AccionNotificacion> get acciones => _acciones.stream;

  Future<void> _manejar(MethodCall llamada) async {
    if (llamada.method != 'accion') return;
    final accion = switch (llamada.arguments) {
      'pausar' => AccionNotificacion.pausar,
      'reanudar' => AccionNotificacion.reanudar,
      'detener' => AccionNotificacion.detener,
      _ => null,
    };
    if (accion != null && !_acciones.isClosed) {
      _acciones.add(accion);
    }
  }

  @override
  Future<void> iniciar() async {
    try {
      await _canal.invokeMethod<bool>('iniciar');
    } on Object {
      // Sin canal (tests/otras plataformas), la grabación sigue funcionando.
    }
  }

  @override
  Future<void> actualizar({required bool pausado}) async {
    try {
      await _canal.invokeMethod<bool>('actualizar', {'pausado': pausado});
    } on Object {
      // La notificación es una ayuda; no debe tumbar la grabación.
    }
  }

  @override
  Future<void> detener() async {
    try {
      await _canal.invokeMethod<bool>('detener');
    } on Object {
      // Nada que hacer si el servicio ya no está.
    }
  }

  @override
  Future<void> dispose() async {
    _canal.setMethodCallHandler(null);
    await _acciones.close();
  }
}
