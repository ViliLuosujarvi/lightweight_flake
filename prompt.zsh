# Prompt and interactive helpers. Sourced from aliases.nix.
#
#   ~/lightweight_flake  main ●2 ?1 ⇡1
#   ❯            <- green: ok, red: failed, yellow: command not found
#
# Needs a Nerd Font for the icons (FiraCode Nerd Font is already installed).

setopt PROMPT_SUBST
autoload -Uz add-zsh-hook

# --- Git info ---------------------------------------------------------------
# One `git status` call per prompt: branch, ahead/behind, staged, modified,
# untracked.
function _prompt_git() {
  command git rev-parse --is-inside-work-tree &>/dev/null || return

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
  done < <(command git status --porcelain=v2 --branch 2>/dev/null)

  [[ $branch == '(detached)' ]] && branch=$(command git rev-parse --short HEAD 2>/dev/null)

  local out="%F{magenta} ${branch}%f"
  (( staged ))    && out+=" %F{green}●${staged}%f"
  (( modified ))  && out+=" %F{yellow}✚${modified}%f"
  (( untracked )) && out+=" %F{blue}?${untracked}%f"
  (( ahead ))     && out+=" %F{cyan}⇡${ahead}%f"
  (( behind ))    && out+=" %F{cyan}⇣${behind}%f"
  print -rn -- "$out"
}

# --- Prompt colour: found / failed / not found ------------------------------
# 127 is what the shell returns when the command doesn't exist.
typeset -g _prompt_status=0
function _prompt_precmd() {
  _prompt_status=$?
  _prompt_git_info=$(_prompt_git)
}
# Registered first so $? is still the user's command when it runs.
add-zsh-hook -d precmd _prompt_precmd 2>/dev/null
precmd_functions=(_prompt_precmd ${precmd_functions:#_prompt_precmd})

function _prompt_char() {
  case $_prompt_status in
    0)   print -rn -- '%F{green}❯%f' ;;
    127) print -rn -- '%F{yellow}❯%f' ;;
    *)   print -rn -- '%F{red}❯%f' ;;
  esac
}

# user@host only over ssh or as root; path is the last 3 components.
typeset -g _prompt_who=""
[[ -n $SSH_CONNECTION ]] && _prompt_who='%F{yellow}%n@%m%f '
PROMPT='%(!.%F{red}%n%f .)${_prompt_who}%B%F{blue}%3~%f%b${_prompt_git_info}'$'\n''$(_prompt_char) '
# Exit code of the last command, on the right, only on failure.
RPROMPT='%(?..%F{red}✘ %?%f)'

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
      print -P "%F{8}󰌵 alias available: %F{cyan}${name}%F{8} = ${expansion}%f"
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
