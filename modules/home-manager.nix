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
  mergedConfig = lib.recursiveUpdate defaultConfig cfg.settings;
  configFile = settingsFormat.generate "opencode-config.json" mergedConfig;
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
            description = "OpenCode with context7 MCP pre-configured";
            mainProgram = "opencode-nix";
          };
        }
        ''
          mkdir -p $out/bin
          makeWrapper ${lib.getExe pkgs.opencode} $out/bin/opencode-nix \
            --set OPENCODE_CONFIG "${configFile}"
        ''
      )
    ];
  };
}
