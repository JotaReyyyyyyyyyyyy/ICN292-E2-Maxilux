# 04 — Consultas SQL de Negocio (Ejecutables en SQLite 3)

Todas las consultas se encuentran en [db/consultas.sql](../db/consultas.sql) y se ejecutan directamente sobre [db/schema.sql](../db/schema.sql) + [db/seed.sql](../db/seed.sql) mediante `python db/ejecutar.py` (0 violaciones de integridad referencial reportadas por `PRAGMA foreign_key_check`).

---

## Q1: Cobertura técnica y estado de fichas por grupo de producto

**Pregunta de negocio:** ¿Qué porcentaje del catálogo cuenta con respaldo técnico consolidado y cuántas fichas siguen en estado `BORRADOR` por categoría?

**Resultado ejecutado (`python db/ejecutar.py`):**

| grupo | total_skus | fichas_totales | fichas_aprobadas | fichas_borrador | skus_con_datos | skus_sin_respaldo | pct_con_datos |
|---|---:|---:|---:|---:|---:|---:|---:|
| PANEL LED | 120 | 22 | 0 | 22 | 114 | 6 | 95,0% |
| SOLAR Y BATERÍA | 116 | 18 | 2 | 16 | 42 | 74 | 36,2% |
| PROYECTOR | 63 | 7 | 0 | 7 | 57 | 6 | 90,5% |
| LUMINARIA CALLE | 38 | 4 | 0 | 4 | 13 | 25 | 34,2% |
| CAMPANA | 33 | 5 | 0 | 5 | 20 | 13 | 60,6% |
| POSTE | 26 | 25 | 0 | 25 | 3 | 23 | 11,5% |
| ANTIEXPLOSIVO | 25 | 6 | 0 | 6 | 15 | 10 | 60,0% |
| TUBO LED | 24 | 12 | 0 | 12 | 24 | 0 | 100,0% |
| AMPOLLETA | 20 | 7 | 0 | 7 | 10 | 10 | 50,0% |
| EMERGENCIA | 17 | 13 | 0 | 13 | 14 | 3 | 82,4% |
| CANOA | 12 | 8 | 0 | 8 | 10 | 2 | 83,3% |
| FAROL PLAZA | 9 | 1 | 0 | 1 | 0 | 9 | 0,0% |
| APLIQUE | 4 | 4 | 0 | 4 | 1 | 3 | 25,0% |
| FOCO | 4 | 1 | 0 | 1 | 0 | 4 | 0,0% |
| **Total** | **511** | **133** | **2** | **131** | **323** | **188** | **63,2%** |

**Interpretación:** Aunque **323 de 511 SKUs (63,2%)** ya poseen datos técnicos extraídos (superando ampliamente el punto de partida manual), la cobertura es muy asimétrica: `TUBO LED` (100%), `PANEL LED` (95%) y `PROYECTOR` (90,5%) concentran el respaldo web, mientras `SOLAR Y BATERÍA` (36,2%, segundo grupo en volumen con 116 SKUs), `LUMINARIA CALLE` (34,2%) y `POSTE` (11,5%) explican la mayoría de los 188 SKUs sin respaldo técnico publicado.

---

## Q2: Ranking de atributos críticos que bloquean la aprobación de fichas

**Pregunta de negocio:** ¿Qué atributos críticos impiden que las 131 fichas `BORRADOR` pasen a estado `APROBADA`?

**Resultado ejecutado:**

| codigo_atributo | atributo_critico | skus_con_dato | skus_faltantes_total | skus_con_datos_sin_atributo | fichas_bloqueadas_por_atributo | pct_cobertura_catalogo |
|---|---|---:|---:|---:|---:|---:|
| `TEMP_OPERACION` | Temperatura de operación | 77 | 434 | 246 | 128 | 15,1% |
| `CERTIFICACIONES` | Certificaciones | 97 | 414 | 226 | 124 | 19,0% |
| `IP` | Grado de protección IP | 278 | 233 | 45 | 85 | 54,4% |

**Interpretación:** El cuello de botella no está en el formato PDF ni en la compilación LaTeX, sino en dos campos críticos que los proveedores rara vez publican de forma estructurada: **Temperatura de operación** (cubre solo 15,1% del catálogo y bloquea 128 fichas) y **Certificaciones** (19,0%, bloquea 124 fichas). Incluso dentro de los 323 SKUs que sí tienen ficha técnica vinculada, a 246 les falta temperatura y a 226 les falta certificación. Esto orienta exactamente qué debe solicitar Finanzas/Proveedores en la próxima ronda.

---

## Q3: Comparativo multi-proveedor y lista de precios (corrección `MIN` vs `MAX`)

**Pregunta de negocio:** ¿Qué diferencia económica genera seleccionar al proveedor de menor costo frente al mayor costo (corrigiendo el error `MAX` de la planilla Excel) en SKUs con múltiples ofertas sintéticas?

**Resultado ejecutado:**

| grupo | skus_multioferta | prom_costo_min_clp | prom_costo_max_clp | diferencia_evitada_clp | prom_precio_proyecto_clp | prom_precio_final_clp |
|---|---:|---:|---:|---:|---:|---:|
| SOLAR Y BATERÍA | 4 | \$73.525 | \$89.150 | \$62.500 | \$121.316 | \$104.406 |
| PROYECTOR | 8 | \$51.800 | \$59.063 | \$58.100 | \$85.470 | \$73.556 |
| CAMPANA | 3 | \$69.633 | \$84.433 | \$44.400 | \$114.895 | \$98.879 |
| PANEL LED | 17 | \$10.818 | \$12.700 | \$32.000 | \$17.849 | \$15.361 |

**Interpretación:** La vista `v_lista_precios_clientes` calcula los tres tramos comerciales (`Proyecto ×1,65`, `Descuento ×1,52`, `Final ×1,42`) sobre `MIN(costo_neto_clp)`. Sobre la muestra sintética de 32 SKUs con ofertas de más de un proveedor, usar el mínimo costo evita un sobrecosto unitario acumulado de **\$197.000 CLP** respecto de la fórmula `=MAX(...)` heredada del Excel original, evitando cotizar fuera de mercado.

---

## Q4: Embudo de prospección B2B por campaña

**Pregunta de negocio:** ¿Cuál es el avance operativo por campaña entre prospectos pendientes, borradores creados vía IMAP, envíos manuales, respuestas humanas y bloqueos?

**Resultado ejecutado:**

| codigo_campana | campana | total_prospectos | pendientes_revision | borradores_imap | enviados_espera | respondidos | bloqueados | tasa_respuesta_pct |
|---|---|---:|---:|---:|---:|---:|---:|---:|
| `CMP-2026-01` | Bodegas, Logística y Galpones RM | 12 | 1 | 2 | 2 | 2 | 5 | 50,0% |
| `CMP-2026-02` | Alumbrado Solar, Vial y Municipalidades | 6 | 5 | 0 | 1 | 0 | 0 | 0,0% |
| `CMP-2026-03` | Instaladores Eléctricos y Áreas Clasificadas | 7 | 1 | 2 | 3 | 1 | 0 | 25,0% |

**Interpretación:** Se visualiza claramente el comportamiento del flujo sin envío automático: existen **7 prospectos `PENDIENTE`** (ocupando 7/100 del cupo operativo), **4 borradores `BORRADOR` en Outlook/IMAP** esperando envío manual humano, **6 enviados en espera**, **3 respuestas humanas reales** (descartando automáticamente respuestas *out-of-office*) y **5 bloqueos**.

---

## Q5: Auditoría de cumplimiento Ley 21.719

**Pregunta de negocio:** ¿Existe algún prospecto o campaña activa sobre empresas o contactos que solicitaron baja, rebotaron o fueron rechazados?

**Resultado ejecutado:**

| id_bloqueo | razon_social_anon | motivo | origen_registro | fecha_bloqueo | prospecciones_activas_indebidas |
|---:|---|---|---|---|---:|
| 1 | Comercializadora Retail Metro SpA (ficticia) | `RECHAZADO_EN_PLANILLA` | `SHEETS` | 2026-10-29 | 0 |
| 2 | Fábrica de Envases Plásticos Chile (ficticia) | `BAJA_TITULAR` | `IMAP_INBOX` | 2026-11-07 | 0 |
| 3 | Supermercados Regionales del Maule (ficticia) | `REBOTE_CORREO` | `IMAP_INBOX` | 2026-11-09 | 0 |
| 4 | Taller Automotriz Flota Pesada Ltda. (ficticia) | `RECHAZADO_EN_PLANILLA` | `SHEETS` | 2026-11-11 | 0 |
| 5 | Inmobiliaria Centros Comerciales Sur (ficticia) | `BAJA_TITULAR` | `IMAP_INBOX` | 2026-11-14 | 0 |

**Interpretación:** Los 5 bloqueos registrados (`SHEETS` e `IMAP_INBOX`) presentan **0 prospecciones activas indebidas**, acreditando auditabilidad plena para el control exigido por la Ley 21.719 (RNF-03).

---

## Q6: Cola de seguimientos vencidos (>= 3 días hábiles sin respuesta)

**Pregunta de negocio:** ¿Qué empresas contactadas manualmente cumplieron ≥ 3 días hábiles sin respuesta humana ni baja, listas para encolar su único seguimiento en revisión?

**Resultado ejecutado (corte `2026-11-19`):**

| codigo_mxl | razon_social_anon | correo_anon | fecha_envio_manual | dias_corridos_sin_resp | regla_dias_habiles |
|---|---|---|---|---:|---:|
| `MXL-PROS-002` | Maestranza Industrial Poniente Ltda. (ficticia) | `mantencion@maestranza-poniente.example` | 2026-11-10 | 9 | 3 |
| `MXL-PROS-005` | Constructora Obras Civiles Norte S.A. (ficticia) | `adquisiciones@obras-norte.example` | 2026-11-11 | 8 | 3 |
| `MXL-PROS-008` | Planta Procesadora BioBío S.A. (ficticia) | `servicios@procesadora-biobio.example` | 2026-11-12 | 7 | 3 |
| `MXL-PROS-011` | Astilleros del Pacífico Sur Ltda. (ficticia) | `mantencion@astilleros-sur.example` | 2026-11-13 | 6 | 3 |

**Interpretación:** Nótese el caso `MXL-PROS-008` (Planta Procesadora BioBío): recibió una respuesta automática (`RESPUESTA_AUTO` fuera de oficina), la cual fue correctamente excluida por la consulta (tal como lo hace `classify()` en `src/mail.mjs`), manteniéndola elegible para seguimiento humano tras cumplirse el plazo de 3 días hábiles.

---

## Q7: Impacto de la disponibilidad documental en atención de clientes y derivaciones

**Pregunta de negocio:** ¿Cómo mejora la tasa de resolución autónoma y el tiempo de respuesta según el estado de la ficha técnica del producto consultado (`COMPLETA`, `BORRADOR` o `SIN_RESPALDO`)?

**Resultado ejecutado:**

| respaldo_documental | total_consultas | resueltas_por_ia | pct_resolucion_ia | deriv_comercial_oper | deriv_finanzas_prov | tiempo_resp_prom_min |
|---|---:|---:|---:|---:|---:|---:|
| `COMPLETA` | 6 | 5 | 83,3% | 0 | 1 | 25,3 |
| `CONSULTA_GENERAL` | 2 | 1 | 50,0% | 1 | 0 | 75,1 |
| `BORRADOR` | 9 | 0 | 0,0% | 5 | 2 | 470,7 |
| `SIN_RESPALDO` | 7 | 0 | 0,0% | 0 | 6 | 1419,0 |

**Interpretación:** Esta consulta demuestra el **cierre sistémico entre los tres módulos** propuesto desde E1: cuando el producto tiene ficha `APROBADA` (`COMPLETA`), 5 de cada 6 consultas (83,3%) se resuelven de manera inmediata sin intervención humana, bajando el tiempo promedio a **25,3 minutos** (incluyendo la única derivación por precio). En contraste, los productos en `BORRADOR` (0% resolución IA; **470,7 min ~ 7,8 horas**) obligan a derivar a Comercial/Operaciones para validar datos críticos, y los `SIN_RESPALDO` (**1.419,0 min ~ 23,7 horas**) escalan íntegramente a Finanzas/Proveedores para consultar al fabricante.
