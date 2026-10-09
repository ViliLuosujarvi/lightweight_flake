{ config, pkgs, lib, ... }:

# Home-manager settings shared by every account. flake.nix combines this
# with users/<name>/home.nix (the account's own packages and shell lines)
# and sets the username.
let
  configFilesOf = import ./config-files.nix { inherit lib; };
  loadSessionVars = ''
    . "${config.home.sessionVariablesPackage}/etc/profile.d/hm-session-vars.sh"
  '';
in
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
    rofi
    firefox
    networkmanagerapplet
    pavucontrol # waybar volume module, left click
    claude-code


    # foot uses "FiraCode Nerd Font"
    nerd-fonts.fira-code
  ];

  fonts.fontconfig.enable = true;

  home.sessionVariables = {
    EDITOR = "kak";
    TERMINAL = "foot";
  };

  # zsh itself is configured system-wide (system/aliases.nix), so home-manager
  # doesn't manage it and wouldn't load home.sessionVariables on its own.
  # ~/.profile is read by the login screen's session wrapper, so sway and
  # everything started from it get them; ~/.zshenv covers every zsh,
  # scripts included. (Having a ~/.zshenv also stops zsh's first-run setup
  # wizard.) The script only runs once per session: after changing a
  # variable, log out and back in.
  home.file.".profile".text = loadSessionVars;
  home.file.".zshenv".text = loadSessionVars;

  # --- Dotfiles ---
  # Everything under common/.config is symlinked into every account's
  # ~/.config; users/<name>/.config adds the account's own files (themes,
  # colors) and replaces any shared file it has its own copy of. Derived from
  # the laptop dotfiles (github.com/ViliLuosujarvi/.dotfiles) but trimmed for
  # the VM: no blur/shadows/animations, no NVIDIA/multi-monitor/Steam/Discord
  # bits.
  xdg.configFile =
    configFilesOf ./.config
    // configFilesOf (../users + "/${config.home.username}/.config");
}
