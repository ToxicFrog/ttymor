-- ItemDB.xml support.
--[[
An <item> tag always contains name= and iconfile= (we probably don't care about
the latter). It may also have:
  level=X         tier of item
  artifact=1      item is an artifact, should have <artifact> tag
  craftoutput=1   item can be made with crafting
  overrideClassName not sure what this does, orbs have OCN="Orb"
  special=1       item should not randomly generated
  type            weapon type, enum {
    sword, axe, mace, staff, bow, thrown, bolt, dagger, polearm }
  maxstack=       maximum generated stack size?

Most of the meat is in the tags that are children of the <item> tag.
It looks like Dredmor uses a similar entity-component system!

So far I've seen:
<description text="...">
<price amount="X">
<food hp="X" mp="X" meat="0|1" effect="...">
  "meat" actually means "non-vegan", so cheese has it
  effect is a name in spellDB
<weapon slashing="X" piercing="X" crushing="X" necromantic="X" ...
  hit="spell effect name" thrown="name of thrown sprite" cantargetfloor="1">
<artifact quality="X">
  X is number of modifiers to add?
<primarybuff id="X" amount="Y">
  X is primary stat id, enum { bur, sag, nim, cad, stb, sav }
<secondarybuff id="X" amount="Y">
  X is secondary stat id, enum {
    HP, MP, melee power, magic power, crit, haywire,
    dodge, block, counter, enemy dodge reduction, armour absorbtion,
    resist, sneakiness, HP regen, MP regen,
    wand burnout reduction, trap sense level, trap sight radius, sight radius
  }
<resistbuff piercing="X" ...>
<damagebuff piercing="X" ....>
<armour level="X" type="head|chest|waist|legs|feet|shield|hands|ring|neck">
<targetHitEffectBuff percentage="XXX" name="effect name">
<thrownBuff percentage="XXX" name="effect name">
  only on some gloves? Applies to thrown weapons while wearing, presumably

The file also contains <power> tags, which map weapon proc names and descriptions
to spell effects in spellDB.
<power name="proc name" description="proc desc" spell="spell name" />
]]

local items = {}

local function itemFromXML(dom)
  local def = {
    name = dom.attr.name;
    Render = { face = '⎊' };
    Item = { categories = {} };
  }
  for _,component in ipairs(dom.el) do
    def.Item.categories[component.name] = true
    if component.name == "description" then
      def.Item.description = component.attr.text
    end
  end
  entity.register(def.name)(def)
  return def
end

local function loadItems(path)
  local dom = xml.load(path)
  local count = 0
  for itemdef in xml.walk(dom.root, 'item') do
    if items[itemdef.attr.name] then
      log.debug("skipping duplicate item definition %s", itemdef.attr.name)
    else
      count = count+1
      local item = itemFromXML(itemdef)
      items[item.name] = item
    end
  end
  log.debug("Loaded %d items from %s", count, path)
end

function dredmor.loadItems()
  loadItems(flags.parsed.dredmor_dir..'/game/itemDB.xml')
  loadItems(flags.parsed.dredmor_dir..'/expansion/game/itemDB.xml')
  loadItems(flags.parsed.dredmor_dir..'/expansion2/game/itemDB.xml')
  loadItems(flags.parsed.dredmor_dir..'/expansion3/game/itemDB.xml')
end

function dredmor.items(filter)
  local R = {}
  filter = filter or f' => true'
  for _,item in pairs(items) do
    if filter(item) then
      R[item.name] = item
      table.insert(R, item)
    end
  end
  log.debug("Returning filtered list of %d items", #R)
  return R
end
