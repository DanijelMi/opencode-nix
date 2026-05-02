# opencode-nix

A Nix flake for [OpenCode](https://opencode.ai) with [context7 MCP](https://github.com/upstash/context7) and [Dynamic Context Pruning](https://github.com/Opencode-DCP/opencode-dynamic-context-pruning) pre-configured.

## Usage

### Run directly

```bash
nix run github:DanijelMi/opencode-nix
```

#### Customising the config directory name

By default, opencode-nix stores its writable config at `~/.config/opencode-nix/`. You can
override the directory name at runtime with `OPENCODE_NIX_DIR_NAME`:

```bash
OPENCODE_NIX_DIR_NAME=opencode-test nix run github:DanijelMi/opencode-nix
```

Set it in your shell profile to make it permanent:

```bash
export OPENCODE_NIX_DIR_NAME=opencode-test
```

### Dev shell

```bash
nix develop github:DanijelMi/opencode-nix
```

### Home Manager

> **Note:** this flake requires `nixpkgs-unstable`. If your system uses a stable channel, pin
> `nixpkgs` to unstable in your flake inputs as shown below.

**Step 1.** Add the flake input:

```nix
inputs = {
  nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  home-manager = {
    url = "github:nix-community/home-manager";
    inputs.nixpkgs.follows = "nixpkgs";
  };
  opencode-nix = {
    url = "github:DanijelMi/opencode-nix";
    inputs.nixpkgs.follows = "nixpkgs";
  };
};
```

**Step 2.** Pass the module to Home Manager in your flake outputs.

Standalone Home Manager:

```nix
home-manager.lib.homeManagerConfiguration {
  pkgs = nixpkgs.legacyPackages.x86_64-linux;
  modules = [
    opencode-nix.homeManagerModules.default
    ./home.nix
  ];
};
```

NixOS with Home Manager as a module:

```nix
home-manager.sharedModules = [ inputs.opencode-nix.homeManagerModules.default ];
```

**Step 3.** Enable in `home.nix`:

```nix
programs.opencode-nix.enable = true;
```

This installs the binary as **`opencode-nix`** — run it with:

```bash
opencode-nix
```

#### Renaming the binary to `opencode`

If you want to type `opencode` instead, and you don't have `pkgs.opencode` installed separately:

```nix
programs.opencode-nix = {
  enable = true;
  binaryName = "opencode";
};
```

> **Note:** `binaryName = "opencode"` will conflict with `pkgs.opencode` if both are installed.

#### Customising the config directory name

By default, opencode-nix stores its writable config at `~/.config/opencode-nix/`. You can
change the directory name:

```nix
programs.opencode-nix = {
  enable = true;
  configDirName = "opencode-test";
};
```

This is useful if you want separate config directories for different profiles or installations.

#### Development tip: local path

For fast iteration while modifying this flake locally, use a path input instead of the GitHub URL:

```nix
opencode-nix.url = "path:/home/username/repos/opencode-nix";
```

## Default Configuration

The default config includes:

- **context7 MCP** — documentation search for any library
- **nixos MCP** — search NixOS packages, options, and documentation (`mcp-nixos` is bundled automatically)
- **opencode-notifier** (`@mohak34/opencode-notifier`) — sound and desktop notifications when done
- **opencode-anthropic-oauth** (`opencode-anthropic-oauth`) — streamlines Anthropic API authentication via OAuth; no API key required
- **DCP** (`@tarquinen/opencode-dcp`) — intelligent context compression and pruning

## Overlay

You can also use the overlay to access the package:

```nix
nixpkgs.overlays = [ inputs.opencode-nix.overlays.default ];
# then pkgs.opencode-nix is available
```
