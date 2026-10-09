{ pkgs, lib, flakeDir, ... }:

# System-wide shell aliases and zsh settings. Because these live in the NixOS
# config (/etc/zshrc, /etc/bashrc) they apply to every user, not just "user".
# Aliases for programs only one account has go in that account's home.nix.
let
  systemFlake = "--flake ${flakeDir}#nixos-vm --impure";
in
{
  environment.systemPackages = with pkgs; [
    lsd # used by the ls aliases below
  ];

  # Ctrl-R (history), Ctrl-T (files), Alt-C (cd) and fuzzy Tab completion
  # (`**<Tab>`) in zsh.
  programs.fzf = {
    keybindings = true;
    fuzzyCompletion = true;
  };

  environment.shellAliases = {
    # NixOS + home-manager, all against the shared checkout (see
    # configuration.nix). The system ones need sudo, so they're "user" only.
    #   nrs  rebuild + switch the system      nrt  rebuild + activate, no boot entry
    #   nrb  build only (does it compile?)    hms  apply your own home, no sudo
    #   nfu  bump the pinned inputs           nup  nfu + nrs + hms
    # hms runs homeConfigurations.$USER; -b bak moves an existing unmanaged
    # file aside instead of aborting. Clean-up: ngc / nix-delete-all-generations
    # (functions, see interactiveShellInit).
    nrs = "sudo nixos-rebuild switch ${systemFlake}";
    nrt = "sudo nixos-rebuild test ${systemFlake}";
    nrb = "nixos-rebuild build ${systemFlake}";
    hms = "home-manager switch -b bak --flake ${flakeDir}#$USER";
    nfu = "nix flake update --flake ${flakeDir}";
    nup = "nfu && nrs && hms"; # the shell expands the aliases in here too
    nd = "nix develop";
    ns = "nix-shell";

    c = "cd ${flakeDir}";

    # Icons for files/folders in the terminal
    ls = "lsd";
    l = "lsd -l"; # long
    la = "lsd -la"; # long, including hidden files
    lt = "lsd --tree";

    # Go up directories with just dots: ".." is one level, "..." two, and so
    # on up to "......." for six.
    ".." = "cd ..";
    "..." = "cd ../..";
    "...." = "cd ../../..";
    "....." = "cd ../../../..";
    "......" = "cd ../../../../..";
    "......." = "cd ../../../../../..";

    # PipeWire: list devices (with their ids), and pick the default by id
    audio = "wpctl status";
    audio-default = "wpctl set-default";

    # Kill processes by exact name, ignoring case: `pk firefox` doesn't also
    # hit everything else with "firefox" in its name.
    pk = "pkill -i -x";
  };

  programs.zsh = {
    # Also sets HISTFILE (~/.zsh_history) and SAVEHIST.
    histSize = 10000;
    setOptions = [ "APPEND_HISTORY" ];

    # compinit is run below instead, with -C: the default one re-checks every
    # completion directory on each shell start. The dump file is named after
    # the current system and home-manager generations, so it's rebuilt only
    # when either changes (i.e. when completions could have changed).
    enableGlobalCompInit = false;

    interactiveShellInit = lib.mkMerge [
      (lib.mkBefore ''
        () {
          local dump=~/.cache/zcompdump-''${''${:-/run/current-system}:A:t}-''${''${:-$HOME/.nix-profile}:A:t}
          # New generation: drop the dumps of older ones.
          [[ -e $dump ]] || { mkdir -p ~/.cache; rm -f ~/.cache/zcompdump-*(N) }
          autoload -U compinit
          compinit -C -d $dump
        }
      '')

      ''
        # Git aliases (g, gav, gcam, gst, ... the oh-my-zsh git plugin set)
        source ${./git-aliases.zsh}

        # Nix clean-up: delete old generations, then garbage-collect the store.
        # Plain nix-collect-garbage only reaches your own profiles, so accounts
        # in wheel also clean the system's (sudo), which removes old boot
        # entries from the menu on the next nrs. Without rollback afterwards.
        #   ngc 7d                      generations older than 7 days
        #   nix-delete-all-generations  everything but the current ones
        _nix_gc() {
          nix-collect-garbage "$@" || return
          if id -nG | grep -qw wheel; then
            sudo nix-collect-garbage "$@"
          fi
        }
        ngc() {
          if [[ -z $1 ]]; then
            print -u2 "usage: ngc <age>, e.g. ngc 7d"
            return 1
          fi
          _nix_gc --delete-older-than "$1"
        }
        nix-delete-all-generations() { _nix_gc -d }
      ''

      # After the zsh-autosuggestions (default order) and
      # zsh-syntax-highlighting (mkAfter) plugins: completion.zsh overrides
      # the suggestion strategy the autosuggestions module sets, and
      # history-substring-search has to come after syntax-highlighting.
      (lib.mkOrder 2000 ''
        # Tab completion (case-insensitive, menu, colors, typo fixes) and
        # the autosuggestion settings.
        source ${./completion.zsh}

        # Type part of a command, then Up/Down cycles only through history
        # lines containing it (case-insensitive).
        source ${pkgs.zsh-history-substring-search}/share/zsh-history-substring-search/zsh-history-substring-search.zsh
        bindkey '^[[A' history-substring-search-up
        bindkey '^[OA' history-substring-search-up
        bindkey '^[[B' history-substring-search-down
        bindkey '^[OB' history-substring-search-down
      '')
    ];

    # NixOS runs promptInit after interactiveShellInit, and its default is
    # `prompt suse`, which would overwrite our PROMPT. So the prompt, alias
    # reminders and command-not-found hints are loaded here instead.
    promptInit = ''
      source ${./prompt.zsh}
    '';

    # Commands turn red as you type if they don't exist, green if they do;
    # greyed-out suggestions (right arrow to accept): folders for `cd`,
    # otherwise history (see completion.zsh).
    syntaxHighlighting.enable = true;
    autosuggestions.enable = true;
  };
}
