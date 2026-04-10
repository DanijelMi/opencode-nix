# opencode-nix

A Nix flake for [OpenCode](https://opencode.ai) with [context7 MCP](https://github.com/upstash/context7) pre-configured.

## Usage

### Run directly

```bash
nix run github:DanijelMi/opencode-nix
```

### Dev shell

```bash
nix develop github:DanijelMi/opencode-nix
```

### Home Manager

Add the flake to your inputs:

```nix
{
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
}
```

#### Local path (for development)

For fast iteration, use a local path instead:

```nix
opencode-nix = {
  url = "path:/home/username/repos/opencode-nix";
  inputs.nixpkgs.follows = "nixpkgs";
};
```

Import the module and enable:

```nix
{
  imports = [ inputs.opencode-nix.homeManagerModules.default ];

  programs.opencode-nix = {
    enable = true;
  };
}
```

This adds `opencode-nix` to your PATH.

### Extending configuration

You can add additional MCP servers or override settings:

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
};
```

Settings are deep-merged with the default context7 configuration.

## Default Configuration

The default config includes context7 MCP for documentation search:

```json
{
  "$schema": "https://opencode.ai/config.json",
  "mcp": {
    "context7": {
      "type": "remote",
      "url": "https://mcp.context7.com/mcp"
    }
  }
}
```

## Overlay

You can also use the overlay to access the package:

```nix
nixpkgs.overlays = [ inputs.opencode-nix.overlays.default ];
# then pkgs.opencode-nix is available
```
