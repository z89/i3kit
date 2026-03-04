#!/usr/bin/env bash
# i3kit-common.sh — Shared functions for i3kit scripts

# Rofi theme path (pywal-themed)
ROFI_THEME="${ROFI_THEME:-$HOME/.config/rofi/rofi.rasi}"

# Generate pywal-themed kitty config, echo the path
generate_kitty_conf() {
    local conf="/tmp/i3kit-kitty.conf"
    local wal_colors="$HOME/.cache/wal/colors.json"
    local user_conf="$HOME/.config/kitty/kitty.conf"

    echo "# i3kit kitty config — inherits user config" > "$conf"
    if [[ -f "$user_conf" ]]; then
        echo "include ${user_conf}" >> "$conf"
    fi

    PYWAL_THEME="${PYWAL_THEME:-true}"
    if [[ "$PYWAL_THEME" == "true" ]] && [[ -f "$wal_colors" ]] && command -v jq &>/dev/null; then
        local bg fg cursor
        bg="$(jq -r '.special.background' "$wal_colors")"
        fg="$(jq -r '.special.foreground' "$wal_colors")"
        cursor="$(jq -r '.special.cursor' "$wal_colors")"

        cat >> "$conf" <<EOF
background ${bg}
foreground ${fg}
cursor ${cursor}
EOF
        for i in $(seq 0 15); do
            local color
            color="$(jq -r ".colors.color${i}" "$wal_colors")"
            echo "color${i} ${color}" >> "$conf"
        done
    fi

    echo "$conf"
}
