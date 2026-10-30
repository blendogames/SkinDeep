param(
    [string]$Root = ""
)

$ErrorActionPreference = "Stop"

if ([string]::IsNullOrWhiteSpace($Root)) {
    $Root = Split-Path $PSScriptRoot -Parent
}

$Root = [System.IO.Path]::GetFullPath($Root)
$TextureDir = Join-Path $Root "stbrielle\textures\stbrielle\annex"
$Marker = Join-Path $TextureDir ".generated-room214-paper-v1"
$Version = "st-brielle-room214-paper-v1-2026-10-17"
$Required = @("room214_paper_d.tga", "room214_paper_local.tga", "room214_paper_s.tga")

$Ready = $false
if (Test-Path $Marker) {
    $MarkerValue = (Get-Content -Raw -Path $Marker).Trim()
    if ($MarkerValue -eq $Version) {
        $Ready = $true
        foreach ($File in $Required) {
            if (-not (Test-Path (Join-Path $TextureDir $File))) {
                $Ready = $false
                break
            }
        }
    }
}

if ($Ready) {
    Write-Host "[OK] Room 214 corrected ledger paper already generated."
    exit 0
}

New-Item -ItemType Directory -Force -Path $TextureDir | Out-Null

$Source = @'
using System;
using System.IO;

public static class StBrielleRoom214Paper
{
    const int N = 256;

    static double Clamp(double v, double lo, double hi)
    {
        if (v < lo) return lo;
        if (v > hi) return hi;
        return v;
    }

    static byte B(double v)
    {
        return (byte)Math.Round(Clamp(v, 0.0, 1.0) * 255.0);
    }

    static uint Hash(int x, int y, int seed)
    {
        unchecked
        {
            uint h = (uint)(x * 374761393 + y * 668265263 + seed * 1442695041);
            h = (h ^ (h >> 13)) * 1274126177u;
            return h ^ (h >> 16);
        }
    }

    static double Grain(int x, int y, int seed)
    {
        return (Hash(x, y, seed) & 0xFFFF) / 65535.0;
    }

    static int Wrap(int v)
    {
        v %= N;
        return v < 0 ? v + N : v;
    }

    static void Put(byte[] rgb, int x, int y, double r, double g, double b)
    {
        int i = (y * N + x) * 3;
        rgb[i + 0] = B(r);
        rgb[i + 1] = B(g);
        rgb[i + 2] = B(b);
    }

    static void WriteTga(string path, byte[] rgb)
    {
        byte[] header = new byte[18];
        header[2] = 2;
        header[12] = (byte)(N & 255);
        header[13] = (byte)(N >> 8);
        header[14] = (byte)(N & 255);
        header[15] = (byte)(N >> 8);
        header[16] = 24;
        header[17] = 0x20;

        using (FileStream fs = new FileStream(path, FileMode.Create, FileAccess.Write, FileShare.None))
        {
            fs.Write(header, 0, header.Length);
            byte[] row = new byte[N * 3];
            for (int y = 0; y < N; y++)
            {
                for (int x = 0; x < N; x++)
                {
                    int src = (y * N + x) * 3;
                    int dst = x * 3;
                    row[dst + 0] = rgb[src + 2];
                    row[dst + 1] = rgb[src + 1];
                    row[dst + 2] = rgb[src + 0];
                }
                fs.Write(row, 0, row.Length);
            }
        }
    }

    public static void Generate(string dir)
    {
        byte[] diffuse = new byte[N * N * 3];
        double[] height = new double[N * N];
        double[] spec = new double[N * N];

        for (int y = 0; y < N; y++) for (int x = 0; x < N; x++)
        {
            double fiber = (Grain(x, y, 1401) - 0.5) * 0.050;
            double mottled = (Grain(x / 5, y / 5, 1429) - 0.5) * 0.035;

            int baseRule = y % 32;
            double rule = (baseRule == 0 || baseRule == 1) ? 1.0 : 0.0;

            // After the middle of the page, the same ledger ruling begins to
            // appear again three pixels later. It is faint enough to read as
            // age or bleed-through until the eye follows it across the sheet.
            double transition = Clamp((x - 104.0) / 48.0, 0.0, 1.0);
            int duplicateRule = (y + 3) % 32;
            double duplicate = (duplicateRule == 0 || duplicateRule == 1) ? transition : 0.0;

            // A nearly erased vertical registration guide drifts instead of
            // remaining straight, suggesting the form was copied from a page
            // whose geometry did not match this one.
            int guideX = 46 + (int)Math.Round(Math.Sin((y / (double)N) * Math.PI * 2.0) * 5.0);
            double guide = Math.Abs(x - guideX) <= 1 ? 1.0 : 0.0;

            double stain = Math.Pow(Grain(x / 9, y / 9, 1459), 7.0) * 0.045;
            double dark = rule * 0.075 + duplicate * 0.055 + guide * 0.035 + stain;

            Put(diffuse, x, y,
                0.56 + fiber + mottled - dark,
                0.47 + fiber * 0.78 + mottled * 0.72 - dark * 0.82,
                0.30 + fiber * 0.46 + mottled * 0.38 - dark * 0.55);

            height[y * N + x] = 0.47 + fiber * 0.30 - rule * 0.018 - duplicate * 0.012 - guide * 0.008;
            spec[y * N + x] = 0.055 + (1.0 - Grain(x, y, 1481)) * 0.025 - stain * 0.25;
        }

        byte[] normal = new byte[N * N * 3];
        byte[] specRgb = new byte[N * N * 3];
        for (int y = 0; y < N; y++)
        {
            int ym = Wrap(y - 1);
            int yp = Wrap(y + 1);
            for (int x = 0; x < N; x++)
            {
                int xm = Wrap(x - 1);
                int xp = Wrap(x + 1);
                double dx = (height[y * N + xp] - height[y * N + xm]) * 2.0;
                double dy = (height[yp * N + x] - height[ym * N + x]) * 2.0;
                double nx = -dx;
                double ny = -dy;
                double nz = 1.0;
                double len = Math.Sqrt(nx * nx + ny * ny + nz * nz);
                nx /= len; ny /= len; nz /= len;
                Put(normal, x, y, nx * 0.5 + 0.5, ny * 0.5 + 0.5, nz * 0.5 + 0.5);
                double sv = Clamp(spec[y * N + x], 0.0, 1.0);
                Put(specRgb, x, y, sv, sv, sv);
            }
        }

        WriteTga(Path.Combine(dir, "room214_paper_d.tga"), diffuse);
        WriteTga(Path.Combine(dir, "room214_paper_local.tga"), normal);
        WriteTga(Path.Combine(dir, "room214_paper_s.tga"), specRgb);
    }
}
'@

try {
    Write-Host "[BUILD] Generating Room 214 corrected ledger paper..."
    Add-Type -TypeDefinition $Source -Language CSharp
    [StBrielleRoom214Paper]::Generate($TextureDir)
    Set-Content -Path $Marker -Value $Version -Encoding ASCII

    foreach ($File in $Required) {
        $Path = Join-Path $TextureDir $File
        if (-not (Test-Path $Path)) {
            throw "Room 214 ledger paper generation did not create $File"
        }
    }

    Write-Host "[OK] Room 214 corrected ledger paper generated in $TextureDir"
    exit 0
}
catch {
    Write-Host "[ERROR] Room 214 ledger paper generation failed." -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    exit 1
}
