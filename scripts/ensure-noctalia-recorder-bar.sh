#!/usr/bin/env bash
set -Eeuo pipefail

state_home="${NOCTALIA_STATE_HOME:-${XDG_STATE_HOME:-$HOME/.local/state}}"
settings="${state_home}/noctalia/settings.toml"
stop_requested=false

usage() {
  cat <<'EOF'
Usage: ensure-noctalia-recorder-bar [--stop]

Ensure the persisted Noctalia [bar.default] end list contains the official
recorder widget. The script changes only an existing one-line end array,
creates a timestamped backup, and refuses ambiguous formats.

Without --stop, Noctalia must already be closed. With --stop, the script sends
SIGTERM only to exact Noctalia processes and waits before editing the state.
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

if awk '
  BEGIN { in_default = 0; found = 0; ambiguous = 0 }
  /^\[/ { in_default = ($0 == "[bar.default]") }
  in_default && /^[[:space:]]*end[[:space:]]*=/ {
    if ($0 ~ /"recorder"/) found = 1
    else if ($0 !~ /^[[:space:]]*end[[:space:]]*=[[:space:]]*\[[^]]*\][[:space:]]*(#.*)?$/) ambiguous = 1
  }
  END { exit(found || ambiguous ? 0 : 1) }
' "$settings"; then
  if grep -Eq '^\[bar\.default\]$' "$settings" && awk '
    BEGIN { in_default = 0; found = 0 }
    /^\[/ { in_default = ($0 == "[bar.default]") }
    in_default && /^[[:space:]]*end[[:space:]]*=/ && /"recorder"/ { found = 1 }
    END { exit(found ? 0 : 1) }
  ' "$settings"; then
    printf 'The persisted [bar.default] end list already contains recorder; nothing changed.\n'
    exit 0
  fi
  if grep -Eq '^\[bar\.default\]$' "$settings" && awk '
    BEGIN { in_default = 0; ambiguous = 0 }
    /^\[/ { in_default = ($0 == "[bar.default]") }
    in_default && /^[[:space:]]*end[[:space:]]*=/ && $0 !~ /^[[:space:]]*end[[:space:]]*=[[:space:]]*\[[^]]*\][[:space:]]*(#.*)?$/ { ambiguous = 1 }
    END { exit(ambiguous ? 0 : 1) }
  ' "$settings"; then
    printf 'Refusing to edit: [bar.default].end is not a supported one-line TOML array.\n' >&2
    exit 3
  fi
fi

if ! grep -Eq '^\[bar\.default\]$' "$settings"; then
  printf 'No persisted [bar.default] override found; the declarative config will own the recorder list.\n'
  exit 0
fi

if ! awk '
  BEGIN { in_default = 0; found = 0; has_end = 0 }
  /^\[/ { in_default = ($0 == "[bar.default]") }
  in_default && /^[[:space:]]*end[[:space:]]*=/ {
    has_end = 1
    if ($0 ~ /"recorder"/) found = 1
  }
  END { exit(has_end && !found ? 0 : 1) }
' "$settings"; then
  printf 'No existing [bar.default].end override without recorder was found; nothing changed.\n'
  exit 0
fi

stop_noctalia_if_requested
backup="${settings}.bak.$(date +%Y%m%d-%H%M%S)"
tmp="$(mktemp "${settings}.tmp.XXXXXX")"
trap 'rm -f "$tmp"' EXIT

awk '
  BEGIN { in_default = 0; changed = 0 }
  /^\[/ { in_default = ($0 == "[bar.default]") }
  in_default && /^[[:space:]]*end[[:space:]]*=/ && $0 !~ /"recorder"/ {
    sub(/\][[:space:]]*(#.*)?$/, ", \"recorder\"]")
    changed = 1
  }
  { print }
  END { if (!changed) exit 1 }
' "$settings" > "$tmp"

cp -a "$settings" "$backup"
mv -f "$tmp" "$settings"

if command -v noctalia >/dev/null 2>&1 && ! noctalia config validate >/dev/null; then
  mv -f "$backup" "$settings"
  printf 'Validation failed; restored %s\n' "$settings" >&2
  exit 1
fi

printf 'Added recorder to the persisted [bar.default] end list.\nBackup: %s\nState: %s\n' "$backup" "$settings"
printf 'Reopen Noctalia after the repair.\n'
