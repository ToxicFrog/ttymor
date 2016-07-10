settings.Bool {
  name = 'Colour-code items by rank';
  category = 'Inventory';
  value = true;
  help = 'Colour-code item icons by item rank. Requires restart.';
  helps = {
    ['highest rank'] = 'Sort inventory items by highest rank first; sort items of same rank by name.',
    ['lowest rank'] = 'Sort inventory items by lowest rank first; sort items of same rank by name.',
    ['name'] = 'Sort inventory items by name only, ignoring rank.',
  };
}

settings.Enum {
  name = 'Hilight artifacts';
  category = 'Inventory';
  value = 'background';
  values = { 'foreground', 'background', 'inverse', 'no' };
  helps = {
    foreground = 'Display artifacts with a different foreground colour. Note that this will override their rank-specific colour if "colour-code items by rank" is on.';
    background = 'Display artifacts with a different background colour.';
    bold = 'Display artifacts in bold. Depending on your terminal/font, this may not work.';
    no = 'Do not hilight artifacts in any way.';
  };
}

local Item = {
  stackable = true;
  artifact = false;
  count = 1;
  description = "***BUG***";
  rank = 0;
  category = 'Misc';
  face = '?';
}

local rank_colours = {
  -- items with no specified rank get a glaring "this is a bug" colour scheme
  [0] = { 0, 0, 0, 255, 255, 255 };

  -- ranks 1-10 in 2-rank increments
  { 192, 192, 192 };  -- grey
  { 0,   255, 0   };  -- green
  { 0,   255, 255 };  -- cyan
  { 128, 64,  255 };  -- magenta
  { 255, 128, 0   };  -- orange

  -- All ranks above 10
  { 255, 0,   255 };
}
local function colourForRank(rank)
  return unpack(rank_colours[(rank/2):ceil():min(6)])
end

-- Item implements the Render protocol; Items may change how they render based
-- on settings, which the basic Render component can't handle.
function Item:render(x, y)
  tty.style('o')
  if settings.inventory.colour_code_items_by_rank then
    tty.colour(colourForRank(self.Item.rank))
  else
    tty.colour(192, 192, 192)
  end
  if self.Item.artifact then
    if settings.inventory.hilight_artifacts == 'foreground' then
      tty.colour(255, 255, 0) -- yellow
    elseif settings.inventory.hilight_artifacts == 'background' then
      tty.bgcolour(64, 64, 64) -- dark grey
    elseif settings.inventory.hilight_artifacts == 'inverse' then
      tty.style('v')
    end
  end
  tty.put(x, y, self.Item.face)
end

-- TODO: figure out how to let different components add things to the examination
-- results, e.g. equipment should show stats and comparison to current gear, food
-- should show amount healed, etc.
local x_order = { 'Item' }
function Item:msg_verb_examine_by()
  local desc = {}
  self:message('describe', desc)
  local desc_lines = {}
  for _,name in ipairs(x_order) do
    for _,line in ipairs(desc[name] or {}) do
      table.insert(desc_lines, line)
    end
  end
  ui.message(tostring(self), desc_lines)
end

function Item:msg_describe(desc)
  desc.Item = {}
  stars = ('★'):rep(self.Item.rank)..('☆'):rep(10-self.Item.rank)
  table.insert(desc.Item, ui.LeftRightTextLine {
    left = stars; right = 'Ƶ%s' % self.Item.price;
  })
  if self.Item.special then
    table.insert(desc.Item, '[non-spawning]')
  end
  if self.Item.artifact then
    table.insert(desc.Item, '[artifact]')
  end
  table.insert(desc.Item, ui.TextLine { text = '' })
  table.insert(desc.Item, self.Item.description)

  return desc
end

function Item:stackWith(other)
  assert(other.type == self.type)
  assert(self.Item.stackable and other.Item.stackable)

  self.Item.count = self.Item.count + other.Item.count
  other:delete()
end

function Item:msg_verbs(verbs)
  verbs.examine = true
  if self.Item.held_by then
    verbs.drop = true
    verbs.dropN = true
  else
    verbs.pickup = true
  end
  return verbs
end

function Item:msg_tostring(string)
  if self.Item.count > 1 then
    table.insert(string, 'x%d' % self.Item.count)
  end
end

return Item
