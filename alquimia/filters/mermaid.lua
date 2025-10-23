-- alquimia/filters/mermaid.lua — robusto para PDF y PPTX
local utils = require 'pandoc.utils'
local sha1  = (utils and utils.sha1) or function(s) return s end

-- === Entorno ===
local OUT_FMT         = "png"
local PNG_WIDTH       = os.getenv("MERMAID_PNG_WIDTH")  or "1200"
local PNG_HEIGHT      = os.getenv("MERMAID_PNG_HEIGHT") or "3200"
local PNG_SCALE       = os.getenv("MERMAID_SCALE")      or ""
local PNG_BG          = os.getenv("MERMAID_BG")         or "white"
local MERMAID_CONFIG  = os.getenv("MERMAID_CONFIG")     or ""
local DIAGRAM_DIR     = os.getenv("DIAGRAM_DIR")        or "docs/assets/diagrams"
local PWD             = os.getenv("PWD")                or "."

local function ensure_dir(path) os.execute('mkdir -p "' .. path .. '"') end

local function slurp(path)
  local f = io.open(path, "rb"); if not f then return nil end
  local c = f:read("*all"); f:close(); return c
end

local function abspath(path)
  if path:sub(1,1) == "/" then return path end
  return PWD .. "/" .. path
end

local function render_mermaid(code, out_rel)
  local out_abs = abspath(out_rel)
  local in_file = os.tmpname() .. ".mmd"
  local f = io.open(in_file, "w"); f:write(code); f:close()

  local sizeFlags = string.format('-w %s -H %s', PNG_WIDTH, PNG_HEIGHT)
  if PNG_SCALE ~= "" then sizeFlags = sizeFlags .. string.format(' -s %s', PNG_SCALE) end

  local cmd
  if MERMAID_CONFIG ~= "" and io.open(MERMAID_CONFIG, "r") ~= nil then
    cmd = string.format('mmdc -i "%s" -o "%s" -c "%s" -b %s %s',
                        in_file, out_abs, MERMAID_CONFIG, PNG_BG, sizeFlags)
  else
    if MERMAID_CONFIG ~= "" then
      io.stderr:write("[mermaid.lua] MERMAID_CONFIG no encontrado: " .. MERMAID_CONFIG .. " (sigo sin config)\n")
    end
    cmd = string.format('mmdc -i "%s" -o "%s" -b %s %s', in_file, out_abs, PNG_BG, sizeFlags)
  end

  local ok = os.execute(cmd)
  os.remove(in_file)
  return (ok == true or ok == 0)
end

local function image_div(out_rel, caption)
  -- insertar con ruta relativa (Pandoc la empaqueta en PPTX y la lee en PDF)
  local imgAttr = pandoc.Attr("", {"mermaid-diagram"}, {["width"] = "100%"})
  local img = pandoc.Image(caption or {}, out_rel, "", imgAttr)
  local divAttr = pandoc.Attr("", {"diagram-block"})
  return pandoc.Div({ pandoc.Para({ img }) }, divAttr)
end

local function handle_mermaid_block(code, caption)
  ensure_dir(DIAGRAM_DIR)

  local cfg_blob = (MERMAID_CONFIG ~= "" and (slurp(MERMAID_CONFIG) or "")) or ""
  local hash_src = table.concat({code, cfg_blob, PNG_WIDTH, PNG_HEIGHT, PNG_SCALE, PNG_BG}, "::")
  local hash     = sha1(hash_src)
  local out_rel  = string.format("%s/%s.%s", DIAGRAM_DIR, hash, OUT_FMT)

  local existed = io.open(abspath(out_rel), "r")
  if existed ~= nil then
    existed:close()
    return image_div(out_rel, caption)
  end

  local ok = render_mermaid(code, out_rel)
  if not ok then
    io.stderr:write("[mermaid.lua] mmdc falló, dejo el bloque como código plano.\n")
    return pandoc.CodeBlock(code, {class = "mermaid"})
  end

  return image_div(out_rel, caption)
end

function CodeBlock(el)
  if el.classes:includes('mermaid') or el.classes:includes('mermaidjs') then
    return handle_mermaid_block(el.text, el.caption)
  end
  return nil
end

function RawBlock(el)
  if el.format == "html" then
    local txt = tostring(el.text or "")
    if txt:match("<pre[^>]*class=[\"'][^\"']*mermaid[^\"']*[\"']") then
      local code = txt:gsub("<.->", "")
      return handle_mermaid_block(code, nil)
    end
  end
  return nil
end
