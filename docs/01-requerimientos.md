# 01 — Requerimientos Actualizados (E2 · Maxilux)

Los requisitos de la Entrega 1 (`RF-01` a `RF-30` y `RNF-01` a `RNF-08`) se mantienen como columna vertebral del SIG y se actualizan para reflejar el alcance efectivo verificado en la Entrega 2, distinguiendo con transparencia qué quedó **implementado y automatizado**, qué quedó **modelado y consultable en SQL 3FN**, y qué queda como **fase futura**.

Priorización MoSCoW: `M` Imprescindible · `S` Importante · `C` Deseable · `W` Fuera de alcance.

---

## 1. Actores del sistema

| Actor | Tipo | Responsabilidad en Maxilux |
|---|---|---|
| **Gestor Comercial y Operaciones (Ariel)** | Humano interno | Revisa y aprueba prospectos en Google Sheets, envía correos manualmente desde Outlook, revisa fichas `BORRADOR` y aprueba su versión final. |
| **Encargado de Finanzas y Proveedores (Jani)** | Humano interno | Gestiona negociación con proveedores, precios/márgenes, condiciones de pago, plazos y obtención de certificados faltantes. |
| **Cliente / Prospecto** | Humano externo | Empresas industriales, logísticas, constructoras, municipalidades, condominios e instaladores eléctricos en Chile. |
| **Orquestador n8n + Worker Node** | Sistema | Ejecuta los 4 flujos de prospección (búsqueda IA, verificación dominio/correo, borradores IMAP, monitoreo/seguimiento y reporte PDF Telegram) y dispara el generador de fichas. |
| **Generador de Fichas (Node + Python + XeLaTeX)** | Sistema | Consolida lista de precios, PDFs y datos web; filtra marcas de proveedores y compila fichas PDF ≤ 2 páginas. |

---

## 2. Estado de Requisitos Funcionales (Trazabilidad E1 → E2)

### Componente 1 — Atención de consultas e inventario de respaldo
| ID | Requisito | Prio. | Estado en E2 | Respaldo en repo |
|---|---|---|---|---|
| RF-01..04 | Entrada única de consultas y respuesta desde fichas aprobadas | M | **Modelado en BD 3FN (interfaz chat pendiente)** | `consulta_cliente`, `Q7` en `db/consultas.sql` |
| RF-05..08 | Derivación con contexto, asignación binaria y control de plazo | M/S | **Modelado y consultable en BD 3FN** | `derivacion_consulta`, `Q7` |
| RF-09..11 | Marcado documental (`COMPLETA`/`BORRADOR`/`SIN_RESPALDO`) y medición de tiempos | M/S | **Implementado en esquema y consultas** | `producto.estado_doc`, `Q7` |

### Componente 2 — Prospección B2B automatizada (n8n)
| ID | Requisito | Prio. | Estado en E2 | Respaldo en repo |
|---|---|---|---|---|
| RF-12 | Campañas de búsqueda por rubros compatibles (14 familias Maxilux) | M | **Implementado en n8n + BD 3FN** | `01_prospeccion.json`, `campana_prospeccion` |
| RF-13..15 | Recopilación de empresa, sitio, correo, fuente URL y fecha | M | **Implementado y verificado literalmente en dominio** | `src/research.mjs`, `contacto` |
| RF-16 | Deduplicación automática por dominio, correo y nombre normalizado | M | **Implementado en SQLite + UNIQUE 3FN** | `prospectExists()`, `empresa_cliente` |
| RF-17..18 | Tope de 100 pendientes, entrega en Sheets con texto sugerido para revisión humana | M | **Implementado en Google Sheets (5 pestañas)** | `Prospectos`, `01_prospeccion.json` |
| RF-19..20 | Detección de envíos manuales (IMAP Sent) y seguimiento tras 3 días hábiles | M/C | **Implementado en Flujo 3 (cron 15 min) + Q6** | `03_seguimiento.json`, `Q6` |
| RF-21 | Marcado `RECHAZADO` o baja (`BAJA_OPTOUT`) y bloqueo permanente | M | **Implementado en Flujo 1/2/3 + tabla `bloqueo_contacto`** | `bloqueo_contacto`, `Q5` |

### Componente 3 — Generación de fichas técnicas (Generador XeLaTeX + n8n)
| ID | Requisito | Prio. | Estado en E2 | Respaldo en repo |
|---|---|---|---|---|
| RF-22..25 | Detección de brechas, extracción multi-fuente y normalización de atributos/erratas | M/S | **Implementado y ejecutado (511 SKUs → 133 fichas)** | `generador/`, `Q1`, `Q2` |
| RF-26 | Uso de códigos internos `MX-1000..MX-1510` sin colisiones | M | **Implementado sobre lista maestra real** | `producto.sku`, `db/seed.sql` |
| RF-27..29 | Borradores con identidad Maxilux, marca `BORRADOR` si faltan críticos y versionado | M/S | **Implementado (`ficha_tecnica` + `v_cobertura_fichas`)** | `ficha_tecnica`, `reportes/` |
| RF-30 | Fichas aprobadas habilitan respuesta autónoma sin derivación | M | **Demostrado cuantitativamente en Q7** | `Q7` (`83,3%` resolución IA en `COMPLETA`) |

---

## 3. Requisitos No Funcionales (RNF)

| ID | Requisito | Estado y verificación en E2 |
|---|---|---|
| RNF-01 | Nunca entregar un dato técnico o precio inventado | **Cumplido:** el generador oculta datos faltantes, marca `BORRADOR` si falta `IP`/`TEMP`/`CERT` y el prompt de IA prohíbe afirmar stock/precio/certificación. |
| RNF-02 | Ninguna ficha técnica sin validación humana ni marcas de proveedor | **Cumplido:** regex de marcas ocultas aborta la compilación PDF si detecta cualquier nombre de proveedor; la aprobación pasa por `APROBADA`. |
| RNF-03 | Cumplimiento Ley 21.719 (fuente, fecha y bloqueo de baja) | **Cumplido:** `fuente_url` + `fecha_obtencion` obligatorios; `bloqueo_contacto` irreversible verificado con `Q5` (0 infracciones). |
| RNF-04 | Ningún correo sale automáticamente sin envío manual humano | **Cumplido:** `DELIVERY_MODE=drafts` forzado en código; cero nodos SMTP en n8n (verificado en test `check` automático). |
| RNF-05..06 | Registro de un paso y operación no técnica | **Cumplido:** revisión en Google Sheets con desplegable `PENDIENTE/APROBADO/RECHAZADO` y envío normal en Outlook. |
| RNF-07..08 | Reproducibilidad en localhost desde el repositorio | **Cumplido:** `python db/ejecutar.py` ejecuta esquema 3FN + seed + 7 consultas en cualquier PC con Python 3 sin instalación adicional. |
