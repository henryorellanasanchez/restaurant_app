import 'package:flutter/foundation.dart';
import 'package:restaurant_app/core/constants/app_constants.dart';
import 'package:restaurant_app/core/di/injection_container.dart';
import 'package:restaurant_app/features/usuarios/domain/entities/usuario.dart';
import 'package:restaurant_app/features/usuarios/domain/usecases/usuario_usecases.dart';

/// Maneja la sesión activa del usuario autenticado.
///
/// Es un [ChangeNotifier] para que [GoRouter] pueda reaccionar a
/// cambios de sesión mediante [refreshListenable].
class AuthChangeNotifier extends ChangeNotifier {
  Usuario? _usuario;

  /// El usuario actualmente autenticado, o null si no hay sesión.
  Usuario? get usuario => _usuario;

  /// Verdadero si hay un usuario autenticado.
  bool get isAuthenticated => _usuario != null;

  /// Autentica al usuario mediante PIN de 4 dígitos.
  ///
  /// Retorna `null` en caso de éxito, o un mensaje de error.
  Future<String?> loginWithPin(String pin) async {
    final result = await sl<VerificarPin>()(
      AppConstants.defaultRestaurantId,
      pin,
    );
    return result.fold((failure) => failure.message, (usuario) {
      if (usuario == null || !usuario.activo) return 'PIN incorrecto';
      _usuario = usuario;
      notifyListeners();
      return null;
    });
  }

  /// Cierra la sesión actual.
  void logout() {
    _usuario = null;
    notifyListeners();
  }
}
