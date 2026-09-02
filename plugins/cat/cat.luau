--!nonstrict

-- Cat: an animated walking cat while the MTM-1106/T501 tablet is connected;
-- otherwise it sleeps. Tablet presence is read from the existing driver-aware
-- helper.

local catFont = noctalia.loadFont("fonts/catwalk2.otf")

local GLYPH_SLEEP = "a"
local WALK_GLYPHS = { "b", "c", "d", "e", "f" }
local FRAME_MS = 80
local WALK_FRAME_MS = 250
local TABLET_POLL_MS = 1500

local catSize = noctalia.getConfig("cat_size")
local colorMode = noctalia.getConfig("cat_color_mode")
local customColor = noctalia.getConfig("cat_color")

local tabletConnected = false
local checkingTablet = false
local frameIndex = 1
local frameElapsed = 0
local tabletElapsed = TABLET_POLL_MS

local function resolveColor()
  if colorMode == "custom" and customColor and customColor ~= "" then
    return customColor
  end
  return "secondary"
end

local lastPublished = nil
local function publishState(glyph, color, connected)
  local key = `{glyph}|{color}|{connected}`
  if key == lastPublished then
    return
  end
  lastPublished = key
  noctalia.state.set("cat", { glyph = glyph, color = color, connected = connected })
end

local function render()
  local connected = tabletConnected == true
  local glyph = connected and WALK_GLYPHS[frameIndex] or GLYPH_SLEEP
  local color = resolveColor()
  publishState(glyph, color, connected)

  barWidget.render(ui.label({
    text = glyph,
    fontFamily = catFont,
    baseline = "inkCentered",
    fontSize = catSize,
    color = color,
  }))

  barWidget.setTooltip(connected and "Tablet connected — click to open" or "Tablet disconnected — click to open panel")
end

local function setTabletConnected(connected)
  connected = connected == true
  if connected ~= tabletConnected then
    frameIndex = 1
    frameElapsed = 0
  end
  tabletConnected = connected
  render()
end

local function refreshTabletStatus()
  if checkingTablet then
    return
  end
  checkingTablet = true

  local accepted = noctalia.runAsync({ "livara-tablet-status" }, function(result)
    checkingTablet = false
    local connected = false
    if result.exitCode == 0 then
      local payload = noctalia.json.decode(result.stdout)
      connected = type(payload) == "table" and payload.connected == true
    end
    setTabletConnected(connected)
  end)

  if not accepted then
    checkingTablet = false
    setTabletConnected(false)
  end
end

noctalia.setUpdateInterval(FRAME_MS)

function update()
  tabletElapsed += FRAME_MS
  if tabletElapsed >= TABLET_POLL_MS then
    tabletElapsed = 0
    refreshTabletStatus()
  end

  if tabletConnected then
    frameElapsed += FRAME_MS
    if frameElapsed >= WALK_FRAME_MS then
      frameElapsed = 0
      frameIndex = frameIndex % #WALK_GLYPHS + 1
    end
  else
    frameIndex = 1
    frameElapsed = 0
  end

  render()
end

function onConfigChanged()
  catSize = noctalia.getConfig("cat_size")
  colorMode = noctalia.getConfig("cat_color_mode")
  customColor = noctalia.getConfig("cat_color")
  render()
end

render()
refreshTabletStatus()

function onClick()
  noctalia.togglePanel("dotnetrob/cat:panel")
end
