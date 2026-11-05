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


def theremin(f, held, vel):
    rel = 0.25; n = _n(held, rel); env = _env(n, 0.09, 0.2, 0.85, rel, int(held * RATE))
    out = array("f", [0.0]) * n; ph = 0.0
    for i in range(n):
        t = i / RATE
        ph += f * (1.0 - 0.03 * math.exp(-t * 18)) * (1.0 + 0.012 * math.sin(TAU * 6.3 * t)) / RATE
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


INSTRUMENTS = {"epiano": epiano, "vibes": vibes, "bass": bass, "synthbass": synthbass, "pulse": pulse,
               "square": square, "thin": thin, "brass": brass, "theremin": theremin, "organ": organ,
               "bell": bell}

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
    raise ValueError(kind)


# --- the song ------------------------------------------------------------------------------

class Song:
    def __init__(self, bpm, beats, reverb=0.25, swing=0.0):
        self.bpm = bpm; self.beats = beats; self.reverb = reverb; self.swing = swing
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

    def note(self, inst, name_or_midi, start_beat, beats, vel=0.8, gain=1.0, wet=1.0, pan=0.0, wide=False):
        m = name_or_midi if isinstance(name_or_midi, int) else midi(name_or_midi)
        held = max(0.03, beats * self.spb * 0.95)
        f = hz(m)
        if wide:
            # Two voices a few cents apart, one each side: a fuller, chorused sound.
            self._mix(INSTRUMENTS[inst](f * 1.003, held, vel), start_beat, gain * 0.75, wet, -0.55)
            self._mix(INSTRUMENTS[inst](f / 1.003, held, vel), start_beat, gain * 0.75, wet, 0.55)
        else:
            self._mix(INSTRUMENTS[inst](f, held, vel), start_beat, gain, wet, pan)

    def hit(self, kind, start_beat, vel=0.8, gain=1.0, wet=0.4, pan=0.0):
        self._mix(drum(kind, vel), start_beat, gain, wet, pan)

    def line(self, inst, start_beat, notes, vel=0.8, gain=1.0, wet=1.0, transpose=0, pan=0.0, wide=False):
        """notes: list of (name or 'r', beats). Returns the beat after the line."""
        at = start_beat
        for name, beats in notes:
            if name != "r":
                self.note(inst, midi(name) + transpose, at, beats, vel, gain, wet, pan, wide)
            at += beats
        return at

    def render(self, path):
        total = len(self.left)
        wet_l = _reverb(self.send, self.reverb, 0)
        wet_r = _reverb(self.send, self.reverb, 23)
        n = self.length
        out_l = array("f", [0.0]) * n; out_r = array("f", [0.0]) * n
        for i in range(total):
            j = i % n if i >= n else i
            out_l[j] += self.left[i] + wet_l[i]
            out_r[j] += self.right[i] + wet_r[i]
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
           "7b9": [4, 10, 13, 7], "m11": [3, 10, 14, 17]}


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
