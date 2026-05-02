# AGENTS.md

## Commands

```bash
just build          # nix build — produces ./result symlink
just dev [dir=.]    # run with live config/ (requires ./result to exist)
just run [dir=.]    # nix run from a target directory
just fmt            # nix fmt (uses nixfmt-tree, not plain nixfmt)
just update         # nix flake update
```

Check formatting without applying:
```bash
nix fmt -- --fail-on-change
```

Validate the flake (only automated check available — no test suite):
```bash
nix flake check
```

Inspect the wrapper script after a build:
```bash
just build && cat result/bin/opencode-nix
```

## Architecture

- **`flake.nix`** — defines all outputs; calls `makeOpencodeNix`; builds a `pkgs.runCommand` config dir by copying `config/config.jsonc`, `config/dcp.json`, and `config/skills/` into the Nix store at build time
- **`lib/make-opencode-nix.nix`** — wraps `pkgs.opencode` with `makeWrapper`; uses a `--run` shell preamble to sync static config files from the store into a writable `~/.config/opencode-nix/` on first launch (or after a flake update); prepends `pkgs.mcp-nixos` to `PATH`
- **`modules/home-manager.nix`** — `programs.opencode-nix` options: `enable`, `binaryName` (`enum ["opencode-nix" "opencode"]`), `configDirName`
- **`config/`** — the live source of truth for defaults; `just dev` points `OPENCODE_CONFIG` and `OPENCODE_CONFIG_DIR` here directly, bypassing the store copy

Flake outputs per system: `packages.{default,opencode-nix,opencode}`, `apps.default`, `formatter`, `devShells.default`, `homeManagerModules.default`, `overlays.default`.

Supported systems: `x86_64-linux`, `aarch64-linux`, `x86_64-darwin`, `aarch64-darwin`.

## Key Gotchas

- **`just dev` requires `./result`** — it does not call `nix build`; run `just build` first if `./result` is missing or stale
- **Formatter is `nixfmt-tree`** (treefmt wrapper), not plain `nixfmt` — `nix fmt` is the correct invocation
- **Config is copied at runtime, not baked in** — on first launch (or after a flake update), the wrapper copies `config.jsonc`, `dcp.json`, and `skills/` from the Nix store to `~/.config/opencode-nix/`; a sentinel file `.nix-store-path` tracks which store path was last synced
- **`OPENCODE_CONFIG` / `OPENCODE_CONFIG_DIR` honour existing env values** — `just dev` relies on this to point at the live `config/` dir without rebuilding
- **opencode parses JSONC natively** — `config/config.jsonc` is copied directly into the store and passed to opencode as-is; no Nix-side comment stripping needed
- **`config/package.json` is gitignored** — exists on disk for plugin development but not tracked; same for `configs/` and `.opencode/` node_modules/package files
- **`configs/` is legacy** — leftover from a past restructure; no tracked content, ignore it
- **No CI, no automated tests** — `nix flake check` is the only gating validation

## Adding a Skill

1. Create `config/skills/<name>/SKILL.md` with YAML frontmatter: `name`, `description`, `compatibility: opencode`
2. No Nix changes needed — `flake.nix` and `home-manager.nix` copy `config/skills/` wholesale at build time

## Git Commit Workflow

A `git-commit` skill is bundled at `config/skills/git-commit/SKILL.md`. Key rules:
- Run `nix fmt` before staging any `.nix` changes
- Never commit the `result` symlink
- Imperative mood, ≤72 chars, no trailing period
