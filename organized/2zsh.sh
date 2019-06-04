#!/usr/bin/env bash

# Start with a oh-my-zsh
echo "Installing/updating oh-my-zsh"
if [[ -d ~/.oh-my-zsh ]]; then
    upgrade_oh_my_zsh
else
    chsh -s /bin/zsh
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"
fi
