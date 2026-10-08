{ config, pkgs, lib, ... }:

# Home-manager settings shared by every account. Each user's home.nix imports
# this and adds its own packages, username and ./.config tree (themes, app
# settings), so changing one account's look never touches the other.
{
  # Keep this at the value it had on first install. Do not bump it later.
  home.stateVersion = "25.05";

  programs.home-manager.enable = true;

  programs.foot.enable = true;

  # The desktop both accounts use. Package installs are shared through the
  # nix store, so having them in two profiles costs no extra disk space.
  home.packages = with pkgs; [
    kakoune
    waybar
    fastfetch
    btop
    wallust
    kitty
    rofi
    firefox
    networkmanagerapplet

    # foot, kitty and waybar configs all use "FiraCode Nerd Font Mono"
    nerd-fonts.fira-code
  ];

  fonts.fontconfig.enable = true;

  home.sessionVariables = {
    EDITOR = "kak";
    TERMINAL = "foot";
  };
}
