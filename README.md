# Linux Dotfiles

Configuration personnelle permettant de préparer rapidement un environnement Linux orienté administration système.

Le dépôt installe un ensemble d’outils courants et déploie les configurations Bash, Tmux et Vim à l’aide de liens symboliques.

## Objectifs

Ce projet permet de :

- préparer rapidement une nouvelle VM Linux ;
- installer un socle commun d’outils en ligne de commande ;
- installer un profil complémentaire orienté administration système ;
- conserver une configuration cohérente entre plusieurs machines ;
- sauvegarder les fichiers existants avant leur remplacement ;
- mettre à jour les configurations avec Git ;
- désinstaller proprement les configurations déployées.

## Distributions prises en charge

Le script prend actuellement en charge :

- Debian ;
- Ubuntu ;
- Rocky Linux.

La distribution est détectée automatiquement à partir du fichier :

```text
/etc/os-release
```

Les autres distributions Linux ne sont pas prises en charge pour le moment.

## Principe de fonctionnement

Le dépôt est cloné par convention dans :

```text
~/.dotfiles
```

Le script crée ensuite les liens symboliques suivants :

```text
~/.bash_aliases -> ~/.dotfiles/config/bash/.bash_aliases
~/.tmux.conf     -> ~/.dotfiles/config/tmux/.tmux.conf
~/.vimrc         -> ~/.dotfiles/config/vim/.vimrc
```

Un bloc géré est également ajouté dans `~/.bashrc` afin de charger automatiquement `.bash_aliases`.

L’utilisation de liens symboliques permet d’appliquer immédiatement les modifications apportées aux fichiers du dépôt après un `git pull`.

## Structure du dépôt

```text
.
├── .github/
│   └── workflows/
│       └── shellcheck.yml
├── config/
│   ├── bash/
│   │   └── .bash_aliases
│   ├── tmux/
│   │   └── .tmux.conf
│   └── vim/
│       └── .vimrc
├── .gitignore
├── install.sh
├── uninstall.sh
└── README.md
```

## Configurations incluses

### Bash

La configuration Bash comprend notamment :

- un prompt distinct pour root et les utilisateurs standards ;
- des alias de navigation ;
- des alias Git ;
- des alias Tmux ;
- des commandes d’administration et de diagnostic ;
- des raccourcis pour `systemctl` et `journalctl` ;
- des commandes d’affichage réseau et système.

Une session root est volontairement mise en évidence en rouge afin de réduire le risque d’exécuter une commande privilégiée par inadvertance.

### Tmux

La configuration Tmux comprend notamment :

- le préfixe standard `Ctrl+B` ;
- la prise en charge de la souris ;
- un historique étendu ;
- une numérotation des fenêtres à partir de 1 ;
- la conservation du répertoire courant dans les nouveaux panneaux ;
- des raccourcis de navigation inspirés de Vim ;
- une confirmation avant la fermeture d’une fenêtre ou d’un panneau ;
- une barre de statut affichant la session, la machine et l’heure.

### Vim

La configuration Vim comprend notamment :

- la coloration syntaxique ;
- les numéros de ligne absolus et relatifs ;
- une recherche améliorée ;
- une indentation adaptée au type de fichier ;
- la mise en évidence des espaces de fin de ligne ;
- une annulation persistante ;
- des raccourcis pour les buffers et les fenêtres ;
- des protections supplémentaires pour les fichiers sensibles ;
- une configuration sans plugin externe.

## Paquets installés

### Socle de base

L’installation standard déploie un ensemble d’outils essentiels, notamment :

- Bash completion ;
- certificats d’autorités de certification ;
- curl ;
- Git ;
- less ;
- client OpenSSH ;
- rsync ;
- sudo ;
- Tmux ;
- tree ;
- unzip ;
- Vim ;
- wget ;
- zip.

Les noms exacts des paquets sont automatiquement adaptés à la distribution.

Par exemple :

- `openssh-client` sur Debian et Ubuntu ;
- `openssh-clients` sur Rocky Linux ;
- `vim` sur Debian et Ubuntu ;
- `vim-enhanced` sur Rocky Linux.

### Profil administrateur

Le profil administrateur ajoute, lorsque les paquets sont disponibles :

- les outils DNS ;
- htop ;
- iftop ;
- iotop ;
- jq ;
- lsof ;
- ncdu ;
- Netcat ;
- Nmap ;
- ripgrep ;
- ShellCheck sur Debian et Ubuntu ;
- sysstat ;
- traceroute.

Certains outils peuvent ne pas être disponibles dans les dépôts standards de Rocky Linux.

Le script n’active volontairement aucun dépôt supplémentaire comme EPEL. Les paquets administratifs indisponibles sont ignorés et affichés dans le résumé final.

## Prérequis

Pour récupérer le dépôt, la machine doit disposer de :

- Git ;
- certificats d’autorités de certification ;
- un accès HTTPS à GitHub ;
- un compte autorisé à utiliser `sudo`, sauf si l’installation est effectuée directement avec root.

Git et les certificats peuvent être installés à l’aide des commandes de bootstrap présentées ci-dessous.

## Installation rapide

### Debian et Ubuntu

Sur une nouvelle machine Debian ou Ubuntu :

```bash
sudo apt-get update &&
sudo apt-get install -y git ca-certificates &&
git clone https://github.com/supasayajinduck/dotfiles.git ~/.dotfiles &&
bash ~/.dotfiles/install.sh --all
```

### Rocky Linux

Sur une nouvelle machine Rocky Linux :

```bash
sudo dnf install -y git ca-certificates &&
git clone https://github.com/supasayajinduck/dotfiles.git ~/.dotfiles &&
bash ~/.dotfiles/install.sh --all
```

> Avant d’exécuter un script récupéré depuis Internet, examine toujours son contenu.

## Installation manuelle

### 1. Installer les prérequis

#### Debian et Ubuntu

```bash
sudo apt-get update
sudo apt-get install -y git ca-certificates
```

#### Rocky Linux

```bash
sudo dnf install -y git ca-certificates
```

### 2. Cloner le dépôt

```bash
git clone https://github.com/supasayajinduck/dotfiles.git ~/.dotfiles
```

### 3. Vérifier le contenu du script

```bash
less ~/.dotfiles/install.sh
```

Tu peux aussi utiliser GitHub pour examiner les modifications et l’historique du fichier avant son exécution.

### 4. Simuler l’installation

```bash
bash ~/.dotfiles/install.sh --all --dry-run
```

Cette commande affiche les actions prévues sans modifier le système.

### 5. Lancer l’installation

Pour installer le socle de base :

```bash
bash ~/.dotfiles/install.sh
```

Pour installer le profil administrateur :

```bash
bash ~/.dotfiles/install.sh --admin
```

Pour installer toutes les catégories disponibles :

```bash
bash ~/.dotfiles/install.sh --all
```

### 6. Charger la configuration Bash

Ouvre un nouveau terminal ou exécute :

```bash
source ~/.bashrc
```

## Options d’installation

### Afficher l’aide

```bash
bash ~/.dotfiles/install.sh --help
```

### Installer le socle de base

```bash
bash ~/.dotfiles/install.sh
```

Cette commande :

- installe les paquets de base ;
- déploie les configurations Bash, Tmux et Vim.

### Installer le profil administrateur

```bash
bash ~/.dotfiles/install.sh --admin
```

Cette commande :

- installe les paquets de base ;
- installe les outils administratifs disponibles ;
- déploie les configurations.

### Installer toutes les catégories

```bash
bash ~/.dotfiles/install.sh --all
```

Pour le moment, `--all` active le profil administrateur.

Cette option est conservée séparément afin de pouvoir ajouter ultérieurement d’autres profils, par exemple :

```text
--dev
--modern
--docker
```

### Afficher la liste des paquets

Pour le socle de base :

```bash
bash ~/.dotfiles/install.sh --list-packages
```

Pour le profil administrateur :

```bash
bash ~/.dotfiles/install.sh --admin --list-packages
```

Cette option affiche les paquets prévus sans les installer.

### Simuler l’installation

```bash
bash ~/.dotfiles/install.sh --all --dry-run
```

Le mode simulation n’applique aucune modification.

La disponibilité réelle des paquets optionnels n’est cependant pas vérifiée dans ce mode.

### Installer uniquement les paquets

```bash
bash ~/.dotfiles/install.sh --admin --packages-only
```

Les liens symboliques et `.bashrc` ne sont pas modifiés.

### Installer uniquement les configurations

```bash
bash ~/.dotfiles/install.sh --dotfiles-only
```

Aucun paquet système n’est installé.

## Avertissement concernant `sudo`

Ne lance pas le script d’installation de cette manière :

```bash
sudo bash ~/.dotfiles/install.sh --all
```

Cela pourrait cibler le répertoire personnel de root au lieu de celui de l’utilisateur courant.

Utilise toujours :

```bash
bash ~/.dotfiles/install.sh --all
```

Le script appelle automatiquement `sudo` uniquement lorsque des privilèges élevés sont nécessaires pour installer les paquets.

Le script refuse une exécution lancée avec `sudo` lorsqu’il détecte la variable `SUDO_USER`.

## Sauvegardes

Lorsqu’un fichier cible existe déjà, le programme le sauvegarde avant de créer le lien symbolique.

Les sauvegardes sont stockées dans :

```text
~/.dotfiles-backup/
```

Chaque installation utilise un répertoire horodaté :

```text
~/.dotfiles-backup/20260824-140700/
```

Une sauvegarde peut contenir :

```text
.bash_aliases
.bashrc
.tmux.conf
.vimrc
```

Le répertoire de sauvegarde n’est créé que lorsqu’un fichier existant doit réellement être remplacé.

## Sécurité

Le programme applique plusieurs contrôles avant de modifier les fichiers :

- les sources doivent appartenir au dépôt ;
- les cibles doivent se trouver sous le répertoire personnel ;
- le répertoire personnel lui-même ne peut pas être remplacé ;
- la racine du système ne peut pas être modifiée ;
- les chemins contenant une traversée avec `..` sont refusés ;
- un répertoire existant n’est jamais supprimé automatiquement ;
- les fichiers existants sont sauvegardés avant leur remplacement ;
- les commandes de suppression récursive ne sont pas utilisées.

Le dépôt ne doit jamais contenir :

- de clé privée SSH ;
- de token GitHub ;
- de mot de passe ;
- de fichier `.env` contenant des valeurs réelles ;
- de certificat privé ;
- d’identifiant d’entreprise ;
- de fichier d’historique du shell.

Le fichier `.gitignore` réduit le risque d’ajout accidentel, mais il ne remplace pas une vérification humaine.

## Mise à jour

Pour récupérer les modifications du dépôt :

```bash
git -C ~/.dotfiles pull --ff-only
```

L’alias suivant est également disponible après installation :

```bash
dotfiles-update
```

Les fichiers liés sont mis à jour immédiatement après le `git pull`.

Pour appliquer une modification affectant les paquets ou le bloc géré dans `.bashrc`, relance le programme :

```bash
bash ~/.dotfiles/install.sh --all
```

Puis recharge Bash :

```bash
source ~/.bashrc
```

## Utilisation de Tmux

Créer une session :

```bash
tmux new-session -s admin
```

Détacher la session sans la fermer :

```text
Ctrl+B puis d
```

Afficher les sessions :

```bash
tmux list-sessions
```

Reprendre la session :

```bash
tmux attach-session -t admin
```

Recharger la configuration Tmux :

```text
Ctrl+B puis r
```

## Utilisation de Vim

La touche leader est la barre d’espace.

Quelques raccourcis disponibles :

```text
Espace puis s       Enregistrer
Espace puis q       Quitter
Espace puis x       Enregistrer et quitter
Espace puis r       Recharger la configuration
Espace puis l       Afficher les caractères invisibles
Espace puis w       Activer ou désactiver le retour à la ligne
Espace puis sh      Créer une fenêtre horizontale
Espace puis sv      Créer une fenêtre verticale
```

## Désinstallation

### Simuler une désinstallation

```bash
bash ~/.dotfiles/uninstall.sh --dry-run
```

### Désinstaller les configurations

```bash
bash ~/.dotfiles/uninstall.sh
```

Cette commande :

- supprime uniquement les liens pointant vers le dépôt courant ;
- retire le bloc géré dans `.bashrc` ;
- sauvegarde `.bashrc` avant de le modifier ;
- conserve les paquets installés ;
- conserve le dépôt ;
- conserve les sauvegardes existantes.

### Afficher les sauvegardes disponibles

```bash
bash ~/.dotfiles/uninstall.sh --list-backups
```

### Désinstaller et restaurer une sauvegarde

```bash
bash ~/.dotfiles/uninstall.sh \
    --restore-backup ~/.dotfiles-backup/20260824-140700
```

La sauvegarde doit être sélectionnée explicitement.

Le programme ne choisit pas automatiquement la sauvegarde la plus récente, car elle ne correspond pas nécessairement à la configuration que tu souhaites restaurer.

### Supprimer ensuite le dépôt

Après avoir désinstallé les configurations et vérifié le résultat :

```bash
rm -rf ~/.dotfiles
```

Cette suppression est volontairement laissée à l’utilisateur.

Avant de l’exécuter, vérifie le chemin :

```bash
realpath ~/.dotfiles
```

## Validation automatique

GitHub Actions vérifie automatiquement les scripts lors :

- d’un push vers `main` ;
- d’une pull request vers `main` ;
- d’un lancement manuel du workflow.

Le workflow applique :

```bash
bash -n install.sh
bash -n uninstall.sh
```

puis :

```bash
shellcheck \
    --shell=bash \
    --severity=style \
    install.sh \
    uninstall.sh
```

Ces contrôles recherchent les erreurs de syntaxe et plusieurs catégories de problèmes courants dans les scripts Bash.

Une validation statique réussie ne remplace pas les tests sur les distributions cibles.

## Procédure de test recommandée

Avant d’utiliser une nouvelle version sur une VM importante, effectue les tests sur une VM temporaire.

### 1. Vérifier la liste des paquets

```bash
bash ~/.dotfiles/install.sh --admin --list-packages
```

### 2. Simuler l’installation

```bash
bash ~/.dotfiles/install.sh --all --dry-run
```

### 3. Exécuter l’installation

```bash
bash ~/.dotfiles/install.sh --all
```

### 4. Relancer l’installation

```bash
bash ~/.dotfiles/install.sh --all
```

Cette seconde exécution permet de vérifier l’idempotence du programme.

Le résultat attendu est notamment :

- aucun bloc dupliqué dans `.bashrc` ;
- aucun lien symbolique recréé inutilement ;
- aucune sauvegarde inutile ;
- aucune erreur liée à un fichier déjà présent.

### 5. Vérifier les liens

```bash
readlink -f ~/.bash_aliases
readlink -f ~/.tmux.conf
readlink -f ~/.vimrc
```

Les chemins doivent pointer vers les fichiers correspondants dans :

```text
~/.dotfiles/config/
```

### 6. Vérifier Bash

```bash
source ~/.bashrc
type dotfiles-update
type gs
type ports
```

### 7. Vérifier Tmux

```bash
tmux new-session -s test
```

Contrôle notamment :

- la barre de statut ;
- la souris ;
- la création des panneaux ;
- le rechargement avec `Ctrl+B`, puis `r`.

### 8. Vérifier Vim

```bash
vim ~/.dotfiles/install.sh
```

Dans Vim :

```vim
:set number?
:set relativenumber?
:set expandtab?
:set undofile?
```

### 9. Simuler la désinstallation

```bash
bash ~/.dotfiles/uninstall.sh --dry-run
```

### 10. Désinstaller

```bash
bash ~/.dotfiles/uninstall.sh
```

### 11. Vérifier le résultat

```bash
ls -la ~/.bash_aliases ~/.tmux.conf ~/.vimrc
grep -F "dotfiles managed block" ~/.bashrc
```

L’absence des fichiers après désinstallation est normale si aucune sauvegarde n’a été restaurée.

## Limites connues

### Rocky Linux et EPEL

Certains outils administratifs peuvent nécessiter EPEL sur Rocky Linux.

Le programme n’active pas automatiquement ce dépôt. Les paquets indisponibles sont ignorés et indiqués dans le résumé.

### Terminal Tmux

La configuration utilise :

```text
tmux-256color
```

Une image Linux très minimale pourrait ne pas disposer de la définition Terminfo correspondante.

En cas d’erreur, la valeur de repli à tester dans `.tmux.conf` est :

```text
screen-256color
```

### Fichiers swap Vim

Les fichiers swap Vim sont actuellement désactivés.

Cela évite de laisser des fichiers temporaires à côté des fichiers administrés, mais réduit les possibilités de récupération après une interruption brutale.

L’historique d’annulation persistant est stocké dans :

```text
~/.cache/vim/undo/
```

### Presse-papiers Vim

Le presse-papiers système est activé uniquement si la version installée de Vim prend en charge cette fonctionnalité.

Sur une VM distante sans environnement graphique, le presse-papiers local du poste utilisateur reste généralement géré par le terminal SSH.

### Tests multi-distributions

Le workflow actuel effectue une analyse statique sur Ubuntu.

Il ne lance pas encore de test réel dans des conteneurs Debian, Ubuntu et Rocky Linux.

## Développement depuis GitHub

Les fichiers peuvent être créés et modifiés directement depuis l’interface web GitHub.

Pour un changement important, le processus recommandé est :

1. créer une branche ;
2. modifier les fichiers ;
3. vérifier l’aperçu des changements ;
4. créer un commit explicite ;
5. ouvrir une pull request ;
6. attendre la réussite du workflow ;
7. examiner les différences ;
8. fusionner dans `main` ;
9. tester sur une VM temporaire.

Exemples de messages de commit :

```text
feat: add bash aliases and dynamic prompt
feat: add tmux administration configuration
feat: add vim administration configuration
feat: add secure multi-distribution installer
feat: add safe dotfiles uninstaller
ci: add ShellCheck workflow
docs: update installation documentation
fix: validate symlink targets before removal
```

## Roadmap

Évolutions envisagées :

- tests automatisés sur Debian, Ubuntu et Rocky Linux ;
- activation optionnelle d’EPEL ;
- profil de développement ;
- profil d’outils modernes ;
- configuration Git générique et fichier local ;
- contrôle du formatage avec `shfmt` ;
- détection automatisée de secrets ;
- prise en charge optionnelle de Docker ;
- prise en charge d’autres distributions Linux.

## Contribution

Les changements doivent rester :

- simples ;
- lisibles ;
- idempotents ;
- compatibles avec les distributions annoncées ;
- sans secrets ;
- sans dépendance externe non justifiée ;
- validés par ShellCheck ;
- testés sur une VM non critique avant utilisation.

## Avertissement

Ce dépôt modifie des fichiers dans le répertoire personnel et installe des paquets système.

Examine toujours les scripts avant leur exécution et teste les changements sur une machine temporaire avant de les appliquer à un environnement important.
