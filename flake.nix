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
      defaultConfig = builtins.fromJSON (builtins.readFile ./configs/default.json);
      defaultDcpConfig = builtins.fromJSON (builtins.readFile ./configs/dcp.json);
    in
    {
      packages = forEachSystem (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          settingsFormat = pkgs.formats.json { };
          configFile = settingsFormat.generate "opencode-config.json" defaultConfig;
          dcpConfigFile = settingsFormat.generate "dcp.json" defaultDcpConfig;
          configDir = pkgs.runCommand "opencode-config-dir" { } ''
            mkdir -p $out
            cp ${configFile} $out/config.json
            cp ${dcpConfigFile} $out/dcp.json
          '';
        in
        {
          default = self.packages.${system}.opencode-nix;
          opencode-nix = makeOpencodeNix { inherit pkgs lib configDir; binaryName = "opencode-nix"; };
          opencode = makeOpencodeNix { inherit pkgs lib configDir; binaryName = "opencode"; };
        }
      );

      apps = forEachSystem (system: {
        default = {
          type = "app";
          program = lib.getExe self.packages.${system}.default;
        };
      });

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
