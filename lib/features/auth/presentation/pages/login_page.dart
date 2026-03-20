import 'package:flutter/material.dart';
import 'package:restaurant_app/core/di/injection_container.dart';
import 'package:restaurant_app/core/theme/app_colors.dart';
import 'package:restaurant_app/features/auth/presentation/providers/auth_provider.dart';

/// Pantalla de login mediante PIN de 4 dígitos.
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final List<String> _digits = [];
  bool _isLoading = false;
  String? _error;

  void _addDigit(String digit) {
    if (_digits.length >= 4 || _isLoading) return;
    setState(() {
      _digits.add(digit);
      _error = null;
    });
    if (_digits.length == 4) {
      _submit();
    }
  }

  void _removeDigit() {
    if (_digits.isEmpty || _isLoading) return;
    setState(() {
      _digits.removeLast();
      _error = null;
    });
  }

  Future<void> _submit() async {
    setState(() => _isLoading = true);
    final pin = _digits.join();
    final error = await sl<AuthChangeNotifier>().loginWithPin(pin);
    if (!mounted) return;
    if (error != null) {
      setState(() {
        _isLoading = false;
        _digits.clear();
        _error = error;
      });
    }
    // Si error == null (éxito), GoRouter redirige automáticamente.
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth >= 600;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: isWide ? 420 : double.infinity),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // ── Logo ──────────────────────────────────────────
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.asset(
                    'assets/images/logo_la_pena.jpg',
                    width: 100,
                    height: 100,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => Icon(
                      Icons.restaurant_rounded,
                      color: AppColors.primary,
                      size: 64,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'La Peña',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Bar & Restaurant',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: AppColors.secondary),
                ),
                const SizedBox(height: 40),
                Text(
                  'Ingresa tu PIN',
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(color: Colors.black87),
                ),
                const SizedBox(height: 20),

                // ── Indicadores de dígitos ─────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(4, (i) {
                    final filled = i < _digits.length;
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 10),
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: filled ? AppColors.primary : Colors.transparent,
                        border: Border.all(
                          color: _error != null
                              ? AppColors.error
                              : AppColors.primary,
                          width: 2,
                        ),
                      ),
                    );
                  }),
                ),

                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _error!,
                    style: TextStyle(color: AppColors.error, fontSize: 13),
                  ),
                ],

                const SizedBox(height: 32),

                // ── Teclado numérico ───────────────────────────────
                if (_isLoading)
                  const CircularProgressIndicator()
                else
                  _PinKeyboard(onDigit: _addDigit, onDelete: _removeDigit),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PinKeyboard extends StatelessWidget {
  final void Function(String) onDigit;
  final VoidCallback onDelete;

  const _PinKeyboard({required this.onDigit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    const digits = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
    ];

    return Column(
      children: [
        for (final row in digits)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: row
                .map((d) => _KeyButton(label: d, onTap: () => onDigit(d)))
                .toList(),
          ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(width: 80, height: 72),
            _KeyButton(label: '0', onTap: () => onDigit('0')),
            SizedBox(
              width: 80,
              height: 72,
              child: IconButton(
                icon: const Icon(Icons.backspace_outlined),
                color: AppColors.secondary,
                iconSize: 26,
                onPressed: onDelete,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _KeyButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _KeyButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 80,
      height: 72,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w500),
          ),
        ),
      ),
    );
  }
}
