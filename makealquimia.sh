#!/usr/bin/env bash
# AlquimiaMD — MD → PDF o PPTX (con Mermaid)
# Uso:
#   ./makealquimia.sh input.md build/salida.pdf
#   ./makealquimia.sh input.md build/slides.pptx
# Lee variables desde .env (PDF_ENGINE, CSS_FILE, MERMAID_CONFIG, PAGE_ORIENTATION, REFERENCE_PPTX,...)

set -e

# Cargar variables de entorno (.env)
if [ -f ".env" ]; then
  export $(grep -v '^[# ]' .env | xargs)
fi

INPUT="${1:-}"
OUTPUT="${2:-}"

if [ -z "$INPUT" ] || [ ! -f "$INPUT" ]; then
  echo "Uso: $0 <input.md> <salida.(pdf|pptx)>"; exit 1
fi
# --- Recursos que puede necesitar pandoc (imágenes, estilos) ---
RESOURCE=".:docs:share:share/styles:${DIAGRAM_DIR}"
DIAGRAM_DIR="${DIAGRAM_DIR:-docs/assets/diagrams}"
echo "🖼  DIAGRAM_DIR: $DIAGRAM_DIR"
echo "🔎 RESOURCE PATH: $RESOURCE"
# --- Funciones ---
pick_engine() {
  if [ -n "${PDF_ENGINE:-}" ]; then echo "$PDF_ENGINE"; return; fi
  if command -v weasyprint >/dev/null 2>&1; then echo "weasyprint"; return; fi
  if command -v wkhtmltopdf >/dev/null 2>&1; then echo "wkhtmltopdf"; return; fi
  if command -v xelatex >/dev/null 2>&1; then echo "xelatex"; return; fi
  echo ""
}

# --- Herramientas base ---
command -v pandoc >/dev/null 2>&1 || { echo "❌ Falta pandoc"; exit 2; }
command -v mmdc   >/dev/null 2>&1 || { echo "❌ Falta Mermaid CLI (mmdc). npm i -g @mermaid-js/mermaid-cli"; exit 2; }

# --- Rutas / Filtros / CSS ---
LUA_FILTER="${LUA_FILTER_PATH:-alquimia/filters/mermaid.lua}"
CSS="${CSS_FILE:-share/styles/print.css}"
[ -f "$LUA_FILTER" ] || { echo "❌ Falta filtro: $LUA_FILTER"; exit 2; }
[ -f "$CSS" ]       || { echo "❌ Falta CSS: $CSS"; exit 2; }

# Info útil
echo "🎨 CSS usado: $CSS"
if [ -n "${MERMAID_CONFIG:-}" ]; then
  if [ -f "$MERMAID_CONFIG" ]; then echo "🜂 Mermaid config → $MERMAID_CONFIG"; else echo "⚠️ MERMAID_CONFIG no existe: $MERMAID_CONFIG"; fi
else
  echo "ℹ️ sin MERMAID_CONFIG (tema Mermaid por defecto)"
fi

# --- Salida ---
mkdir -p "$(dirname "$OUTPUT")"
EXT="${OUTPUT##*.}"

# --- Recursos que puede necesitar pandoc (imágenes, estilos) ---
RESOURCE=".:docs:share:share/styles"

# === MODO PPTX (slides) ===
if [ "$EXT" = "pptx" ]; then
  echo "🎞️  Modo PPTX (slides)"
  # Nota: PPTX no usa CSS; los estilos vienen del reference.pptx si lo pasas
  SLIDE_LEVEL="${SLIDE_LEVEL:-2}"        # encabezado de nivel 2 inicia slide
  CMD=(pandoc "$INPUT"
       --from=gfm+raw_html
       --lua-filter="$LUA_FILTER"
       --resource-path="$RESOURCE"
       -t pptx
       --slide-level="$SLIDE_LEVEL"
       -o "$OUTPUT")
  # Reference PPTX (opcional, para tu branding de slides)
  if [ -n "${REFERENCE_PPTX:-}" ] && [ -f "$REFERENCE_PPTX" ]; then
    CMD+=(--reference-doc="$REFERENCE_PPTX")
    echo "📎 reference.pptx → $REFERENCE_PPTX"
  fi

  echo "→ Generando: $OUTPUT"
  "${CMD[@]}"
  echo "✅ Listo: $OUTPUT"
  exit 0
fi

# === MODO PDF ===
if [ "$EXT" != "pdf" ]; then
  echo "❌ Extensión de salida no soportada: .$EXT (usa .pdf o .pptx)"; exit 2
fi

ENGINE="$(pick_engine)"
[ -n "$ENGINE" ] || { echo "❌ No hay motor PDF disponible (instala weasyprint o wkhtmltopdf o xelatex)"; exit 2; }

# Orientación/tamaño (para PDF)
PAGE_SIZE="${PAGE_SIZE:-A4}"
PAGE_ORIENTATION="${PAGE_ORIENTATION:-portrait}"  # portrait | landscape

# CSS temporal con @page y ajuste de alto de diagramas según orientación
TMP_CSS="$(mktemp /tmp/alquimia.XXXXXX.css)"
trap 'rm -f "$TMP_CSS"' EXIT

if [ "$PAGE_ORIENTATION" = "landscape" ]; then
  cat > "$TMP_CSS" <<CSS
@page { size: ${PAGE_SIZE} landscape; margin: 2cm; }
img.mermaid-diagram{ max-height: 17cm !important; }
CSS
else
  cat > "$TMP_CSS" <<CSS
@page { size: ${PAGE_SIZE} portrait; margin: 2cm; }
img.mermaid-diagram{ max-height: 24cm !important; }
CSS
fi

CMD=(pandoc "$INPUT"
     --from=gfm+raw_html
     --lua-filter="$LUA_FILTER"
     --pdf-engine="$ENGINE"
     --resource-path="$RESOURCE"
     --css="$CSS"
     --css="$TMP_CSS"
     -o "$OUTPUT")

# Ajustes por motor
if [ "$ENGINE" = "wkhtmltopdf" ]; then
  CMD+=(--pdf-engine-opt=--enable-local-file-access
        --pdf-engine-opt=--orientation
        --pdf-engine-opt="$PAGE_ORIENTATION")
elif [ "$ENGINE" = "xelatex" ]; then
  [ "$PAGE_ORIENTATION" = "landscape" ] && CMD+=(-V geometry:landscape)
  CMD+=(-V mainfont=Inter -V monofont="JetBrains Mono" -V geometry:margin=2cm)
fi

echo "🖨️  Modo PDF — Motor: $ENGINE — Tamaño: $PAGE_SIZE — Orientación: $PAGE_ORIENTATION"
echo "→ Generando: $OUTPUT"
"${CMD[@]}"
echo "✅ Listo: $OUTPUT"
