# Screen Toolkit

Noctalia v5 plugin for color picking, OCR, QR/barcode scanning, palette extraction, Lens search, measurement, annotation, screen recording and image sharing.

## Contract

| Field | Value |
|---|---|
| ID | `alexander/screen-toolkit` |
| Entries | `widget` bar widget, `toggle` shortcut, `panel`, `panel-legacy`, `result` panels, `service` IPC |
| Runtime | Noctalia v5 |

This is an independent v5 port of the [legacy v4 plugin](https://github.com/noctalia-dev/legacy-v4-plugins/tree/main/screen-toolkit).

## Dependencies

Install only the tools used by the enabled features:

| Capability | Tools |
|---|---|
| Selection and capture | `slurp`, `grim` |
| Color and image processing | `hyprpicker`, `imagemagick` |
| OCR and codes | `tesseract` plus language data, `zbar` |
| Search and sharing | `curl`, `jq`, `xdg-open` |
| Recording | `ffmpeg`, `ffprobe`, `bc`, `stat`, `pkill` and one backend |
| Annotation | `swappy` or `satty`; `gimp` is a fallback |
| Preview | `mpv` for legacy recording preview |

Supported recording backends are `gpu-screen-recorder`, `wl-screenrec` and `wf-recorder`. `translate-shell` is optional for OCR translation. `hyprctl` or `niri` is optional for focused-window annotation.

Region tools require a Wayland compositor with the relevant wlroots protocols. Window annotation uses Hyprland or Niri integration when available.

## Usage

Add the widget to a bar and/or add the shortcut tile in the Noctalia control center. Left-click opens the configured panel; right-click on the bar widget quick-picks a color. During recording, the widget and shortcut expose the stop action.

The `panel-mode` setting selects `standard` or `legacy`. Both layouts use the same service and result panel:

```sh
noctalia msg plugin alexander/screen-toolkit:service all toggle
noctalia msg panel-toggle alexander/screen-toolkit:panel
noctalia msg panel-toggle alexander/screen-toolkit:panel-legacy
noctalia msg panel-toggle alexander/screen-toolkit:result
```

The standard panel groups the tools in a compact grid. Legacy mode preserves the v4-style layout and adds dedicated markup and recording subpanels. Capture results are copied to the clipboard and remain available in the result panel; temporary previews live under `/tmp` for the session.

Available actions include color, OCR, QR, palette, Lens, measure, GIF/MP4 recording, markup and sharing. Recording can capture microphone and desktop audio according to its settings. The `hide-cursor` option applies to screenshots and recordings where the selected backend supports it.

## Settings

Settings are managed under **Settings → Plugins**. The stable groups are:

| Group | Settings |
|---|---|
| Paths | `screenshot-path`, `video-path`, `filename-format` |
| OCR and sharing | `selected-ocr-lang`, `search-engine-url`, `x02-api-key`, `x02-expiry` |
| Recording | `record-audio-out`, `record-audio-in`, `record-codec`, `record-fps`, `record-skip-confirmation`, `record-copy-to-clipboard`, `gif-max-seconds` |
| Interface | `panel-mode`, `hide-cursor`, `share-skip-popover` |

The complete defaults and ranges remain in `plugin.toml`; this document intentionally avoids duplicating the schema.

## Validation

Verify plugin discovery, each enabled dependency path, standard and legacy panels, clipboard output, recording start/stop, result persistence and missing-tool notifications. Run the repository's Noctalia checks before enabling the plugin in the system configuration.
