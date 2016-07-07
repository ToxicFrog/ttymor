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
  local w = self:getChildBB().w
  self.visible = true
  self.title = title:sub(1,w-2)
  self.content:clear()
  for _,line in ipairs(content) do
    if type(line) == 'string' then
      self.content:attach(ui.WrappingTextLine {
        text = line; wrap_width = w;
      })
    else
      self.content:attach(line)
    end
  end
  self:layout()
end

function HudWin:cmd_update_hud()
  self.content:clear()
  self.visible = false
  return true
end

return HudWin
