import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Datos fiscales del emisor necesarios para generar comprobantes electrónicos.
class FiscalConfig {
  const FiscalConfig({
    this.ruc = '',
    this.razonSocial = '',
    this.nombreComercial = '',
    this.establecimiento = '001',
    this.puntoEmision = '001',
    this.autorizacionSri = '',
    this.direccion = '',
    this.ambiente = 'pruebas',
  });

  final String ruc;
  final String razonSocial;
  final String nombreComercial;
  final String establecimiento;
  final String puntoEmision;
  final String autorizacionSri;
  final String direccion;
  final String ambiente;

  bool get isConfigured =>
      ruc.isNotEmpty &&
      establecimiento.isNotEmpty &&
      puntoEmision.isNotEmpty &&
      autorizacionSri.isNotEmpty;

  FiscalConfig copyWith({
    String? ruc,
    String? razonSocial,
    String? nombreComercial,
    String? establecimiento,
    String? puntoEmision,
    String? autorizacionSri,
    String? direccion,
    String? ambiente,
  }) {
    return FiscalConfig(
      ruc: ruc ?? this.ruc,
      razonSocial: razonSocial ?? this.razonSocial,
      nombreComercial: nombreComercial ?? this.nombreComercial,
      establecimiento: establecimiento ?? this.establecimiento,
      puntoEmision: puntoEmision ?? this.puntoEmision,
      autorizacionSri: autorizacionSri ?? this.autorizacionSri,
      direccion: direccion ?? this.direccion,
      ambiente: ambiente ?? this.ambiente,
    );
  }

  Map<String, dynamic> toJson() => {
    'ruc': ruc,
    'razonSocial': razonSocial,
    'nombreComercial': nombreComercial,
    'establecimiento': establecimiento,
    'puntoEmision': puntoEmision,
    'autorizacionSri': autorizacionSri,
    'direccion': direccion,
    'ambiente': ambiente,
  };

  factory FiscalConfig.fromJson(Map<String, dynamic> json) => FiscalConfig(
    ruc: (json['ruc'] as String?) ?? '',
    razonSocial: (json['razonSocial'] as String?) ?? '',
    nombreComercial: (json['nombreComercial'] as String?) ?? '',
    establecimiento: (json['establecimiento'] as String?) ?? '001',
    puntoEmision: (json['puntoEmision'] as String?) ?? '001',
    autorizacionSri: (json['autorizacionSri'] as String?) ?? '',
    direccion: (json['direccion'] as String?) ?? '',
    ambiente: (json['ambiente'] as String?) ?? 'pruebas',
  );
}

/// Persiste y recupera la configuración fiscal del establecimiento.
class FiscalConfigService {
  static const String _key = 'fiscal_config';

  Future<FiscalConfig> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return const FiscalConfig();
    try {
      return FiscalConfig.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } on Exception {
      return const FiscalConfig();
    }
  }

  Future<void> save(FiscalConfig config) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(config.toJson()));
  }
}
