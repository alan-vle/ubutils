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
    
    if command -v fzf &> /dev/null; then
        result=$(printf "%s\n" "${hosts[@]}" | fzf --prompt="$prompt" --height=40% --border)
        if [[ -n "$result" ]]; then
            eval "$varname='$result'"
            return
        fi
    fi
    
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

# Show SCP
showScpInfo() {
    echo ""
    printInfo "SCP (Secure Copy Protocol)"
    echo ""
    
    local transferType source dest
    local host user path localPath
    
    echo "1) Local → Distant"
    echo "2) Distant → Local"
    echo "3) Distant → Distant"
    echo ""
    echo -ne "${COLOR_INFO}Type de transfert : ${COLOR_RESET}"
    read transferType
    echo ""
    
    if [[ "$transferType" == "1" ]]; then
        promptWithCompletion "Fichier local : " localPath
        
        echo -ne "${COLOR_INFO}[M]anuel ou [S]SH ? ${COLOR_RESET}"
        read sshType
        echo ""
        
        if [[ "${sshType,,}" == "s" ]]; then
            promptSshHost "Host : " host
        else
            promptWithCompletion "User : " user
            promptWithCompletion "Host : " host
            host="${user}@${host}"
        fi
        
        promptWithCompletion "Chemin distant : " path
        
        source="$localPath"
        dest="${host}:${path}"
        
    elif [[ "$transferType" == "2" ]]; then
        echo -ne "${COLOR_INFO}[M]anuel ou [S]SH ? ${COLOR_RESET}"
        read -n 1 sshType
        echo ""
        
        if [[ "${sshType,,}" == "s" ]]; then
            promptSshHost "Host : " host
        else
            promptWithCompletion "User : " user
            promptWithCompletion "Host : " host
            host="${user}@${host}"
        fi
        
        promptWithCompletion "Chemin distant : " path
        promptWithCompletion "Destination locale : " localPath
        
        source="${host}:${path}"
        dest="$localPath"
        
    else
        printInfo "SOURCE"
        echo -ne "${COLOR_INFO}[M]anuel ou [S]SH ? ${COLOR_RESET}"
        read -n 1 sshType
        echo ""
        
        if [[ "${sshType,,}" == "s" ]]; then
            promptSshHost "Host : " host
        else
            promptWithCompletion "User : " user
            promptWithCompletion "Host : " host
            host="${user}@${host}"
        fi
        
        promptWithCompletion "Chemin : " path
        source="${host}:${path}"
        
        host=""
        user=""
        path=""
        
        echo ""
        printInfo "DESTINATION"
        echo -ne "${COLOR_INFO}[M]anuel ou [S]SH ? ${COLOR_RESET}"
        read -n 1 sshType
        echo ""
        
        if [[ "${sshType,,}" == "s" ]]; then
            promptSshHost "Host : " host
        else
            promptWithCompletion "User : " user
            promptWithCompletion "Host : " host
            host="${user}@${host}"
        fi
        
        promptWithCompletion "Chemin : " path
        dest="${host}:${path}"
    fi
    
    local cmd="scp -r $source $dest"
    
    echo ""
    printSuccess "Commande générée :"
    echo -e "  ${COLOR_MENU}$cmd${COLOR_RESET}"
    echo ""
    
    echo -ne "${COLOR_INFO}Exécuter ? (o/n) : ${COLOR_RESET}"
    read -n 1 execute
    echo ""
    
    if [[ "${execute,,}" == "o" ]]; then
        echo ""
        printInfo "Exécution..."
        eval "$cmd"
        [[ $? -eq 0 ]] && printSuccess "Terminé" || printError "Erreur"
    fi
    
    showSubMenu
}

# Show Rsync
showRsyncInfo() {
    echo ""
    printInfo "Rsync (Remote Sync)"
    echo ""
    
    local source dest syncMode deleteFiles showProgress
    local host user path localPath
    
    echo -ne "${COLOR_INFO}Afficher progression ? (o/n) : ${COLOR_RESET}"
    read -n 1 showProgress
    echo ""
    
    echo -ne "${COLOR_INFO}Supprimer fichiers absents ? (o/n) : ${COLOR_RESET}"
    read -n 1 deleteFiles
    echo ""
    
    echo "1) Local → Distant"
    echo "2) Distant → Local"
    echo "3) Distant → Distant"
    echo ""
    echo -ne "${COLOR_INFO}Type : ${COLOR_RESET}"
    read -n 1 transferType
    echo ""
    echo ""
    
    if [[ "$transferType" == "1" ]]; then
        promptWithCompletion "Source locale : " source
        
        echo -ne "${COLOR_INFO}[M]anuel ou [S]SH ? ${COLOR_RESET}"
        read -n 1 sshType
        echo ""
        
        if [[ "${sshType,,}" == "s" ]]; then
            promptSshHost "Host : " host
        else
            promptWithCompletion "User : " user
            promptWithCompletion "Host : " host
            host="${user}@${host}"
        fi
        
        promptWithCompletion "Chemin distant : " path
        dest="${host}:${path}"
        
    elif [[ "$transferType" == "2" ]]; then
        echo -ne "${COLOR_INFO}[M]anuel ou [S]SH ? ${COLOR_RESET}"
        read -n 1 sshType
        echo ""
        
        if [[ "${sshType,,}" == "s" ]]; then
            promptSshHost "Host : " host
        else
            promptWithCompletion "User : " user
            promptWithCompletion "Host : " host
            host="${user}@${host}"
        fi
        
        promptWithCompletion "Chemin distant : " path
        promptWithCompletion "Destination locale : " localPath
        
        source="${host}:${path}"
        dest="$localPath"
        
    else
        printInfo "SOURCE"
        echo -ne "${COLOR_INFO}[M]anuel ou [S]SH ? ${COLOR_RESET}"
        read -n 1 sshType
        echo ""
        
        if [[ "${sshType,,}" == "s" ]]; then
            promptSshHost "Host : " host
        else
            promptWithCompletion "User : " user
            promptWithCompletion "Host : " host
            host="${user}@${host}"
        fi
        
        promptWithCompletion "Chemin : " path
        source="${host}:${path}"
        
        host=""
        user=""
        path=""
        
        echo ""
        printInfo "DESTINATION"
        echo -ne "${COLOR_INFO}[M]anuel ou [S]SH ? ${COLOR_RESET}"
        read -n 1 sshType
        echo ""
        
        if [[ "${sshType,,}" == "s" ]]; then
            promptSshHost "Host : " host
        else
            promptWithCompletion "User : " user
            promptWithCompletion "Host : " host
            host="${user}@${host}"
        fi
        
        promptWithCompletion "Chemin : " path
        dest="${host}:${path}"
    fi
    
    local cmd="rsync -avz"
    [[ "${showProgress,,}" == "o" ]] && cmd="$cmd --progress"
    [[ "${deleteFiles,,}" == "o" ]] && cmd="$cmd --delete"
    cmd="$cmd $source $dest"
    
    echo ""
    printSuccess "Commande générée :"
    echo -e "  ${COLOR_MENU}$cmd${COLOR_RESET}"
    echo ""
    
    echo -ne "${COLOR_INFO}Exécuter ? (o/n) : ${COLOR_RESET}"
    read -n 1 execute
    echo ""
    
    if [[ "${execute,,}" == "o" ]]; then
        echo ""
        printInfo "Exécution..."
        eval "$cmd"
        [[ $? -eq 0 ]] && printSuccess "Terminé" || printError "Erreur"
    fi
    
    showSubMenu
}

# Exit program
exitProgram() {
    echo ""
    printSuccess "Au revoir!"
    exit 0
}