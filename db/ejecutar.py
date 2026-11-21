"""Ejecutor reproducible de la base de datos SIG Maxilux (SQLite 3).

Prueba de oro (entorno limpio, cero dependencias externas):
    python db/ejecutar.py
"""
import argparse
import re
import sqlite3
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parent


def format_table(headers, rows):
    if not rows:
        return "(sin filas)"
    str_rows = [["" if v is None else str(v) for v in r] for r in rows]
    widths = [max(len(h), *(len(r[i]) for r in str_rows)) for i, h in enumerate(headers)]
    sep = "+-" + "-+-".join("-" * w for w in widths) + "-+"
    fmt = lambda vals: "| " + " | ".join(vals[i].ljust(widths[i]) for i in range(len(headers))) + " |"
    out = [sep, fmt(headers), sep]
    out.extend(fmt(r) for r in str_rows)
    out.append(sep)
    return "\n".join(out)


def split_queries(sql_text):
    pattern = re.compile(r"^--\s*===\s*(Q\d+:\s*.*?)===\s*$", re.MULTILINE)
    matches = list(pattern.finditer(sql_text))
    queries = []
    for idx, m in enumerate(matches):
        start = m.end()
        end = matches[idx + 1].start() if idx + 1 < len(matches) else len(sql_text)
        body = sql_text[start:end].strip()
        if body:
            queries.append((m.group(1).strip(), body))
    return queries


def main():
    parser = argparse.ArgumentParser(description="Carga schema.sql + seed.sql y ejecuta consultas.sql en SQLite 3.")
    parser.add_argument("--db", default=":memory:", help="Ruta del archivo SQLite de salida (por defecto :memory:)")
    args = parser.parse_args()

    if args.db != ":memory:":
        db_path = Path(args.db)
        if db_path.exists():
            db_path.unlink()

    conn = sqlite3.connect(args.db)
    conn.execute("PRAGMA foreign_keys = ON;")

    schema_sql = (BASE_DIR / "schema.sql").read_text(encoding="utf-8")
    seed_sql = (BASE_DIR / "seed.sql").read_text(encoding="utf-8")
    queries_sql = (BASE_DIR / "consultas.sql").read_text(encoding="utf-8")

    conn.executescript(schema_sql)
    conn.executescript(seed_sql)

    fk_errors = conn.execute("PRAGMA foreign_key_check;").fetchall()
    if fk_errors:
        raise RuntimeError(f"Errores de clave foránea detectados: {fk_errors}")

    print("=== VERIFICACIÓN DE INTEGRIDAD REFERENCIAL Y VOLUMEN ===")
    checks = [
        ("Grupos de producto", "SELECT COUNT(*) FROM grupo_producto"),
        ("Series comerciales", "SELECT COUNT(*) FROM serie_comercial"),
        ("Proveedores anonimizados", "SELECT COUNT(*) FROM proveedor"),
        ("Fichas técnicas", "SELECT COUNT(*) FROM ficha_tecnica"),
        ("Productos (SKUs MX)", "SELECT COUNT(*) FROM producto"),
        ("Ofertas proveedor (sintéticas)", "SELECT COUNT(*) FROM oferta_proveedor"),
        ("Especificaciones técnicas", "SELECT COUNT(*) FROM especificacion_producto"),
        ("Empresas prospecto/cliente", "SELECT COUNT(*) FROM empresa_cliente"),
        ("Contactos verificados", "SELECT COUNT(*) FROM contacto"),
        ("Prospecciones", "SELECT COUNT(*) FROM prospeccion"),
        ("Bloqueos Ley 21.719", "SELECT COUNT(*) FROM bloqueo_contacto"),
        ("Consultas de clientes", "SELECT COUNT(*) FROM consulta_cliente"),
        ("Derivaciones internas", "SELECT COUNT(*) FROM derivacion_consulta"),
        ("Violaciones FK (PRAGMA foreign_key_check)", "SELECT 0"),
    ]
    summary_rows = [(label, conn.execute(q).fetchone()[0]) for label, q in checks]
    print(format_table(["Entidad / Control", "Cantidad"], summary_rows))

    for title, sql in split_queries(queries_sql):
        print(f"\n=== {title} ===")
        cur = conn.execute(sql)
        headers = [d[0] for d in cur.description]
        rows = cur.fetchall()
        print(format_table(headers, rows))

    conn.close()
    print("\nEjecución completada sin errores.")


if __name__ == "__main__":
    main()
