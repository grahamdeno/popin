"""Synthesizes three Pro alarm sounds (owner, 2026-11-14): Tick-tock (Clock), Bubbles (Fishbowl, Soap), Groove (Disco).
28 s each, 44.1 kHz mono 16-bit, loudness matched to the other alarms (RMS about -14 dB, peak -0.4 dB).
Run: python3 scripts/make_alarm_sounds.py  (writes into App/Promptly/Sounds)."""
import wave, sys, numpy as np
SR = 44100
DUR = 28.0
rng = np.random.default_rng(7)
N = int(SR * DUR)

def env(n, a=0.002, d=0.1):
    t = np.arange(n) / SR
    e = np.exp(-t / d)
    na = max(1, int(a * SR))
    e[:na] *= np.linspace(0, 1, na)
    return e

def add(buf, sig, at):
    i = int(at * SR)
    if i >= len(buf): return
    j = min(len(buf), i + len(sig))
    buf[i:j] += sig[: j - i]

def lowpass(x, cut):
    a = np.exp(-2 * np.pi * cut / SR); y = np.zeros_like(x); s = 0.0
    for k in range(len(x)):
        s = (1 - a) * x[k] + a * s; y[k] = s
    return y

def highpass(x, cut): return x - lowpass(x, cut)

def finish(x, name, target=-14.0):
    x = x - x.mean()
    x /= np.abs(x).max()
    for _ in range(12):
        r = 20 * np.log10(np.sqrt((x ** 2).mean()))
        g = 10 ** ((target - r) / 20)
        y = x * g; k = 0.7; a = np.abs(y); o = a > k
        y[o] = np.sign(y[o]) * (k + (1 - k) * np.tanh((a[o] - k) / (1 - k)))
        x = y / max(1.0, np.abs(y).max())
    x *= 10 ** (-0.4 / 20) / np.abs(x).max()
    fade = int(0.05 * SR); x[-fade:] *= np.linspace(1, 0, fade)
    w = wave.open(f"App/Promptly/Sounds/{name}", "wb"); w.setnchannels(1); w.setsampwidth(2); w.setframerate(SR)
    w.writeframes((np.clip(x, -1, 1) * 32767).astype(np.int16).tobytes()); w.close()
    print(name, "rms", round(20 * np.log10(np.sqrt((x ** 2).mean())), 1))

def bell(freq, dur=1.6, amp=1.0):
    n = int(dur * SR); t = np.arange(n) / SR
    parts = [(1, 1.0, 1.2), (2.0, 0.5, 0.7), (3.01, 0.25, 0.45), (4.2, 0.12, 0.3)]
    return amp * sum(a * np.sin(2 * np.pi * freq * m * t) * env(n, 0.003, d) for m, a, d in parts)

# Tick-tock: wooden ticks that quicken, then a soft two-note chime; repeats a little louder each cycle.
def tick(high):
    n = int(0.06 * SR); t = np.arange(n) / SR
    f1, f2 = (2100, 1150) if high else (1500, 800)
    noise = highpass(rng.standard_normal(n), 1500) * env(n, 0.0005, 0.004)
    return 0.6 * noise + np.sin(2 * np.pi * f1 * t) * env(n, 0.0005, 0.012) + 0.6 * np.sin(2 * np.pi * f2 * t) * env(n, 0.0005, 0.02)

buf = np.zeros(N); at = 0.2; cyc = 0
while at < DUR - 1.5:
    gap = 0.5; hi = True; vol = min(1.0, 0.55 + 0.15 * cyc)
    for i in range(16):
        add(buf, vol * tick(hi), at); hi = not hi
        at += gap; gap = max(0.22, gap * 0.94)
    add(buf, 0.9 * vol * bell(1318.5), at); add(buf, 0.9 * vol * bell(1046.5), at + 0.45)
    at += 2.0; cyc += 1
finish(buf, "tick_tock_alarm.wav")

# Bubbles: underwater bloops rising faster, then a five-note marimba run up a pentatonic scale.
def bloop(f0):
    n = int(0.09 * SR); t = np.arange(n) / SR
    f = f0 * (1 + 2.2 * t / t[-1])
    return np.sin(2 * np.pi * np.cumsum(f) / SR) * env(n, 0.002, 0.03)

def marimba(freq, amp=1.0):
    n = int(0.9 * SR); t = np.arange(n) / SR
    return amp * (np.sin(2 * np.pi * freq * t) * env(n, 0.002, 0.25) + 0.35 * np.sin(2 * np.pi * freq * 4 * t) * env(n, 0.001, 0.05))

scale = [523.25, 587.33, 659.25, 783.99, 880.0, 1046.5]
buf = np.zeros(N); at = 0.2; cyc = 0
while at < DUR - 2.5:
    vol = min(1.0, 0.55 + 0.15 * cyc); gap = 0.32
    for i in range(14):
        add(buf, vol * 0.7 * bloop(rng.uniform(260, 520)), at + rng.uniform(-0.02, 0.02))
        at += gap; gap = max(0.09, gap * 0.86)
    for i, f in enumerate(scale[:5] if cyc % 2 == 0 else scale[1:]):
        add(buf, vol * marimba(f), at + 0.16 * i)
    at += 2.0; cyc += 1
finish(buf, "bubbles_alarm.wav")

# Groove: 70s four-on-the-floor kick, open hi-hat on the offbeat and an octave bass line; builds in over 4 bars.
BPM = 118; beat = 60 / BPM
def kick():
    n = int(0.25 * SR); t = np.arange(n) / SR
    f = 50 + 70 * np.exp(-t / 0.03)
    return np.sin(2 * np.pi * np.cumsum(f) / SR) * env(n, 0.001, 0.12)
def hat():
    n = int(0.12 * SR)
    return highpass(rng.standard_normal(n), 7000) * env(n, 0.001, 0.04)
def bassnote(freq, dur):
    n = int(dur * SR); t = np.arange(n) / SR
    saw = 2 * ((freq * t) % 1) - 1
    return lowpass(saw, 600) * env(n, 0.004, dur * 0.8)
def stab(freqs):
    n = int(0.18 * SR); t = np.arange(n) / SR
    return sum(np.sin(2 * np.pi * f * t) + 0.3 * np.sin(4 * np.pi * f * t) for f in freqs) * env(n, 0.003, 0.08) / len(freqs)

roots = [110.0, 110.0, 98.0, 130.81]   # A, A, G, C
chords = [[440, 523.25, 659.25], [440, 523.25, 659.25], [392, 493.88, 587.33], [523.25, 659.25, 783.99]]
buf = np.zeros(N); b = 0
while b * beat < DUR - 0.5:
    at = 0.1 + b * beat; bar = b // 4
    add(buf, 0.9 * kick(), at)
    if bar >= 1: add(buf, 0.35 * hat(), at + beat / 2)
    if bar >= 2:
        r = roots[bar % 4]
        add(buf, 0.55 * bassnote(r, beat / 2 * 0.9), at); add(buf, 0.55 * bassnote(r * 2, beat / 2 * 0.9), at + beat / 2)
    if bar >= 3 and b % 4 in (1, 3): add(buf, 0.35 * stab(chords[bar % 4]), at + beat / 2)
    b += 1
finish(buf, "groove_alarm.wav")
