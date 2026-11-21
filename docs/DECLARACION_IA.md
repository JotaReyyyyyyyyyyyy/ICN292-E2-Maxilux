# Declaración de Uso de Inteligencia Artificial — Entrega 2

En conformidad con las instrucciones de integridad académica de la asignatura **ICN-292 — Sistemas de Información para la Gestión (Segundo Semestre 2026)**, el Grupo 2 (Paralelo 100) declara de manera transparente el uso de herramientas de Inteligencia Artificial generativa y asistentes de desarrollo durante la elaboración de la Entrega 2.

---

## 1. Herramientas utilizadas y propósito

| Herramienta | Etapas donde apoyó | Alcance del apoyo | Validación realizada por el equipo |
|---|---|---|---|
| **Asistentes de IA para desarrollo (Claude / Antigravity)** | Revisión de código n8n, diseño de esquema 3FN, redacción de scripts SQL, diagramas TikZ y documentación `.md`/`.tex`. | Revisión de inconsistencias entre el paquete de prospección n8n y la lista de precios real; generación del DDL `schema.sql`, script anonimizador para `seed.sql` y estructura del informe/presentación. | Ejecución real de los 66 tests unitarios (`npm test`), validación de integridad referencial (`PRAGMA foreign_key_check`), ejecución completa de `db/ejecutar.py` (`Q1`–`Q7`) y compilación de todos los PDFs en `pdflatex`. |
| **API LLM integrada en el sistema (Gemini / OpenAI)** | Módulo de prospección B2B (`01_prospeccion.json` y `03_seguimiento.json`) en tiempo de ejecución del SIG. | Búsqueda asistida de empresas candidatas en Chile y redacción de borradores comerciales en español de Chile. | Sujeta a verificación determinística obligatoria del correo literal en HTML del mismo dominio (`src/research.mjs`), revisión humana obligatoria en Google Sheets y envío manual humano en Outlook (`DELIVERY_MODE=drafts`). |

---

## 2. Compromisos verificados de integridad

1. **Cero datos o resultados inventados:** Las cifras de catálogo (511 SKUs, 14 grupos, 133 fichas técnicas, 2 aprobadas, 131 borradores, 323 SKUs con respaldo, brechas de IP/Temperatura/Certificaciones) corresponden fielmente a la base consolidada real de Maxilux anonimizada en `db/seed.sql`. Las entidades de prospección, costos unitarios sintéticos y consultas de atención se declaran explícitamente como **sintéticas/anonimizadas coherentes con la PYME** para proteger privacidad y confidencialidad comercial.
2. **Cero capturas o salidas simuladas:** Todas las tablas de resultados de `Q1`–`Q7` incluidas en `docs/04-sql-consultas.md`, en el informe y en la presentación fueron obtenidas directamente de la ejecución real de `python db/ejecutar.py`.
3. **Código ejecutado y auditado:** El equipo revisó, probó y comprende la totalidad del esquema SQL, las consultas, los flujos n8n y los scripts entregados para su defensa oral.
