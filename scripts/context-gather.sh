#!/usr/bin/env bash
# context-gather.sh — Captures system context for i3kit
# Outputs formatted context text to stdout

set -euo pipefail

# Load config
CONFIG_FILE="${XDG_CONFIG_HOME:-$HOME/.config}/i3kit/i3kit.conf"
if [[ -f "$CONFIG_FILE" ]]; then
    source "$CONFIG_FILE"
fi

CONTEXT_SOURCES="${CONTEXT_SOURCES:-pwd,git,history,error,window,clipboard}"
HISTORY_LINES="${HISTORY_LINES:-10}"
CLIPBOARD_MAX_CHARS="${CLIPBOARD_MAX_CHARS:-500}"

output=""

# Helper to check if a source is enabled
source_enabled() {
    [[ ",$CONTEXT_SOURCES," == *",$1,"* ]]
}

# --- Working Directory & Git ---
if source_enabled "pwd"; then
    dir="$(pwd)"
    git_info=""
    if source_enabled "git" && command -v git &>/dev/null && git rev-parse --is-inside-work-tree &>/dev/null 2>&1; then
        branch="$(git branch --show-current 2>/dev/null || echo "detached")"
        modified="$(git status --short 2>/dev/null | wc -l | tr -d ' ')"
        git_info=" (git: ${branch}, ${modified} changed files)"
    fi
    output+="[Directory] ${dir}${git_info}"$'\n'
fi

# --- Recent Shell History ---
if source_enabled "history"; then
    # Try reading zsh history file directly
    if [[ -f "${HISTFILE:-$HOME/.zsh_history}" ]]; then
        hist="$(tail -n "$HISTORY_LINES" "${HISTFILE:-$HOME/.zsh_history}" 2>/dev/null | sed 's/^: [0-9]*:[0-9]*;//' || true)"
        if [[ -n "$hist" ]]; then
            output+="[Recent Commands]"$'\n'
            while IFS= read -r line; do
                output+="$ ${line}"$'\n'
            done <<< "$hist"
        fi
    fi
fi

# --- Last Error ---
if source_enabled "error"; then
    error_file="/tmp/i3kit-last-error"
    if [[ -f "$error_file" ]] && [[ -s "$error_file" ]]; then
        # Only include if the error is recent (less than 5 minutes old)
        if [[ "$(find "$error_file" -mmin -5 2>/dev/null)" ]]; then
            error_content="$(cat "$error_file" 2>/dev/null | head -20)"
            if [[ -n "$error_content" ]]; then
                output+="[Last Error]"$'\n'
                output+="${error_content}"$'\n'
            fi
        fi
    fi
fi

# --- Active Window ---
if source_enabled "window" && command -v xdotool &>/dev/null; then
    window_name="$(xdotool getactivewindow getwindowname 2>/dev/null || true)"
    if [[ -n "$window_name" ]]; then
        output+="[Active Window] ${window_name}"$'\n'
    fi
fi

# --- Clipboard ---
if source_enabled "clipboard" && command -v xclip &>/dev/null; then
    # Primary selection (highlighted text)
    primary="$(xclip -selection primary -o 2>/dev/null || true)"
    if [[ -n "$primary" ]]; then
        len=${#primary}
        if (( len > CLIPBOARD_MAX_CHARS )); then
            kb=$(echo "scale=1; $len / 1024" | bc 2>/dev/null || echo "$len bytes")
            output+="[Selection] [selection: ${kb}KB]"$'\n'
        else
            output+="[Selection] ${primary}"$'\n'
        fi
    fi

    # Clipboard content
    clip="$(xclip -selection clipboard -o 2>/dev/null || true)"
    if [[ -n "$clip" ]]; then
        len=${#clip}
        if (( len > CLIPBOARD_MAX_CHARS )); then
            kb=$(echo "scale=1; $len / 1024" | bc 2>/dev/null || echo "$len bytes")
            output+="[Clipboard] [clipboard: ${kb}KB]"$'\n'
        else
            output+="[Clipboard] ${clip}"$'\n'
        fi
    fi
fi

# Output the gathered context (trim trailing newline)
printf '%s' "$output"
