# Script de instalação dos Dotfiles do Tiago
# Executar no PowerShell: .\install.ps1

Write-Host "`nConfigurando dotfiles no Windows..." -ForegroundColor Cyan

$dotfilesDir = if ($PSScriptRoot) { $PSScriptRoot } else { "C:\projects\dotfiles" }

# 1. Garante permissão de execução de scripts locais
try {
    Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force -ErrorAction SilentlyContinue
} catch {}

# 2. Fecha instâncias abertas do Neovim/Neovide para libertar ficheiros
Get-Process -Name "neovide", "nvim" -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
Start-Sleep -Milliseconds 500

# 3. Configuração do Neovim (Junction para manter sincronização contínua)
$nvimTarget = "$env:LOCALAPPDATA\nvim"
$nvimSource = "$dotfilesDir\nvim"

$isAlreadyLinked = $false
if (Test-Path $nvimTarget -ErrorAction SilentlyContinue) {
    try {
        $item = Get-Item $nvimTarget -Force -ErrorAction SilentlyContinue
        if ($item.LinkType -eq "Junction") {
            $isAlreadyLinked = $true
        }
    } catch {}
}

if (-not $isAlreadyLinked) {
    if (Test-Path $nvimTarget -ErrorAction SilentlyContinue) {
        cmd /c "rmdir `"$nvimTarget`"" 2>$null
        if (Test-Path $nvimTarget -ErrorAction SilentlyContinue) {
            Remove-Item -Path $nvimTarget -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
    cmd /c "mklink /J `"$nvimTarget`" `"$nvimSource`"" 2>$null
}

if (Test-Path "$nvimTarget\init.lua" -ErrorAction SilentlyContinue) {
    Write-Host "[OK] Neovim ligado com sucesso via Junction a $nvimSource!" -ForegroundColor Green
} else {
    New-Item -ItemType Directory -Force -Path $nvimTarget -ErrorAction SilentlyContinue | Out-Null
    Copy-Item "$nvimSource\*" "$nvimTarget\" -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "[OK] Neovim configurado por cópia em $nvimTarget" -ForegroundColor Green
}

# 4. Configuração dos Perfis do PowerShell (PowerShell 7 e Windows PowerShell 5.1)
$profileSource = "$dotfilesDir\powershell\Microsoft.PowerShell_profile.ps1"
Unblock-File -Path $profileSource -ErrorAction SilentlyContinue

$profileTargets = @(
    $PROFILE,
    "$env:USERPROFILE\Documents\PowerShell\Microsoft.PowerShell_profile.ps1",
    "$env:USERPROFILE\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1"
) | Select-Object -Unique

foreach ($target in $profileTargets) {
    if (-not $target) { continue }
    $targetDir = Split-Path -Parent $target
    if (-not (Test-Path $targetDir -ErrorAction SilentlyContinue)) {
        New-Item -ItemType Directory -Force -Path $targetDir -ErrorAction SilentlyContinue | Out-Null
    }
    try {
        Copy-Item -Path $profileSource -Destination $target -Force -ErrorAction Stop
        Unblock-File -Path $target -ErrorAction SilentlyContinue
        Write-Host "[OK] PowerShell Profile instalado em $target" -ForegroundColor Green
    } catch {
        Write-Host "[NOTA] Perfil em uso ou protegido em $target (será atualizado quando o terminal reiniciar)" -ForegroundColor Yellow
    }
}

# 5. Configuração do Windows Terminal (se instalado)
$terminalSource = "$dotfilesDir\terminal\settings.json"
if (Test-Path $terminalSource -ErrorAction SilentlyContinue) {
    $terminalTargets = @(
        "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json",
        "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminalPreview_8wekyb3d8bbwe\LocalState\settings.json",
        "$env:LOCALAPPDATA\Microsoft\Windows Terminal\settings.json"
    )
    foreach ($termFile in $terminalTargets) {
        $termDir = Split-Path -Parent $termFile
        if (Test-Path $termDir -ErrorAction SilentlyContinue) {
            try {
                Copy-Item -Path $terminalSource -Destination $termFile -Force -ErrorAction Stop
                Write-Host "[OK] Windows Terminal configurado em $termFile" -ForegroundColor Green
            } catch {
                Write-Host "[NOTA] Não foi possível atualizar $termFile" -ForegroundColor Yellow
            }
        }
    }
}

# Desbloqueia o próprio script de instalação
Unblock-File -Path "$dotfilesDir\install.ps1" -ErrorAction SilentlyContinue

Write-Host "`nDotfiles instalados e operacionais!" -ForegroundColor Green
