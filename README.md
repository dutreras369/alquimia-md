
# ✨ AlquimiaMD
> Transformar Markdown en PDF con gracia, color y símbolos.

**AlquimiaMD** es una herramienta modular para convertir archivos `.md` en **PDF enriquecidos**, integrando:
- Diagramas Mermaid (`flowchart`, `sequence`, `state`, etc.),
- Temas visuales personalizados en SCSS/CSS,
- Motores PDF autodetectados (`wkhtmltopdf`, `weasyprint`, `xelatex`),
- Flujo CLI reutilizable entre proyectos (`alquimia`).

---

## 🧭 Propósito

Este proyecto unifica los flujos dispersos de documentación y diseño técnico —que antes requerían comandos complejos de Pandoc, Mermaid y LaTeX— en una **sola invocación** reproducible, poética y portable.

---

## ⚙️ Instalación

```bash
# Crear entorno virtual
python3 -m venv .venv
source .venv/bin/activate

# Instalar dependencias
pip install -e .

# Dependencias del sistema
sudo apt install pandoc wkhtmltopdf -y
npm install -g @mermaid-js/mermaid-cli
```

---

## 🚀 Uso

```bash
# Compilar un archivo .md a PDF
alquimia docs/ng/adv/flujo/s4/Angular_Flujo_Reactivo.md --title "Angular — Flujo Reactivo"

# O toda una carpeta
alquimia docs/ng/adv/flujo --output build/pdfs
```

### Opciones

| Parámetro | Descripción |
|------------|-------------|
| `--css` | Define una hoja de estilo alternativa |
| `--engine` | Fuerza motor PDF: `wkhtmltopdf`, `weasyprint`, `xelatex` |
| `--meta` | Archivo YAML con metadatos (title, author, keywords) |
| `--title` | Título rápido sin editar el `.md` |
| `--output` | Carpeta o archivo PDF de salida |

---

## 🗂️ Estructura del proyecto

```
AlquimiaMD/
├── alquimia/
│   ├── cli.py
│   ├── engines.py
│   ├── mermaid.py
│   ├── util.py
│   └── filters/
│       └── mermaid.lua
├── share/
│   └── styles/
│       └── print.css
├── docs/
│   └── Angular_Flujo_Reactivo.md
├── .env.example
├── pyproject.toml
├── requirements.txt
├── README.md
└── infra/
    ├── infra-comandos.md
    └── env-windows.md
```

---

## 🧰 Recomendaciones y limpieza

| Elemento | Estado sugerido | Motivo |
|-----------|----------------|--------|
| `infra-comandos.md` | ✅ Mover a `infra/` | Documentación técnica auxiliar |
| `env-windows.md` | ✅ Mover a `infra/` | Configuración de entorno |
| `.env` real | ⚠️ Ignorar en Git | Usar solo `.env.example` |
| `docs/tests` | ❌ Eliminar si redundante | Mantener ejemplos clave |
| `fonts/` | 🔸 Opcional | Solo si no usas fuentes del sistema |
| `requirements.txt` + `pyproject.toml` | ✅ Mantener | Para empaquetado reproducible |

---

## 🌈 Autoría

Creado por **Davriel / Espacios Virtuales**,  
en el cruce entre código y símbolo.

> _“Doy al texto un cuerpo, al diagrama un cauce,  
> y al PDF un alma que respire.”_

---

## 🧙‍♂️ Próximos pasos

- Exportar a **DOCX/HTML** con estilo coherente  
- Integrar plantillas LaTeX personalizadas  
- Publicar en **PyPI** (`pip install alquimia-md`)  
- Automatizar builds con **GitHub Actions**  
- Extender compatibilidad con Windows y macOS

---

🜁 **Ecosistema Espacios Virtuales**  
_Arte, código y alquimia documental_
