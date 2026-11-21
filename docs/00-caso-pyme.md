# 00 — Caso PYME: Maxilux (Continuidad desde Unter E1)

## 1. Justificación formal del cambio excepcional Unter → Maxilux (E1 → E2)

En la Entrega 1 se levantó el caso de **Unter**, distribuidora de equipos de protección personal (EPP), herramientas e insumos industriales operada por dos personas (Ariel y Jani). Al iniciar la fase de implementación de la Entrega 2 con los mismos dueños, se formalizó el alcance sobre **Maxilux**, empresa hermana perteneciente al mismo grupo controlador que opera **exactamente bajo la misma estructura organizacional de dos roles** (Comercial/Operaciones y Finanzas/Proveedores), bajo el mismo modelo de **intermediación contra pedido sin inventario propio** y presentando **los mismos tres problemas críticos** diagnosticados en E1.

> **Estado administrativo:** Conforme a la Sección 2 del enunciado de Entrega 2 (*"cambio excepcional justificado en docs/00-caso-pyme.md, con aprobación del profesor"*), este documento registra formalmente la continuidad estructural y operativa Unter → Maxilux, quedando sujeta a ratificación explícita del profesor de paralelo (Patricio Eduardo Cifuentes Reyes) y adjunto del respaldo de entrevista/SII actualizado previo al cierre definitivo.

### ¿Por qué el cambio fortalece la Entrega 2 sin romper la continuidad de E1?
1. **Mismos dueños y dotación:** Opera con el mismo equipo directivo de 2 personas y la misma regla de derivación binaria (todo lo financiero/precios/proveedores recae en Finanzas/Proveedores; todo lo comercial, catálogo, fichas técnicas y prospección recae en Comercial/Operaciones).
2. **Evidencia empírica ya presente desde la entrevista de E1:** En la transcripción original de E1 (`ICN292_P100_TranscripcionEntrevista.txt`), el entrevistado ya mencionaba explícitamente el rubro de **iluminación** (junto con el problema de confusión con distribuidoras eléctricas como Enel/CGE en campañas de Google Ads), la prospección manual en frío y el armado manual de fichas técnicas.
3. **Datos reales auditables a escala completa:** Maxilux aportó su lista maestra de precios (**511 SKUs** en **14 grupos**), **55 fichas PDF reales de proveedores** y un catálogo web de **181 productos**, permitiendo construir y medir un generador real de **133 fichas técnicas PDF** y validar los flujos de prospección en n8n.

---

## 2. Identificación de la PYME

| Campo | Valor |
|---|---|
| Nombre comercial | **Maxilux** |
| Razón social / RUT | *Pendiente confirmación formal para pie de ficha e inicio de actividades SII* |
| Rubro | Comercialización e intermediación B2B de iluminación LED industrial, comercial, vial y solar |
| Dotación interna | **2 roles operativos** (Comercial/Operaciones y Finanzas/Proveedores), sin departamento de TI |
| Dirección de referencia | Santiago, Región Metropolitana (Santa Victoria 387, Of. 1007 según fichas históricas; La Concepción 81 en E1) |
| Modelo operativo | Compra al proveedor contra pedido confirmado del cliente (sin stock propio masivo) |

---

## 3. Problema de negocio medible (línea base)

### 3.1 Prospección B2B manual, sin memoria y alto desperdicio en pauta digital
- **Prospección directa:** Armar una lista diaria de **5 empresas** consultando Google Maps y directorios mercantiles toma **1,5 horas** (validación manual sin datos de contacto directo) y visitarlas en frío consume entre **5 y 6 horas** al día siguiente, frecuentemente sin ser atendidos ni lograr agenda.
- **Captación pagada (Google Ads):** Gasto mensual entre **\$400.000 y \$600.000 CLP**, donde aproximadamente **8 de cada 10 contactos (80%)** corresponden a consultas no calificadas o erróneas (confusión con empresas de distribución eléctrica).
- **Ausencia de registro:** Sin una base centralizada, no existe memoria de qué empresas ya fueron contactadas ni registro de solicitudes de baja (riesgo directo ante la Ley 21.719).

### 3.2 Ausencia de documentación técnica propia y dispersión de catálogo
- **Armado manual de fichas:** Cada ficha se confeccionaba a mano en Canva, Word, PowerPoint o PDF tomando entre **15 y 20 minutos por producto**. Con **511 SKUs** activos en la lista maestra (y potencial de expansión sobre 3.000 referencias), generar o actualizar el catálogo manualmente requeriría más de **127 a 170 horas-hombre** continuas.
- **Riesgo de desintermediación:** Reenviar los PDFs de proveedores exponía marcas y códigos originales al cliente final.
- **Inconsistencia en planillas Excel:** La auditoría de la lista maestra reveló que **478 de 511 SKUs (93,5%)** carecían de costo y código de proveedor cargado; además, la fórmula de `ORIGEN` usaba `MINIFS` (menor costo) mientras `COSTO` usaba `MAX` (mayor costo), generando un error latente al incorporar un segundo proveedor.

### 3.3 Atención de consultas dispersa y dependiente de la ficha técnica
- Sin un repositorio único de fichas aprobadas, las consultas por correo, WhatsApp o web exigen buscar PDFs dispersos o escribirle al proveedor y esperar días por una respuesta.

---

## 4. Objetivos y KPI verificables en Entrega 2

| Objetivo SIG | KPI medido en E2 (respaldado en BD / generador) | Valor verificado |
|---|---|---|
| Centralizar y normalizar catálogo en 3FN | SKUs unificados en tabla `producto` + grupos | **511 SKUs / 14 grupos / 133 fichas** |
| Automatizar generación de fichas sin marcas de proveedor | Fichas generadas automáticamente (≤ 2 págs.) y fuga de marcas | **133 PDFs (0 fugas de proveedor)** |
| Hacer visibles las brechas críticas antes de publicar | Fichas `BORRADOR` vs `APROBADA` y faltantes críticos | **2 aprobadas / 131 borrador** (77 temp., 97 cert., 278 IP) |
| Corregir cálculo de costos multi-proveedor | Vista SQL `v_lista_precios_clientes` con `MIN(costo)` | **32 SKUs multi-oferta** con ahorro calculado |
| Estandarizar prospección B2B con control humano y Ley 21.719 | Tope pendientes, envíos manuales y cumplimiento de bloqueos | **Cupo 100 / 0 prospecciones activas sobre bloqueados** |
