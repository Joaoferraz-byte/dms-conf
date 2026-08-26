--!nonstrict

local FRAME_COUNT = 6
local FRAME_MS = 60
local IMAGE_WIDTH = 300
local IMAGE_HEIGHT = 250

local frameIndex = 0
local frameElapsed = 0

local function framePath()
  return string.format("./frames/frame-%03d.png", frameIndex)
end

local function render()
  panel.render(ui.column({
    flexGrow = 1,
    gap = 10,
    align = "center",
  }, {
    ui.spacer({ height = 8 }),
    ui.image({
      key = "kurukuru-animation",
      path = framePath(),
      width = IMAGE_WIDTH,
      height = IMAGE_HEIGHT,
      fit = "contain",
    }),
    ui.spacer({ flexGrow = 1 }),
    ui.separator({ thickness = 1, color = "outline_variant", spacing = 2 }),
    ui.button({
      text = "New Xournal++ Note",
      glyph = "note",
      variant = "primary",
      controlSize = "sm",
      width = 320,
      tooltip = "Open today's Xournal++ journal note",
      onClick = "onNewNote",
    }),
  }))
end

function onNewNote()
  if not noctalia.runAsync({ "livara-xournal-new-note" }) then
    noctalia.notifyError("Xournal++", "Could not start today's journal note")
  end
end

function onOpen(_context)
  frameIndex = 0
  frameElapsed = 0
  panel.setNeedsFrameTick(true)
  render()
end

function onClose()
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
