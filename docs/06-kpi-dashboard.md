# Tablero KPI en localhost

Desde la raíz del repositorio ejecuta `python -m app` con Python 3.11 o posterior y abre [127.0.0.1:8000](http://127.0.0.1:8000). Se carga el esquema y el conjunto de datos de Entrega 2 en memoria y se ejecutan las mismas consultas que en `python db/ejecutar.py`. El tablero es de solo lectura y vuelve a cargar los datos al iniciar. No hace llamadas a n8n, correo ni APIs.

## Indicadores y decisiones

| Indicador | Fórmula y fuente | Meta o criterio de decisión | Responsable |
|---|---|---|---|
| Cobertura técnica | SKU con respaldo dividido por SKU totales, Q1 sobre `producto.estado_doc` | Priorizar familias bajo la cobertura global. Completar respaldo de forma progresiva. | Comercial / Operaciones |
| Fichas aprobadas | Fichas con estado `APROBADA` sobre fichas totales, tabla `ficha_tecnica` | Liberar solo fichas aprobadas y usar Q2 para enfocar la revisión en atributos críticos faltantes. | Comercial / Operaciones |
| Prospectos por revisar | Conteo de decisiones `PENDIENTE` por campaña, Q4 | Mantener el límite operativo de 100 pendientes y revisar antes de generar borradores. | Comercial / Operaciones |
| Prospecciones activas con bloqueo | Suma de prospecciones activas detectadas por registro de bloqueo, Q5 | Meta de cero. Si hay coincidencias, revisar los bloqueos y la cola antes de preparar contactos. | Comercial / Operaciones |
| Diferencia entre ofertas | Suma de costo máximo menos costo mínimo de SKU multioferta, Q3 | Revisar los SKU con mayor diferencia. Los costos del ejercicio son sintéticos. | Finanzas / Proveedores |
| Tiempo medio de respuesta | Promedio de minutos entre ingreso y respuesta entre los casos respondidos, Q7 | Comparar escenarios de respaldo y priorizar fichas faltantes. La simulación no fija un SLA de producción. | Comercial / Operaciones |

## Recorrido para la defensa

1. En **Resumen**, compara el 63,2 % global con las familias de menor cobertura y abre **Catálogo**. Q2 muestra qué atributos faltan para acelerar la revisión.
2. En **Prospección**, muestra la cola por campaña, el control de bloqueos y los seguimientos al corte del 19/11/2026. Q6 cuenta lunes a viernes según el plazo de cada campaña, sin calendario de feriados en esta demostración.
3. En **Atención**, compara los tiempos medios del escenario simulado con y sin respaldo. Los resultados sirven para priorizar datos de catálogo y requieren validación con operación real.

La base usa catálogo anonimizado y registros sintéticos de ofertas, prospección y atención. Las evidencias de automatización y su relación con el proceso se documentan en [Flujos n8n](05-automatizacion-n8n.md). El trabajador de producción y sus cuentas son independientes de este tablero de demostración.
