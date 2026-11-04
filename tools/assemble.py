"""Finish a reel: one-word captions (Ralph style) + narration + music bed + SFX cues, mastered to -13 LUFS / -1 dBTP.
usage: python tools/assemble.py <reel_dir> <video.mp4> <out.mp4>
reel_dir holds narration.mp3, words.json, sfx.json (cue list; sfx names = file names in assets/sfx (or $KIT_SFX_DIR), "SYNTH:x" = made here).
"""
import json, os, re, subprocess, sys, tempfile

KIT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SFX_DIR = os.environ.get("KIT_SFX_DIR", os.path.join(KIT, "assets", "sfx")).replace("\\", "/")
FONTS = os.environ.get("KIT_FONTS_DIR", os.path.join(KIT, "assets", "fonts")).replace("\\", "/")
reel, video, out = sys.argv[1], sys.argv[2], sys.argv[3]
tmp = tempfile.mkdtemp(prefix="reel_")


def run(cmd):
    r = subprocess.run(cmd, capture_output=True, text=True)
    if r.returncode != 0:
        sys.exit("FAILED: " + " ".join(cmd[:6]) + "\n" + r.stderr[-2000:])
    return r


def dur(f):
    return float(run(["ffprobe", "-v", "error", "-show_entries", "format=duration", "-of", "csv=p=0", f]).stdout.strip())


# ---------------------------------------------------------------- captions
words = json.load(open(os.path.join(reel, "words.json"), encoding="utf-8"))


def ts(t):
    h, m, s = int(t // 3600), int(t % 3600 // 60), t % 60
    return f"{h}:{m:02d}:{s:05.2f}"


ass = ["[Script Info]", "ScriptType: v4.00+", "PlayResX: 1080", "PlayResY: 1920", "WrapStyle: 2", "",
       "[V4+ Styles]",
       "Format: Name, Fontname, Fontsize, PrimaryColour, SecondaryColour, OutlineColour, BackColour, Bold, Italic, Underline, StrikeOut, "
       "ScaleX, ScaleY, Spacing, Angle, BorderStyle, Outline, Shadow, Alignment, MarginL, MarginR, MarginV, Encoding",
       # 11-03 (competitor research, research\FORMULA.md): top channels caption bigger + bolder, ~70% down the
       # screen over the chest so faces stay clear. Was Poppins SemiBold 82, centered.
       "Style: W,Poppins ExtraBold,150,&H00FFFFFF,&H00FFFFFF,&H00101010,&H96000000,0,0,0,0,100,100,0,0,1,5,3,2,40,40,540,1", "",
       "[Events]", "Format: Layer, Start, End, Style, Name, MarginL, MarginR, MarginV, Effect, Text"]
for i, w in enumerate(words):
    text = re.sub(r"[^\w'-]", "", w["w"]).strip("-").lower()  # 11-03: keep hyphens ("forty-seven", "barks-a-lot")
    if not text:
        continue
    start = w["start"]
    nxt = words[i + 1]["start"] if i + 1 < len(words) else w["end"] + 0.6
    end = min(nxt, w["end"] + 0.45) if nxt - w["end"] > 0.45 else nxt
    ass.append(f"Dialogue: 0,{ts(start)},{ts(end)},W,,0,0,0,,{{\\fscx86\\fscy86\\t(0,90,\\fscx100\\fscy100)}}{text}")
ass_path = os.path.join(tmp, "captions.ass")
open(ass_path, "w", encoding="utf-8").write("\n".join(ass) + "\n")
print("captions:", len(ass) - 13, "words")

# ---------------------------------------------------------------- synth sounds
synth = {
    "siren": "0.5*sin(2*PI*(720*t-(430/PI)*cos(PI*t)))+0.16*sin(4*PI*(720*t-(430/PI)*cos(PI*t)))+0.08*sin(6*PI*(720*t-(430/PI)*cos(PI*t)))",
    "powerdown": "0.7*sin(2*PI*(420*t-230*t*t))*exp(-1.2*t)+0.2*sin(4*PI*(420*t-230*t*t))*exp(-1.5*t)",
}
synth_len = {"siren": 9.0, "powerdown": 0.9}


def synth_file(name):
    p = os.path.join(tmp, f"synth_{name}.wav")
    if not os.path.exists(p):
        L = synth_len[name]
        af = "aecho=0.8:0.6:120|260:0.35|0.2,lowpass=f=3200" if name == "siren" else "lowpass=f=2500"
        run(["ffmpeg", "-v", "error", "-y", "-f", "lavfi", "-i", f"aevalsrc={synth[name]}:s=44100:d={L}",
             "-af", f"{af},afade=t=in:d={min(0.4, L / 4)},afade=t=out:st={L - min(1.2, L / 2)}:d={min(1.2, L / 2)}", "-ac", "2", p])
    return p


def sfx_file(name):
    if name.startswith("SYNTH:"):
        return synth_file(name[6:])
    for root, _, files in os.walk(SFX_DIR):
        if "candidates" in root:
            continue
        for f in files:
            if os.path.splitext(f)[0] == name and f.lower().endswith((".mp3", ".wav")):
                return os.path.join(root, f)
    sys.exit("missing sfx " + name)


# ---------------------------------------------------------------- mix
cfg = json.load(open(os.path.join(reel, "sfx.json"), encoding="utf-8"))
narr = os.path.join(reel, "narration.mp3")
vlen = dur(video)
# music: one bed {"file","lufs"} or a list of acts [{"file","lufs","start","end","from"(s into the track),"fin","fout"}]
music = cfg["music"] if isinstance(cfg["music"], list) else [dict(cfg["music"], start=0, end=vlen, fin=1, fout=2.2)]
inputs = ["-i", narr]
fil = [f"[0:a]aresample=44100,aformat=channel_layouts=stereo,apad=whole_dur={vlen:.3f}[v]"]
labels = ["[v]"]
for k, m in enumerate(music):
    inputs += ["-i", m["file"]]
    a, b = m["start"], min(m.get("end", vlen), vlen)
    L, fin, fout, off = b - a, m.get("fin", 0.15), m.get("fout", 0.6), m.get("from", 0)
    ms = int(a * 1000)
    fil.append(f"[{k + 1}:a]aresample=44100,aformat=channel_layouts=stereo,atrim={off:.3f}:{off + L:.3f},asetpts=PTS-STARTPTS,"
               f"loudnorm=I={m['lufs']}:TP=-6:LRA=11,afade=t=in:d={fin},afade=t=out:st={max(0, L - fout):.3f}:d={fout},"
               f"adelay={ms}|{ms}[m{k}]")
    labels.append(f"[m{k}]")
base = len(music) + 1
for k, c in enumerate(cfg["cues"]):
    f = sfx_file(c["sfx"])
    inputs += ["-i", f]
    idx = k + base
    trim = f",atrim=0:{c['len']},afade=t=out:st={max(0, c['len'] - 0.5)}:d=0.5" if "len" in c else ""
    ms = int(c["t"] * 1000)
    fil.append(f"[{idx}:a]aresample=44100,aformat=channel_layouts=stereo{trim},"
               f"volume={c['db'] - 9}dB,adelay={ms}|{ms}[s{k}]")
    labels.append(f"[s{k}]")
fil.append("".join(labels) + f"amix=inputs={len(labels)}:normalize=0:duration=first[pre]")
mix = os.path.join(tmp, "mix.wav")
run(["ffmpeg", "-v", "error", "-y", *inputs, "-filter_complex", ";".join(fil), "-map", "[pre]", "-t", f"{vlen:.3f}", mix])

# two-pass master to -13 LUFS / -1 dBTP
m = run(["ffmpeg", "-hide_banner", "-i", mix, "-af", "loudnorm=I=-13:TP=-1.5:LRA=11:print_format=json", "-f", "null", "-"]).stderr
j = json.loads(m[m.rfind("{"):m.rfind("}") + 1])
master = os.path.join(tmp, "master.wav")
run(["ffmpeg", "-v", "error", "-y", "-i", mix, "-af",
     f"loudnorm=I=-13:TP=-1.5:LRA=11:measured_I={j['input_i']}:measured_TP={j['input_tp']}:measured_LRA={j['input_lra']}:"
     f"measured_thresh={j['input_thresh']}:offset={j['target_offset']}:linear=true,alimiter=limit=0.75:level=false",
     "-ar", "48000", master])

if "--keep-picture" in sys.argv:  # <video> is a finished reel: copy its picture untouched, swap in the new audio
    run(["ffmpeg", "-v", "error", "-y", "-i", video, "-i", master, "-map", "0:v", "-map", "1:a", "-c:v", "copy",
         "-c:a", "aac", "-b:a", "192k", "-movflags", "+faststart", "-shortest", out])
    print("wrote", out, f"{dur(out):.2f}s (picture copied)")
    sys.exit(0)

# ---------------------------------------------------------------- picture + captions + audio
fdir = FONTS.replace(":", "\\:")
apath = ass_path.replace("\\", "/").replace(":", "\\:")
run(["ffmpeg", "-v", "error", "-y", "-i", video, "-i", master, "-filter_complex",
     f"[0:v]subtitles='{apath}':fontsdir='{fdir}',setsar=1,format=yuv420p[vo]",
     "-map", "[vo]", "-map", "1:a", "-c:v", "libx264", "-preset", "slow", "-crf", "18", "-r", "30",
     "-c:a", "aac", "-b:a", "192k", "-movflags", "+faststart", "-shortest", out])
print("wrote", out, f"{dur(out):.2f}s")
