param(
    [string]$Root = ""
)

$ErrorActionPreference = "Stop"

if ([string]::IsNullOrWhiteSpace($Root)) {
    $Root = Split-Path $PSScriptRoot -Parent
}

$Root = [System.IO.Path]::GetFullPath($Root)
$SoundDir = Join-Path $Root "stbrielle\sound\annex"
$SoundPath = Join-Path $SoundDir "room214_threshold.wav"
$VersionPath = Join-Path $SoundDir ".room214-threshold-v1"
$Version = "st-brielle-room214-threshold-v1-2026-10-17"

if ((Test-Path $SoundPath) -and (Test-Path $VersionPath)) {
    $CurrentVersion = (Get-Content -Raw -Path $VersionPath).Trim()
    if ($CurrentVersion -eq $Version) {
        Write-Host "[OK] Room 214 threshold sound already generated."
        exit 0
    }
}

New-Item -ItemType Directory -Force -Path $SoundDir | Out-Null

try {
    # A seamless eight-second mono PCM loop. The component frequencies all
    # complete an integer number of cycles inside the loop, so the boundary
    # does not click. The result is less a musical drone than a pressure/electrical
    # condition that seems to exist only at the corrected threshold.
    $SampleRate = 11025
    $DurationSeconds = 8
    $SampleCount = $SampleRate * $DurationSeconds
    $Channels = 1
    $BitsPerSample = 16
    $BlockAlign = $Channels * ($BitsPerSample / 8)
    $ByteRate = $SampleRate * $BlockAlign
    $DataBytes = $SampleCount * $BlockAlign

    $Stream = [System.IO.File]::Open($SoundPath, [System.IO.FileMode]::Create, [System.IO.FileAccess]::Write, [System.IO.FileShare]::None)
    $Writer = New-Object System.IO.BinaryWriter($Stream)

    try {
        $Writer.Write([System.Text.Encoding]::ASCII.GetBytes("RIFF"))
        $Writer.Write([int](36 + $DataBytes))
        $Writer.Write([System.Text.Encoding]::ASCII.GetBytes("WAVE"))
        $Writer.Write([System.Text.Encoding]::ASCII.GetBytes("fmt "))
        $Writer.Write([int]16)
        $Writer.Write([int16]1)
        $Writer.Write([int16]$Channels)
        $Writer.Write([int]$SampleRate)
        $Writer.Write([int]$ByteRate)
        $Writer.Write([int16]$BlockAlign)
        $Writer.Write([int16]$BitsPerSample)
        $Writer.Write([System.Text.Encoding]::ASCII.GetBytes("data"))
        $Writer.Write([int]$DataBytes)

        for ($i = 0; $i -lt $SampleCount; $i++) {
            $t = $i / [double]$SampleRate

            # 47/49 Hz make a two-Hz pressure beat. 94 Hz is a restrained
            # electrical harmonic. A very slow eight-second amplitude drift
            # makes the sound difficult to locate without becoming musical.
            $beat = 0.52 * [Math]::Sin(2.0 * [Math]::PI * 47.0 * $t) +
                    0.42 * [Math]::Sin(2.0 * [Math]::PI * 49.0 * $t + 0.35)
            $harmonic = 0.18 * [Math]::Sin(2.0 * [Math]::PI * 94.0 * $t + 1.1)
            $drift = 0.78 + 0.22 * [Math]::Sin(2.0 * [Math]::PI * 0.125 * $t - 0.6)
            $sample = ($beat + $harmonic) * $drift * 0.19

            if ($sample -gt 0.95) { $sample = 0.95 }
            if ($sample -lt -0.95) { $sample = -0.95 }
            $Writer.Write([int16][Math]::Round($sample * 32767.0))
        }
    }
    finally {
        $Writer.Dispose()
        $Stream.Dispose()
    }

    Set-Content -Path $VersionPath -Value $Version -Encoding ASCII
    Write-Host "[OK] Room 214 threshold sound generated: $SoundPath"
    exit 0
}
catch {
    Write-Host "[ERROR] Room 214 threshold sound generation failed." -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    exit 1
}
