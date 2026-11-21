import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';

import '../models/perfil_gps.dart';

enum PermisoUbicacion {
  concedido,
  denegado,
  denegadoSiempre,
  servicioDesactivado,
  error,
}

@immutable
class PuntoGps {
  const PuntoGps({
    required this.latitud,
    required this.longitud,
    required this.tiempo,
    this.altitud,
    this.precision,
    this.velocidad,
    this.rumbo,
  });

  final double latitud;
  final double longitud;
  final DateTime tiempo;
  final double? altitud;
  final double? precision;
  final double? velocidad;
  final double? rumbo;
}

abstract interface class ServicioUbicacion {
  Future<bool> prepararNotificaciones();
  Future<PermisoUbicacion> asegurarPermiso();
  Future<bool> servicioActivo();
  Future<PuntoGps?> posicionActual();
  Stream<PuntoGps> posiciones(PerfilGps perfil);
  Future<void> abrirAjustesPermiso();
  Future<void> abrirAjustesUbicacion();
}

AndroidSettings ajustesAndroidPara(PerfilGps perfil) => AndroidSettings(
  accuracy: perfil.calidad == CalidadGps.alta
      ? LocationAccuracy.high
      : LocationAccuracy.medium,
  distanceFilter: perfil.distanciaMinima,
  intervalDuration: perfil.intervalo,
  forceLocationManager: true,
  useMSLAltitude: true,
);

PuntoGps convertirPosicion(Position posicion, {DateTime Function()? ahora}) {
  final referencia = (ahora ?? DateTime.now)();
  final tiempo = posicion.timestamp;
  return PuntoGps(
    latitud: posicion.latitude,
    longitud: posicion.longitude,
    tiempo: tiempo.isAfter(referencia.subtract(const Duration(minutes: 5)))
        ? tiempo
        : referencia,
    altitud: posicion.altitude,
    precision: posicion.accuracy > 0 ? posicion.accuracy : null,
    velocidad: posicion.hasSpeed ? posicion.speed : null,
    rumbo: posicion.heading >= 0 ? posicion.heading : null,
  );
}

class ServicioUbicacionGeolocator implements ServicioUbicacion {
  const ServicioUbicacionGeolocator();

  static const _canalPermisos = MethodChannel(
    'com.izquierdojl.tolochatracks/permisos',
  );

  @override
  Future<bool> prepararNotificaciones() async {
    try {
      final concedido = await _canalPermisos
          .invokeMethod<bool>('pedirNotificaciones')
          .timeout(const Duration(seconds: 30));
      return concedido ?? true;
    } on Object {
      return true;
    }
  }

  @override
  Future<PermisoUbicacion> asegurarPermiso() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        return PermisoUbicacion.servicioDesactivado;
      }
      var permiso = await Geolocator.checkPermission();
      if (permiso == LocationPermission.denied) {
        permiso = await Geolocator.requestPermission();
      }
      if (permiso == LocationPermission.deniedForever) {
        return PermisoUbicacion.denegadoSiempre;
      }
      if (permiso == LocationPermission.denied ||
          permiso == LocationPermission.unableToDetermine) {
        return PermisoUbicacion.denegado;
      }
      if (!await Geolocator.isLocationServiceEnabled()) {
        return PermisoUbicacion.servicioDesactivado;
      }
      return PermisoUbicacion.concedido;
    } on Object {
      return PermisoUbicacion.error;
    }
  }

  @override
  Future<bool> servicioActivo() async {
    try {
      return await Geolocator.isLocationServiceEnabled();
    } on Object {
      return false;
    }
  }

  @override
  Future<PuntoGps?> posicionActual() async {
    try {
      final posicion = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 8),
        ),
      );
      return convertirPosicion(posicion);
    } on Object {
      try {
        final ultima = await Geolocator.getLastKnownPosition();
        return ultima == null ? null : convertirPosicion(ultima);
      } on Object {
        return null;
      }
    }
  }

  @override
  Stream<PuntoGps> posiciones(PerfilGps perfil) {
    final LocationSettings ajustes;
    if (Platform.isAndroid) {
      ajustes = ajustesAndroidPara(perfil);
    } else {
      ajustes = LocationSettings(
        accuracy: perfil.calidad == CalidadGps.alta
            ? LocationAccuracy.high
            : LocationAccuracy.medium,
        distanceFilter: perfil.distanciaMinima,
      );
    }
    return Geolocator.getPositionStream(locationSettings: ajustes)
        .map(convertirPosicion);
  }

  @override
  Future<void> abrirAjustesPermiso() => Geolocator.openAppSettings();

  @override
  Future<void> abrirAjustesUbicacion() => Geolocator.openLocationSettings();
}
