# Powerlevel10k instant prompt must be initialized before other shell setup.
typeset -g POWERLEVEL9K_INSTANT_PROMPT=quiet
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# ---------------------------------------------------------------------------
# Paths and SDK locations
# ---------------------------------------------------------------------------
export ZSH="$HOME/.oh-my-zsh"
export PNPM_HOME="$HOME/Library/pnpm"
export ANDROID_HOME="$HOME/Library/Android/sdk"
export JAVA_HOME="$(/usr/libexec/java_home -v 17)"

# Add the Google Cloud SDK before assembling the consolidated PATH.
if [[ -f "$HOME/Downloads/google-cloud-sdk/path.zsh.inc" ]]; then
  source "$HOME/Downloads/google-cloud-sdk/path.zsh.inc"
fi

export PATH

# Keep one copy of each entry. Ordering retains the existing preference for
# user-installed tools while grouping all PATH configuration in one place.
typeset -U path
path=(
  "/Applications/WebStorm.app/Contents/MacOS"
  "$HOME/.backboard/bin"
  "$HOME/.grok/bin"
  "$HOME/.kimi-code/bin"
  "$HOME/.local/bin"
  "$HOME/.opencode/bin"
  "/usr/local/opt/openjdk@17/bin"
  "/opt/homebrew/opt/openjdk@17/bin"
  "$HOME/.antigravity/antigravity/bin"
  "$PNPM_HOME"
  "/usr/local/opt/postgresql@16/bin"
  "/opt/homebrew/lib/ruby/gems/3.3.0/bin"
  "/opt/homebrew/opt/ruby/bin"
  "$HOME/.npm-global/bin"
  "$HOME/.bun/bin"
  "$HOME/bin"
  $path
  "$HOME/.maestro/bin"
  "$ANDROID_HOME/platform-tools"
  "$ANDROID_HOME/cmdline-tools/latest/bin"
  "$ANDROID_HOME/emulator"
)

# ---------------------------------------------------------------------------
# Oh My Zsh and plugins
# ---------------------------------------------------------------------------
ZSH_THEME="powerlevel10k/powerlevel10k"
plugins=(
  git
  zsh-completions
  zsh-npm-scripts-autocomplete
  zsh-help
  zsh-autosuggestions
  zsh-syntax-highlighting
)
source "$ZSH/oh-my-zsh.sh"

# ---------------------------------------------------------------------------
# Environment defaults and credentials
# ---------------------------------------------------------------------------
export EDITOR="nano"
export LANG="en_US.UTF-8"
export LC_ALL="en_US.UTF-8"
export COREPACK_ENABLE_AUTO_PIN=0
export PYO3_USE_ABI3_FORWARD_COMPATIBILITY=1
export ENABLE_EXPERIMENTAL_MCP_CLI='true'

# Non-secret service configuration.
export AI_GATEWAY_MODEL="anthropic/claude-sonnet-5"
export AI_GATEWAY_URL="https://ai-gateway.vercel.sh"
export AWS_PROFILE="admin"
export AWS_REGION="us-east-1"
export LINEAR_CLIENT_ID="c4aa03f475c5723131a8771eb5bdce1b"
export N8N_API_URL="https://agruble.app.n8n.cloud/api/v1"

# Keep API keys and long-lived credentials out of this tracked file. Put their
# exports in ~/.config/zsh/secrets.zsh and restrict it with: chmod 600 <file>.
ZSH_SECRETS_FILE="${XDG_CONFIG_HOME:-$HOME/.config}/zsh/secrets.zsh"
if [[ -r "$ZSH_SECRETS_FILE" ]]; then
  source "$ZSH_SECRETS_FILE"
fi
unset ZSH_SECRETS_FILE

# ---------------------------------------------------------------------------
# Runtime initialization and shell integrations
# ---------------------------------------------------------------------------
eval "$(rbenv init -)"

if [[ -r "$HOME/.iterm2_shell_integration.zsh" ]]; then
  source "$HOME/.iterm2_shell_integration.zsh"
fi

if [[ -f "$HOME/Downloads/google-cloud-sdk/completion.zsh.inc" ]]; then
  source "$HOME/Downloads/google-cloud-sdk/completion.zsh.inc"
fi

# Docker Desktop completions.
fpath=("$HOME/.docker/completions" $fpath)

# Bun completions.
if [[ -s "$HOME/.bun/_bun" ]]; then
  source "$HOME/.bun/_bun"
fi

# Grok completions.
fpath=("$HOME/.grok/completions/zsh" $fpath)
autoload -Uz compinit && compinit -C

# OpenClaw completion.
if [[ -f "$HOME/.openclaw/completions/openclaw.zsh" ]]; then
  source "$HOME/.openclaw/completions/openclaw.zsh"
fi

# # ---------------------------------------------------------------------------
# # Package-manager aliases and helpers
# # ---------------------------------------------------------------------------
# alias y="yarn"
# alias ys="yarn start"
# alias yr="yarn run"
# alias yb="yarn build"
# alias yd="yarn add -D"
# alias ya="yarn add -W"
# alias bb="bun run build"
# alias bd="bun add -d"
#
# unalias b 2>/dev/null
# b() {
#   if [[ $# -eq 0 ]]; then
#     bun install
#     return
#   fi
#
#   case "$1" in
#     x|repl|exec|add|remove|update|audit|dedupe|prune|outdated|link|unlink|publish|patch|pm|info|why)
#       bun "$@"
#       ;;
#     *)
#       bun run "$@"
#       ;;
#   esac
# }
#
# bs() {
#   if [[ -f package.json ]] && grep -q '"start"[[:space:]]*:' package.json; then
#     bun run start
#   else
#     bun run dev
#   fi
# }
#
# # ---------------------------------------------------------------------------
# # General command aliases and helpers
# # ---------------------------------------------------------------------------
# alias c="claude"
# alias o="opencode --yolo"
# alias m="muse --yolo"

# ---------------------------------------------------------------------------
# Filesystem and navigation aliases
# ---------------------------------------------------------------------------
alias cat="bat --paging=never"
alias lc='colorls'
alias l='colorls -l'
alias ll='colorls -lA'
alias la='colorls -la'
alias lS='colorls -lS'
alias lx='colorls -lX'
alias lr='colorls --tree=5'
alias dus='du -sh *'

# ---------------------------------------------------------------------------
# Service helpers
# ---------------------------------------------------------------------------
alias mysql-start='pkill -f "/opt/homebrew.*mysqld " 2>/dev/null; sleep 1; nohup /opt/homebrew/opt/mysql@8.4/bin/mysqld --user=$(whoami) --datadir=/opt/homebrew/var/mysql --socket=/tmp/mysql.sock --pid-file=/tmp/mysql.pid --skip-networking --log-error=/tmp/mysql_err.log &'

# # ---------------------------------------------------------------------------
# # History and key bindings
# # ---------------------------------------------------------------------------
# HISTFILE="$HOME/.zsh_history"
# HISTSIZE=50000
# SAVEHIST=50000
# unsetopt SHARE_HISTORY
# setopt INC_APPEND_HISTORY
# setopt EXTENDED_HISTORY
# setopt HIST_IGNORE_DUPS


# ---------------------------------------------------------------------------
# Prompt and directory-change helpers
# ---------------------------------------------------------------------------
[[ ! -f "$HOME/.p10k.zsh" ]] || source "$HOME/.p10k.zsh"
if [[ -r "${XDG_CONFIG_HOME:-$HOME/.config}/zi/init.zsh" ]]; then
  source "${XDG_CONFIG_HOME:-$HOME/.config}/zi/init.zsh" && zzinit
fi

_fscr_greet() {
  if [[ -f "fscripts.md" ]]; then
    echo ""
    echo "\033[1;32m👋  fscripts.md found!\033[0m  Run \033[1;36myarn fsr\033[0m to launch the script runner."
    echo ""
  fi
}
chpwd_functions+=(_fscr_greet)
_fscr_greet

# ---------------------------------------------------------------------------
# Optional / disabled configuration retained for reference
# ---------------------------------------------------------------------------
# export GOOGLE_APPLICATION_CREDENTIALS="$HOME/DEVELOPMENT/fc-uservoice/packages/p-react/fs.json"
# export NVM_DIR="$HOME/.nvm"
# Lazy-load nvm: sourcing nvm.sh runs `nvm use` on every shell launch.
# _nvm_lazy_load() {
#   unset -f nvm node npm npx yarn pnpm corepack _nvm_lazy_load
#   [[ -s "/usr/local/opt/nvm/nvm.sh" ]] && source "/usr/local/opt/nvm/nvm.sh"
#   [[ -s "$NVM_DIR/nvm.sh" ]] && source "$NVM_DIR/nvm.sh"
#   [[ -s "/usr/local/opt/nvm/etc/bash_completion.d/nvm" ]] && source "/usr/local/opt/nvm/etc/bash_completion.d/nvm"
#   [[ -s "$NVM_DIR/bash_completion" ]] && source "$NVM_DIR/bash_completion"
# }
# for _nvm_cmd in nvm node npm npx yarn pnpm corepack; do
#   eval "${_nvm_cmd}() { _nvm_lazy_load; ${_nvm_cmd} \"\$@\"; }"
# done
# unset _nvm_cmd
#
# Disabled keyboard navigation variants:
# autoload -U up-line-or-beginning-search down-line-or-beginning-search
# zle -N up-line-or-beginning-search
# zle -N down-line-or-beginning-search
# bindkey "^[[A" up-line-or-beginning-search
# bindkey "^[[B" down-line-or-beginning-search
#
# Legacy zplug setup (unused):
# source "$HOME/.zplug/init.zsh"
# zplug "g-plane/zsh-yarn-autocompletions", hook-build:"./zplug.zsh", defer:2
# zplug "buonomo/yarn-extra-completion", defer:2
# zplug "Freed-Wu/zsh-help", defer:2
# zplug "me3n/iterm-tab-colors", defer:2
