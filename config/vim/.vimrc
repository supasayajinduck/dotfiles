" =============================================================================
" Dotfiles Vim configuration
"
" Description:
"   Configuration Vim légère et orientée administration système.
"   Compatible avec Debian, Ubuntu et Rocky Linux.
"
" Objectifs:
"   - rester utilisable sans plugin;
"   - améliorer la lisibilité;
"   - éviter les modifications involontaires;
"   - faciliter l'édition des fichiers de configuration;
"   - conserver un comportement prévisible sur une VM distante.
" =============================================================================

" =============================================================================
" Compatibilité générale
" =============================================================================

" Désactiver le mode compatible avec l'ancien éditeur Vi.
set nocompatible

" Activer la détection du type de fichier.
filetype on

" Charger les règles d'indentation et les plugins natifs liés aux types de fichiers.
filetype plugin indent on

" Activer la coloration syntaxique lorsque le terminal la prend en charge.
if has("syntax")
    syntax enable
endif

" =============================================================================
" Encodage
" =============================================================================

" Utiliser UTF-8 comme encodage principal.
set encoding=utf-8

" Détecter plusieurs encodages courants lors de l'ouverture d'un fichier.
set fileencodings=utf-8,latin1

" =============================================================================
" Interface et affichage
" =============================================================================

" Afficher les numéros de ligne.
set number

" Afficher en permanence la position du curseur.
set ruler

" Afficher les commandes incomplètes dans la dernière ligne.
set showcmd

" Afficher le mode courant.
set showmode

" Toujours afficher la barre de statut.
set laststatus=2

" Afficher le titre du fichier dans le titre du terminal.
set title

" Ne pas masquer les caractères situés au-delà de la largeur de l'écran.
set nowrap

" Autoriser le retour à la ligne visuel avec une commande dédiée.
nnoremap <leader>w :set wrap!<CR>

" Garder plusieurs lignes visibles au-dessus et en dessous du curseur.
set scrolloff=5

" Garder plusieurs colonnes visibles à gauche et à droite du curseur.
set sidescrolloff=5

" Afficher les paires de parenthèses, crochets et accolades correspondantes.
set showmatch

" Ne pas afficher de son ou de clignotement lors d'une erreur.
set noerrorbells
set visualbell
set t_vb=

" =============================================================================
" Couleurs et terminal
" =============================================================================

" Indiquer que le terminal prend en charge un arrière-plan sombre.
set background=dark

" Activer les couleurs avancées lorsque Vim et le terminal les prennent en charge.
if has("termguicolors")
    set termguicolors
endif

" Utiliser un thème fourni nativement avec Vim.
silent! colorscheme desert

" =============================================================================
" Indentation
" =============================================================================

" Utiliser des espaces au lieu des tabulations.
set expandtab

" Nombre d'espaces utilisé pour afficher une tabulation.
set tabstop=4

" Nombre d'espaces utilisé lors d'une indentation automatique.
set shiftwidth=4

" Nombre d'espaces insérés lors de l'utilisation de Tab.
set softtabstop=4

" Adapter automatiquement les valeurs d'indentation existantes.
set shiftround

" Conserver l'indentation de la ligne précédente.
set autoindent

" Activer une indentation intelligente pour les langages compatibles.
set smartindent

" =============================================================================
" Recherche
" =============================================================================

" Rechercher pendant la saisie.
set incsearch

" Mettre en évidence les résultats de recherche.
set hlsearch

" Ignorer la casse lors d'une recherche.
set ignorecase

" Respecter la casse si la recherche contient 
