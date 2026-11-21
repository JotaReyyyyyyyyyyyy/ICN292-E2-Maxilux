# ICN-292 · Entrega 2 — Solución SIG Final: Maxilux

Repositorio oficial de la **Entrega 2 (E2)** de la asignatura **ICN-292 — Sistemas de Información para la Gestión** (Universidad Técnica Federico Santa María, Campus Vitacura, Segundo Semestre 2026).

> **Nota sobre continuidad del caso:** El caso PYME se actualizó de *Unter* (Entrega 1) a **Maxilux**, empresa perteneciente a los mismos dueños que opera exactamente bajo el mismo modelo de intermediación y distribución (2 personas internas) y presenta los mismos problemas de negocio. La justificación formal y trazabilidad completa están en [docs/00-caso-pyme.md](docs/00-caso-pyme.md) y [CHANGELOG.md](CHANGELOG.md).
>
> **Privacidad y anonimización:** Todos los datos cargados en `db/seed.sql` son anonimizados o sintéticos coherentes con la escala real de la PYME. Este repositorio no contiene credenciales, API keys, costos reales de proveedores, nombres reales de proveedores ni correos reales de clientes o prospectos.

---

## 1. Prueba de oro (reproducibilidad en entorno limpio)

Cualquier ayudante o docente puede verificar el esquema **3FN**, cargar los datos y ejecutar las **7 consultas de negocio** en menos de 10 segundos utilizando **SQLite 3** (incluido de serie en Python 3, sin necesidad de instalar motores ni servidores externos):

### Opción A — Ejecutor directo en Python (sin dependencias externas)

```bash
git clone https://github.com/JotaReyyyyyyyyyyyy/ICN292-E2-Maxilux.git
cd ICN292-E2-Maxilux
python db/ejecutar.py
```

El script `db/ejecutar.py` realiza automáticamente en memoria (`:memory:`):
1. Activa `PRAGMA foreign_keys = ON`.
2. Carga `db/schema.sql` (16 tablas en 3FN + 2 vistas).
3. Carga `db/seed.sql` (511 SKUs reales anonimizados, 133 fichas técnicas, 370 ofertas multi-proveedor sintéticas, 1.827 especificaciones técnicas, 25 empresas `.example`, 30 contactos, 25 prospecciones, 5 bloqueos Ley 21.719, 24 consultas y 15 derivaciones).
4. Ejecuta `PRAGMA foreign_key_check` verificando **0 errores**.
5. Ejecuta e imprime de forma tabular las consultas `Q1` a `Q7` definidas en `db/consultas.sql`.

Si se desea persistir el archivo SQLite en disco para inspeccionarlo con DBeaver o DB Browser:

```bash
python db/ejecutar.py --db maxilux_e2.sqlite
```

### Opción B — CLI nativo `sqlite3`

```bash
sqlite3 maxilux_e2.sqlite < db/schema.sql
sqlite3 maxilux_e2.sqlite < db/seed.sql
sqlite3 -header -column maxilux_e2.sqlite < db/consultas.sql
```

---

## 2. Estructura del repositorio

```text
Entrega 2/
├── README.md                          # Esta guía (prueba de oro reproducible)
├── CHANGELOG.md                       # Trazabilidad detallada Entrega 1 -> Entrega 2
├── ENLACE_GITHUB.txt                  # URL del repositorio y tag/commit defendido
├── .gitignore                         # Protección contra fuga de credenciales/archivos locales
├── db/
│   ├── schema.sql                     # DDL SQLite 3 normalizado a 3FN (16 tablas + 2 vistas)
│   ├── seed.sql                       # DML anonimizado y sintético coherente (511 SKUs, 133 fichas)
│   ├── consultas.sql                  # 7 consultas SQL de negocio (Q1 a Q7)
│   └── ejecutar.py                    # Runner reproducible (stdlib Python, cero dependencias)
├── docs/
│   ├── 00-caso-pyme.md                # Caso Maxilux, justificación Unter->Maxilux y métricas
│   ├── 01-requerimientos.md           # Actores, alcance y requisitos RF/RNF actualizados
│   ├── 02-bpmn.md                     # Evolución BPMN AS-IS / TO-BE y mapeo a n8n
│   ├── 03-modelo-datos.md             # Normalización 1FN->2FN->3FN, anomalías evitadas y diccionario
│   ├── 04-sql-consultas.md            # Resultados ejecutados e interpretación de Q1 a Q7
│   ├── 05-automatizacion-n8n.md       # Flujos n8n exportados, arquitectura Worker y trazabilidad BPMN
│   ├── 07-etica-ley-21719.md          # Cumplimiento Ley 21.719, privacidad y control humano
│   └── DECLARACION_IA.md              # Declaración transparente de uso de Inteligencia Artificial
├── automatizacion/
│   ├── prospeccion/                   # 4 flujos n8n (Docker y localhost), plantilla Excel y config.env.example
│   └── fichas/                        # Flujos n8n de generación de fichas técnicas (sanitizados)
├── assets/
│   ├── bpm/                           # Modelos fuente Bizagi (.bpm) de continuidad E1
│   └── diagramas/                     # Diagramas TikZ (.tex, .pdf, .png) de ER 3FN, BPMN E2 y Arquitectura
├── informe/
│   ├── ICN292_P100_E2_Godoy_Tapia.tex # Fuente LaTeX del informe final
│   └── ICN292_P100_E2_Godoy_Tapia.pdf # Informe final compilado
└── presentacion/
    ├── ICN292_P100_E2_Godoy_Tapia_Presentacion.tex # Guion visual Beamer (9 diapositivas)
    └── ICN292_P100_E2_Godoy_Tapia_Presentacion.pdf # Presentación PDF para defensa (<= 7 min)
```

---

## 3. Equipo y asignatura

**Grupo 2 · Paralelo 100 · Profesor: Patricio Eduardo Cifuentes Reyes**  
Universidad Técnica Federico Santa María · Campus Vitacura · Segundo Semestre 2026

| Nombre completo | Rol en la Entrega 2 |
|---|---|
| Juan Pablo Godoy Fajardo | Evidencia del caso, integración Sheets/n8n y gobernanza de datos |
| Vicente Soto Martínez | Diseño de procesos BPMN, indicadores KPI y presentación |
| Joaquín Tapia Mandiola | Modelo de datos 3FN, arquitectura lógica y automatización |
| Claudio Vera Avila | Scripts SQL (`schema.sql`, `seed.sql`), consultas y reproducibilidad |
