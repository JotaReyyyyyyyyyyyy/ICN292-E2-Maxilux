# CHANGELOG — Trazabilidad Entrega 1 → Entrega 2

Registro de cambios relevantes entre la **Entrega 1 (Diagnóstico y diseño preliminar)** y la **Entrega 2 (Solución SIG implementada, normalizada y auditable)**.

---

## [v1.1-e2] — 2026-11-20 · Tablero local

- Agregado el tablero de gestión con navegación de catálogo, prospección y atención. Sus resultados provienen de las consultas de negocio y del esquema SQLite de la entrega.
- Q6 calcula el plazo de cada campaña contando lunes a viernes hasta el corte de demostración. Q7 agrega las derivaciones por consulta antes del cálculo de porcentajes y tiempos.
- Incorporadas las instrucciones de ejecución desde un clon limpio, las fichas de KPI y la demo en el informe y la presentación. Los resultados sintéticos de atención y prospección se identifican en pantalla.

## [v1.0-e2] — 2026-11-19 · Entrega 2 Final

### 1. Cambio excepcional de razón social del caso: *Unter* → *Maxilux*
- **Qué cambió:** Se actualizó la identificación comercial de *Unter* a **Maxilux**, empresa de los mismos dueños que opera con idéntica estructura (2 personas internas) e idénticos procesos de intermediación y distribución B2B de iluminación industrial, comercial y vial.
- **Qué se mantuvo:** Los tres procesos críticos levantados (atención de consultas, prospección B2B, generación de fichas técnicas), la regla de asignación de dos roles (Comercial/Operaciones vs. Finanzas/Proveedores), los requisitos centrales (RNF-01..RNF-04) y el marco de cumplimiento Ley 21.719.
- **Por qué cambió:** Maxilux concentra la operación activa de catálogos, listas de precios (511 SKUs en 14 grupos) y los 55 PDFs reales de proveedores sobre los cuales se implementó y validó la automatización real en n8n.

### 2. Procesos BPMN (E1 → E2)
- **Qué cambió:**
  - En **Búsqueda / Prospección de clientes**, el diseño conceptual de E1 (campaña genérica y calificación por puntaje) se materializó en el BPMN TO-BE de E2 mediante **4 flujos n8n desacoplados**: (1) Prospección con tope de 100 pendientes y verificación literal de dominio/correo; (2) Generación idempotente de borradores vía IMAP sin envío automático; (3) Monitoreo de buzón cada 15 min + seguimiento automático tras 3 días hábiles sin respuesta; (4) Reporte semanal PDF vía Telegram (domingos 08:00).
  - En **Generación de Fichas Técnicas**, se reemplazó el flujo genérico de Word/PPT por un **generador automatizado consolidado** (`Base de fichas` + filtro anti-marcas + compilación XeLaTeX ≤ 2 páginas con marca de agua `BORRADOR` mientras falte IP, temperatura de operación o certificaciones).
  - En **Atención de consultas**, el chatbot con Chat integrado quedó **modelado en BD 3FN (`consulta_cliente`, `derivacion_consulta`)** y documentado como fase pendiente de despliegue productivo, priorizando en E2 resolver primero el cuello de botella documental (fichas) y comercial (prospección).

### 3. Modelo de datos: de ER preliminar (9 entidades) a 3FN estricta (16 tablas + 2 vistas)
- **Qué cambió:**
  - Se descompuso la tabla plana operativa de 77 columnas del generador de fichas (`Base de fichas Maxilux.xlsx`) y la tabla no-1FN basada en blobs JSON (`leads(id, payload)`) del worker de prospección en un **esquema relacional 3FN de 16 tablas y 2 vistas**.
  - Se separaron entidades normalizadas: `grupo_producto`, `serie_comercial`, `proveedor`, `ficha_tecnica`, `producto`, `oferta_proveedor` (soporte multi-proveedor con costos sintéticos), `atributo_tecnico` y `especificacion_producto` (eliminando grupos repetitivos `Característica 1..6` y dependencias transitivas).
  - Se incorporó el cálculo dinámico por vista (`v_lista_precios_clientes`) corrigiendo la anomalía detectada en la planilla Excel original (donde `ORIGEN` usaba `MINIFS` y `COSTO` usaba `MAX`).
  - Se formalizó `bloqueo_contacto` ligado a `empresa_cliente` y `contacto` para garantizar la trazabilidad e irreversibilidad exigida por la **Ley 21.719**.

### 4. SQL ejecutable y evidencia cuantitativa (`db/`)
- Se incorporaron `db/schema.sql`, `db/seed.sql` (anonimizado a partir de la escala real de 511 SKUs y 133 fichas), `db/consultas.sql` (Q1–Q7) y `db/ejecutar.py` verificable en entorno limpio con SQLite 3.

### 5. Correcciones técnicas aplicadas al paquete de automatización n8n
- Ampliación de prompts de IA y skill comercial de 6 líneas a las **14 familias reales** de Maxilux (destacando Solares/Baterías con 22,7% del catálogo y Alumbrado Público/Postes).
- Ajuste de razonamiento y presupuesto API por defecto (`openai` / `gpt-6-luna` con `reasoning.effort=medium`, respaldo opcional en Gemini y `LLM_BUDGET_USD=5.00`) para mejorar calidad de búsqueda/redacción y evitar bloqueos tras dos lotes.
- Eliminación de referencias residuales a otros proyectos y limpieza completa de credenciales antes de versionar en GitHub.
