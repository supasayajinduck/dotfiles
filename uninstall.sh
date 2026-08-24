#!/usr/bin/env bash

###############################################################################
# Dotfiles uninstaller
#
# Description :
#   Supprime uniquement les liens symboliques et les blocs de configuration
#   créés par install.sh.
#
# Important :
#   - les paquets installés ne sont pas désinstallés ;
#   - le dépôt Git n'est pas supprimé ;
#   - les sauvegardes existantes ne sont pas supprimées ;
#   - une restauration nécessite une option explicite.
#
# Exécution :
#   bash uninstall.sh
#   bash uninstall.sh --dry-run
#   bash uninstall.sh --list-backups
#   bash uninstall.sh --restore-backup ~/.dotfiles-backup/YYYYMMDD-HHMMSS
###############################################################################

set -Eeuo pipefail

###############################################################################
# Variables globales
###############################################################################

readonly SCRIPT_NAME="$(basename -- "$0")"
readonly SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
readonly TIMESTAMP="$(date +'%Y%m%d-%H%M%S')"
readonly BACKUP_ROOT="${HOME}/.dotfiles-backup"
readonly UNINSTALL_BACKUP_DIR="${BACKUP_ROOT}/uninstall-${TIMESTAMP}"

readonly BASHRC_MARKER_START='# >>> dotfiles managed block >>>'
readonly BASHRC_MARKER_END='# <<< dotfiles managed block <<<'

DRY_RUN=false
LIST_BACKUPS=false
RESTORE_BACKUP_DIR=""
UNINSTALL_BACKUP_CREATED=false

REMOVED_LINKS=()
SKIPPED_TARGETS=()
RESTORED_FILES=()

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
    printf[0m %s\n' "$*"
() {
 '\033[1;33m[WARN]\
log_error() {
    printf[0m %s\n' "$*"
() {
033[0m %s\n' "$*" >&2
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
  --dry-run
      Affiche les actions sans modifier les fichiers.

  --list-backups
      Affiche les sauvegardes disponibles dans :
      ${BACKUP_ROOT}

  --restore-backup CHEMIN
      Restaure les fichiers d'une sauvegarde précise après la désinstallation.

      Le chemin doit se trouver directement sous :
      ${BACKUP_ROOT}

  -h, --help
      Affiche cette aide.

Comportement par défaut :
  - supprime les liens symboliques gérés par ce dépôt ;
  - retire le bloc Dotfiles de ~/.bashrc ;
  - crée une sauvegarde de sécurité de ~/.bashrc avant modification ;
  - ne désinstalle aucun paquet ;
  - ne supprime ni le dépôt ni les anciennes sauvegardes.

Exemples :
  bash ${SCRIPT_NAME}
  bash ${SCRIPT_NAME} --dry-run
  bash ${SCRIPT_NAME} --list-backups
  bash ${SCRIPT_NAME} --restore-backup \\
      "${BACKUP_ROOT}/20260824-140700"
EOF
}

###############################################################################
# Fonctions génériques
###############################################################################

run_command() {
    if "$DRY_RUN"; then
        printf '[DRY-RUN]'

        printf ' %q' "$@"
        printf '\n'

        return 0
    fi

    "$@"
}

###############################################################################
# Arguments
###############################################################################

parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --dry-run)
                DRY_RUN=true
                ;;

            --list-backups)
                LIST_BACKUPS=true
                ;;

            --restore-backup)
                if [[ $# -lt 2 ]]; then
                    die "L'option --restore-backup nécessite un chemin."
                fi

                RESTORE_BACKUP_DIR="$2"
                shift
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
}

###############################################################################
# Validation du contexte
###############################################################################

validate_execution_context() {
    if [[ "$EUID" -eq 0 && -n "${SUDO_USER:-}" ]]; then
        die "Ne lance pas ce script avec sudo.

Utilise plutôt :
  bash ${SCRIPT_DIR}/${SCRIPT_NAME}

La désinstallation concerne les fichiers de ton utilisateur."
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
# Validation des chemins
###############################################################################

validate_home_target() {
    local target_path="$1"

    [[ -n "$target_path" ]] ||
        die "Le chemin cible est vide."

    [[ "$target_path" == "${HOME}/"* ]] ||
        die "La cible doit se trouver sous HOME : ${target_path}"

    [[ "$target_path" != "$HOME" ]] ||
        die "Refus de modifier directement le répertoire HOME."

    [[ "$target_path" != "/" ]] ||
        die "Refus de modifier la racine du système."

    case "$target_path" in
        *"/../"*|*"/.."|*"/./"*|*"/.")
            die "Le chemin cible contient une traversée interdite : ${target_path}"
            ;;
    esac
}

validate_repository_source() {
    local source_path="$1"

    [[ -n "$source_path" ]] ||
        die "Le chemin source est vide."

    [[ "$source_path" == "${SCRIPT_DIR}/"* ]] ||
        die "La source n'appartient pas au dépôt : ${source_path}"
}

###############################################################################
# Sauvegardes créées avant désinstallation
###############################################################################

create_uninstall_backup_directory() {
    if "$UNINSTALL_BACKUP_CREATED"; then
        return
    fi

    run_command mkdir -p "$UNINSTALL_BACKUP_DIR"
    UNINSTALL_BACKUP_CREATED=true

    log_info "Sauvegarde de désinstallation : ${UNINSTALL_BACKUP_DIR}"
}

backup_before_uninstall() {
    local source_path="$1"
    local relative_path=""
    local backup_path=""
    local backup_parent=""

    if [[ ! -e "$source_path" && ! -L "$source_path" ]]; then
        return
    fi

    validate_home_target "$source_path"
    create_uninstall_backup_directory

    relative_path="${source_path#"${HOME}/"}"
    backup_path="${UNINSTALL_BACKUP_DIR}/${relative_path}"
    backup_parent="$(dirname -- "$backup_path")"

    run_command mkdir -p "$backup_parent"
    run_command cp -a "$source_path" "$backup_path"

    log_success "Sauvegarde de sécurité créée : ${backup_path}"
}

###############################################################################
# Suppression sécurisée des liens symboliques
###############################################################################

remove_managed_symlink() {
    local source_path="$1"
    local target_path="$2"
    local configured_source=""

    validate_repository_source "$source_path"
    validate_home_target "$target_path"

    if [[ ! -e "$target_path" && ! -L "$target_path" ]]; then
        log_info "Cible absente : ${target_path}"
        return
    fi

    if [[ ! -L "$target_path" ]]; then
        log_warning "La cible n'est pas un lien symbolique, suppression refusée :"
        printf '  %s\n' "$target_path"

        SKIPPED_TARGETS+=("$target_path")
        return
    fi

    configured_source="$(readlink -- "$target_path")"

    if [[ "$configured_source" != "$source_path" ]]; then
        log_warning "Le lien ne pointe pas vers ce dépôt, suppression refusée :"
        printf '  Cible  : %s\n' "$target_path"
        printf '  Source : %s\n' "$configured_source"

        SKIPPED_TARGETS+=("$target_path")
        return
    fi

    run_command rm -f -- "$target_path"

    REMOVED_LINKS+=("$target_path")
    log_success "Lien supprimé : ${target_path}"
}

###############################################################################
# Suppression du bloc géré dans .bashrc
###############################################################################

remove_bashrc_managed_block() {
    local bashrc="${HOME}/.bashrc"
    local start_count=0
    local end_count=0
    local temporary_file=""

    validate_home_target "$bashrc"

    if [[ ! -f "$bashrc" ]]; then
        log_info "Fichier absent : ${bashrc}"
        return
    fi

    start_count="$(grep -Fc "$BASHRC_MARKER_START" "$bashrc" || true)"
    end_count="$(grep -Fc "$BASHRC_MARKER_END" "$bashrc" || true)"

    if [[ "$start_count" -eq 0 && "$end_count" -eq 0 ]]; then
        log_info "Aucun bloc Dotfiles présent dans ${bashrc}."
        return
    fi

    if [[ "$start_count" -ne 1 || "$end_count" -ne 1 ]]; then
        log_warning "Le bloc Dotfiles dans ${bashrc} est incomplet ou dupliqué."
        log_warning "Modification automatique refusée."
        log_warning "Début trouvé : ${start_count}, fin trouvée : ${end_count}"

        SKIPPED_TARGETS+=("$bashrc")
        return
    fi

    backup_before_uninstall "$bashrc"

    if "$DRY_RUN"; then
        log_info "[DRY-RUN] Suppression du bloc Dotfiles dans ${bashrc}"
        return
    fi

    temporary_file="$(mktemp "${HOME}/.bashrc.dotfiles.XXXXXX")"

    awk \
        -v start="$BASHRC_MARKER_START" \
        -v end="$BASHRC_MARKER_END" \
        '
        $0 == start {
            inside = 1
            next
        }

        $0 == end {
            inside = 0
            next
        }

        !inside {
            print
        }
        ' \
        "$bashrc" > "$temporary_file"

    chmod --reference="$bashrc" "$temporary_file"
    mv -- "$temporary_file" "$bashrc"

    log_success "Bloc Dotfiles retiré de ${bashrc}."
}

###############################################################################
# Désinstallation des configurations
###############################################################################

uninstall_dotfiles() {
    log_info "Suppression des configurations gérées par ce dépôt."

    remove_managed_symlink \
        "${SCRIPT_DIR}/config/bash/.bash_aliases" \
        "${HOME}/.bash_aliases"

    remove_managed_symlink \
        "${SCRIPT_DIR}/config/tmux/.tmux.conf" \
        "${HOME}/.tmux.conf"

    remove_managed_symlink \
        "${SCRIPT_DIR}/config/vim/.vimrc" \
        "${HOME}/.vimrc"

    remove_bashrc_managed_block

    log_success "Traitement des configurations terminé."
}

###############################################################################
# Liste des sauvegardes
###############################################################################

list_available_backups() {
    local backup_directory=""
    local found=false

    printf '\n'
    printf '%s\n' "Sauvegardes disponibles :"
    printf '%s\n' "============================================================"

    if [[ ! -d "$BACKUP_ROOT" ]]; then
        printf 'Aucune sauvegarde disponible.\n'
        printf 'Répertoire absent : %s\n' "$BACKUP_ROOT"
        return
    fi

    while IFS= read -r backup_directory; do
        found=true
        printf '%s\n' "$backup_directory"
    done < <(
        find "$BACKUP_ROOT" \
            -mindepth 1 \
            -maxdepth 1 \
            -type d \
            -print |
        sort
    )

    if ! "$found"; then
        printf 'Aucune sauvegarde disponible.\n'
    fi
}

###############################################################################
# Validation d'une sauvegarde à restaurer
###############################################################################

validate_restore_directory() {
    local restore_directory="$1"
    local canonical_root=""
    local canonical_restore=""
    local restore_parent=""

    [[ -n "$restore_directory" ]] ||
        die "Aucun répertoire de restauration n'a été indiqué."

    [[ -d "$BACKUP_ROOT" ]] ||
        die "Le répertoire de sauvegarde n'existe pas : ${BACKUP_ROOT}"

    [[ -d "$restore_directory" ]] ||
        die "La sauvegarde n'existe pas : ${restore_directory}"

    canonical_root="$(readlink -f -- "$BACKUP_ROOT")"
    canonical_restore="$(readlink -f -- "$restore_directory")"
    restore_parent="$(dirname -- "$canonical_restore")"

    [[ "$restore_parent" == "$canonical_root" ]] ||
        die "La sauvegarde doit se trouver directement sous :
  ${BACKUP_ROOT}

Chemin reçu :
  ${restore_directory}"

    [[ "$canonical_restore" != "$canonical_root" ]] ||
        die "Le répertoire racine des sauvegardes ne peut pas être restauré."
}

###############################################################################
# Restauration d'un fichier
###############################################################################

restore_file() {
    local backup_directory="$1"
    local relative_path="$2"
    local source_path="${backup_directory}/${relative_path}"
    local target_path="${HOME}/${relative_path}"
    local target_parent=""

    validate_home_target "$target_path"

    if [[ ! -e "$source_path" && ! -L "$source_path" ]]; then
        log_info "Absent de la sauvegarde : ${relative_path}"
        return
    fi

    if [[ -d "$source_path" && ! -L "$source_path" ]]; then
        log_warning "La source est un répertoire, restauration refusée :"
        printf '  %s\n' "$source_path"

        SKIPPED_TARGETS+=("$target_path")
        return
    fi

    if [[ -d "$target_path" && ! -L "$target_path" ]]; then
        log_warning "La cible est un répertoire, restauration refusée :"
        printf '  %s\n' "$target_path"

        SKIPPED_TARGETS+=("$target_path")
        return
    fi

    target_parent="$(dirname -- "$target_path")"
    run_command mkdir -p "$target_parent"

    if [[ -e "$target_path" || -L "$target_path" ]]; then
        backup_before_uninstall "$target_path"
        run_command rm -f -- "$target_path"
    fi

    run_command cp -a "$source_path" "$target_path"

    RESTORED_FILES+=("$target_path")
    log_success "Fichier restauré : ${target_path}"
}

###############################################################################
# Restauration d'une sauvegarde
###############################################################################

restore_backup() {
    local canonical_restore=""

    validate_restore_directory "$RESTORE_BACKUP_DIR"
    canonical_restore="$(readlink -f -- "$RESTORE_BACKUP_DIR")"

    log_info "Restauration depuis : ${canonical_restore}"

    restore_file "$canonical_restore" ".bash_aliases"
    restore_file "$canonical_restore" ".bashrc"
    restore_file "$canonical_restore" ".tmux.conf"
    restore_file "$canonical_restore" ".vimrc"

    log_success "Traitement de la restauration terminé."
}

###############################################################################
# Résumé
###############################################################################

print_array_items() {
    local item=""

    for item in "$@"; do
        printf '  - %s\n' "$item"
    done
}

show_summary() {
    printf '\n'
    printf '%s\n' "============================================================"
    printf '%s\n' " Résumé de la désinstallation"
    printf '%s\n' "============================================================"
    printf 'Utilisateur       : %s\n' "$(id -un)"
    printf 'Dépôt             : %s\n' "$SCRIPT_DIR"
    printf 'Mode simulation   : %s\n' "$DRY_RUN"
    printf 'Liens supprimés   : %s\n' "${#REMOVED_LINKS[@]}"
    printf 'Fichiers restaurés: %s\n' "${#RESTORED_FILES[@]}"
    printf 'Cibles ignorées   : %s\n' "${#SKIPPED_TARGETS[@]}"

    if "$UNINSTALL_BACKUP_CREATED"; then
        printf 'Sauvegarde sécurité : %s\n' "$UNINSTALL_BACKUP_DIR"
    else
        printf 'Sauvegarde sécurité : aucune nécessaire\n'
    fi

    if [[ ${#REMOVED_LINKS[@]} -gt 0 ]]; then
        printf '\nLiens supprimés :\n'
        print_array_items "${REMOVED_LINKS[@]}"
    fi

    if [[ ${#RESTORED_FILES[@]} -gt 0 ]]; then
        printf '\nFichiers restaurés :\n'
        print_array_items "${RESTORED_FILES[@]}"
    fi

    if [[ ${#SKIPPED_TARGETS[@]} -gt 0 ]]; then
        printf '\nCibles ignorées :\n'
        print_array_items "${SKIPPED_TARGETS[@]}"
    fi

    printf '%s\n' "============================================================"
}

###############################################################################
# Programme principal
###############################################################################

main() {
    parse_arguments "$@"
    validate_execution_context

    if "$LIST_BACKUPS"; then
        list_available_backups
        exit 0
    fi

    log_info "Démarrage de la désinstallation."

    uninstall_dotfiles

    if [[ -n "$RESTORE_BACKUP_DIR" ]]; then
        restore_backup
    fi

    show_summary

    if "$DRY_RUN"; then
        log_success "Simulation terminée. Aucun changement n'a été effectué."
    else
        log_success "Désinstallation terminée."
        log_info "Ouvre un nouveau terminal pour actualiser l'environnement."
    fi
}

main "$@"
