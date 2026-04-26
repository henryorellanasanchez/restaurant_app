# Release Smoke Checklist

Fecha: 2026-04-25
Versión objetivo: 1.0.1+2

## 1. Validación automática
- [x] flutter analyze sin issues.
- [x] flutter test pasando.
- [x] Build Web release generado.
- [x] Build Android APK release generado.
- [x] Build Android AAB release generado.

## 2. Smoke test funcional (manual)

### Inicio de sesión y sesión
- [ ] Login con usuario administrador.
- [ ] Login con usuario cajero.
- [ ] Login con usuario mesero.
- [ ] Cerrar sesión y volver a entrar.

### Navegación y permisos
- [ ] Verificar menú lateral/móvil según rol.
- [ ] Confirmar que módulos restringidos no aparecen para roles sin permiso.
- [ ] Confirmar resaltado correcto de navegación en rutas hijas.

### Operación principal
- [ ] Mesas: crear, editar, reservar y liberar.
- [ ] Pedidos: crear pedido, agregar items, avanzar estados.
- [ ] Cocina: mover pedidos entre columnas y marcar items.
- [ ] Caja: cobrar pedido y verificar ticket.
- [ ] Reportes: cargar dashboard y exportes (si aplica).

### Sincronización y respaldo
- [ ] Sincronización: estado de nube conectado y ejecución manual.
- [ ] Validar mensaje de bloqueo cuando nube no esté disponible.
- [ ] Backup local: crear y restaurar.
- [ ] Backup Drive: iniciar sesión, subir y restaurar.

### Página pública y web
- [ ] Home pública visible en móvil y desktop.
- [ ] Menú público y reservas públicas funcionando.
- [ ] Enlaces externos (mapa/WhatsApp/teléfono) operativos.

## 3. Artefactos de salida
- APK release: build/app/outputs/flutter-apk/app-release.apk
- AAB release: build/app/outputs/bundle/release/app-release.aab
- Web release: build/web

## 4. Publicación
- [ ] Confirmar versión en pubspec: 1.0.1+2.
- [ ] Adjuntar changelog al despliegue.
- [ ] Respaldar keystore y key.properties de forma segura.
- [ ] Tag de release en Git.
