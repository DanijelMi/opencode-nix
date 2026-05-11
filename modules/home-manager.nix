{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.programs.opencode-nix;
  makeOpencodeNix = import ../lib/make-opencode-nix.nix;
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

    enabledMcps = lib.mkOption {
      type = lib.types.listOf (lib.types.enum [
        "context7"
        "nixos"
        "grafana"
        "gitlab"
        "atlassian"
      ]);
      default = [
        "context7"
        "grafana"
        "gitlab"
        "atlassian"
      ];
      example = [
        "context7"
        "nixos"
      ];
      description = ''
        List of MCP servers to enable. Defaults to all available MCPs except
        "nixos" (which requires a running NixOS or nixpkgs evaluation context
        and is expensive to start).

        Available MCPs:
        - "context7"  — remote MCP for library documentation lookup
        - "nixos"     — local MCP for NixOS/nixpkgs queries (bundled binary)
        - "grafana"   — local MCP for Grafana dashboards (bundled binary)
        - "gitlab"    — on-demand MCP for GitLab (via npx)
        - "atlassian" — on-demand MCP for Jira/Confluence (via uvx)
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [
      (makeOpencodeNix {
        inherit pkgs lib;
        binaryName = cfg.binaryName;
        configDirName = cfg.configDirName;
        enabledMcps = cfg.enabledMcps;
      })
    ];
  };
}
