"""A tiny music synthesizer for Grandpa: standard-library Python only.

Songs are note lists written in songs.py. Each is rendered to a loopable 16-bit stereo WAV: the
reverb tail at the end is folded back onto the start, so the file loops without a click.
Run:  py tools/music/render.py <out_dir> [song ...]
"""
import math, random, wave
from array import array

RATE = 32000
TAU = math.tau

NOTE_PC = {"C": 0, "C#": 1, "Db": 1, "D": 2, "D#": 3, "Eb": 3, "E": 4, "F": 5, "F#": 6, "Gb": 6,
           "G": 7, "G#": 8, "Ab": 8, "A": 9, "A#": 10, "Bb": 10, "B": 11}


def midi(name):
    """'A4' -> 69, 'Bb3' -> 58."""
    pitch, octave = name[:-1], int(name[-1])
    return 12 * (octave + 1) + NOTE_PC[pitch]


def hz(m):
    return 440.0 * 2 ** ((m - 69) / 12.0)


def _env(n, attack, decay, sustain, release, held):
    out = array("f", [0.0]) * n
    a = max(1, int(attack * RATE)); d = max(1, int(decay * RATE)); r = max(1, int(release * RATE))
    last = 0.0
    for i in range(n):
        if i < held:
            if i < a:
                level = i / a
            elif i < a + d:
                level = 1.0 - (1.0 - sustain) * (i - a) / d
            else:
                level = sustain
            last = level
        else:
            level = last * max(0.0, 1.0 - (i - held) / r)
        out[i] = level
    return out


def _n(held, release):
    return int((held + release) * RATE)


# --- instruments: (frequency, held seconds, velocity) -> float array -------------------------

def epiano(f, held, vel):
    """Electric piano: a sine carrier with a decaying sine modulator and a soft bell tine."""
    rel = 0.35; n = _n(held, rel); hn = int(held * RATE)
    out = array("f", [0.0]) * n; w = TAU * f / RATE
    for i in range(n):
        t = i / RATE
        s = math.sin(w * i + (1.8 * math.exp(-t * 5.0) + 0.3) * math.sin(w * i)) * math.exp(-t * 1.8)
        s += 0.12 * math.sin(7 * w * i) * math.exp(-t * 30)
        if i > hn:
            s *= max(0.0, 1.0 - (i - hn) / (rel * RATE))
        out[i] = s * vel
    return out


def vibes(f, held, vel):
    rel = 0.7; n = _n(held, rel); hn = int(held * RATE)
    out = array("f", [0.0]) * n; w = TAU * f / RATE
    for i in range(n):
        t = i / RATE
        s = (math.sin(w * i) + 0.22 * math.sin(4 * w * i) * math.exp(-t * 7)) * math.exp(-t * 1.4)
        s *= 0.78 + 0.22 * math.sin(TAU * 5.0 * t)
        if i > hn:
            s *= max(0.0, 1.0 - (i - hn) / (rel * RATE))
        out[i] = s * vel
    return out


def bass(f, held, vel):
    """Upright-ish plucked bass: a quick thump into a round tone."""
    rel = 0.07; n = _n(held, rel); env = _env(n, 0.003, 0.3, 0.5, rel, int(held * RATE))
    out = array("f", [0.0]) * n; w = TAU * f / RATE
    for i in range(n):
        t = i / RATE
        bright = 0.45 * math.exp(-t * 14)
        out[i] = (math.sin(w * i) + (0.3 + bright) * math.sin(2 * w * i) + bright * 0.6 * math.sin(3 * w * i)) * env[i] * vel
    return out


def synthbass(f, held, vel):
    """A punchy saw bass with a closing filter, for the boss."""
    rel = 0.04; n = _n(held, rel); env = _env(n, 0.002, 0.12, 0.75, rel, int(held * RATE))
    out = array("f", [0.0]) * n; ph = 0.0; lp = 0.0; lp2 = 0.0
    for i in range(n):
        t = i / RATE
        ph = (ph + f / RATE) % 1.0
        raw = 2.0 * ph - 1.0
        k = 0.06 + 0.35 * math.exp(-t * 18)
        lp += k * (raw - lp); lp2 += k * (lp - lp2)
        out[i] = lp2 * env[i] * vel * 1.4
    return out


def pulse(f, held, vel, duty=0.25, vib=True, bright=0.5):
    """A pulse lead with delayed vibrato and a gentle lowpass."""
    rel = 0.09; n = _n(held, rel); env = _env(n, 0.006, 0.12, 0.75, rel, int(held * RATE))
    out = array("f", [0.0]) * n; ph = 0.0; lp = 0.0
    for i in range(n):
        t = i / RATE
        depth = 0.007 * min(1.0, max(0.0, (t - 0.15) / 0.25)) if vib else 0.0
        ph += f * (1.0 + depth * math.sin(TAU * 5.6 * t)) / RATE
        raw = 1.0 if (ph % 1.0) < duty else -1.0
        lp += bright * (raw - lp)
        out[i] = lp * env[i] * vel * 0.5
    return out


def square(f, held, vel):
    return pulse(f, held, vel, 0.5, False, 0.4)


def thin(f, held, vel):
    return pulse(f, held, vel, 0.125, False, 0.6)


def brass(f, held, vel):
    """A cheesy muted trumpet: a saw whose filter opens with each note, with a little bend up."""
    rel = 0.06; n = _n(held, rel); env = _env(n, 0.02, 0.15, 0.7, rel, int(held * RATE))
    out = array("f", [0.0]) * n; ph = 0.0; lp = 0.0; lp2 = 0.0
    for i in range(n):
        t = i / RATE
        bend = 1.0 - 0.025 * math.exp(-t * 25)
        ph = (ph + f * bend * (1 + 0.004 * math.sin(TAU * 5 * t) * min(1.0, t * 3)) / RATE) % 1.0
        raw = 2.0 * ph - 1.0
        k = 0.05 + 0.22 * env[i]
        lp += k * (raw - lp); lp2 += k * (lp - lp2)
        out[i] = lp2 * env[i] * vel * 1.1
    return out


def glass(f, held, vel):
    """A mellow, rounded square with vibrato: the soft synth of a public-address lounge."""
    return pulse(f, held, vel, 0.5, True, 0.16)


def theremin(f, held, vel, slide_from=None, slide=0.0):
    """A theremin: a near-sine with vibrato that scoops up into each note. Given `slide_from` (a
    frequency), it starts there instead and glides to the note over `slide` seconds (portamento)."""
    gliding = slide_from is not None and slide > 0.0
    rel = 0.1 if gliding else 0.25; n = _n(held, rel)
    env = _env(n, 0.025 if gliding else 0.09, 0.2, 0.85, rel, int(held * RATE))
    out = array("f", [0.0]) * n; ph = 0.0
    ratio = math.log(slide_from / f) if gliding else 0.0
    for i in range(n):
        t = i / RATE
        if gliding:
            bend = math.exp(ratio * (0.5 + 0.5 * math.cos(math.pi * t / slide))) if t < slide else 1.0
        else:
            bend = 1.0 - 0.03 * math.exp(-t * 18)
        ph += f * bend * (1.0 + 0.012 * math.sin(TAU * 6.3 * t)) / RATE
        out[i] = (math.sin(TAU * ph) + 0.12 * math.sin(2 * TAU * ph)) * env[i] * vel * 0.8
    return out


def organ(f, held, vel):
    rel = 0.05; n = _n(held, rel); env = _env(n, 0.01, 0.05, 0.9, rel, int(held * RATE))
    out = array("f", [0.0]) * n; w = TAU * f / RATE
    for i in range(n):
        t = i / RATE
        trem = 0.85 + 0.15 * math.sin(TAU * 6.0 * t)
        click = 0.3 * math.exp(-t * 200)
        out[i] = (math.sin(w * i) + 0.7 * math.sin(2 * w * i) + 0.4 * math.sin(3 * w * i)
                  + 0.3 * math.sin(4 * w * i) + 0.15 * math.sin(6 * w * i) + click) * env[i] * vel * trem * 0.38
    return out


def bell(f, held, vel):
    n = int(2.5 * RATE); out = array("f", [0.0]) * n; w = TAU * f / RATE
    for i in range(n):
        t = i / RATE
        out[i] = (math.sin(w * i) * math.exp(-t * 1.5) + 0.45 * math.sin(2.76 * w * i) * math.exp(-t * 3)
                  + 0.25 * math.sin(5.4 * w * i) * math.exp(-t * 6)) * vel * 0.6
    return out


# --- more colours: tables, keys, reeds, pipes, voices ----------------------------------------

TABLE = 2048
_tables = {}


def _table(key, weights):
    """One cycle of summed sine harmonics, (harmonic, amplitude) pairs, scaled to a peak of 1."""
    if key in _tables:
        return _tables[key]
    t = array("f", [0.0]) * TABLE
    for i in range(TABLE):
        x = TAU * i / TABLE
        t[i] = sum(a * math.sin(h * x) for h, a in weights)
    peak = max(1e-6, max(abs(v) for v in t))
    for i in range(TABLE):
        t[i] /= peak
    _tables[key] = t
    return t


def _play_table(table, f, env, vel, vib=0.0, vib_rate=5.2, vib_delay=0.2, scoop=0.0):
    """Reads a wavetable at f under an envelope, with delayed vibrato and an optional scoop up to pitch."""
    n = len(env); out = array("f", [0.0]) * n; ph = 0.0; inc = f * TABLE / RATE
    for i in range(n):
        if vib or scoop:
            t = i / RATE
            m = 1.0
            if vib:
                m += vib * min(1.0, max(0.0, (t - vib_delay) / 0.3)) * math.sin(TAU * vib_rate * t)
            if scoop:
                m -= scoop * math.exp(-t * 30)
            ph += inc * m
        else:
            ph += inc
        out[i] = table[int(ph) & 2047] * env[i] * vel
    return out


def piano(f, held, vel):
    """A soft upright: bright at the hammer, mellowing as it rings, two strings a hair apart."""
    rel = 0.25; ring = min(held, 3.5); n = _n(ring, rel); hn = int(ring * RATE)
    table = _table("piano", [(k, 1.0 / k ** 1.25) for k in range(1, 10)])
    out = array("f", [0.0]) * n; p1 = 0.0; p2 = 0.0; inc1 = f * TABLE / RATE; inc2 = inc1 * 1.0009
    lp = 0.0; decay = 0.9 + f / 700.0
    for i in range(n):
        t = i / RATE
        p1 += inc1; p2 += inc2
        raw = table[int(p1) & 2047] + table[int(p2) & 2047]
        k = 0.06 + 0.5 * vel * math.exp(-t * 4.0)
        lp += k * (raw - lp)
        e = math.exp(-t * decay) * min(1.0, i / 64.0)
        if i > hn:
            e *= max(0.0, 1.0 - (i - hn) / (rel * RATE))
        out[i] = (lp * 0.5 + 0.15 * _noise() * math.exp(-t * 250)) * e * vel
    return out


def musicbox(f, held, vel):
    """A music-box tine: a clear note with a glassy overtone, ringing on whatever the length."""
    n = int(1.8 * RATE); out = array("f", [0.0]) * n; w = TAU * f / RATE
    for i in range(n):
        t = i / RATE
        out[i] = (math.sin(w * i) * math.exp(-t * 2.4) + 0.35 * math.sin(3.0 * w * i) * math.exp(-t * 7)
                  + 0.12 * math.sin(5.9 * w * i) * math.exp(-t * 18)) * vel * 0.55 * min(1.0, i / 24.0)
    return out


def marimba(f, held, vel):
    """Wooden bars, or bones: a round note with a knock on top, quickly gone."""
    n = int(min(held + 0.3, 1.1) * RATE); out = array("f", [0.0]) * n; w = TAU * f / RATE
    for i in range(n):
        t = i / RATE
        out[i] = (math.sin(w * i) * math.exp(-t * 5.5) + 0.3 * math.sin(3.93 * w * i) * math.exp(-t * 22)
                  + 0.1 * math.sin(9.2 * w * i) * math.exp(-t * 60)) * vel * min(1.0, i / 16.0)
    return out


def tri(f, held, vel):
    """A chip triangle for bass lines."""
    rel = 0.03; n = _n(held, rel); env = _env(n, 0.002, 0.08, 0.85, rel, int(held * RATE))
    out = array("f", [0.0]) * n; ph = 0.0; inc = f / RATE
    for i in range(n):
        ph = (ph + inc) % 1.0
        out[i] = (4.0 * abs(ph - 0.5) - 1.0) * env[i] * vel
    return out


def pipe(f, held, vel):
    """A church pipe organ: 16', 8', 4' and 2' ranks with a breathy chiff, no tremolo."""
    rel = 0.15; n = _n(held, rel); env = _env(n, 0.045, 0.1, 0.92, rel, int(held * RATE))
    table = _table("pipe", [(1, 0.5), (2, 1.0), (3, 0.22), (4, 0.55), (6, 0.18), (8, 0.3), (10, 0.08)])
    out = _play_table(table, f / 2.0, env, vel * 0.55)
    lp = 0.0
    for i in range(min(n, int(0.05 * RATE))):
        lp += 0.3 * (_noise() - lp)
        out[i] += lp * 0.12 * vel * math.exp(-i / RATE * 60)
    return out


def theatre(f, held, vel):
    """A picture-house organ: flute pipes at 16', 8', 4' and 2', under a deep tremulant that sways
    the pitch and the loudness together."""
    rel = 0.18; n = _n(held, rel); env = _env(n, 0.035, 0.12, 0.9, rel, int(held * RATE))
    table = _table("theatre", [(1, 0.3), (2, 1.0), (3, 0.06), (4, 0.4), (6, 0.12), (8, 0.1)])
    out = _play_table(table, f / 2.0, env, vel * 0.6, vib=0.0055, vib_rate=6.6, vib_delay=0.0)
    for i in range(n):
        out[i] *= 0.8 + 0.2 * math.sin(TAU * 6.6 * i / RATE)
    return out


def pad(f, held, vel):
    """Soft strings: three saws a little apart under a warm filter, swelling in and out."""
    rel = 0.6; n = _n(held, rel); env = _env(n, 0.3, 0.3, 0.85, rel, int(held * RATE))
    out = array("f", [0.0]) * n; ph = [0.0, 0.33, 0.66]; inc = [f * d / RATE for d in (1.0, 1.006, 0.994)]
    lp = 0.0; lp2 = 0.0
    for i in range(n):
        raw = 0.0
        for k in range(3):
            ph[k] = (ph[k] + inc[k]) % 1.0
            raw += 2.0 * ph[k] - 1.0
        lp += 0.07 * (raw - lp); lp2 += 0.07 * (lp - lp2)
        out[i] = lp2 * env[i] * vel * 0.45
    return out


def choir(f, held, vel):
    """An 'aah' choir: harmonics shaped by vowel formants, two voices, slow in and out."""
    rel = 0.45; n = _n(held, rel); env = _env(n, 0.22, 0.2, 0.9, rel, int(held * RATE))
    key = "choir%d" % int(f)
    weights = []
    for h in range(1, 40):
        hf = h * f
        if hf > 6000:
            break
        a = sum(g / (1.0 + ((hf - fm) / bw) ** 2) for fm, bw, g in ((700, 130, 1.0), (1150, 150, 0.55), (2700, 220, 0.22)))
        weights.append((h, a + 0.02 / h))
    table = _table(key, weights)
    a = _play_table(table, f * 1.003, env, vel * 0.5, vib=0.006, vib_rate=5.1, vib_delay=0.1)
    b = _play_table(table, f / 1.003, env, vel * 0.5, vib=0.006, vib_rate=4.6, vib_delay=0.15)
    for i in range(n):
        a[i] += b[i]
    return a


def flute(f, held, vel):
    """A soft flute: nearly a sine, a little breath, and vibrato once the note settles."""
    rel = 0.1; n = _n(held, rel); env = _env(n, 0.05, 0.1, 0.85, rel, int(held * RATE))
    table = _table("flute", [(1, 1.0), (2, 0.18), (3, 0.06)])
    out = _play_table(table, f, env, vel * 0.8, vib=0.008, vib_rate=5.0, vib_delay=0.25)
    lp = 0.0
    for i in range(n):
        lp += 0.15 * (_noise() - lp)
        out[i] += lp * 0.1 * env[i] * vel
    return out


def reed(f, held, vel):
    """A clarinet: hollow odd harmonics, a quick breath in, a gentle vibrato."""
    rel = 0.08; n = _n(held, rel); env = _env(n, 0.03, 0.1, 0.85, rel, int(held * RATE))
    table = _table("reed", [(1, 1.0), (2, 0.05), (3, 0.45), (5, 0.25), (7, 0.12), (9, 0.06)])
    return _play_table(table, f, env, vel * 0.75, vib=0.005, vib_rate=5.4, vib_delay=0.3)


def bassoon(f, held, vel):
    """A grumpy bassoon: reedy and nasal, each note scooping up into pitch."""
    rel = 0.06; n = _n(held, rel); env = _env(n, 0.025, 0.12, 0.8, rel, int(held * RATE))
    table = _table("bassoon", [(1, 0.45), (2, 1.0), (3, 0.8), (4, 0.5), (5, 0.38), (6, 0.2), (7, 0.12), (8, 0.06)])
    return _play_table(table, f, env, vel * 0.8, vib=0.004, vib_rate=4.8, vib_delay=0.35, scoop=0.03)


def guitar(f, held, vel):
    """A nylon pluck (Karplus-Strong), damped when the note ends."""
    rel = 0.12; n = _n(min(held, 2.5), rel); hn = int(min(held, 2.5) * RATE)
    period = RATE / f - 0.5
    d = max(2, int(period)); frac = period - d
    c = (1.0 - frac) / (1.0 + frac)
    out = array("f", [0.0]) * n
    lp = 0.0
    for i in range(min(n, d + 1)):
        lp += 0.5 * (_noise() - lp)
        out[i] = lp
    ax = 0.0; ay = 0.0
    for i in range(d + 1, n):
        g = 0.4985 if i < hn else 0.47
        x = (out[i - d] + out[i - d - 1]) * g
        y = c * x + ax - c * ay
        ax = x; ay = y
        out[i] = y
    for i in range(n):
        out[i] *= vel * (1.0 if i < hn else max(0.0, 1.0 - (i - hn) / (rel * RATE)))
    return out


def tapestop(f, held, vel):
    """A held organ chord whose tape grinds to a halt: the pitch sinks to nothing as it fades."""
    n = int(held * RATE); out = array("f", [0.0]) * n
    table = _table("tape", [(1, 1.0), (2, 0.5), (3, 0.3), (4, 0.2), (5, 0.1)])
    ph = 0.0; inc = f * TABLE / RATE
    for i in range(n):
        p = i / n
        ph += inc * (1.0 - p) ** 2
        out[i] = table[int(ph) & 2047] * (1.0 - p) ** 0.6 * vel * 0.6
    return out


INSTRUMENTS = {"epiano": epiano, "vibes": vibes, "bass": bass, "synthbass": synthbass, "pulse": pulse,
               "square": square, "thin": thin, "brass": brass, "theremin": theremin, "organ": organ,
               "bell": bell, "piano": piano, "musicbox": musicbox, "marimba": marimba, "tri": tri,
               "pipe": pipe, "pad": pad, "choir": choir, "flute": flute, "reed": reed, "bassoon": bassoon,
               "guitar": guitar, "tapestop": tapestop, "glass": glass, "theatre": theatre}

_rng = random.Random(7)


def _noise():
    return _rng.uniform(-1.0, 1.0)


def drum(kind, vel):
    if kind == "kick":
        n = int(0.4 * RATE); out = array("f", [0.0]) * n; ph = 0.0
        for i in range(n):
            t = i / RATE
            ph += (50 + 130 * math.exp(-t * 30)) / RATE
            out[i] = (math.tanh(2.2 * math.sin(TAU * ph)) * math.exp(-t * 7.5) + 0.4 * _noise() * math.exp(-t * 300)) * vel
        return out
    if kind == "snare":
        n = int(0.25 * RATE); out = array("f", [0.0]) * n; prev = 0.0
        for i in range(n):
            t = i / RATE
            x = _noise(); hp = x - prev; prev = x
            out[i] = (0.65 * hp * math.exp(-t * 14) + 0.4 * math.sin(TAU * 185 * t) * math.exp(-t * 22)) * vel
        return out
    if kind == "clap":
        n = int(0.25 * RATE); out = array("f", [0.0]) * n; lp = 0.0
        for i in range(n):
            t = i / RATE
            burst = sum(math.exp(-(t - o) * 90) for o in (0.0, 0.011, 0.022) if t >= o)
            lp += 0.6 * (_noise() - lp)
            out[i] = lp * (burst * 0.4 + 0.5 * math.exp(-t * 18)) * vel * 0.8
        return out
    if kind in ("hat", "openhat", "shaker"):
        dur, decay, g = {"hat": (0.05, 70, 0.35), "openhat": (0.25, 12, 0.35), "shaker": (0.07, 40, 0.22)}[kind]
        n = int(dur * RATE); out = array("f", [0.0]) * n; prev = 0.0
        for i in range(n):
            t = i / RATE
            x = _noise(); hp = x - prev; prev = x
            env = math.exp(-t * decay) * (min(1.0, t / 0.008) if kind == "shaker" else 1.0)
            out[i] = hp * env * vel * g
        return out
    if kind == "brush":
        n = int(0.16 * RATE); out = array("f", [0.0]) * n; lp = 0.0
        for i in range(n):
            t = i / RATE
            lp += 0.35 * (_noise() - lp)
            out[i] = lp * min(1.0, t / 0.02) * math.exp(-t * 14) * vel * 0.5
        return out
    if kind == "rim":
        n = int(0.06 * RATE); out = array("f", [0.0]) * n
        for i in range(n):
            t = i / RATE
            out[i] = (math.sin(TAU * 1700 * t) * 0.5 + 0.5 * _noise()) * math.exp(-t * 60) * vel * 0.5
        return out
    if kind == "crash":
        n = int(1.6 * RATE); out = array("f", [0.0]) * n; prev = 0.0
        for i in range(n):
            t = i / RATE
            x = _noise(); hp = x - prev; prev = x
            out[i] = hp * math.exp(-t * 2.6) * vel * 0.3
        return out
    if kind == "clank":
        # Struck sheet metal: a few clashing partials and a sharp click.
        n = int(0.3 * RATE); out = array("f", [0.0]) * n
        for i in range(n):
            t = i / RATE
            s = sum(a * math.sin(TAU * fr * t) * math.exp(-t * d) for fr, a, d in
                    ((523, 1.0, 22), (1131, 0.7, 28), (1787, 0.5, 36), (2593, 0.35, 48)))
            out[i] = (s * 0.45 + 0.6 * _noise() * math.exp(-t * 400)) * vel * 0.6
        return out
    if kind == "anvil":
        n = int(1.1 * RATE); out = array("f", [0.0]) * n
        for i in range(n):
            t = i / RATE
            s = sum(a * math.sin(TAU * fr * t) * math.exp(-t * d) for fr, a, d in
                    ((1350, 1.0, 5), (3080, 0.6, 8), (4620, 0.35, 12), (6200, 0.2, 16)))
            out[i] = (s * 0.35 + 0.7 * _noise() * math.exp(-t * 500)) * vel * 0.5
        return out
    if kind == "steam":
        n = int(0.9 * RATE); out = array("f", [0.0]) * n; prev = 0.0; lp = 0.0
        for i in range(n):
            t = i / RATE
            x = _noise(); hp = x - prev; prev = x
            lp += 0.5 * (hp - lp)
            out[i] = lp * min(1.0, t / 0.06) * math.exp(-t * 3.2) * vel * 0.45
        return out
    if kind in ("tom", "bongo", "conga"):
        top, low, dec, dur = {"tom": (170, 95, 11, 0.45), "bongo": (520, 430, 28, 0.15), "conga": (330, 270, 18, 0.25)}[kind]
        n = int(dur * RATE); out = array("f", [0.0]) * n; ph = 0.0
        for i in range(n):
            t = i / RATE
            ph += (low + (top - low) * math.exp(-t * 30)) / RATE
            out[i] = (math.sin(TAU * ph) * math.exp(-t * dec) + 0.3 * _noise() * math.exp(-t * 200)) * vel * 0.8
        return out
    if kind in ("woodblock", "tick"):
        fr, dec, dur = (880, 70, 0.08) if kind == "woodblock" else (2600, 240, 0.03)
        n = int(dur * RATE); out = array("f", [0.0]) * n
        for i in range(n):
            t = i / RATE
            out[i] = (math.sin(TAU * fr * t) + 0.5 * math.sin(TAU * fr * 1.47 * t) + 0.3 * _noise() * math.exp(-t * 600)) \
                * math.exp(-t * dec) * vel * 0.5
        return out
    if kind == "ride":
        n = int(0.9 * RATE); out = array("f", [0.0]) * n; prev = 0.0
        for i in range(n):
            t = i / RATE
            x = _noise(); hp = x - prev; prev = x
            ring = 0.12 * (math.sin(TAU * 3150 * t) + 0.7 * math.sin(TAU * 4870 * t) + 0.5 * math.sin(TAU * 5910 * t))
            out[i] = (hp * 0.2 * math.exp(-t * 7) + ring * math.exp(-t * 4.5)) * vel * 0.55
        return out
    if kind == "crackle":
        # A worn record: a scatter of tiny clicks.
        n = int(0.5 * RATE); out = array("f", [0.0]) * n; lp = 0.0
        for i in range(n):
            x = _rng.uniform(-1.0, 1.0) if _rng.random() < 0.0012 else 0.0
            lp += 0.6 * (x - lp)
            out[i] = lp * vel * 0.9
        return out
    if kind == "zap":
        n = int(0.14 * RATE); out = array("f", [0.0]) * n; ph = 0.0
        for i in range(n):
            t = i / RATE
            ph += (100 + 1500 * math.exp(-t * 30)) / RATE
            out[i] = (1.0 if ph % 1.0 < 0.5 else -1.0) * math.exp(-t * 18) * vel * 0.25
        return out
    if kind == "cricket":
        n = int(0.16 * RATE); out = array("f", [0.0]) * n
        for i in range(n):
            t = i / RATE
            k = t / 0.04
            gate = math.sin(math.pi * (k % 1.0)) if k < 3 else 0.0
            out[i] = math.sin(TAU * 4300 * t) * gate * gate * vel * 0.25
        return out
    if kind == "flap":
        # A departures board turning over: a quick run of little plastic clacks.
        n = int(0.4 * RATE); out = array("f", [0.0]) * n
        for c in range(9):
            start = int((c * 0.04 + _rng.uniform(0, 0.008)) * RATE)
            for j in range(int(0.015 * RATE)):
                if start + j < n:
                    t = j / RATE
                    out[start + j] += (0.6 * _noise() + math.sin(TAU * 1900 * t)) * math.exp(-t * 450) * vel * 0.45
        return out
    if kind == "ring":
        # An old telephone: a clapper rattling between two small bells for a second, then ringing out.
        n = int(1.4 * RATE); out = array("f", [0.0]) * n
        la = lb = 0.0; dec = math.exp(-28.0 / RATE); period = RATE // 40
        for i in range(n):
            t = i / RATE
            if i % period == 0 and t < 1.0:
                if (i // period) % 2:
                    lb = 1.0
                else:
                    la = 1.0
            out[i] = (la * (math.sin(TAU * 1250 * t) + 0.4 * math.sin(TAU * 3110 * t))
                      + lb * (math.sin(TAU * 1480 * t) + 0.4 * math.sin(TAU * 3590 * t))) * vel * 0.3
            la *= dec; lb *= dec
        return out
    if kind == "bloop":
        # A blob letting go in a lava lamp: a soft sine that rises as it floats off.
        n = int(0.4 * RATE); out = array("f", [0.0]) * n; ph = 0.0
        for i in range(n):
            t = i / RATE
            ph += (160 + 380 * (1.0 - math.exp(-t * 9))) / RATE
            out[i] = math.sin(TAU * ph) * min(1.0, t / 0.015) * math.exp(-t * 9) * vel * 0.6
        return out
    raise ValueError(kind)


# --- the song ------------------------------------------------------------------------------

class Song:
    """`meter` is beats per bar. A looping song folds its tail onto its start; a sting (loop=False)
    keeps `tail` seconds after its last beat and fades out. `tremolo` maps an instrument name to
    (pulses per beat, depth): every note it plays swells and dips in time with the beat."""

    def __init__(self, bpm, beats, reverb=0.25, swing=0.0, meter=4, loop=True, tail=2.0, tremolo=None):
        self.bpm = bpm; self.beats = beats; self.reverb = reverb; self.swing = swing
        self.meter = meter; self.loop = loop; self.tail = tail
        self.tremolo = tremolo or {}
        self._slide_from = None; self._slide = 0.0
        self.spb = 60.0 / bpm
        self.length = int(beats * self.spb * RATE)
        size = self.length + 4 * RATE
        self.left = array("f", [0.0]) * size
        self.right = array("f", [0.0]) * size
        self.send = array("f", [0.0]) * size

    def _swung(self, beat):
        frac = beat % 1.0
        if self.swing and abs(frac - 0.5) < 1e-6:
            return beat + self.swing
        return beat

    def _mix(self, sound, start_beat, gain, wet, pan):
        start = int(self._swung(start_beat) * self.spb * RATE)
        gl = gain * math.cos((pan + 1) * math.pi / 4) * 1.414
        gr = gain * math.sin((pan + 1) * math.pi / 4) * 1.414
        left, right, send = self.left, self.right, self.send
        end = min(len(left), start + len(sound))
        for i in range(start, end):
            s = sound[i - start]
            left[i] += s * gl
            right[i] += s * gr
            send[i] += s * gain * wet

    def note(self, inst, name_or_midi, start_beat, beats, vel=0.8, gain=1.0, wet=1.0, pan=0.0, wide=False, legato=0.95):
        m = name_or_midi if isinstance(name_or_midi, int) else midi(name_or_midi)
        held = max(0.03, beats * self.spb * legato)
        f = hz(m)
        # Inside a gliding line, the note slides in from the one before it.
        kw = {} if self._slide_from is None else dict(slide_from=hz(self._slide_from), slide=self._slide)
        if wide:
            # Two voices a few cents apart, one each side: a fuller, chorused sound.
            for d, side in ((1.003, -0.55), (1 / 1.003, 0.55)):
                if kw:
                    kw["slide_from"] = hz(self._slide_from) * d
                sound = self._tremble(inst, INSTRUMENTS[inst](f * d, held, vel, **kw), start_beat)
                self._mix(sound, start_beat, gain * 0.75, wet, side)
        else:
            self._mix(self._tremble(inst, INSTRUMENTS[inst](f, held, vel, **kw), start_beat), start_beat, gain, wet, pan)

    def _tremble(self, inst, sound, start_beat):
        """Applies the song's tremolo for this instrument, locked to the beat: full on each pulse."""
        if inst not in self.tremolo:
            return sound
        per_beat, depth = self.tremolo[inst]
        rate = TAU * per_beat * self.bpm / 60.0
        t0 = self._swung(start_beat) * self.spb
        for i in range(len(sound)):
            sound[i] *= 1.0 - depth * (0.5 - 0.5 * math.cos(rate * (t0 + i / RATE)))
        return sound

    def hit(self, kind, start_beat, vel=0.8, gain=1.0, wet=0.4, pan=0.0):
        self._mix(drum(kind, vel), start_beat, gain, wet, pan)

    def line(self, inst, start_beat, notes, vel=0.8, gain=1.0, wet=1.0, transpose=0, pan=0.0, wide=False, bars=None,
             legato=0.95, glide=0.0):
        """notes: list of (name or 'r', beats). Returns the beat after the line. With `bars`, the
        line must fill exactly that many bars of the song's meter. With `glide` (seconds), each note
        slides in from the one before it, unless a rest comes between; the instrument must take
        `slide_from` (the theremin does)."""
        if bars is not None:
            total = sum(b for _, b in notes)
            assert abs(total - bars * self.meter) < 1e-6, "line is %g beats, not %d bars" % (total, bars)
        at = start_beat; prev = None
        try:
            for name, beats in notes:
                if name != "r":
                    m = midi(name) + transpose
                    self._slide_from = prev if glide and prev != m else None
                    self._slide = glide
                    self.note(inst, m, at, beats, vel, gain, wet, pan, wide, legato)
                    prev = m
                else:
                    prev = None
                at += beats
        finally:
            self._slide_from = None
        return at

    def render(self, path):
        total = len(self.left)
        wet_l = _reverb(self.send, self.reverb, 0)
        wet_r = _reverb(self.send, self.reverb, 23)
        n = self.length if self.loop else min(total, self.length + int(self.tail * RATE))
        out_l = array("f", [0.0]) * n; out_r = array("f", [0.0]) * n
        for i in range(total if self.loop else n):
            j = i % n if i >= n else i
            out_l[j] += self.left[i] + wet_l[i]
            out_r[j] += self.right[i] + wet_r[i]
        if not self.loop:
            fade = int(0.6 * RATE)
            for k in range(fade):
                g = 1.0 - k / fade
                out_l[n - fade + k] *= g; out_r[n - fade + k] *= g
        peak = max(1e-6, max(max(abs(x) for x in out_l), max(abs(x) for x in out_r)))
        scale = 0.9 / peak
        frames = array("h", [0]) * (2 * n)
        norm = math.tanh(1.15)
        for i in range(n):
            frames[2 * i] = int(math.tanh(out_l[i] * scale * 1.15) / norm * 32000)
            frames[2 * i + 1] = int(math.tanh(out_r[i] * scale * 1.15) / norm * 32000)
        with wave.open(path, "wb") as w:
            w.setnchannels(2); w.setsampwidth(2); w.setframerate(RATE)
            w.writeframes(frames.tobytes())
        return n / RATE


def _reverb(x, amount, spread):
    """A small room: four feedback combs into two allpasses. `spread` offsets the delays per side."""
    n = len(x)
    acc = array("f", [0.0]) * n
    for d, g in ((0.0297, 0.80), (0.0371, 0.78), (0.0411, 0.76), (0.0437, 0.74)):
        delay = int(RATE * d) + spread
        buf = array("f", [0.0]) * delay; j = 0
        for i in range(n):
            y = buf[j]
            buf[j] = x[i] + y * g
            acc[i] += y
            j += 1
            if j == delay:
                j = 0
    for d, g in ((0.005, 0.7), (0.0017, 0.7)):
        delay = int(RATE * d) + spread // 4
        buf = array("f", [0.0]) * delay; j = 0
        for i in range(n):
            b = buf[j]
            y = -g * acc[i] + b
            buf[j] = acc[i] + g * y
            acc[i] = y
            j += 1
            if j == delay:
                j = 0
    for i in range(n):
        acc[i] *= amount * 0.25
    return acc


# --- chords ---------------------------------------------------------------------------------

QUALITY = {"": [0, 4, 7], "m": [0, 3, 7], "7": [0, 4, 7, 10], "maj7": [0, 4, 7, 11], "m7": [0, 3, 7, 10],
           "m6": [0, 3, 7, 9], "6": [0, 4, 7, 9], "dim": [0, 3, 6],
           "maj9": [4, 7, 11, 14], "m9": [3, 7, 10, 14], "9": [4, 10, 14, 7], "13": [4, 10, 14, 21],
           "7b9": [4, 10, 13, 7], "m11": [3, 10, 14, 17], "m7b5": [0, 3, 6, 10], "sus4": [0, 5, 7],
           "mmaj7": [0, 3, 7, 11]}


def chord(symbol, low=54):
    """'Fmaj9' -> voiced MIDI notes between low and low + 12, plus the root's pitch class."""
    root = symbol[:2] if len(symbol) > 1 and symbol[1] in "#b" else symbol[:1]
    qual = symbol[len(root):]
    pc = NOTE_PC[root]
    notes = sorted(set(low + ((pc + iv - low) % 12) for iv in QUALITY[qual]))
    return notes, pc


def bass_note(symbol, octave_low=36, fifth=False):
    _, pc = chord(symbol)
    m = octave_low + ((pc - octave_low) % 12)
    return m + 7 if fifth else m
