# Runbook de Publicación - v1.0.1+2

Fecha: 2026-04-25
Sistema: La Peña Bar & Restaurant

## Objetivo
Publicar Android y Web de forma controlada, con validaciones previas, responsables claros y plan de rollback.

## Roles sugeridos
- Responsable técnico: validación final de build y configuración.
- Responsable de producto: aprobación funcional.
- Responsable de operación: comunicación interna y seguimiento post-release.

## Fase 1 - Pre-publicación
1. Confirmar versión en pubspec: 1.0.1+2.
2. Confirmar changelog actualizado.
3. Ejecutar validación automática:
   - flutter analyze
   - flutter test
4. Verificar artefactos:
   - AAB: build/app/outputs/bundle/release/app-release.aab
   - APK: build/app/outputs/flutter-apk/app-release.apk
   - Web: build/web
5. Ejecutar smoke test manual con el checklist de docs/release_smoke_checklist.md.
6. Respaldar keystore y key.properties en almacenamiento seguro.

## Fase 2 - Publicación Android
1. Subir app-release.aab a Play Console (track interno o producción según política).
2. Pegar notas de versión desde docs/release_notes_playstore_web.md.
3. Revisar advertencias de compatibilidad y permisos.
4. Publicar y registrar hora exacta de liberación.

## Fase 3 - Publicación Web
1. Desplegar contenido de build/web al hosting objetivo.
2. Invalidar caché CDN (si aplica).
3. Confirmar acceso público y carga de assets.
4. Ejecutar verificación rápida en:
   - Desktop (Chrome/Edge)
   - Móvil (Android y iOS)

## Fase 4 - Verificación post-release (30 a 60 min)
1. Login por rol: administrador, cajero, mesero.
2. Flujo operativo mínimo:
   - crear pedido,
   - avanzar en cocina,
   - cobrar en caja,
   - revisar reporte rápido,
   - validar sincronización.
3. Revisar errores críticos y comportamiento de navegación.

## Plan de rollback

### Android
1. Detener promoción a producción en Play Console o volver a la versión estable previa.
2. Comunicar a operación que la actualización queda pausada.

### Web
1. Revertir despliegue al build anterior estable.
2. Invalidar caché nuevamente.
3. Validar home, login y navegación principal.

## Criterio de éxito
- Sin errores bloqueantes en operación principal.
- Sin regresiones visibles en navegación y permisos por rol.
- Sin fallos críticos de sincronización o caja.

## Cierre
1. Crear tag de release en Git.
2. Compartir mensaje interno de versión liberada.
3. Registrar incidencias observadas para hotfix si aplica.
