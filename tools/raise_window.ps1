# Raise a top-level window (by title suffix/prefix match) in z-order WITHOUT activating it (no focus change).
param([string]$Match)
Add-Type @'
using System; using System.Text; using System.Runtime.InteropServices;
public class ZO {
  public delegate bool EP(IntPtr h, IntPtr l);
  [DllImport("user32.dll")] public static extern bool EnumWindows(EP f, IntPtr l);
  [DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr h);
  [DllImport("user32.dll")] public static extern int GetWindowText(IntPtr h, StringBuilder s, int n);
  [DllImport("user32.dll")] public static extern bool SetWindowPos(IntPtr h, IntPtr after, int x, int y, int cx, int cy, uint f);
  public static IntPtr Find(string m) { IntPtr r = IntPtr.Zero; EnumWindows((h, l) => { if (!IsWindowVisible(h)) return true; var sb = new StringBuilder(256); GetWindowText(h, sb, 256); if (sb.ToString().Contains(m)) { r = h; return false; } return true; }, IntPtr.Zero); return r; }
}
'@
$h = [ZO]::Find($Match)
if ($h -eq [IntPtr]::Zero) { "not found: $Match"; exit 1 }
# SWP_NOSIZE 1 | SWP_NOMOVE 2 | SWP_NOACTIVATE 0x10 ; HWND_TOP = 0
[ZO]::SetWindowPos($h, [IntPtr]::Zero, 0, 0, 0, 0, 0x13) | Out-Null
"raised: $Match"
