#!/bin/bash

echo "🚀 Démarrage de l'installation des Dotfiles (Méthode Native Debian)..."

# 1. On s'assure qu'on est à la racine de l'utilisateur
cd ~

# 2. On écrase l'ancien fichier local par la nouvelle version de ton GitHub
cp dotfiles/.bash_aliases ~/.bash_aliases

echo "✅ Fichier .bash_aliases mis en place avec succès."
echo "🎉 Installation terminée ! Le système Debian s'occupe du reste."
echo "🔄 Tape 'source ~/.bashrc' pour recharger l'environnement."
