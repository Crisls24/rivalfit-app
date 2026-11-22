# Entrenamiento verificado: plan de implementación

Fecha: 18 de noviembre de 2026.

Objetivo: completar una sesión de sentadillas, conservarla sin duplicados y reflejar sus resultados en Mi progreso y Liga. El resto de ejercicios se incorpora después de validar este recorrido.

## Entregas y criterios de aceptación

| Entrega | Alcance | Se considera terminada cuando |
| --- | --- | --- |
| 1. Reglas y contratos | Estados de sesión, datos, reglas de conteo e integración | El recorrido y sus responsabilidades están definidos; se identifican las dependencias pendientes del servidor. |
| 2. Flujo de entrenamiento | Preparación, sesión y resumen; controlador independiente de la cámara | Iniciar, pausar, continuar, terminar y salir tienen estados claros; los datos simulados se limitan a desarrollo. |
| 3. Cámara y postura | Permisos, vista previa y detección local | El dispositivo muestra una postura válida y permite recuperarse de permisos denegados, pérdida de postura y cambios de ciclo de vida. |
| 4. Conteo de sentadillas | Máquina de estados del movimiento | Cada ciclo completo suma una vez; una pausa, postura incompleta o pérdida de detección no genera repeticiones. |
| 5. Guardado fiable | Persistencia local, sincronización y confirmación del servidor | Cerrar y reabrir conserva sesiones pendientes; reintentar una petición no duplica sesiones ni puntos. |
| 6. Progreso y Liga | Totales reales, rangos, insignias y clasificación semanal | Una sesión confirmada actualiza las vistas correspondientes una sola vez y conserva el historial. |
| 7. Validación de beta | Pruebas del recorrido, precisión y rendimiento en teléfono | Hay evidencia de funcionamiento en el dispositivo, errores recuperables y limitaciones documentadas. |

Cada entrega incluye implementación, comprobaciones apropiadas y una revisión del resultado antes de ampliar el alcance. No se considera terminada una integración que solo tiene interfaz.

## Entrega 1: especificación funcional y técnica

Estado: documento autorizado para iniciar la implementación. Las decisiones competitivas pendientes se enumeran expresamente más adelante y conservan su carácter de propuesta hasta resolverse.

### Alcance y resultado esperado

El usuario entra a Sentadillas desde Entrenar, prepara la cámara, inicia una sesión, recibe indicaciones, puede pausar y termina viendo un resumen fiable. Su resultado se conserva localmente y, una vez confirmado por el servidor, alimenta Progreso y la Liga que corresponda.

Quedan fuera de este recorrido inicial: otros contadores de ejercicios, relojes, cardio, duelos, nuevos bonos, edición manual de repeticiones y clasificación pública global. La estructura debe permitir ampliar ejercicios sin duplicar el flujo de sesión.

### Reglas iniciales

- Primer ejercicio: `sentadillas`, vinculado al grupo existente `MuscleGroup.legs`.
- Sesión libre, sin límite de tiempo; el usuario decide cuándo terminar.
- Una repetición válida requiere partir de la postura inicial, completar el descenso y regresar a la postura inicial. Los umbrales se calibran en la entrega 4 con evidencia del teléfono.
- Pausar o perder los puntos corporales necesarios descarta el ciclo incompleto. Continuar exige recuperar la postura inicial.
- El tiempo activo excluye pausas. La duración transcurrida y el tiempo activo son conceptos separados.
- Una repetición confirmada aporta una repetición global, una de piernas y un punto de Liga cuando corresponda. No se incluyen multiplicadores ni bonos en esta primera versión.
- La sesión puede terminar sin conexión y quedar pendiente. Los puntos competitivos solo se muestran como confirmados tras la aceptación del servidor.
- Una sesión sin repeticiones puede descartarse sin generar puntos ni desbloquear trofeos.
- El vídeo y los fotogramas no se suben al servidor.

### Estados del recorrido

| Estado | Comportamiento |
| --- | --- |
| Preparación | Explica colocación, solicita permisos y comprueba postura antes de iniciar. |
| Activa | Cuenta ciclos válidos y tiempo activo; muestra una indicación breve de corrección. |
| Pausada | Detiene conteo y tiempo activo; requiere recuperar postura al continuar. |
| Resumen | Muestra repeticiones, tiempo y estado de guardado. La sesión ya no cambia. |
| Pendiente de sincronizar | Conserva el resultado local y permite reintentar. |
| Confirmada | Usa la respuesta del servidor para progreso y puntos. |
| Rechazada | Conserva el resultado local y comunica el motivo; no concede puntos. |

Salir con una sesión activa exige elegir entre continuar, terminar o descartar. Al enviar la aplicación al fondo se pausa; no se cuenta mientras la cámara no está activa.

### Contrato de datos propuesto

Este contrato describe responsabilidades; no presupone que estas columnas ya existan en Supabase.

| Dato | Responsabilidad |
| --- | --- |
| Identificador de sesión | Se genera una vez al iniciar y se reutiliza en todos los reintentos. |
| Usuario | Se vincula localmente al propietario; el servidor obtiene la identidad desde la autenticación. |
| Ejercicio y versión de reglas | Permiten interpretar el resultado sin depender de reglas futuras. |
| Inicio y fin en UTC | Permiten conservar historial y resolver periodos semanales. |
| Tiempo activo | Se acumula solo durante entrenamiento activo. |
| Repeticiones válidas | Resultado del contador local; se valida en el servidor antes de acreditar puntos. |
| Origen | Detección con cámara; no mezclar con registros manuales o futuros relojes. |
| Estado de sincronización | Metadato local, separado del resultado deportivo. |
| Confirmación | El servidor devuelve el identificador aceptado y el resultado de acreditación. |

El identificador debe ser único en el servidor. La inserción y la acreditación de puntos deben formar una transacción: dos peticiones para la misma sesión producen una sola acreditación. El cliente no actualiza directamente `weekly_points`.

La detección local no constituye por sí sola una prueba contra manipulación. La primera beta debe declarar esta limitación; las comprobaciones de coherencia del servidor no equivalen a validar vídeo.

### Integración con la base actual

| Componente existente | Integración prevista |
| --- | --- |
| `lib/features/exercise/domain/models/exercise.dart` | Reutilizar identificadores de ejercicio y grupos musculares. |
| `lib/features/home/presentation/tabs/progress_view.dart` | Sustituir los valores iniciales por progreso confirmado, conservando mapa, rango e insignias. |
| `lib/features/league/data/datasources/league_supabase_data_source.dart` | Seguir leyendo clasificación; la escritura de puntos pertenece al servidor. |
| `infra/sql/league_identity.sql` | Solo documenta identidad de ligas; no sirve como esquema de sesiones. |

### Dependencias que deben resolverse antes de publicar la integración

1. Obtener el esquema real de sesiones, usuarios, políticas RLS y mecanismos actuales de puntos para escribir una migración compatible. No ejecutar SQL deducido del PRD.
2. Usar un corte semanal común para todas las ligas, el lunes a las 00:00 en la zona `America/Mexico_City`.
3. Definir la pertenencia aplicable a una sesión: el servidor debe impedir que cambiar de Liga o sincronizar tarde duplique la acreditación. Una sesión pendiente nunca se asigna automáticamente a la nueva Liga del usuario.
4. Definir el tratamiento de sincronizaciones tardías antes de publicar ganadores semanales. La hora enviada por el teléfono no es una fuente fiable por sí sola.
5. Centralizar umbrales de rangos y condiciones de trofeos antes de la entrega 6. No inventar nuevos umbrales desde los widgets.

## Siguiente trabajo: entrega 2

Implementar el controlador y las pantallas de preparación, sesión y resumen detrás del acceso actual a sentadillas. Mantener separadas la presentación, la fuente de postura, el contador y el guardado. La simulación solo permite revisar el flujo durante desarrollo y no acredita progreso ni puntos.

Comprobar transiciones, pausa al ir al fondo, descarte y finalización única. La cámara real, el conteo y la sincronización se conectan en sus entregas respectivas.

## Especificación de pantallas

| Pantalla | Contenido y acciones | Condiciones y errores |
| --- | --- | --- |
| Preparación | Nombre del ejercicio, explicación corta de colocación, vista previa, estado de detección e Iniciar | Iniciar permanece deshabilitado sin permiso, cámara lista y postura inicial estable. Si el permiso está bloqueado, ofrecer Abrir ajustes. |
| Entrenamiento | Cámara como elemento principal, contador grande, tiempo activo, una indicación breve, Pausar y Terminar | No mostrar varias correcciones a la vez. La pérdida de postura suspende el conteo y muestra cómo recuperarla. |
| Pausa | Contador conservado, Continuar, Terminar y Descartar | Continuar pasa primero por la recuperación de postura; no suma durante esa preparación. Descartar solicita confirmación si hay repeticiones. |
| Resumen | Repeticiones, tiempo activo, estado de guardado y Volver a Entrenar | Separar resultado local de progreso confirmado. Si no hay repeticiones, explicar que no se generaron puntos. |
| Sincronización pendiente | Resultado conservado y mensaje Guardado en este teléfono; pendiente de sincronizar | Permitir salir y reintentar. Un fallo de red no convierte la sesión en rechazada. |

La pantalla no promete puntos, rangos ni trofeos obtenidos antes de recibir la confirmación correspondiente. El resumen muestra resultados reales; no incluye cifras de ejemplo en producción.

### Criterios visuales y de interacción

- Conservar tipografía, colores y componentes de RivalFit. El verde identifica la acción principal y el estado activo.
- Priorizar contador y corrección durante el ejercicio; reservar rangos e insignias para el resumen y Mi progreso.
- Evitar cuadros de texto y teclado durante entrenamiento. Los controles deben tener etiquetas claras y áreas táctiles accesibles.
- No depender únicamente del color para expresar postura válida, pausa o error.
- Adaptar el contenido a pantallas pequeñas, áreas seguras y tamaño de texto del sistema.
- No reconstruir toda la vista de cámara por cada actualización de tiempo o contador. Las animaciones no deben bloquear las acciones.

## Modelo de estados para implementación

Separar el estado del entrenamiento del estado de sincronización. Una sesión terminada puede estar pendiente o confirmada sin volver a estar activa.

| Estado de entrenamiento | Evento | Resultado |
| --- | --- | --- |
| Preparación | Iniciar con postura estable | Crear identificador y pasar a activa. |
| Activa | Ciclo válido completo | Incrementar una repetición y esperar otro ciclo completo. |
| Activa | Pérdida de detección | Suspender conteo y tiempo activo; descartar ciclo parcial y esperar postura estable. |
| Recuperando postura | Postura estable | Reanudar solo si el usuario no había pausado. |
| Activa o recuperando postura | Pausar o aplicación al fondo | Pasar a pausada y descartar ciclo parcial. |
| Pausada | Continuar | Recuperar postura antes de reactivar conteo y tiempo. |
| Activa, recuperando postura o pausada | Terminar | Detener cámara y reloj; congelar resultado y persistir antes de mostrar guardado exitoso. |
| Activa o pausada | Descartar confirmado | Detener recursos y salir sin acreditar resultado. |
| Terminada | Terminar repetido | No producir otra sesión ni otra escritura. |

Los periodos sin detección se excluyen del tiempo activo. El reloj se calcula con tiempo monotónico durante la ejecución, no contando intervalos de animación; las fechas UTC sirven para el registro. No se reanuda automáticamente después de volver del fondo.

Un fallo al persistir localmente mantiene el resumen con una acción Reintentar guardado y un aviso explícito. No se debe mostrar Guardado hasta que la escritura haya terminado.

## Contrato técnico de referencia

Los nombres siguientes son el contrato propuesto del dominio. Su correspondencia con tablas y RPC se definirá al consultar el esquema real.

| Campo | Tipo lógico | Validación |
| --- | --- | --- |
| `sessionId` | UUID | Inmutable desde el inicio; clave de idempotencia. |
| `ownerUserId` | UUID | Debe coincidir con el usuario autenticado al sincronizar. |
| `exerciseId` | Identificador del catálogo | Primera versión: `sentadillas`. |
| `rulesVersion` | Cadena versionada | El servidor debe reconocerla o rechazarla expresamente. |
| `source` | Enumeración | Primera versión: `camera`. |
| `startedAtUtc`, `endedAtUtc` | Instantes UTC | Fin no anterior al inicio; comprobar coherencia temporal. |
| `activeDurationMs` | Entero | No negativo; no superior a la duración transcurrida. |
| `validReps` | Entero | No negativo; límites de coherencia definidos con la calibración. |
| `leagueContext` | Identidad de pertenencia, opcional | Contexto a validar por el servidor; nunca confiar en una Liga arbitraria enviada por el cliente. |

Metadatos locales separados: estado de guardado/sincronización, número de intentos, último error, próxima oportunidad de reintento y confirmación recibida. No incluir imágenes ni puntos corporales en el contrato remoto inicial.

La respuesta de aceptación debe identificar la sesión y devolver repeticiones acreditadas, puntos acreditados, Liga y periodo aplicables cuando existan. El reenvío de un identificador aceptado devuelve su resultado anterior. Reutilizar el mismo identificador con contenido deportivo diferente debe producir un conflicto, no modificar el resultado acreditado.

### Persistencia y recuperación

- Persistir el resultado terminado antes de intentar enviarlo. Guardar borradores activos periódicamente y al pausar; no escribir en disco por cada fotograma.
- Si el proceso se cierra durante una sesión, recuperar el borrador como interrumpido. No reanudar el reloj ni sumar tiempo mientras la app estuvo cerrada. Permitir terminar con lo conservado o descartar.
- Una sesión pendiente pertenece a su cuenta original. Al cerrar sesión, detener envíos; otra cuenta no puede verla ni sincronizarla como propia.
- Reintentar con espera progresiva y límite de frecuencia. Si la respuesta se pierde después de guardar en el servidor, reutilizar el mismo identificador.
- No borrar el resultado pendiente por un error temporal. La retención y eliminación asociadas al borrado de cuenta se definen junto con la implementación de almacenamiento.

## Separación de responsabilidades

| Pieza | Responsabilidad | No debe asumir |
| --- | --- | --- |
| Presentación | Mostrar estados y enviar acciones del usuario | Consultas directas de puntos o reglas de conteo en widgets. |
| Controlador de sesión | Transiciones, tiempo y finalización única | Detalles de cámara o consultas SQL. |
| Fuente de postura | Entregar observaciones corporales y disponibilidad | Decidir rangos, puntos o guardado. |
| Contador de sentadillas | Interpretar ciclos completos de observaciones | Acceso a interfaz, autenticación o red. |
| Repositorio de sesiones | Borradores, resultados y cola de sincronización | Modificar contadores deportivos desde la interfaz. |
| Servidor | Identidad, validaciones, idempotencia y acreditación atómica | Confiar en puntos calculados libremente por el cliente. |
| Progreso y Liga | Leer resultados confirmados y refrescar sus estados | Sumar otra vez el resultado al reconstruir una pantalla. |

Las interfaces concretas y la ubicación de clases se ajustarán a los patrones ya existentes. No introducir una segunda solución de estado o navegación.

## Casos de aceptación verificables

| Caso | Resultado esperado | Entrega que lo verifica |
| --- | --- | --- |
| Permiso denegado o cámara no disponible | Explicación y recuperación; no permite iniciar. | 3 |
| Descenso y regreso válidos | Exactamente una repetición. | 4 |
| Movimiento parcial o ruido de detección | No suma. | 4 |
| Pausa o pérdida de postura a mitad de ciclo | Descarta parcial; exige nueva postura inicial. | 4 |
| Aplicación al fondo y regreso | Pausada; no suma tiempo ni repeticiones en segundo plano. | 2 y 3 |
| Pulsar Terminar varias veces | Un resultado local y una identidad de sesión. | 2 y 5 |
| Sin conexión al finalizar | Resultado persistido y estado pendiente visible. | 5 |
| Cierre del proceso con resultado pendiente | Se recupera tras abrir con la misma cuenta. | 5 |
| Cierre del proceso durante entrenamiento | Borrador interrumpido; no continúa contando. | 5 |
| Servidor acepta y se pierde la respuesta | Reintento devuelve aceptación anterior, sin duplicar. | 5 |
| Cambio de cuenta con sesiones pendientes | Ninguna sesión se atribuye a la cuenta nueva. | 5 |
| Sesión aceptada sin pertenencia competitiva válida | Progreso personal confirmado; no inventa puntos de Liga. | 6 |
| Volver a abrir Progreso o Liga | No vuelve a acreditar la sesión. | 6 |
| Sesión con cero repeticiones | No genera puntos ni premios. | 5 y 6 |
| Error de almacenamiento local | Mensaje de error y reintento; no afirma que se guardó. | 5 |

## Decisiones pendientes y momento de resolución

| Decisión | Propuesta | Debe resolverse antes de |
| --- | --- | --- |
| Cámara, orientación y colocación | Elegir una configuración inicial mediante prueba en teléfono; documentarla en Preparación. | Entrega 3 |
| Motor de postura | Evaluar compatibilidad, latencia y tamaño en el dispositivo antes de fijar dependencia. | Entrega 3 |
| Umbrales y estabilidad de postura | Calibrar con ciclos válidos, parciales y pérdida de articulaciones; versionar reglas. | Entrega 4 |
| Esquema y RPC de sesiones | Inspeccionar backend real y preparar migración revisable. | Entrega 5 |
| Cierre y zona semanal | Lunes a las 00:00 en `America/Mexico_City` (confirmado). | Entrega 6 |
| Pertenencia y envíos tardíos | Validar contexto original; no transferir puntos entre ligas; fijar política de cierre. | Entrega 6 |
| Rangos e insignias | Unificar reglas existentes; conservar sorpresa de trofeos no obtenidos. | Entrega 6 |

## Cierre documental de la entrega 1

Incluye alcance, pantallas, estados, contrato propuesto, responsabilidades, recuperación y criterios de aceptación. No modifica lógica de producción, dependencias ni base de datos. No acredita haber medido precisión o rendimiento.

La entrega 2 puede construirse contra estos contratos sin conexión competitiva. Las decisiones señaladas como pendientes bloquean su integración correspondiente, no deben resolverse con valores ficticios en producción.

## Avance de la entrega 2

Implementado el recorrido de preparación, entrenamiento, pausa y resumen de sentadillas en `/session` y `/exercise/sentadillas`, con controlador independiente de cámara y red. El reloj usa `Stopwatch`; al salir al fondo se pausa y al continuar exige recuperar postura. La salida durante una sesión ofrece conservar la pausa, descartar o terminar. Finalizar repetidamente conserva un solo resultado en memoria.

La versión inicial permitió simular postura y repeticiones solo en desarrollo. Al integrar la entrega 3 se retiraron esos controles de la pantalla y se conectó la preparación a la cámara Android. Iniciar depende de la postura inicial estable; desde la entrega 4 el contador recibe ciclos del detector. No hay escrituras de sesiones ni de puntos.

La recuperación de borradores, persistencia del identificador y sincronización corresponden a la entrega 5. Cámara, permisos y detección corresponden a la entrega 3. Falta revisar visualmente el flujo en el teléfono antes de dar la entrega 2 por validada.

### Base de dominio implementada (entrega 1)

`lib/features/exercise/domain/models/training_session.dart` incorpora las reglas versionadas, el origen cámara/simulación, los estados de sincronización y el resultado inmutable. El resultado valida fechas, duración y repeticiones. Las sesiones simuladas y las vacías quedan excluidas del envío competitivo mediante el contrato de elegibilidad, que el futuro adaptador deberá respetar.

El controlador genera un UUID v4 una sola vez al iniciar y conserva la misma identidad al pausar, continuar y terminar. Finalizar congela el resultado; las llamadas posteriores no lo reemplazan. Esta identidad aún vive en memoria: no equivale a persistencia ni a idempotencia del servidor.

El reloj solo notifica la interfaz durante actividad. Al pausar, perder postura o terminar se detiene el temporizador visual. El contrato conserva el origen simulado para pruebas aisladas; la pantalla utiliza origen cámara desde la entrega 3. Ningún camino actual escribe puntos o progreso.

Se agregaron pruebas para identidad, finalización única, recuperación de postura, validación del resultado y exclusión de simulaciones. La validación de interfaz y ciclo de vida en el teléfono sigue pendiente; el estado documental no sustituye esa comprobación.

## Entrega 3: cámara y preparación de postura (solo Android)

Por indicación del usuario, iOS queda fuera de esta entrega. No se modifican sus permisos, versión mínima ni proyecto Xcode.

Integración escrita:

- Cámara frontal cuando existe; alternativa a otra cámara disponible. Vista previa y captura de imágenes en memoria sin audio ni grabación.
- Adaptador Android Camera2 con formato NV21 y detector de postura ML Kit en modo continuo.
- Un fotograma en procesamiento como máximo y separación mínima de 150 ms entre solicitudes; descartar fotogramas adicionales en lugar de acumularlos.
- Preparación basada en visibilidad y confianza de hombros, cadera, rodillas y tobillos. La postura inicial requiere piernas extendidas durante 700 ms. Son valores iniciales de preparación, no criterios calibrados de repetición ni garantías de precisión.
- Pérdida de postura o ausencia de resultados durante más de un segundo suspende el conteo y exige recuperar la posición inicial. Durante la actividad, doblar las rodillas no se interpreta por sí solo como pérdida de visibilidad.
- Errores y permisos denegados tienen mensaje y recuperación; Abrir ajustes usa un canal Android para los permisos de RivalFit.
- Pausa, finalización y salida al fondo liberan la cámara. Al volver no se reanuda automáticamente una sesión pausada.

Dependencias nuevas: `camera`, `camera_android` y `google_mlkit_pose_detection` (0.14.1). Android requiere API 24 como mínimo para la versión seleccionada de cámara. Se eligió la implementación Camera2 explícitamente para el flujo NV21. Referencias de integración: [camera](https://pub.dev/packages/camera), [camera_android](https://pub.dev/packages/camera_android) y [ML Kit 0.14.1](https://pub.dev/packages/google_mlkit_pose_detection/versions/0.14.1).

Estado de verificación: el usuario ejecutó `pub get` correctamente y se actualizó `pubspec.lock` con los paquetes nuevos. Se comprobó el registro Android de Camera2 y se contrastaron sus formatos de imagen con el código instalado. La compilación desde el entorno del asistente se detuvo antes de compilar por acceso denegado al archivo de bloqueo de la caché de Gradle del usuario. La compilación y el funcionamiento en el teléfono siguen pendientes: no se declara esta entrega validada.

Para continuar, reconstruir desde la terminal normal con `.\.fvm\flutter_sdk\bin\flutter.bat run`. Las dependencias de Dart ya se descargaron; Gradle puede necesitar descargar los componentes Android del detector. Hot reload no incorpora los plugins nativos nuevos.

Antes de cerrar la entrega, comprobar: permiso aceptado/denegado, regreso de Ajustes, cuerpo fuera del cuadro, postura estable, pausa/continuación, salida al fondo durante inicialización y salida de la pantalla con detector trabajando. El conteo real sigue reservado a la entrega 4 y el guardado a la entrega 5.

## Entrega 4: contador de sentadillas conectado

El detector entrega observaciones de ángulos de rodilla y visibilidad a un contador Dart independiente de Flutter, cámara y red. Cada observación procesada llega al contador, aunque el mensaje visible no cambie. El controlador de sesión solo acepta resultados mientras está activo; pausa, finalización y pérdida de postura descartan el ciclo parcial. El resultado final incluye las repeticiones contadas en memoria.

Secuencia: postura erguida estable → descenso → profundidad estable → regreso erguido estable → una repetición. Mantenerse de pie o en el punto inferior no añade repeticiones. Volver arriba sin confirmar profundidad no suma. Después de una interrupción se exige empezar desde la postura inicial.

Parámetros iniciales centralizados en `SquatSessionRules`:

| Parámetro | Valor inicial |
| --- | --- |
| Postura erguida | Ambas rodillas con ángulo proyectado de al menos 160° |
| Inicio de descenso | Ambas rodillas por debajo de 145° |
| Profundidad del ciclo | Ambas rodillas con ángulo proyectado de 105° o menos |
| Estabilidad arriba | 250 ms |
| Estabilidad en profundidad | 150 ms |
| Mínimo desde inicio del descenso hasta confirmación del regreso | 600 ms |
| Caducidad del ciclo | 15 s |
| Separación máxima entre observaciones | 700 ms; superarla descarta el ciclo |
| Diferencia máxima entre ángulos de piernas | 35°; superarla exige preparar otro ciclo |

Los ángulos son proyecciones 2D, no medidas clínicas ni una validación completa de técnica. Su utilidad depende de la posición del teléfono y la visibilidad. La preparación pide dejar el teléfono estable y girarse ligeramente de lado para hacer visible la flexión, conservando ambas piernas dentro del cuadro. Estos parámetros requieren calibración con el teléfono y pueden generar falsos negativos; no se afirma precisión ni protección completa contra manipulación.

La indicación visible durante la actividad procede de la fase del contador. La cámara conserva las instrucciones de colocación durante la preparación o recuperación. Las observaciones no se guardan ni se envían al servidor.

Verificación realizada: comprobaciones ejecutables de Dart para ciclos completos, dos ciclos consecutivos, descensos parciales, profundidad aislada, huecos de detección, pérdida de visibilidad y reinicio. Se agregaron pruebas de Flutter para contador e integración con pausa/finalización; su ejecución en este entorno se bloqueó antes de cargarlas por el socket local (error 10057). Falta ejecutar esas pruebas en la terminal normal y calibrar con movimientos reales antes de cerrar esta entrega.

El guardado persistente y los reintentos se incorporan en la entrega 5 descrita a continuación. La actualización de Progreso/Liga permanece en la entrega 6.

## Entrega 5: persistencia local y sincronización

### Implementado en la app

- Resultado final guardado antes de mostrar el estado de guardado exitoso. Ante error de escritura se ofrece Reintentar guardado y se avisa antes de salir sin conservarlo.
- Borrador al iniciar, cambiar de fase y cada cinco segundos de actividad. Tras un cierre inesperado se recupera el último punto guardado: no se inventa tiempo ni se continúa contando durante el cierre. Puede faltar el tramo desde el último punto de recuperación.
- Entrenar muestra sesiones interrumpidas con Guardar resultado o Descartar, y resultados pendientes, sincronizados o rechazados. Descartar un borrador solicita confirmación.
- Archivos JSON privados de la aplicación, separados por cuenta. Escrituras serializadas, archivo temporal vaciado a disco y copia previa de respaldo. Un archivo ilegible no se reemplaza silenciosamente; se intenta recuperar su respaldo y se informa si no es posible.
- Una sesión terminada es inmutable. Un punto de recuperación tardío no puede convertirla otra vez en borrador. Repetir la finalización conserva el identificador y el resultado existentes.
- Cola de sincronización con espera progresiva (15 segundos hasta 15 minutos), comprobación cada 30 segundos mientras el proceso sigue disponible, reintento al volver a la app y reintento manual. No se promete ejecución en segundo plano con la app cerrada.
- Antes de enviar se guarda el siguiente plazo de reintento. Una respuesta perdida deja la sesión pendiente y el envío posterior usa el mismo identificador.
- Los datos permanecen vinculados a su cuenta de origen. El adaptador y la RPC verifican esa identidad; cambiar de cuenta detiene nuevos envíos del repositorio anterior.
- Simulaciones y sesiones vacías se excluyen de la cola. Un rechazo permanente conserva el resultado local y no concede puntos.

### Backend preparado, pendiente de activar

El esquema versionado del backend, en infra/supabase/volumes/db/init/10-autohost-schema.sql, ya define public.sessions. La migración de la entrega 5 usa esa tabla y añade tres columnas opcionales para la versión de reglas, la hora de inicio y la duración exacta en microsegundos. La RPC conserva el contrato de la app y compara el resultado anterior al reintentar.

La política de lectura existente permite consultar sesiones propias o de una liga a la que se pertenece. La entrega 5 guarda league_id nulo. Las políticas restrictivas protegen las filas versionadas de escrituras directas del cliente autenticado y mantienen el comportamiento previo de las sesiones antiguas.

**Activación:** revisar y aplicar la migración en el Supabase real, comprobar que las políticas y el contrato son compatibles con ese despliegue, y arrancar con:

```powershell
.\.fvm\flutter_sdk\bin\flutter.bat run --dart-define=TRAINING_SYNC_ENABLED=true
```

Hasta entonces la opción permanece desactivada por defecto: las sesiones se conservan en el teléfono como pendientes y no se realizan peticiones a una función que todavía no existe. No se ha ejecutado una migración contra producción ni se ha afirmado sincronización real sin comprobar el servidor.

Estas sesiones aún no incluyen un contexto competitivo de pertenencia validado. La entrega 6 no debe asignarlas retroactivamente a la Liga actual del usuario; antes de acreditar competencia deben resolverse pertenencia original, cierre semanal y sincronización tardía.

### Verificación reproducible

`scripts/verify_training_storage.dart` ejecuta comprobaciones de Dart sin depender de sockets de pruebas de Flutter ni del backend. Cubre recuperación al recrear el repositorio, precisión de duración, respuesta perdida, reenvío sin otro identificador, espera entre reintentos, finalización duplicada, aislamiento de cuentas, rechazo conservado, recuperación desde respaldo, exclusión de simulaciones y errores de disco.

```powershell
.\.fvm\flutter_sdk\bin\cache\dart-sdk\bin\dart.exe run scripts/verify_training_storage.dart
```

Pendiente para cerrar la entrega: probar cierre/reapertura en Android y comprobar la migración y recepción en el Supabase real. La verificación local no sustituye esas comprobaciones.

## Entrega 6 · Ranking semanal

Aplicar training_sessions_v1.sql y después league_weekly_ranking_v1.sql.
La configuración «RivalFit (Supabase local)» de VS Code y el script local `scripts/dev.ps1` arrancan con `TRAINING_SYNC_ENABLED=true` y `LEAGUE_WEEKLY_RANKING_ENABLED=true`.

La traza `SQUAT_TRACE` está desactivada por defecto. Para diagnosticar el conteo en debug, elige `true` al iniciar desde VS Code o agrega `-SquatTrace` al ejecutar el script. Para medir rendimiento, deja la traza desactivada.

El servidor asigna puntos cuando existe una sola membresía vigente, registrada antes del inicio declarado, y la sesión llega dentro de la misma semana. El corte es el lunes a las 00:00 en Ciudad de México. Las sesiones anteriores a la activación, fuera de plazo o con pertenencia ambigua solo aportan al progreso personal. Salir o volver a entrar no transfiere puntos a la nueva membresía. El ranking agrega las sesiones por identificador y semana.

Para validar la acreditación en Android, iniciar con una cuenta que ya pertenezca a la liga. Terminar una serie sin conexión y volver a abrir la app con la misma cuenta. En la lista de sesiones debe quedar pendiente. Al reconectar, esperar el reintento automático o pulsar «Reintentar sincronización». Comprobar que Progreso suma las repeticiones una vez y muestra Bronce en piernas, y que el ranking de Liga solo añade los puntos de esa sesión una vez si llegó dentro de su semana. Una serie guardada al cierre de la semana y recibida en la siguiente solo suma a Progreso.

La hora de inicio procede del teléfono. La comprobación de membresía limita la atribución, pero no certifica independientemente cuándo ocurrió el ejercicio.

Al abrir la app con una cuenta, el repositorio restaura las sesiones confirmadas de esa cuenta desde Supabase y las conserva en el teléfono para consultar Progreso sin conexión. Mantiene el identificador original en la restauración. Las sesiones que quedaron únicamente en el teléfono requieren sincronizarse antes de desinstalar.
