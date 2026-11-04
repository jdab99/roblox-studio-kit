"""Record a reel's narration in the Blocky Tales voice (ElevenLabs Adam, sped up 1.4x tape-style).

usage: python tools/narrate.py scripts/reel-01-the-key-heist.md reels/01-key-heist
Writes narration.mp3 (final voice, -14 LUFS) and words.json (each word with start/end seconds in the final audio).
"""
import os, sys, json, base64, subprocess, requests

VOICE = "pNInz6obpgDQGcFmaJgB"  # Adam (premade)
SPEED = 1.4

script_md, out_dir = sys.argv[1], sys.argv[2]
os.makedirs(out_dir, exist_ok=True)
md = open(script_md, encoding="utf-8").read()
body = md.split("## Script (narrator)", 1)[1].split("\n## ", 1)[0]
text = "\n".join(l.strip() for l in body.strip().splitlines() if l.strip())

r = requests.post(f"https://api.elevenlabs.io/v1/text-to-speech/{VOICE}/with-timestamps",
                  headers={"xi-api-key": os.environ["ELEVENLABS_API_KEY"]},
                  json={"text": text, "model_id": "eleven_multilingual_v2"})
r.raise_for_status()
d = r.json()
raw = os.path.join(out_dir, "narration-raw.mp3")
open(raw, "wb").write(base64.b64decode(d["audio_base64"]))

# words from the character alignment, times scaled to the sped-up audio
al = d["alignment"]
words, cur, start, end = [], "", None, None
for ch, s, e in zip(al["characters"], al["character_start_times_seconds"], al["character_end_times_seconds"]):
    if ch.isspace():
        if cur:
            words.append({"w": cur, "start": round(start / SPEED, 3), "end": round(end / SPEED, 3)})
        cur, start = "", None
        continue
    if start is None:
        start = s
    cur += ch
    end = e
if cur:
    words.append({"w": cur, "start": round(start / SPEED, 3), "end": round(end / SPEED, 3)})
json.dump(words, open(os.path.join(out_dir, "words.json"), "w", encoding="utf-8"), indent=0)

subprocess.run(["ffmpeg", "-v", "error", "-y", "-i", raw, "-af",
                f"asetrate=44100*{SPEED},aresample=44100,loudnorm=I=-14:TP=-1",
                os.path.join(out_dir, "narration.mp3")], check=True)
print(len(text), "chars,", len(words), "words, last word ends", words[-1]["end"], "s")
