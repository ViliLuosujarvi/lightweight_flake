{ pkgs, ... }:

# System-wide shell aliases and zsh history settings. Because these live in
# the NixOS config (/etc/zshrc, /etc/bashrc) they apply to every user, not
# just "user". Trimmed from to_be_incorporated/aliases: personal directory
# jumps, pentesting (nmap), Discord/Steam and other host-specific bits
# were left out.
let
  flake = "/srv/nixos-config";
in
{
  environment.systemPackages = with pkgs; [
    lsd # used by the ls aliases below
    fzf # Ctrl-R / Ctrl-T / Alt-C in zsh, see interactiveShellInit
  ];

  environment.shellAliases = {
    # NixOS + home-manager, from the shared checkout (see configuration.nix).
    # nrs applies the system (needs sudo, so "user" only). hms applies the
    # current account's own home from homeConfigurations.$USER, no sudo; run
    # it as each account after the first install. update bumps the pinned
    # inputs, then rebuilds the system and your home ("user" only). -b bak
    # moves an existing unmanaged file aside instead of aborting.
    nrs = "sudo nixos-rebuild switch --flake ${flake}#nixos-vm --impure";
    hms = "home-manager switch -b bak --flake ${flake}#$USER";
    update = "nix flake update --flake ${flake} && sudo nixos-rebuild switch --flake ${flake}#nixos-vm --impure && home-manager switch -b bak --flake ${flake}#$USER";
    nfu = "nix flake update";
    ncg = "nix-collect-garbage --delete-older-than";
    ncgo = "nix-collect-garbage -d";
    nd = "nix develop";
    ns = "nix-shell";

    # Icons for files/folders in the terminal
    ls = "lsd";
    l = "lsd -l";
    la = "lsd -a";
    lla = "lsd -la";
    lt = "lsd --tree";

    # Go up directories with just dots: ".." is one level, "......" is six
    ".." = "cd ..";
    "..." = "cd ../..";
    "...." = "cd ../../..";
    "....." = "cd ../../../..";
    "......" = "cd ../../../../..";
    "......." = "cd ../../../../../..";

    # PipeWire
    pws = "wpctl status";
    pwds = "wpctl set-default";

    # Kill by (case-insensitive) name
    pk = "pkill -i";

    vpn = "protonvpn-app";
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
    '';

    # NixOS runs promptInit after interactiveShellInit, and its default is
    # `prompt suse`, which would overwrite our PROMPT. So the prompt, alias
    # reminders and command-not-found hints are loaded here instead.
    promptInit = ''
      source ${./prompt.zsh}
    '';

    # Commands turn red as you type if they don't exist, green if they do;
    # greyed-out history suggestions (right arrow to accept).
    syntaxHighlighting.enable = true;
    autosuggestions.enable = true;
  };
}
