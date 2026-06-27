#!/usr/bin/env bash

# Toggles maximized state on the active window. Used as hyprbars' bar double-click action.

hyprctl dispatch "hl.dsp.window.fullscreen({ mode = 'maximized' })"
