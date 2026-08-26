--!nonstrict
-- Central Cat popup. The original kurukuru.gif is preserved beside this
-- entry; the six extracted PNG frames are used because Noctalia v5's
-- ui.image presents one texture and does not animate GIFs itself.

local FRAME_COUNT = 6
local FRAME_MS = 60
local IMAGE_WIDTH = 300
local IMAGE_HEIGHT = 253

local frameIndex = 0
local frameElapsed = 0
local snapshot = nil

local function framePath()
  return string.format("./frames/frame-%03d.png", frameIndex)
end

local function render()
  panel.render(ui.column({
    fill = "surface/0.96",
    radius = 20,
    border = "outline_variant",
    borderWidth = 1,
    gap = 12,
    padding = 16,
    paddingV = 16,
    align = "center",
    justify = "start",
  }, {
    -- Deliberately adds a little more top breathing room than the equal
    -- side/bottom padding, keeping the animation away from the button.
    ui.spacer({ height = 8 }),
    ui.image({
      key = "kurukuru-animation",
      path = framePath(),
      width = IMAGE_WIDTH,
      height = IMAGE_HEIGHT,
      fit = "contain",
      radius = 14,
    }),
    ui.spacer({ flexGrow = 1 }),
    ui.separator({ thickness = 1, color = "outline_variant", spacing = 2 }),
    ui.button({
      text = "New Xournal++ Note",
      glyph = "note",
      variant = "primary",
      controlSize = "md",
      width = 300,
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

function onOpen()
  frameIndex = 0
  frameElapsed = 0
  snapshot = noctalia.state.get("cat")
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

noctalia.state.watch("cat", function(value)
  snapshot = value
  render()
end)
