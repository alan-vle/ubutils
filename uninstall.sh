#!/bin/bash

# Uninstall script

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source utilities
source "${SCRIPT_DIR}/src/printers.sh"
source "${SCRIPT_DIR}/src/config.sh"

printInfo "Uninstalling package: $PACKAGE_NAME"

# Validate PACKAGE_NAME is not empty
if [[ -z "$PACKAGE_NAME" ]]; then
    printError "PACKAGE_NAME is empty - ABORTING"
    exit 1
fi

# Remove executable
if [[ -f "$HOME/.local/bin/$PACKAGE_NAME" ]]; then
    rm "$HOME/.local/bin/$PACKAGE_NAME"
    printSuccess "Removed executable"
fi

# Remove package files
if [[ -d "$HOME/.local/share/$PACKAGE_NAME" ]]; then
    rm -rf "$HOME/.local/share/$PACKAGE_NAME"
    printSuccess "Removed package files"
fi

# Remove config
if [[ -d "$HOME/.config/$PACKAGE_NAME" ]]; then
    rm -rf "$HOME/.config/$PACKAGE_NAME"
    printSuccess "Removed config directory"
fi

printSuccess "Uninstall complete!"