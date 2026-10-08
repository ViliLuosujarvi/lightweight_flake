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
    in
    {
      nixosConfigurations.nixos-vm = nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          ./system/configuration.nix
          ./system/aliases.nix
          ./system/pentest.nix

          # Applies both accounts' home-manager configs as part of the system
          # build, so the pentest account gets its packages and dotfiles without
          # needing its own copy of this flake or a manual home-manager bootstrap.
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            # Existing unmanaged files are moved aside instead of aborting.
            home-manager.backupFileExtension = "bak";
            home-manager.users.user = import ./users/user/home.nix;
            home-manager.users.pentest = import ./users/pentest/home.nix;
          }
        ];
      };
    };
}
