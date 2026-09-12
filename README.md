# RivalFit

App de ejercicio competitivo social con verificacion IA anti-trampas.

Convierte el ejercicio diario en una competencia entre amigos: rankings
semanales, desafios 1v1 y verificacion de repeticiones por vision
artificial on-device (anti-trampas), con soporte de smartwatch (Wear OS /
watchOS) para ejercicios de cardio.

## Stack

- **Frontend:** Flutter (Dart) — Riverpod, GoRouter, Supabase Flutter SDK
- **Backend:** Supabase self-hosted (PostgreSQL, Auth, Realtime, Edge Functions)
- **Notificaciones:** FCM HTTP v1

## Plataformas

Android 10+ / iOS 15+.

## Dev setup

La version de Flutter esta fijada por proyecto con [FVM](https://fvm.app)
(ver `.fvm/fvm_config.json`). No uses tu Flutter global.

1. Clona el repo:

   ```sh
   git clone https://github.com/Crisls24/rivalfit-app.git
   cd rivalfit-app
   ```

2. Instala la version de Flutter fijada (descarga el SDK al cache de FVM):

   ```sh
   fvm install
   ```

3. Descarga las dependencias del proyecto:

   ```sh
   fvm flutter pub get
   ```

4. Corre la app (los `--dart-define` configuran Supabase):

   ```sh
   fvm flutter run --dart-define=SUPABASE_URL=https://fit-api.iscx.site \
     --dart-define=SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJyb2xlIjoiYW5vbiIsImlzcyI6InN1cGFiYXNlIiwiaWF0IjoxNzg3NTQ3NTkzLCJleHAiOjE5NDUyMjc1OTN9.aBEIQEPBw-Q8cPlb4BY2PHLyiiJW-ZPOAh2D3NdnUWA
   ```

Para editar en VS Code: instala las extensiones recomendadas (`.vscode/extensions.json`),
que usan el SDK de `.fvm/flutter_sdk` y el launch config ya incluye los `--dart-define`.

## CI

`.github/workflows/ci.yml` corre `flutter analyze` y `flutter test` en cada push/PR a `main`
usando la version de Flutter fijada en `.fvm/fvm_config.json`.