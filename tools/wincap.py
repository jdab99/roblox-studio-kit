"""Capture the Roblox Studio window itself (Windows Graphics Capture), not the screen.
Other windows on top do NOT get into the picture and Studio never has to come to the front.
Studio must not be minimized (restore_studio() un-minimizes it without activating it).
The viewport is found from the director's full-screen magenta marker, so window size/layout doesn't matter.
"""
import ctypes, os, subprocess, threading, time
import numpy as np
from windows_capture import WindowsCapture

user32 = ctypes.windll.user32

# Which Studio this process drives (11-03: two Studios can film at once). "Place1" = the main Studio (window
# "Place1 - Roblox Studio"); "Place2" = the second one opened from film\studio2\Place2.rbxl, on the 2nd monitor.
STUDIO = os.environ.get("BLOCKY_STUDIO", "Place1")


def pick_studio(studios):
    """MCP studio id for STUDIO. Place2's MCP name can be null, so for Place2 take the one that is not Place1."""
    for s in studios:
        if s.get("name") == STUDIO:
            return s["id"]
    if STUDIO != "Place1":
        others = [s for s in studios if s.get("name") != "Place1"]
        if len(others) == 1:
            return others[0]["id"]
    return None


def studio_hwnd():
    found = []

    @ctypes.WINFUNCTYPE(ctypes.c_bool, ctypes.c_void_p, ctypes.c_void_p)
    def cb(h, _):
        n = user32.GetWindowTextLengthW(h)
        if n and user32.IsWindowVisible(h):
            buf = ctypes.create_unicode_buffer(n + 1)
            user32.GetWindowTextW(h, buf, n + 1)
            t = buf.value
            if t.endswith("- Roblox Studio") and (t.startswith(STUDIO + " ") or (STUDIO + ".rbxl") in t):
                found.append(h)
        return True
    user32.EnumWindows(cb, 0)
    if not found:
        raise RuntimeError(f"Roblox Studio window for {STUDIO} not found")
    return found[0]


def restore_studio():
    """Un-minimize Studio and make it fill ITS monitor's work area (big viewport = sharp video), without activating it."""
    h = studio_hwnd()
    if user32.IsIconic(h):
        user32.ShowWindow(h, 4)  # SW_SHOWNOACTIVATE
        time.sleep(1.0)
    if not user32.IsZoomed(h):
        class RECT(ctypes.Structure):
            _fields_ = [("l", ctypes.c_long), ("t", ctypes.c_long), ("r", ctypes.c_long), ("b", ctypes.c_long)]

        class MONITORINFO(ctypes.Structure):
            _fields_ = [("cb", ctypes.c_ulong), ("mon", RECT), ("work", RECT), ("flags", ctypes.c_ulong)]
        mi = MONITORINFO()
        mi.cb = ctypes.sizeof(MONITORINFO)
        user32.MonitorFromWindow.restype = ctypes.c_void_p
        user32.GetMonitorInfoW(ctypes.c_void_p(user32.MonitorFromWindow(ctypes.c_void_p(h), 2)), ctypes.byref(mi))
        wa = mi.work
        user32.SetWindowPos(h, 0, wa.l, wa.t, wa.r - wa.l, wa.b - wa.t, 0x0004 | 0x0010)  # NOZORDER | NOACTIVATE
        time.sleep(1.0)
    return h


class Cap:
    """Keeps the latest frame of the Studio window. Optional sink(frame, t) is called for every frame."""

    def __init__(self):
        # Keep the display awake while capturing: a sleeping display stops Studio drawing and the take
        # silently freezes on one frame (reel 09, 11-02). ES_CONTINUOUS | ES_SYSTEM_REQUIRED | ES_DISPLAY_REQUIRED.
        ctypes.windll.kernel32.SetThreadExecutionState(0x80000000 | 0x1 | 0x2)
        self.hwnd = restore_studio()
        self.latest, self.n, self.sink = None, 0, None
        self.cv = threading.Condition()
        self.cap = WindowsCapture(cursor_capture=False, draw_border=False, window_hwnd=self.hwnd)

        @self.cap.event
        def on_frame_arrived(frame, control):
            f = frame.frame_buffer
            t = time.perf_counter()
            if self.sink:
                self.sink(f, t)
            with self.cv:
                self.latest = f.copy() if not self.sink else None
                self.n += 1
                self.cv.notify_all()

        @self.cap.event
        def on_closed():
            pass

        self.ctl = self.cap.start_free_threaded()

    def frame(self, timeout=5.0):
        """Wait for a NEW frame and return it (BGRA numpy)."""
        with self.cv:
            n0 = self.n
            if not self.cv.wait_for(lambda: self.n > n0 + 1 and self.latest is not None, timeout):
                raise RuntimeError("no frames from the Studio window (minimized? Play stopped?)")
            return self.latest

    def stop(self):
        self.ctl.stop()
        ctypes.windll.kernel32.SetThreadExecutionState(0x80000000)


def magenta_box(f):
    """Bounding box (x, y, w, h) of the magenta marker = the 3D viewport, even sizes."""
    b, g, r = f[:, :, 0].astype(int), f[:, :, 1].astype(int), f[:, :, 2].astype(int)
    m = (r > 200) & (g < 70) & (b > 200)
    ys, xs = np.nonzero(m)
    if len(xs) < 10000:
        raise RuntimeError("magenta marker not visible in the Studio window")
    x0, x1, y0, y1 = xs.min(), xs.max() + 1, ys.min(), ys.max() + 1
    w, h = (x1 - x0) // 2 * 2, (y1 - y0) // 2 * 2
    return int(x0), int(y0), int(w), int(h)


class Recorder:
    """Writes the cropped viewport to ffmpeg at a constant 30 fps on the wall clock (repeats/drops frames to keep time)."""

    def __init__(self, cap, box, out, vf, fps=30):
        self.cap, self.box, self.fps = cap, box, fps
        x, y, w, h = box
        self.ff = subprocess.Popen(["ffmpeg", "-v", "error", "-y", "-f", "rawvideo", "-pix_fmt", "bgra", "-s", f"{w}x{h}",
                                    "-r", str(fps), "-i", "-", "-vf", vf, "-c:v", "libx264", "-preset", "veryfast",
                                    "-crf", "16", "-pix_fmt", "yuv420p", out], stdin=subprocess.PIPE)
        self.t0, self.written, self.dup, self.got = None, 0, 0, 0
        self.lock = threading.Lock()
        self.closed = False
        cap.sink = self.sink

    def sink(self, f, t):
        x, y, w, h = self.box
        with self.lock:
            if self.closed:
                return
            if self.t0 is None:
                self.t0 = t
            self.got += 1
            want = int((t - self.t0) * self.fps) + 1
            if want <= self.written:
                return  # faster than 30 fps: drop
            data = np.ascontiguousarray(f[y:y + h, x:x + w]).tobytes()
            k = want - self.written
            self.dup += k - 1
            for _ in range(k):
                self.ff.stdin.write(data)
            self.written = want

    def close(self):
        with self.lock:
            self.closed = True
            self.cap.sink = None
            self.ff.stdin.close()
        self.ff.wait()
        msg = f"{self.written} frames written ({self.got} captured, {self.dup} repeated to hold 30 fps)"
        if self.written and self.dup > self.written * 0.02:
            msg += "\nWARNING: over 2% repeated frames = Studio stopped drawing (display asleep, minimized or covered?). Check the take for a freeze."
        return msg
