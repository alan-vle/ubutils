#!/bin/bash

# Show sub-menu after action
showSubMenu() {
    echo ""
    echo -ne "${COLOR_INFO}[R]etour au menu | [Q]uitter : ${COLOR_RESET}"
    read -n 1 subChoice
    echo ""
    
    case ${subChoice,,} in
        q)
            exitProgram
            ;;
        r|*)
            return
            ;;
    esac
}

# Show user profile
showProfile() {
    local name="$1"
    echo ""
    printInfo "Profil actuel :"
    echo -e "  ${COLOR_SUCCESS}Prénom:${COLOR_RESET} $name"
    showSubMenu
}

# Get SSH hosts from config
getSshHosts() {
    if [[ -f ~/.ssh/config ]]; then
        grep -i "^Host " ~/.ssh/config | grep -v '[*?]' | awk '{print $2}' | sort -u
    fi
}

# Prompt with SSH host selection
promptSshHost() {
    local prompt="$1"
    local varname="$2"
    local result
    local hosts=($(getSshHosts))
    
    if [[ ${#hosts[@]} -eq 0 ]]; then
        echo -ne "${COLOR_INFO}${prompt}${COLOR_RESET}"
        read -e result
        eval "$varname='$result'"
        return
    fi
    
    # Try fzf first
    if command -v fzf &> /dev/null; then
        result=$(printf "%s\n" "${hosts[@]}" | fzf --prompt="$prompt" --height=40% --border)
        if [[ -n "$result" ]]; then
            eval "$varname='$result'"
            return
        fi
    fi
    
    # Fallback: numbered list
    echo ""
    printInfo "Hosts SSH disponibles :"
    local i=1
    for host in "${hosts[@]}"; do
        echo "  $i) $host"
        ((i++))
    done
    echo "  0) Saisie manuelle"
    echo ""
    
    local choice
    while true; do
        echo -ne "${COLOR_INFO}Choisir (0-$((${#hosts[@]}))) : ${COLOR_RESET}"
        read choice
        
        if [[ "$choice" == "0" ]]; then
            echo -ne "${COLOR_INFO}${prompt}${COLOR_RESET}"
            read -e result
            eval "$varname='$result'"
            return
        elif [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le "${#hosts[@]}" ]; then
            result="${hosts[$((choice-1))]}"
            eval "$varname='$result'"
            return
        else
            printError "Choix invalide"
        fi
    done
}

# Prompt standard
promptWithCompletion() {
    local prompt="$1"
    local varname="$2"
    local result
    
    echo -ne "${COLOR_INFO}${prompt}${COLOR_RESET}"
    read -e result
    eval "$varname='$result'"
}

# Show SCP explanation and usage
showScpInfo() {
    echo ""
    printInfo "SCP (Secure Copy Protocol)"
    echo ""
    
    local file sourceUser sourceHost sourcePath destUser destHost destPath
    local isRemoteSource isRemoteDest sourceType destType
    
    # Prompt for file with completion
    while [[ -z "$file" ]]; do
        promptWithCompletion "Fichier/dossier local : " file
    done
    
    # Source type
    echo -ne "${COLOR_INFO}Source distante ? (o/n) : ${COLOR_RESET}"
    read -n 1 isRemoteSource
    echo ""
    
    if [[ "${isRemoteSource,,}" == "o" ]]; then
        echo -ne "${COLOR_INFO}Source - [M]anuel ou [S]SH config ? (m/s) : ${COLOR_RESET}"
        read -n 1 sourceType
        echo ""
        
        if [[ "${sourceType,,}" == "s" ]]; then
            while [[ -z "$sourceHost" ]]; do
                promptSshHost "Source - SSH config ID : " sourceHost
            done
        else
            while [[ -z "$sourceUser" ]]; do
                promptWithCompletion "Source - User : " sourceUser
            done
            
            while [[ -z "$sourceHost" ]]; do
                promptWithCompletion "Source - Host : " sourceHost
            done
            
            sourceHost="${sourceUser}@${sourceHost}"
        fi
        
        while [[ -z "$sourcePath" ]]; do
            promptWithCompletion "Source - Chemin : " sourcePath
        done
        
        source="${sourceHost}:${sourcePath}"
    else
        source="$file"
    fi
    
    # Destination type
    echo -ne "${COLOR_INFO}Destination distante ? (o/n) : ${COLOR_RESET}"
    read -n 1 isRemoteDest
    echo ""
    
    if [[ "${isRemoteDest,,}" == "o" ]]; then
        echo -ne "${COLOR_INFO}Destination - [M]anuel ou [S]SH config ? (m/s) : ${COLOR_RESET}"
        read -n 1 destType
        echo ""
        
        if [[ "${destType,,}" == "s" ]]; then
            while [[ -z "$destHost" ]]; do
                promptSshHost "Destination - SSH config ID : " destHost
            done
        else
            while [[ -z "$destUser" ]]; do
                promptWithCompletion "Destination - User : " destUser
            done
            
            while [[ -z "$destHost" ]]; do
                promptWithCompletion "Destination - Host : " destHost
            done
            
            destHost="${destUser}@${destHost}"
        fi
        
        while [[ -z "$destPath" ]]; do
            promptWithCompletion "Destination - Chemin : " destPath
        done
        
        destination="${destHost}:${destPath}"
    else
        while [[ -z "$destPath" ]]; do
            promptWithCompletion "Destination locale : " destPath
        done
        destination="$destPath"
    fi
    
    # Generate command
    local cmd="scp"
    if [[ -d "$file" ]]; then
        cmd="$cmd -r"
    fi
    cmd="$cmd $source $destination"
    
    echo ""
    printSuccess "Commande générée :"
    echo -e "  ${COLOR_MENU}$cmd${COLOR_RESET}"
    echo ""
    
    # Ask to execute
    echo -ne "${COLOR_INFO}Exécuter la commande ? (o/n) : ${COLOR_RESET}"
    read -n 1 execute
    echo ""
    
    if [[ "${execute,,}" == "o" ]]; then
        echo ""
        printInfo "Exécution en cours..."
        eval "$cmd"
        local exitCode=$?
        
        if [[ $exitCode -eq 0 ]]; then
            printSuccess "Transfert terminé avec succès"
        else
            printError "Erreur lors du transfert (code: $exitCode)"
        fi
    fi
    
    showSubMenu
}

# Show Rsync explanation and usage
showRsyncInfo() {
    echo ""
    printInfo "Rsync (Remote Sync)"
    echo ""
    
    local source dest syncMode deleteFiles showProgress
    local sourceUser sourceHost sourcePath destUser destHost destPath
    local isRemoteSource isRemoteDest sourceType destType
    
    # Sync mode
    echo -ne "${COLOR_INFO}Mode : [1] Synchroniser | [2] Backup : ${COLOR_RESET}"
    read -n 1 syncMode
    echo ""
    
    # Options
    echo -ne "${COLOR_INFO}Afficher la progression ? (o/n) : ${COLOR_RESET}"
    read -n 1 showProgress
    echo ""
    
    echo -ne "${COLOR_INFO}Supprimer fichiers absents de la source ? (o/n) : ${COLOR_RESET}"
    read -n 1 deleteFiles
    echo ""
    
    # Source
    while [[ -z "$source" ]]; do
        promptWithCompletion "Source (fichier/dossier) : " source
    done
    
    echo -ne "${COLOR_INFO}Source distante ? (o/n) : ${COLOR_RESET}"
    read -n 1 isRemoteSource
    echo ""
    
    if [[ "${isRemoteSource,,}" == "o" ]]; then
        echo -ne "${COLOR_INFO}Source - [M]anuel ou [S]SH config ? (m/s) : ${COLOR_RESET}"
        read -n 1 sourceType
        echo ""
        
        if [[ "${sourceType,,}" == "s" ]]; then
            promptSshHost "Source - SSH config ID : " sourceHost
        else
            while [[ -z "$sourceUser" ]]; do
                promptWithCompletion "Source - User : " sourceUser
            done
            while [[ -z "$sourceHost" ]]; do
                promptWithCompletion "Source - Host : " sourceHost
            done
            sourceHost="${sourceUser}@${sourceHost}"
        fi
        
        while [[ -z "$sourcePath" ]]; do
            promptWithCompletion "Source - Chemin : " sourcePath
        done
        
        source="${sourceHost}:${sourcePath}"
    fi
    
    # Destination
    echo -ne "${COLOR_INFO}Destination distante ? (o/n) : ${COLOR_RESET}"
    read -n 1 isRemoteDest
    echo ""
    
    if [[ "${isRemoteDest,,}" == "o" ]]; then
        echo -ne "${COLOR_INFO}Destination - [M]anuel ou [S]SH config ? (m/s) : ${COLOR_RESET}"
        read -n 1 destType
        echo ""
        
        if [[ "${destType,,}" == "s" ]]; then
            promptSshHost "Destination - SSH config ID : " destHost
        else
            while [[ -z "$destUser" ]]; do
                promptWithCompletion "Destination - User : " destUser
            done
            while [[ -z "$destHost" ]]; do
                promptWithCompletion "Destination - Host : " destHost
            done
            destHost="${destUser}@${destHost}"
        fi
        
        while [[ -z "$destPath" ]]; do
            promptWithCompletion "Destination - Chemin : " destPath
        done
        
        dest="${destHost}:${destPath}"
    else
        while [[ -z "$destPath" ]]; do
            promptWithCompletion "Destination locale : " destPath
        done
        dest="$destPath"
    fi
    
    # Generate command
    local cmd="rsync -avz"
    
    if [[ "${showProgress,,}" == "o" ]]; then
        cmd="$cmd --progress"
    fi
    
    if [[ "${deleteFiles,,}" == "o" ]]; then
        cmd="$cmd --delete"
    fi
    
    cmd="$cmd $source $dest"
    
    echo ""
    printSuccess "Commande générée :"
    echo -e "  ${COLOR_MENU}$cmd${COLOR_RESET}"
    echo ""
    
    # Ask to execute
    echo -ne "${COLOR_INFO}Exécuter la commande ? (o/n) : ${COLOR_RESET}"
    read -n 1 execute
    echo ""
    
    if [[ "${execute,,}" == "o" ]]; then
        echo ""
        printInfo "Exécution en cours..."
        eval "$cmd"
        local exitCode=$?
        
        if [[ $exitCode -eq 0 ]]; then
            printSuccess "Synchronisation terminée avec succès"
        else
            printError "Erreur lors de la synchronisation (code: $exitCode)"
        fi
    fi
    
    showSubMenu
}

# Exit program
exitProgram() {
    echo ""
    printSuccess "Au revoir!"
    exit 0
}