param(
    [string]$Root = ""
)

$ErrorActionPreference = "Stop"

if ([string]::IsNullOrWhiteSpace($Root)) {
    $Root = Split-Path $PSScriptRoot -Parent
}

$Root = [System.IO.Path]::GetFullPath($Root)
$TextureDir = Join-Path $Root "stbrielle\textures\stbrielle\annex"
$Marker = Join-Path $TextureDir ".generated-v2"
$Version = "municipal-gothic-surfaces-v2-2026-10-29b"

$Required = @(
    "plaster_d.tga", "plaster_local.tga", "plaster_s.tga",
    "tile_d.tga", "tile_local.tga", "tile_s.tga",
    "stone_d.tga", "stone_local.tga", "stone_s.tga",
    "blackmetal_d.tga", "blackmetal_local.tga", "blackmetal_s.tga",
    "wood_d.tga", "wood_local.tga", "wood_s.tga",
    "brass_d.tga", "brass_local.tga", "brass_s.tga",
    "paint_d.tga", "paint_local.tga", "paint_s.tga",
    "brick_d.tga", "brick_local.tga", "brick_s.tga",
    "asphalt_d.tga", "asphalt_local.tga", "asphalt_s.tga",
    "paper_d.tga", "paper_local.tga", "paper_s.tga",
    "light_radial.tga"
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
    Write-Host "[OK] Municipal Annex texture set already generated."
    exit 0
}

New-Item -ItemType Directory -Force -Path $TextureDir | Out-Null

$Source = @'
using System;
using System.IO;

public static class StBrielleAnnexTextures
{
    const int N = 512;

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

    static double Rand(int x, int y, int seed)
    {
        return (Hash(x, y, seed) & 0x00FFFFFF) / 16777215.0;
    }

    static double Fade(double t)
    {
        return t * t * (3.0 - 2.0 * t);
    }

    static int Wrap(int v, int m)
    {
        v %= m;
        return v < 0 ? v + m : v;
    }

    static double Noise(int x, int y, int cells, int seed)
    {
        return Noise2(x, y, cells, cells, seed);
    }

    static double Noise2(int x, int y, int cellsX, int cellsY, int seed)
    {
        double gx = ((double)x / N) * cellsX;
        double gy = ((double)y / N) * cellsY;
        int x0 = (int)Math.Floor(gx);
        int y0 = (int)Math.Floor(gy);
        double tx = Fade(gx - Math.Floor(gx));
        double ty = Fade(gy - Math.Floor(gy));

        double a = Rand(Wrap(x0, cellsX), Wrap(y0, cellsY), seed);
        double b = Rand(Wrap(x0 + 1, cellsX), Wrap(y0, cellsY), seed);
        double c = Rand(Wrap(x0, cellsX), Wrap(y0 + 1, cellsY), seed);
        double d = Rand(Wrap(x0 + 1, cellsX), Wrap(y0 + 1, cellsY), seed);

        double ab = a + (b - a) * tx;
        double cd = c + (d - c) * tx;
        return ab + (cd - ab) * ty;
    }

    static double Fbm(int x, int y, int seed)
    {
        return Noise(x, y, 4, seed) * 0.50 +
               Noise(x, y, 8, seed + 17) * 0.28 +
               Noise(x, y, 16, seed + 31) * 0.15 +
               Noise(x, y, 32, seed + 47) * 0.07;
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

    static void WriteMaps(string dir, string name, byte[] diffuse, double[] height, double[] spec, double normalStrength)
    {
        byte[] normal = new byte[N * N * 3];
        byte[] specRgb = new byte[N * N * 3];

        for (int y = 0; y < N; y++)
        {
            int ym = Wrap(y - 1, N);
            int yp = Wrap(y + 1, N);
            for (int x = 0; x < N; x++)
            {
                int xm = Wrap(x - 1, N);
                int xp = Wrap(x + 1, N);
                double dx = (height[y * N + xp] - height[y * N + xm]) * normalStrength * (N / 256.0);
                double dy = (height[yp * N + x] - height[ym * N + x]) * normalStrength * (N / 256.0);
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
        byte[] d = new byte[N * N * 3]; double[] h = new double[N * N]; double[] s = new double[N * N];
        for (int y = 0; y < N; y++) for (int x = 0; x < N; x++)
        {
            double broad = Fbm(x, y, 101), pores = Noise(x, y, 64, 177);
            double repairs = Clamp((Noise(x, y, 8, 113) - 0.60) * 3.8, 0, 1);
            double stain = Clamp((Noise(x, y, 4, 127) - 0.52) * 1.8, 0, 0.45);
            double v = (broad - 0.5) * 0.16 + (pores - 0.5) * 0.035;
            Put(d, x, y, 0.54 + v - stain * 0.13 + repairs * 0.025,
                         0.52 + v - stain * 0.14, 0.45 + v * 0.85 - stain * 0.10);
            h[y * N + x] = broad * 0.16 + pores * 0.025 + repairs * 0.035;
            s[y * N + x] = 0.045 + repairs * 0.025;
        }
        WriteMaps(dir, "plaster", d, h, s, 2.3);
    }

    static void BuildTile(string dir)
    {
        byte[] d = new byte[N * N * 3]; double[] h = new double[N * N]; double[] s = new double[N * N];
        int size = N / 4;
        for (int y = 0; y < N; y++) for (int x = 0; x < N; x++)
        {
            int mx = x % size, my = y % size;
            double edge = Math.Min(Math.Min(mx, size - 1 - mx), Math.Min(my, size - 1 - my));
            double tile = Clamp((edge - 1.0) / 2.0, 0, 1);
            double variant = Rand(x / size, y / size, 201) - 0.5;
            double wear = Noise(x, y, 8, 249), mineral = Noise(x, y, 64, 231);
            double fleck = Clamp((mineral - 0.66) * 4.0, 0, 1);
            double v = variant * 0.055 + (wear - 0.5) * 0.055 + fleck * 0.075;
            Put(d, x, y, 0.06 + tile * (0.14 + v), 0.065 + tile * (0.165 + v), 0.058 + tile * (0.145 + v));
            h[y * N + x] = tile * 0.11 + mineral * 0.007;
            s[y * N + x] = 0.025 + tile * (0.18 + wear * 0.20);
        }
        WriteMaps(dir, "tile", d, h, s, 2.1);
    }

    static void BuildStone(string dir)
    {
        byte[] d = new byte[N * N * 3]; double[] h = new double[N * N]; double[] s = new double[N * N];
        int width = N / 2, height = N / 4;
        for (int y = 0; y < N; y++) for (int x = 0; x < N; x++)
        {
            int row = y / height, sx = Wrap(x + (row % 2) * width / 2, N);
            int mx = sx % width, my = y % height;
            double edge = Math.Min(Math.Min(mx, width - 1 - mx), Math.Min(my, height - 1 - my));
            double face = Clamp((edge - 1) / 3.0, 0, 1);
            double pores = Noise(x, y, 64, 337), mineral = Fbm(x, y, 301);
            double block = Rand(sx / width, row, 353) - 0.5;
            double v = (mineral - 0.5) * 0.12 + (pores - 0.5) * 0.04 + block * 0.065;
            Put(d, x, y, 0.18 + face * (0.29 + v), 0.17 + face * (0.28 + v), 0.15 + face * (0.24 + v));
            h[y * N + x] = face * 0.10 + mineral * 0.035 + pores * 0.015;
            s[y * N + x] = 0.025 + face * 0.035;
        }
        WriteMaps(dir, "stone", d, h, s, 2.5);
    }

    static void BuildBlackMetal(string dir)
    {
        byte[] d = new byte[N * N * 3]; double[] h = new double[N * N]; double[] s = new double[N * N];
        for (int y = 0; y < N; y++) for (int x = 0; x < N; x++)
        {
            double n = Fbm(x, y, 401), fine = Noise(x, y, 64, 433);
            double rust = Clamp((Fbm(x, y, 451) - 0.60) * 3.7, 0, 1);
            // Periodic scratches keep the painted iron repeat continuous.
            double scratch = Math.Pow(0.5 + 0.5 * Math.Sin(x * 2.0 * Math.PI / N * 71.0), 30.0)
                            * Clamp((Noise(x, y, 16, 477) - 0.55) * 4.0, 0, 1);
            double v = (n - 0.5) * 0.04 + (fine - 0.5) * 0.012;
            Put(d, x, y, 0.083 + v + rust * 0.12 + scratch * 0.07,
                         0.090 + v + rust * 0.035 + scratch * 0.065, 0.088 + v + scratch * 0.058);
            h[y * N + x] = fine * 0.012 + rust * 0.025 - scratch * 0.012;
            s[y * N + x] = 0.30 + n * 0.15 - rust * 0.20 + scratch * 0.15;
        }
        WriteMaps(dir, "blackmetal", d, h, s, 1.8);
    }

    static void BuildWood(string dir)
    {
        byte[] d = new byte[N * N * 3]; double[] h = new double[N * N]; double[] s = new double[N * N];
        for (int y = 0; y < N; y++) for (int x = 0; x < N; x++)
        {
            int warpedX = Wrap(x + (int)((Noise2(x, y, 4, 2, 501) - 0.5) * 28.0), N);
            double grain = Noise2(warpedX, y, 64, 4, 513) * 0.72 + Noise2(warpedX, y, 128, 8, 521) * 0.28;
            double fine = Noise(x, y, 64, 529), wear = Noise2(x, y, 8, 2, 547);
            double v = (grain - 0.5) * 0.10 + (fine - 0.5) * 0.012 + (wear - 0.5) * 0.07;
            Put(d, x, y, 0.235 + v, 0.115 + v * 0.65, 0.058 + v * 0.40);
            h[y * N + x] = grain * 0.015 + fine * 0.005;
            s[y * N + x] = 0.12 + wear * 0.14;
        }
        WriteMaps(dir, "wood", d, h, s, 1.6);
    }

    static void BuildBrass(string dir)
    {
        byte[] d = new byte[N * N * 3]; double[] h = new double[N * N]; double[] s = new double[N * N];
        for (int y = 0; y < N; y++) for (int x = 0; x < N; x++)
        {
            double n = Fbm(x, y, 601), fine = Noise(x, y, 64, 619);
            double tarnish = Clamp((Fbm(x, y, 641) - 0.53) * 2.9, 0, 0.7);
            double v = (n - 0.5) * 0.12 + (fine - 0.5) * 0.025;
            Put(d, x, y, (0.48 + v) * (1 - tarnish * 0.60),
                         (0.33 + v * 0.75) * (1 - tarnish * 0.28), (0.15 + v * 0.40) + tarnish * 0.03);
            h[y * N + x] = fine * 0.008 + tarnish * 0.02;
            s[y * N + x] = 0.55 + n * 0.12 - tarnish * 0.50;
        }
        WriteMaps(dir, "brass", d, h, s, 1.4);
    }

    static void BuildPaint(string dir)
    {
        byte[] d = new byte[N * N * 3]; double[] h = new double[N * N]; double[] s = new double[N * N];
        for (int y = 0; y < N; y++) for (int x = 0; x < N; x++)
        {
            double n = Fbm(x, y, 701), fine = Noise(x, y, 64, 727);
            double chip = Clamp((Noise(x, y, 32, 739) - 0.73) * 5, 0, 1);
            double v = 0.76 + (n - 0.5) * 0.12 + (fine - 0.5) * 0.025 - chip * 0.20;
            Put(d, x, y, v, v, v);
            h[y * N + x] = fine * 0.009 - chip * 0.02;
            s[y * N + x] = 0.15 + n * 0.06 - chip * 0.12;
        }
        WriteMaps(dir, "paint", d, h, s, 1.9);
    }

    static void BuildBrick(string dir)
    {
        byte[] d = new byte[N * N * 3]; double[] h = new double[N * N]; double[] s = new double[N * N];
        int width = N / 4, height = N / 8;
        for (int y = 0; y < N; y++) for (int x = 0; x < N; x++)
        {
            int row = y / height, sx = Wrap(x + (row % 2) * width / 2, N);
            int mx = sx % width, my = y % height;
            double edge = Math.Min(Math.Min(mx, width - 1 - mx), Math.Min(my, height - 1 - my));
            double face = Clamp((edge - 1) / 3.0, 0, 1);
            double n = Fbm(x, y, 801), grit = Noise(x, y, 64, 817);
            double block = Rand(sx / width, row, 827) - 0.5;
            double soot = Clamp((Noise(x, y, 8, 839) - 0.58) * 2, 0, 0.45);
            double v = block * 0.12 + (grit - 0.5) * 0.065 + (n - 0.5) * 0.08 - soot * 0.12;
            Put(d, x, y, 0.16 + face * (0.22 + v), 0.16 + face * (0.045 + v * 0.65), 0.135 + face * (0.005 + v * 0.45));
            h[y * N + x] = face * 0.10 + grit * 0.016;
            s[y * N + x] = 0.02 + face * 0.045;
        }
        WriteMaps(dir, "brick", d, h, s, 2.3);
    }

    static void BuildAsphalt(string dir)
    {
        byte[] d = new byte[N * N * 3]; double[] h = new double[N * N]; double[] s = new double[N * N];
        for (int y = 0; y < N; y++) for (int x = 0; x < N; x++)
        {
            double n = Fbm(x, y, 901), aggregate = Noise(x, y, 64, 917);
            double wet = Clamp((Noise(x, y, 4, 937) - 0.40) * 3.5, 0, 1);
            double speck = Clamp((aggregate - 0.60) * 3.0, 0, 1);
            double v = 0.095 + (n - 0.5) * 0.035 + speck * 0.06;
            Put(d, x, y, v * (1 - wet * 0.26), (v + 0.008) * (1 - wet * 0.24), (v + 0.013) * (1 - wet * 0.20));
            h[y * N + x] = aggregate * 0.022 * (1 - wet * 0.85) + n * 0.008;
            s[y * N + x] = 0.07 + wet * 0.52;
        }
        WriteMaps(dir, "asphalt", d, h, s, 2.0);
    }

    static void BuildPaper(string dir)
    {
        byte[] d = new byte[N * N * 3]; double[] h = new double[N * N]; double[] s = new double[N * N];
        for (int y = 0; y < N; y++) for (int x = 0; x < N; x++)
        {
            double fiber = Noise(x, y, 64, 1001), stain = Noise(x, y, 8, 1017);
            double rule = y % (N / 16) < 2 ? 0.035 : 0;
            double v = (fiber - 0.5) * 0.04 + (stain - 0.5) * 0.07 - rule;
            Put(d, x, y, 0.76 + v, 0.69 + v, 0.53 + v * 0.80);
            h[y * N + x] = fiber * 0.005;
            s[y * N + x] = 0.035;
        }
        WriteMaps(dir, "paper", d, h, s, 1.3);
    }

    static void BuildLightProfile(string dir)
    {
        byte[] d = new byte[N * N * 3];
        for (int y = 0; y < N; y++) for (int x = 0; x < N; x++)
        {
            double u = 2.0 * x / (N - 1) - 1, v = 2.0 * y / (N - 1) - 1;
            double energy = Math.Pow(Clamp(1 - u * u - v * v, 0, 1), 1.25);
            Put(d, x, y, energy, energy, energy);
        }
        WriteTga(Path.Combine(dir, "light_radial.tga"), d);
    }

    public static void Generate(string dir)
    {
        Directory.CreateDirectory(dir);
        BuildPlaster(dir);
        BuildTile(dir);
        BuildStone(dir);
        BuildBlackMetal(dir);
        BuildWood(dir);
        BuildBrass(dir);
        BuildPaint(dir);
        BuildBrick(dir);
        BuildAsphalt(dir);
        BuildPaper(dir);
        BuildLightProfile(dir);
    }
}
'@

try {
    Write-Host "[BUILD] Generating original Municipal Annex texture set..."
    Add-Type -TypeDefinition $Source -Language CSharp
    [StBrielleAnnexTextures]::Generate($TextureDir)

    foreach ($File in $Required) {
        $Path = Join-Path $TextureDir $File
        if (-not (Test-Path $Path)) {
            throw "Texture generation did not create $File"
        }
    }

    Set-Content -Path $Marker -Value $Version -Encoding ASCII
    Write-Host "[OK] Municipal Annex textures generated in $TextureDir"
    exit 0
}
catch {
    Write-Host "[ERROR] Municipal Annex texture generation failed." -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    exit 1
}
