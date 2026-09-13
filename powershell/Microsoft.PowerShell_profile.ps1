
# Configuração do PSReadLine com proteção para janelas pequenas / terminais embutidos
if ($Host.UI.RawUI.WindowSize.Width -ge 50 -and $Host.UI.RawUI.WindowSize.Height -ge 5) {
    try {
        Set-PSReadLineOption -PredictionSource History -ErrorAction SilentlyContinue
        Set-PSReadLineOption -PredictionViewStyle ListView -ErrorAction SilentlyContinue
    } catch {}
} else {
    try {
        Set-PSReadLineOption -PredictionSource History -ErrorAction SilentlyContinue
        Set-PSReadLineOption -PredictionViewStyle InlineView -ErrorAction SilentlyContinue
    } catch {}
}
try { Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete -ErrorAction SilentlyContinue } catch {}
if (Get-Module -ListAvailable -Name PSFzf) {
    Import-Module PSFzf -ErrorAction SilentlyContinue
    try { Set-PSReadLineKeyHandler -Key Ctrl+r -ScriptBlock { Invoke-FzfHistory } -ErrorAction SilentlyContinue } catch {}
}

# Import the Chocolatey Profile that contains the necessary code to enable
# tab-completions to function for `choco`.
# Be aware that if you are missing these lines from your profile, tab completion
# for `choco` will not function.
# See https://ch0.co/tab-completion for details.
$ChocolateyProfile = "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1"
if (Test-Path($ChocolateyProfile)) {
  Import-Module "$ChocolateyProfile"
}
Remove-Item -Path Alias:cd -Force -ErrorAction SilentlyContinue
$projectsRoot = if ($env:PROJECTS_DIR) { $env:PROJECTS_DIR } else { "C:\projects" }

# Auto-cd estilo Linux/ZSH: se digitares o nome de uma pasta (ex: `projects`, `..`, `nvim`), faz cd automaticamente!
$ExecutionContext.InvokeCommand.CommandNotFoundAction = {
    param($cmdName, $eventArgs)
    # Suporta caminhos normais e variáveis como ~
    try {
        $expanded = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($cmdName)
        if (Test-Path -LiteralPath $expanded -PathType Container) {
            $safePath = $expanded.Replace("'", "''")
            $eventArgs.CommandScriptBlock = [ScriptBlock]::Create("Set-Location -LiteralPath '$safePath'; Get-ChildItem")
        }
    } catch {
        # Deixa comandos normais seguirem para o erro padrão.
    }
}

function cd {
    param($path)
    if ($path) {
        Set-Location $path
    } else {
        Set-Location $projectsRoot
    }
    Get-ChildItem
}

# Atalhos rápidos de navegação
function p       { Set-Location $projectsRoot; Get-ChildItem }
function appdata { Set-Location "$env:LOCALAPPDATA"; Get-ChildItem }
function nvimdir { Set-Location "$env:LOCALAPPDATA\nvim"; Get-ChildItem }
function ..      { Set-Location ..; Get-ChildItem }
function ...     { Set-Location ..\..; Get-ChildItem }

# Abre o Neovide no diretório ou ficheiro indicado: nv ., nv ficheiro.json
Remove-Item Alias:nv -Force -ErrorAction SilentlyContinue
function nv {
    param([Parameter(ValueFromRemainingArguments=$true)][string[]]$Path)
    & "$env:LOCALAPPDATA\Programs\Neovide\neovide.exe" $Path
}
