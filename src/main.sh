#!/bin/bash

# Get script directory and source utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source all utility files
source "${SCRIPT_DIR}/printers.sh"
source "${SCRIPT_DIR}/constants.sh"
source "${SCRIPT_DIR}/config.sh"
source "${SCRIPT_DIR}/menu_options.sh"

# Prompt user for their name
promptForName() {
    local userName
    echo ""
    echo -ne "${COLOR_INFO}Quel est votre prénom ? ${COLOR_RESET}"
    read userName
    
    if [[ -n "$userName" ]]; then
        setConfigValue "$CONFIG_KEY_NAME" "$userName"
        printSuccess "Prénom enregistré : $userName"
    else
        printWarning "Aucun prénom saisi."
    fi
}

# Display menu and get user choice
showMenu() {
    local name="$1"
    echo ""
    echo -e "${COLOR_MENU}╔════════════════════════════════╗${COLOR_RESET}"
    echo -e "${COLOR_MENU}║           MENU                 ║${COLOR_RESET}"
    echo -e "${COLOR_MENU}╚════════════════════════════════╝${COLOR_RESET}"
    
    for key in $(echo "${!MENU_OPTIONS[@]}" | tr ' ' '\n' | sort -n); do
        printMenu "  ${key}. ${MENU_OPTIONS[$key]}"
    done
    
    echo ""
    echo -ne "${COLOR_INFO}$name, que voulez-vous faire ? ${COLOR_RESET}"
    read choice
}

# Handle user menu selection
handleMenuChoice() {
    local choice="$1"
    local name="$2"
    
    case $choice in
        1)
            showProfile "$name"
            ;;
        2)
            promptForName
            ;;
        *)
            if [[ -n "${MENU_CALLBACKS[$choice]}" ]]; then
                ${MENU_CALLBACKS[$choice]}
            else
                printError "Choix invalide."
            fi
            ;;
    esac
}

# Main entry point
main() {
    initConfigFile
    
    local name=$(getConfigValue "$CONFIG_KEY_NAME")
    
    if [[ -z "$name" ]]; then
        promptForName
        name=$(getConfigValue "$CONFIG_KEY_NAME")
    fi
    
    echo ""
    printSuccess "Hello $name!"
    
    while true; do
        showMenu "$name"
        handleMenuChoice "$choice" "$name"
        name=$(getConfigValue "$CONFIG_KEY_NAME")
    done
}

main