-- 'text' only: quality, material, decor, startPhoneme, phoneme,
-- adjective, ichor, insult, random,

-- noun: text, plural, [statue]
local text = {}

local function loadText(path)
  local dom = xml.load(path)
  for node in xml.walk(dom.root) do
    text[node.name] = text[node.name] or {}
    table.insert(text[node.name], xml.attrs(node))
  end
end

function dredmor.loadText()
  return dredmor.loadFiles(loadText, '/text.xml')
end

function dredmor.text(category, type)
  local words = text[category]
  return words[math.random(1, #words)][type or 'text']
end
