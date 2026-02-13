#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="${HOME}/dotfiles-backup-$(date +%Y%m%d-%H%M%S)"

DRY_RUN=false
SKIP_INSTALL=false

usage() {
  cat <<USAGE
Uso: $(basename "$0") [--dry-run] [--skip-install]

Migra imediatamente os dotfiles deste repositório para o WSL atual,
instalando dependências base, criando symlinks e guardando backups
dos ficheiros antigos.

Opções:
  --dry-run       Mostra o que seria feito sem alterar nada.
  --skip-install  Não instala dependências; só aplica symlinks.
  -h, --help      Mostra esta ajuda.
USAGE
}

log() {
  printf '[dotfiles-migrate] %s\n' "$*"
}

run() {
  if [ "$DRY_RUN" = true ]; then
    printf '[dry-run] %s\n' "$*"
  else
    eval "$@"
  fi
}

run_sudo() {
  if [ "$DRY_RUN" = true ]; then
    printf '[dry-run] sudo %s\n' "$*"
  else
    sudo bash -lc "$*"
  fi
}

install_dependencies() {
  if [ "$SKIP_INSTALL" = true ]; then
    log "Instalação de dependências ignorada (--skip-install)."
    return 0
  fi

  log "A instalar dependências base (apt, npm, oh-my-zsh, starship, neovim)..."

  run_sudo "apt update"
  run_sudo "DEBIAN_FRONTEND=noninteractive apt install -y software-properties-common ca-certificates curl git zsh unzip nodejs npm default-jdk ripgrep fd-find htop fastfetch zellij kitty"

  # Live Server (utilizado nos atalhos/configs do nvim)
  run_sudo "npm install -g live-server"

  # GitHub CLI (algumas distros não têm pacote `gh` por omissão)
  if [ "$DRY_RUN" = true ]; then
    printf '[dry-run] command -v gh >/dev/null 2>&1 || (type -p curl >/dev/null && curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg && sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg && echo \"deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main\" | sudo tee /etc/apt/sources.list.d/github-cli.list >/dev/null && sudo apt update && sudo apt install -y gh)\n'
  else
    if ! command -v gh >/dev/null 2>&1; then
      curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
      sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg
      echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list >/dev/null
      run_sudo "apt update"
      run_sudo "DEBIAN_FRONTEND=noninteractive apt install -y gh"
    fi
  fi

  # Neovim recente (ppa unstable, conforme README)
  run_sudo "add-apt-repository ppa:neovim-ppa/unstable -y"
  run_sudo "apt update"
  run_sudo "DEBIAN_FRONTEND=noninteractive apt install -y neovim"

  # Oh My Zsh (apenas se ainda não existir)
  if [ "$DRY_RUN" = true ]; then
    printf '[dry-run] [ -d "$HOME/.oh-my-zsh" ] || RUNZSH=no CHSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"\n'
  else
    if [ ! -d "$HOME/.oh-my-zsh" ]; then
      RUNZSH=no CHSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
    fi
  fi

  # Starship (apenas se ainda não existir)
  if [ "$DRY_RUN" = true ]; then
    printf '[dry-run] command -v starship >/dev/null 2>&1 || curl -sS https://starship.rs/install.sh | sh -s -- -y\n'
  else
    if ! command -v starship >/dev/null 2>&1; then
      curl -sS https://starship.rs/install.sh | sh -s -- -y
    fi
  fi

  log "Instalação de dependências concluída."
}

backup_target() {
  local target="$1"

  if [ ! -e "$target" ] && [ ! -L "$target" ]; then
    return 0
  fi

  local target_resolved
  target_resolved="$(readlink -f "$target" 2>/dev/null || true)"

  # Não cria backup se já estiver a apontar para algo dentro do repo.
  if [ -n "$target_resolved" ] && [[ "$target_resolved" == "$DOTFILES_DIR"* ]]; then
    return 0
  fi

  run "mkdir -p \"$BACKUP_DIR\""

  local rel_path
  rel_path="${target#/}"
  run "mkdir -p \"$BACKUP_DIR/$(dirname "$rel_path")\""
  run "mv \"$target\" \"$BACKUP_DIR/$rel_path\""
  log "Backup criado: $target -> $BACKUP_DIR/$rel_path"
}

link_item() {
  local source="$1"
  local target="$2"

  backup_target "$target"
  run "mkdir -p \"$(dirname "$target")\""
  run "ln -sfn \"$source\" \"$target\""
  log "Symlink aplicado: $target -> $source"
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --dry-run)
      DRY_RUN=true
      ;;
    --skip-install)
      SKIP_INSTALL=true
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      log "Opção inválida: $1"
      usage
      exit 1
      ;;
  esac
  shift
done

log "A migrar dotfiles a partir de: $DOTFILES_DIR"

install_dependencies

link_item "$DOTFILES_DIR/zsh/zshrc" "$HOME/.zshrc"
link_item "$DOTFILES_DIR/git/gitconfig" "$HOME/.gitconfig"

link_item "$DOTFILES_DIR/nvim" "$HOME/.config/nvim"
link_item "$DOTFILES_DIR/kitty" "$HOME/.config/kitty"
link_item "$DOTFILES_DIR/lazygit" "$HOME/.config/lazygit"
link_item "$DOTFILES_DIR/gh" "$HOME/.config/gh"
link_item "$DOTFILES_DIR/zellij" "$HOME/.config/zellij"
link_item "$DOTFILES_DIR/fastfetch" "$HOME/.config/fastfetch"
link_item "$DOTFILES_DIR/htop/htoprc" "$HOME/.config/htop/htoprc"
link_item "$DOTFILES_DIR/starship/starship.toml" "$HOME/.config/starship.toml"

if [ "$DRY_RUN" = true ]; then
  log "Dry-run concluído. Nenhuma alteração foi aplicada."
else
  log "Migração concluída com sucesso."
  if [ -d "$BACKUP_DIR" ]; then
    log "Backups guardados em: $BACKUP_DIR"
  fi
fi
