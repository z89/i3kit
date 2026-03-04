# i3kit

Custom kit of essential scripts and fixes for my Arch Linux + i3wm setup.

## What's in the kit

### Claude Code integration

Hotkey-driven Claude Code launcher with automatic context capture (working directory, git status, shell history, recent errors, clipboard). Opens in a pywal-themed floating kitty terminal.

| Keybinding | Action |
|---|---|
| `$mod+a` | New Claude chat with auto-captured context |
| `$mod+Shift+a` | Resume last Claude session |
| `$mod+g` | Quick ask via rofi prompt (short answers as notifications, long answers in a popup) |
| `$mod+Shift+g` | Explain selected text |
| `$mod+Mod1+g` | Fix selected code, copy result to clipboard |
| `$mod+Print` | Screenshot region, open Claude chat with the image |
| `$mod+Shift+b` | Resume a bookmarked session |
| `$mod+Mod1+b` | Save current session as bookmark |
| `$mod+F1` | Show shortcut help menu |

### Dynamic gaps

An i3ipc-based Python daemon that adjusts left/right outer gaps based on how many tiled windows are on the focused workspace. Designed for ultrawide monitors where a single tiled window shouldn't stretch edge to edge. Also floats new windows by default and resizes specific window classes on creation.

Starts automatically with i3 via `exec_always`. Gap adjustments for inner/top/bottom are persisted across i3 reloads in `~/.config/i3/.gap-state.json`.

| Tiled windows | Left/right gap |
|---|---|
| 1-2 | 680px (~20% margin) |
| 3-4 | 340px (~10% margin) |
| 5+ | 154px (~3% margin) |

### Zsh error capture

A zsh hook that records failed commands and their exit codes to `/tmp/i3kit-last-error`. This feeds into the Claude context so "fix my last error" works without copy-pasting.

### Pywal-themed kitty configs

Generates a kitty terminal config on the fly from `~/.cache/wal/colors.json`, so floating terminals match the current wallpaper theme.

## Install

```bash
git clone https://github.com/z89/i3kit.git ~/Documents/Github-Projects/i3kit
cd ~/Documents/Github-Projects/i3kit
chmod +x install.sh && ./install.sh
```

The installer checks dependencies, symlinks scripts to `~/.local/bin/`, adds i3 keybindings, and sets up zsh hooks. Configs are backed up before any changes.

After installing, reload i3 (`$mod+Shift+r`) and `source ~/.zshrc`.

## Uninstall

```bash
~/Documents/Github-Projects/i3kit/uninstall.sh
```

## Dependencies

| Package | Purpose |
|---|---|
| `claude` | Claude Code CLI (install separately) |
| `kitty` | Terminal emulator |
| `xclip` | Clipboard access |
| `xdotool` | Active window detection |
| `jq` | JSON parsing |
| `flameshot` | Screenshot capture |
| `rofi` | Prompt menus |
| `dunst` | Notifications |
| `python-i3ipc` | i3 IPC for dynamic gaps |

## Configuration

`~/.config/i3kit/i3kit.conf`:

```bash
CLAUDE_FLAGS=""                  # Extra flags for claude CLI
CONTEXT_SOURCES="pwd,git,history,error,window,clipboard"
HISTORY_LINES=10                 # Shell history lines to capture
CLIPBOARD_MAX_CHARS=500          # Max clipboard content length
KITTY_WIDTH="60ppt"              # Window width (i3 percentage)
KITTY_HEIGHT="70ppt"             # Window height
PYWAL_THEME=true                 # Use pywal colors
NOTIFICATION_CHAR_LIMIT=300      # Max chars for notification (longer opens popup)
NOTIFY_ON_EXIT=true              # Notification when session finishes
```

## License

MIT
