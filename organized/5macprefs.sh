#!/usr/bin/env bash

# Remove selected built-in apps from the Dock.
sub "Removing built-in apps from the Dock"
for app in "App Store" \
    "Safari" \
    "Mail" \
    "News" \
    "Contacts" \
    "Calendar" \
    "Messages" \
    "Reminders" \
    "Maps" \
    "Photos" \
    "Music" \
    "Freeform" \
    "TV" \
    "Apple TV" \
    "Apple Music" \
    "News" \
    "FaceTime" \
    "iTunes" \
    "iBooks" \
    "Siri" \
    "Launchpad"; do
    echo "$app"
    dloc="$(defaults read com.apple.dock persistent-apps | grep file-label | awk -v app="$app" '$0 ~ app {print NR; exit}')"
    if [[ -n "$dloc" ]]; then
        /usr/libexec/PlistBuddy -c "Delete persistent-apps:$dloc" \
            "$HOME/Library/Preferences/com.apple.dock.plist"
    fi
done
osascript -e 'delay 3' -e 'tell Application "Dock"' -e 'quit' -e 'end tell'

# Configure scrolling and trackpad behavior.
sub "Configuring scrolling and trackpad"
defaults write NSGlobalDomain AppleShowScrollBars -string "Always"
# Turn off natural scrolling (one setting covers mouse and trackpad). macOS
# only reads it at login, so it takes effect after logging out and back in.
defaults write NSGlobalDomain com.apple.swipescrolldirection -bool false
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
