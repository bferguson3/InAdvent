local Button = {
  position = lovr.math.newVec3(0,0,0),
  size = lovr.math.newVec3(0.4, 0.2, 0.05),
  onPressed = function() end, -- button is pressed
  onReleased = function() end, -- button is lifted
  onActuate = function() end, -- button is lifted with cursor still inside
  label = "Untitled",
  fraction = 0.0,
  isToggle = false,
  font = lovr.graphics.newFont(32)
}

-- todo: reuse this button for the HoverKeyboard
function Button:new(o)
  o = o or {}
  setmetatable(o, self)
  self.__index = self
  o.collider = Button.letters.world:newBoxCollider(o.position.x, o.position.y, o.position.z, o.size.x, o.size.y, o.size.z)
  o.collider:setUserData(o)
  return o
end
function Button:remove()
  self.collider:destroy()
end
function Button:draw()
  lovr.graphics.setFont(self.font)
  lovr.graphics.setColor(0.3, 0.3, 0.4)
  lovr.graphics.box('fill', self.position, self.size)

  lovr.graphics.setColor(0.9, 0.9, 0.9)
  local depth = 0.05
  local buttonPos = self.position + lovr.math.vec3(0,0,(1.0-self.fraction) * depth + 0.01)
  lovr.graphics.print(self.label, buttonPos + lovr.math.vec3(0,0,self.size.z/2 + 0.01), 0.07)

  lovr.graphics.setColor(0.5, 0.5, self.highlighted and 0.7 or 0.6)
  lovr.graphics.box('fill', buttonPos, self.size - lovr.math.vec3(0.05,0.05,0))
end
function Button:update()
end
function Button:highlight()
  self.highlighted = true
end
function Button:dehighlight()
  self.highlighted = false
end
function Button:select()
  if self.isToggle == false then
    self.selected = true
    self.fraction = 1.0
    self.onPressed(self)
  end
end
function Button:deselect()
  if self.isToggle == false then
    self.selected = false
    self.onReleased(self)
  else
    self.selected = not self.selected
    if self.selected then
      self.onPressed(self)
    else
      self.onReleased(self)
    end
  end
  self.fraction = self.selected and 1.0 or 0.0
end
function Button:setSelected(newValue)
  self.selected = newValue
  self.fraction = self.selected and 1.0 or 0.0
end
function Button:actuate()
  self.onActuate(self)
end

return Button