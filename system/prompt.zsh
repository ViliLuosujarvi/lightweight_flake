# Prompt and interactive helpers. Sourced from aliases.nix (programs.zsh.promptInit,
# which NixOS runs last in /etc/zshrc - anything set earlier would be
# overwritten by the default `prompt suse`).
#
# Plain ASCII, zsh built-ins and git only; no icon font needed.
#
#   user @ host (branch * +1 ~2 ?3 ahead 1) venv /full/path
#   current-folder $                                  1  14:32

setopt PROMPT_SUBST PROMPT_SP
autoload -Uz add-zsh-hook

# --- Git info ---------------------------------------------------------------
# One `git status` call per prompt: branch, ahead/behind, staged, modified,
# untracked. Stored in _prompt_git_info as
# "(branch * +1 ~2 ?3 ahead 1 behind 1) " in yellow; empty outside a
# repository (git status prints nothing there).
#
# `git status` honours the repository's own .git/config, so just cd-ing into a
# downloaded repo (a dumped .git from a target, an extracted tarball) could
# run its core.fsmonitor command; that is switched off here. A filter driver
# in that config could still run, so accounts that handle untrusted repos set
# PROMPT_NO_GIT=1 in ~/.zshrc to leave git out of the prompt entirely.
typeset -g _prompt_git_info=""
function _prompt_git() {
  _prompt_git_info=""
  [[ -n $PROMPT_NO_GIT ]] && return

  local branch="" ahead=0 behind=0 staged=0 modified=0 untracked=0 line
  while IFS= read -r line; do
    case $line in
      '# branch.head '*) branch=${line#\# branch.head } ;;
      '# branch.ab '*)
        ahead=${${line#\# branch.ab +}%% *}
        behind=${line##* -}
        ;;
      '1 '*|'2 '*)
        [[ ${line[3]} != . ]] && (( staged++ ))
        [[ ${line[4]} != . ]] && (( modified++ ))
        ;;
      'u '*) (( modified++ )) ;;
      '? '*) (( untracked++ )) ;;
    esac
  done < <(command git -c core.fsmonitor=false status --porcelain=v2 --branch 2>/dev/null)
  [[ -z $branch ]] && return   # not in a work tree

  [[ $branch == '(detached)' ]] && branch=$(command git rev-parse --short HEAD 2>/dev/null)
  # The prompt expands % sequences after substituting this in, so a branch
  # named e.g. "x%F{red}" must not be able to restyle (or garble) the prompt.
  branch=${branch//\%/%%}

  local out="%F{yellow}(${branch}"
  (( staged + modified + untracked )) && out+=" %F{red}*%F{yellow}"
  (( staged ))    && out+=" %F{green}+${staged}%F{yellow}"
  (( modified ))  && out+=" %F{yellow}~${modified}"
  (( untracked )) && out+=" %F{blue}?${untracked}%F{yellow}"
  (( ahead ))     && out+=" %F{cyan}ahead ${ahead}%F{yellow}"
  (( behind ))    && out+=" %F{cyan}behind ${behind}%F{yellow}"
  _prompt_git_info="$out)%f "
}
add-zsh-hook precmd _prompt_git

# Python virtualenv name, if one is active.
typeset -g _prompt_venv_info=""
function _prompt_venv() {
  _prompt_venv_info=${VIRTUAL_ENV:+"%F{cyan}(${${VIRTUAL_ENV:t}//\%/%%})%f "}
}
add-zsh-hook precmd _prompt_venv

# --- Prompt -----------------------------------------------------------------
# A blank line, then user @ host (git) (venv) full path, then current folder
# and the prompt char.
PROMPT=$'\n'
PROMPT+='%F{magenta}%n%f @ %F{magenta}%m%f ${_prompt_git_info}${_prompt_venv_info}%F{green}%~%f'$'\n'
PROMPT+='%F{yellow}%1~%f %F{magenta}%(!.#.$)%f '
PROMPT2='%F{8}\ %f'

# Exit code (only if non-zero) and a clock, on the right.
RPROMPT='%(?..%F{red}%?%f )%F{blue}%D{%H:%M}%f'

# --- Recommendations --------------------------------------------------------

# 1. Alias reminder: typed a long command that an alias already covers.
function _alias_reminder() {
  local typed=${1## } name expansion
  [[ -z $typed ]] && return
  local first=${typed%% *}
  (( ${+aliases[$first]} )) && return   # already using an alias
  for name expansion in ${(kv)aliases}; do
    (( ${#expansion} < 4 )) && continue
    if [[ $typed == $expansion || $typed == "$expansion "* ]]; then
      print -P "%F{8}tip: alias available: %F{cyan}${name}%F{8} = ${expansion}%f"
      return
    fi
  done
}
add-zsh-hook preexec _alias_reminder

# 2. Command not found: suggest similar commands from your history, then
#    fall back to the nix way of getting it.
function command_not_found_handler() {
  local cmd=$1
  print -u2 -P "%F{yellow}zsh: command not found: ${cmd}%f"

  local -a seen
  local line w
  for line in "${(@f)$(fc -ln 1 2>/dev/null)}"; do
    w=${${line## }%% *}
    [[ -z $w || $w == $cmd ]] && continue
    # same first two letters, or one contains the other
    if [[ ${w[1,2]} == ${cmd[1,2]} || $w == *$cmd* || $cmd == *$w* ]]; then
      (( ${seen[(Ie)$w]} )) || seen+=$w
    fi
    (( ${#seen} >= 3 )) && break
  done
  (( ${#seen} )) && print -u2 -P "%F{8}  did you mean: %F{cyan}${(j:, :)seen}%f"
  print -u2 -P "%F{8}  try it once with: %F{cyan}nix-shell -p ${cmd}%f"
  return 127
}
