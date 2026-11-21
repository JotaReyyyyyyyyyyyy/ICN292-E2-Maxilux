# 07 — Ética, Privacidad y Cumplimiento Ley 21.719

## 1. Marco normativo aplicable

La **Ley N.° 21.719** sobre protección de datos personales en Chile entra en vigencia el **1 de diciembre de 2026** (diez días después del cierre de esta Entrega 2). Aunque las micro y pequeñas empresas cuentan con un régimen transitorio de amonestación durante el primer año, las obligaciones sustantivas de **licitud, finalidad, proporcionalidad, exactitud, seguridad y derechos del titular (ARCO / oposición)** aplican íntegramente desde el diseño del sistema (*privacy by design*).

---

## 2. Controles implementados en el SIG Maxilux

| Principio / Riesgo | Control técnico implementado en la arquitectura y BD 3FN | Evidencia verificable |
|---|---|---|
| **Base de licitud y minimización (Prospección B2B)** | Solo se recopilan correos corporativos o de áreas funcionales publicados abiertamente en el sitio web oficial de la empresa (`contacto.fuente_url` y `fecha_obtencion`). Se descartan dominios personales o de terceros sin fuente verificable en el mismo dominio (`verify()` en `src/research.mjs`). | Columnas `fuente_url`, `fecha_obtencion`, `verificado_dominio` en `contacto` (`schema.sql`). |
| **Derecho de oposición y baja irreversible (RNF-03)** | Todo rechazo en revisión humana (`RECHAZADO`), solicitud explícita de baja en bandeja de entrada (`BAJA_OPTOUT`) o rebote permanente (`REBOTE_CORREO`) registra un bloqueo permanente en `bloqueo_contacto` a nivel de empresa, dominio, correo y nombre normalizado. | Tabla `bloqueo_contacto` + consulta de auditoría `Q5` (**0 prospecciones activas sobre bloqueados**). |
| **Prohibición de spam / envío masivo no supervisado (RNF-04)** | `DELIVERY_MODE=drafts` está validado de forma cerrada tanto en el código (`Engine.steps`) como en pruebas automáticas (`npm run check`). No existe ningún nodo SMTP en n8n: una persona debe revisar y enviar manualmente cada borrador desde Outlook. | `automatizacion/prospeccion/flujos/*.json` + `src/core.mjs`. |
| **Seguridad contra fuga de secretos y datos comerciales** | El repositorio público en GitHub excluye mediante `.gitignore` cualquier archivo de credenciales (`privado/`, `*.env`, `Correos.txt`, `Login.txt`). Todos los datos en `db/seed.sql` están anonimizados: proveedores genéricos (`P01..P08`), costos sintéticos CLP y empresas ficticias bajo dominio reservado `.example` (RFC 2606). | Auditoría automática de privacidad sobre todo `Entrega 2/` (**0 filtraciones**). |
| **Responsabilidad técnica y prohibición de alucinación IA (RNF-01 / RNF-02)** | Las fichas técnicas nunca inventan valores ni imprimen marcas de proveedores; ante ausencia de `IP`, `Temp. operación` o `Certificaciones` generan marca de agua `BORRADOR`. En prospección, el prompt prohíbe prometer stock, precios, plazos o certificaciones sin confirmación. | `ficha_tecnica.estado`, `Q2` y reglas en `src/research.mjs`. |

---

## 3. Derechos del titular y procedimiento operativo

1. **Si una empresa responde solicitando no ser contactada:** El Flujo 3 clasifica el texto entrante (`classify()` en `src/mail.mjs`), cancela automáticamente cualquier borrador de seguimiento pendiente y graba el registro en `bloqueo_contacto` (`BAJA_TITULAR`), impidiendo que vuelva a ser propuesta en futuras campañas.
2. **Conservación y depuración:** El cupo máximo de **100 prospectos pendientes** impide acumular bases masivas ociosas sin gestión ni finalidad comercial vigente.
3. **Protección de la cadena comercial de la PYME:** La separación de `proveedor` y `oferta_proveedor` en la BD interna versus la exclusión estricta de marcas en `ficha_tecnica` resguarda el modelo de negocio de intermediación de Maxilux frente a la desintermediación.
