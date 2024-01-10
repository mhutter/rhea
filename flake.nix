{
  description = "Deployment for my server(s)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    deploy-rs = {
      url = "github:serokell/deploy-rs";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, deploy-rs }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
    in
    {
      # Ensure necessary tooling is available
      devShells."${system}".default = pkgs.mkShell {
        packages = [ pkgs.deploy-rs ];
      };

      # NixOS configurations
      nixosConfigurations.rhea = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux ";
        modules = [ ./configuration.nix ];
      };

      # Deployment specifications
      deploy.nodes.rhea = {
        hostname = "rhea";
        sshUser = "root";
        remoteBuild = true;
        # See: https://github.com/serokell/deploy-rs/issues/226
        sshOpts = [ "-oControlMaster=no" "-oControlPath=/dev/null" ];

        profiles.system = {
          path = deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations.rhea;
        };
      };

      # FIXME: reenable; will pull a gig of dependencies ...
      # checks = builtins.mapAttrs (system: deployLib: deployLib.deployChecks self.deploy) deploy-rs.lib;
    };
}

