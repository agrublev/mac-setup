#!/usr/bin/env bash

# Point iTerm2 at the settings exported to iterm/ in this repo. iTerm2 reads
# them the next time it launches, so nothing is prompted and an iTerm2 that is
# running this script is not overwritten.
ITERM_DOMAIN="com.googlecode.iterm2"
ITERM_SETTINGS_DIR="${SCRIPT_DIR:-$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)}/iterm"

sub "Loading iTerm2 profile and settings"
if [[ ! -f "$ITERM_SETTINGS_DIR/$ITERM_DOMAIN.plist" ]]; then
    warn "No $ITERM_DOMAIN.plist in $ITERM_SETTINGS_DIR; skipping iTerm2 settings"
elif ! plutil -lint "$ITERM_SETTINGS_DIR/$ITERM_DOMAIN.plist" >/dev/null; then
    warn "$ITERM_DOMAIN.plist is not a valid plist; skipping iTerm2 settings"
else
    defaults write "$ITERM_DOMAIN" PrefsCustomFolder -string "$ITERM_SETTINGS_DIR"
    defaults write "$ITERM_DOMAIN" LoadPrefsFromCustomFolder -bool true
    # Don't show the "changes will be lost" reminder when settings are loaded
    # from a custom folder.
    defaults write "$ITERM_DOMAIN" NoSyncNeverRemindPrefsChangesLostForFile -bool true
    ok "iTerm2 will load its settings from $ITERM_SETTINGS_DIR (restart iTerm2)"
fi
