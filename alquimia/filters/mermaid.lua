-- filters/mermaid.lua
-- Renderiza ```mermaid``` (y también ```mermaidjs```) a SVG con mmdc
-- Cachea por hash, crea logs si falla, y soporta bloques anidados.

local utils = require 'pandoc.utils'
local stringify = (pandoc.utils and pandoc.utils.stringify) or function(x) return x end
local sha1 = (pandoc.utils and pandoc.utils.sha1) or function(s) return s end

local function ensure_dir(path)
  os.execute('mkdir -p "' .. path .. '"')
end

local function render_mermaid(code, out_file)
  -- Escribe a un temporal .mmd
  local in_file = os.tmpname() .. ".mmd"
  local f = io.open(in_file, "w")
  f:write(code)
  f:close()

  -- Ejecuta mmdc
  local cmd = string.format('mmdc -i "%s" -o "%s"', in_file, out_file)
  local ok = os.execute(cmd)

  -- Limpia el temporal (best-effort)
  os.remove(in_file)

  return (ok == true or ok == 0)
end

-- Convierte un CodeBlock mermaid en imagen SVG
local function handle_mermaid_block(code, caption)
  local diagram_dir = "docs/assets/diagrams"
  ensure_dir(diagram_dir)

  -- Hash del contenido para cache estable
  local hash = sha1(code)
  local out_file = diagram_dir .. "/" .. hash .. ".svg"

  -- Si ya existe, reusa
  local f = io.open(out_file, "r")
  if f ~= nil then
    f:close()
    return pandoc.Para({ pandoc.Image(caption or {}, out_file) })
  end

  -- Render
  local ok = render_mermaid(code, out_file)
  if not ok then
    io.stderr:write("[mermaid.lua] Falló mmdc, guardo el texto sin renderizar.\n")
    return pandoc.CodeBlock(code, {class = "mermaid"})
  end

  return pandoc.Para({ pandoc.Image(caption or {}, out_file) })
end

function CodeBlock(el)
  -- Acepta ```mermaid``` o ```mermaidjs```
  if el.classes:includes('mermaid') or el.classes:includes('mermaidjs') then
    return handle_mermaid_block(el.text, el.caption)
  end
  return nil
end

-- Por si viniera como RawBlock (raro, pero pasa en algunos pipelines)
function RawBlock(el)
  if el.format == "html" then
    local txt = tostring(el.text or "")
    if txt:match("<pre[^>]*class=[\"'][^\"']*mermaid[^\"']*[\"']") then
      local code = txt:gsub("<.->", "") -- naive: quita tags
      return handle_mermaid_block(code, nil)
    end
  end
  return nil
end
