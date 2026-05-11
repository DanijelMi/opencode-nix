# Builds the opencode-nix wrapped binary.
# Shared by flake.nix (packages output) and modules/home-manager.nix.
{
  pkgs,
  lib,
  binaryName ? "opencode-nix",
  configDirName ? "opencode-nix",
  enabledMcps ? [
    "context7"
    "grafana"
    "gitlab"
    "atlassian"
  ],
}:
let
  # All available MCP server definitions.
  allMcps = {
    context7 = {
      type = "remote";
      url = "https://mcp.context7.com/mcp";
    };
    nixos = {
      type = "local";
      command = [ "mcp-nixos" ];
    };
    grafana = {
      type = "local";
      command = [ "mcp-grafana" ];
    };
    gitlab = {
      type = "local";
      command = [
        "npx"
        "-y"
        "@zereight/mcp-gitlab"
      ];
      environment = {
        GITLAB_PERSONAL_ACCESS_TOKEN = "{env:GITLAB_PERSONAL_ACCESS_TOKEN}";
        GITLAB_API_URL = "{env:GITLAB_API_URL}";
      };
    };
    atlassian = {
      type = "local";
      command = [
        "uvx"
        "mcp-atlassian"
      ];
      environment = {
        JIRA_URL = "{env:JIRA_URL}";
        JIRA_USERNAME = "{env:JIRA_USERNAME}";
        JIRA_API_TOKEN = "{env:JIRA_API_TOKEN}";
        CONFLUENCE_URL = "{env:CONFLUENCE_URL}";
        CONFLUENCE_USERNAME = "{env:CONFLUENCE_USERNAME}";
        CONFLUENCE_API_TOKEN = "{env:CONFLUENCE_API_TOKEN}";
      };
    };
  };

  filteredMcps = lib.filterAttrs (name: _: builtins.elem name enabledMcps) allMcps;

  # Binaries that need to be on PATH for bundled local MCPs.
  mcpBinPaths =
    lib.optional (builtins.elem "nixos" enabledMcps) pkgs.mcp-nixos
    ++ lib.optional (builtins.elem "grafana" enabledMcps) pkgs.mcp-grafana;

  # Compact MCP JSON — jq pretty-prints it during configDir assembly.
  mcpJson = pkgs.writeText "mcps.json" (builtins.toJSON filteredMcps);

  configDir = pkgs.runCommand "opencode-config-dir" {
    nativeBuildInputs = [ pkgs.jq ];
  } ''
    mkdir -p $out

    # Write the static header (schema, models, plugins) including the JSONC
    # comment. Single-quoted heredoc delimiter prevents shell expansion of
    # "$schema" and similar tokens.
    cat > $out/config.jsonc <<'HEADER'
{
  "$schema": "https://opencode.ai/config.json",
  "small_model": "anthropic/claude-haiku-4-5",
  "agent": {
    "explore": {
      "model": "anthropic/claude-haiku-4-5"
    },
    "build": {
      "prompt": "When you need a scratch directory for temporary files or intermediate build artifacts, use /tmp/opencode/ — it is pre-approved and does not require a permission prompt."
    }
  },
  "plugin": [
    "@mohak34/opencode-notifier@latest",
    // "opencode-claude-auth@latest",
    "@tarquinen/opencode-dcp@latest",
    "opencode-anthropic-oauth@latest"
  ],
HEADER

    # Append "mcp": followed by the pretty-printed, properly-indented MCP JSON.
    # jq formats the object; sed adds 2-space indent to every line after the
    # opening "{" so the content nests correctly inside the outer object.
    printf '  "mcp": ' >> $out/config.jsonc
    ${pkgs.jq}/bin/jq '.' ${mcpJson} \
      | sed '2,$ s/^/  /' >> $out/config.jsonc

    # Append the outer closing brace.
    printf '}\n' >> $out/config.jsonc

    cp ${../config/dcp.json} $out/dcp.json
    cp -r ${../config/skills} $out/skills
  '';

  # Shell preamble that syncs static config files from the Nix store into a
  # writable directory (~/.config/opencode-nix/) before exec'ing opencode.
  #
  # Strategy:
  #   - Use a sentinel file to track which store path was last synced.
  #   - Only copy when the sentinel doesn't match (i.e. first launch, or after
  #     a flake update that produced a new configDir store path).
  #   - Copy only the static files (config.jsonc, dcp.json, skills/) so that
  #     opencode's own runtime state (node_modules, package.json, bun.lock,
  #     .gitignore, etc.) is never disturbed between launches.
  #   - OPENCODE_CONFIG / OPENCODE_CONFIG_DIR still honour any value already
  #     set in the environment, so `just dev` overrides continue to work.
  preamble = ''
    _oc_nix_store_config="${configDir}"
    _oc_config_dir="''${XDG_CONFIG_HOME:-$HOME/.config}/''${OPENCODE_NIX_DIR_NAME:-${configDirName}}"
    _oc_sentinel="$_oc_config_dir/.nix-store-path"

    if [ "$(cat "$_oc_sentinel" 2>/dev/null)" != "$_oc_nix_store_config" ]; then
      mkdir -p "$_oc_config_dir/skills"
      cp -f "$_oc_nix_store_config/config.jsonc" "$_oc_config_dir/config.jsonc"
      cp -f "$_oc_nix_store_config/dcp.json"    "$_oc_config_dir/dcp.json"
      cp -rf "$_oc_nix_store_config/skills/."   "$_oc_config_dir/skills/"
      chmod -R u+w "$_oc_config_dir/config.jsonc" "$_oc_config_dir/dcp.json" "$_oc_config_dir/skills"
      printf '%s' "$_oc_nix_store_config" > "$_oc_sentinel"
    fi

    export OPENCODE_CONFIG="''${OPENCODE_CONFIG:-$_oc_config_dir/config.jsonc}"
    export OPENCODE_CONFIG_DIR="''${OPENCODE_CONFIG_DIR:-$_oc_config_dir}"
  '';
in
pkgs.runCommand "${binaryName}-${pkgs.opencode.version or "unstable"}"
  {
    nativeBuildInputs = [ pkgs.makeWrapper ];
    meta = lib.recursiveUpdate (pkgs.opencode.meta or { }) {
      description = "OpenCode with context7 MCP, nixos MCP, and DCP pre-configured";
      mainProgram = binaryName;
    };
  }
  ''
    mkdir -p $out/bin
    makeWrapper ${lib.getExe pkgs.opencode} $out/bin/${binaryName} \
      --run ${lib.escapeShellArg preamble} \
      ${lib.optionalString (mcpBinPaths != [ ]) "--prefix PATH : ${lib.makeBinPath mcpBinPaths}"}
  ''
