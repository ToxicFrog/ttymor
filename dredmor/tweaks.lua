-- Support for Dredmor's tweakDB.xml
-- Tweaks loaded from it are registered as hidden settings.

settings.Category { name = 'Tweaks (Global)' }
settings.Category { name = 'Tweaks (Easy)' }
settings.Category { name = 'Tweaks (Medium)' }
settings.Category { name = 'Tweaks (Hard)' }

local cats = {
  tweakDB = 'Tweaks (Global)';
  easy = 'Tweaks (Easy)';
  medium = 'Tweaks (Medium)';
  hard = 'Tweaks (Hard)';
}

function dredmor.loadTweaks()
  local dom = xml.load(flags.parsed.dredmor_dir..'/game/tweakDB.xml')
  local cat = 'Tweaks (Global)'
  for node in xml.walk(dom.root, 'tweak') do
    local cat = cats[node.parent.name]
    if node.attr.fval then
      settings.Float {
        category = cat;
        name = node.attr.name;
        value = tonumber(node.attr.fval);
      }
    elseif node.attr.ival then
      settings.Int {
        category = cat;
        name = node.attr.name;
        value = tonumber(node.attr.ival);
      }
    else
      error(repr(node))
    end
  end
end
