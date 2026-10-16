#!/usr/bin/env bash

# Install Claude Code and its statusline when picked in the setup checklist.
if ! app_selected "Claude Code"; then
    info "Claude Code not selected; skipping"
    return 0
fi

sub "installing Claude Code..."
curl -fsSL https://claude.ai/install.sh | bash
sub "Installing Claude Code statusline"
curl -fsSL \
    https://gist.githubusercontent.com/agrublev/282d6054044953ddcac1c9f09dec9997/raw/0cec9596c8c1f5ea39169f565f3e2b0e8f2b3590/statusline.sh \
    | bash
ok "claude code installed"
