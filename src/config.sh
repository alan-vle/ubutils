#!/bin/bash

# Package info
PACKAGE_NAME="plici-package"
MODE="${MODE:-prod}"
MODE="${MODE,,}"  # Convert to lowercase

# File paths
if [[ "$MODE" == "dev" ]]; then
    CONFIG_FILE="./config.conf"
else
    CONFIG_FILE="$HOME/.config/${PACKAGE_NAME}/config.conf"
fi

# Config keys
CONFIG_KEY_NAME="name"

# Read value from config file
getConfigValue() {
    local key="$1"
    local value=$(grep "^${key}=" "$CONFIG_FILE" 2>/dev/null | cut -d'=' -f2-)
    echo "$value"
}

# Write value to config file
setConfigValue() {
    local key="$1"
    local value="$2"
    
    if grep -q "^${key}=" "$CONFIG_FILE" 2>/dev/null; then
        sed -i "s|^${key}=.*|${key}=${value}|" "$CONFIG_FILE"
    else
        echo "${key}=${value}" >> "$CONFIG_FILE"
    fi
}

# Create config file if it doesn't exist
initConfigFile() {
    local configDir=$(dirname "$CONFIG_FILE")
    if [[ ! -d "$configDir" ]]; then
        mkdir -p "$configDir"
    fi
    
    if [[ ! -f "$CONFIG_FILE" ]]; then
        echo "${CONFIG_KEY_NAME}=" > "$CONFIG_FILE"
    fi
}