# i3kit zsh integration
# Captures last command's stderr for context injection
# Source this from your .zshrc

# Store the last command for error tracking
__i3kit_preexec() {
    __i3kit_last_cmd="$1"
    __i3kit_cmd_start=1
}

__i3kit_precmd() {
    local exit_code=$?
    local error_file="/tmp/i3kit-last-error"

    if [[ -n "${__i3kit_cmd_start:-}" ]] && (( exit_code != 0 )); then
        # Command failed — record it
        {
            echo "Command: ${__i3kit_last_cmd}"
            echo "Exit code: ${exit_code}"
            # If there's a stderr capture from the command, include it
            if [[ -f /tmp/i3kit-stderr-capture ]]; then
                echo "---"
                cat /tmp/i3kit-stderr-capture 2>/dev/null
            fi
        } > "$error_file"
    else
        # Last command succeeded — clear the error file
        rm -f "$error_file" 2>/dev/null
    fi

    unset __i3kit_cmd_start
}

# Register hooks (only if not already registered)
if [[ -z "${__i3kit_hooks_registered:-}" ]]; then
    autoload -Uz add-zsh-hook
    add-zsh-hook preexec __i3kit_preexec
    add-zsh-hook precmd __i3kit_precmd
    __i3kit_hooks_registered=1
fi
