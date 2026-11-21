-- ============================================================================
-- Maxilux SpA · Sistema de Información para la Gestión (ICN-292 · Entrega 2)
-- Motor: SQLite 3 (compatible con ejecución estándar sin servidor externo)
-- Esquema normalizado a Tercera Forma Normal (3FN)
-- ============================================================================

PRAGMA foreign_keys = ON;

DROP VIEW IF EXISTS v_cobertura_fichas;
DROP VIEW IF EXISTS v_lista_precios_clientes;

DROP TABLE IF EXISTS derivacion_consulta;
DROP TABLE IF EXISTS consulta_cliente;
DROP TABLE IF EXISTS bloqueo_contacto;
DROP TABLE IF EXISTS interaccion_prospeccion;
DROP TABLE IF EXISTS prospeccion;
DROP TABLE IF EXISTS campana_prospeccion;
DROP TABLE IF EXISTS contacto;
DROP TABLE IF EXISTS empresa_cliente;
DROP TABLE IF EXISTS especificacion_producto;
DROP TABLE IF EXISTS atributo_tecnico;
DROP TABLE IF EXISTS oferta_proveedor;
DROP TABLE IF EXISTS producto;
DROP TABLE IF EXISTS ficha_tecnica;
DROP TABLE IF EXISTS proveedor;
DROP TABLE IF EXISTS serie_comercial;
DROP TABLE IF EXISTS grupo_producto;

-- ----------------------------------------------------------------------------
-- 1. Catálogo y Documentación Técnica
-- ----------------------------------------------------------------------------

CREATE TABLE grupo_producto (
    id_grupo      INTEGER PRIMARY KEY AUTOINCREMENT,
    codigo_grupo  TEXT    NOT NULL UNIQUE,
    nombre        TEXT    NOT NULL UNIQUE,
    descripcion   TEXT
);

CREATE TABLE serie_comercial (
    id_serie       INTEGER PRIMARY KEY AUTOINCREMENT,
    nombre         TEXT    NOT NULL UNIQUE,
    nivel_gama     TEXT    NOT NULL CHECK (nivel_gama IN ('BASICA', 'ESTANDAR', 'ALTA', 'PROFESIONAL', 'SIN_SERIE')),
    orden_calidad  INTEGER NOT NULL CHECK (orden_calidad >= 0)
);

CREATE TABLE proveedor (
    id_proveedor       INTEGER PRIMARY KEY AUTOINCREMENT,
    codigo_origen      TEXT    NOT NULL UNIQUE,
    razon_social_anon  TEXT    NOT NULL UNIQUE,
    tipo_integracion   TEXT    NOT NULL CHECK (tipo_integracion IN ('API_WEB', 'SITEMAP_WEB', 'PDF_MANUAL', 'EVENTUAL')),
    activo             INTEGER NOT NULL DEFAULT 1 CHECK (activo IN (0, 1))
);

CREATE TABLE ficha_tecnica (
    id_ficha             INTEGER PRIMARY KEY AUTOINCREMENT,
    codigo_ficha         TEXT    NOT NULL UNIQUE,
    nombre_ficha         TEXT    NOT NULL UNIQUE,
    descripcion_breve    TEXT,
    estado               TEXT    NOT NULL CHECK (estado IN ('BORRADOR', 'EN_REVISION', 'APROBADA', 'OBSOLETA')),
    version              INTEGER NOT NULL DEFAULT 1 CHECK (version > 0),
    paginas              INTEGER NOT NULL DEFAULT 1 CHECK (paginas BETWEEN 1 AND 2),
    tiene_foto_principal INTEGER NOT NULL DEFAULT 0 CHECK (tiene_foto_principal IN (0, 1)),
    aprobada_por         TEXT,
    fecha_generacion     TEXT    NOT NULL,
    fecha_aprobacion     TEXT,
    CHECK (estado <> 'APROBADA' OR (aprobada_por IS NOT NULL AND fecha_aprobacion IS NOT NULL))
);

CREATE TABLE producto (
    sku              TEXT    PRIMARY KEY,
    id_grupo         INTEGER NOT NULL REFERENCES grupo_producto(id_grupo) ON UPDATE CASCADE,
    id_serie         INTEGER NOT NULL REFERENCES serie_comercial(id_serie) ON UPDATE CASCADE,
    id_ficha         INTEGER          REFERENCES ficha_tecnica(id_ficha) ON UPDATE CASCADE,
    nombre_producto  TEXT    NOT NULL,
    potencia_w       REAL             CHECK (potencia_w IS NULL OR potencia_w > 0),
    cct_k            INTEGER          CHECK (cct_k IS NULL OR cct_k > 0),
    estado_doc       TEXT    NOT NULL CHECK (estado_doc IN ('COMPLETA', 'BORRADOR', 'SIN_RESPALDO')),
    activo           INTEGER NOT NULL DEFAULT 1 CHECK (activo IN (0, 1))
);

CREATE TABLE oferta_proveedor (
    id_oferta               INTEGER PRIMARY KEY AUTOINCREMENT,
    sku                     TEXT    NOT NULL REFERENCES producto(sku) ON DELETE CASCADE ON UPDATE CASCADE,
    id_proveedor            INTEGER NOT NULL REFERENCES proveedor(id_proveedor) ON UPDATE CASCADE,
    codigo_proveedor_anon   TEXT    NOT NULL,
    costo_neto_clp          NUMERIC NOT NULL CHECK (costo_neto_clp > 0),
    regla_vinculo           TEXT    NOT NULL CHECK (regla_vinculo IN ('CODIGO_EXACTO', 'EQUIVALENCIA_WEB', 'EQUIVALENCIA_CATALOGO')),
    es_proveedor_principal  INTEGER NOT NULL DEFAULT 0 CHECK (es_proveedor_principal IN (0, 1)),
    fecha_vigencia          TEXT    NOT NULL,
    UNIQUE (sku, id_proveedor)
);

CREATE TABLE atributo_tecnico (
    id_atributo      INTEGER PRIMARY KEY AUTOINCREMENT,
    codigo_atributo  TEXT    NOT NULL UNIQUE,
    nombre           TEXT    NOT NULL UNIQUE,
    unidad           TEXT,
    seccion_ficha    TEXT    NOT NULL,
    es_critico       INTEGER NOT NULL DEFAULT 0 CHECK (es_critico IN (0, 1))
);

CREATE TABLE especificacion_producto (
    sku                  TEXT    NOT NULL REFERENCES producto(sku) ON DELETE CASCADE ON UPDATE CASCADE,
    id_atributo          INTEGER NOT NULL REFERENCES atributo_tecnico(id_atributo) ON UPDATE CASCADE,
    valor                TEXT    NOT NULL,
    origen_dato          TEXT    NOT NULL CHECK (origen_dato IN ('CATALOGO_PDF', 'WEB_PROVEEDOR', 'MANUAL_VALIDADO')),
    id_proveedor_fuente  INTEGER          REFERENCES proveedor(id_proveedor) ON UPDATE CASCADE,
    fecha_captura        TEXT    NOT NULL,
    PRIMARY KEY (sku, id_atributo)
);

-- ----------------------------------------------------------------------------
-- 2. Prospección B2B y Cumplimiento Ley 21.719
-- ----------------------------------------------------------------------------

CREATE TABLE empresa_cliente (
    id_empresa         INTEGER PRIMARY KEY AUTOINCREMENT,
    razon_social_anon  TEXT    NOT NULL,
    rubro              TEXT    NOT NULL,
    dominio_web        TEXT    NOT NULL UNIQUE,
    sitio_web          TEXT    NOT NULL,
    comuna_zona        TEXT    NOT NULL,
    tipo_relacion      TEXT    NOT NULL CHECK (tipo_relacion IN ('PROSPECTO', 'CLIENTE_ACTIVO', 'DESCARTADO')),
    fecha_alta         TEXT    NOT NULL
);

CREATE TABLE contacto (
    id_contacto        INTEGER PRIMARY KEY AUTOINCREMENT,
    id_empresa         INTEGER NOT NULL REFERENCES empresa_cliente(id_empresa) ON DELETE CASCADE ON UPDATE CASCADE,
    nombre_anon        TEXT    NOT NULL,
    cargo              TEXT    NOT NULL,
    correo_anon        TEXT    NOT NULL UNIQUE,
    fuente_url         TEXT    NOT NULL,
    fecha_obtencion    TEXT    NOT NULL,
    verificado_dominio INTEGER NOT NULL DEFAULT 1 CHECK (verificado_dominio IN (0, 1))
);

CREATE TABLE campana_prospeccion (
    id_campana                INTEGER PRIMARY KEY AUTOINCREMENT,
    codigo_campana            TEXT    NOT NULL UNIQUE,
    nombre                    TEXT    NOT NULL,
    rubro_objetivo            TEXT    NOT NULL,
    zona_objetivo             TEXT    NOT NULL,
    cupo_max_pendientes       INTEGER NOT NULL DEFAULT 100 CHECK (cupo_max_pendientes > 0),
    lote_por_corrida          INTEGER NOT NULL DEFAULT 10  CHECK (lote_por_corrida BETWEEN 1 AND 100),
    dias_habiles_seguimiento  INTEGER NOT NULL DEFAULT 3   CHECK (dias_habiles_seguimiento > 0),
    max_seguimientos          INTEGER NOT NULL DEFAULT 1   CHECK (max_seguimientos >= 0),
    fecha_inicio              TEXT    NOT NULL,
    estado                    TEXT    NOT NULL CHECK (estado IN ('ACTIVA', 'PAUSADA', 'CERRADA'))
);

CREATE TABLE prospeccion (
    id_prospeccion    INTEGER PRIMARY KEY AUTOINCREMENT,
    codigo_mxl        TEXT    NOT NULL UNIQUE,
    id_campana        INTEGER NOT NULL REFERENCES campana_prospeccion(id_campana) ON UPDATE CASCADE,
    id_contacto       INTEGER NOT NULL REFERENCES contacto(id_contacto) ON UPDATE CASCADE,
    encaje_comercial  TEXT    NOT NULL,
    decision_humana   TEXT    NOT NULL DEFAULT 'PENDIENTE' CHECK (decision_humana IN ('PENDIENTE', 'APROBADO', 'RECHAZADO')),
    estado_sistema    TEXT    NOT NULL DEFAULT 'PENDIENTE' CHECK (estado_sistema IN ('PENDIENTE', 'BORRADOR', 'ENVIADO', 'RESPONDIDO', 'BLOQUEADA', 'CANCELADO')),
    asunto_sugerido   TEXT    NOT NULL,
    notas_revision    TEXT,
    fecha_creacion    TEXT    NOT NULL,
    UNIQUE (id_campana, id_contacto)
);

CREATE TABLE interaccion_prospeccion (
    id_interaccion      INTEGER PRIMARY KEY AUTOINCREMENT,
    id_prospeccion      INTEGER NOT NULL REFERENCES prospeccion(id_prospeccion) ON DELETE CASCADE ON UPDATE CASCADE,
    tipo_evento         TEXT    NOT NULL CHECK (tipo_evento IN ('BORRADOR_IMAP', 'ENVIO_MANUAL', 'RESPUESTA_HUMANA', 'RESPUESTA_AUTO', 'REBOTE', 'BAJA_OPTOUT', 'SEGUIMIENTO_CREADO')),
    numero_intento      INTEGER NOT NULL DEFAULT 0 CHECK (numero_intento >= 0),
    id_mensaje_externo  TEXT,
    resumen_contenido   TEXT,
    fecha_evento        TEXT    NOT NULL
);

CREATE TABLE bloqueo_contacto (
    id_bloqueo       INTEGER PRIMARY KEY AUTOINCREMENT,
    id_empresa       INTEGER NOT NULL REFERENCES empresa_cliente(id_empresa) ON UPDATE CASCADE,
    id_contacto      INTEGER          REFERENCES contacto(id_contacto) ON UPDATE CASCADE,
    motivo           TEXT    NOT NULL CHECK (motivo IN ('RECHAZADO_EN_PLANILLA', 'BAJA_TITULAR', 'REBOTE_CORREO', 'DUPLICADO')),
    fecha_bloqueo    TEXT    NOT NULL,
    origen_registro  TEXT    NOT NULL CHECK (origen_registro IN ('SHEETS', 'IMAP_INBOX', 'SISTEMA'))
);

-- ----------------------------------------------------------------------------
-- 3. Atención de Consultas y Derivaciones
-- ----------------------------------------------------------------------------

CREATE TABLE consulta_cliente (
    id_consulta      INTEGER PRIMARY KEY AUTOINCREMENT,
    id_contacto      INTEGER NOT NULL REFERENCES contacto(id_contacto) ON UPDATE CASCADE,
    sku_consultado   TEXT             REFERENCES producto(sku) ON UPDATE CASCADE,
    canal            TEXT    NOT NULL CHECK (canal IN ('CHAT_WEB', 'WHATSAPP', 'CORREO', 'TELEFONO')),
    categoria        TEXT    NOT NULL CHECK (categoria IN ('TECNICA_PRODUCTO', 'PRECIO_DISPONIBILIDAD', 'ESTADO_PEDIDO', 'OTRA')),
    resuelta_por_ia  INTEGER NOT NULL DEFAULT 0 CHECK (resuelta_por_ia IN (0, 1)),
    estado           TEXT    NOT NULL CHECK (estado IN ('RESUELTA', 'DERIVADA', 'PENDIENTE', 'CERRADA')),
    fecha_ingreso    TEXT    NOT NULL,
    fecha_respuesta  TEXT
);

CREATE TABLE derivacion_consulta (
    id_derivacion       INTEGER PRIMARY KEY AUTOINCREMENT,
    id_consulta         INTEGER NOT NULL REFERENCES consulta_cliente(id_consulta) ON DELETE CASCADE ON UPDATE CASCADE,
    asignado_rol        TEXT    NOT NULL CHECK (asignado_rol IN ('COMERCIAL_OPERACIONES', 'FINANZAS_PROVEEDORES')),
    motivo_derivacion   TEXT    NOT NULL,
    plazo_comprometido  TEXT    NOT NULL,
    estado              TEXT    NOT NULL CHECK (estado IN ('ABIERTA', 'RESUELTA', 'VENCIDA')),
    fecha_asignacion    TEXT    NOT NULL,
    fecha_cierre        TEXT
);

-- ----------------------------------------------------------------------------
-- 4. Índices de Soporte
-- ----------------------------------------------------------------------------

CREATE INDEX idx_producto_grupo ON producto(id_grupo);
CREATE INDEX idx_producto_ficha ON producto(id_ficha);
CREATE INDEX idx_oferta_sku ON oferta_proveedor(sku);
CREATE INDEX idx_espec_attr ON especificacion_producto(id_atributo);
CREATE INDEX idx_prosp_estado ON prospeccion(decision_humana, estado_sistema);
CREATE INDEX idx_inter_prosp ON interaccion_prospeccion(id_prospeccion, tipo_evento);
CREATE INDEX idx_bloqueo_emp ON bloqueo_contacto(id_empresa);
CREATE INDEX idx_consulta_sku ON consulta_cliente(sku_consultado);

-- ----------------------------------------------------------------------------
-- 5. Vistas de Negocio (evitan atributos derivados almacenados)
-- ----------------------------------------------------------------------------

CREATE VIEW v_lista_precios_clientes AS
SELECT
    p.sku,
    g.nombre AS grupo,
    p.nombre_producto,
    p.cct_k,
    COUNT(o.id_oferta) AS cantidad_ofertas,
    MIN(o.costo_neto_clp) AS costo_minimo_clp,
    MAX(o.costo_neto_clp) AS costo_maximo_clp,
    ROUND(MIN(o.costo_neto_clp) * 1.65, 0) AS precio_proyecto_clp,
    ROUND(MIN(o.costo_neto_clp) * 1.52, 0) AS precio_descuento_clp,
    ROUND(MIN(o.costo_neto_clp) * 1.42, 0) AS precio_final_clp
FROM producto p
JOIN grupo_producto g ON g.id_grupo = p.id_grupo
JOIN oferta_proveedor o ON o.sku = p.sku
GROUP BY p.sku, g.nombre, p.nombre_producto, p.cct_k;

CREATE VIEW v_cobertura_fichas AS
SELECT
    f.id_ficha,
    f.codigo_ficha,
    f.nombre_ficha,
    f.estado,
    f.paginas,
    f.tiene_foto_principal,
    COUNT(DISTINCT p.sku) AS total_modelos,
    COUNT(DISTINCT CASE WHEN p.estado_doc <> 'SIN_RESPALDO' THEN p.sku END) AS modelos_con_datos,
    COUNT(DISTINCT CASE WHEN p.estado_doc = 'SIN_RESPALDO' THEN p.sku END) AS modelos_sin_respaldo,
    SUM(CASE WHEN NOT EXISTS (
        SELECT 1 FROM especificacion_producto ep
        JOIN atributo_tecnico a ON a.id_atributo = ep.id_atributo
        WHERE ep.sku = p.sku AND a.codigo_atributo = 'IP'
    ) THEN 1 ELSE 0 END) AS skus_sin_ip,
    SUM(CASE WHEN NOT EXISTS (
        SELECT 1 FROM especificacion_producto ep
        JOIN atributo_tecnico a ON a.id_atributo = ep.id_atributo
        WHERE ep.sku = p.sku AND a.codigo_atributo = 'TEMP_OPERACION'
    ) THEN 1 ELSE 0 END) AS skus_sin_temp_operacion,
    SUM(CASE WHEN NOT EXISTS (
        SELECT 1 FROM especificacion_producto ep
        JOIN atributo_tecnico a ON a.id_atributo = ep.id_atributo
        WHERE ep.sku = p.sku AND a.codigo_atributo = 'CERTIFICACIONES'
    ) THEN 1 ELSE 0 END) AS skus_sin_certificaciones
FROM ficha_tecnica f
JOIN producto p ON p.id_ficha = f.id_ficha
GROUP BY f.id_ficha, f.codigo_ficha, f.nombre_ficha, f.estado, f.paginas, f.tiene_foto_principal;
