#!/usr/bin/env bash
osascript -e 'tell application "System Preferences" to quit'
# curl -s http://www.getmacapps.com/raw/ufg0cg3bebl | sh

# Ask for the administrator password upfront
#sudo -v

#while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

echo "Starting bootstrapping"

# Before starting, make sure xcode command line tools is installed
xcode-select --install



# Start with a oh-my-zsh
echo "Installing/updating oh-my-zsh"
if [[ -d ~/.oh-my-zsh ]]; then
    upgrade_oh_my_zsh
else
    chsh -s /bin/zsh
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"
fi




# Check for Homebrew, install if we don't have it
if test ! $(which brew); then
    echo "Installing homebrew..."
    ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
fi


# Update homebrew recipes
brew update

PACKAGES=(
    git
    node
    python
    python3
    wget
)

echo "Installing packages..."
brew install ${PACKAGES[@]}
echo "Cleaning up..."
brew cleanup

echo "Installing cask..."

brew cask install virtualbox

brew cask install vagrant
vagrant plugin install vagrant-vbguest




# Installing useful apps

echo "Installing useful apps"

curl -s 'https://macapps.link/en/firefox-chrome-skitch-github-sequelpro-phpstorm-vscode-iterm-transmission-cord-unarchiver-1password-filezilla-teamviewer-caffeine-vlc-skype' | sh





for app in "App Store"\
	"Safari"\
	"Mail"\
	"News"\
	"Contacts"\
	"Calendar"\
	"Messages"\
	"Reminders"\
	"Maps"\
	"Photos"\
	"FaceTime"\
	"iTunes"\
	"iBooks"\
	"Siri"\
	"Launchpad"; do
	echo $app
        dloc="defaults read com.apple.dock persistent-apps | grep file-label | awk '/$app/  {printf NR}'"
        dloc=$(eval $dloc)
    echo $dloc
    sudo -u $USER /usr/libexec/PlistBuddy -c "Delete persistent-apps:$dloc" ~/Library/Preferences/com.apple.dock.plist
done
osascript -e 'delay 3' -e 'tell Application "Dock"' -e 'quit' -e 'end tell'


# Always show scrollbars
defaults write NSGlobalDomain AppleShowScrollBars -string "Always"

# Disable “natural” (Lion-style) scrolling
defaults write NSGlobalDomain com.apple.swipescrolldirection -bool false


# Trackpad: enable tap to click for this user and for the login screen
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true
defaults -currentHost write NSGlobalDomain com.apple.mouse.tapBehavior -int 1
defaults write NSGlobalDomain com.apple.mouse.tapBehavior -int 1


# Enable tap-to-click
#defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true
#defaults -currentHost write NSGlobalDomain com.apple.mouse.tapBehavior -int 1


# Enable tap-to-click

# Trackpad: enable tap to click for this user and for the login screen
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true
defaults -currentHost write NSGlobalDomain com.apple.mouse.tapBehavior -int 1
defaults write NSGlobalDomain com.apple.mouse.tapBehavior -int 1

# Trackpad: map bottom right corner to right-click
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadCornerSecondaryClick -int 2
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadRightClick -bool true
defaults -currentHost write NSGlobalDomain com.apple.trackpad.trackpadCornerClickBehavior -int 1
defaults -currentHost write NSGlobalDomain com.apple.trackpad.enableSecondaryClick -bool true


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

# Load new settings before rebuilding the index
killall mds > /dev/null 2>&1
# Make sure indexing is enabled for the main volume
sudo mdutil -i on / > /dev/null
# Rebuild the index from scratch
sudo mdutil -E / > /dev/null



###
#
#

#sudo chown -R $(whoami) $(brew --prefix)/*
#sudo chown -R $(whoami):admin /usr/local && sudo chmod -R g+rwx /usr/local
#
## Check for Homebrew, install if we don't have it
#if test ! $(which brew); then
#    echo "Installing homebrew..."
#    ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
#fi

