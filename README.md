# dotfiles

Personal setup procedure and configuration files. Supports macOS and Linux (including Dev Containers).
The source of truth is `mise/config*.toml`, applied by [`mise bootstrap`](https://mise.jdx.dev/cli/bootstrap.html) (experimental).

## Setup

1. Run the following in Terminal.

   ```sh
   $ cd ~
   # The first `git` run may start installing the Xcode Command Line Tools.
   # Run the command again after it finishes.
   $ git clone https://github.com/ohbarye/dotfiles.git
   $ ~/dotfiles/setup.sh
   ```

2. Do the "Manual steps" below.

`setup.sh` is idempotent: run it as many times as you like. It prepares mise and runs `mise bootstrap`.

- Links the configs into `~/.config/mise/` and layers OS-specific ones via `MISE_ENV=macos|linux`.
  mise must be **2026.9.14 or newer** (for relative dotfile symlinks); `setup.sh` installs or upgrades it.
- Links the dotfiles (a regular file in the way is moved to `*.bak` first).
- macOS: installs Homebrew packages (brew / cask / mas) and applies `defaults`.
- Installs the `[tools]` (language runtimes are macOS-only; Linux gets `delta`, `sheldon`, `fzf`, `jq`).
- Linux: installs `tree`, `vim`, `silversearcher-ag`, etc. with `apt` (failures are tolerated).
- Reproduces agent skills from `agents/skills.manifest` at pinned refs (`scripts/install-skills.sh`;
  own skills come from [`ohbarye/agent-skills`](https://github.com/ohbarye/agent-skills), the rest from upstream).

Link only: `SETUP_LINKS_ONLY=1 ~/dotfiles/setup.sh`.
In Dev Containers, VS Code's dotfiles integration runs `setup.sh`; Homebrew is not used there.

## Manual steps

Things `setup.sh` does not automate.

- Sign in to the App Store (needed for the apps installed with `mas`; do this before `setup.sh`).
- Sign in to 1Password and enable the CLI (`op`) integration and the SSH agent.
- Log in to GitHub with `gh auth login`.
- `.safe-chain` is distributed by MDM. Shells do not error where it is missing.
- Log in to the Claude Code / Codex apps.
- Register the company plugin marketplace (its repository name is kept out of this public repo):
  `claude plugin marketplace add <company agent_skills repository>`
- Re-register Claude Code MCP servers (they live in `~/.claude.json` and are not reproduced).

## Layout

| Path | Contents |
| --- | --- |
| `mise/config.toml` | Common: tools and dotfile links (relative links for AI-agent files) |
| `mise/config.macos.toml` | macOS: packages (brew / cask / mas), defaults, editor and Karabiner settings |
| `mise/config.linux.toml` | Linux / Dev Container: OS-specific git config, etc. |
| `setup.sh` | Entry point: prepares mise and calls `mise bootstrap` |
| `agents/skills.manifest` | Where each agent skill comes from, with a pinned ref. The contents of `agents/skills/` are git-ignored and reproduced by `scripts/install-skills.sh` |
| `.zshrc` and other `.z*` | zsh (plugins in `sheldon/plugins.toml`) |
| `.gitconfig`, `.gitconfig.{macos,linux}` | git; OS-specific settings are included through `~/.gitconfig.os` |
| `editors/`, `karabiner/` | VS Code / Cursor / Karabiner settings and extension lists |
| `claude/`, `codex/` | AI agent settings and commands |
| `test/setup_test.sh` | Regression tests |

## Day to day

```sh
$ mise bootstrap status                  # declared vs. actual
$ mise bootstrap plan                    # preview what would change
$ mise bootstrap --dry-run               # check without writing anything
$ mise bootstrap                         # apply (convergent; safe to repeat)
$ mise bootstrap packages use brew:foo   # declare a package and install it
```

`MISE_ENV` is derived from the OS in `.zshenv`.

## Policy

- This repository is public. Do not put company repository names, hostnames, paths or secrets here.
- The Codex app appends `[projects.*]` to `codex/config.toml`. Leave those hunks out when committing.
- Files such as `~/.claude/settings.json` are links, so changes made by the apps show up as diffs here.
- `mise bootstrap` is experimental and may change. Check with `--dry-run` when changing things.

## Tests

```sh
$ test/setup_test.sh
```

Besides static checks, it applies the dotfiles to a sandboxed HOME with the real `mise`, and runs the whole
`setup.sh` flow with `brew` / `gh` / etc. stubbed. It never touches real packages or defaults.
CI runs the same script on macOS.

## Environments

- macOS (Apple Silicon). History: M1 Pro (2022-04-17) → M2 Pro (2023-08-31).
