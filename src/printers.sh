#!/bin/bash

# Color constants
readonly COLOR_RESET="\033[0m"
readonly COLOR_INFO="\033[1;34m"
readonly COLOR_SUCCESS="\033[1;32m"
readonly COLOR_WARNING="\033[1;33m"
readonly COLOR_ERROR="\033[1;31m"
readonly COLOR_MENU="\033[1;36m"

# Print colored messages
printInfo() {
    echo -e "${COLOR_INFO}ℹ ${1}${COLOR_RESET}"
}

printSuccess() {
    echo -e "${COLOR_SUCCESS}✓ ${1}${COLOR_RESET}"
}

printWarning() {
    echo -e "${COLOR_WARNING}⚠ ${1}${COLOR_RESET}"
}

printError() {
    echo -e "${COLOR_ERROR}✗ ${1}${COLOR_RESET}"
}

printMenu() {
    echo -e "${COLOR_MENU}${1}${COLOR_RESET}"
}