#!/usr/bin/env bash

# Install the Xcode command-line tools and Claude Code.
sub "Installing Xcode command-line tools"
xcode-select --install
ok "git installed"

sub "installing Claude Code..."
curl -fsSL https://claude.ai/install.sh | bash
sub "Installing Claude Code statusline"
curl -fsSL \
    https://gist.githubusercontent.com/agrublev/282d6054044953ddcac1c9f09dec9997/raw/0cec9596c8c1f5ea39169f565f3e2b0e8f2b3590/statusline.sh \
    | bash
ok "claude code installed"
