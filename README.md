# ubutils

Script bash interactif pour faciliter les transferts de fichiers via SCP et Rsync avec une interface colorée et intuitive.

## Fonctionnalités

- **Gestion de profil** : Configuration du prénom utilisateur
- **SCP** : Transfert sécurisé de fichiers
  - Local → Distant
  - Distant → Local
  - Distant → Distant
- **Rsync** : Synchronisation incrémentale de fichiers
  - Options : progression, suppression fichiers absents
  - Support des 3 types de transferts
- **Support SSH config** : Utilisation des hosts configurés dans `~/.ssh/config`
- **Interface colorée** : Messages d’info, succès, warning, erreur
- **Autocomplétion** : Fichiers/dossiers avec Tab
- **Sélection interactive** : Liste numérotée ou fzf pour les hosts SSH

## Structure du projet

```
my-package/
├── install.sh          # Script d'installation
├── uninstall.sh        # Script de désinstallation
└── src/
    ├── main.sh         # Point d'entrée principal
    ├── config.sh       # Gestion de la configuration
    ├── constants.sh    # Constantes et structure du menu
    ├── printers.sh     # Fonctions d'affichage coloré
    └── menu_options.sh # Fonctions des options du menu
```

## Installation

```bash
chmod +x install.sh
./install.sh
```

Le package s’installe dans :

- **Exécutable** : `~/.local/bin/my-package`
- **Fichiers** : `~/.local/share/my-package/`
- **Config** : `~/.config/my-package/config.conf`

### Ajouter au PATH

Si `~/.local/bin` n’est pas dans votre PATH, ajoutez à `~/.bashrc` ou `~/.zshrc` :

```bash
export PATH="$HOME/.local/bin:$PATH"
```

## Utilisation

### Mode production

```bash
my-package
```

### Mode développement

```bash
MODE=dev ./src/main.sh
```

En mode dev, le fichier de configuration est créé dans `./config.conf` au lieu de `~/.config/`.

## Menu principal

```
1. Afficher le profil
2. Modifier le prénom
3. SCP - Transfert sécurisé
4. Rsync - Synchronisation
5. Quitter
```

## Exemples d’utilisation

### SCP - Envoyer un fichier

1. Choisir option 3 (SCP)
1. Sélectionner type 1 (Local → Distant)
1. Saisir le fichier local : `document.pdf`
1. Choisir SSH config ou manuel
1. Saisir le chemin distant : `/home/user/documents/`
1. Confirmer l’exécution

**Commande générée** : `scp -r document.pdf myserver:/home/user/documents/`

### Rsync - Synchroniser un dossier

1. Choisir option 4 (Rsync)
1. Activer la progression : `o`
1. Activer suppression fichiers absents : `o`
1. Sélectionner type 1 (Local → Distant)
1. Saisir source : `./project/`
1. Saisir destination : `/var/www/html/`

**Commande générée** : `rsync -avz --progress --delete ./project/ myserver:/var/www/html/`

## Configuration SSH

Pour utiliser les hosts SSH configurés, créez ou éditez `~/.ssh/config` :

```
Host myserver
    HostName 192.168.1.100
    User admin
    Port 22
    IdentityFile ~/.ssh/id_rsa

Host prod
    HostName example.com
    User deploy
```

Le script détectera automatiquement ces hosts et les proposera en sélection.

## Désinstallation

```bash
chmod +x uninstall.sh
./uninstall.sh
```

Supprime :

- L’exécutable
- Les fichiers du package
- Le fichier de configuration

## Développement

### Modifier le nom du package

Éditer `src/config.sh` :

```bash
PACKAGE_NAME="mon-nouveau-nom"
```

### Ajouter une option au menu

1. **Ajouter dans `src/constants.sh`** :

```bash
declare -A MENU_OPTIONS=(
    ...
    [6]="Nouvelle option"
)

declare -A MENU_CALLBACKS=(
    ...
    [6]="maNouvelleFonction"
)
```

1. **Créer la fonction dans `src/menu_options.sh`** :

```bash
maNouvelleFonction() {
    echo ""
    printInfo "Ma nouvelle fonctionnalité"
    # Votre code ici
    showSubMenu
}
```

1. **Réinstaller** :

```bash
./install.sh
```

## Dépendances optionnelles

- **fzf** : Pour une sélection interactive des hosts SSH (recommandé)
  
  ```bash
  # Ubuntu/Debian
  sudo apt install fzf
  
  # MacOS
  brew install fzf
  ```

## Compatibilité

- Bash 4.0+
- Linux, MacOS, WSL
- SSH client installé pour SCP/Rsync

## Sécurité

- Les commandes générées sont affichées avant exécution
- Validation des chemins lors de l’installation/désinstallation
- Pas d’utilisation de `sudo`
- Chemins d’installation dans le home utilisateur

## License

MIT

## Auteur

Votre nom