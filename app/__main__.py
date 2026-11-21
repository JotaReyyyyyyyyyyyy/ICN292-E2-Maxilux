"""Tablero local de la Entrega 2 con la base SQLite de demostración."""

import argparse
from contextlib import closing
from html import escape
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
import sqlite3
from urllib.parse import urlsplit

from db.ejecutar import load_database, read_queries


NAVIGATION = {
    "/": "Resumen",
    "/catalogo": "Catálogo",
    "/prospeccion": "Prospección",
    "/atencion": "Atención",
}


def number(value, decimals=0):
    return f"{value:,.{decimals}f}".replace(",", "_").replace(".", ",").replace("_", ".")


def table(rows, columns):
    head = "".join(
        f'<th scope="col" class="{("numeric" if unit else "text")}">{escape(label)}</th>'
        for _, label, unit in columns
    )
    body = []
    for row in rows:
        cells = []
        for key, _, unit in columns:
            value = row[key]
            if value is None:
                formatted = "—"
            elif unit == "CLP":
                formatted = f"${number(value)}"
            elif unit == "%":
                formatted = f"{number(value, 1)} %"
            elif unit == "min":
                formatted = f"{number(value, 1)} min"
            elif unit == "n":
                formatted = number(value)
            else:
                formatted = escape(str(value))
            alignment = "numeric" if unit else "text"
            cells.append(f'<td class="{alignment}">{formatted}</td>')
        body.append(f"<tr>{''.join(cells)}</tr>")
    if not body:
        return '<p class="empty">Sin filas para este indicador.</p>'
    return (
        f'<div class="table-scroll" tabindex="0" role="region" aria-label="Tabla de resultados">'
        f"<table><thead><tr>{head}</tr></thead><tbody>{''.join(body)}</tbody></table></div>"
    )


def panel(title, detail, content):
    return f'<section class="panel"><h2>{escape(title)}</h2><p>{escape(detail)}</p>{content}</section>'


def card(label, value, detail):
    return (
        f'<article class="metric"><h2>{escape(label)}</h2>'
        f'<strong>{escape(value)}</strong><p>{escape(detail)}</p></article>'
    )


def page(path, title, description, content):
    navigation = "".join(
        f'<a href="{url}"' + (' aria-current="page"' if url == path else "") + f">{label}</a>"
        for url, label in NAVIGATION.items()
    )
    return f"""<!doctype html>
<html lang="es-CL">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>{escape(title)} | Maxilux</title>
  <link rel="stylesheet" href="/tablero.css">
</head>
<body>
  <a class="skip" href="#contenido">Ir a los indicadores</a>
  <header class="masthead">
    <div class="wrap header-inner">
      <a href="/" class="brand">Maxilux <span>Gestión</span></a>
      <nav aria-label="Secciones del tablero">{navigation}</nav>
    </div>
  </header>
  <main class="wrap" id="contenido">
    <div class="intro"><h1>{escape(title)}</h1><p>{escape(description)}</p></div>
    {content}
  </main>
  <footer class="wrap">ICN-292 · Grupo 2 · Entrega 2 · SQLite local · Datos anonimizados y sintéticos</footer>
</body>
</html>
"""


def render_pages():
    with closing(sqlite3.connect(":memory:")) as conn:
        load_database(conn)
        conn.row_factory = sqlite3.Row
        results = {
            title.partition(":")[0]: conn.execute(sql).fetchall()
            for title, sql in read_queries()
        }
        total, approved, drafts = conn.execute("""
            SELECT COUNT(*), COUNT(*) FILTER (WHERE estado = 'APROBADA'),
                   COUNT(*) FILTER (WHERE estado = 'BORRADOR')
            FROM ficha_tecnica
        """).fetchone()

    q1, q2, q3, q4, q5, q6, q7 = (results[f"Q{index}"] for index in range(1, 8))
    skus = sum(row["total_skus"] for row in q1)
    backed = sum(row["skus_con_datos"] for row in q1)
    coverage = number(100 * backed / skus, 1) + " %" if skus else "—"
    pending = sum(row["pendientes_revision"] or 0 for row in q4)
    conflicts = sum(row["prospecciones_activas_indebidas"] for row in q5)
    metrics = "".join((
        card("Cobertura técnica", coverage, f"{number(backed)} de {number(skus)} SKU con respaldo · Q1"),
        card("Fichas aprobadas", f"{number(approved)} de {number(total)}", f"{number(drafts)} en borrador · SQLite"),
        card("Prospectos por revisar", number(pending), "Decisiones pendientes en campañas de prueba · Q4"),
        card("Prospecciones activas con bloqueo", number(conflicts), "Meta: 0 · Control sobre datos sintéticos · Q5"),
    ))
    bars = []
    for row in sorted(q1, key=lambda row: row["pct_con_datos"]):
        group = escape(row["grupo"])
        percent = row["pct_con_datos"]
        label = f'{number(row["skus_con_datos"])} / {number(row["total_skus"])}'
        bars.append(
            f'<li><span>{group}</span><meter min="0" max="100" value="{percent}" '
            f'aria-label="Cobertura de {group}">{number(percent, 1)} %</meter>'
            f'<strong>{number(percent, 1)} %</strong><small>{label} SKU</small></li>'
        )

    coverage_panel = panel(
        "Cobertura por familia · Q1",
        "Ordenada de menor a mayor cobertura para priorizar la búsqueda de fichas.",
        f'<ul class="bars">{"".join(bars)}</ul>',
    )
    opportunities = panel(
        "Cobertura técnica por familia · Q1",
        "Un SKU cuenta como respaldado cuando su estado documental es completa o borrador.",
        table(q1, (
            ("grupo", "Familia", None), ("total_skus", "SKU", "n"),
            ("skus_con_datos", "Con respaldo", "n"), ("skus_sin_respaldo", "Sin respaldo", "n"),
            ("pct_con_datos", "Cobertura", "%"),
        )),
    )
    gaps = panel(
        "Atributos pendientes · Q2",
        "Las brechas por atributo ayudan a decidir qué solicitar al proveedor primero.",
        table(q2, (
            ("atributo_critico", "Atributo", None), ("skus_con_dato", "SKU con dato", "n"),
            ("fichas_bloqueadas_por_atributo", "Fichas con brecha", "n"), ("pct_cobertura_catalogo", "Cobertura", "%"),
        )),
    )
    prices = panel(
        "Diferencia entre ofertas · Q3",
        "Suma de máximo menos mínimo por SKU con más de una oferta. Los costos son sintéticos.",
        table(q3, (
            ("grupo", "Familia", None), ("skus_multioferta", "SKU", "n"),
            ("prom_costo_min_clp", "Mín. promedio", "CLP"), ("prom_costo_max_clp", "Máx. promedio", "CLP"),
            ("diferencia_evitada_clp", "Diferencia", "CLP"),
        )),
    )
    funnel = panel(
        "Embudo por campaña · Q4",
        "La tasa divide las respuestas humanas registradas por los contactos enviados o respondidos.",
        table(q4, (
            ("campana", "Campaña", None), ("total_prospectos", "Prospectos", "n"),
            ("pendientes_revision", "Pendientes", "n"), ("borradores_imap", "Borradores", "n"),
            ("enviados_espera", "En espera", "n"), ("respondidos", "Respondidos", "n"),
            ("bloqueados", "Bloqueados", "n"), ("tasa_respuesta_pct", "Tasa", "%"),
        )),
    )
    blocks = panel(
        "Revisión de bloqueos · Q5",
        "El control identifica prospecciones activas asociadas con una empresa bloqueada.",
        table(q5, (
            ("razon_social_anon", "Empresa de prueba", None), ("motivo", "Motivo", None),
            ("fecha_bloqueo", "Fecha del bloqueo", None), ("prospecciones_activas_indebidas", "Activas", "n"),
        )),
    )
    followup = panel(
        "Seguimientos elegibles · Q6",
        "Corte de demostración: 19 de noviembre de 2026. Una respuesta automática no cierra el seguimiento.",
        table(q6, (
            ("codigo_mxl", "Prospecto", None), ("razon_social_anon", "Empresa de prueba", None),
            ("fecha_envio_manual", "Envío manual", None), ("dias_habiles_sin_resp", "Días hábiles", "n"),
            ("regla_dias_habiles", "Plazo de campaña", "n"),
        )),
    )
    service = panel(
        "Tiempo de respuesta según respaldo · Q7",
        "Simulación con 24 consultas de ejemplo. La media considera las consultas con fecha de respuesta.",
        table(q7, (
            ("respaldo_documental", "Tipo de respaldo", None), ("total_consultas", "Consultas", "n"),
            ("resueltas_por_ia", "Resueltas por IA", "n"), ("pct_resolucion_ia", "Resolución IA", "%"),
            ("tiempo_resp_prom_min", "Tiempo medio", "min"),
        )),
    )
    return {
        "/": page("/", "Indicadores de gestión", "Prioriza fichas por completar y revisa la operación a partir de una base de demostración local.", f'<div class="metrics">{metrics}</div>{coverage_panel}'),
        "/catalogo": page("/catalogo", "Catálogo y fichas", "Compara la cobertura documental, las brechas técnicas y las ofertas de ejemplo.", opportunities + gaps + prices),
        "/prospeccion": page("/prospeccion", "Prospección", "Revisa el embudo, los bloqueos y los casos de seguimiento sobre datos sintéticos.", funnel + blocks + followup),
        "/atencion": page("/atencion", "Atención de consultas", "Compara escenarios de atención según la ficha disponible. El chatbot corresponde a una fase posterior.", service),
    }


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--port", type=int, default=8000, help="puerto en 127.0.0.1 (por defecto 8000)")
    args = parser.parse_args()
    responses = {
        path: ("text/html; charset=utf-8", html.encode("utf-8"))
        for path, html in render_pages().items()
    }
    responses["/tablero.css"] = ("text/css; charset=utf-8", Path(__file__).with_name("tablero.css").read_bytes())

    class Handler(BaseHTTPRequestHandler):
        def do_GET(self):
            self.respond()

        def do_HEAD(self):
            self.respond()

        def respond(self):
            response = responses.get(urlsplit(self.path).path)
            if response is None:
                self.send_error(404)
                return
            content_type, body = response
            self.send_response(200)
            self.send_header("Content-Type", content_type)
            self.send_header("Content-Length", str(len(body)))
            self.send_header("Cache-Control", "no-store")
            self.send_header("X-Content-Type-Options", "nosniff")
            self.end_headers()
            if self.command == "GET":
                self.wfile.write(body)

    with ThreadingHTTPServer(("127.0.0.1", args.port), Handler) as server:
        print(f"Tablero Maxilux: http://127.0.0.1:{server.server_port}/  ·  Ctrl+C para cerrar", flush=True)
        try:
            server.serve_forever()
        except KeyboardInterrupt:
            pass


if __name__ == "__main__":
    main()
