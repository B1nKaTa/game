"""A tiny music synthesizer for Grandpa: standard-library Python only.

Songs are note lists written in songs.py. Each is rendered to a loopable 16-bit mono WAV: the
reverb tail at the end is folded back onto the start, so the file loops without a click.
Run:  py tools/music/render.py <out_dir> [song ...]
"""
import math, random, struct, wave
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


# --- envelopes -------------------------------------------------------------------------------

def adsr(n, attack, decay, sustain, release, held):
    """Per-sample envelope for a note held `held` samples, then released."""
    out = array("f", [0.0]) * n
    a = max(1, int(attack * RATE)); d = max(1, int(decay * RATE)); r = max(1, int(release * RATE))
    level = 0.0
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


# --- instruments -----------------------------------------------------------------------------
# Each takes (frequency, held seconds, velocity) and returns a float array.

def _length(held, release):
    return int((held + release) * RATE)


def epiano(f, held, vel):
    """An electric piano: a sine carrier with a decaying sine modulator."""
    rel = 0.35
    n = _length(held, rel); held_n = int(held * RATE)
    out = array("f", [0.0]) * n
    w = TAU * f / RATE
    for i in range(n):
        t = i / RATE
        dec = math.exp(-t * 2.2)
        index = 1.6 * math.exp(-t * 6.0) + 0.25
        s = math.sin(w * i + index * math.sin(w * i)) * dec
        if i > held_n:
            s *= max(0.0, 1.0 - (i - held_n) / (rel * RATE))
        out[i] = s * vel
    return out


def vibes(f, held, vel):
    """A vibraphone: sine plus a 4x partial, with motor tremolo."""
    rel = 0.6
    n = _length(held, rel); held_n = int(held * RATE)
    out = array("f", [0.0]) * n
    w = TAU * f / RATE
    for i in range(n):
        t = i / RATE
        dec = math.exp(-t * 1.6)
        trem = 0.8 + 0.2 * math.sin(TAU * 5.2 * t)
        s = (math.sin(w * i) + 0.18 * math.sin(4 * w * i) * math.exp(-t * 8)) * dec * trem
        if i > held_n:
            s *= max(0.0, 1.0 - (i - held_n) / (rel * RATE))
        out[i] = s * vel
    return out


def bass(f, held, vel):
    """A round plucked bass: sine with a little second harmonic."""
    rel = 0.08
    n = _length(held, rel)
    env = adsr(n, 0.004, 0.25, 0.55, rel, int(held * RATE))
    out = array("f", [0.0]) * n
    w = TAU * f / RATE
    for i in range(n):
        out[i] = (math.sin(w * i) + 0.3 * math.sin(2 * w * i) + 0.1 * math.sin(3 * w * i)) * env[i] * vel
    return out


def tuba(f, held, vel):
    rel = 0.06
    n = _length(held, rel)
    env = adsr(n, 0.025, 0.12, 0.7, rel, int(held * RATE))
    out = array("f", [0.0]) * n
    w = TAU * f / RATE
    for i in range(n):
        out[i] = (math.sin(w * i) + 0.5 * math.sin(2 * w * i) + 0.25 * math.sin(3 * w * i)
                  + 0.1 * math.sin(4 * w * i)) * env[i] * vel * 0.7
    return out


def pulse(f, held, vel, duty=0.25, vib=True):
    """A soft pulse lead with delayed vibrato, lowpassed so it never buzzes."""
    rel = 0.08
    n = _length(held, rel)
    env = adsr(n, 0.008, 0.1, 0.7, rel, int(held * RATE))
    out = array("f", [0.0]) * n
    phase = 0.0; lp = 0.0
    for i in range(n):
        t = i / RATE
        depth = 0.006 * min(1.0, max(0.0, (t - 0.18) / 0.25)) if vib else 0.0
        phase += f * (1.0 + depth * math.sin(TAU * 5.5 * t)) / RATE
        raw = 1.0 if (phase % 1.0) < duty else -1.0
        lp += 0.28 * (raw - lp)
        out[i] = lp * env[i] * vel * 0.55
    return out


def square(f, held, vel):
    return pulse(f, held, vel, 0.5, False)


def thin(f, held, vel):
    return pulse(f, held, vel, 0.125, False)


def theremin(f, held, vel):
    """A wobbly, spooky lead: sine with wide slow vibrato and a slide-in."""
    rel = 0.25
    n = _length(held, rel)
    env = adsr(n, 0.09, 0.2, 0.85, rel, int(held * RATE))
    out = array("f", [0.0]) * n
    phase = 0.0
    for i in range(n):
        t = i / RATE
        bend = 1.0 - 0.03 * math.exp(-t * 18)
        phase += f * bend * (1.0 + 0.012 * math.sin(TAU * 6.3 * t)) / RATE
        out[i] = (math.sin(TAU * phase) + 0.12 * math.sin(2 * TAU * phase)) * env[i] * vel * 0.8
    return out


def organ(f, held, vel):
    """Drawbar organ: 8', 4', 2 2/3', 2' with a slow rotating-speaker tremolo."""
    rel = 0.05
    n = _length(held, rel)
    env = adsr(n, 0.01, 0.05, 0.9, rel, int(held * RATE))
    out = array("f", [0.0]) * n
    w = TAU * f / RATE
    for i in range(n):
        t = i / RATE
        trem = 0.85 + 0.15 * math.sin(TAU * 6.0 * t)
        out[i] = (math.sin(w * i) + 0.6 * math.sin(2 * w * i) + 0.35 * math.sin(3 * w * i)
                  + 0.25 * math.sin(4 * w * i)) * env[i] * vel * trem * 0.4
    return out


def bell(f, held, vel):
    """A soft chime: inharmonic partials that ring out."""
    n = int(2.5 * RATE)
    out = array("f", [0.0]) * n
    w = TAU * f / RATE
    for i in range(n):
        t = i / RATE
        out[i] = (math.sin(w * i) * math.exp(-t * 1.5) + 0.45 * math.sin(2.76 * w * i) * math.exp(-t * 3)
                  + 0.25 * math.sin(5.4 * w * i) * math.exp(-t * 6)) * vel * 0.6
    return out


_rng = random.Random(7)


def _noise():
    return _rng.uniform(-1.0, 1.0)


def drum(kind, vel):
    if kind == "kick":
        n = int(0.35 * RATE); out = array("f", [0.0]) * n; phase = 0.0
        for i in range(n):
            t = i / RATE
            phase += (48 + 110 * math.exp(-t * 28)) / RATE
            out[i] = math.sin(TAU * phase) * math.exp(-t * 9) * vel
        return out
    if kind == "snare":
        n = int(0.22 * RATE); out = array("f", [0.0]) * n; prev = 0.0
        for i in range(n):
            t = i / RATE
            x = _noise(); hp = x - prev; prev = x
            out[i] = (0.6 * hp * math.exp(-t * 16) + 0.35 * math.sin(TAU * 190 * t) * math.exp(-t * 25)) * vel
        return out
    if kind in ("hat", "openhat"):
        n = int((0.25 if kind == "openhat" else 0.05) * RATE); out = array("f", [0.0]) * n; prev = 0.0
        decay = 12 if kind == "openhat" else 70
        for i in range(n):
            t = i / RATE
            x = _noise(); hp = x - prev; prev = x
            out[i] = hp * math.exp(-t * decay) * vel * 0.35
        return out
    if kind == "brush":
        n = int(0.16 * RATE); out = array("f", [0.0]) * n; lp = 0.0
        for i in range(n):
            t = i / RATE
            lp += 0.35 * (_noise() - lp)
            env = min(1.0, t / 0.02) * math.exp(-t * 14)
            out[i] = lp * env * vel * 0.5
        return out
    if kind == "rim":
        n = int(0.06 * RATE); out = array("f", [0.0]) * n
        for i in range(n):
            t = i / RATE
            out[i] = (math.sin(TAU * 1700 * t) * 0.5 + 0.5 * _noise()) * math.exp(-t * 60) * vel * 0.5
        return out
    raise ValueError(kind)


INSTRUMENTS = {"epiano": epiano, "vibes": vibes, "bass": bass, "tuba": tuba, "pulse": pulse,
               "square": square, "thin": thin, "theremin": theremin, "organ": organ, "bell": bell}


# --- the song ------------------------------------------------------------------------------

class Song:
    def __init__(self, bpm, beats, reverb=0.25):
        self.bpm = bpm; self.beats = beats; self.reverb = reverb
        self.spb = 60.0 / bpm
        self.length = int(beats * self.spb * RATE)
        self.dry = array("f", [0.0]) * (self.length + 4 * RATE)
        self.send = array("f", [0.0]) * (self.length + 4 * RATE)

    def _mix(self, sound, start_beat, gain, wet):
        start = int(start_beat * self.spb * RATE)
        dry, send = self.dry, self.send
        end = min(len(dry), start + len(sound))
        for i in range(start, end):
            s = sound[i - start] * gain
            dry[i] += s
            send[i] += s * wet

    def note(self, inst, name_or_midi, start_beat, beats, vel=0.8, gain=1.0, wet=1.0):
        m = name_or_midi if isinstance(name_or_midi, int) else midi(name_or_midi)
        held = max(0.03, beats * self.spb * 0.95)
        self._mix(INSTRUMENTS[inst](hz(m), held, vel), start_beat, gain, wet)

    def hit(self, kind, start_beat, vel=0.8, gain=1.0, wet=0.4):
        self._mix(drum(kind, vel), start_beat, gain, wet)

    def line(self, inst, start_beat, notes, vel=0.8, gain=1.0, wet=1.0, transpose=0):
        """notes: list of (name or 'r', beats). Returns the beat after the line."""
        at = start_beat
        for name, beats in notes:
            if name != "r":
                self.note(inst, midi(name) + transpose, at, beats, vel, gain, wet)
            at += beats
        return at

    def render(self, path):
        total = len(self.dry)
        wet = _reverb(self.send, self.reverb)
        mix = array("f", [0.0]) * total
        for i in range(total):
            mix[i] = self.dry[i] + wet[i]
        # Fold the tail past the loop point back onto the start, so the file loops cleanly.
        n = self.length
        out = array("f", mix[:n])
        for i in range(n, total):
            out[i - n] += mix[i]
        peak = max(1e-6, max(abs(x) for x in out))
        scale = 0.89 / peak
        frames = array("h", [0]) * n
        for i in range(n):
            x = math.tanh(out[i] * scale * 1.1) / math.tanh(1.1)
            frames[i] = int(max(-1.0, min(1.0, x)) * 32000)
        with wave.open(path, "wb") as w:
            w.setnchannels(1); w.setsampwidth(2); w.setframerate(RATE)
            w.writeframes(frames.tobytes())
        return n / RATE


def _reverb(x, amount):
    """A small room: four feedback combs into two allpasses."""
    n = len(x)
    combs = [(int(RATE * d), g) for d, g in ((0.0297, 0.80), (0.0371, 0.78), (0.0411, 0.76), (0.0437, 0.74))]
    acc = array("f", [0.0]) * n
    for delay, g in combs:
        buf = array("f", [0.0]) * delay; j = 0
        for i in range(n):
            y = buf[j]
            buf[j] = x[i] + y * g
            acc[i] += y
            j += 1
            if j == delay:
                j = 0
    for delay, g in ((int(RATE * 0.005), 0.7), (int(RATE * 0.0017), 0.7)):
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
           "m6": [0, 3, 7, 9], "6": [0, 4, 7, 9], "dim": [0, 3, 6]}


def chord(symbol, low=54):
    """'Fmaj7' -> voiced MIDI notes between low and low + 12, plus the root's pitch class."""
    root = symbol[:2] if len(symbol) > 1 and symbol[1] in "#b" else symbol[:1]
    qual = symbol[len(root):]
    pc = NOTE_PC[root]
    notes = sorted(low + ((pc + iv - low) % 12) for iv in QUALITY[qual])
    return notes, pc


def bass_note(symbol, octave_low=36, fifth=False):
    _, pc = chord(symbol)
    m = octave_low + ((pc - octave_low) % 12)
    return m + 7 if fifth else m
