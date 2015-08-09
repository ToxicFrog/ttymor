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

--
-- Notes on TweakDB settings
-- This is largely guesswork; please add to it as you figure things out.
--[[
  num lutefisk statues
  num quest statues
  num shelves per level
Minimum value.

  additional number of monsters per room per level
Defaults to 2, which seems high (that's 100-120 extra monsters on level 1,
going up by 50-60 per floor).

  dredmor statues per level
  numstairs
  number of reagents per level
Not sure if this is minimum or exact.

  max shops
  max wizard graffitis
Self-explanatory.

  treasure roll size
  {weapon,armour,ring,ammo,food,potion,lockpick,mushroom,wand} roll {min,max}
Used for treasure generation; generate a number between 0 and (treasure roll size-1),
then see which range it falls in, then generate an item of that type.

  minimum number of treasures
  maximum additional treasures
I think this means it places between (minimum) and (minimum+maximum) treasures
per level, but the naming might be misleading; min+max seems like a lot. TODO:
fire up dredmor and take a look.

  minimum blockers
  blocker number a
  blocker number b
  dispenser chance
  fountain chance
  uberchest chance
  anvil chance
  bbq chance
  freezer chance
Not sure how these work. Does 'minimum blockers' count customblockers from room
files, or only randomly placed ones? And what do the other numbers mean? At first
I thought they were 1-in-N values -- e.g. a given blocker has a 1 in 12 chance
to be blocker A or B, or a 1 in 80 chance to be an uberchest -- but under that
assumption they sum up to less than 0.5.

There's a comment that says "blockers are 1-in-X, right?" but it doesn't sound
very certain.

  number of teleporters
Again, not sure if this is min, max, or exact

  gold drop per level
Note that there's also per-difficult-level gold-per-kill and gold-per-floor settings.
Is this one even hooked up anymore?

  artifact quality museum multiplier
  item power granting chance
God-related settings.

  lutefisk divider
  additional monster grace period
  horde room grace period

  dredmor statue break exp
  lockpick exp

  entropy min
  entropy max
  entropy scale
For wands. Results in starting entropy from 5 to 30.

  burn min
  burn max
  burn scale
Results in burn rate from 2 to 10.

  monster hurt anim time
  corpse time
  max shops

  box muller std dev
Uberchest. Based on comments elsewhere, probably the stddev of the distribution used
to determine chest level; higher values == more likely variance from dungeon level.

  monster loot drop chance

  percent chance a found recipe is encrusting

  bad weapon penalty
  bad dual wield penalty
This penalty is a *divider* to the original stat, not a subtraction.

  miss ammo drop percent
  hit ammo drop percent
  hit thrown drop percent

  blood magic inc level 0
  blood magic inc level 1
  blood magic inc level 2
  blood magic inc level 3
  blood magic inc level 4

  midas scaler

  tooltip border size
Probably don't need to care about this one. :)

  trap XP scale

  boss mob XP scaler

  small random food buff
  small random food buff variation

--- PER-DIFFICULTY-LEVEL SETTINGS ---

  monster HP global scale
  monster additional HP percent per level
  monster additional HP per level

  artifact quality museum multiplier

  monster level adder
  experience n
  monster boost chance

  store buy price scaler
  store sell price scaler
  vending machine scale

  hpregenturns
  spregenturns

  monsterspawnturns
  minimum number of monsters in room
  maximum number of additional monsters

  horde chance
  minimum horde size
  additional horde size
  horde is overpowered chance
Last of these is 1 in N, seems likely horde chance is as well.

  named monster chance
  additional named monster primary point budget
  additional named monster secondary point budget
  additional named monster damage per level
  named monster box muller
As with uberchests, deviation from dungeon level

  num traps per level
  trap XP scale

  gold amount per level
Modifier for monster drops.

  zorkmids per level
Gold on the floor, probably. Multiplied by (level+1), which since dredmor levels
start at 0 means it starts at 300, not 600.

  minimum food per level
Is this 40, or 40 * depth? Latter seems really high.

  monster level sneaking penalty

  instability proc rate
]]
