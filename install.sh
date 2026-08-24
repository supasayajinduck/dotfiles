#!/usr/bin/env bash

###############################################################################
# Dotfiles installer
#
# Distributions prises en charge :
#   - Debian
#   - Ubuntu
#   - Rocky Linux
#
# Exécution :
#   bash install.sh
#   bash install.sh --admin
#   bash install.sh --all
#   bash install.sh --all --dry-run
###############################################################################

set -Eeuo pipefail

###############################################################################
# Variables globales
###############################################################################

readonly SCRIPT_NAME
readonly SCRIPT_DIR
readonly TIMESTAMP
readonly BACKUP_ROOT
readonly BACKUP_DIR

SCRIPT_NAME="$(basename -- "$0")"
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
TIMESTAMP="$(date +'%Y%m%d-%H%M%S')"
BACKUP_ROOT="${HOME}/.dotfiles-backup"
BACKUP_DIR="${BACKUP_ROOT}/${TIMESTAMP}"

DISTRO_ID=""
DISTRO_NAME=""
DISTRO_FAMILY=""
PACKAGE_MANAGER=""

INSTALL_PACKAGES=true
INSTALL_DOTFILES=true
INSTALL_ADMIN=false
INSTALL_ALL=false
DRY_RUN=false
LIST_PACKAGES=false

DOTFILES_ONLY_SELECTED=false
PACKAGES_ONLY_SELECTED=false
BACKUP_CREATED=false

AVAILABLE_ADMIN_PACKAGES=()
UNAVAILABLE_ADMIN_PACKAGES=()

###############################################################################
# Paquets Debian et Ubuntu
###############################################################################

DEBIAN_BASE_PACKAGES=(
    bash-completion
    ca-certificates
    curl
    git
    less
    openssh-client
    rsync
    sudo
    tmux
    tree
    unzip
    vim
    wget
    zip
)

DEBIAN_ADMIN_PACKAGES=(
    dnsutils
    htop
    iftop
    iotop
    jq
    lsof
    ncdu
    netcat-openbsd
    nmap
    ripgrep
    shellcheck
    sysstat
    traceroute
)

###############################################################################
# Paquets Rocky Linux
###############################################################################

ROCKY_BASE_PACKAGES=(
    bash-completion
    ca-certificates
    curl
    git
    less
    openssh-clients
    rsync
    sudo
    tmux
    tree
    unzip
    vim-enhanced
    wget
    zip
)

ROCKY_ADMIN_PACKAGES=(
    bind-utils
    htop
    iftop
    iotop
    jq
    lsof
    ncdu
    nmap
    nmap-ncat
    ripgrep
    sysstat
    traceroute
)

###############################################################################
# Affichage
###############################################################################

log_info() {
    printf '\033[1;34m[INFO]\033[0m %s\n' "$*"
}

log_success() {
    printf '\033[1;32m[OK]\033[0m %s\n' "$*"
}

log_warning() {
    printf '\033[1;33m[WARN]\033[0m %s\n' "$*"
}

log_error() {
    printf '\033[1;31m[ERROR]\033[0m %s\n' "$*" >&2
}

die() {
    log_error "$*"
    exit 1
}

###############################################################################
# Gestion des erreurs
###############################################################################

on_error() {
    local exit_code="$1"
    local line_number="$2"

    log_error "Une erreur est survenue à la ligne ${line_number}."
    log_error "Code de retour : ${exit_code}"

    exit "$exit_code"
}

trap 'on_error "$?" "$LINENO"' ERR

###############################################################################
# Aide
###############################################################################

show_help() {
    cat <<EOF
Utilisation :
  bash ${SCRIPT_NAME} [OPTIONS]

Options :
  --admin           Installe le socle et les outils d'administration
  --all             Installe toutes les catégories disponibles
  --dotfiles-only   Déploie uniquement les fichiers de configuration
  --packages-only   Installe uniquement les paquets
  --list-packages   Affiche les paquets prévus sans les installer
  --dry-run         Affiche les actions sans modifier le système
  -h, --help        Affiche cette aide

Comportement par défaut :
  - installation des paquets de base ;
  - déploiement des configurations Bash, Tmux et Vim.

Exemples :
  bash ${SCRIPT_NAME}
  bash ${SCRIPT_NAME} --admin
  bash ${SCRIPT_NAME} --all
  bash ${SCRIPT_NAME} --all --dry-run
  bash ${SCRIPT_NAME} --dotfiles-only
  bash ${SCRIPT_NAME} --admin --packages-only
EOF
}

###############################################################################
# Fonctions génériques
###############################################################################

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

run_command() {
    if "$DRY_RUN"; then
        printf '[DRY-RUN]'

        printf ' %q' "$@"
        printf '\n'

        return 0
    fi

    "$@"
}

run_as_root() {
    if [[ "$EUID" -eq 0 ]]; then
        run_command "$@"
        return
    fi

    if command_exists sudo; then
        run_command sudo "$@"
        return
    fi

    die "Cette opération nécessite les privilèges root et sudo est absent."
}

###############################################################################
# Validation du contexte d'exécution
###############################################################################

validate_execution_context() {
    if [[ "$EUID" -eq 0 && -n "${SUDO_USER:-}" ]]; then
        die "Ne lance pas ce script avec sudo.

Utilise plutôt :
  bash ${SCRIPT_DIR}/${SCRIPT_NAME} --all

Le script utilisera sudo uniquement pour installer les paquets."
    fi

    [[ -n "${HOME:-}" ]] ||
        die "La variable HOME n'est pas définie."

    [[ -d "$HOME" ]] ||
        die "Le répertoire personnel n'existe pas : ${HOME}"

    [[ -r "${SCRIPT_DIR}/${SCRIPT_NAME}" ]] ||
        die "Impossible de lire le script depuis : ${SCRIPT_DIR}"

    log_info "Utilisateur cible : $(id -un)"
    log_info "Répertoire personnel : ${HOME}"
    log_info "Dépôt Dotfiles : ${SCRIPT_DIR}"
}
###############################################################################
# Arguments
###############################################################################

parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --admin)
                INSTALL_ADMIN=true
                ;;

            --all)
                INSTALL_ALL=true
                INSTALL_ADMIN=true
                ;;

            --dotfiles-only)
                DOTFILES_ONLY_SELECTED=true
                INSTALL_PACKAGES=false
                INSTALL_DOTFILES=true
                ;;

            --packages-only)
                PACKAGES_ONLY_SELECTED=true
                INSTALL_PACKAGES=true
                INSTALL_DOTFILES=false
                ;;

            --list-packages)
                LIST_PACKAGES=true
                ;;

            --dry-run)
                DRY_RUN=true
                ;;

            -h|--help)
                show_help
                exit 0
                ;;

            *)
                die "Option inconnue : $1

Utilise :
  bash ${SCRIPT_NAME} --help"
                ;;
        esac

        shift
    done

    if "$DOTFILES_ONLY_SELECTED" && "$PACKAGES_ONLY_SELECTED"; then
        die "Les options --dotfiles-only et --packages-only sont incompatibles."
    fi
}

###############################################################################
# Détection de la distribution
###############################################################################

detect_distribution() {
    [[ -r /etc/os-release ]] ||
        die "Impossible de lire /etc/os-release."

    # shellcheck disable=SC1091
    source /etc/os-release

    DISTRO_ID="${ID:-unknown}"
    DISTRO_NAME="${PRETTY_NAME:-$DISTRO_ID}"

    case "$DISTRO_ID" in
        debian|ubuntu)
            DISTRO_FAMILY="debian"
            PACKAGE_MANAGER="apt-get"
            ;;

        rocky)
            DISTRO_FAMILY="rocky"
            PACKAGE_MANAGER="dnf"
            ;;

        *)
            die "Distribution non prise en charge : ${DISTRO_NAME}

Distributions prises en charge :
  - Debian
  - Ubuntu
  - Rocky Linux"
            ;;
    esac

    log_success "Distribution détectée : ${DISTRO_NAME}"
    log_info "Gestionnaire de paquets : ${PACKAGE_MANAGER}"
}

###############################################################################
# Affichage des paquets
###############################################################################

print_package_array() {
    local title="$1"
    shift

    printf '\n%s\n' "$title"

    for package in "$@"; do
        printf '  - %s\n' "$package"
    done
}

show_selected_packages() {
    case "$DISTRO_FAMILY" in
        debian)
            print_package_array \
                "Paquets de base Debian/Ubuntu :" \
                "${DEBIAN_BASE_PACKAGES[@]}"

            if "$INSTALL_ADMIN"; then
                print_package_array \
                    "Paquets d'administration Debian/Ubuntu :" \
                    "${DEBIAN_ADMIN_PACKAGES[@]}"
            fi
            ;;

        rocky)
            print_package_array \
                "Paquets de base Rocky Linux :" \
                "${ROCKY_BASE_PACKAGES[@]}"

            if "$INSTALL_ADMIN"; then
                print_package_array \
                    "Paquets d'administration Rocky Linux :" \
                    "${ROCKY_ADMIN_PACKAGES[@]}"
            fi
            ;;
    esac

    printf '\n'
}

###############################################################################
# Vérification de la disponibilité des paquets optionnels
###############################################################################

debian_package_available() {
    local package="$1"

    apt-cache show "$package" >/dev/null 2>&1
}

rocky_package_available() {
    local package="$1"

    dnf --quiet list "$package" >/dev/null 2>&1
}

collect_available_admin_packages() {
    local package=""

    AVAILABLE_ADMIN_PACKAGES=()
    UNAVAILABLE_ADMIN_PACKAGES=()

    if ! "$INSTALL_ADMIN"; then
        return
    fi

    if "$DRY_RUN"; then
        case "$DISTRO_FAMILY" in
            debian)
                AVAILABLE_ADMIN_PACKAGES=("${DEBIAN_ADMIN_PACKAGES[@]}")
                ;;

            rocky)
                AVAILABLE_ADMIN_PACKAGES=("${ROCKY_ADMIN_PACKAGES[@]}")
                ;;
        esac

        log_warning "Le mode dry-run ne vérifie pas réellement la disponibilité des paquets."
        return
    fi

    case "$DISTRO_FAMILY" in
        debian)
            for package in "${DEBIAN_ADMIN_PACKAGES[@]}"; do
                if debian_package_available "$package"; then
                    AVAILABLE_ADMIN_PACKAGES+=("$package")
                else
                    UNAVAILABLE_ADMIN_PACKAGES+=("$package")
                fi
            done
            ;;

        rocky)
            for package in "${ROCKY_ADMIN_PACKAGES[@]}"; do
                if rocky_package_available "$package"; then
                    AVAILABLE_ADMIN_PACKAGES+=("$package")
                else
                    UNAVAILABLE_ADMIN_PACKAGES+=("$package")
                fi
            done
            ;;
    esac
}

###############################################################################
# Installation des paquets
###############################################################################

install_debian_packages() {
    log_info "Mise à jour de l'index APT."
    run_as_root apt-get update

    log_info "Installation des paquets de base."
    run_as_root env DEBIAN_FRONTEND=noninteractive \
        apt-get install -y "${DEBIAN_BASE_PACKAGES[@]}"

    collect_available_admin_packages

    if [[ ${#AVAILABLE_ADMIN_PACKAGES[@]} -gt 0 ]]; then
        log_info "Installation des outils d'administration disponibles."

        run_as_root env DEBIAN_FRONTEND=noninteractive \
            apt-get install -y "${AVAILABLE_ADMIN_PACKAGES[@]}"
    fi
}

install_rocky_packages() {
    log_info "Actualisation des métadonnées DNF."
    run_as_root dnf makecache

    log_info "Installation des paquets de base."
    run_as_root dnf install -y "${ROCKY_BASE_PACKAGES[@]}"

    collect_available_admin_packages

    if [[ ${#AVAILABLE_ADMIN_PACKAGES[@]} -gt 0 ]]; then
        log_info "Installation des outils d'administration disponibles."

        run_as_root dnf install -y "${AVAILABLE_ADMIN_PACKAGES[@]}"
    fi
}

install_packages() {
    log_info "Installation des paquets pour ${DISTRO_NAME}."

    case "$DISTRO_FAMILY" in
        debian)
            install_debian_packages
            ;;

        rocky)
            install_rocky_packages
            ;;

        *)
            die "Famille de distribution inconnue : ${DISTRO_FAMILY}"
            ;;
    esac

    if [[ ${#UNAVAILABLE_ADMIN_PACKAGES[@]} -gt 0 ]]; then
        log_warning "Certains paquets optionnels ne sont pas disponibles :"

        for package in "${UNAVAILABLE_ADMIN_PACKAGES[@]}"; do
            printf '  - %s\n' "$package"
        done

        log_warning "Aucun dépôt supplémentaire n'a été activé automatiquement."
    fi

    log_success "Installation des paquets terminée."
}

###############################################################################
# Validation des chemins
###############################################################################

validate_source_path() {
    local source_path="$1"

    [[ -n "$source_path" ]] ||
        die "Le chemin source est vide."

    [[ "$source_path" == "${SCRIPT_DIR}/"* ]] ||
        die "Le fichier source n'appartient pas au dépôt : ${source_path}"

    [[ -f "$source_path" ]] ||
        die "Le fichier source n'existe pas : ${source_path}"
}

validate_target_path() {
    local target_path="$1"

    [[ -n "$target_path" ]] ||
        die "Le chemin cible est vide."

    [[ "$target_path" == "${HOME}/"* ]] ||
        die "La cible doit se trouver dans le répertoire personnel : ${target_path}"

    [[ "$target_path" != "$HOME" ]] ||
        die "Refus de modifier directement le répertoire HOME."

    [[ "$target_path" != "/" ]] ||
        die "Refus de modifier la racine du système."

    case "$target_path" in
        *"/../"*|*"/.."|*"/./"*|*"/.")
            die "Le chemin cible contient une traversée non autorisée : ${target_path}"
            ;;
    esac
}

###############################################################################
# Sauvegardes
###############################################################################

create_backup_directory() {
    if "$BACKUP_CREATED"; then
        return
    fi

    run_command mkdir -p "$BACKUP_DIR"
    BACKUP_CREATED=true

    log_info "Répertoire de sauvegarde : ${BACKUP_DIR}"
}

backup_path() {
    local source_path="$1"
    local relative_path=""
    local backup_path=""
    local backup_parent=""

    if [[ ! -e "$source_path" && ! -L "$source_path" ]]; then
        return
    fi

    validate_target_path "$source_path"

    create_backup_directory

    relative_path="${source_path#"${HOME}/"}"
    backup_path="${BACKUP_DIR}/${relative_path}"
    backup_parent="$(dirname -- "$backup_path")"

    run_command mkdir -p "$backup_parent"
    run_command cp -a "$source_path" "$backup_path"

    log_success "Sauvegarde créée : ${backup_path}"
}

###############################################################################
# Création des liens symboliques
###############################################################################

create_symlink() {
    local source_path="$1"
    local target_path="$2"
    local target_parent=""
    local current_source=""

    validate_source_path "$source_path"
    validate_target_path "$target_path"

    target_parent="$(dirname -- "$target_path")"
    run_command mkdir -p "$target_parent"

    if [[ -L "$target_path" ]]; then
        current_source="$(readlink -f -- "$target_path" 2>/dev/null || true)"

        if [[ "$current_source" == "$(readlink -f -- "$source_path")" ]]; then
            log_info "Lien déjà correct : ${target_path}"
            return
        fi

        backup_path "$target_path"
        run_command rm -f -- "$target_path"
    elif [[ -f "$target_path" ]]; then
        backup_path "$target_path"
        run_command rm -f -- "$target_path"
    elif [[ -d "$target_path" ]]; then
        die "La cible est un répertoire. Suppression refusée : ${target_path}"
    elif [[ -e "$target_path" ]]; then
        die "Type de cible non pris en charge : ${target_path}"
    fi

    run_command ln -s "$source_path" "$target_path"

    log_success "Lien créé : ${target_path} -> ${source_path}"
}

###############################################################################
# Configuration Bash
###############################################################################

configure_bashrc() {
    local bashrc="${HOME}/.bashrc"
    local marker_start='# >>> dotfiles managed block >>>'

    validate_target_path "$bashrc"

    if [[ ! -e "$bashrc" ]]; then
        log_info "Création de ${bashrc}."
        run_command touch "$bashrc"
    fi

    if [[ -f "$bashrc" ]] && grep -Fq "$marker_start" "$bashrc"; then
        log_info "Le chargement de .bash_aliases est déjà configuré."
        return
    fi

    backup_path "$bashrc"

    if "$DRY_RUN"; then
        log_info "[DRY-RUN] Ajout du bloc Dotfiles dans ${bashrc}"
        return
    fi

    cat >> "$bashrc" <<'EOF'

# >>> dotfiles managed block >>>
# Ce bloc est géré par le dépôt Dotfiles.
if [ -f "${HOME}/.bash_aliases" ]; then
    . "${HOME}/.bash_aliases"
fi
# <<< dotfiles managed block <<<
EOF

    log_success "Chargement de .bash_aliases ajouté à ${bashrc}."
}
###############################################################################
# Déploiement des configurations
###############################################################################

install_bash_configuration() {
    create_symlink \
        "${SCRIPT_DIR}/config/bash/.bash_aliases" \
        "${HOME}/.bash_aliases"

    configure_bashrc
}

install_tmux_configuration() {
    create_symlink \
        "${SCRIPT_DIR}/config/tmux/.tmux.conf" \
        "${HOME}/.tmux.conf"
}

install_vim_configuration() {
    create_symlink \
        "${SCRIPT_DIR}/config/vim/.vimrc" \
        "${HOME}/.vimrc"
}

install_dotfiles() {
    log_info "Déploiement des fichiers de configuration."

    install_bash_configuration
    install_tmux_configuration
    install_vim_configuration

    log_success "Déploiement des configurations terminé."
}

###############################################################################
# Résumé
###############################################################################

boolean_label() {
    if "$1"; then
        printf 'oui'
    else
        printf 'non'
    fi
}

show_summary() {
    printf '\n'
    printf '%s\n' "============================================================"
    printf '%s\n' " Résumé"
    printf '%s\n' "============================================================"
    printf 'Distribution         : %s\n' "$DISTRO_NAME"
    printf 'Utilisateur           : %s\n' "$(id -un)"
    printf 'Dépôt                 : %s\n' "$SCRIPT_DIR"
    printf 'Paquets               : %s\n' "$(boolean_label "$INSTALL_PACKAGES")"
    printf 'Dotfiles              : %s\n' "$(boolean_label "$INSTALL_DOTFILES")"
    printf 'Profil administrateur : %s\n' "$(boolean_label "$INSTALL_ADMIN")"
    printf 'Installation complète : %s\n' "$(boolean_label "$INSTALL_ALL")"
    printf 'Mode simulation       : %s\n' "$(boolean_label "$DRY_RUN")"

    if "$BACKUP_CREATED"; then
        printf 'Sauvegardes           : %s\n' "$BACKUP_DIR"
    else
        printf 'Sauvegardes           : aucune nécessaire\n'
    fi

    if [[ ${#UNAVAILABLE_ADMIN_PACKAGES[@]} -gt 0 ]]; then
        printf 'Paquets ignorés       : %s\n' \
            "${UNAVAILABLE_ADMIN_PACKAGES[*]}"
    fi

    printf '%s\n' "============================================================"
}

###############################################################################
# Programme principal
###############################################################################

main() {
    parse_arguments "$@"
    validate_execution_context
    detect_distribution

    log_info "Démarrage de l'installation."

    if "$LIST_PACKAGES"; then
        show_selected_packages
        exit 0
    fi

    if "$INSTALL_PACKAGES"; then
        install_packages
    else
        log_info "Installation des paquets désactivée."
    fi

    if "$INSTALL_DOTFILES"; then
        install_dotfiles
    else
        log_info "Déploiement des configurations désactivé."
    fi

    show_summary

    if "$DRY_RUN"; then
        log_success "Simulation terminée. Aucun changement n'a été effectué."
    else
        log_success "Installation terminée."
        log_info "Ouvre un nouveau terminal ou exécute : source ~/.bashrc"
    fi
}

main "$@"
