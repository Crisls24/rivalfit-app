# RivalFit · Conteo y experiencia de entrenamiento

Objetivo: que alguien pueda abrir Sentadillas desde Liga, entender en segundos cómo colocar el teléfono y completar una sesión con feedback perceptible a distancia.

## Entrega 7A · Recuperar el conteo

- Reproducir en Android con el teléfono en el piso y registrar, solo en desarrollo, tiempo entre muestras, visibilidad, ángulos de rodilla, fase y motivo de reinicio. Guardar datos numéricos sin vídeo. Revisar el caso antes de cambiar umbrales.
- El flujo actual puede pedir postura erguida dos veces. El controlador habilita Inicio con la preparación y después reinicia el contador, que vuelve a esperar una postura estable. Hacer que el contador se arme con una muestra erguida reciente y que solo se rearme tras pausa o pérdida real de seguimiento.
- Separar seguimiento de postura inicial. Durante el descenso se necesitan articulaciones visibles y una secuencia válida. La pérdida breve y la pérdida sostenida deben tener comportamiento definido. Una interrupción sostenida invalida el ciclo parcial.
- Comparar encuadre frontal y oblicuo con el teléfono en el piso. Ver si fallan la visibilidad de ambas piernas, el ángulo proyectado o la separación temporal. Si se admite trabajar con un lado visible, mantener ese lado durante todo el ciclo y comprobar el impacto en falsos positivos.
- Probar ciclos completos, descensos parciales, pausa, pérdida de seguimiento y regreso. Un ciclo completo suma una vez y un parcial no suma.

## Entrega 7B · Entrenar con el teléfono en el piso

- Mostrar una sola guía breve antes de colocar el teléfono, con una referencia visual del encuadre y una demostración del descenso y regreso. Mostrarla la primera vez por ejercicio y dejar una opción para volver a verla.
- Pedir permiso de cámara en el primer uso. Al tocar Entrenar, abrir la cámara en la misma pantalla y usar una sola comprobación de encuadre y postura. Cuando esté lista, iniciar una cuenta regresiva corta con opción de cancelar.
- Priorizar el número de repeticiones grande y de alto contraste. Mostrar un solo estado a la vez. Usar sonido opcional para inicio, repetición y pérdida de seguimiento sostenida. La vibración del teléfono puede complementar el aviso cuando se tiene en la mano.
- Mantener Pausar y Terminar accesibles. Las explicaciones largas se quedan en la guía y los avisos importantes durante la sesión deben entenderse sin leer texto pequeño.

## Entrega 7C · Entrada rápida desde Liga y validación

- Añadir acceso directo a Sentadillas desde Liga, con la posición propia y la diferencia de puntos respecto al puesto inmediatamente superior cuando existan datos. También conservar el acceso desde Entrenar.
- Al terminar, mostrar el número de repeticiones, el estado de sincronización y los puntos que el servidor haya acreditado. Refrescar el ranking al regresar y verificar que reenviar la misma sesión conserve el total. Si falla la conexión, mantener la sesión pendiente y comunicarlo.
- En Android, probar permiso inicial, entrada recurrente de un toque, lectura del contador y avisos desde el encuadre real, pausa y recuperación, guardado y ranking. Medir tiempo desde tocar Entrenar hasta poder empezar, cuánto tarda en verse una repetición y cuántos ciclos se pierden en un conjunto anotado de movimientos.
- Criterio inicial de beta: contar al menos 9 de 10 sentadillas completas en el encuadre publicado, sin sumar parciales ni duplicar ciclos en esa prueba. Ampliar la muestra antes de afirmar precisión general.
