{ config, pkgs, lib, ... }:

let
  configFilesOf = import ../../common/config-files.nix { inherit lib; };
in
{
  imports = [ ../../common/home.nix ];

  home.username = "user";
  home.homeDirectory = "/home/user";

  # Programming / daily-use extras on top of the common desktop.
  home.packages = with pkgs; [
    proton-vpn
  ];

  # Emacs with every package .config/emacs/init.el `require`s; plain emacs
  # has none of them and init.el stops at the first missing one.
  programs.emacs = {
    enable = true;
    extraPackages = epkgs: with epkgs; [
      vertico
      orderless
      corfu
      evil
      projectile
      treemacs
      doom-modeline
      dashboard
      nerd-icons
      nerd-icons-dired
      nerd-icons-completion
    ];
  };

  home.file.".zshrc".text = ''
    alias vpn=protonvpn-app
  '';

  # --- Dotfiles ---
  # Everything under ./.config is symlinked in as-is. Derived from the laptop
  # dotfiles (github.com/ViliLuosujarvi/.dotfiles) but trimmed for the VM:
  # no blur/shadows/animations, no NVIDIA/multi-monitor/Steam/Discord bits.
  xdg.configFile = configFilesOf ./.config;
}
