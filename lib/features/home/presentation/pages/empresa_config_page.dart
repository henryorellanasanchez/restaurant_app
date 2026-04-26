import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:restaurant_app/core/constants/app_constants.dart';
import 'package:restaurant_app/core/theme/app_colors.dart';
import 'package:restaurant_app/features/pagina_publica/domain/entities/public_config.dart';
import 'package:restaurant_app/features/pagina_publica/presentation/providers/public_config_provider.dart';

/// Página de configuración institucional del negocio.
///
/// Solo accesible para administradores desde el dashboard.
/// Centraliza los datos corporativos que rigen en todo el sistema:
/// logo, nombre, propietario, correos, teléfonos y otros datos relevantes.
class EmpresaConfigPage extends ConsumerStatefulWidget {
  const EmpresaConfigPage({super.key});

  @override
  ConsumerState<EmpresaConfigPage> createState() => _EmpresaConfigPageState();
}

class _EmpresaConfigPageState extends ConsumerState<EmpresaConfigPage> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nombreNegocioCtrl;
  late final TextEditingController _propietarioCtrl;
  late final TextEditingController _telefonoPrincipalCtrl;
  late final TextEditingController _telefonoSecundarioCtrl;
  late final TextEditingController _emailContactoCtrl;
  late final TextEditingController _emailSecundarioCtrl;
  late final TextEditingController _logoUrlCtrl;
  late final TextEditingController _direccionCtrl;
  late final TextEditingController _whatsappCtrl;

  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _nombreNegocioCtrl = TextEditingController();
    _propietarioCtrl = TextEditingController();
    _telefonoPrincipalCtrl = TextEditingController();
    _telefonoSecundarioCtrl = TextEditingController();
    _emailContactoCtrl = TextEditingController();
    _emailSecundarioCtrl = TextEditingController();
    _logoUrlCtrl = TextEditingController();
    _direccionCtrl = TextEditingController();
    _whatsappCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _nombreNegocioCtrl.dispose();
    _propietarioCtrl.dispose();
    _telefonoPrincipalCtrl.dispose();
    _telefonoSecundarioCtrl.dispose();
    _emailContactoCtrl.dispose();
    _emailSecundarioCtrl.dispose();
    _logoUrlCtrl.dispose();
    _direccionCtrl.dispose();
    _whatsappCtrl.dispose();
    super.dispose();
  }

  void _initFromConfig(PublicConfig config) {
    if (_initialized) return;
    _initialized = true;
    _nombreNegocioCtrl.text = config.nombreNegocio.isNotEmpty
        ? config.nombreNegocio
        : AppConstants.appFullName;
    _propietarioCtrl.text = config.propietario;
    _telefonoPrincipalCtrl.text = config.telefono.isNotEmpty
        ? config.telefono
        : AppConstants.contactPhone;
    _telefonoSecundarioCtrl.text = config.telefonoSecundario;
    _emailContactoCtrl.text = config.emailContacto.isNotEmpty
        ? config.emailContacto
        : AppConstants.contactEmail;
    _emailSecundarioCtrl.text = config.emailSecundario;
    _logoUrlCtrl.text = config.logoUrl;
    _direccionCtrl.text = config.direccion;
    _whatsappCtrl.text = config.whatsapp.isNotEmpty
        ? config.whatsapp
        : AppConstants.contactWhatsapp;
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    final current =
        ref.read(publicConfigProvider).config ??
        PublicConfig.defaults(AppConstants.defaultRestaurantId);

    final actualizado = current.copyWith(
      nombreNegocio: _nombreNegocioCtrl.text.trim(),
      propietario: _propietarioCtrl.text.trim(),
      telefono: _telefonoPrincipalCtrl.text.trim(),
      telefonoSecundario: _telefonoSecundarioCtrl.text.trim(),
      emailContacto: _emailContactoCtrl.text.trim(),
      emailSecundario: _emailSecundarioCtrl.text.trim(),
      logoUrl: _logoUrlCtrl.text.trim(),
      direccion: _direccionCtrl.text.trim(),
      whatsapp: _whatsappCtrl.text.trim(),
      updatedAt: DateTime.now(),
    );

    final ok = await ref.read(publicConfigProvider.notifier).save(actualizado);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? 'Información de la empresa guardada correctamente.'
              : ref.read(publicConfigProvider).error ?? 'Error al guardar',
        ),
        backgroundColor: ok ? AppColors.success : AppColors.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(publicConfigProvider);

    if (state.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (state.hasConfig && !_initialized) {
      _initFromConfig(state.config!);
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text('Información de la Empresa'),
        centerTitle: false,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // ── Encabezado descriptivo ────────────────────────────
            _InfoCard(
              icon: Icons.info_outline_rounded,
              message:
                  'Esta información se usa en todo el sistema: tickets, '
                  'reportes, documentos, encabezados y la página pública. '
                  'Mantenla actualizada.',
            ),
            const SizedBox(height: 20),

            // ── Logo ───────────────────────────────────────────────
            _Seccion(
              titulo: 'Logo del negocio',
              icono: Icons.image_rounded,
              children: [
                _Campo(
                  controller: _logoUrlCtrl,
                  label: 'URL del logo',
                  hint: 'https://... (enlace público a la imagen)',
                  icono: Icons.link_rounded,
                  keyboardType: TextInputType.url,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Pega la URL de una imagen pública (PNG o JPG). '
                  'El logo aparece en tickets, encabezados y reportes.',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
                // Vista previa del logo si hay URL válida
                _LogoPreview(url: _logoUrlCtrl.text),
              ],
            ),

            const SizedBox(height: 16),

            // ── Nombre y propietario ───────────────────────────────
            _Seccion(
              titulo: 'Datos del negocio',
              icono: Icons.business_rounded,
              children: [
                _Campo(
                  controller: _nombreNegocioCtrl,
                  label: 'Nombre del negocio *',
                  hint: 'La Peña Bar & Restaurant',
                  icono: Icons.store_rounded,
                  maxLength: 100,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'El nombre del negocio es requerido'
                      : null,
                ),
                const SizedBox(height: 14),
                _Campo(
                  controller: _propietarioCtrl,
                  label: 'Nombre del propietario',
                  hint: 'Nombre completo',
                  icono: Icons.person_rounded,
                  maxLength: 100,
                ),
                const SizedBox(height: 14),
                _Campo(
                  controller: _direccionCtrl,
                  label: 'Dirección del negocio',
                  hint: 'Calle, número, ciudad, provincia...',
                  icono: Icons.location_on_rounded,
                  maxLines: 2,
                ),
              ],
            ),

            const SizedBox(height: 16),

            // ── Teléfonos ──────────────────────────────────────────
            _Seccion(
              titulo: 'Teléfonos',
              icono: Icons.phone_rounded,
              children: [
                _Campo(
                  controller: _telefonoPrincipalCtrl,
                  label: 'Teléfono principal',
                  hint: '099 000 0000',
                  icono: Icons.phone_rounded,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 14),
                _Campo(
                  controller: _whatsappCtrl,
                  label: 'WhatsApp',
                  hint: '0994645989 (sin espacios ni guiones)',
                  icono: Icons.chat_rounded,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 14),
                _Campo(
                  controller: _telefonoSecundarioCtrl,
                  label: 'Teléfono secundario (opcional)',
                  hint: '02 000 0000',
                  icono: Icons.phone_forwarded_rounded,
                  keyboardType: TextInputType.phone,
                ),
              ],
            ),

            const SizedBox(height: 16),

            // ── Correos ────────────────────────────────────────────
            _Seccion(
              titulo: 'Correos electrónicos',
              icono: Icons.email_rounded,
              children: [
                _Campo(
                  controller: _emailContactoCtrl,
                  label: 'Correo principal',
                  hint: 'contacto@negocio.com',
                  icono: Icons.email_rounded,
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return null;
                    final r = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
                    if (!r.hasMatch(v.trim())) return 'Correo inválido';
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                _Campo(
                  controller: _emailSecundarioCtrl,
                  label: 'Correo secundario (opcional)',
                  hint: 'otro@negocio.com',
                  icono: Icons.alternate_email_rounded,
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return null;
                    final r = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
                    if (!r.hasMatch(v.trim())) return 'Correo inválido';
                    return null;
                  },
                ),
              ],
            ),

            const SizedBox(height: 24),

            // ── Botón guardar ──────────────────────────────────────
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: state.isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.save_rounded),
              label: Text(
                state.isSaving ? 'Guardando...' : 'Guardar información',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onPressed: state.isSaving ? null : _guardar,
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

// ── Widgets de apoyo ──────────────────────────────────────────────────────────

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String message;

  const _InfoCard({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.info.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.info.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.info, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Seccion extends StatelessWidget {
  final String titulo;
  final IconData icono;
  final List<Widget> children;

  const _Seccion({
    required this.titulo,
    required this.icono,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceVariant),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(
              children: [
                Icon(icono, size: 18, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  titulo,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 16),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }
}

class _Campo extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final IconData icono;
  final int maxLines;
  final int? maxLength;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  const _Campo({
    required this.controller,
    required this.label,
    required this.icono,
    this.hint,
    this.maxLines = 1,
    this.maxLength,
    this.keyboardType,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      maxLength: maxLength,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icono),
        border: const OutlineInputBorder(),
        isDense: false,
      ),
    );
  }
}

/// Vista previa del logo (se actualiza al guardar).
class _LogoPreview extends StatelessWidget {
  final String url;

  const _LogoPreview({required this.url});

  @override
  Widget build(BuildContext context) {
    if (url.trim().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Center(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.network(
            url.trim(),
            height: 90,
            errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            loadingBuilder: (_, child, progress) => progress == null
                ? child
                : const SizedBox(
                    height: 40,
                    child: Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
