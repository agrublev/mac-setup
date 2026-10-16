#!/usr/bin/env bash

# Apps offered in the setup checklist. setup.sh sources this before any
# section runs; 2brew.sh installs the picked casks, 4apps.sh the picked
# downloads, and "section" entries are installed by their own section file.
#
# Each entry is "Name|kind|target|source":
#   cask           Name|cask|<cask token>
#   dmg, zip, tar  Name|<archive type>|<app bundle>|<download URL>
#   section        Name|section|<section file that installs it>
# A source of "github:owner/repo" downloads the newest release asset of that
# archive type instead of a fixed URL.
APP_CATALOG=(
    "Claude Code|section|1claude.sh"
    "iTerm2|cask|iterm2"
    "Visual Studio Code|cask|visual-studio-code"
    "WebStorm|cask|webstorm"
    "VLC|cask|vlc"
    "The Unarchiver|cask|the-unarchiver"
    "Caffeine|cask|caffeine"
    "Chrome|dmg|Google Chrome.app|https://dl.google.com/chrome/mac/stable/GGRO/googlechrome.dmg"
    "GitHub|zip|GitHub Desktop.app|https://central.github.com/deployments/desktop/desktop/latest/darwin"
    "SequelPro|dmg|Sequel Pro.app|https://sequelpro.com/release?do=download-latest"
    "Sketch|zip|Sketch.app|https://www.sketchapp.com/download/sketch.zip"
    "Postman|zip|Postman.app|https://dl.pstmn.io/download/latest/osx"
    "Transmission|dmg|Transmission.app|https://github.com/transmission/transmission-releases/raw/master/Transmission-3.00.dmg"
    "1Password|zip|1Password 7.app|https://cachefly-origin.agilebits.com/dist/1P/mac7/1Password-7.10.4.zip"
    "ForkLift|zip|ForkLift.app|https://download.binarynights.com/ForkLift3.zip"
    "Etcher|dmg|balenaEtcher.app|https://github.com/balena-io/etcher/releases/download/v1.7.2/balenaEtcher-1.7.2.dmg"
    "HandBrake|dmg|HandBrake.app|https://download.handbrake.fr/releases/1.1.1/HandBrake-1.1.1.dmg"
    "Rectangle|dmg|Rectangle.app|github:rxhanson/Rectangle"
)
