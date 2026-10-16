#!/usr/bin/env bash

# ── repeat a character N times
_rep() { local i; for ((i=0; i<$2; i++)); do printf '%s' "$1"; done; }

# Big boxed section header
section() {
  local t=$(echo "$1" | tr '[:lower:]' '[:upper:]')
  printf '\n\033[1;35m╔%s╗\n' "$(_rep ═ 41)"
  printf '║\033[1;37m  ▸ %-37s\033[1;35m║\n' "$t"
  printf '╚%s╝\033[0m\n' "$(_rep ═ 41)"
}

# Inline sub-section rule
sub() {
  local t=$(echo "$1" | tr '[:lower:]' '[:upper:]')
  local fill=$(( 43 - 5 - ${#t} - 1 ))
  printf '\n\033[1;36m── ▸ \033[1;37m%s \033[1;36m%s\033[0m\n' "$t" "$(_rep ─ $fill)"
  progress_step "$1"
}

# Plain divider
divider() { printf '\033[2m%s\033[0m\n' "$(_rep ┄ 43)"; }

# Status lines
ok()   { printf '  \033[1;32m✓\033[0m %s\n' "$1"; }
fail() { printf '  \033[1;31m✗\033[0m %s\n' "$1"; }
info() { printf '  \033[1;36m→\033[0m %s\n' "$1"; }
warn() { printf '  \033[1;33m!\033[0m %s\n' "$1"; }

# ── Checkbox picker
# choose_many "Question" item... lists the items with every box checked.
# ↑/↓ (or j/k) move, space toggles, a checks/unchecks all, enter confirms.
# The checked items are left in PICKED. Written for the bash 3.2 that ships
# with macOS, since this runs before Homebrew exists.
choose_many() {
  local prompt="$1"; shift
  local items=("$@") checked=() count=$# cursor=0 i key rest all tty_state
  for ((i = 0; i < count; i++)); do checked[i]=1; done

  printf '\n\033[1;36m  ? \033[1;37m%s\033[0m\n' "$prompt"
  printf '\033[2m    ↑/↓ move · space toggle · a all/none · enter confirm\033[0m\n'
  tty_state="$(stty -g)"
  # No echo or line buffering, so stray keys can't scribble over the list.
  stty -echo -icanon
  printf '\033[?25l'
  trap 'stty "$tty_state"; printf "\033[?25h\n"; exit 130' INT
  _picker_draw

  while :; do
    IFS= read -rsn1 key
    if [[ "$key" == $'\033' ]]; then
      IFS= read -rsn2 -t 1 rest
      key+="$rest"
    fi
    case "$key" in
      $'\033[A'|$'\033OA'|k) cursor=$(( (cursor + count - 1) % count )) ;;
      $'\033[B'|$'\033OB'|j) cursor=$(( (cursor + 1) % count )) ;;
      ' ') checked[cursor]=$(( !checked[cursor] )) ;;
      a)
        # Check everything unless everything is already checked.
        all=0
        for ((i = 0; i < count; i++)); do (( checked[i] )) || all=1; done
        for ((i = 0; i < count; i++)); do checked[i]=$all; done
        ;;
      '') break ;;
      *) continue ;;
    esac
    printf '\033[%dA' "$count"
    _picker_draw
  done

  stty "$tty_state"
  printf '\033[?25h'
  trap - INT
  PICKED=()
  for ((i = 0; i < count; i++)); do
    (( checked[i] )) && PICKED+=("${items[i]}")
  done
}

# Draws one frame of the list in a single write. Reads choose_many's locals
# (items, checked, count, cursor) through bash's dynamic scoping.
_picker_draw() {
  local i box e=$'\033' out=""
  for ((i = 0; i < count; i++)); do
    box="[ ]"
    (( checked[i] )) && box="${e}[1;32m[x]${e}[0m"
    if (( i == cursor )); then
      out+="  ${e}[1;36m❯${e}[0m ${box} ${e}[1;37m${items[i]}${e}[0m${e}[K"$'\n'
    else
      out+="    ${box} ${items[i]}${e}[K"$'\n'
    fi
  done
  printf '%s' "$out"
}

# True when $1 was checked in the app picker.
app_selected() {
  local name
  for name in "${SELECTED_APPS[@]}"; do
    [[ "$name" == "$1" ]] && return 0
  done
  return 1
}

# ── Sticky progress bar
# Reserves the bottom terminal row with a scroll region; a background ticker
# redraws it from a state file so section output scrolls above it. Skipped
# when stdout is not a terminal (e.g. piped to a log).
PROGRESS_ON=0
PROGRESS_INDEX=0
PROGRESS_SUB=0
PROGRESS_SUBS=0
PROGRESS_SPIN=(⠋ ⠙ ⠹ ⠸ ⠼ ⠴ ⠦ ⠧ ⠇ ⠏)

_term_size() { stty size </dev/tty 2>/dev/null; }

# Write the current state for the ticker. $1 = step label.
_progress_set() {
  (( PROGRESS_ON )) || return 0
  local n=$PROGRESS_SUB frac=0 pct
  (( n > PROGRESS_SUBS )) && n=$PROGRESS_SUBS
  # A section only reaches 100% when the next one starts.
  (( PROGRESS_SUBS > 0 )) && frac=$(( n * 100 / (PROGRESS_SUBS + 1) ))
  pct=$(( ((PROGRESS_INDEX - 1) * 100 + frac) / PROGRESS_TOTAL ))
  printf '%s\n%s\n%s\n%s\n' "$PROGRESS_INDEX" "$pct" "$PROGRESS_NAME" "$1" \
    > "$PROGRESS_STATE"
}

_progress_draw() {
  local frame="$1" idx pct name step rows cols
  { read -r idx; read -r pct; read -r name; read -r step; } \
    < "$PROGRESS_STATE" 2>/dev/null
  [[ -n "$name" ]] || return 0
  read -r rows cols <<< "$(_term_size)"
  (( rows > 2 )) || return 0

  # Re-reserve the bottom row after a window resize.
  if [[ "$rows $cols" != "$_progress_size" ]]; then
    printf '\0337\033[1;%dr\0338' "$((rows - 1))"
    _progress_size="$rows $cols"
  fi

  local width=0 filled bar="" timer tail elapsed=$(( SECONDS - PROGRESS_T0 ))
  if (( cols >= 70 )); then width=20; elif (( cols >= 50 )); then width=10; fi
  if (( width > 0 )); then
    filled=$(( pct * width / 100 ))
    printf -v bar '\033[36m%s\033[90m%s\033[97m ' \
      "$(_rep █ $filled)" "$(_rep ░ $((width - filled)))"
  fi
  printf -v timer '%02d:%02d' $((elapsed / 60)) $((elapsed % 60))
  tail="$name"
  [[ -n "$step" ]] && printf -v tail '%s \033[2m›\033[22m %s' "$name" "$step"

  # Autowrap is disabled while drawing so long labels are clipped, not wrapped.
  printf '\0337\033[?7l\033[%d;1H\033[0;97;48;5;236m %s %s/%s %s%3d%%  %s  \033[2m│\033[22m %s\033[K\033[0m\033[?7h\0338' \
    "$rows" "${PROGRESS_SPIN[frame]}" "$idx" "$PROGRESS_TOTAL" "$bar" "$pct" \
    "$timer" "$tail"
}

_progress_loop() {
  local frame=0
  while kill -0 "$$" 2>/dev/null; do
    _progress_draw "$frame"
    frame=$(( (frame + 1) % ${#PROGRESS_SPIN[@]} ))
    sleep 0.2
  done
}

# $1 = total number of sections.
progress_start() {
  [[ -t 1 ]] || return 0
  local rows cols
  read -r rows cols <<< "$(_term_size)"
  (( rows > 2 )) || return 0
  PROGRESS_STATE="$(mktemp "${TMPDIR:-/tmp}/setup-progress.XXXXXX")" || return 0
  PROGRESS_ON=1
  PROGRESS_TOTAL="$1"
  PROGRESS_T0=$SECONDS
  _progress_size="$rows $cols"
  # Push a blank line so the cursor is inside the new scroll region.
  printf '\n\0337\033[1;%dr\0338\033[1A' "$((rows - 1))"
  _progress_loop &
  PROGRESS_PID=$!
  trap progress_end EXIT
  trap 'exit 130' INT
  trap 'exit 143' TERM
}

# $1 = section name, $2 = section file (used to count its sub steps).
progress_section() {
  PROGRESS_INDEX=$(( PROGRESS_INDEX + 1 ))
  PROGRESS_NAME="$1"
  PROGRESS_SUB=0
  PROGRESS_SUBS=$(grep -c '^[[:space:]]*sub[[:space:]]' "$2" 2>/dev/null)
  _progress_set ""
}

progress_step() {
  PROGRESS_SUB=$(( PROGRESS_SUB + 1 ))
  _progress_set "$1"
}

progress_end() {
  (( PROGRESS_ON )) || return 0
  PROGRESS_ON=0
  kill "$PROGRESS_PID" 2>/dev/null
  wait "$PROGRESS_PID" 2>/dev/null
  local rows cols
  read -r rows cols <<< "$(_term_size)"
  printf '\0337\033[r\0338'
  (( rows > 0 )) && printf '\0337\033[%d;1H\033[2K\0338' "$rows"
  rm -f "$PROGRESS_STATE"
}

# Main macOS setup orchestrator. Each section is sourced so environment
# changes and the app installer cleanup trap remain in this shell process.
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
SECTION_DIR="$SCRIPT_DIR/organized"

osascript -e 'tell application "System Preferences" to quit'
printf '\033[1;36m'
cat << 'EOF'
╭─────────────────────────────────────────╮
│                                         │
│        ╔═╗ ╔╗╔ ╔═╗ ╔═╗ ╦   ╦ ╔═╗        │
│        ╠═╣ ║║║ ║ ╦ ║╣  ║     ╚═╗        │
│        ╩ ╩ ╝╚╝ ╚═╝ ╚═╝ ╩═╝   ╚═╝        │
│                                         │
│    ╔╦╗ ╔═╗ ╔═╗   ╔═╗ ╔═╗ ╔╦╗ ╦ ╦ ╔═╗    │
│    ║║║ ╠═╣ ║     ╚═╗ ║╣   ║  ║ ║ ╠═╝    │
│    ╩ ╩ ╩ ╩ ╚═╝   ╚═╝ ╚═╝  ╩  ╚═╝ ╩      │
│                                         │
╰─────────────────────────────────────────╯
EOF
printf '\033[0m\n'
sleep 1

# Pick the apps up front so the rest of the setup runs unattended. Without a
# terminal (e.g. output piped to a log) every app in the catalog is installed.
source "$SECTION_DIR/app-catalog.sh"
APP_NAMES=()
for entry in "${APP_CATALOG[@]}"; do
    APP_NAMES+=("${entry%%|*}")
done
if [[ -t 0 && -t 1 ]]; then
    choose_many "Which apps should be installed?" "${APP_NAMES[@]}"
    SELECTED_APPS=("${PICKED[@]}")
else
    SELECTED_APPS=("${APP_NAMES[@]}")
fi
ok "${#SELECTED_APPS[@]} of ${#APP_NAMES[@]} apps selected"

run_section() {
    local section="$1"
    local section_path="$SECTION_DIR/$section"
    local name="${section%.sh}"

    # Drop the numeric ordering prefix for the progress bar label.
    progress_section "${name#"${name%%[!0-9]*}"}" "$section_path"

    if [[ ! -r "$section_path" ]]; then
        printf 'Missing setup section: %s\n' "$section_path" >&2
        return 1
    fi

    section "$name"
#    printf '\n========== %s ==========\n' "${section%.sh}"
    source "$section_path"
}

SECTIONS=(
    "2brew.sh"
    "3zsh.sh"
    "4apps.sh"
    "5macprefs.sh"
    "1claude.sh"
)

progress_start "${#SECTIONS[@]}"
for section_file in "${SECTIONS[@]}"; do
    run_section "$section_file"
done
progress_end
