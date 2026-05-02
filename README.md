# opencode-nix

A Nix flake for [OpenCode](https://opencode.ai) with [context7 MCP](https://github.com/upstash/context7) and [Dynamic Context Pruning](https://github.com/Opencode-DCP/opencode-dynamic-context-pruning) pre-configured.

## Usage

### Run directly

```bash
nix run github:DanijelMi/opencode-nix
```

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

### Extending configuration

You can add additional MCP servers, override opencode settings, or adjust DCP behaviour:

```nix
programs.opencode-nix = {
  enable = true;
  settings = {
    mcp = {
      my-custom-mcp = {
        type = "remote";
        url = "https://my-mcp.example.com/mcp";
      };
    };
  };
  dcpSettings = {
    compress = {
      maxContextLimit = 200000;
    };
  };
};
```

`settings` and `dcpSettings` are each deep-merged with their respective default configurations.

## Default Configuration

The default config includes:

- **context7 MCP** — documentation search for any library
- **nixos MCP** — search NixOS packages, options, and documentation (`mcp-nixos` is bundled automatically)
- **opencode-notifier** (`@mohak34/opencode-notifier`) — desktop notifications for long-running tasks
- **opencode-claude-auth** (`opencode-claude-auth`) — streamlines Claude API authentication via OAuth; no API key required
- **DCP** (`@tarquinen/opencode-dcp`) — intelligent context compression and pruning

```json
{
  "$schema": "https://opencode.ai/config.json",
  "plugin": [
    "@mohak34/opencode-notifier@latest",
    "opencode-claude-auth@latest",
    "@tarquinen/opencode-dcp@latest"
  ],
  "mcp": {
    "context7": {
      "type": "remote",
      "url": "https://mcp.context7.com/mcp"
    },
    "nixos": {
      "type": "local",
      "command": ["mcp-nixos"]
    }
  }
}
```

### DCP Configuration

A default DCP configuration is provided at `configs/dcp.json` and installed via `OPENCODE_CONFIG_DIR`. Key defaults:

- **Compress mode**: `range` — compresses conversation spans into summaries
- **Permission**: `allow` — no confirmation prompt for compression
- **Deduplication**: enabled — removes duplicate tool call outputs
- **Purge errors**: enabled — prunes errored tool inputs after 4 turns
- **Notifications**: detailed chat notifications

When using the Home Manager module, DCP settings can be overridden declaratively via the `dcpSettings` option (see above). Alternatively, override at the project level (`.opencode/dcp.json`) or globally (`~/.config/opencode/dcp.jsonc`). See the [DCP documentation](https://github.com/Opencode-DCP/opencode-dynamic-context-pruning#configuration) for all options.

## Overlay

You can also use the overlay to access the package:

```nix
nixpkgs.overlays = [ inputs.opencode-nix.overlays.default ];
# then pkgs.opencode-nix is available
```
