{ pkgs, ... }:

# The "user" account: common/home.nix plus these. Its own dotfiles (themes,
# colors) are in ./.config, on top of common/.config.
{
  # Programming / daily-use extras on top of the common desktop.
  home.packages = with pkgs; [
    proton-vpn
    freecad
  ];

  # System zsh reads ~/.zshrc after /etc/zshrc, so aliases for programs only
  # this account has live here.
  home.file.".zshrc".text = ''
    alias vpn=protonvpn-app
    alias cad=freecad
  '';
}
