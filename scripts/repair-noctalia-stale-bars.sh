#!/usr/bin/env bash
set -Eeuo pipefail

state_home="${NOCTALIA_STATE_HOME:-${XDG_STATE_HOME:-$HOME/.local/state}}"
settings="${state_home}/noctalia/settings.toml"
stop_requested=false

usage() {
  cat <<'EOF'
Usage: repair-noctalia-stale-bars [--stop]

Remove only the stale [bar.main] override from Noctalia settings.

Without --stop, Noctalia must already be closed. With --stop, the script
sends SIGTERM only to exact Noctalia processes, waits for them to exit, then
creates a backup and performs the same validated edit. Reopen Noctalia after
completion with `noctalia`.
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

stop_noctalia_if_requested

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
printf 'Reopen Noctalia with: noctalia\n'
