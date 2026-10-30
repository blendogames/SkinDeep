param([string]$Root = "")
$ErrorActionPreference = "Stop"
if ([string]::IsNullOrWhiteSpace($Root)) { $Root = Split-Path $PSScriptRoot -Parent }
$Root = [System.IO.Path]::GetFullPath($Root)
Add-Type -AssemblyName System.Drawing
$Code = @'
using System;
using System.IO;
using System.Drawing;
using System.Drawing.Imaging;
using System.Runtime.InteropServices;
public static class MunicipalMaterialPreview {
    static Bitmap LoadTga(string path) {
        byte[] data = File.ReadAllBytes(path);
        int w = data[12] | data[13] << 8, h = data[14] | data[15] << 8;
        if (data[2] != 2 || data[16] != 24 || data[17] != 32 || data.Length != 18 + w * h * 3)
            throw new Exception("Unexpected TGA layout: " + path);
        Bitmap image = new Bitmap(w, h, PixelFormat.Format24bppRgb);
        BitmapData locked = image.LockBits(new Rectangle(0, 0, w, h), ImageLockMode.WriteOnly, PixelFormat.Format24bppRgb);
        try {
            for (int y = 0; y < h; y++)
                Marshal.Copy(data, 18 + y * w * 3, IntPtr.Add(locked.Scan0, y * locked.Stride), w * 3);
        } finally { image.UnlockBits(locked); }
        return image;
    }
    public static void Build(string root) {
        string[] names = { "plaster", "tile", "stone", "blackmetal", "wood", "brass", "paint", "brick", "asphalt", "paper", "room214_plaster", "room214_tile", "room214_wood", "room214_metal", "room214_paper" };
        string directory = Path.Combine(root, "stbrielle/textures/stbrielle/annex");
        using (Bitmap board = new Bitmap(1000, 750))
        using (Graphics graphics = Graphics.FromImage(board))
        using (Font title = new Font("Segoe UI", 22, FontStyle.Bold))
        using (Font label = new Font("Segoe UI", 10))
        using (Brush ink = new SolidBrush(Color.FromArgb(222, 210, 183))) {
            graphics.Clear(Color.FromArgb(19, 23, 24));
            graphics.DrawString("ST. BRIELLE / MUNICIPAL GOTHIC", title, ink, 24, 18);
            graphics.DrawString("Generated diffuse maps / asset inspection sheet / not an in-game screenshot", label, ink, 24, 57);
            for (int i = 0; i < names.Length; i++) {
                int x = 24 + (i % 5) * 196, y = 98 + (i / 5) * 210;
                using (Bitmap texture = LoadTga(Path.Combine(directory, names[i] + "_d.tga")))
                    graphics.DrawImage(texture, new Rectangle(x, y, 172, 172));
                graphics.DrawString(names[i].Replace('_', ' '), label, ink, x, y + 179);
            }
            string output = Path.Combine(root, "graphics-validation");
            Directory.CreateDirectory(output);
            board.Save(Path.Combine(output, "municipal-materials.png"), ImageFormat.Png);
        }
    }
}
'@
Add-Type -TypeDefinition $Code -ReferencedAssemblies System.Drawing -Language CSharp
[MunicipalMaterialPreview]::Build($Root)
Write-Host "[OK] Material inspection sheet created."
