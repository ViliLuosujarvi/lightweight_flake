{
  description = "NixOS VM config: Hyprland + foot + kakoune, with separate dev and pentest accounts";

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

      # Standalone home-manager, one config per account:
      #   home-manager switch --flake .#user
      #   home-manager switch --flake .#pentest
      mkHome = name: home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        modules = [ ./users/${name}/home.nix ];
      };
    in
    {
      homeConfigurations = {
        user = mkHome "user";
        pentest = mkHome "pentest";
      };

      nixosConfigurations.nixos-vm = nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          ./system/configuration.nix
          ./system/aliases.nix
          ./system/pentest.nix
        ];
      };
    };
}
