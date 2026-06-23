# dotfiles

Configuration personnelle pour environnement Linux. Ce dépôt contient tous les fichiers de configuration (dotfiles) nécessaires pour configurer rapidement une nouvelle VM Linux avec mon setup habituel.

## 📋 Table des matières

- [À propos](#à-propos)
- [Prérequis](#prérequis)
- [Installation](#installation)
- [Fichiers configurés](#fichiers-configurés)
- [Utilisation](#utilisation)

## À propos

Ce dépôt regroupe les configurations personnalisées pour :
- Shell (bashrc, zshrc, etc.)
- Éditeurs de texte et IDE
- Outils de développement
- Alias et variables d'environnement
- Autres fichiers de configuration système

L'objectif est de pouvoir cloner ce dépôt et lancer un script d'installation pour automatiser la mise en place de l'environnement.

## Prérequis

Avant de lancer l'installation, assurez-vous d'avoir :
- Une distribution Linux (Ubuntu, Debian, Fedora, etc.)
- Git installé sur votre système
- Accès en lecture au dépôt (SSH key configurée ou accès HTTPS)

## Installation

Suivez les étapes ci-dessous pour installer et configurer votre environnement :

### Étape 1 : Cloner le dépôt

```bash
git clone https://github.com/supasayajinduck/dotfiles.git
```

Cette commande télécharge une copie locale de tous les fichiers de configuration du dépôt dans un dossier nommé `dotfiles`.

### Étape 2 : Rendre le script exécutable

```bash
chmod +x dotfiles/install.sh
```

La commande `chmod +x` modifie les permissions du fichier `install.sh` pour le rendre exécutable. Sans cette étape, vous ne pourrez pas lancer le script directement.

### Étape 3 : Lancer le script d'installation

```bash
./dotfiles/install.sh
```

Le script exécute automatiquement tous les liens symboliques (symlinks) et les configurations nécessaires pour mettre en place votre environnement personnel.

> ⚠️ **Attention** : Vérifiez le contenu du script avant de l'exécuter, particulièrement s'il provient d'une source externe, pour des raisons de sécurité.

## Fichiers configurés

Le dépôt gère les configurations suivantes :

- `~/.bashrc` - Configuration du shell Bash
- `~/.zshrc` - Configuration du shell Zsh
- `~/.config/` - Fichiers de configuration d'applications modernes
- Et d'autres fichiers selon vos besoins

## Utilisation

Après l'installation, les configurations seront automatiquement appliquées. Pour bénéficier des changements, rechargez votre shell :

```bash
source ~/.bashrc
# ou
source ~/.zshrc
```

## 📝 Notes

- Sauvegardez vos configurations existantes avant de lancer l'installation
- Le script peut créer des liens symboliques vers vos anciens fichiers
- Pour mettre à jour les configurations, faites un `git pull` dans le dossier dotfiles

## Support

Pour toute question ou problème, consultez le dépôt ou contactez le mainteneur.
