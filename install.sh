#!/usr/bin/env bash
# i3kit installer
set -euo pipefail

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN_DIR="$HOME/.local/bin"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/i3kit"
DATA_DIR="$HOME/.local/share/i3kit"
I3_CONFIG="$HOME/.config/i3/config"
ZSHRC="$HOME/.zshrc"

info()  { echo -e "${GREEN}[+]${NC} $1"; }
warn()  { echo -e "${YELLOW}[!]${NC} $1"; }
error() { echo -e "${RED}[x]${NC} $1"; }

# --- Check dependencies ---
info "Checking dependencies..."
DEPS=(claude kitty xclip xdotool jq flameshot rofi dunst)
MISSING=()

for dep in "${DEPS[@]}"; do
    if ! command -v "$dep" &>/dev/null; then
        MISSING+=("$dep")
    fi
done

if (( ${#MISSING[@]} > 0 )); then
    warn "Missing dependencies: ${MISSING[*]}"

    # Separate pacman-installable from others
    PACMAN_PKGS=()
    for pkg in "${MISSING[@]}"; do
        if [[ "$pkg" == "claude" ]]; then
            error "'claude' CLI not found. Install Claude Code first: https://docs.anthropic.com/en/docs/claude-code"
            exit 1
        else
            PACMAN_PKGS+=("$pkg")
        fi
    done

    if (( ${#PACMAN_PKGS[@]} > 0 )); then
        read -rp "Install ${PACMAN_PKGS[*]} via pacman? [Y/n] " answer
        if [[ "${answer,,}" != "n" ]]; then
            sudo pacman -S --needed "${PACMAN_PKGS[@]}"
        else
            error "Cannot continue without dependencies."
            exit 1
        fi
    fi
fi
info "All dependencies satisfied."

# --- Create directories ---
info "Creating directories..."
mkdir -p "$BIN_DIR" "$CONFIG_DIR" "$DATA_DIR"

# --- Install config ---
if [[ ! -f "$CONFIG_DIR/i3kit.conf" ]]; then
    cp "$PROJECT_DIR/config/i3kit.conf" "$CONFIG_DIR/i3kit.conf"
    info "Installed config to $CONFIG_DIR/i3kit.conf"
else
    warn "Config already exists at $CONFIG_DIR/i3kit.conf — skipping."
fi

# --- Symlink scripts ---
info "Symlinking scripts to $BIN_DIR..."

SCRIPTS=(
    i3kit
    i3kit-common.sh
    context-gather.sh
    i3kit-quick-ask
    i3kit-explain
    i3kit-fix
    i3kit-screenshot
    i3kit-bookmarks
    i3kit-help
    dynamic-gaps.py
    start-dynamic-gaps.sh
)

for script in "${SCRIPTS[@]}"; do
    chmod +x "$PROJECT_DIR/scripts/$script"
    ln -sf "$PROJECT_DIR/scripts/$script" "$BIN_DIR/$script"
done
info "Scripts linked."

# --- i3 configuration ---
if [[ -f "$I3_CONFIG" ]]; then
    info "Configuring i3..."

    # Backup i3 config
    cp "$I3_CONFIG" "${I3_CONFIG}.i3kit-backup"
    info "Backed up i3 config to ${I3_CONFIG}.i3kit-backup"

    # Remove old $mod+Shift+a binding (wpg -m) if present
    if grep -q 'bindsym \$mod+Shift+a' "$I3_CONFIG"; then
        warn "Removing existing \$mod+Shift+a binding from i3 config."
        sed -i '/bindsym \$mod+Shift+a/d' "$I3_CONFIG"
    fi

    # Copy i3 fragment
    I3_FRAGMENT_DIR="$HOME/.config/i3"
    cp "$PROJECT_DIR/i3/i3kit.conf" "$I3_FRAGMENT_DIR/i3kit.conf"

    # Add include line if not present
    if ! grep -q 'include.*i3kit.conf' "$I3_CONFIG"; then
        echo "" >> "$I3_CONFIG"
        echo "# i3kit" >> "$I3_CONFIG"
        echo "include ~/.config/i3/i3kit.conf" >> "$I3_CONFIG"
        info "Added include directive to i3 config."
    else
        warn "i3 config already includes i3kit.conf — skipping."
    fi
else
    warn "i3 config not found at $I3_CONFIG — skipping i3 setup."
fi

# --- Zsh integration ---
if [[ -f "$ZSHRC" ]]; then
    info "Setting up zsh integration..."

    # Backup .zshrc
    cp "$ZSHRC" "${ZSHRC}.i3kit-backup"
    info "Backed up .zshrc to ${ZSHRC}.i3kit-backup"

    if ! grep -q 'i3kit.zsh' "$ZSHRC"; then
        cat >> "$ZSHRC" <<'EOF'

# i3kit: error capture for Claude Code context
[ -f ~/Documents/Github-Projects/i3kit/zsh/i3kit.zsh ] && source ~/Documents/Github-Projects/i3kit/zsh/i3kit.zsh
EOF
        info "Added zsh hook to .zshrc"
    else
        warn ".zshrc already sources i3kit.zsh — skipping."
    fi
else
    warn ".zshrc not found — skipping zsh integration."
fi

echo ""
info "Installation complete!"
echo ""
echo "  Next steps:"
echo "    1. Reload i3: \$mod+Shift+r"
echo "    2. Source zsh:  source ~/.zshrc"
echo "    3. Try it:      \$mod+a (new chat) or \$mod+F1 (help menu)"
echo ""
echo "  Config: $CONFIG_DIR/i3kit.conf"
echo "  Uninstall: $PROJECT_DIR/uninstall.sh"
