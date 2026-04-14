import 'package:intl/intl.dart';
import 'package:restaurant_app/core/constants/app_constants.dart';
import 'package:restaurant_app/core/domain/enums.dart';
import 'package:restaurant_app/features/caja/domain/entities/venta.dart';
import 'package:restaurant_app/services/facturacion/fiscal_config_service.dart';
import 'package:restaurant_app/services/facturacion/sri_secuencial_service.dart';

/// Estado de la configuración necesaria para facturación electrónica con SRI.
class SriConnectionStatus {
  final bool isConfigured;
  final Uri endpoint;
  final String environment;
  final String environmentCode;
  final List<String> missingFields;
  final String message;

  const SriConnectionStatus({
    required this.isConfigured,
    required this.endpoint,
    required this.environment,
    required this.environmentCode,
    required this.missingFields,
    required this.message,
  });

  bool get canPrepareInvoice => isConfigured && missingFields.isEmpty;
}

/// Borrador local de factura electrónica preparado para ser enviado por backend.
class SriInvoiceDraft {
  final SriConnectionStatus status;
  final Map<String, dynamic> payload;
  final String reference;
  final String accessKey;
  final String xmlPreview;
  final Map<String, String> requestHeaders;
  final bool transmissionCommented;
  final List<String> nextSteps;

  const SriInvoiceDraft({
    required this.status,
    required this.payload,
    required this.reference,
    required this.accessKey,
    required this.xmlPreview,
    required this.requestHeaders,
    required this.transmissionCommented,
    required this.nextSteps,
  });
}

/// Contrato para preparar la integración futura con SRI.
abstract class SriService {
  Future<SriConnectionStatus> getConnectionStatus();
  Future<SriInvoiceDraft> buildInvoiceDraft(Venta venta);
  Future<Map<String, dynamic>> buildBridgeRequest(Venta venta);
  Future<Map<String, dynamic>> sendInvoiceWhenEnabled(SriInvoiceDraft draft);
}

/// Implementación base.
///
/// La app deja listo el payload, el XML preliminar, la clave de acceso y
/// la estructura para un backend puente. La conexión real queda comentada.
class SriServiceImpl implements SriService {
  final SriSecuencialService _secuencialService;

  SriServiceImpl({SriSecuencialService? secuencialService})
    : _secuencialService = secuencialService ?? SriSecuencialService();

  @override
  Future<SriConnectionStatus> getConnectionStatus() async {
    final cfg = await FiscalConfigService().load();

    final missing = <String>[];
    if (cfg.ruc.isEmpty) missing.add('RUC');
    if (cfg.establecimiento.isEmpty) missing.add('Establecimiento');
    if (cfg.puntoEmision.isEmpty) missing.add('Punto de emisión');
    if (cfg.autorizacionSri.isEmpty) missing.add('Autorización SRI');

    final environment = cfg.ambiente.isNotEmpty
        ? cfg.ambiente
        : AppConstants.sriEnvironment;
    final endpoint = Uri.parse(
      AppConstants.sriBridgeBaseUrl,
    ).resolve(AppConstants.sriBridgeInvoicePath);
    final isConfigured = missing.isEmpty;

    return SriConnectionStatus(
      isConfigured: isConfigured,
      endpoint: endpoint,
      environment: environment,
      environmentCode: _resolveEnvironmentCode(environment),
      missingFields: missing,
      message: isConfigured
          ? 'Configuración fiscal lista. Se generará XML y clave de acceso; el envío real al SRI queda comentado por ahora.'
          : 'Faltan datos fiscales: ${missing.join(', ')}. Configúralos en Caja → Configuración Fiscal.',
    );
  }

  @override
  Future<SriInvoiceDraft> buildInvoiceDraft(Venta venta) async {
    final cfg = await FiscalConfigService().load();
    final status = await getConnectionStatus();
    final reference = _buildReference(venta);
    final estab = _normalizeDigits(cfg.establecimiento, 3, fallback: '001');
    final puntoEmision = _normalizeDigits(cfg.puntoEmision, 3, fallback: '001');
    final secuencial = await _secuencialService.siguiente(
      estab: estab,
      puntoEmision: puntoEmision,
      restaurantId: venta.restaurantId,
    );
    final accessKey = _buildAccessKey(venta, cfg, status, secuencial);
    final xmlPreview = _buildXmlPreview(
      venta: venta,
      cfg: cfg,
      accessKey: accessKey,
      reference: reference,
      status: status,
      secuencial: secuencial,
    );

    final payload = <String, dynamic>{
      'ambiente': status.environment,
      'codigoAmbiente': status.environmentCode,
      'endpoint': status.endpoint.toString(),
      'conexionComentada': true,
      'emisor': {
        'ruc': cfg.ruc,
        'razonSocial': cfg.razonSocial.isNotEmpty
            ? cfg.razonSocial
            : AppConstants.appFullName,
        'establecimiento': _normalizeDigits(
          cfg.establecimiento,
          3,
          fallback: '001',
        ),
        'puntoEmision': _normalizeDigits(cfg.puntoEmision, 3, fallback: '001'),
        'autorizacion': cfg.autorizacionSri,
      },
      'cliente': {
        'nombre': venta.clienteNombre,
        'email': venta.clienteEmail,
        'identificacion': venta.clienteIdentificacion,
      },
      'comprobante': {
        'tipo': venta.tipoComprobante.value,
        'referencia': reference,
        'claveAcceso': accessKey,
        'secuencial': secuencial,
        'pedidoId': venta.pedidoId,
        'fechaEmision': venta.createdAt.toIso8601String(),
        'moneda': AppConstants.currencyCode,
        'metodoPago': venta.metodoPago.value,
      },
      'totales': {
        'subtotal': venta.subtotal,
        'impuestos': venta.impuestos,
        'total': venta.total,
      },
      'items': venta.detalles
          .map(
            (detalle) => {
              'productoId': detalle.productoId,
              'descripcion': detalle.varianteNombre != null
                  ? '${detalle.productoNombre ?? 'Producto'} (${detalle.varianteNombre})'
                  : (detalle.productoNombre ?? 'Producto'),
              'cantidad': detalle.cantidad,
              'precioUnitario': detalle.precioUnitario,
              'subtotal': detalle.subtotal,
            },
          )
          .toList(),
      'xmlPreview': xmlPreview,
    };

    return SriInvoiceDraft(
      status: status,
      payload: payload,
      reference: reference,
      accessKey: accessKey,
      xmlPreview: xmlPreview,
      requestHeaders: const {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      transmissionCommented: true,
      nextSteps: const [
        'Configurar el backend puente que firme el XML.',
        'Descomentar el bloque HTTP dentro de `sendInvoiceWhenEnabled`.',
        'Mapear la respuesta real del backend/SRI a la venta autorizada.',
      ],
    );
  }

  @override
  Future<Map<String, dynamic>> buildBridgeRequest(Venta venta) async {
    final draft = await buildInvoiceDraft(venta);
    return {
      'endpoint': draft.status.endpoint.toString(),
      'headers': draft.requestHeaders,
      'body': draft.payload,
      'commented': draft.transmissionCommented,
      'nextSteps': draft.nextSteps,
    };
  }

  @override
  Future<Map<String, dynamic>> sendInvoiceWhenEnabled(
    SriInvoiceDraft draft,
  ) async {
    // -----------------------------------------------------------------
    // CONEXIÓN REAL PENDIENTE DE ACTIVACIÓN
    //
    // Cuando el backend puente ya exista, descomentar el bloque siguiente
    // e importar `dart:convert` y `package:http/http.dart` as http.
    //
    // final response = await http.post(
    //   draft.status.endpoint,
    //   headers: draft.requestHeaders,
    //   body: jsonEncode(draft.payload),
    // );
    //
    // if (response.statusCode >= 200 && response.statusCode < 300) {
    //   return jsonDecode(response.body) as Map<String, dynamic>;
    // }
    //
    // throw Exception(
    //   'Error al enviar la factura al backend/SRI: ${response.body}',
    // );
    // -----------------------------------------------------------------

    return {
      'sent': false,
      'commented': true,
      'reference': draft.reference,
      'accessKey': draft.accessKey,
      'message':
          'La transmisión real al backend/SRI quedó preparada pero comentada por solicitud.',
    };
  }

  String _buildReference(Venta venta) {
    final y = venta.createdAt.year.toString();
    final m = venta.createdAt.month.toString().padLeft(2, '0');
    final d = venta.createdAt.day.toString().padLeft(2, '0');
    final suffix = venta.id.replaceAll('-', '').toUpperCase().substring(0, 8);
    return 'FAC-$y$m$d-$suffix';
  }

  String _buildAccessKey(
    Venta venta,
    FiscalConfig cfg,
    SriConnectionStatus status,
    String secuencial,
  ) {
    final fecha = DateFormat('ddMMyyyy').format(venta.createdAt);
    const docCode = '01'; // factura
    final ruc = _normalizeDigits(cfg.ruc, 13, fallback: '9999999999999');
    final establecimiento = _normalizeDigits(
      cfg.establecimiento,
      3,
      fallback: '001',
    );
    final puntoEmision = _normalizeDigits(cfg.puntoEmision, 3, fallback: '001');
    final codigoNumerico = _normalizeDigits(venta.id, 8, fallback: '12345678');
    const tipoEmision = '1';

    final base =
        '$fecha$docCode$ruc${status.environmentCode}$establecimiento$puntoEmision$secuencial$codigoNumerico$tipoEmision';
    return '$base${_modulo11(base)}';
  }

  String _buildXmlPreview({
    required Venta venta,
    required FiscalConfig cfg,
    required String accessKey,
    required String reference,
    required SriConnectionStatus status,
    required String secuencial,
  }) {
    final razonSocial = cfg.razonSocial.isNotEmpty
        ? cfg.razonSocial
        : AppConstants.appFullName;
    final nombreComercial = cfg.nombreComercial.isNotEmpty
        ? cfg.nombreComercial
        : razonSocial;
    final identificacion = venta.clienteIdentificacion ?? '9999999999999';
    final cliente = venta.clienteNombre ?? 'CONSUMIDOR FINAL';
    final fechaEmision = DateFormat('dd/MM/yyyy').format(venta.createdAt);
    final establecimiento = _normalizeDigits(
      cfg.establecimiento,
      3,
      fallback: '001',
    );
    final puntoEmision = _normalizeDigits(cfg.puntoEmision, 3, fallback: '001');
    final direccion = cfg.direccion.isNotEmpty
        ? cfg.direccion
        : 'Dirección no configurada';

    // IVA — derivado de los totales almacenados en la venta
    final ivaCodPct = _ivaCodigoPorcentaje(venta.impuestos, venta.subtotal);
    final ivaTarifa = _ivaTarifa(venta.impuestos, venta.subtotal);
    final baseImponible = venta.subtotal.toStringAsFixed(2);
    final valorIva = venta.impuestos.toStringAsFixed(2);

    final detallesXml = venta.detalles
        .map((detalle) {
          final descripcion = detalle.varianteNombre != null
              ? '${detalle.productoNombre ?? 'Producto'} (${detalle.varianteNombre})'
              : (detalle.productoNombre ?? 'Producto');
          // IVA proporcional por línea
          final lineaBase = detalle.subtotal.toStringAsFixed(2);
          final lineaIva = venta.subtotal > 0
              ? (detalle.subtotal * venta.impuestos / venta.subtotal)
                    .toStringAsFixed(2)
              : '0.00';
          return '''
    <detalle>
      <codigoPrincipal>${_xmlEscape(detalle.productoId)}</codigoPrincipal>
      <descripcion>${_xmlEscape(descripcion)}</descripcion>
      <cantidad>${detalle.cantidad}</cantidad>
      <precioUnitario>${detalle.precioUnitario.toStringAsFixed(6)}</precioUnitario>
      <descuento>0.00</descuento>
      <precioTotalSinImpuesto>$lineaBase</precioTotalSinImpuesto>
      <impuestos>
        <impuesto>
          <codigo>2</codigo>
          <codigoPorcentaje>$ivaCodPct</codigoPorcentaje>
          <tarifa>$ivaTarifa</tarifa>
          <baseImponible>$lineaBase</baseImponible>
          <valor>$lineaIva</valor>
        </impuesto>
      </impuestos>
    </detalle>''';
        })
        .join('\n');

    return '''<?xml version="1.0" encoding="UTF-8"?>
<factura id="comprobante" version="1.1.0">
  <infoTributaria>
    <ambiente>${status.environmentCode}</ambiente>
    <tipoEmision>1</tipoEmision>
    <razonSocial>${_xmlEscape(razonSocial)}</razonSocial>
    <nombreComercial>${_xmlEscape(nombreComercial)}</nombreComercial>
    <ruc>${_normalizeDigits(cfg.ruc, 13, fallback: '9999999999999')}</ruc>
    <claveAcceso>$accessKey</claveAcceso>
    <codDoc>01</codDoc>
    <estab>$establecimiento</estab>
    <ptoEmi>$puntoEmision</ptoEmi>
    <secuencial>$secuencial</secuencial>
    <dirMatriz>${_xmlEscape(direccion)}</dirMatriz>
  </infoTributaria>
  <infoFactura>
    <fechaEmision>$fechaEmision</fechaEmision>
    <dirEstablecimiento>${_xmlEscape(direccion)}</dirEstablecimiento>
    <tipoIdentificacionComprador>${_tipoIdentificacion(identificacion)}</tipoIdentificacionComprador>
    <razonSocialComprador>${_xmlEscape(cliente)}</razonSocialComprador>
    <identificacionComprador>${_xmlEscape(identificacion)}</identificacionComprador>
    <totalSinImpuestos>$baseImponible</totalSinImpuestos>
    <totalDescuento>0.00</totalDescuento>
    <totalConImpuestos>
      <totalImpuesto>
        <codigo>2</codigo>
        <codigoPorcentaje>$ivaCodPct</codigoPorcentaje>
        <baseImponible>$baseImponible</baseImponible>
        <valor>$valorIva</valor>
      </totalImpuesto>
    </totalConImpuestos>
    <propina>0.00</propina>
    <importeTotal>${venta.total.toStringAsFixed(2)}</importeTotal>
    <moneda>DOLAR</moneda>
    <pagos>
      <pago>
        <formaPago>${_formapagoCode(venta.metodoPago)}</formaPago>
        <total>${venta.total.toStringAsFixed(2)}</total>
      </pago>
    </pagos>
  </infoFactura>
  <detalles>
$detallesXml
  </detalles>
  <infoAdicional>
    <campoAdicional nombre="referenciaInterna">${_xmlEscape(reference)}</campoAdicional>
    <campoAdicional nombre="correo">${_xmlEscape(venta.clienteEmail ?? '')}</campoAdicional>
  </infoAdicional>
</factura>
''';
  }

  /// Código SRI de tipo de identificación del comprador.
  /// 04 = RUC, 05 = Cédula, 06 = Pasaporte, 07 = Consumidor Final.
  String _tipoIdentificacion(String identificacion) {
    if (identificacion == '9999999999999') return '07';
    if (identificacion.length == 13) return '04';
    if (identificacion.length == 10) return '05';
    return '06';
  }

  /// Código SRI de porcentaje de IVA derivado del monto almacenado.
  /// 0 = 0 %, 2 = 12 %, 3 = 13 %, 4 = 15 %.
  String _ivaCodigoPorcentaje(double impuestos, double subtotal) {
    if (impuestos == 0 || subtotal == 0) return '0';
    final rate = (impuestos / subtotal * 100).round();
    if (rate <= 1) return '0';
    if (rate <= 12) return '2';
    if (rate <= 13) return '3';
    return '4'; // 15 % — tarifa vigente en Ecuador desde 2024
  }

  /// Tarifa de IVA como cadena con dos decimales.
  String _ivaTarifa(double impuestos, double subtotal) {
    if (impuestos == 0 || subtotal == 0) return '0.00';
    final rate = (impuestos / subtotal * 100).round();
    if (rate <= 1) return '0.00';
    if (rate <= 12) return '12.00';
    if (rate <= 13) return '13.00';
    if (rate <= 14) return '14.00';
    return '15.00';
  }

  /// Código SRI de forma de pago.
  /// 01 = efectivo, 17 = transferencia, 19 = tarjeta de crédito.
  String _formapagoCode(MetodoPago m) => switch (m) {
    MetodoPago.efectivo => '01',
    MetodoPago.tarjeta => '19',
    MetodoPago.transferencia => '17',
  };

  String _resolveEnvironmentCode(String environment) {
    final env = environment.toLowerCase();
    return env.contains('prod') ? '2' : '1';
  }

  String _normalizeDigits(
    String? value,
    int length, {
    required String fallback,
  }) {
    final digits = _onlyDigits(value ?? '');
    final source = digits.isEmpty ? fallback : digits;
    final trimmed = source.length > length
        ? source.substring(source.length - length)
        : source;
    return trimmed.padLeft(length, '0');
  }

  String _onlyDigits(String value) => value.replaceAll(RegExp(r'[^0-9]'), '');

  int _modulo11(String input) {
    var factor = 2;
    var total = 0;

    for (var i = input.length - 1; i >= 0; i--) {
      total += int.parse(input[i]) * factor;
      factor = factor == 7 ? 2 : factor + 1;
    }

    final modulo = 11 - (total % 11);
    if (modulo == 11) return 0;
    if (modulo == 10) return 1;
    return modulo;
  }

  String _xmlEscape(String value) {
    return value
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');
  }
}
