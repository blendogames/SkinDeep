param(
    [string]$Root = ""
)

$ErrorActionPreference = "Stop"

if ([string]::IsNullOrWhiteSpace($Root)) {
    $Root = Split-Path $PSScriptRoot -Parent
}

$Root = [System.IO.Path]::GetFullPath($Root)
$TextureDir = Join-Path $Root "stbrielle\textures\stbrielle\annex"
$Marker = Join-Path $TextureDir ".generated-room214-v2"
$Version = "st-brielle-room214-corrected-v2-2026-10-29b"

$Required = @(
    "room214_plaster_d.tga", "room214_plaster_local.tga", "room214_plaster_s.tga",
    "room214_tile_d.tga", "room214_tile_local.tga", "room214_tile_s.tga",
    "room214_wood_d.tga", "room214_wood_local.tga", "room214_wood_s.tga",
    "room214_metal_d.tga", "room214_metal_local.tga", "room214_metal_s.tga"
)

$Ready = $false
if (Test-Path $Marker) {
    $MarkerValue = (Get-Content -Raw -Path $Marker).Trim()
    if ($MarkerValue -eq $Version) {
        $Ready = $true
        foreach ($File in $Required) {
            if (-not (Test-Path (Join-Path $TextureDir $File)) -or
                (Get-Item (Join-Path $TextureDir $File)).Length -ne (18 + 512 * 512 * 3)) {
                $Ready = $false
                break
            }
        }
    }
}

if ($Ready) {
    Write-Host "[OK] Room 214 corrected texture set already generated."
    exit 0
}

New-Item -ItemType Directory -Force -Path $TextureDir | Out-Null

$Source = @'
using System;
using System.IO;

public static class StBrielleRoom214Textures
{
    const int N = 512;
    const double Tau = Math.PI * 2.0;

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

    static int Cell(int value, int size) { value %= size; return value < 0 ? value + size : value; }
    static double Noise2(int x, int y, int cellsX, int cellsY, int seed)
    {
        double gx = (double)x / N * cellsX, gy = (double)y / N * cellsY;
        int ix = (int)Math.Floor(gx), iy = (int)Math.Floor(gy);
        double tx = gx - ix, ty = gy - iy;
        tx = tx * tx * (3 - 2 * tx); ty = ty * ty * (3 - 2 * ty);
        double a = Grain(Cell(ix, cellsX), Cell(iy, cellsY), seed);
        double b = Grain(Cell(ix + 1, cellsX), Cell(iy, cellsY), seed);
        double c = Grain(Cell(ix, cellsX), Cell(iy + 1, cellsY), seed);
        double d = Grain(Cell(ix + 1, cellsX), Cell(iy + 1, cellsY), seed);
        return (a + (b - a) * tx) * (1 - ty) + (c + (d - c) * tx) * ty;
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

    static void WriteMaps(string dir, string name, byte[] diffuse, double[] height, double[] spec, double strength)
    {
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
                double dx = (height[y * N + xp] - height[y * N + xm]) * strength * (N / 256.0);
                double dy = (height[yp * N + x] - height[ym * N + x]) * strength * (N / 256.0);
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

        WriteTga(Path.Combine(dir, name + "_d.tga"), diffuse);
        WriteTga(Path.Combine(dir, name + "_local.tga"), normal);
        WriteTga(Path.Combine(dir, name + "_s.tga"), specRgb);
    }

    static void BuildPlaster(string dir)
    {
        byte[] d = new byte[N * N * 3];
        double[] h = new double[N * N];
        double[] s = new double[N * N];

        for (int y = 0; y < N; y++) for (int x = 0; x < N; x++)
        {
            double px = x / (double)N;
            double py = y / (double)N;
            double fine = (Grain(x, y, 901) - 0.5) * 0.030;
            double broad = Math.Sin(Tau * px * 2.0 + Math.Sin(Tau * py) * 0.8) * 0.022;
            double breath = Math.Sin(Tau * px + Math.Sin(Tau * py * 2.0) * 0.45) * 0.5 + 0.5;

            // Faint erased-writing stain: never cleanly readable, but too regular to be water damage.
            double scriptA = Math.Sin(px * Tau * 4.0 + Math.Sin(py * Tau) * 1.1);
            double scriptB = Math.Sin(py * Tau * 3.0 + Math.Sin(px * Tau * 3.0));
            double erased = Math.Pow(Clamp((scriptA + scriptB) * 0.25 + 0.44, 0.0, 1.0), 5.0) * 0.055;

            double v = broad + fine - erased;
            Put(d, x, y, 0.515 + v, 0.505 + v * 0.98, 0.435 + v * 0.92);
            h[y * N + x] = 0.42 + broad * 1.8 + fine * 0.5 + breath * 0.038 - erased * 0.45;
            s[y * N + x] = 0.105 + breath * 0.025 - erased * 0.18;
        }
        WriteMaps(dir, "room214_plaster", d, h, s, 3.0);
    }

    static void BuildTile(string dir)
    {
        byte[] d = new byte[N * N * 3];
        double[] h = new double[N * N];
        double[] s = new double[N * N];

        for (int y = 0; y < N; y++) for (int x = 0; x < N; x++)
        {
            // Vertical grout lines drift sideways over the texture while horizontal lines stay square.
            // The floor reads as ordinary tile until the eye tries to follow a joint across the room.
            int shift = (int)Math.Round(Math.Sin((y / (double)N) * Tau) * 14.0);
            int mx = Wrap(x + shift) % (N / 4);
            int my = y % (N / 4);
            double seam = (mx <= 2 || mx >= N / 4 - 2 || my <= 2 || my >= N / 4 - 2) ? 1.0 : 0.0;
            double n = (Grain(x, y, 1001) - 0.5) * 0.035;
            double sheen = 0.5 + 0.5 * Math.Sin((x + y) / (double)N * Tau * 2.0);
            double v = n - seam * 0.040;
            Put(d, x, y, 0.195 + v, 0.220 + v, 0.198 + v);
            h[y * N + x] = 0.12 + n * 0.15 - seam * 0.10;
            s[y * N + x] = 0.18 + sheen * 0.11 - seam * 0.12;
        }
        WriteMaps(dir, "room214_tile", d, h, s, 3.1);
    }

    static void BuildWood(string dir)
    {
        byte[] d = new byte[N * N * 3];
        double[] h = new double[N * N];
        double[] s = new double[N * N];

        for (int y = 0; y < N; y++) for (int x = 0; x < N; x++)
        {
            double horizontal = Noise2(x, y, 64, 4, 1113) * 0.72 + Noise2(x, y, 128, 8, 1119) * 0.28;
            double vertical = Noise2(x, y, 4, 64, 1113) * 0.72 + Noise2(x, y, 8, 128, 1119) * 0.28;
            double blend = 0.5 - 0.5 * Math.Cos(x / (double)N * Tau);
            double grain = horizontal * (1.0 - blend) + vertical * blend;
            double noise = (Grain(x, y, 1101) - 0.5) * 0.045;
            double v = (grain - 0.5) * 0.10 + noise * 0.25;
            Put(d, x, y, 0.215 + v, 0.105 + v * 0.52, 0.052 + v * 0.30);
            h[y * N + x] = 0.10 + grain * 0.018 + noise * 0.10;
            s[y * N + x] = 0.10 + grain * 0.10;
        }
        WriteMaps(dir, "room214_wood", d, h, s, 2.7);
    }

    static void BuildMetal(string dir)
    {
        byte[] d = new byte[N * N * 3];
        double[] h = new double[N * N];
        double[] s = new double[N * N];

        for (int y = 0; y < N; y++) for (int x = 0; x < N; x++)
        {
            double angleScratch = Math.Sin(x / (double)N * Tau * 3.0 + y / (double)N * Tau * 2.0 + Math.Sin((x - y) / (double)N * Tau) * 2.0);
            double scratch = Math.Pow(Clamp(angleScratch * 0.5 + 0.5, 0.0, 1.0), 18.0);
            double noise = (Grain(x, y, 1201) - 0.5) * 0.020;
            double rust = Math.Pow(Clamp(Noise2(x, y, 16, 16, 1229) - 0.56, 0.0, 1.0) * 2.7, 2.0);
            Put(d, x, y, 0.078 + noise + rust * 0.090 + scratch * 0.018,
                           0.085 + noise + rust * 0.026 + scratch * 0.020,
                           0.087 + noise + rust * 0.006 + scratch * 0.018);
            h[y * N + x] = 0.25 + noise * 0.7 + rust * 0.06 - scratch * 0.08;
            s[y * N + x] = 0.34 - rust * 0.20 + scratch * 0.20;
        }
        WriteMaps(dir, "room214_metal", d, h, s, 2.2);
    }

    public static void Generate(string dir)
    {
        Directory.CreateDirectory(dir);
        BuildPlaster(dir);
        BuildTile(dir);
        BuildWood(dir);
        BuildMetal(dir);
    }
}
'@

try {
    Write-Host "[BUILD] Generating Room 214 corrected texture set..."
    Add-Type -TypeDefinition $Source -Language CSharp
    [StBrielleRoom214Textures]::Generate($TextureDir)

    foreach ($File in $Required) {
        $Path = Join-Path $TextureDir $File
        if (-not (Test-Path $Path)) {
            throw "Room 214 texture generation did not create $File"
        }
    }

    Set-Content -Path $Marker -Value $Version -Encoding ASCII
    Write-Host "[OK] Room 214 corrected textures generated in $TextureDir"
    exit 0
}
catch {
    Write-Host "[ERROR] Room 214 texture generation failed." -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    exit 1
}
