{
  description = "NixOS configuration for Raspberry Pi 3B (rpi)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

    colmena.url = "github:zhaofengli/colmena";
    colmena.inputs.nixpkgs.follows = "nixpkgs";

    # sops-install-secrets is a Go program that is not in the binary cache: on a Pi 3B (1 GB RAM) it
    # must never be recompiled by a nixpkgs update. It is built from pinned revisions of sops-nix and
    # nixpkgs (the ones deployed when this was set up) and used through `sops.package`.
    # To update it, change both revisions together.
    nixpkgs-sops.url = "github:NixOS/nixpkgs/cd4ea8d57de16f4810bc5f14207bac45fbf19f67";
    sops-nix.url = "github:Mic92/sops-nix/44931708c62937c2b1bf7953902989fa5bb9ee1b";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs-sops";

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
          targetUser    = "leon";
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
