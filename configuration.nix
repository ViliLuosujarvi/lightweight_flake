{ config, pkgs, ... }:

{
  imports = [
    # `nixos-generate-config` writes this to /etc/nixos/hardware-configuration.nix
    # on every NixOS machine by default, so this always picks up whatever the
    # machine it's built on actually detected - no copying into the flake needed.
    /etc/nixos/hardware-configuration.nix
  ];

  # --- Boot (UEFI) ---
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "nixos-vm";
  networking.networkmanager.enable = true;

  time.timeZone = "UTC";
  i18n.defaultLocale = "en_US.UTF-8";
  console.keyMap = "us";

  # --- User ---
  users.users.user = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" "video" ];
    shell = pkgs.zsh;
  };

  programs.zsh.enable = true;

  # Autologin on tty1, then exec Hyprland straight from the login shell.
  # No display manager at all -> lightest possible path to a graphical session.
  services.getty.autologinUser = "user";
  programs.zsh.loginShellInit = ''
    if [ -z "$DISPLAY" ] && [ "$(tty)" = "/dev/tty1" ]; then
      exec Hyprland
    fi
  '';

  # --- Hyprland ---
  programs.hyprland.enable = true;

  # --- Audio (PipeWire) ---
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    pulse.enable = true;
  };

  # --- CLI / packages ---
  # foot, kakoune and waybar are user-level, managed via home-manager (home.nix)
  # alongside their dotfiles, so they're not duplicated here.
  environment.systemPackages = with pkgs; [
    git
    gh
    wget
    curl
  ];

  # Keep this at the value it had on first install. Do not bump it later.
  system.stateVersion = "25.05";
}
