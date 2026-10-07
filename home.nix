{ config, pkgs, lib, ... }:

let
  # Recursively walk a directory and turn every regular file it contains
  # into an xdg.configFile entry, keyed by its path relative to that
  # directory - so ./.config/hypr/UserConfigs/Keybinds.conf becomes the
  # xdg.configFile key "hypr/UserConfigs/Keybinds.conf", symlinked from the
  # nix store at ~/.config/hypr/UserConfigs/Keybinds.conf.
  #
  # Each file gets its own symlink (rather than symlinking whole directories
  # wholesale) so that apps which write runtime state next to their config
  # (btop's log, emacs' eln-cache/auto-save-list, etc.) still get a normal,
  # writable directory to do that in.
  configFilesOf = dir:
    lib.concatMapAttrs
      (name: type:
        let path = dir + "/${name}"; in
        if type == "directory" then
          lib.mapAttrs' (k: v: lib.nameValuePair "${name}/${k}" v) (configFilesOf path)
        else
          { ${name} = { source = path; }; }
      )
      (builtins.readDir dir);
in
{
  home.username = "user";
  home.homeDirectory = "/home/user";

  # Keep this at the value it had on first install. Do not bump it later.
  home.stateVersion = "25.05";

  programs.home-manager.enable = true;

  programs.foot.enable = true;

  home.packages = with pkgs; [
    kakoune
    waybar
    fastfetch
    btop
    neofetch
    wallust
    direnv
    kitty
    rofi-wayland
    emacs
  ];

  fonts.fontconfig.enable = true;

  home.sessionVariables = {
    EDITOR = "kak";
    TERMINAL = "foot";
  };

  # --- Dotfiles ---
  # Everything under ./.config is the real, untrimmed desktop config from
  # https://github.com/ViliLuosujarvi/.dotfiles (hosts/Laptop), symlinked
  # in as-is. Some of it (NVIDIA env vars, multi-monitor rules, keybinds for
  # apps like Steam/Discord/dolphin that aren't installed here) won't do
  # anything useful on a lightweight VM, but it's kept verbatim rather than
  # re-trimmed.
  xdg.configFile = configFilesOf ./.config;
}
