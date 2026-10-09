{ pkgs, ... }:

# System-wide shell aliases and zsh history settings. Because these live in
# the NixOS config (/etc/zshrc, /etc/bashrc) they apply to every user, not
# just "user". Trimmed from to_be_incorporated/aliases: personal directory
# jumps, pentesting (nmap), Discord/Steam and other host-specific bits
# were left out.
let
  flake = "/srv/nixos-vm-config";
in
{
  environment.systemPackages = with pkgs; [
    lsd # used by the ls aliases below
    fzf # Ctrl-R / Ctrl-T / Alt-C in zsh, see interactiveShellInit
  ];

  environment.shellAliases = {
    # NixOS + home-manager, all against the shared checkout (see
    # configuration.nix). The system ones need sudo, so they're "user" only.
    #   nrs  rebuild + switch the system      nrt  rebuild + activate, no boot entry
    #   nrb  build only (does it compile?)    hms  apply your own home, no sudo
    #   nfu  bump the pinned inputs           nup  nfu + nrs + hms
    # hms runs homeConfigurations.$USER; -b bak moves an existing unmanaged
    # file aside instead of aborting. Clean-up: ngc / nix-delete-all-generations
    # (functions, see interactiveShellInit).
    nrs = "sudo nixos-rebuild switch --flake ${flake}#nixos-vm --impure";
    nrt = "sudo nixos-rebuild test --flake ${flake}#nixos-vm --impure";
    nrb = "nixos-rebuild build --flake ${flake}#nixos-vm --impure";
    hms = "home-manager switch -b bak --flake ${flake}#$USER";
    nfu = "nix flake update --flake ${flake}";
    nup = "nix flake update --flake ${flake} && sudo nixos-rebuild switch --flake ${flake}#nixos-vm --impure && home-manager switch -b bak --flake ${flake}#$USER";
    nd = "nix develop";
    ns = "nix-shell";

    c = "cd /srv/nixos-vm-config/";

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
    histSize = 10000;
    setOptions = [ "APPEND_HISTORY" ];
    interactiveShellInit = ''
      HISTFILE=~/.zsh_history
      SAVEHIST=10000
      source <(${pkgs.fzf}/bin/fzf --zsh)

      # Git aliases (g, gav, gcam, gst, ... the oh-my-zsh git plugin set)
      source ${./git-aliases.zsh}

      # Tab completion (case-insensitive, menu, colors, typo fixes) and
      # word-by-word accepting of autosuggestions.
      source ${./completion.zsh}

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
    '';

    # NixOS runs promptInit after interactiveShellInit, and its default is
    # `prompt suse`, which would overwrite our PROMPT. So the prompt, alias
    # reminders and command-not-found hints are loaded here instead.
    promptInit = ''
      source ${./prompt.zsh}

      # Type part of a command, then Up/Down cycles only through history
      # lines containing it (case-insensitive). Loaded here because it has
      # to come after zsh-syntax-highlighting.
      source ${pkgs.zsh-history-substring-search}/share/zsh-history-substring-search/zsh-history-substring-search.zsh
      bindkey '^[[A' history-substring-search-up
      bindkey '^[OA' history-substring-search-up
      bindkey '^[[B' history-substring-search-down
      bindkey '^[OB' history-substring-search-down
    '';

    # Commands turn red as you type if they don't exist, green if they do;
    # greyed-out history suggestions (right arrow to accept).
    syntaxHighlighting.enable = true;
    autosuggestions.enable = true;
  };
}
