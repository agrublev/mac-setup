#!/usr/bin/env bash

# Install Homebrew when it is not already available. Its installer also
# installs the Xcode command-line tools (git, clang), which the oh-my-zsh step
# needs, and waits for them to finish.
if ! command -v brew >/dev/null 2>&1; then
    sub "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# Add the standard Homebrew location to this shell after a fresh install.
if ! command -v brew >/dev/null 2>&1; then
    if [[ -x /opt/homebrew/bin/brew ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    elif [[ -x /usr/local/bin/brew ]]; then
        eval "$(/usr/local/bin/brew shellenv)"
    fi
fi

sub "Updating Homebrew recipes"
brew update

# Command-line tools and Zsh plugins are formulae.
FORMULAE=(
    git
    node
    python
    python3
    wget
    zsh
    zsh-completions
    zsh-syntax-highlighting
    zsh-autosuggestions
    zsh-npm-scripts-autocomplete
    yarn
)

# Desktop applications are casks.
CASKS=(
    iterm2
    visual-studio-code
    webstorm
    vlc
    the-unarchiver
    caffeine
)

sub "Installing Homebrew formulae (git, node, python, zsh plugins...)"
brew install "${FORMULAE[@]}"

sub "Installing Homebrew casks (iTerm2, VS Code, WebStorm...)"
brew install --cask "${CASKS[@]}"

# Rebuild the Zsh completion cache after installing the completion packages.
sub "Rebuilding Zsh completion cache"
if command -v zsh >/dev/null 2>&1; then
    BREW_PREFIX="$(brew --prefix)"
    chmod go-w "$BREW_PREFIX/share"
    chmod -R go-w "$BREW_PREFIX/share/zsh"
    FPATH="$BREW_PREFIX/share/zsh-completions:$FPATH" \
        zsh -c 'rm -f "$HOME/.zcompdump"; autoload -Uz compinit; compinit'
fi

sub "Cleaning up Homebrew"
brew cleanup