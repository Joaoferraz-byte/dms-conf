#!/usr/bin/env bash
set -Eeuo pipefail

state_home="${NOCTALIA_STATE_HOME:-${XDG_STATE_HOME:-$HOME/.local/state}}"
settings="${state_home}/noctalia/settings.toml"

if [[ ! -f "$settings" ]]; then
  printf 'No Noctalia settings override found: %s\n' "$settings"
  exit 0
fi

if pgrep -x noctalia >/dev/null 2>&1 || pgrep -f '^/.*/noctalia([[:space:]]|$)' >/dev/null 2>&1; then
  printf 'Refusing to edit while Noctalia is running. Close it and run again.\n' >&2
  exit 2
fi

backup="${settings}.bak.$(date +%Y%m%d-%H%M%S)"
tmp="$(mktemp "${settings}.tmp.XXXXXX")"
trap 'rm -f "$tmp"' EXIT

awk '
  BEGIN { removed = 0; skip = 0 }
  /^\[\[?bar\.main([.]|\])/ {
    removed = 1
    skip = 1
    next
  }
  skip && /^\[/ { skip = 0 }
  !skip { print }
  END {
    if (!removed) exit 3
  }
' "$settings" > "$tmp" || {
  status=$?
  if [[ "$status" -eq 3 ]]; then
    printf 'No [bar.main] override found in %s; nothing changed.\n' "$settings"
    exit 0
  fi
  printf 'Could not filter %s safely.\n' "$settings" >&2
  exit "$status"
}

cp -a "$settings" "$backup"
mv -f "$tmp" "$settings"

if command -v noctalia >/dev/null 2>&1 && ! noctalia config validate >/dev/null; then
  mv -f "$backup" "$settings"
  printf 'Validation failed; restored %s\n' "$settings" >&2
  exit 1
fi

printf 'Removed stale [bar.main] override.\nBackup: %s\nState: %s\n' "$backup" "$settings"
