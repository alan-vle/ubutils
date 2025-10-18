#!/bin/bash

# Menu options structure
declare -A MENU_OPTIONS=(
    [1]="Afficher le profil"
    [2]="Modifier le prénom"
    [3]="SCP - Transfert sécurisé"
    [4]="Rsync - Synchronisation"
    [5]="Quitter"
)

declare -A MENU_CALLBACKS=(
    [3]="showScpInfo"
    [4]="showRsyncInfo"
    [5]="exitProgram"
)