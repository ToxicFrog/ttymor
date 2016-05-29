-- ItemDB.xml support.
--[[
An <item> tag always contains name= and iconfile= (we probably don't care about
the latter). It may also have:
  level=X         tier of item
  artifact=1      item is an artifact, should have <artifact> tag
  craftoutput=1   item can be made with crafting
  overrideClassName display this instead of the item's actual category; used for
                  e.g. orbs so that they show up as "Orb" rather than "Shield"
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
<potion spell="spell name">
<wand spell="spell name" mincharge="X" maxcharge="Y">

The file also contains <power> tags, which map weapon proc names and descriptions
to spell effects in spellDB.
<power name="proc name" description="proc desc" spell="spell name" />

]]

local items = {}
local components = {}

local faces = {
  -- Weapons
  Sword   = '⸔';
  Axe     = 'Γ';
  Mace    = '¶';
  Staff   = 'ƪ';
  Bow     = 'Ϯ';
  Thrown  = '✢';
  Bolt    = '➶';
  Dagger  = '†';
  Polearm = '⸕';
  Orb     = '⍟';
  Tome    = '⌺';
  -- Armour
  Helm    = '⌓';
  Armour  = '⍞';
  Belt    = '⑄';
  Pants   = 'Π';
  Boots   = '⅃';
  Gloves  = 'ﬀ';
  Shield  = '⩌';
  Ring    = '⍥';
  Amulet  = '⍜';
  -- Consumables
  Food    = '%';
  Drink   = '∪';
  Trap    = '▩';
  Wand    = '/';
  Potion  = '!';
  Mushroom= '⊼';
  -- Crafting
  Tool    = '✇';
  Gem     = '❂';
  Reagent = '❚';
}

function components:description(item)
  item.Item.description = self.attr.text
end

function components:price(item)
  item.Item.price = tonumber(self.attr.amount)
end

function components:armour(item)
  local armour_types = {
    head = 'Helm'; chest = 'Armour'; waist = 'Belt'; legs = 'Pants';
    feet = 'Boots'; shield = 'Shield'; hands = 'Gloves'; ring = 'Ring'; neck = 'Amulet';
  }
  item.Item.category = item.Item.category or armour_types[self.attr.type]
  item.Item.level = item.Item.level or tonumber(self.attr.level)
end

function components:food(item)
  item.Item.category = self.attr.mp and 'Drink' or 'Food'
end

local function genericComponent(self, item)
  item.Item.category = self.name:gsub('^[a-z]', string.upper)
end

for _,tag in ipairs { 'potion', 'wand', 'toolkit', 'trap', 'mushroom', 'gem' } do
  components[tag] = genericComponent
end

local function addComponent(item, component)
  if components[component.name] then
    components[component.name](component, item)
  end
end

-- Figure out an item's category from the <item> DOM.
-- For most items we infer the category from the item components, but for some
-- things we have to look at the DOM:
-- - items with overrideClassName set are mechanically identical to an existing
--   category, like Shield, but have their own category name, like Orb or Tome
-- - weapons will have type=... indicating the weapon type
-- - alchemical reagents will have alchemical=1
-- - as a special case (eurgh), items with "scrap" in the name, from expansion2,
--   are also considered reagents
-- Items for which even the component handler can't figure it out use the default
-- for the Item component, which is 'Misc'.
local function itemCategory(dom)
  local weapon_types = { [0] = "Sword", "Axe", "Mace", "Staff", "Bow", "Thrown", "Bolt", "Dagger", "Polearm" }
  if dom.attr.overrideClassName then
    return dom.attr.overrideClassName
  elseif dom.attr.type then
    return weapon_types[tonumber(dom.attr.type)]
  elseif dom.attr.alchemical or dom.attr.name:match('Scrap') then
    return 'Reagent'
  end
end

local function itemFromXML(dom)
  local def = {
    name = dom.attr.name;
    Render = { face = '⁇'; colour = { 0,0,0, 255,0,0 } };
    Interactable = {};
    Item = {
      level = tonumber(dom.attr.level);
      special = dom.attr.special;
      category = itemCategory(dom);
    };
  }
  for _,component in ipairs(dom.el) do
    addComponent(def, component)
  end
  if faces[def.Item.category] then
    def.Render.face = faces[def.Item.category]
    def.Render.colour = nil
  end
  entity.register(def.name)(def)
  return def
end

local function loadItems(path)
  local dom = xml.load(path)
  local count = 0
  for itemdef in xml.walk(dom.root, 'item') do
    if items[itemdef.attr.name] then
      log.warning("skipping duplicate item definition %s", itemdef.attr.name)
    else
      count = count+1
      local item = itemFromXML(itemdef)
      items[item.name] = item
      table.insert(items, item)
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

function dredmor.randomItem()
  local i = math.random(1,#items)
  return items[i].name,items[i]
end
