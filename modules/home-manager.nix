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
        These will be deep-merged with the base configuration.
      '';
    };

    dcpSettings = lib.mkOption {
      type = settingsFormat.type;
      default = { };
      example = {
        compress = {
          maxContextLimit = 200000;
        };
      };
      description = ''
        Additional DCP configuration settings to merge with the defaults.
        These will be deep-merged with the base DCP configuration from configs/dcp.json.
        See https://github.com/Opencode-DCP/opencode-dynamic-context-pruning#configuration
        for all available options.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ (makeOpencodeNix { inherit pkgs lib configDir; }) ];
  };
}
