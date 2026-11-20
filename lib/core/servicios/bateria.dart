import 'package:flutter/services.dart';

abstract interface class ServicioBateria {
  Future<bool?> estaExento();

  Future<void> pedirExencion();
}

class ServicioBateriaCanal implements ServicioBateria {
  const ServicioBateriaCanal();

  static const _canal = MethodChannel('com.izquierdojl.tolochatracks/bateria');

  @override
  Future<bool?> estaExento() async {
    try {
      return await _canal.invokeMethod<bool>('estadoBateria');
    } on Object {
      return null;
    }
  }

  @override
  Future<void> pedirExencion() async {
    try {
      await _canal.invokeMethod<bool>('pedirExencionBateria');
    } on Object {
      // En tests o plataformas sin canal no hay nada que abrir.
    }
  }
}
