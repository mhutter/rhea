{
  description = "Deployment for my server(s)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    systems.url = "github:nix-systems/x86_64-linux";
    utils = {
      url = "github:numtide/flake-utils";
      inputs.systems.follows = "systems";
    };

    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.systems.follows = "systems";
      # disable unused deps
      inputs.darwin.follows = "";
      inputs.home-manager.follows = "";
    };

    deploy-rs = {
      url = "github:serokell/deploy-rs";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.utils.follows = "utils";
    };
  };

  outputs = { self, nixpkgs, agenix, deploy-rs, ... }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
      # Allow us to make use of nixpkgs' binary cache for deploy-rs
      deployPkgs = import nixpkgs {
        inherit system;
        overlays = [
          deploy-rs.overlay
          (self: super: { deploy-rs = { inherit (pkgs) deploy-rs; lib = super.deploy-rs.lib; }; })
        ];
      };
    in
    {
      # Ensure necessary tooling is available
      devShells."${system}".default = pkgs.mkShell {
        packages = [
          agenix.packages."${system}".default
          pkgs.deploy-rs
        ];
      };

      # NixOS configurations
      nixosConfigurations.rhea = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux ";
        modules = [
          ./configuration.nix
          agenix.nixosModules.default
        ];
      };

      # Deployment specifications
      deploy.nodes.rhea = {
        hostname = "rhea";
        sshUser = "root";
        remoteBuild = true;
        # See: https://github.com/serokell/deploy-rs/issues/226
        sshOpts = [ "-oControlMaster=no" ];

        profiles.system = {
          path = deployPkgs.deploy-rs.lib.activate.nixos self.nixosConfigurations.rhea;
        };
      };

      # This is highly advised, and will prevent many possible mistakes
      checks = builtins.mapAttrs
        (system: deployLib: deployLib.deployChecks self.deploy)
        deploy-rs.lib;
    };
}

