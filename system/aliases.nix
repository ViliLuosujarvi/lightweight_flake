{ pkgs, ... }:

# System-wide shell aliases and zsh history settings. Because these live in
# the NixOS config (/etc/zshrc, /etc/bashrc) they apply to every user, not
# just "user". Trimmed from to_be_incorporated/aliases: personal directory
# jumps, pentesting (nmap), Discord/Steam and other host-specific bits
# were left out.
{
  environment.systemPackages = with pkgs; [
    lsd # used by the ls aliases below
    fzf # Ctrl-R / Ctrl-T / Alt-C in zsh, see interactiveShellInit
  ];

  environment.shellAliases = {
    # NixOS / home-manager. The flake is expected at ~/nixos-config, so these
    # work from any directory, and hms/update build the config of whichever
    # account runs them ($USER = "user" or "pentest"). --impure is needed
    # because configuration.nix imports /etc/nixos/hardware-configuration.nix.
    hms = "home-manager switch --flake $HOME/nixos-config#$USER";
    nrs = "sudo nixos-rebuild switch --flake $HOME/nixos-config#nixos-vm --impure";
    update = "home-manager switch --flake $HOME/nixos-config#$USER";
    upgrade = "sudo nixos-rebuild switch --flake $HOME/nixos-config#nixos-vm --impure";
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
