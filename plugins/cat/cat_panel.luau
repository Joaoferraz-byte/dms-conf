--!nonstrict

local catFont = noctalia.loadFont("fonts/catwalk2.otf")
local PANEL_CAT_SIZE = 260

local panelOpen = false
local snapshot = nil

local function readCatState()
  snapshot = noctalia.state.get("cat")
end

local function render()
  local glyph = snapshot and snapshot.glyph or "a"
  local color = snapshot and snapshot.color or "secondary"

  panel.render(ui.column({
    flexGrow = 1,
    gap = 10,
    padding = 12,
    align = "center",
  }, {
    ui.spacer({ height = 8 }),
    ui.label({
      text = glyph,
      fontFamily = catFont,
      baseline = "inkCentered",
      fontSize = PANEL_CAT_SIZE,
      color = color,
    }),
    ui.spacer({ flexGrow = 1 }),
    ui.separator({ thickness = 1, color = "outline_variant", spacing = 2 }),
    ui.row({ width = 320, gap = 8, justify = "center", align = "center" }, {
      ui.button({
        text = "New Xournal",
        glyph = "note",
        variant = snapshot and snapshot.connected and "primary" or "secondary",
        controlSize = "sm",
        width = 156,
        tooltip = snapshot and snapshot.connected
          and "Open today's Xournal journal"
          or "Tablet inactive — connect tablet to enable New Xournal",
        onClick = "onNewXournal",
      }),
      ui.button({
        text = "New Daily",
        glyph = "calendar",
        variant = "primary",
        controlSize = "sm",
        width = 156,
        tooltip = "Open today's Obsidian Daily Note",
        onClick = "onNewDaily",
      }),
    }),
  }))
end

function onNewXournal()
  readCatState()
  if not (snapshot and snapshot.connected == true) then
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
  readCatState()
  render()
end

function onClose()
  panelOpen = false
end

noctalia.state.watch("cat", function(value)
  if not panelOpen then
    return
  end

  snapshot = value
  render()
end)
