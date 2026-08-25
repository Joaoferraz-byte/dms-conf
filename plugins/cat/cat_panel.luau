--!nonstrict
-- Cat panel: the popup opened by clicking the bar widget. Shows the same cat
-- glyph as the bar, just bigger, with a footer action for the daily note.
--
-- The panel runs in its own Luau runtime, so it can't share locals with
-- cat.luau. Instead the bar widget publishes { glyph, color, pace } to the
-- plugin's shared state store under "cat" whenever any of them change, and
-- this script re-renders on every update. No ticks of its own are needed.

local catFont = noctalia.loadFont("fonts/catwalk2.otf")

local PANEL_CAT_SIZE = 120

local snapshot = nil

local function render()
  local glyph = snapshot and snapshot.glyph or "a"
  local color = snapshot and snapshot.color or "secondary"
  panel.render(ui.column({ gap = 10, align = "center", padding = 20 }, {
    ui.label({
      text = glyph,
      fontFamily = catFont,
      baseline = "inkCentered",
      fontSize = PANEL_CAT_SIZE,
      color = color,
    }),
    ui.spacer({ flexGrow = 1 }),
    ui.separator({ thickness = 1, color = "outline_variant", spacing = 2 }),
    ui.button({
      text = "New Xournal++ Note",
      glyph = "note",
      variant = "primary",
      controlSize = "sm",
      width = 232,
      tooltip = "Open today's Xournal++ note",
      onClick = "onNewNote",
    }),
  }))
end

function onNewNote()
  if not noctalia.runAsync({ "livara-xournal-new-note" }) then
    noctalia.notifyError("Xournal++", "Could not start the daily note")
  end
end

noctalia.state.watch("cat", function(value)
  snapshot = value
  render()
end)

function onOpen()
  snapshot = noctalia.state.get("cat")
  render()
end
