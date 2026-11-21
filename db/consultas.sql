-- ============================================================================
-- Maxilux SpA · Consultas SQL de Negocio (ICN-292 · Entrega 2)
-- Todas las cifras del informe y presentación provienen directamente de aquí.
-- Fecha de corte de referencia para análisis de plazos: 2026-11-19.
-- ============================================================================

-- === Q1: Cobertura técnica y estado de fichas por grupo de producto ===
SELECT
    g.nombre AS grupo,
    COUNT(DISTINCT p.sku) AS total_skus,
    COUNT(DISTINCT f.id_ficha) AS fichas_totales,
    COUNT(DISTINCT CASE WHEN f.estado = 'APROBADA' THEN f.id_ficha END) AS fichas_aprobadas,
    COUNT(DISTINCT CASE WHEN f.estado = 'BORRADOR' THEN f.id_ficha END) AS fichas_borrador,
    SUM(CASE WHEN p.estado_doc <> 'SIN_RESPALDO' THEN 1 ELSE 0 END) AS skus_con_datos,
    SUM(CASE WHEN p.estado_doc = 'SIN_RESPALDO' THEN 1 ELSE 0 END) AS skus_sin_respaldo,
    ROUND(100.0 * SUM(CASE WHEN p.estado_doc <> 'SIN_RESPALDO' THEN 1 ELSE 0 END) / COUNT(*), 1) AS pct_con_datos
FROM producto p
JOIN grupo_producto g ON g.id_grupo = p.id_grupo
JOIN ficha_tecnica f ON f.id_ficha = p.id_ficha
GROUP BY g.id_grupo, g.nombre
ORDER BY total_skus DESC, g.nombre ASC;

-- === Q2: Ranking de atributos críticos que bloquean la aprobación de fichas ===
SELECT
    a.codigo_atributo,
    a.nombre AS atributo_critico,
    COUNT(DISTINCT CASE WHEN ep.valor IS NOT NULL THEN p.sku END) AS skus_con_dato,
    SUM(CASE WHEN ep.valor IS NULL THEN 1 ELSE 0 END) AS skus_faltantes_total,
    SUM(CASE WHEN p.estado_doc <> 'SIN_RESPALDO' AND ep.valor IS NULL THEN 1 ELSE 0 END) AS skus_con_datos_sin_atributo,
    COUNT(DISTINCT CASE WHEN ep.valor IS NULL THEN p.id_ficha END) AS fichas_bloqueadas_por_atributo,
    ROUND(100.0 * COUNT(DISTINCT CASE WHEN ep.valor IS NOT NULL THEN p.sku END) / COUNT(DISTINCT p.sku), 1) AS pct_cobertura_catalogo
FROM atributo_tecnico a
CROSS JOIN producto p
LEFT JOIN especificacion_producto ep
    ON ep.sku = p.sku AND ep.id_atributo = a.id_atributo
WHERE a.es_critico = 1
GROUP BY a.id_atributo, a.codigo_atributo, a.nombre
ORDER BY skus_faltantes_total DESC, a.codigo_atributo ASC;

-- === Q3: Comparativo multi-proveedor y lista de precios (MIN vs MAX costo) ===
SELECT
    v.grupo,
    COUNT(*) AS skus_multioferta,
    ROUND(AVG(v.costo_minimo_clp), 0) AS prom_costo_min_clp,
    ROUND(AVG(v.costo_maximo_clp), 0) AS prom_costo_max_clp,
    SUM(v.costo_maximo_clp - v.costo_minimo_clp) AS diferencia_evitada_clp,
    ROUND(AVG(v.precio_proyecto_clp), 0) AS prom_precio_proyecto_clp,
    ROUND(AVG(v.precio_final_clp), 0) AS prom_precio_final_clp
FROM v_lista_precios_clientes v
WHERE v.cantidad_ofertas > 1
GROUP BY v.grupo
ORDER BY diferencia_evitada_clp DESC;

-- === Q4: Embudo de prospección B2B por campaña y control de cupo ===
SELECT
    c.codigo_campana,
    c.nombre AS campana,
    COUNT(pr.id_prospeccion) AS total_prospectos,
    SUM(CASE WHEN pr.decision_humana = 'PENDIENTE' THEN 1 ELSE 0 END) AS pendientes_revision,
    SUM(CASE WHEN pr.estado_sistema = 'BORRADOR' THEN 1 ELSE 0 END) AS borradores_imap,
    SUM(CASE WHEN pr.estado_sistema = 'ENVIADO' THEN 1 ELSE 0 END) AS enviados_espera,
    SUM(CASE WHEN pr.estado_sistema = 'RESPONDIDO' THEN 1 ELSE 0 END) AS respondidos,
    SUM(CASE WHEN pr.estado_sistema = 'BLOQUEADA' THEN 1 ELSE 0 END) AS bloqueados,
    COALESCE(ROUND(
        100.0 * SUM(CASE WHEN pr.estado_sistema = 'RESPONDIDO' THEN 1 ELSE 0 END) /
        NULLIF(SUM(CASE WHEN pr.estado_sistema IN ('ENVIADO', 'RESPONDIDO') THEN 1 ELSE 0 END), 0),
        1
    ), 0.0) AS tasa_respuesta_pct
FROM campana_prospeccion c
LEFT JOIN prospeccion pr ON pr.id_campana = c.id_campana
GROUP BY c.id_campana, c.codigo_campana, c.nombre
ORDER BY c.id_campana ASC;

-- === Q5: Auditoría de cumplimiento Ley 21.719 (bloqueos vigentes vs prospecciones activas) ===
SELECT
    b.id_bloqueo,
    e.razon_social_anon,
    b.motivo,
    b.origen_registro,
    substr(b.fecha_bloqueo, 1, 10) AS fecha_bloqueo,
    SUM(CASE
        WHEN pr.estado_sistema IN ('PENDIENTE', 'BORRADOR', 'ENVIADO')
          OR pr.decision_humana IN ('PENDIENTE', 'APROBADO')
        THEN 1 ELSE 0
    END) AS prospecciones_activas_indebidas
FROM bloqueo_contacto b
JOIN empresa_cliente e ON e.id_empresa = b.id_empresa
LEFT JOIN contacto ct ON ct.id_empresa = e.id_empresa
LEFT JOIN prospeccion pr ON pr.id_contacto = ct.id_contacto
GROUP BY b.id_bloqueo, e.razon_social_anon, b.motivo, b.origen_registro, b.fecha_bloqueo
ORDER BY b.id_bloqueo ASC;

-- === Q6: Cola de seguimientos vencidos (>= 3 días hábiles desde envío sin respuesta) ===
SELECT
    pr.codigo_mxl,
    e.razon_social_anon,
    ct.correo_anon,
    substr(MAX(CASE WHEN i.tipo_evento = 'ENVIO_MANUAL' THEN i.fecha_evento END), 1, 10) AS fecha_envio_manual,
    CAST(ROUND(julianday('2026-11-19') - julianday(substr(MAX(CASE WHEN i.tipo_evento = 'ENVIO_MANUAL' THEN i.fecha_evento END), 1, 10))) AS INTEGER) AS dias_corridos_sin_resp,
    c.dias_habiles_seguimiento AS regla_dias_habiles
FROM prospeccion pr
JOIN campana_prospeccion c ON c.id_campana = pr.id_campana
JOIN contacto ct ON ct.id_contacto = pr.id_contacto
JOIN empresa_cliente e ON e.id_empresa = ct.id_empresa
JOIN interaccion_prospeccion i ON i.id_prospeccion = pr.id_prospeccion
WHERE pr.estado_sistema = 'ENVIADO'
  AND NOT EXISTS (
      SELECT 1 FROM bloqueo_contacto b
      WHERE b.id_empresa = e.id_empresa
  )
  AND NOT EXISTS (
      SELECT 1 FROM interaccion_prospeccion i2
      WHERE i2.id_prospeccion = pr.id_prospeccion
        AND i2.tipo_evento IN ('RESPUESTA_HUMANA', 'BAJA_OPTOUT', 'REBOTE', 'SEGUIMIENTO_CREADO')
  )
GROUP BY pr.id_prospeccion, pr.codigo_mxl, e.razon_social_anon, ct.correo_anon, c.dias_habiles_seguimiento
HAVING MAX(CASE WHEN i.tipo_evento = 'ENVIO_MANUAL' THEN i.fecha_evento END) <= '2026-11-16T23:59:59Z'
ORDER BY fecha_envio_manual ASC;

-- === Q7: Impacto de disponibilidad documental en atención de clientes y derivaciones ===
SELECT
    COALESCE(p.estado_doc, 'CONSULTA_GENERAL') AS respaldo_documental,
    COUNT(DISTINCT cc.id_consulta) AS total_consultas,
    SUM(cc.resuelta_por_ia) AS resueltas_por_ia,
    ROUND(100.0 * SUM(cc.resuelta_por_ia) / COUNT(DISTINCT cc.id_consulta), 1) AS pct_resolucion_ia,
    SUM(CASE WHEN d.asignado_rol = 'COMERCIAL_OPERACIONES' THEN 1 ELSE 0 END) AS deriv_comercial_oper,
    SUM(CASE WHEN d.asignado_rol = 'FINANZAS_PROVEEDORES' THEN 1 ELSE 0 END) AS deriv_finanzas_prov,
    ROUND(AVG(CASE
        WHEN cc.fecha_respuesta IS NOT NULL
        THEN (julianday(cc.fecha_respuesta) - julianday(cc.fecha_ingreso)) * 1440.0
    END), 1) AS tiempo_resp_prom_min
FROM consulta_cliente cc
LEFT JOIN producto p ON p.sku = cc.sku_consultado
LEFT JOIN derivacion_consulta d ON d.id_consulta = cc.id_consulta
GROUP BY COALESCE(p.estado_doc, 'CONSULTA_GENERAL')
ORDER BY pct_resolucion_ia DESC, total_consultas DESC;
