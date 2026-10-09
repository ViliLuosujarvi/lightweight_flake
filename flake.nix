{
  description = "NixOS VM config: sway + foot + kakoune, with separate dev and pentest accounts";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, ... }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };

      # Standalone home-manager: each account applies its own home with
      # `hms` (home-manager switch, no sudo), so pentest can manage its own
      # packages and dotfiles without being in wheel.
      homeFor = name: home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        modules = [ ./users/${name}/home.nix ];
      };
    in
    {
      # Applied by `nrs` as root. This must never import anything under
      # users/pentest: pentest can write there, and root evaluating it would
      # hand pentest root.
      nixosConfigurations.nixos-vm = nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          ./system/configuration.nix
          ./system/aliases.nix
          ./system/pentest.nix

          # The home-manager CLI from the same pinned input the homes are
          # built with, so `hms` works on a fresh install.
          { environment.systemPackages = [ home-manager.packages.${system}.home-manager ]; }
        ];
      };

      homeConfigurations = {
        user = homeFor "user";
        pentest = homeFor "pentest";
      };
    };
}
