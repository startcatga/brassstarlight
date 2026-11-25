"""Synthesises every Brass & Starlight sound from scratch (no samples, no
licences). Run: python tool/make_sfx.py  -> writes assets/sfx/*.wav and
assets/sfx/night.ogg (needs ffmpeg on PATH for the ogg loop).
"""
import os
import subprocess
import wave

import numpy as np

RATE = 22050
OUT = os.path.join(os.path.dirname(__file__), '..', 'assets', 'sfx')
rng = np.random.default_rng(7)


def t_of(dur):
    return np.arange(int(RATE * dur)) / RATE


def write(name, x, peak=0.8):
    os.makedirs(OUT, exist_ok=True)
    x = np.asarray(x, np.float64)
    x = x / max(1e-9, np.abs(x).max()) * peak
    with wave.open(os.path.join(OUT, name + '.wav'), 'wb') as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes((x * 32767).astype('<i2').tobytes())
    print('wrote', name)


def celesta(freq, dur, decay=4.5, attack=0.003):
    """Glassy bell: slightly inharmonic partials and a soft attack."""
    t = t_of(dur)
    env = np.minimum(1, t / attack) * np.exp(-decay * t)
    partials = ((1, 1.0), (2.0, 0.30), (3.01, 0.10), (4.2, 0.05))
    tone = sum(a * np.sin(2 * np.pi * freq * m * t) * np.exp(-m * 0.6 * t) for m, a in partials)
    return env * tone


def mix(*parts):
    n = max(int(o * RATE) + len(s) for o, s in parts)
    out = np.zeros(n)
    for o, s in parts:
        k = int(o * RATE)
        out[k:k + len(s)] += s
    return out


def lowpass(x, alpha):
    y = np.zeros_like(x)
    acc = 0.0
    for i, v in enumerate(x):
        acc += alpha * (v - acc)
        y[i] = acc
    return y


# Pentatonic ladder (D major pentatonic): each linked star rings one step higher.
LADDER = [587.33, 659.25, 739.99, 880.00, 987.77,
          1174.66, 1318.51, 1479.98, 1760.00, 1975.53, 2349.32, 2637.02]
for i, f in enumerate(LADDER):
    write(f'star_{i}', mix((0, celesta(f, 0.9, decay=5.0)), (0, 0.25 * celesta(f * 2, 0.4, decay=9))))

# Line breaks: a soft descending pair, muted.
broken = mix((0, celesta(440, 0.5, 9)), (0.08, celesta(330, 0.6, 8)))
write('broken', broken * np.linspace(1, 0, len(broken)) ** 0.5, peak=0.5)

# Touched a loose star: a dull glassy tick.
tick = celesta(220, 0.25, decay=18) + 0.4 * lowpass(rng.normal(0, 1, int(RATE * 0.25)), 0.08) * np.exp(-30 * t_of(0.25))
write('decoy', tick, peak=0.5)

# Constellation sealed: rising arpeggio and a shimmer tail.
seal = mix(
    (0.00, celesta(587.33, 1.6, 2.6)),
    (0.10, celesta(739.99, 1.6, 2.6)),
    (0.20, celesta(880.00, 1.6, 2.4)),
    (0.30, celesta(1174.66, 2.0, 2.0)),
    *[(0.45 + k * 0.045, 0.25 * celesta(2349.32 * (1 + 0.06 * k), 0.6, 7)) for k in range(8)],
)
write('seal', seal, peak=0.75)

# UI tap: a small wooden click (brass control).
click_t = t_of(0.07)
click = (np.sin(2 * np.pi * 1900 * click_t) * np.exp(-90 * click_t)
         + 0.6 * lowpass(rng.normal(0, 1, len(click_t)), 0.3) * np.exp(-120 * click_t))
write('tap', click, peak=0.45)

# Page turn: a short filtered paper rustle.
n = int(RATE * 0.32)
rustle = lowpass(rng.normal(0, 1, n), 0.35) - lowpass(rng.normal(0, 1, n), 0.05)
env = np.sin(np.linspace(0, np.pi, n)) ** 1.5
write('page', rustle * env, peak=0.35)

# Seal earned / chapter opened: two warm notes, a fifth apart.
write('unlock', mix((0, celesta(440, 1.2, 3)), (0.14, celesta(659.25, 1.4, 2.6))), peak=0.7)

# Lantern hint: a soft rising shimmer.
write('lantern', mix(*[(k * 0.06, 0.6 * celesta(1174.66 * 2 ** (k / 5), 0.7, 6)) for k in range(5)]), peak=0.55)

# Ambient night loop: a slow drone chord with wind, seamless at 24 s.
dur = 24.0
t = t_of(dur)
drone = np.zeros_like(t)
for f, a in ((73.42, 0.5), (110.0, 0.35), (146.83, 0.25), (220.0, 0.12), (277.18, 0.06)):
    lfo = 0.6 + 0.4 * np.sin(2 * np.pi * t / dur * (2 if f > 150 else 1) + f)
    drone += a * lfo * np.sin(2 * np.pi * f * t)
wind = lowpass(rng.normal(0, 1, len(t)), 0.02)
wind *= 0.5 + 0.5 * np.sin(2 * np.pi * t / dur * 3) ** 2
bed = drone * 0.6 + wind * 6.0
# Sparse distant chimes on the pentatonic ladder.
for k, when in enumerate((3.0, 9.5, 14.0, 19.5)):
    note = celesta(LADDER[(k * 3) % 6], 3.0, 1.4) * 0.08
    s = int(when * RATE)
    bed[s:s + len(note)] += note[: len(bed) - s]
fade = int(RATE * 1.5)
bed[:fade] = bed[:fade] * np.linspace(0, 1, fade) + bed[-fade:] * np.linspace(1, 0, fade)
bed = bed[:-fade]
write('night_tmp', bed, peak=0.5)
src = os.path.join(OUT, 'night_tmp.wav')
dst = os.path.join(OUT, 'night.ogg')
subprocess.run(['ffmpeg', '-y', '-loglevel', 'error', '-i', src, '-c:a', 'libvorbis', '-q:a', '4', dst], check=True)
os.remove(src)
print('wrote night.ogg')
