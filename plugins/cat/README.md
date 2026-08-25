# Cat

An animated cat that lives in your bar. It sleeps when the MTM-1106/T501
tablet is disconnected and walks at a normal pace while the tablet is connected —
colored to match your theme, or any color you pick.

## Plugin

| Field | Value |
| --- | --- |
| ID | `dotnetrob/cat` |
| Entries | Bar widget: `cat`; panel: `panel` |

## Usage

Add the "Cat" widget to any bar from Settings → Bar → Add Widget. Click the
widget to toggle a popup panel showing the same cat at panel size — animating
in step with the bar cat — plus a footer button named `New Xournal++ Note`.
Click anywhere outside the panel to dismiss it. The panel can also be toggled over IPC:

```sh
noctalia msg panel-toggle dotnetrob/cat:panel
```

## Settings

| Setting | Type | Default | Description |
| --- | --- | --- | --- |
| `cat_size` | `int` | `24` | Sprite size in the bar, in pixels (12–48). |
| `cat_color_mode` | `select` | `theme` | `theme` colors the cat with the palette's `secondary` role and tracks theme changes; `custom` uses the color below. |
| `cat_color` | `color` | `#E8A24C` | Used when `cat_color_mode` is `custom`. |

## Notes

Every 1.5 seconds the widget invokes the existing `livara-tablet-status`
helper, which checks the physical USB/Input identity used by the configured
MTM-1106/T501 driver. The helper is only a read-only presence check; it does
not start or stop the driver. The panel mirrors the bar widget through the
plugin's in-process shared state store, so the large cat follows the same
sleep/walk state. Its shape comes from a small custom icon font
(`fonts/catwalk2.otf`) traced from the MIT-licensed
[CatWalk](https://store.kde.org/p/2055225) plasmoid by Driglu4it, which lets
it be recolored like normal bar text instead of a fixed-color image.

The footer action reuses `livara-xournal-new-note`. It opens today's note in
`~/Vault/02 - Xournal++`, creating the file when necessary.
