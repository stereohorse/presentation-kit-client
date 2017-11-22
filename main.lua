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

local origin = {
  x = 0,
  y = 0
}

local scrollSpeed = 100


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

local function sendRaw(msg)
  local params = {
    body = json.encode(msg)
  }

  network.request("http://92.53.78.222:8080/events", "POST", networkListener, params)
end

local function sendMessage(type)
  local whiteboardEvent = {
    x = pointer.x,
    y = pointer.y,
    type = type
  }

  sendRaw(whiteboardEvent)
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
  origin.x = 0
  origin.y = 0

  pointer.x = 0
  pointer.y = 0

  sendMessage('CLEAR')
end

local function onReset()
  pointer.x = -origin.x
  pointer.y = -origin.y

  sendMessage('MOVE_POINTER')
end

local clearBtn = widget.newButton({
  left = 10,
  top = 10,
  shape = "roundedRect",
  label = "clr",
  width = 50,
  height = 50,
  onPress = onClear
})


local resetBtn = widget.newButton({
  left = display.contentWidth - 60,
  top = 10,
  shape = "roundedRect",
  label = "clbr",
  width = 50,
  height = 50,
  onPress = onReset
})

local sensitivity = 5

local function sensitivitySliderListener(event)
  sensitivity = event.value / 100 * 20
end

local sensitivitySlider = widget.newSlider({
  left = 10,
  top = 80,
  width = display.contentWidth - 20,
  value = 25,
  listener = sensitivitySliderListener
})


local function scrollX(delta)
  pointer.x = pointer.x - delta
  origin.x = origin.x + delta

  local scrollEvent = {
    x = pointer.x,
    y = pointer.y,
    dx = delta,
    dy = 0,
    type = 'MOVE_CANVAS'
  }

  sendRaw(scrollEvent)
end

local function scrollY(delta)
  pointer.y = pointer.y - delta
  origin.y = origin.y + delta

  local scrollEvent = {
    x = pointer.x,
    y = pointer.y,
    dx = 0,
    dy = delta,
    type = 'MOVE_CANVAS'
  }

  sendRaw(scrollEvent)
end

local scrollLeftBtn = widget.newButton({
  x = 35,
  y = display.contentCenterY,
  shape = "roundedRect",
  label = "<",
  width = 50,
  height = 100,
  onPress = function() scrollX(scrollSpeed) end
})

local scrollRightBtn = widget.newButton({
  x = display.contentWidth - 35,
  y = display.contentCenterY,
  shape = "roundedRect",
  label = ">",
  width = 50,
  height = 100,
  onPress = function() scrollX(-scrollSpeed) end
})

local scrollUpBtn = widget.newButton({
  left = display.contentCenterX - 50,
  top = 10,
  shape = "roundedRect",
  label = "^",
  width = 100,
  height = 50,
  onPress = function() scrollY(-scrollSpeed) end
})

local scrollDownBtn = widget.newButton({
  left = display.contentCenterX - 50,
  top = display.contentHeight - 60,
  shape = "roundedRect",
  label = "v",
  width = 100,
  height = 50,
  onPress = function() scrollY(scrollSpeed) end
})

local function onGyro(event)
  local dx = event.xRotation * event.deltaTime * 180 / math.pi
  local dz = event.zRotation * event.deltaTime * 180 / math.pi

  local changed = false

  if (math.abs(dx) > 0.1) then
    pointer.y = pointer.y + dx * -sensitivity
    changed = true
  end

  if (math.abs(dz) > 0.1) then
    pointer.x = pointer.x + dz * -sensitivity
    changed = true
  end

  if changed then
    local drawEvent = {
      x = pointer.x,
      y = pointer.y,
      type = 'MOVE_POINTER'
    }

    if (drawBtnPressed) then
      if (firstDrawBtnPress) then
        drawEvent.type = 'DRAW_START'
        firstDrawBtnPress = false
      else
        drawEvent.type = 'DRAW'
      end
    else
      firstDrawBtnPress = true
    end

    sendRaw(drawEvent)
  end
end

Runtime:addEventListener("gyroscope", onGyro)
