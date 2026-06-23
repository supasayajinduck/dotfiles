#!/bin/bash

echo "🚀 Démarrage de l'installation des Dotfiles..."

# 1. On s'assure qu'on est dans le répertoire personnel
cd ~

# 2. On copie (ou on met à jour) ton fichier personnel caché à la racine
cp dotfiles/.mon_prompt ~/.mon_prompt
echo "✅ Fichier .mon_prompt copié."

# 3. La vérification de sécurité (idempotence)
# On cherche le mot "source ~/.mon_prompt" dans le .bashrc en mode silencieux (-q)
if grep -q "source ~/.mon_prompt" ~/.bashrc; then
    echo "⏭️  Le .bashrc est déjà configuré, on ne touche à rien."
else
    # Si le texte n'y est pas, on l'ajoute proprement à la fin
    echo "" >> ~/.bashrc
    echo "# Chargement de la configuration Masten (GitHub)" >> ~/.bashrc
    echo "source ~/.mon_prompt" >> ~/.bashrc
    echo "✅ Configuration injectée dans le .bashrc."
fi

echo "🎉 Installation terminée ! Tape 'source ~/.bashrc' pour appliquer."
