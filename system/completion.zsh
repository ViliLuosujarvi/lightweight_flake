# Tab completion and line-editing helpers. Sourced from aliases.nix
# (programs.zsh.interactiveShellInit), which /etc/zshrc runs after compinit,
# so it applies to every user.

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
