
# ── PSReadLine ────────────────────────────────────────────────────────────────
$_isWide = $Host.UI.RawUI.WindowSize.Width -ge 50 -and $Host.UI.RawUI.WindowSize.Height -ge 5
$_view   = if ($_isWide) { "ListView" } else { "InlineView" }
try {
    Set-PSReadLineOption -PredictionSource History -PredictionViewStyle $_view -ErrorAction SilentlyContinue
    Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete -ErrorAction SilentlyContinue
} catch {}

# ── PSFzf: lazy-load apenas quando Ctrl+R é premido pela primeira vez ─────────
# (Get-Module -ListAvailable escaneia o disco inteiro — muito lento no arranque)
$_fzfModule = "$env:USERPROFILE\Documents\PowerShell\Modules\PSFzf\PSFzf.psd1"
if (-not (Test-Path $_fzfModule)) {
    $_fzfModule = "$env:USERPROFILE\Documents\WindowsPowerShell\Modules\PSFzf\PSFzf.psd1"
}
if (Test-Path $_fzfModule) {
    Set-PSReadLineKeyHandler -Key Ctrl+r -ScriptBlock {
        if (-not (Get-Module PSFzf)) {
            Import-Module PSFzf -ErrorAction SilentlyContinue
        }
        Invoke-FzfHistory
    } -ErrorAction SilentlyContinue
}

# ── Chocolatey: adiciona apenas o PATH, sem Import-Module completo (~300ms) ───
if ($env:ChocolateyInstall) {
    $env:PATH = "$env:ChocolateyInstall\bin;" + $env:PATH
}

# ── Navegação ─────────────────────────────────────────────────────────────────
Remove-Item -Path Alias:cd -Force -ErrorAction SilentlyContinue
$projectsRoot = if ($env:PROJECTS_DIR) { $env:PROJECTS_DIR } else { "C:\projects" }

# Auto-cd estilo Linux/ZSH: digitar nome de pasta faz cd automaticamente
$ExecutionContext.InvokeCommand.CommandNotFoundAction = {
    param($cmdName, $eventArgs)
    try {
        $expanded = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($cmdName)
        if (Test-Path -LiteralPath $expanded -PathType Container) {
            $safePath = $expanded.Replace("'", "''")
            $eventArgs.CommandScriptBlock = [ScriptBlock]::Create("Set-Location -LiteralPath '$safePath'; Get-ChildItem")
        }
    } catch {}
}

function cd {
    param($path)
    if ($path) { Set-Location $path } else { Set-Location $projectsRoot }
    Get-ChildItem
}

function p       { Set-Location $projectsRoot; Get-ChildItem }
function appdata { Set-Location "$env:LOCALAPPDATA"; Get-ChildItem }
function nvimdir { Set-Location "$env:LOCALAPPDATA\nvim"; Get-ChildItem }
function ..      { Set-Location ..; Get-ChildItem }
function ...     { Set-Location ..\..; Get-ChildItem }

# ── Neovide ───────────────────────────────────────────────────────────────────
Remove-Item Alias:nv -Force -ErrorAction SilentlyContinue
function nv {
    param([Parameter(ValueFromRemainingArguments=$true)][string[]]$Path)
    & "$env:LOCALAPPDATA\Programs\Neovide\neovide.exe" $Path
}
