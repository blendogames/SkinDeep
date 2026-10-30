param(
    [string]$Destination = "",
    [switch]$Force
)

$ErrorActionPreference = "Stop"

if ([string]::IsNullOrWhiteSpace($Destination)) {
    $Destination = Split-Path $PSScriptRoot -Parent
}

$Destination = [System.IO.Path]::GetFullPath($Destination)
New-Item -ItemType Directory -Force -Path $Destination | Out-Null

$LogPath = Join-Path $Destination "stbrielle_runtime_setup.log"
try {
    Start-Transcript -Path $LogPath -Force | Out-Null
} catch {
    # Transcript logging is helpful but not required.
}

# Pin the official dhewm3 dependency bundle so the build is reproducible.
$DhewmLibsCommit = "57c565984c41356e8b1c4d31f182e763b6ea210a"
$Repo = "dhewm/dhewm3-libs"
$RelativeBase = "x86_64-w64-mingw32/bin"
$RawBase = "https://raw.githubusercontent.com/$Repo/$DhewmLibsCommit/$RelativeBase"
$ApiBase = "https://api.github.com/repos/$Repo/contents/$RelativeBase"

$RuntimeDlls = @(
    "OpenAL32.dll",
    "SDL2.dll",
    "libjpeg-8.dll",
    "libogg-0.dll",
    "libvorbis-0.dll",
    "libvorbisfile-3.dll",
    "zlib1.dll"
)

try {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
} catch {
}

function Get-StBrielleRuntimeFile {
    param(
        [Parameter(Mandatory=$true)][string]$Name,
        [Parameter(Mandatory=$true)][string]$Output
    )

    $Temp = "$Output.download"
    if (Test-Path $Temp) {
        Remove-Item -Force $Temp
    }

    # Route 1: raw.githubusercontent.com with PowerShell.
    $RawUrl = "$RawBase/$Name"
    Write-Host "[TRY 1] PowerShell raw: $Name"
    try {
        Invoke-WebRequest -UseBasicParsing -Uri $RawUrl -OutFile $Temp -TimeoutSec 45
        if ((Test-Path $Temp) -and ((Get-Item $Temp).Length -gt 0)) {
            Move-Item -Force $Temp $Output
            return
        }
    } catch {
        Write-Host "[WARN] Raw PowerShell failed: $($_.Exception.Message)"
    }

    if (Test-Path $Temp) {
        Remove-Item -Force $Temp
    }

    # Route 2: curl.exe against raw.githubusercontent.com.
    $Curl = Get-Command curl.exe -ErrorAction SilentlyContinue
    if ($Curl) {
        Write-Host "[TRY 2] curl raw: $Name"
        & $Curl.Source -L --fail --silent --show-error --connect-timeout 20 --max-time 60 $RawUrl -o $Temp
        if (($LASTEXITCODE -eq 0) -and (Test-Path $Temp) -and ((Get-Item $Temp).Length -gt 0)) {
            Move-Item -Force $Temp $Output
            return
        }
        if (Test-Path $Temp) {
            Remove-Item -Force $Temp
        }
    }

    # Route 3: GitHub Contents API, requesting raw media.
    $ApiUrl = "$ApiBase/$Name?ref=$DhewmLibsCommit"
    Write-Host "[TRY 3] GitHub API raw: $Name"
    try {
        $Headers = @{
            "Accept" = "application/vnd.github.raw+json"
            "User-Agent" = "stbrielle-runtime-setup"
        }
        Invoke-WebRequest -UseBasicParsing -Headers $Headers -Uri $ApiUrl -OutFile $Temp -TimeoutSec 45
        if ((Test-Path $Temp) -and ((Get-Item $Temp).Length -gt 0)) {
            Move-Item -Force $Temp $Output
            return
        }
    } catch {
        Write-Host "[WARN] GitHub API failed: $($_.Exception.Message)"
    }

    if (Test-Path $Temp) {
        Remove-Item -Force $Temp
    }

    throw "Unable to download $Name using all configured GitHub routes."
}

try {
    Write-Host ""
    Write-Host "ST. BRIELLE runtime dependency setup"
    Write-Host "Destination: $Destination"
    Write-Host "Log: $LogPath"
    Write-Host ""

    $Downloaded = 0
    $Existing = 0

    foreach ($Dll in $RuntimeDlls) {
        $Output = Join-Path $Destination $Dll

        if ((Test-Path $Output) -and -not $Force) {
            $Item = Get-Item $Output
            if ($Item.Length -gt 0) {
                Write-Host "[OK] $Dll"
                $Existing++
                continue
            }
        }

        Write-Host "[GET] $Dll"
        Get-StBrielleRuntimeFile -Name $Dll -Output $Output
        $Downloaded++
    }

    $Missing = @()
    foreach ($Dll in $RuntimeDlls) {
        $Path = Join-Path $Destination $Dll
        if (-not (Test-Path $Path)) {
            $Missing += $Dll
        }
    }

    if ($Missing.Count -gt 0) {
        throw "Runtime setup incomplete. Missing: $($Missing -join ', ')"
    }

    Write-Host ""
    Write-Host "Runtime dependencies ready."
    Write-Host "Existing: $Existing"
    Write-Host "Downloaded: $Downloaded"
    Write-Host "Verified: $($RuntimeDlls.Count) DLLs present in $Destination"
    Write-Host ""
}
catch {
    Write-Host ""
    Write-Host "ST. BRIELLE runtime setup FAILED." -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    Write-Host "See log: $LogPath"
    Write-Host ""
    exit 1
}
finally {
    try {
        Stop-Transcript | Out-Null
    } catch {
    }
}
