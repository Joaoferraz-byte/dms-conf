# Cat popup animation asset

The popup uses `kurukuru.gif`, preserved unchanged from the historical Livara
shell asset in `shell-conf` commit `1d712981a0ba81b14a727cc5fe4209e35b58dc60`.

- Original path: `assets/kurukuru.gif`
- Original dimensions: 399×337 pixels
- Original size: 99,006 bytes
- SHA-256: `750d6115bb86008ffbeb09dccd2a8b1e20a466da26295fc724a2170be70f8be8`

Noctalia v5 `ui.image` presents one texture and does not animate GIF frames in
panel UI. The six 399×337 RGBA PNGs under `frames/` are deterministic frame
extractions from this GIF, preserving the original 60 ms frame durations in the
Cat panel's frame-tick loop. They are not recolored or geometrically edited.
