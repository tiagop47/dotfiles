# Dotfiles do Tiago (WSL + Neovim + Neovide)

Setup pessoal para transformar o WSL (Ubuntu) num ambiente de desenvolvimento rápido, com workflow estilo VS Code dentro do Neovim.


## Migração rápida (copy/paste)
Se queres validar já que está "pronto a migrar", este é o caminho mais curto:

```bash
git clone https://github.com/tiagop47/dotfiles.git ~/dotfiles
cd ~/dotfiles
chmod +x migrate-wsl.sh
./migrate-wsl.sh --dry-run
./migrate-wsl.sh
```

> No fim, reinicia o terminal (ou corre `exec zsh`).

## O que este repositório configura
- **Neovim (v0.10+)** com plugins via Lazy.nvim.
- **Zsh + Oh My Zsh** com aliases e defaults de produtividade.
- **Starship** para prompt moderno e leve.
- **Ferramentas de terminal** como Kitty, Zellij, Lazygit, Fastfetch e htop.
- **Integrações de desenvolvimento** (Node, Java, Live Server, LSP, etc.) usadas pela configuração.

---

## Instalação recomendada (automática)
> Se queres “ficar com tudo pronto” da forma mais simples, usa este caminho.

### 1) Clonar o repositório
```bash
git clone https://github.com/tiagop47/dotfiles.git ~/dotfiles
cd ~/dotfiles
```

### 2) Simular antes de aplicar (opcional, mas recomendado)
```bash
./migrate-wsl.sh --dry-run
```

### 3) Aplicar instalação e symlinks
```bash
./migrate-wsl.sh
```

Este script faz automaticamente:
- instalação de dependências base (`zsh`, `git`, `node/npm`, `java`, `neovim`, etc.);
- instalação de ferramentas extra usadas no setup (`live-server`, `gh`, `starship`, Oh My Zsh, etc.);
- criação de symlinks para as configs deste repositório;
- backup dos teus ficheiros antigos em `~/dotfiles-backup-<timestamp>`.

### Opções úteis do script
```bash
./migrate-wsl.sh --skip-install  # só aplica symlinks
./migrate-wsl.sh --dry-run       # mostra o que faria
./migrate-wsl.sh --help
```

Notas importantes:
- O script está pensado para **Ubuntu/Debian (APT)** dentro de WSL.
- Podes precisar de password `sudo` durante a instalação.
- O install do Oh My Zsh é feito com `CHSH=no`; se quiseres zsh por defeito, corre no fim: `chsh -s $(which zsh)`.

---

## Instalação manual (se preferires controlar tudo)

### 1) Pré-requisitos
```bash
sudo apt update
sudo apt install -y software-properties-common ca-certificates curl git zsh unzip nodejs npm default-jdk ripgrep fd-find htop fastfetch zellij kitty
sudo npm install -g live-server
```

### 2) Neovim 0.10+
```bash
sudo add-apt-repository ppa:neovim-ppa/unstable -y
sudo apt update
sudo apt install -y neovim
```

### 3) Oh My Zsh + Starship
```bash
# Oh My Zsh
RUNZSH=no CHSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# Starship
curl -sS https://starship.rs/install.sh | sh -s -- -y
```

### 4) Symlinks principais
```bash
git clone https://github.com/tiagop47/dotfiles.git ~/dotfiles

ln -sfn ~/dotfiles/zsh/zshrc ~/.zshrc
ln -sfn ~/dotfiles/git/gitconfig ~/.gitconfig

mkdir -p ~/.config
ln -sfn ~/dotfiles/nvim ~/.config/nvim
ln -sfn ~/dotfiles/kitty ~/.config/kitty
ln -sfn ~/dotfiles/lazygit ~/.config/lazygit
ln -sfn ~/dotfiles/gh ~/.config/gh
ln -sfn ~/dotfiles/zellij ~/.config/zellij
ln -sfn ~/dotfiles/fastfetch ~/.config/fastfetch
ln -sfn ~/dotfiles/htop/htoprc ~/.config/htop/htoprc
ln -sfn ~/dotfiles/starship/starship.toml ~/.config/starship.toml
```

---

## Primeiro arranque (checklist rápida)
Depois da instalação:
1. **Fecha e reabre o terminal** (ou executa `zsh`).
2. Abre `nvim` e espera a instalação inicial dos plugins.
3. Confirma binários:
   ```bash
   nvim --version
   zsh --version
   starship --version
   node --version
   java --version
   ```

---

## Configuração no Windows (Neovide)
1. Instala o **[Neovide](https://neovide.dev/)** no Windows.
2. Instala a **FiraCode Nerd Font** (todas as variantes).
3. No WSL, abre com:
   ```bash
   neovide .
   ```
   Também podes usar o alias `nv` (definido no `.zshrc`).

---

## Atalhos principais (estilo VS Code)

| Tecla | Ação |
| :--- | :--- |
| `Ctrl + P` | Procurar ficheiros (Quick Open) |
| `Ctrl + Shift + E` | Abrir/Fechar explorador |
| `Ctrl + D` | Selecionar próxima ocorrência |
| `Shift + Alt + F` | Formatar documento |
| `Ctrl + ç` | Abrir/Fechar terminal integrado |
| `Ctrl + .` | Quick Fix / Code Actions |
| `F12` | Ir para definição |
| `Ctrl + S` | Guardar ficheiro |
| `Ctrl + Z` | Undo |
| `Alt + L + O` | Toggle Live Server |
| `Ctrl + Shift + C` | Toggle Codeium Auto-complete |
| `Ctrl + + / -` | Zoom in/out |

---

## Troubleshooting rápido
- `add-apt-repository: command not found` → instala `software-properties-common`.
- `E: Unable to locate package ...` → corre `sudo apt update` e volta a tentar.
- `nvim` abre sem plugins → espera 1-2 minutos no primeiro arranque (instalação Lazy.nvim).
- Queres reaplicar só configs sem reinstalar pacotes: `./migrate-wsl.sh --skip-install`.

---

## Atualizar os dotfiles
```bash
cd ~/dotfiles
git pull
./migrate-wsl.sh --skip-install
```

Se alterares configurações locais e quiseres publicar:
```bash
git add .
git commit -m "chore: update dotfiles"
git push
```
