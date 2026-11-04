param([string]$Out)
# Grab just the Roblox Studio window (Studio PID from the running process)
Add-Type -AssemblyName System.Drawing
Add-Type @"
using System; using System.Runtime.InteropServices;
public class W { [StructLayout(LayoutKind.Sequential)] public struct R { public int L, T, Ri, B; }
[DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr h, out R r);
[DllImport("user32.dll")] public static extern bool SetProcessDPIAware();
[DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr h);
[DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr h, int c); }
"@
[W]::SetProcessDPIAware() | Out-Null
$p = Get-Process RobloxStudioBeta | Where-Object { $_.MainWindowHandle -ne 0 } | Select-Object -First 1
# bring Studio in front of anything covering it (3 = maximize)
[W]::ShowWindow($p.MainWindowHandle, 3) | Out-Null
[W]::SetForegroundWindow($p.MainWindowHandle) | Out-Null
Start-Sleep -Milliseconds 300
$r = New-Object W+R
[W]::GetWindowRect($p.MainWindowHandle, [ref]$r) | Out-Null
$w = $r.Ri - $r.L; $h = $r.B - $r.T
$bmp = New-Object System.Drawing.Bitmap $w, $h
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.CopyFromScreen($r.L, $r.T, 0, 0, $bmp.Size)
$bmp.Save($Out, [System.Drawing.Imaging.ImageFormat]::Png)
"$($r.L),$($r.T) ${w}x${h}"
