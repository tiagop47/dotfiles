# tiagop47 Dotfiles - WSL & Neovim Setup

Este repositório contém a minha configuração pessoal para um ambiente de desenvolvimento produtivo no WSL (Ubuntu), focado na experiência "VS Code" dentro do Neovim, utilizando o Neovide como interface gráfica no Windows.

## O que está incluído?
- **Neovim (v0.10+):** Configuração completa em Lua com Lazy.nvim.
- **Zsh + Oh My Zsh:** Terminal turbinado com aliases úteis.
- **Starship:** Prompt minimalista e rápido.
- **LSP & Análise:** Suporte para Java, JavaScript, HTML, CSS, ESLint e ErrorLens.
- **Neovide:** Configuração para aceleração por GPU e animações fluidas.
- **Live Server:** Visualização em tempo real para projetos Web.
- **AI Completion:** Integração com Codeium.

---

## Instalação Passo a Passo

### Migração imediata para outro WSL (inclui instalação)
Se estás a começar um WSL do zero e já clonaste este repositório, podes preparar tudo de uma vez com:

```bash
cd ~/dotfiles
./migrate-wsl.sh
```

Por omissão, o script:
- instala dependências base (zsh, git, node/npm, java, neovim, etc.);
- instala `live-server`, Oh My Zsh e Starship (quando não existirem);
- cria symlinks para todas as configs deste repo;
- faz backup automático de ficheiros/configs existentes em `~/dotfiles-backup-<timestamp>`.

Opções úteis:

```bash
./migrate-wsl.sh --dry-run
./migrate-wsl.sh --skip-install
```

### 1. Pré-requisitos (WSL/Ubuntu)
Primeiro, garante que o teu sistema está atualizado e com as ferramentas base:
```bash
sudo apt update && sudo apt install -y zsh curl git nodejs npm default-jdk ripgrep fd-find
# Necessário para o Live Server
sudo npm install -g live-server
```

### 2. Configurar o Shell (Zsh & Starship)
Instala o Oh My Zsh e o Starship:
```bash
# Oh My Zsh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# Starship
curl -sS https://starship.rs/install.sh | sh
```

### 3. Instalar o Neovim (v0.10+)
Para teres a versão mais recente:
```bash
sudo add-apt-repository ppa:neovim-ppa/unstable -y
sudo apt update && sudo apt install neovim -y
```

### 4. Aplicar os Dotfiles (Symlinks)
Clona este repositório e vincula os ficheiros usando links simbólicos:
```bash
git clone https://github.com/tiagop47/dotfiles.git ~/dotfiles

# Neovim
mkdir -p ~/.config/nvim
ln -s ~/dotfiles/nvim/init.lua ~/.config/nvim/init.lua

# Zsh
rm ~/.zshrc
ln -s ~/dotfiles/zsh/zshrc ~/.zshrc

# Starship
mkdir -p ~/.config
ln -s ~/dotfiles/starship/starship.toml ~/.config/starship.toml
```

---

## Configuração no Windows (Neovide)

1. Descarrega e instala o **[Neovide](https://neovide.dev/)**.
2. Instala a fonte **[FiraCode Nerd Font](https://github.com/ryanoasis/nerd-fonts/releases/download/v3.1.1/FiraCode.zip)** no Windows (instala todas as variantes: Bold, Italic, etc.).
3. No terminal do WSL, agora podes abrir o editor com:
   ```bash
   neovide .
   ```
   *(O alias `nv` também está configurado no .zshrc).*

---

## Atalhos Principais (Estilo VS Code)

| Tecla | Acção |
| :--- | :--- |
| `Ctrl + P` | Procurar ficheiros (Quick Open) |
| `Ctrl + Shift + E` | Abrir/Fechar Explorador de Ficheiros |
| `Ctrl + D` | Selecionar próxima ocorrência (Multi-cursor) |
| `Shift + Alt + F` | Formatar documento (Prettier/LSP) |
| `Ctrl + ç` | Abrir/Fechar Terminal Integrado |
| `Ctrl + .` | Quick Fix / Code Actions |
| `F12` | Ir para Definição |
| `Ctrl + S` | Guardar Ficheiro |
| `Ctrl + Z` | Desfazer (Undo) |
| `Alt + L + O` | **Toggle Live Server** (Abre index.html da raiz) |
| `Ctrl + Shift + C` | **Toggle Codeium Auto-complete** |
| `Ctrl + + / -` | Aumentar/Diminuir Zoom |

---

## Manutenção
Para atualizar o repositório com novas mudanças:
```bash
cd ~/dotfiles
git add .
git commit -m "Update config: Live Server, Codeium toggle and Green Line Numbers"
git push
```
