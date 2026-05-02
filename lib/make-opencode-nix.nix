# Builds the opencode-nix wrapped binary.
# Shared by flake.nix (packages output) and modules/home-manager.nix.
{
  pkgs,
  lib,
  configDir,
  binaryName ? "opencode-nix",
}:
let
  # Shell preamble that syncs static config files from the Nix store into a
  # writable directory (~/.config/opencode-nix/) before exec'ing opencode.
  #
  # Strategy:
  #   - Use a sentinel file to track which store path was last synced.
  #   - Only copy when the sentinel doesn't match (i.e. first launch, or after
  #     a flake update that produced a new configDir store path).
  #   - Copy only the static files (config.json, dcp.json, skills/) so that
  #     opencode's own runtime state (node_modules, package.json, bun.lock,
  #     .gitignore, etc.) is never disturbed between launches.
  #   - OPENCODE_CONFIG / OPENCODE_CONFIG_DIR still honour any value already
  #     set in the environment, so `just dev` overrides continue to work.
  preamble = ''
    _oc_nix_store_config="${configDir}"
    _oc_config_dir="''${XDG_CONFIG_HOME:-$HOME/.config}/opencode-nix"
    _oc_sentinel="$_oc_config_dir/.nix-store-path"

    if [ "$(cat "$_oc_sentinel" 2>/dev/null)" != "$_oc_nix_store_config" ]; then
      mkdir -p "$_oc_config_dir/skills"
      cp -f "$_oc_nix_store_config/config.json" "$_oc_config_dir/config.json"
      cp -f "$_oc_nix_store_config/dcp.json"    "$_oc_config_dir/dcp.json"
      cp -rf "$_oc_nix_store_config/skills/."   "$_oc_config_dir/skills/"
      chmod -R u+w "$_oc_config_dir/config.json" "$_oc_config_dir/dcp.json" "$_oc_config_dir/skills"
      printf '%s' "$_oc_nix_store_config" > "$_oc_sentinel"
    fi

    export OPENCODE_CONFIG="''${OPENCODE_CONFIG:-$_oc_config_dir/config.json}"
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
      --prefix PATH : ${lib.makeBinPath [ pkgs.mcp-nixos ]}
  ''
