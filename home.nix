{ config, pkgs, ... }:

{
  home.username = "user";
  home.homeDirectory = "/home/user";

  # Keep this at the value it had on first install. Do not bump it later.
  home.stateVersion = "25.05";

  programs.home-manager.enable = true;

  home.packages = with pkgs; [
    foot
    kakoune
    waybar
  ];

  home.sessionVariables = {
    EDITOR = "kak";
    TERMINAL = "foot";
  };

  # --- Dotfiles ---
  # Adapted from https://github.com/ViliLuosujarvi/.dotfiles, hosts/Laptop
  # (hostname NanSuS-Laptop) - trimmed down from that laptop's full JaKooLit-based
  # Hyprland setup to what a GPU-less, single-monitor VM actually needs: no
  # NVIDIA env vars, no multi-monitor rules, no app binds for software that
  # isn't installed here (Steam, Discord, rofi, dolphin, etc).
  xdg.configFile = {
    "hypr/hyprland.conf".text = builtins.readFile ./dotfiles/hyprland.conf;
    "waybar/config.jsonc".text = builtins.readFile ./dotfiles/waybar-config.jsonc;
    "waybar/style.css".text = builtins.readFile ./dotfiles/waybar-style.css;
    "kak/kakrc".text = builtins.readFile ./dotfiles/kakrc;
    "kak/colors/purple_best.kak".text = builtins.readFile ./dotfiles/purple_best.kak;
    "foot/foot.ini".text = builtins.readFile ./dotfiles/foot.ini;
  };
}
