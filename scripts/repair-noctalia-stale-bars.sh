#!/usr/bin/env bash
set -Eeuo pipefail

state_home="${NOCTALIA_STATE_HOME:-${XDG_STATE_HOME:-$HOME/.local/state}}"
settings="${state_home}/noctalia/settings.toml"
stop_requested=false

usage() {
  cat <<'EOF'
Usage: repair-noctalia-stale-bars [--stop]

Repair only stale Noctalia bar/panel state in settings.toml:
  - remove [bar.main] and nested bar.main tables;
  - change panel_anchor_bar = "main" to panel_anchor_bar = "default".

Without --stop, Noctalia must already be closed. With --stop, the script
sends SIGTERM only to exact Noctalia processes, waits for them to exit, then
creates a backup and performs the validated edit. Reopen Noctalia after
completion with the normal Niri startup or `noctalia` for a one-off test.
EOF
}

case "${1:-}" in
  "") ;;
  --stop) stop_requested=true ;;
  -h|--help) usage; exit 0 ;;
  *) usage >&2; exit 64 ;;
esac

noctalia_pids() {
  {
    pgrep -x noctalia || true
    pgrep -f '^/.*/noctalia([[:space:]]|$)' || true
  } | sort -nu
}

stop_noctalia_if_requested() {
  local -a pids=()
  mapfile -t pids < <(noctalia_pids)
  if ((${#pids[@]} == 0)); then
    return 0
  fi

  if [[ "$stop_requested" != true ]]; then
    printf 'Refusing to edit while Noctalia is running. Close it or run with --stop.\n' >&2
    exit 2
  fi

  printf 'Stopping exact Noctalia process IDs: %s\n' "${pids[*]}"
  kill -TERM "${pids[@]}"
  for _ in {1..50}; do
    mapfile -t pids < <(noctalia_pids)
    ((${#pids[@]} == 0)) && return 0
    sleep 0.1
  done

  printf 'Noctalia did not exit after SIGTERM; refusing to edit. Remaining PIDs: %s\n' "${pids[*]}" >&2
  exit 2
}

if [[ ! -f "$settings" ]]; then
  printf 'No Noctalia settings override found: %s\n' "$settings"
  exit 0
fi

if ! grep -Eq '(^[[:space:]]*panel_anchor_bar[[:space:]]*=[[:space:]]*"main"|^\[\[?bar\.main([.]|\]))' "$settings"; then
  printf 'No stale bar/panel state found in %s; nothing changed.\n' "$settings"
  exit 0
fi

stop_noctalia_if_requested

backup="${settings}.bak.$(date +%Y%m%d-%H%M%S)"
tmp="$(mktemp "${settings}.tmp.XXXXXX")"
trap 'rm -f "$tmp"' EXIT

awk '
  BEGIN { skip = 0; removed_bar = 0; repaired_anchor = 0 }
  /^\[\[?bar\.main([.]|\])/ {
    removed_bar = 1
    skip = 1
    next
  }
  skip && /^\[/ { skip = 0 }
  skip { next }
  /^[[:space:]]*panel_anchor_bar[[:space:]]*=[[:space:]]*"main"([[:space:]]*(#.*)?)?$/ {
    print "panel_anchor_bar = \"default\""
    repaired_anchor = 1
    next
  }
  { print }
  END {
    if (removed_bar || repaired_anchor) {
      printf "# repair: removed_bar=%d repaired_anchor=%d\n", removed_bar, repaired_anchor > "/dev/stderr"
    }
  }
' "$settings" >"$tmp"

cp -a "$settings" "$backup"
mv -f "$tmp" "$settings"

if command -v noctalia >/dev/null 2>&1 && ! noctalia config validate >/dev/null; then
  mv -f "$backup" "$settings"
  printf 'Validation failed; restored %s\n' "$settings" >&2
  exit 1
fi

printf 'Repaired stale Noctalia panel/bar state.\nBackup: %s\nState: %s\n' "$backup" "$settings"
printf 'The repair is persistent; do not rerun it unless a future settings edit recreates the stale state.\n'
printf 'Reopen Noctalia with the normal Niri startup or: noctalia\n'
