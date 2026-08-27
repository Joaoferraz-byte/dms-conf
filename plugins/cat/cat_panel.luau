--!nonstrict

local FRAME_COUNT = 6
local FRAME_MS = 60
local IMAGE_WIDTH = 300
local IMAGE_HEIGHT = 250
local BUTTON_WIDTH = 156

local frameIndex = 0
local frameElapsed = 0
local panelOpen = false
local tabletConnected = false

local function readTabletState()
  local state = noctalia.state.get("cat")
  tabletConnected = type(state) == "table" and state.connected == true
end

local function render()
  local xournalVariant = tabletConnected and "primary" or "secondary"
  local xournalTooltip = tabletConnected
    and "Open today's Xournal journal"
    or "Tablet inactive — connect tablet to enable New Xournal"

  panel.render(ui.column({
    flexGrow = 1,
    gap = 10,
    padding = 12,
    align = "center",
  }, {
    ui.spacer({ height = 8 }),
    ui.image({
      key = "kurukuru-animation",
      path = string.format("./frames/frame-%03d.png", frameIndex),
      width = IMAGE_WIDTH,
      height = IMAGE_HEIGHT,
      fit = "contain",
    }),
    ui.spacer({ flexGrow = 1 }),
    ui.separator({ thickness = 1, color = "outline_variant", spacing = 2 }),
    ui.row({ gap = 8, justify = "space_between" }, {
      ui.button({
        text = "New Xournal",
        glyph = "note",
        variant = xournalVariant,
        controlSize = "sm",
        width = BUTTON_WIDTH,
        tooltip = xournalTooltip,
        onClick = "onNewXournal",
      }),
      ui.button({
        text = "New Daily",
        variant = "primary",
        controlSize = "sm",
        width = BUTTON_WIDTH,
        tooltip = "Open today's Obsidian Daily Note",
        onClick = "onNewDaily",
      }),
    }),
  }))
end

function onNewXournal()
  readTabletState()
  if not tabletConnected then
    noctalia.notifyError("Xournal++", "Tablet inactive — connect the tablet first")
    render()
    return
  end

  if not noctalia.runAsync({ "livara-xournal-new-note" }) then
    noctalia.notifyError("Xournal++", "Could not start today's journal note")
  end
end

function onNewDaily()
  if not noctalia.runAsync({ "livara-obsidian-daily-note" }) then
    noctalia.notifyError("Obsidian", "Could not open today's Daily Note")
  end
end

function onOpen(_context)
  panelOpen = true
  frameIndex = 0
  frameElapsed = 0
  readTabletState()
  panel.setNeedsFrameTick(true)
  render()
end

function onClose()
  panelOpen = false
  panel.setNeedsFrameTick(false)
end

function onFrameTick(deltaMs)
  frameElapsed += deltaMs
  while frameElapsed >= FRAME_MS do
    frameElapsed -= FRAME_MS
    frameIndex = (frameIndex + 1) % FRAME_COUNT
  end
  render()
end

noctalia.state.watch("cat", function(value)
  if not panelOpen then
    return
  end

  tabletConnected = type(value) == "table" and value.connected == true
  render()
end)
