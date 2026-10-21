{
  description = "NixOS configuration for Raspberry Pi 3B (rpi)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

    colmena.url = "github:zhaofengli/colmena";
    colmena.inputs.nixpkgs.follows = "nixpkgs";

    sops-nix.url = "github:Mic92/sops-nix";

    fcksws.url = "github:leonpwd/fcksws";
    fcksws.inputs.nixpkgs.follows = "nixpkgs";

    notifynotes.url = "github:leonpwd/NotifyNotes";
    notifynotes.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, colmena, sops-nix, fcksws, notifynotes, ... }@inputs: {
    nixosConfigurations.rpi = nixpkgs.lib.nixosSystem {
      system = "aarch64-linux";
      specialArgs = { inherit inputs; };
      modules = [
        sops-nix.nixosModules.sops
        fcksws.nixosModules.default
        notifynotes.nixosModules.default
        ./configuration.nix
      ];
    };

    colmenaHive = colmena.lib.makeHive self.outputs.colmena;

    colmena = {
      meta = {
        nixpkgs = import nixpkgs {
          system = "aarch64-linux";
        };
        specialArgs = { inherit inputs; };
      };

      rpi = { name, nodes, ... }: {
        deployment = {
          targetHost    = "rpi";
          buildOnTarget = true;
        };

        imports = [
          sops-nix.nixosModules.sops
          fcksws.nixosModules.default
          notifynotes.nixosModules.default
          ./configuration.nix
        ];
      };
    };
  };
}
