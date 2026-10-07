{ config, pkgs, ... }:

{
  imports = [
    # Picks up whatever `nixos-generate-config` detected on the machine being
    # built. This is an absolute path outside the flake, so evaluation must
    # be impure: `nixos-rebuild switch --flake .#nixos-vm --impure`.
    /etc/nixos/hardware-configuration.nix
  ];

  # --- Boot (UEFI) ---
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # --- Nix ---
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nixpkgs.config.allowUnfree = true;

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
    # Only applied if the account has no password set yet - won't overwrite
    # a password you later set yourself with `passwd`. Change it after login.
    initialPassword = "changeme";
  };

  programs.zsh.enable = true;

  # Hooks direnv into zsh and ships nix-direnv (fast, cached `use flake`).
  programs.direnv.enable = true;

  # --- Login manager (greetd + tuigreet) ---
  # TUI greeter: draws a login prompt directly on the console, no graphics
  # stack of its own, then execs the chosen session command. The regular,
  # systemd-managed way to start Hyprland instead of an autologin shell hack.
  services.greetd = {
    enable = true;
    settings.default_session = {
      command = "${pkgs.tuigreet}/bin/tuigreet --time --cmd Hyprland";
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
