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

  # --- Login manager (greetd + tuigreet) ---
  # TUI greeter: draws a login prompt directly on the console, no graphics
  # stack of its own, then execs the chosen session command. The regular,
  # systemd-managed way to start Hyprland instead of an autologin shell hack.
  services.greetd = {
    enable = true;
    settings.default_session = {
      command = "${pkgs.greetd.tuigreet}/bin/tuigreet --time --cmd Hyprland";
      user = "greeter";
    };
  };

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
