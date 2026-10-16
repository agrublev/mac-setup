#!/usr/bin/env bash

# Built-in apps to remove from the Dock, by bundle ID so the match works in
# any system language.
DOCK_REMOVE=(
    com.apple.AppStore            # App Store
    com.apple.Safari              # Safari
    com.apple.mail                # Mail
    com.apple.news                # News
    com.apple.AddressBook         # Contacts
    com.apple.iCal                # Calendar
    com.apple.MobileSMS           # Messages
    com.apple.reminders           # Reminders
    com.apple.Maps                # Maps
    com.apple.Photos              # Photos
    com.apple.Music               # Music
    com.apple.freeform            # Freeform
    com.apple.TV                  # TV
    com.apple.FaceTime            # FaceTime
    com.apple.Notes               # Notes
    com.apple.iTunes              # iTunes (older macOS)
    com.apple.iBooksX             # Books
    com.apple.siri.launcher       # Siri
    com.apple.launchpad.launcher  # Launchpad
)

# Delete every persistent-apps entry in the Dock plist $1 whose bundle ID is
# in DOCK_REMOVE. Indexes are 0-based and shift down after each delete.
remove_dock_apps() {
    local plist="$1" i=0 bundle_id
    while /usr/libexec/PlistBuddy -c "Print persistent-apps:$i" "$plist" >/dev/null 2>&1; do
        bundle_id="$(/usr/libexec/PlistBuddy \
            -c "Print persistent-apps:$i:tile-data:bundle-identifier" "$plist" 2>/dev/null)"
        if [[ -n "$bundle_id" && " ${DOCK_REMOVE[*]} " == *" $bundle_id "* ]]; then
            /usr/libexec/PlistBuddy -c "Print persistent-apps:$i:tile-data:file-label" "$plist"
            /usr/libexec/PlistBuddy -c "Delete persistent-apps:$i" "$plist"
        else
            i=$((i + 1))
        fi
    done
}

sub "Removing built-in apps from the Dock"
# Edit an exported copy and import it back. Writing straight to the file in
# ~/Library/Preferences bypasses the preferences cache, which then serves
# stale data and can overwrite the edit.
DOCK_PLIST="$(mktemp "${TMPDIR:-/tmp}/dock.XXXXXX")"
defaults export com.apple.dock "$DOCK_PLIST"
remove_dock_apps "$DOCK_PLIST"
defaults import com.apple.dock "$DOCK_PLIST"
rm -f "$DOCK_PLIST"
killall Dock

# Configure scrolling and trackpad behavior.
sub "Configuring scrolling and trackpad"
defaults write NSGlobalDomain AppleShowScrollBars -string "Always"
# Turn off natural scrolling (one setting covers mouse and trackpad). macOS
# only reads it at login, so it takes effect after logging out and back in.
defaults write NSGlobalDomain com.apple.swipescrolldirection -bool false
defaults write -g com.apple.swipescrolldirection -bool false
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true
defaults -currentHost write NSGlobalDomain com.apple.mouse.tapBehavior -int 1
defaults write NSGlobalDomain com.apple.mouse.tapBehavior -int 1

sub "Mapping trackpad bottom-right corner to right-click"
# Map the trackpad bottom-right corner to right-click.
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadCornerSecondaryClick -int 2
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadRightClick -bool true
defaults -currentHost write NSGlobalDomain com.apple.trackpad.trackpadCornerClickBehavior -int 1
defaults -currentHost write NSGlobalDomain com.apple.trackpad.enableSecondaryClick -bool true

sub "Configuring Spotlight result categories"
# Configure Spotlight result categories.
defaults write com.apple.spotlight orderedItems -array \
    '{"enabled" = 1;"name" = "APPLICATIONS";}' \
    '{"enabled" = 1;"name" = "SYSTEM_PREFS";}' \
    '{"enabled" = 1;"name" = "DIRECTORIES";}' \
    '{"enabled" = 1;"name" = "PDF";}' \
    '{"enabled" = 1;"name" = "FONTS";}' \
    '{"enabled" = 0;"name" = "DOCUMENTS";}' \
    '{"enabled" = 0;"name" = "MESSAGES";}' \
    '{"enabled" = 0;"name" = "CONTACT";}' \
    '{"enabled" = 0;"name" = "EVENT_TODO";}' \
    '{"enabled" = 0;"name" = "IMAGES";}' \
    '{"enabled" = 0;"name" = "BOOKMARKS";}' \
    '{"enabled" = 0;"name" = "MUSIC";}' \
    '{"enabled" = 0;"name" = "MOVIES";}' \
    '{"enabled" = 0;"name" = "PRESENTATIONS";}' \
    '{"enabled" = 0;"name" = "SPREADSHEETS";}' \
    '{"enabled" = 0;"name" = "SOURCE";}' \
    '{"enabled" = 0;"name" = "MENU_DEFINITION";}' \
    '{"enabled" = 0;"name" = "MENU_OTHER";}' \
    '{"enabled" = 0;"name" = "MENU_CONVERSION";}' \
    '{"enabled" = 0;"name" = "MENU_EXPRESSION";}' \
    '{"enabled" = 0;"name" = "MENU_WEBSEARCH";}' \
    '{"enabled" = 0;"name" = "MENU_SPOTLIGHT_SUGGESTIONS";}'

sub "Rebuilding Spotlight index"
# Rebuild the Spotlight index after changing its result categories.
killall mds >/dev/null 2>&1
sudo mdutil -i on / >/dev/null
sudo mdutil -E / >/dev/null
