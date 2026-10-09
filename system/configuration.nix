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

  # --- Shared flake checkout ---
  # This flake lives in /srv/nixos-config, owned by "user", who commits and
  # runs `nrs`. pentest gets write access to users/pentest only (ACL, incl.
  # default entries so files either account creates stay writable by both),
  # which is enough to edit its own home and `hms` it, but not the system
  # config root builds. safe.directory lets pentest run git in the checkout.
  #
  # Migrating from the old shared-wheel layout, run once as "user" before nrs:
  #   sudo setfacl -R -b /srv/nixos-config
  #   sudo chown -R user:users /srv/nixos-config
  #   sudo chmod -R g-ws /srv/nixos-config
  systemd.tmpfiles.rules = [
    "d /srv/nixos-config 0755 user users - -"
    "A+ /srv/nixos-config/users/pentest - - - - user:pentest:rwX,default:user:pentest:rwX,default:user:user:rwX,mask::rwx,default:mask::rwx"
  ];
  programs.git = {
    enable = true;
    config.safe.directory = "/srv/nixos-config";
  };

  # Hooks direnv into zsh and ships nix-direnv (fast, cached `use flake`).
  programs.direnv.enable = true;

  # --- Login manager (ly) ---
  # TUI display manager with built-in background animations (none / doom /
  # matrix). `animation` sets the default; the key shown at the login screen
  # switches it. Sessions come from the Wayland session files that
  # programs.sway and programs.hyprland ship.
  services.displayManager.ly = {
    enable = true;
    settings = {
      animation = "matrix";
    };
  };

  # --- Window managers ---
  # Sway is the one to use here: the VM has no 3D acceleration, and sway can
  # draw with pixman, a plain 2D CPU renderer. Hyprland can only draw through
  # OpenGL, which without a GPU Mesa emulates on the CPU (llvmpipe), so every
  # redraw costs far more. Hyprland stays installed as a second session; pick
  # either in ly's session field (it remembers the last one).
  programs.sway = {
    enable = true;
    wrapperFeatures.gtk = true;
    # Only what the configs use; the default list (wmenu, swaylock, grim,
    # ...) isn't needed.
    extraPackages = [ ];
    extraSessionCommands = ''
      export WLR_RENDERER=pixman
      export QT_QPA_PLATFORM="wayland;xcb"
      export SDL_VIDEODRIVER=wayland
      export ELECTRON_OZONE_PLATFORM_HINT=auto
      # Java GUIs (Burp Suite) draw blank grey windows under sway otherwise.
      export _JAVA_AWT_WM_NONREPARENTING=1
    '';
  };
  programs.hyprland.enable = true;

  # --- Audio (PipeWire) ---
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    pulse.enable = true;
  };

  # --- CLI / packages ---
  # foot, kakoune and waybar are user-level, managed via home-manager (users/<name>/home.nix)
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
