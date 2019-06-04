#!/usr/bin/env bash

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
