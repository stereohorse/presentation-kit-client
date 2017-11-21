-----------------------------------------------------------------------------------------
--
-- main.lua
--
-----------------------------------------------------------------------------------------

-- Your code here
local json = require "json"
local widget = require "widget"


local pointer = {
  x = display.contentCenterX,
  y = display.contentCenterY
}


if not system.hasEventSource("gyroscope") then
  local txtOptions = {
    text = "no gyroscope!",
    x = display.contentCenterX,
    y = display.contentCenterY,
    font = native.systemFont
  }

  display.newText(txtOptions)
end


local function networkListener(event)
  if (event.isError) then
    local txtOptions = {
      text = "networ error: " .. event.response,
      x = display.contentCenterX,
      y = display.contentCenterY,
      font = native.systemFont
    }

    display.newText(txtOptions)
  end
end

local function sendMessage(type)
  local whiteboardEvent = {
    x = pointer.x,
    y = pointer.y,
    type = type
  }

  local params = {
    body = json.encode(whiteboardEvent)
  }

  network.request("http://192.168.0.46:8080/events", "POST", networkListener, params)
end


local drawBtnPressed = false
local firstDrawBtnPress = true

local drawBtn = widget.newButton({
  x = display.contentCenterX,
  y = display.contentCenterY,
  shape = "roundedRect",
  width = 100,
  height = 100,
  onPress = function() drawBtnPressed = true end,
  onRelease = function() drawBtnPressed = false end
})


local function onClear()
  sendMessage('CLEAR')
end

local function onReset()
  pointer.x = 0
  pointer.y = 0

  sendMessage('RESET')
end

local clearBtn = widget.newButton({
  left = 10,
  top = 10,
  shape = "roundedRect",
  label = "clear",
  width = 100,
  height = 50,
  onPress = onClear
})


local resetBtn = widget.newButton({
  left = display.contentWidth - 110,
  top = 10,
  shape = "roundedRect",
  label = "reset",
  width = 100,
  height = 50,
  onPress = onReset
})


local function onGyro(event)
  local dx = event.xRotation * event.deltaTime * 180 / math.pi
  local dz = event.zRotation * event.deltaTime * 180 / math.pi

  local changed = false

  if (math.abs(dx) > 0.1) then
    pointer.y = pointer.y + dx * -5
    changed = true
  end

  if (math.abs(dz) > 0.1) then
    pointer.x = pointer.x + dz * -5
    changed = true
  end

  if changed then
    local msgType = 'MOVE_POINTER'

    if (drawBtnPressed) then
      if (firstDrawBtnPress) then
        msgType = 'DRAW_START'
        firstDrawBtnPress = false
      else
        msgType = 'DRAW'
      end
    else
      firstDrawBtnPress = true
    end

    sendMessage(msgType)
  end
end

Runtime:addEventListener("gyroscope", onGyro)
