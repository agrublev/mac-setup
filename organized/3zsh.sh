#!/usr/bin/env bash

# Start with a oh-my-zsh
sub "Installing/updating oh-my-zsh"
OMZ_DIR="${ZSH:-$HOME/.oh-my-zsh}"
if [[ -d "$OMZ_DIR" ]]; then
    # upgrade_oh_my_zsh only exists inside zsh, so run the upgrade script
    # directly. It is a zsh script and expects $ZSH to point at the install.
    ZSH="$OMZ_DIR" zsh "$OMZ_DIR/tools/upgrade.sh"
else
    chsh -s /bin/zsh
    # RUNZSH=no stops the installer from dropping into zsh mid-setup.
    RUNZSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"
fi

# ---------------------------------------------------------------------------
# Update ~/.zshrc with the blocks managed by this script.
#
# Each block is delimited by marker comments, so re-running the setup replaces
# them instead of appending duplicates. The zsh-plugin block is placed at the
# very top of ~/.zshrc and the aliases/history block at the very bottom.
# ---------------------------------------------------------------------------
ZSHRC="$HOME/.zshrc"
[[ -f "$ZSHRC" ]] || touch "$ZSHRC"

# The markers keep the old "2zsh.sh" name so re-runs still find and replace
# blocks written before this file was renamed.
TOP_BEGIN='# >>> 2zsh.sh plugins (managed) >>>'
TOP_END='# <<< 2zsh.sh plugins <<<'
BOTTOM_BEGIN='# >>> 2zsh.sh aliases/history (managed) >>>'
BOTTOM_END='# <<< 2zsh.sh aliases/history <<<'

read -r -d '' TOP_BLOCK <<'ZSH_TOP' || true
# >>> 2zsh.sh plugins (managed) >>>
source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh
source /opt/homebrew/share/zsh-autocomplete/zsh-autocomplete.plugin.zsh
export ZSH_HIGHLIGHT_HIGHLIGHTERS_DIR=/opt/homebrew/share/zsh-syntax-highlighting/highlighters
# <<< 2zsh.sh plugins <<<
ZSH_TOP

read -r -d '' BOTTOM_BLOCK <<'ZSH_BOTTOM' || true
# >>> 2zsh.sh aliases/history (managed) >>>
# ---------------------------------------------------------------------------
# Package-manager aliases and helpers
# ---------------------------------------------------------------------------
alias y="yarn"
alias ys="yarn start"
alias yr="yarn run"
alias yb="yarn build"
alias yd="yarn add -D"
alias ya="yarn add -W"
alias bb="bun run build"
alias bd="bun add -d"

unalias b 2>/dev/null
b() {
  if [[ $# -eq 0 ]]; then
    bun install
    return
  fi

  case "$1" in
    x|repl|exec|add|remove|update|audit|dedupe|prune|outdated|link|unlink|publish|patch|pm|info|why)
      bun "$@"
      ;;
    *)
      bun run "$@"
      ;;
  esac
}

bs() {
  if [[ -f package.json ]] && grep -q '"start"[[:space:]]*:' package.json; then
    bun run start
  else
    bun run dev
  fi
}

# ---------------------------------------------------------------------------
# General command aliases and helpers
# ---------------------------------------------------------------------------
alias c="claude"
alias o="opencode --yolo"
alias m="muse --yolo"


# ---------------------------------------------------------------------------
# History and key bindings
# ---------------------------------------------------------------------------
HISTFILE="$HOME/.zsh_history"
HISTSIZE=50000
SAVEHIST=50000
unsetopt SHARE_HISTORY
setopt INC_APPEND_HISTORY
setopt EXTENDED_HISTORY
setopt HIST_IGNORE_DUPS

# Restore normal up/down arrow history navigation (zsh-autocomplete overrides it)
bindkey '^[[A' up-line-or-history
bindkey '^[OA' up-line-or-history
bindkey '^[[B' down-line-or-history
bindkey '^[OB' down-line-or-history

# Make Tab / Shift-Tab cycle through zsh-autocomplete suggestions
bindkey '\t' menu-select "$terminfo[kcbt]" menu-select
bindkey -M menuselect '\t' menu-complete "$terminfo[kcbt]" reverse-menu-complete
# <<< 2zsh.sh aliases/history <<<
ZSH_BOTTOM

# Drop a previously managed block (everything between one begin/end marker
# pair) from stdin, using exact line comparison.
strip_block() {
    awk -v begin="$1" -v end="$2" '
        $0 == begin { in_block = 1; next }
        $0 == end   { in_block = 0; next }
        { if (!in_block) print }
    '
}

# Trim blank lines from the top and bottom of stdin while preserving interior
# blank lines, so repeated runs produce the same file.
trim_blank_edges() {
    awk '
        /^[[:space:]]*$/ { if (started) pending++; next }
        {
            started = 1
            while (pending > 0) { print ""; pending-- }
            print
        }
    '
}

sub "Updating ~/.zshrc (zsh plugins, aliases, history)"
tmp="$(mktemp)"
{
    printf '%s\n' "$TOP_BLOCK"
    strip_block "$TOP_BEGIN" "$TOP_END" < "$ZSHRC" \
        | strip_block "$BOTTOM_BEGIN" "$BOTTOM_END" \
        | trim_blank_edges
    printf '%s\n' "$BOTTOM_BLOCK"
} > "$tmp"
mv "$tmp" "$ZSHRC"

echo "Updated ~/.zshrc: zsh plugins at top, aliases/history/key bindings at bottom"
