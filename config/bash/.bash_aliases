###############################################################################
# Dotfiles Bash aliases
#
# Description :
#   Configuration interactive Bash destinée aux environnements Linux
#   Debian, Ubuntu et Rocky Linux.
#
# Important :
#   Ce fichier ne doit contenir aucun secret, mot de passe, token ou
#   paramètre propre à une entreprise.
###############################################################################

###############################################################################
# Vérification du shell interactif
###############################################################################

# Ne pas charger les alias et le prompt dans un shell non interactif.
case $- in
    *i*) ;;
    *) return ;;
esac

###############################################################################
# Prompt dynamique
###############################################################################

# Le prompt permet de distinguer immédiatement :
#   - une session root, affichée en rouge ;
#   - une session utilisateur standard, affichée en cyan.
#
# Structure :
#   utilisateur@machine:répertoire$

if [[ ${EUID:-$(id -u)} -eq 0 ]]; then
    # Alerte visuelle root.
    PS1='\[\033[01;31m\]\u\[\033[00m\]@\[\033[01;32m\]\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[01;31m\]#\[\033[00m\] '
else
    #[00m\ Session utilisateur standard.
    PS1='\[\033[01;36m\]\u\[\033[00m\]@\[\033[01;32m\]\h\[\033[00m\]:\[\033[01;34m\]\w\[00m\]\$ '
fi

###############################################################################
# Navigation
###############################################################################

alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'

###############################################################################
# Affichage des fichiers
###############################################################################

# Les options utilisées ici sont compatibles avec GNU ls, présent sur
# Debian, Ubuntu et Rocky Linux.
alias ls='ls --color=auto'
alias ll='ls -laht --group-directories-first --color=auto'
alias la='ls -A --color=auto'
alias l='ls -CF --color=auto'

# Affichage d'une arborescence avec une profondeur limitée.
alias tree1='tree -L 1'
alias tree2='tree -L 2'
alias tree3='tree -L 3'

###############################################################################
# Recherche et lecture
###############################################################################

alias grep='grep --color=auto'
alias egrep='grep -E --color=auto'
alias fgrep='grep -F --color=auto'

# Recherche insensible à la casse dans l'historique Bash.
alias hgrep='history | grep -i'

###############################################################################
# Espace disque
###############################################################################

# Afficher les systèmes de fichiers avec leur type.
alias dfh='df -hT'

# Afficher la taille totale du répertoire courant.
alias duh='du -sh'

# Classer les éléments du répertoire courant par taille.
alias dus='du -sh -- * 2>/dev/null | sort -h'

###############################################################################
# Processus et ressources système
###############################################################################

# Affichage lisible de la mémoire.
alias meminfo='free -h'

# Afficher les processus sous forme d'arborescence.
alias pst='ps auxf'

# Rechercher un processus par nom.
alias psg='ps aux | grep -i'

###############################################################################
# Réseau
###############################################################################

# Afficher les adresses IP de la machine.
alias myip='hostname -I'

# Afficher les interfaces réseau.
alias interfaces='ip -brief address'

# Afficher la table de routage.
alias routes='ip route'

# Afficher les sockets TCP et UDP en écoute.
alias ports='ss -tulpn'

# Afficher uniquement les ports TCP en écoute.
alias tcpports='ss -ltnp'

# Afficher uniquement les ports UDP en écoute.
alias udpports='ss -lunp'

###############################################################################
# Services et journaux systemd
###############################################################################

# Ces alias sont destinés aux distributions utilisant systemd.
alias sc='systemctl'
alias scu='systemctl --user'
alias jc='journalctl'
alias jcf='journalctl -f'
alias jcxe='journalctl -xe'

###############################################################################
# Git
###############################################################################

alias gs='git status'
alias ga='git add'
alias gaa='git add --all'
alias gb='git branch'
alias gc='git commit'
alias gd='git diff'
alias gds='git diff --staged'
alias gl='git log --oneline --graph --decorate --all'
alias gp='git pull --ff-only'
alias gpush='git push'

# Mise à jour du dépôt de dotfiles.
alias dotfiles-update='git -C "${HOME}/.dotfiles" pull --ff-only'

# Afficher le statut du dépôt de dotfiles.
alias dotfiles-status='git -C "${HOME}/.dotfiles" status'

###############################################################################
# Tmux
###############################################################################

alias tls='tmux list-sessions'
alias ta='tmux attach-session'
alias tn='tmux new-session -s'

###############################################################################
# Archives
###############################################################################

alias targz='tar -czvf'
alias untargz='tar -xzvf'

###############################################################################
# Chemins et informations système
###############################################################################

# Afficher chaque entrée de PATH sur une ligne séparée.
alias path='printf "%s\n" "${PATH//:/$'\''\n'\''}"'

# Afficher les informations principales du système.
alias sysinfo='printf "Hostname : %s\nKernel   : %s\nOS       : " "$(hostname)" "$(uname -r)"; grep "^PRETTY_NAME=" /etc/os-release | cut -d= -f2- | tr -d "\""'

###############################################################################
# Rechargement de la configuration
###############################################################################

alias reload-bash='source "${HOME}/.bashrc"'
