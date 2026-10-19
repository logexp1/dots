# Windows counterpart of install.sh: winget packages, GnuPG + password store, pass-winmenu.
# Usage (Windows PowerShell 5.1 or pwsh):
#   powershell -ExecutionPolicy Bypass -File install\windows\install.ps1 all
#   powershell -ExecutionPolicy Bypass -File install\windows\install.ps1 gpg passmenu
param([string[]]$Modules)

$ErrorActionPreference = 'Stop'

$BaseDir = Split-Path (Split-Path $PSScriptRoot)
$AllModules = @('packages', 'gpg', 'passmenu')

$Fingerprint = 'D56378D8CBE9852BACAE1E37360913AC5912FEB8'
$PassRepo = 'https://github.com/logexp1/password-store.git'
$PassDir = Join-Path $HOME '.password-store'
$PassMenuDir = Join-Path $HOME 'utils\pass-winmenu'

function Log-Step($module, $msg) { Write-Host "[$module] " -ForegroundColor Blue -NoNewline; Write-Host $msg }
function Log-Warn($module, $msg) { Write-Host "[$module] $msg" -ForegroundColor Yellow }
function Log-Error($module, $msg) { Write-Host "[$module] $msg" -ForegroundColor Red }

# winget installs update PATH in the registry only; reload it so new tools are found.
function Update-Path {
    $machine = [Environment]::GetEnvironmentVariable('Path', 'Machine')
    $user = [Environment]::GetEnvironmentVariable('Path', 'User')
    $env:Path = "$machine;$user"
}

function Require-Cmd($name) {
    Update-Path
    if (-not (Get-Command $name -ErrorAction SilentlyContinue)) {
        throw "Required command '$name' not found. Run the 'packages' module first."
    }
}

function Run-Packages {
    $list = Join-Path $BaseDir 'install\packages\windows'
    $ids = Get-Content $list | ForEach-Object { $_.Trim() } | Where-Object { $_ -and -not $_.StartsWith('#') }
    foreach ($id in $ids) {
        Log-Step 'packages' "Installing $id..."
        winget install --id $id --exact --silent --accept-source-agreements --accept-package-agreements
        # Non-zero also covers "already installed, no upgrade available".
        if ($LASTEXITCODE -ne 0) { Log-Warn 'packages' "winget exited with $LASTEXITCODE for $id (already installed?)" }
    }
    Update-Path
    Log-Step 'packages' 'Done.'
}

function Has-SecretKey {
    # Windows PowerShell 5.1 turns redirected native stderr into errors, which Stop would throw.
    $ErrorActionPreference = 'Continue'
    $out = & gpg --list-secret-keys --with-colons $Fingerprint 2>$null
    return [bool]($out | Where-Object { $_ -like 'sec:*' })
}

function Run-Gpg {
    Require-Cmd gpg
    Require-Cmd git

    # Same cache times as common/.gnupg/gpg-agent.conf; Gpg4win brings its own pinentry.
    $gnupgHome = Join-Path $env:APPDATA 'gnupg'
    New-Item -ItemType Directory -Force $gnupgHome | Out-Null
    $agentConf = Join-Path $gnupgHome 'gpg-agent.conf'
    Log-Step 'gpg' "Writing $agentConf..."
    @(
        '# cache passwords for (another) 3 hours after use'
        'default-cache-ttl 10800'
        '# cache passwords for 24 hours max'
        'max-cache-ttl 86400'
    ) | Set-Content $agentConf -Encoding ascii
    & gpg-connect-agent reloadagent /bye | Out-Null

    if (Has-SecretKey) {
        Log-Step 'gpg' 'Secret key already in keyring, skipping import.'
    } else {
        # install/gpg.sh reads the same file from OneDrive.
        $keyFile = if ($env:OneDrive) { Join-Path $env:OneDrive 'privkey.asc' } else { $null }
        if (-not $keyFile -or -not (Test-Path $keyFile)) {
            Log-Warn 'gpg' "privkey.asc not found in OneDrive ($env:OneDrive)."
            $keyFile = Read-Host 'Path to the exported secret key (.asc), or empty to skip'
        }
        if (-not $keyFile) {
            Log-Warn 'gpg' 'Skipping key import. Import it later, then re-run: install.ps1 gpg'
            return
        }
        Log-Step 'gpg' "Importing secret key from $keyFile..."
        & gpg --import $keyFile
        if (-not (Has-SecretKey)) { throw "Import finished but secret key $Fingerprint is missing." }
    }

    Log-Step 'gpg' 'Setting key trust to ultimate...'
    "${Fingerprint}:6:" | & gpg --import-ownertrust

    if (Test-Path $PassDir) {
        Log-Step 'gpg' "Password store already exists at $PassDir, pulling..."
        & git -C $PassDir pull --ff-only
    } else {
        Log-Step 'gpg' 'Cloning password store...'
        & git clone $PassRepo $PassDir
    }
    Log-Step 'gpg' 'Done.'
}

function Run-PassMenu {
    $exe = Join-Path $PassMenuDir 'pass-winmenu.exe'
    if (Test-Path $exe) {
        Log-Step 'passmenu' "pass-winmenu already at $PassMenuDir, skipping download."
    } else {
        Log-Step 'passmenu' 'Downloading the latest pass-winmenu release...'
        $release = Invoke-RestMethod 'https://api.github.com/repos/geluk/pass-winmenu/releases/latest'
        # The -nogpg build uses Gpg4win's gpg instead of a bundled copy.
        $asset = $release.assets | Where-Object { $_.name -eq 'pass-winmenu-nogpg.zip' } | Select-Object -First 1
        if (-not $asset) { throw "No pass-winmenu-nogpg.zip in release $($release.tag_name)." }
        $zip = Join-Path $env:TEMP $asset.name
        Invoke-WebRequest $asset.browser_download_url -OutFile $zip -UseBasicParsing
        $staging = Join-Path $env:TEMP 'pass-winmenu-extract'
        Remove-Item $staging -Recurse -Force -ErrorAction SilentlyContinue
        Expand-Archive $zip -DestinationPath $staging -Force
        # The zip may wrap everything in one top-level folder.
        $src = Get-ChildItem $staging -Recurse -Filter 'pass-winmenu.exe' | Select-Object -First 1
        if (-not $src) { throw 'pass-winmenu.exe not found in the downloaded zip.' }
        New-Item -ItemType Directory -Force $PassMenuDir | Out-Null
        Copy-Item (Join-Path $src.DirectoryName '*') $PassMenuDir -Recurse -Force
        Remove-Item $zip, $staging -Recurse -Force
        Log-Step 'passmenu' "Installed $($release.tag_name) to $PassMenuDir."
    }

    # Start at login; pinentry only appears on the first Ctrl+Alt+P.
    $startup = [Environment]::GetFolderPath('Startup')
    $link = Join-Path $startup 'pass-winmenu.lnk'
    Log-Step 'passmenu' "Creating startup shortcut $link..."
    $shortcut = (New-Object -ComObject WScript.Shell).CreateShortcut($link)
    $shortcut.TargetPath = $exe
    $shortcut.WorkingDirectory = $PassMenuDir
    $shortcut.Save()

    if (-not (Get-Process pass-winmenu -ErrorAction SilentlyContinue)) {
        Start-Process $exe -WorkingDirectory $PassMenuDir
    }
    Log-Step 'passmenu' 'Done. Press Ctrl+Alt+P to search the password store.'
}

if (-not $Modules) {
    Write-Host "Usage: install.ps1 <module> [module...] | all"
    Write-Host ''
    Write-Host 'Available modules:'
    $AllModules | ForEach-Object { Write-Host "  $_" }
    exit 0
}
if ($Modules -contains 'all') { $Modules = $AllModules }

foreach ($m in $Modules) {
    if ($AllModules -notcontains $m) { Log-Error 'install' "Unknown module: $m"; exit 1 }
}
foreach ($m in $Modules) {
    switch ($m) {
        'packages' { Run-Packages }
        'gpg' { Run-Gpg }
        'passmenu' { Run-PassMenu }
    }
}
