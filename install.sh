#!/bin/bash

# Installation script

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source utilities
source "${SCRIPT_DIR}/src/printers.sh"
source "${SCRIPT_DIR}/src/config.sh"

printInfo "Installing package: $PACKAGE_NAME"

# Validate PACKAGE_NAME
if [[ -z "$PACKAGE_NAME" ]]; then
    printError "PACKAGE_NAME is empty - ABORTING"
    exit 1
fi

# Check if already installed
if [[ -f "$HOME/.local/bin/$PACKAGE_NAME" ]]; then
    echo ""
    printWarning "Package already installed"
    echo -ne "${COLOR_INFO}Réinstaller ? (o/n) : ${COLOR_RESET}"
    read -n 1 reinstall
    echo ""
    
    if [[ "${reinstall,,}" == "o" ]]; then
        printInfo "Uninstalling old version..."
        "${SCRIPT_DIR}/uninstall.sh"
        echo ""
    else
        printInfo "Installation cancelled"
        exit 0
    fi
fi

# Create directories
mkdir -p "$HOME/.local/bin"

# Copy source files
rm -rf "$HOME/.local/share/$PACKAGE_NAME"
cp -r "${SCRIPT_DIR}/src" "$HOME/.local/share/$PACKAGE_NAME"
printSuccess "Files copied"

# Create executable
cat > "$HOME/.local/bin/$PACKAGE_NAME" << EOF
#!/bin/bash
export MODE=prod
exec "\$HOME/.local/share/$PACKAGE_NAME/main.sh" "\$@"
EOF

chmod +x "$HOME/.local/bin/$PACKAGE_NAME"
printSuccess "Executable created"

# Check PATH
if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
    echo ""
    printInfo "Add to ~/.bashrc or ~/.zshrc:"
    echo "export PATH=\"\$HOME/.local/bin:\$PATH\""
fi

echo ""
printSuccess "Installation complete! Run '$PACKAGE_NAME'"