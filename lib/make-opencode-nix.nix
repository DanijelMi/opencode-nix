# Builds the opencode-nix wrapped binary.
# Shared by flake.nix (packages output) and modules/home-manager.nix.
{
  pkgs,
  lib,
  configDir,
  binaryName ? "opencode-nix",
}:
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
      --set-default OPENCODE_CONFIG "${configDir}/config.json" \
      --set-default OPENCODE_CONFIG_DIR "${configDir}" \
      --prefix PATH : ${lib.makeBinPath [ pkgs.mcp-nixos ]}
  ''
