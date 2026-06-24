#!/bin/bash

echo "🚀 Démarrage de l'installation des Dotfiles (Multi-Distributions)..."

# 1. On se place à la racine
cd ~

# 2. On copie le fichier d'alias
cp dotfiles/.bash_aliases ~/.bash_aliases
echo "✅ Fichier .bash_aliases mis en place."

# 3. Le test de compatibilité multi-OS
# On cherche si le mot ".bash_aliases" existe déjà dans le .bashrc
if grep -q "\.bash_aliases" ~/.bashrc; then
    echo "⏭️  Support natif détecté (ex: Ubuntu/Debian). Aucune modification du .bashrc requise."
else
    # Si introuvable (ex: Rocky Linux, Arch), on injecte le standard Debian à la fin
    echo "" >> ~/.bashrc
    echo "# Chargement des alias personnalisés (Dotfiles)" >> ~/.bashrc
    echo "if [ -f ~/.bash_aliases ]; then" >> ~/.bashrc
    echo "    . ~/.bash_aliases" >> ~/.bashrc
    echo "fi" >> ~/.bashrc
    echo "✅ Injection du code de chargement dans le .bashrc (Mode Red Hat/Rocky)."
fi

echo "🎉 Installation terminée ! Tape 'source ~/.bashrc' pour appliquer."
