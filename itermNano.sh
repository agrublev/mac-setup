#!/usr/bin/env bash
# Make Option+Left/Right jump by word in GNU nano on macOS (iTerm2 + Terminal.app).
# Safe to re-run: every step checks before changing anything.
set -euo pipefail

NANORC="$HOME/.nanorc"
ITERM_DOMAIN="com.googlecode.iterm2"
PLISTBUDDY="/usr/libexec/PlistBuddy"

log() { printf '==> %s\n' "$*"; }
warn() { printf 'WARN: %s\n' "$*" >&2; }

# 1. GNU nano (macOS ships pico as /usr/bin/nano, which ignores ~/.nanorc)
# Never run /usr/bin/nano here: it's pico, which ignores --version and opens
# the editor (output swallowed by the pipe), so the script appears to hang.
ensure_gnu_nano() {
  if ! command -v brew >/dev/null; then
    warn "Homebrew missing; install GNU nano manually."
    return
  fi
  local gnu_nano
  gnu_nano="$(brew --prefix)/bin/nano"
  if [[ -x "$gnu_nano" ]] && "$gnu_nano" --version </dev/null 2>/dev/null | grep -q "GNU nano"; then
    log "GNU nano already installed: $gnu_nano"
  else
    log "Installing GNU nano via Homebrew"
    brew install nano
  fi
  if [[ "$(command -v nano)" != "$gnu_nano" ]]; then
    warn "'nano' still resolves to $(command -v nano); put $(brew --prefix)/bin before /usr/bin in PATH."
  fi
}

# 2. nanorc bindings: Esc-b / Esc-f (what Option+Left/Right send) -> word jumps
ensure_nanorc() {
  touch "$NANORC"
  local line
  for line in "bind M-b prevword main" "bind M-f nextword main"; do
    if grep -qxF "$line" "$NANORC"; then
      log "nanorc already has: $line"
    else
      printf '%s\n' "$line" >>"$NANORC"
      log "Added to nanorc: $line"
    fi
  done
}

# 3. iTerm2: map Option+Left/Right on the default profile to send Esc-b / Esc-f
set_iterm_key() {
  local plist="$1" idx="$2" key="$3" text="$4"
  local path=":New Bookmarks:$idx:Keyboard Map:$key"
  "$PLISTBUDDY" -c "Delete '$path'" "$plist" 2>/dev/null || true
  "$PLISTBUDDY" \
    -c "Add '$path' dict" \
    -c "Add '$path:Action' integer 10" \
    -c "Add '$path:Text' string $text" \
    -c "Add '$path:Version' integer 2" \
    -c "Add '$path:Apply Mode' integer 0" \
    -c "Add '$path:Escaping' integer 1" \
    "$plist"
}

ensure_iterm_keys() {
  if ! defaults read "$ITERM_DOMAIN" >/dev/null 2>&1; then
    log "iTerm2 not configured on this machine; skipping"
    return
  fi
  if [[ "$(osascript -e "application id \"$ITERM_DOMAIN\" is running")" == "true" ]]; then
    warn "iTerm2 is running and would overwrite the change on quit."
    warn "Quit iTerm2, then re-run this script from Terminal.app."
    return
  fi

  local tmp guid idx=0 found=""
  tmp="$(mktemp -t iterm2prefs).plist"
  trap 'rm -f "$tmp"; trap - RETURN' RETURN
  defaults export "$ITERM_DOMAIN" "$tmp"
  guid="$(defaults read "$ITERM_DOMAIN" "Default Bookmark Guid")"

  while "$PLISTBUDDY" -c "Print ':New Bookmarks:$idx:Guid'" "$tmp" >/dev/null 2>&1; do
    if [[ "$("$PLISTBUDDY" -c "Print ':New Bookmarks:$idx:Guid'" "$tmp")" == "$guid" ]]; then
      found="$idx"
      break
    fi
    idx=$((idx + 1))
  done
  if [[ -z "$found" ]]; then
    warn "Default iTerm2 profile not found; skipping"
    return
  fi

  "$PLISTBUDDY" -c "Print ':New Bookmarks:$found:Keyboard Map'" "$tmp" >/dev/null 2>&1 ||
    "$PLISTBUDDY" -c "Add ':New Bookmarks:$found:Keyboard Map' dict" "$tmp"
  set_iterm_key "$tmp" "$found" "0xf702-0x280000" b # Option+Left
  set_iterm_key "$tmp" "$found" "0xf703-0x280000" f # Option+Right
  defaults import "$ITERM_DOMAIN" "$tmp"
  log "iTerm2 default profile: Option+Left/Right now send Esc-b / Esc-f"
}

main() {
  ensure_gnu_nano
  ensure_nanorc
  ensure_iterm_keys
  log "Done. Terminal.app already sends Esc-b / Esc-f for Option+arrows by default."
}

main "$@"
