---
name: git-commit
description: Create well-formed git commits in the opencode-nix repository
compatibility: opencode
metadata:
  audience: contributors
  workflow: git
---

## What I do

- Stage the right files and craft a concise, well-formed commit message
- Follow the commit style conventions of this project
- Run pre-commit checks (formatting) before committing
- Verify the commit succeeded with `git status`

## When to use me

Use this skill when the user explicitly asks you to commit changes. Do NOT commit
proactively — always wait for an explicit request.

## Commit message style

- Use the **imperative mood** in the subject line: "add", "fix", "update", "remove"
- Keep the subject line under **72 characters**
- Focus on the **why**, not the what — the diff shows what changed
- No period at the end of the subject line
- Examples:
  - `add git-commit skill for opencode agents`
  - `fix strip-jsonc handling of escaped quotes`
  - `update default config to include new MCP server`
  - `refactor make-opencode-nix to support skills dir`

## Step-by-step workflow

1. **Check current state**
   ```bash
   git status
   git diff
   git log --oneline -5
   ```

2. **Format Nix files before staging** (required for any `.nix` file changes)
   ```bash
   nix fmt
   ```

3. **Stage relevant files** — be selective, do not stage unrelated changes
   ```bash
   git add <files>
   ```

4. **Commit**
   ```bash
   git commit -m "<subject line>"
   ```

5. **Verify**
   ```bash
   git status
   ```

## Project-specific notes

- Never commit `result` (symlink to Nix store) — it is in `.gitignore`
- Never commit `.env`, secrets, or API keys
- Do not use `--no-verify` to skip hooks unless the user explicitly asks
- Do not force-push to `main` without an explicit user request
- `configs/default.jsonc` changes affect all users — mention this in the commit message body if relevant
- After changing any `.nix` file, always run `nix fmt` before staging
- If the build is affected, mention it: e.g. `(requires nix build)`

## Safety rules

- NEVER amend a commit that has already been pushed to the remote
- NEVER use `git push --force` unless the user explicitly requests it
- If a commit fails, fix the issue and create a NEW commit — do not amend
- Only commit changes that are directly related to the user's request
