#!/usr/bin/env bash
set -uo pipefail

NOTES_FILE="$HOME/.config/eww/notes.txt"
touch "$NOTES_FILE"

case "${1:-show}" in
    show)
        cat "$NOTES_FILE"
        ;;
    save)
        printf '%s' "${2:-}" > "$NOTES_FILE"
        ;;
esac
