# Tab completion, autosuggestion settings and line-editing helpers. Sourced
# from aliases.nix (programs.zsh.interactiveShellInit, after compinit and the
# autosuggestions/syntax-highlighting plugins), so it applies to every user.

# --- Completion -------------------------------------------------------------
# Plain completion first; if nothing matches, allow typos (_approximate).
zstyle ':completion:*' completer _complete _approximate
# Typos allowed: one per three typed characters, at most two
# (`cd Dokuments<Tab>` -> Documents).
zstyle -e ':completion:*:approximate:*' max-errors \
  'reply=( $(( ($#PREFIX + $#SUFFIX) / 3 > 2 ? 2 : ($#PREFIX + $#SUFFIX) / 3 )) numeric )'

# Case-insensitive: `doc<Tab>` matches Documents, `DOC<Tab>` matches docker.
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'

# Menu: Tab opens a list you move through with the arrow keys.
zstyle ':completion:*' menu select

# Colors: files colored like ls (zsh's defaults when LS_COLORS is unset),
# matches grouped under headers such as "-- external command --".
zstyle ':completion:*:default' list-colors ${(s.:.)LS_COLORS}
zstyle ':completion:*' group-name ''
zstyle ':completion:*:descriptions' format '%F{yellow}-- %d --%f'
zstyle ':completion:*:corrections' format '%F{red}-- %d (errors: %e) --%f'
zstyle ':completion:*:warnings' format '%F{red}-- no matches --%f'

# --- Suggestions ------------------------------------------------------------
# Accept just the next word of the grey autosuggestion: Ctrl+Right or Alt+f
# (Right arrow / End still accept all of it).
bindkey '^[[1;5C' forward-word
bindkey '^[f' forward-word

# Where the grey suggestion comes from: folders for `cd` (cd_dirs, below),
# otherwise history. Set here because the autosuggestions module only accepts
# its built-in strategy names, and resets this before this file is sourced.
ZSH_AUTOSUGGEST_STRATEGY=(cd_dirs history)
# Wrap the line-editor widgets once, at the first prompt, instead of again
# before every prompt (all plugins are loaded by then).
ZSH_AUTOSUGGEST_MANUAL_REBIND=1

# For `cd`, suggest a matching folder in the current directory before history.
# Exact case wins, else case-insensitive. The suggestion can only append to
# what's typed, so `cd ge` shows `cd ge|neral/`; _cd_fix_case turns that into
# `cd General/` on Enter, if that path doesn't exist and exactly one folder
# matches.
_zsh_autosuggest_strategy_cd_dirs() {
  emulate -L zsh -o extendedglob
  [[ $1 == cd\ * ]] || return
  local word=${1#cd }
  local -a dirs=( ${(b)word}*(N/) )
  (( $#dirs )) || dirs=( (#i)${(b)word}*(N/) )
  (( $#dirs )) && typeset -g suggestion="$1${dirs[1]:$#word}/"
}
_cd_fix_case() {
  emulate -L zsh -o extendedglob
  [[ $BUFFER == cd\ * ]] || return
  local word=${BUFFER#cd }
  [[ -z $word || -d $word ]] && return
  local -a m=( (#i)${(b)word%/}(N/) )
  (( $#m == 1 )) && BUFFER="cd $m[1]/"
}
autoload -Uz add-zle-hook-widget
add-zle-hook-widget zle-line-finish _cd_fix_case
