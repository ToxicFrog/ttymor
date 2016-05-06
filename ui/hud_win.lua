local HudWin = ui.Box:subclass {
  name = 'hud';
  visible = true;
  colour = { 192, 192, 192 };
  display_scrollbar = false;
  faces = { sw = '┣'; se = '┫'; }
}

function HudWin:__init(...)
  self.content = ui.VList {
    visible = true;
    name = "hudlist";
    size = { inf, 0 };
  }
  ui.Box.__init(self, ...)
end

function HudWin:setContent(title, content)
  self.visible = true
  self.title = title
  self.content:clear()
  for _,item in ipairs(content) do
    self.content:attach(item)
  end
  self:layout()
end

function HudWin:cmd_update_hud()
  self.content:clear()
  self.visible = false
  return true
end

return HudWin
