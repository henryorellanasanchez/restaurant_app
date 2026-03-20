import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:restaurant_app/core/constants/app_constants.dart';
import 'package:restaurant_app/core/di/injection_container.dart';
import 'package:restaurant_app/features/cotizaciones/domain/entities/cotizacion.dart';
import 'package:restaurant_app/features/cotizaciones/domain/usecases/cotizacion_usecases.dart';

final cotizacionesProvider = FutureProvider.autoDispose<List<Cotizacion>>((
  ref,
) async {
  final result = await sl<GetCotizaciones>()(AppConstants.defaultRestaurantId);
  return result.fold((_) => <Cotizacion>[], (items) => items);
});
