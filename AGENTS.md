# AGENTS.md

This document provides guidelines for AI coding agents working in the opencode-nix repository.

## Project Overview

This is a Nix flake repository that packages [OpenCode](https://opencode.ai) with [context7 MCP](https://github.com/upstash/context7) pre-configured. It provides:
- A Nix package wrapper for OpenCode
- Home Manager module for declarative configuration
- Default JSON configuration with context7 MCP

## Build, Lint, and Test Commands

### Building

Build the default package:
```bash
nix build
```

Build and run directly:
```bash
nix run
```

Enter development shell:
```bash
nix develop
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

After making changes to `configs/default.json` or other configuration files, test the wrapped binary:

Build and run directly (fastest):
```bash
nix run
```

Or build then run separately:
```bash
nix build && ./result/bin/opencode-nix
```

Verify the generated configuration file:
```bash
nix build && cat $(nix eval --raw .#packages.x86_64-linux.default.env.OPENCODE_CONFIG)
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
- Use `builtins.fromJSON` for parsing JSON files

#### Naming Conventions
- Use kebab-case for option names: `programs.opencode-nix`
- Use camelCase for local variable names: `defaultConfig`, `mergedConfig`
- Prefix configuration variables with `cfg`: `cfg = config.programs.opencode-nix`
- Use descriptive names: `settingsFormat`, `configFile`

### JSON Configuration Style

- Always include `$schema` for validation
- Use 2-space indentation
- Keep configuration minimal and focused
- Use descriptive key names for MCP servers

Example:
```json
{
  "$schema": "https://opencode.ai/config.json",
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
│   └── default.json    # Default OpenCode configuration
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
1. Edit `configs/default.json`
2. Validate JSON syntax: `nix-instantiate --parse configs/default.json`
3. Rebuild to verify: `nix build`
4. Update README.md if adding new features

### Supporting a New Platform
1. Add system to `supportedSystems` list in `flake.nix`
2. Verify package availability in nixpkgs for that platform
3. Test with: `nix build .#packages.<system>.default`

## Important Notes

- This repository has no automated tests - rely on `nix flake check` and manual testing
- Always test Home Manager module changes with actual Home Manager configuration
- Keep the flake.nix and home-manager.nix patterns consistent
- Changes to default.json affect all users - maintain backward compatibility
- Document breaking changes clearly in commit messages and README updates
