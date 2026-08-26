# Cat

An animated tablet-aware cat in the Noctalia bar. It sleeps when the MTM-1106/T501 tablet is disconnected and walks at a normal pace while the tablet is connected, with the bar glyph colored by the active theme.

## Plugin

| Field | Value |
| --- | --- |
| ID | `dotnetrob/cat` |
| Entries | Bar widget: `cat`; panel: `panel` |
| Panel | Floating, centered, 380×430 logical pixels, `surface/0.88` background |

## Usage

Add the `Cat` widget to a bar from **Settings → Bar → Add Widget**. Clicking the widget toggles a centered popup. The popup shows the preserved `kurukuru.gif` animation above a footer button named **New Xournal++ Note**. The panel uses six deterministic PNG frames because Noctalia v5's `ui.image` control presents one texture rather than advancing GIF frames itself.

Clicking outside the popup dismisses it. The panel can also be toggled over IPC:

```sh
noctalia msg panel-toggle dotnetrob/cat:panel
```

## Settings

| Setting | Type | Default | Description |
| --- | --- | --- | --- |
| `cat_size` | `int` | `24` | Sprite size in the bar, in pixels (12–48). |
| `cat_color_mode` | `select` | `theme` | `theme` colors the bar cat with the palette's `secondary` role and tracks theme changes; `custom` uses the color below. |
| `cat_color` | `color` | `#E8A24C` | Used when `cat_color_mode` is `custom`. |

## Tablet and Xournal++ behavior

Every 1.5 seconds the bar widget invokes the existing `livara-tablet-status` helper, which checks the physical USB/Input identity used by the configured MTM-1106/T501 driver. The helper is read-only and does not start or stop the driver. The panel remains an independent visual popup and does not add a second tablet poller.

The **New Xournal++ Note** action reuses `livara-xournal-new-note`. It opens today's note under `~/Vault/02 - Xournal++`; clicking again on the same day reopens the existing file. When the file does not yet exist, the helper passes its intended path to Xournal++ and lets the native Xournal++ profile apply the configured journal `pageTemplate` and `forceZoomToFitOnLoad`, rather than creating a competing hardcoded XML document.

## Asset provenance

The original `kurukuru.gif` is preserved unchanged. Its source and deterministic frame extraction are documented in [`ASSET-SOURCE.md`](ASSET-SOURCE.md). The panel uses a translucent `surface/0.88` fill, matching the bar's configured `background_opacity = 0.88`; transparency outside the character comes from the GIF alpha channel, while opaque black outlines are part of the artwork. The bar itself continues to use the reviewed `catwalk2.otf` glyph animation so tablet presence remains theme-aware and lightweight.

To remove the stale second bar, close Noctalia and run `~/.local/bin/repair-noctalia-stale-bars`. If Noctalia is still running, use the explicit opt-in `~/.local/bin/repair-noctalia-stale-bars --stop`; it sends SIGTERM only to exact Noctalia processes, waits for exit, performs the backup-first edit and tells you to reopen Noctalia with `noctalia`.
