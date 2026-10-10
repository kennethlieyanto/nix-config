{
  description = "kennethl's personal nix configuration";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-26.05";
    nixpkgs-unstable.url = "nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    herdr = {
      url = "github:herdrdev/herdr/v0.9.3";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    hunk = {
      url = "github:modem-dev/hunk";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    tw-gnome = {
      url = "path:/home/kennethl/projects/personal/tw-gnome";
      flake = false;
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      nixpkgs-unstable,
      home-manager,
      herdr,
      hunk,
      tw-gnome,
      ...
    }:
    {
      nixosConfigurations.kennethl = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./configuration.nix
          home-manager.nixosModules.home-manager
          {
            nixpkgs.overlays = [
              (
                final: prev:
                let
                  unstable = import nixpkgs-unstable {
                    inherit (prev.stdenv.hostPlatform) system;
                    config.allowUnfree = true;
                  };
                in
                {
                  esphome-device-builder = unstable.esphome-device-builder;
                  opencode = unstable.opencode;
                  handy = unstable.handy;
                }
              )
            ];
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              users.kennethl = import ./home.nix;
              backupFileExtension = "backup";
              extraSpecialArgs = { inherit herdr hunk tw-gnome; };
            };
          }
        ];
      };
    };
}
