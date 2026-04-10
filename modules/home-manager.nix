{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.programs.opencode-nix;
  settingsFormat = pkgs.formats.json { };
  defaultConfig = builtins.fromJSON (builtins.readFile ../configs/default.json);
  defaultDcpConfig = builtins.fromJSON (builtins.readFile ../configs/dcp.json);
  mergedConfig = lib.recursiveUpdate defaultConfig cfg.settings;
  configFile = settingsFormat.generate "opencode-config.json" mergedConfig;
  dcpConfigFile = settingsFormat.generate "dcp.json" defaultDcpConfig;
  configDir = pkgs.runCommand "opencode-config-dir" { } ''
    mkdir -p $out
    cp ${configFile} $out/config.json
    cp ${dcpConfigFile} $out/dcp.json
  '';
in
{
  options.programs.opencode-nix = {
    enable = lib.mkEnableOption "opencode-nix with context7 MCP pre-configured";

    settings = lib.mkOption {
      type = settingsFormat.type;
      default = { };
      example = {
        mcp = {
          my-custom-mcp = {
            type = "remote";
            url = "https://my-mcp.example.com/mcp";
          };
        };
      };
      description = ''
        Additional opencode configuration settings to merge with the defaults.
        These will be deep-merged with the base context7 MCP configuration.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [
      (pkgs.runCommand "opencode-nix-${pkgs.opencode.version or "unstable"}"
        {
          nativeBuildInputs = [ pkgs.makeWrapper ];
          meta = lib.recursiveUpdate (pkgs.opencode.meta or { }) {
            description = "OpenCode with context7 MCP and DCP pre-configured";
            mainProgram = "opencode-nix";
          };
        }
        ''
                    mkdir -p $out/bin
          makeWrapper ${lib.getExe pkgs.opencode} $out/bin/opencode-nix \
                       --set OPENCODE_CONFIG "${configDir}/config.json" \
                       --set OPENCODE_CONFIG_DIR "${configDir}" \
                       --prefix PATH : ${lib.makeBinPath [ pkgs.mcp-nixos ]}
        ''
      )
    ];
  };
}
