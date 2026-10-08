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
    emacs
    proton-vpn
  ];

  # --- Dotfiles ---
  # Everything under ./.config is symlinked in as-is. Derived from the laptop
  # dotfiles (github.com/ViliLuosujarvi/.dotfiles) but trimmed for the VM:
  # no blur/shadows/animations, no NVIDIA/multi-monitor/Steam/Discord bits.
  xdg.configFile = configFilesOf ./.config;
}
