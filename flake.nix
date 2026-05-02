{
  description = "OpenCode with context7 MCP, nixos MCP, and DCP pre-configured";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      home-manager,
      ...
    }:
    let
      supportedSystems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];
      lib = nixpkgs.lib;
      forEachSystem = lib.genAttrs supportedSystems;
      makeOpencodeNix = import ./lib/make-opencode-nix.nix;
    in
    {
      packages = forEachSystem (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          configDir = pkgs.runCommand "opencode-config-dir" { } ''
            mkdir -p $out
            cp ${./config/config.jsonc} $out/config.jsonc
            cp ${./config/dcp.json} $out/dcp.json
            cp -r ${./config/skills} $out/skills
          '';
        in
        {
          default = self.packages.${system}.opencode-nix;
          opencode-nix = makeOpencodeNix {
            inherit pkgs lib configDir;
            binaryName = "opencode-nix";
          };
          opencode = makeOpencodeNix {
            inherit pkgs lib configDir;
            binaryName = "opencode";
          };
        }
      );

      apps = forEachSystem (system: {
        default = {
          type = "app";
          program = lib.getExe self.packages.${system}.default;
        };
      });

      formatter = forEachSystem (system: nixpkgs.legacyPackages.${system}.nixfmt-tree);

      devShells = forEachSystem (system: {
        default = nixpkgs.legacyPackages.${system}.mkShell {
          packages = [ self.packages.${system}.default ];
        };
      });

      homeManagerModules.default = import ./modules/home-manager.nix;

      overlays.default = final: _prev: {
        opencode-nix = self.packages.${final.stdenv.hostPlatform.system}.default;
      };
    };
}
