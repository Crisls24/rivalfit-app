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

## Desarrollo

```sh
flutter pub get
flutter run
```

La URL de Supabase se configura por `--dart-define`:

```sh
flutter run --dart-define=SUPABASE_URL=https://fit-api.iscx.site \
  --dart-define=SUPABASE_ANON_KEY=<anon_key>
```