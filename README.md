# RivalFit

App movil de ejercicio competitivo social con verificacion por IA anti-trampas.

La idea central: convertir el ejercicio diario en una competencia entre amigos.
Cada repeticion verificada suma puntos para una liga, alimenta el ranking
semanal y hace subir el rango personal. La verificacion con camara e IA sera
on-device (ML Kit), para que el conteo no dependa de trucos ni de datos
enviados a mano.

## Estado actual

RivalFit ya tiene la base de producto y autenticacion lista. Hoy se puede:

### Cuenta y perfil

- Registro e inicio de sesion con correo y contrasena.
- Recuperacion de contrasena con codigo OTP de 6 digitos enviado por correo.
- Auto-verificacion del codigo al abrir el enlace de recuperacion.
- Login social con Google y Facebook mediante OAuth PKCE. El boton de Apple
  esta preparado para iOS, pero su integracion sigue pendiente.
- Sesion persistente y restauracion automatica al abrir la app.
- Onboarding de perfil en 3 pasos: identidad, metricas base y nivel de
  entrenamiento.
- Nombre visible, alias, edad, peso, estatura, nivel y foto de perfil.
- Foto subida a Supabase Storage y perfil guardado en la base de datos.
- Opcion de omitir el perfil, con recordatorio en la siguiente sesion.

### Ligas

- Crear una liga con nombre, emblema/foto y una apuesta social opcional.
- Codigo de invitacion automatico de 6 caracteres.
- Unirse a una liga por codigo o por enlace de invitacion.
- Limite de 10 miembros validado en el backend.
- Invitacion por WhatsApp u otras apps, con enlace HTTPS y preview.
- Busqueda de rivales por alias o nombre para invitarlos.
- Ranking semanal con top 5 en la tarjeta de liga y clasificacion completa.
- Perfil de cada miembro, puntos semanales y salida voluntaria de la liga.
- Deep links para invitaciones, recuperacion de contrasena y callback OAuth.

### Navegacion y experiencia

- Onboarding inicial de 3 slides con video.
- Shell principal con 4 tabs: Entrenar, Liga, Progreso y Ajustes.
- Catalogo visual de ejercicios: lagartijas, sentadillas, abdominales, dips y
  cardio.
- Resumen semanal, racha y progreso por grupo muscular (estructura visual).
- Tema claro/oscuro con identidad visual propia.
- Cierre de sesion y manejo de errores de red/autenticacion con mensajes
  legibles.

### Base tecnica

- Backend Supabase self-hosted con Auth, PostgreSQL, Storage, Realtime y Edge
  Functions.
- Esquema inicial para usuarios, ligas, sesiones, retos, conexiones sociales y
  datos de smartwatch, con RLS y triggers de ligas.
- Android App Links para invitaciones HTTPS y scheme propio para OAuth/reset.
- Tests unitarios de auth, recuperacion, deep links y ligas.
- CI con `flutter analyze` y `flutter test` en cada push/PR a `main`.

## Lo que falta por construir

### Prioridad 1 - MVP de entrenamiento

- [ ] Pantalla de sesion de entrenamiento con camara.
- [ ] Deteccion de pose on-device con ML Kit para lagartijas, sentadillas,
  abdominales y dips.
- [ ] Conteo de repeticiones verificado y logica anti-trampas.
- [ ] Tutorial animado por ejercicio antes de la primera sesion.
- [ ] Guardar sesiones reales y calcular puntos semanales a partir de ellas.
- [ ] Reinicio semanal automatico de puntos.
- [ ] Conectar el resumen semanal, la racha y la clasificacion a datos reales.
- [ ] Retos 1v1 entre miembros de una liga.

### Prioridad 2 - Progreso y notificaciones

- [ ] Rango global real (Novato, Principiante, etc.) segun repeticiones.
- [ ] Progreso por grupo muscular (Bronce a Diamante) con datos reales.
- [ ] Insignias y logros desbloqueables.
- [ ] Edicion de perfil y metricas desde Ajustes.
- [ ] Nivel de actividad, idioma y preferencias de notificaciones.
- [ ] Push notifications con FCM HTTP v1.
- [ ] Login con Apple y credenciales OAuth de produccion para Google/Facebook.

### Prioridad 3 - Cardio y produccion

- [ ] Integracion con smartwatch para cardio (Wear OS / watchOS).
- [ ] Sincronizacion de datos de frecuencia cardiaca y sesiones de cardio.
- [ ] Despliegue de produccion en servidor Linux.
- [ ] Backups automaticos de la base de datos.
- [ ] SMTP real para correos transaccionales.
- [ ] Monitoreo, logs y endurecimiento de seguridad.
- [ ] Mas tests de integracion, widgets y flujos end-to-end.

## Stack

- **App:** Flutter + Dart
- **Estado:** Riverpod
- **Navegacion:** GoRouter
- **Backend:** Supabase self-hosted (PostgreSQL, Auth, Storage, Realtime, Edge
  Functions)
- **Deep links:** `app_links` + Android App Links
- **Media:** `image_picker`, `video_player`, Supabase Storage
- **UI:** Google Fonts, Flutter Animate, SVG
- **Compartir:** `share_plus`
- **Notificaciones:** FCM HTTP v1 (pendiente)

## Plataformas

Android 10+ / iOS 15+.

El paquete de la app es `com.rivalfit.rivalfit`, usado por los deep links de
OAuth y recuperacion.

## Arquitectura del proyecto

```
lib/
  app/          # Router, tema y widgets compartidos
  core/         # Deep links, errores y utilidades transversales
  features/
    auth/       # Login, signup, recuperacion, sesion y perfil
    profile/    # Onboarding de perfil en 3 pasos
    home/       # Shell principal y tabs Entrenar/Progreso/Ajustes
    league/     # Ligas, ranking, invitaciones y busqueda de rivales
    exercise/   # Catalogo de ejercicios y pantallas de sesion/tutorial
test/           # Tests unitarios y de widgets
```

El backend vive en una instancia Supabase self-hosted separada. Este repo
contiene el cliente Flutter; la configuracion de infraestructura, secretos y
documentos internos no se versiona aqui.

## Dev setup

La version de Flutter esta fijada con [FVM](https://fvm.app) en `.fvmrc`
(Flutter 3.47.1). No uses tu Flutter global.

1. Clona el repo:

   ```sh
   git clone https://github.com/Crisls24/rivalfit-app.git
   cd rivalfit-app
   ```

2. Instala la version fijada de Flutter:

   ```sh
   fvm install
   ```

3. Descarga las dependencias:

   ```sh
   fvm flutter pub get
   ```

4. Consigue la URL y la `anon key` de tu instancia de Supabase. Pide las
   credenciales de desarrollo al equipo o usa tu propia instancia local.

5. Corre la app con los `--dart-define`:

   ```powershell
   fvm flutter run --dart-define=SUPABASE_URL="<URL_DE_TU_SUPABASE>" --dart-define=SUPABASE_ANON_KEY="<ANON_KEY>"
   ```

Tambien puedes compilar un APK con los mismos valores:

```powershell
fvm flutter build apk --debug --dart-define=SUPABASE_URL="<URL_DE_TU_SUPABASE>" --dart-define=SUPABASE_ANON_KEY="<ANON_KEY>"
```

> Importante: los `--dart-define` se necesitan tanto en `run` como en
> `build apk`. Si compilas sin `SUPABASE_ANON_KEY`, el cliente envia una API key
> vacia, el gateway responde HTTP 401 en texto plano y la app muestra "No
> pudimos conectar con el servidor" en todos los flujos de Auth.

Para editar en VS Code instala las extensiones recomendadas
(`.vscode/extensions.json`). La configuracion de VS Code usa el SDK de FVM y
`.vscode/launch.json` te pedira la URL y la `anon key` al iniciar la sesion de
depuracion; no se guardan en el repositorio.

## Comandos utiles

```sh
fvm flutter analyze
fvm flutter test
fvm flutter run --dart-define=SUPABASE_URL="<URL_DE_TU_SUPABASE>" --dart-define=SUPABASE_ANON_KEY="<ANON_KEY>"
```

## CI

`.github/workflows/ci.yml` corre `flutter analyze` y `flutter test` en cada
push/PR a `main`, usando la version de Flutter fijada en `.fvmrc`.

## Seguridad y datos sensibles

- No versiones `.env`, tokens, contrasenas, `service_role` keys, secretos de
  OAuth, tokens de Cloudflare ni claves de service account de Firebase.
- La `anon key` es una clave publica de cliente, pero aun asi debe gestionarse
  por entorno y no reutilizarse entre desarrollo y produccion.
- Este README usa placeholders a proposito: no contiene credenciales reales.
- Los documentos internos, la infraestructura y los scripts quedan fuera del
  repositorio publico mediante `.gitignore`.
