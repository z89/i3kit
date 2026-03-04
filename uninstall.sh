#!/usr/bin/env bash
# i3kit uninstaller
set -euo pipefail

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

BIN_DIR="$HOME/.local/bin"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/i3kit"
DATA_DIR="$HOME/.local/share/i3kit"
I3_CONFIG="$HOME/.config/i3/config"
ZSHRC="$HOME/.zshrc"

info()  { echo -e "${GREEN}[+]${NC} $1"; }
warn()  { echo -e "${YELLOW}[!]${NC} $1"; }

# --- Remove symlinks ---
info "Removing symlinks..."
rm -f "$BIN_DIR/i3kit"
rm -f "$BIN_DIR/i3kit-common.sh"
rm -f "$BIN_DIR/context-gather.sh"
rm -f "$BIN_DIR/i3kit-quick-ask"
rm -f "$BIN_DIR/i3kit-explain"
rm -f "$BIN_DIR/i3kit-fix"
rm -f "$BIN_DIR/i3kit-screenshot"
rm -f "$BIN_DIR/i3kit-bookmarks"
rm -f "$BIN_DIR/i3kit-help"
rm -f "$BIN_DIR/dynamic-gaps.py"
rm -f "$BIN_DIR/start-dynamic-gaps.sh"
info "Symlinks removed."

# --- Remove i3 configuration ---
if [[ -f "$I3_CONFIG" ]]; then
    info "Cleaning i3 config..."

    # Remove include line
    if grep -q 'include.*i3kit.conf' "$I3_CONFIG"; then
        sed -i '/# i3kit/d' "$I3_CONFIG"
        sed -i '/include.*i3kit.conf/d' "$I3_CONFIG"
        info "Removed include directive from i3 config."
    fi

    # Remove i3 fragment
    rm -f "$HOME/.config/i3/i3kit.conf"

    # Restore backup if it exists (has the old wpg binding)
    if [[ -f "${I3_CONFIG}.i3kit-backup" ]]; then
        warn "Backup available at ${I3_CONFIG}.i3kit-backup"
        read -rp "Restore original i3 config from backup? [y/N] " answer
        if [[ "${answer,,}" == "y" ]]; then
            cp "${I3_CONFIG}.i3kit-backup" "$I3_CONFIG"
            info "Restored i3 config from backup."
        fi
        rm -f "${I3_CONFIG}.i3kit-backup"
    fi
fi

# --- Remove zsh integration ---
if [[ -f "$ZSHRC" ]]; then
    info "Cleaning .zshrc..."
    if grep -q 'i3kit.zsh' "$ZSHRC"; then
        sed -i '/# i3kit: error capture/d' "$ZSHRC"
        sed -i '/i3kit\.zsh/d' "$ZSHRC"
        info "Removed zsh hook from .zshrc."
    fi

    if [[ -f "${ZSHRC}.i3kit-backup" ]]; then
        rm -f "${ZSHRC}.i3kit-backup"
        info "Removed .zshrc backup."
    fi
fi

# --- Remove config ---
if [[ -d "$CONFIG_DIR" ]]; then
    rm -rf "$CONFIG_DIR"
    info "Removed config directory: $CONFIG_DIR"
fi

# --- Remove session data ---
if [[ -d "$DATA_DIR" ]]; then
    read -rp "Remove session data at $DATA_DIR? [y/N] " answer
    if [[ "${answer,,}" == "y" ]]; then
        rm -rf "$DATA_DIR"
        info "Removed session data."
    else
        warn "Kept session data at $DATA_DIR"
    fi
fi

# --- Cleanup temp files ---
rm -f /tmp/i3kit-kitty.conf
rm -f /tmp/i3kit-last-error
rm -f /tmp/i3kit-stderr-capture
rm -f /tmp/i3kit-answer-*
rm -f /tmp/i3kit-screenshot-*

echo ""
info "Uninstall complete!"
echo "  Reload i3 with \$mod+Shift+r to apply changes."
echo "  Run 'source ~/.zshrc' to reload shell config."
