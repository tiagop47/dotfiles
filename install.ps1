# Script de instalação dos Dotfiles do Tiago
# Executar no PowerShell: .\install.ps1

Write-Host "Configurando dotfiles no Windows..." -ForegroundColor Cyan

# Permite executar o instalador a partir de qualquer diretório.
$repoRoot = $PSScriptRoot
if (-not $repoRoot) { $repoRoot = (Get-Location).Path }

# 1. Neovim
$nvimTarget = "$env:LOCALAPPDATA\nvim"
if (-not (Test-Path $nvimTarget)) {
    New-Item -ItemType Directory -Force -Path $nvimTarget | Out-Null
}
Copy-Item (Join-Path $repoRoot "nvim\init.lua") "$nvimTarget\init.lua" -Force
Copy-Item (Join-Path $repoRoot "nvim\lazy-lock.json") "$nvimTarget\lazy-lock.json" -Force
Copy-Item (Join-Path $repoRoot "nvim\lua") "$nvimTarget\" -Recurse -Force
Write-Host "[OK] Neovim configurado em $nvimTarget" -ForegroundColor Green

# 2. PowerShell Profile
$psProfileDir = Split-Path -Parent $PROFILE
if (-not (Test-Path $psProfileDir)) {
    New-Item -ItemType Directory -Force -Path $psProfileDir | Out-Null
}
Copy-Item (Join-Path $repoRoot "powershell\Microsoft.PowerShell_profile.ps1") "$PROFILE" -Force
Write-Host "[OK] PowerShell Profile instalado em $PROFILE" -ForegroundColor Green

# 3. Windows Terminal
$wtSettings = "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"
if (Test-Path (Split-Path -Parent $wtSettings)) {
    Copy-Item (Join-Path $repoRoot "terminal\settings.json") $wtSettings -Force
    Write-Host "[OK] Windows Terminal configurado" -ForegroundColor Green
}

# 4. OmniSharp Formatting (C# Allman braces)
$omniDir = "$HOME\.omnisharp"
if (-not (Test-Path $omniDir)) {
    New-Item -ItemType Directory -Force -Path $omniDir | Out-Null
}
if (Test-Path (Join-Path $repoRoot "omnisharp\omnisharp.json")) {
    Copy-Item (Join-Path $repoRoot "omnisharp\omnisharp.json") "$omniDir\omnisharp.json" -Force
    Write-Host "[OK] Configuração OmniSharp instalada em $omniDir" -ForegroundColor Green
}

Write-Host "`nDotfiles instalados com sucesso!" -ForegroundColor Green
