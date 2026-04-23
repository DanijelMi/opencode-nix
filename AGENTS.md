# AGENTS.md

This document provides guidelines for AI coding agents working in the opencode-nix repository.

## Project Overview

This is a Nix flake repository that packages [OpenCode](https://opencode.ai) with [context7 MCP](https://github.com/upstash/context7) pre-configured. It provides:
- A Nix package wrapper for OpenCode
- Home Manager module for declarative configuration
- Default JSONC configuration with context7 MCP

## Build, Lint, and Test Commands

This project uses a Justfile. Run `just` to see all available commands.

### Building

Build the default package:
```bash
just build
```

Build and run in a specific directory:
```bash
just run /path/to/project
```

### Development

Run opencode-nix with local configs for fast iteration (skips nix build, uses local config files directly):
```bash
just dev /path/to/project
```

### Linting and Formatting

Format all Nix files:
```bash
nix fmt
```

Check formatting without applying changes:
```bash
nix fmt -- --check
```

Run static analysis with statix (if available):
```bash
nix run nixpkgs#statix -- check .
```

Run deadnix to find unused code:
```bash
nix run nixpkgs#deadnix
```

### Testing/Validation

Check flake validity:
```bash
nix flake check
```

Evaluate the flake without building:
```bash
nix eval .#packages.x86_64-linux.default
```

Test the Home Manager module (example):
```bash
nix eval .#homeManagerModules.default
```

#### Testing the opencode-nix Binary

After making changes to `configs/default.jsonc` or other configuration files, test the wrapped binary:

Build and run with local configs (fastest iteration):
```bash
just dev
```

Or build then run the wrapped binary:
```bash
just build && just run
```

Verify the generated configuration file:
```bash
just build && cat $(nix eval --raw .#packages.x86_64-linux.default.env.OPENCODE_CONFIG)
```

### Updating Dependencies

Update the flake lock file:
```bash
just update
```

## Code Style Guidelines

### Nix Code Style

#### Formatting
- Use 2-space indentation
- Maximum line length of 100 characters
- Place `in` keyword on its own line after `let` blocks
- Use trailing commas in attribute sets and lists (multi-line)

#### Function Definitions
- Place function arguments on separate lines when more than 2 arguments
- Use standard argument pattern: `{ arg1, arg2, ... }:`
- Separate inputs from other arguments with a blank line

Example:
```nix
{
  input1,
  input2,
  ...
}:

let
  # bindings
in
{
  # body
}
```

#### Attribute Sets
- Use `lib.recursiveUpdate` for deep merging configurations
- Use `lib.mkEnableOption` for boolean enable options
- Use `lib.mkOption` with proper type declarations
- Use `lib.mkIf` for conditional configuration

#### Imports and Paths
- Use relative paths for internal files: `./modules/home-manager.nix`
- Use `builtins.readFile` for reading file contents
- Use `builtins.fromJSON` for parsing JSON/JSONC files (strip comments with `strip-jsonc.nix` first for JSONC)

#### Naming Conventions
- Use kebab-case for option names: `programs.opencode-nix`
- Use camelCase for local variable names: `defaultConfig`, `mergedConfig`
- Prefix configuration variables with `cfg`: `cfg = config.programs.opencode-nix`
- Use descriptive names: `settingsFormat`, `configFile`

### JSONC Configuration Style

- Always include `$schema` for validation
- Use 2-space indentation
- Keep configuration minimal and focused
- Use descriptive key names for MCP servers
- `//` line comments are supported (stripped via `lib/strip-jsonc.nix`)

Example:
```jsonc
{
  "$schema": "https://opencode.ai/config.json",
  // MCP servers
  "mcp": {
    "server-name": {
      "type": "remote",
      "url": "https://example.com/mcp"
    }
  }
}
```

## Project Structure

```
.
├── flake.nix           # Main flake definition
├── flake.lock          # Locked dependencies
├── configs/
│   └── default.jsonc   # Default OpenCode configuration (JSONC with comments)
├── lib/
│   ├── make-opencode-nix.nix # Shared package wrapping logic
│   └── strip-jsonc.nix # JSONC comment stripping helper
├── modules/
│   └── home-manager.nix # Home Manager module
└── README.md           # User documentation
```

## Architecture Patterns

### Flake Outputs
- Always define `packages`, `apps`, `devShells`, `homeManagerModules`, and `overlays`
- Use `forEachSystem` to support multiple platforms
- Support: x86_64-linux, aarch64-linux, x86_64-darwin, aarch64-darwin

### Package Wrapping
- Use `pkgs.runCommand` to create wrapped packages
- Use `makeWrapper` for wrapping binaries
- Set environment variables with `--set` flag
- Include proper metadata with `meta` attribute

### Home Manager Modules
- Place options under `programs.<name>` namespace
- Provide sensible defaults with `default = { }`
- Include example configurations in option definitions
- Use `lib.mkIf cfg.enable` for conditional activation
- Wrap `pkgs.opencode` directly (no overlay needed for users)

### Configuration Merging
- Start with default config from JSON file
- Use `lib.recursiveUpdate` to merge user settings
- Generate final config with `pkgs.formats.json`
- Pass config file via environment variable

## Error Handling

### Nix-specific Practices
- Use `lib.optionalAttrs` for conditional attributes
- Use `lib.optionals` for conditional lists
- Provide fallback values with `or`: `pkgs.opencode.version or "unstable"`
- Use `lib.mkIf` instead of imperative conditionals

### Validation
- Always include `meta.mainProgram` for wrapped binaries
- Include `meta.description` for discoverability
- Preserve upstream metadata when wrapping packages

## Common Tasks

### Adding a New Configuration Option
1. Add option definition in `modules/home-manager.nix`
2. Document with `description` and `example`
3. Ensure it merges properly with `lib.recursiveUpdate`
4. Update README.md with usage example

### Updating Default Configuration
1. Edit `configs/default.jsonc`
2. Validate by building: `just build`
3. Test with `just dev`
4. Update README.md if adding new features

### Supporting a New Platform
1. Add system to `supportedSystems` list in `flake.nix`
2. Verify package availability in nixpkgs for that platform
3. Test with: `nix build .#packages.<system>.default`

## Important Notes

- This repository has no automated tests - rely on `nix flake check` and manual testing
- Always test Home Manager module changes with actual Home Manager configuration
- Keep the flake.nix and home-manager.nix patterns consistent
- Changes to default.jsonc affect all users - maintain backward compatibility
- Document breaking changes clearly in commit messages and README updates
