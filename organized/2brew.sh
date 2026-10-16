#!/usr/bin/env bash

# Install Homebrew when it is not already available. Its installer also
# installs the Xcode command-line tools (git, clang), which the oh-my-zsh step
# needs, and waits for them to finish.
if ! command -v brew >/dev/null 2>&1; then
    sub "Installing Homebrew..."
    # NONINTERACTIVE skips the "Press RETURN" prompt, but then the installer
    # only uses cached sudo credentials. Ask for the password once and keep it
    # fresh while the command-line tools download (sudo forgets after 5 min).
    sudo -v
    while kill -0 "$$" 2>/dev/null; do sudo -n true; sleep 60; done 2>/dev/null &
    SUDO_KEEPALIVE_PID=$!
    NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    kill "$SUDO_KEEPALIVE_PID" 2>/dev/null
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
    bun
    python
    wget
    zsh
    zsh-completions
    zsh-syntax-highlighting
    zsh-autosuggestions
    zsh-autocomplete
    yarn
)

# Desktop applications are the casks from app-catalog.sh that were picked in
# the setup checklist.
CASKS=()
for entry in "${APP_CATALOG[@]}"; do
    IFS='|' read -r app_name app_kind app_cask _ <<< "$entry"
    if [[ "$app_kind" == cask ]] && app_selected "$app_name"; then
        CASKS+=("$app_cask")
    fi
done

sub "Installing Homebrew formulae (git, node, python, zsh plugins...)"
brew install "${FORMULAE[@]}"

if (( ${#CASKS[@]} )); then
    sub "Installing selected Homebrew casks"
    brew install --cask "${CASKS[@]}"
fi

# Rebuild the Zsh completion cache after installing the completion packages.
sub "Rebuilding Zsh completion cache"
if command -v zsh >/dev/null 2>&1; then
    BREW_PREFIX="$(brew --prefix)"
    chmod go-w "$BREW_PREFIX/share"
    chmod -R go-w "$BREW_PREFIX/share/zsh"
    # Extend fpath inside zsh. Exporting FPATH from bash replaces zsh's default
    # function path, so compinit itself can no longer be found.
    zsh -c 'fpath=("$1/share/zsh-completions" $fpath); rm -f "$HOME/.zcompdump"; autoload -Uz compinit; compinit' \
        zsh "$BREW_PREFIX"
fi

sub "Cleaning up Homebrew"
brew cleanup