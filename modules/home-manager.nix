{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.programs.opencode-nix;
  makeOpencodeNix = import ../lib/make-opencode-nix.nix;
  configDir = pkgs.runCommand "opencode-config-dir" { } ''
    mkdir -p $out
    cp ${../config/config.jsonc} $out/config.jsonc
    cp ${../config/dcp.json} $out/dcp.json
    cp -r ${../config/skills} $out/skills
  '';
in
{
  options.programs.opencode-nix = {
    enable = lib.mkEnableOption "opencode with context7 MCP, nixos MCP, and DCP pre-configured";

    configDirName = lib.mkOption {
      type = lib.types.str;
      default = "opencode-nix";
      example = "opencode-test";
      description = ''
        Name of the writable config directory created under $XDG_CONFIG_HOME
        (default: ~/.config/opencode-nix). Can also be overridden at runtime
        via the OPENCODE_NIX_DIR_NAME environment variable.
      '';
    };

    binaryName = lib.mkOption {
      type = lib.types.enum [
        "opencode-nix"
        "opencode"
      ];
      default = "opencode-nix";
      example = "opencode";
      description = ''
        The name of the installed binary.
        Use "opencode-nix" (default) to avoid conflicts with pkgs.opencode if both are installed.
        Use "opencode" to match the upstream binary name.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [
      (makeOpencodeNix {
        inherit pkgs lib configDir;
        binaryName = cfg.binaryName;
        configDirName = cfg.configDirName;
      })
    ];
  };
}
