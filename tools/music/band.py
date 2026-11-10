"""The band: songs played by real sampled instruments instead of the built-in synth.

A Band is a Song that keeps its notes instead of synthesising them. When it renders, the notes are
written to a MIDI file and played by FluidSynth through SoundFonts (General MIDI instruments, plus
the orchestra in bank 1 when it has been converted, see sfz2sf2.py). The tail that rings past the
loop point is folded back onto the start, so the WAV loops without a click.

The kit helpers (melody, comp, bassline, arp) work on a Band as on a Song. Two differences:
- a note's `gain` is ignored: a part's `level` sets how loud it sits, and `vel` how hard it is played;
- an instrument is a part declared with `s.part(name, program, ...)`, not one of synth.py's.

FluidSynth and the SoundFonts live outside the project. Their paths come from the environment, with
the developer's defaults below: GRANDPA_FLUIDSYNTH, GRANDPA_SOUNDFONT (General MIDI) and
GRANDPA_ORCHESTRA (bank-1 orchestra, optional).
"""
import math, os, random, struct, subprocess, tempfile, wave
from array import array

import synth

FLUIDSYNTH = os.environ.get("GRANDPA_FLUIDSYNTH", r"D:\fluidsynth-2.6.2\win64\fluidsynth-v2.6.2-win10-x64-cpp11\bin\fluidsynth.exe")
SOUNDFONT = os.environ.get("GRANDPA_SOUNDFONT", r"D:\soundfonts\GeneralUser-GS.sf2")
ORCHESTRA = os.environ.get("GRANDPA_ORCHESTRA", r"D:\soundfonts\vsco2-ce.sf2")
RATE = 44100
TPB = 480

GM = ["piano", "brightpiano", "grand_e", "honkytonk", "epiano", "epiano2", "harpsichord", "clav",
      "celesta", "glock", "musicbox", "vibes", "marimba", "xylophone", "bells", "dulcimer",
      "organ", "percorgan", "rockorgan", "churchorgan", "reedorgan", "accordion", "harmonica", "bandoneon",
      "nylon", "steel", "jazzgtr", "cleangtr", "mutedgtr", "overdrive", "distortion", "gtrharmonics",
      "upright", "fingerbass", "pickbass", "fretless", "slap", "slap2", "synthbass", "synthbass2",
      "violin", "viola", "cello", "contrabass", "tremstrings", "pizz", "harp", "timpani",
      "strings", "slowstrings", "synthstrings", "synthstrings2", "choir", "oohs", "synthvoice", "orchhit",
      "trumpet", "trombone", "tuba", "mutedtrumpet", "horn", "brass", "synthbrass", "synthbrass2",
      "sopranosax", "altosax", "tenorsax", "barisax", "oboe", "englishhorn", "bassoon", "clarinet",
      "piccolo", "flute", "recorder", "panflute", "bottle", "shakuhachi", "whistle", "ocarina",
      "squarelead", "sawlead", "calliope", "chiff", "charang", "voicelead", "fifths", "basslead",
      "newage", "warmpad", "polysynth", "choirpad", "bowedpad", "metalpad", "halopad", "sweeppad",
      "rain", "soundtrack", "crystal", "atmosphere", "brightness", "goblins", "echoes", "scifi",
      "sitar", "banjo", "shamisen", "koto", "kalimba", "bagpipe", "fiddle", "shanai",
      "tinkle", "agogo", "steeldrum", "woodblocks", "taiko", "melotom", "synthdrum", "reversecymbal",
      "fretnoise", "breath", "seashore", "bird", "phone", "helicopter", "applause", "gunshot"]
assert len(GM) == 128
# The converted orchestra (sfz2sf2.py), bank 1: General MIDI numbers where the instrument has one,
# 96-109 for the short and muted articulations. Its samples are not looped, so a note held longer
# than about five seconds fades with its sample.
ORCH = {"orch_" + k: (1, p) for k, p in {
    "piano": 0, "glock": 9, "marimba": 12, "xylophone": 13, "bells": 14, "organ": 19,
    "violin": 40, "viola": 41, "cello": 42, "bass": 43, "tremolo": 44, "pizz": 45, "harp": 46, "timpani": 47,
    "strings": 48, "strings_soft": 49, "trumpet": 56, "trombone": 57, "tuba": 58, "trumpet_mute": 59,
    "horn": 60, "oboe": 68, "bassoon": 70, "clarinet": 71, "piccolo": 72, "flute": 73,
    "strings_short": 96, "violin_short": 97, "trumpet_short": 98, "trombone_short": 99, "tuba_short": 100,
    "horn_short": 101, "flute_short": 102, "oboe_short": 103, "clarinet_short": 104, "bassoon_short": 105,
    "piccolo_short": 106, "horn_mute": 107, "trumpet_harmon": 108, "timpani_roll": 109}.items()}
ORCH["orch_celesta"] = (0, 8)  # the orchestra has none; the General MIDI one stands in
# Drum kits (bank 128) and drum names -> General MIDI keys.
KITS = {"standard": 0, "room": 8, "power": 16, "electronic": 24, "808": 25, "jazz": 32, "brush": 40, "orchestra": 48}
DRUMS = {"kick": 36, "kick2": 35, "snare": 38, "snare2": 40, "rim": 37, "clap": 39, "hat": 42, "pedalhat": 44,
         "openhat": 46, "crash": 49, "crash2": 57, "ride": 51, "ridebell": 53, "splash": 55, "china": 52,
         "tom_floor": 41, "tom_lo": 43, "tom": 45, "tom_mid": 47, "tom_hi": 48, "tom_top": 50,
         "tambourine": 54, "cowbell": 56, "vibraslap": 58, "bongo_hi": 60, "bongo": 61, "conga_hi": 62,
         "conga": 63, "conga_lo": 64, "timbale_hi": 65, "timbale": 66, "agogo": 67, "cabasa": 69,
         "shaker": 70, "guiro": 73, "claves": 75, "woodblock_hi": 76, "woodblock": 77, "tick": 76,
         "triangle": 81, "triangle_mute": 80, "jingle": 83, "sticks": 31, "click": 33}


def program(spec):
    """'nylon' -> (0, 24); 'orch_strings' -> (1, 48), or (0, 48) when the orchestra is missing; (b, p) as is."""
    if isinstance(spec, tuple):
        bank, prog = spec
    elif isinstance(spec, int):
        bank, prog = 0, spec
    elif spec in ORCH:
        bank, prog = ORCH[spec]
    else:
        bank, prog = 0, GM.index(spec)
    if bank == 1 and not os.path.exists(ORCHESTRA):
        bank = 0
    return bank, prog


class _Part:
    def __init__(self, name, spec, level, pan, reverb, chorus):
        self.name = name; self.bank, self.prog = program(spec)
        self.level = level; self.pan = pan; self.reverb = reverb; self.chorus = chorus
        self.channels = {}  # side (-1, 0, 1) -> MIDI channel


class Band(synth.Song):
    """bars of `meter` beats at `bpm`. `loudness` is the target RMS in dBFS (calm songs sit lower).
    `humanize` nudges each note's time (seconds) and velocity a little, from a fixed seed."""

    def __init__(self, bpm, bars, meter=4, swing=0.0, loop=True, tail=4.0, loudness=-17.0, humanize=0.006,
                 room=0.6, seed=7):
        self.bpm = bpm; self.meter = meter; self.beats = bars * meter; self.swing = swing
        self.loop = loop; self.tail = tail; self.loudness = loudness; self.room = room
        self.spb = 60.0 / bpm; self.tremolo = {}
        self._slide_from = None; self._slide = 0.0
        self._rng = random.Random(seed); self._humanize = humanize
        self.parts = {}; self.kit_program = 0; self.kit_level = 0.85
        self._events = []  # (beat, order, kind, data)

    # --- setting up -------------------------------------------------------------------------
    def part(self, name, spec, level=0.75, pan=0.0, reverb=0.35, chorus=0.0):
        """Declares an instrument part. `level` 0..1 is its volume, `reverb`/`chorus` its sends."""
        self.parts[name] = _Part(name, spec, level, pan, reverb, chorus)

    def kit(self, name="standard", level=0.85):
        self.kit_program = KITS[name]; self.kit_level = level

    # --- playing ----------------------------------------------------------------------------
    def _jitter(self):
        return self._rng.uniform(-self._humanize, self._humanize) / self.spb

    def note(self, inst, name_or_midi, start_beat, beats, vel=0.8, gain=1.0, wet=1.0, pan=0.0, wide=False, legato=0.95):
        if inst not in self.parts:
            raise KeyError("part %r was never declared with s.part()" % inst)
        m = name_or_midi if isinstance(name_or_midi, int) else synth.midi(name_or_midi)
        side = 0 if wide or abs(pan) < 0.25 else (1 if pan > 0 else -1)
        v = max(1, min(127, int(127 * vel) + self._rng.randint(-5, 5)))
        start = max(0.0, self._swung(start_beat) + self._jitter())
        self._events.append((start, 2, "on", (inst, side, m, v)))
        self._events.append((start + max(0.05, beats * legato), 1, "off", (inst, side, m)))

    def hit(self, kind, start_beat, vel=0.8, gain=1.0, wet=0.4, pan=0.0):
        v = max(1, min(127, int(127 * vel) + self._rng.randint(-4, 4)))
        start = max(0.0, self._swung(start_beat) + self._jitter() * 0.5)
        self._events.append((start, 2, "drum", (DRUMS[kind], v)))

    def cc(self, inst, beat, control, value):
        """A controller change on every channel of a part, e.g. 11 (expression) for a swell, 64 (pedal)."""
        self._events.append((beat, 0, "cc", (inst, control, int(value))))

    def swell(self, inst, start_beat, beats, low=40, high=127, steps=16):
        """Expression rising from `low` to `high` over `beats` (a crescendo); swap them to fade."""
        for k in range(steps + 1):
            self.cc(inst, start_beat + beats * k / steps, 11, low + (high - low) * k / steps)

    # --- rendering --------------------------------------------------------------------------
    def _channel(self, part, side, header):
        if side not in part.channels:
            used = {c for p in self.parts.values() for c in p.channels.values()}
            free = [c for c in range(16) if c != 9 and c not in used]
            if not free:
                if 0 in part.channels:
                    return part.channels[0]
                raise RuntimeError("out of MIDI channels at part %r" % part.name)
            c = free[0]; part.channels[side] = c
            pan = max(-1.0, min(1.0, part.pan + 0.45 * side))
            header += [bytes([0xB0 | c, 0, part.bank]), bytes([0xB0 | c, 32, 0]), bytes([0xC0 | c, part.prog]),
                       bytes([0xB0 | c, 7, int(127 * part.level)]), bytes([0xB0 | c, 10, int(64 + 63 * pan)]),
                       bytes([0xB0 | c, 91, int(127 * part.reverb)]), bytes([0xB0 | c, 93, int(127 * part.chorus)]),
                       bytes([0xB0 | c, 11, 127])]
        return part.channels[side]

    def write_midi(self, path):
        header = [bytes([0xC9, self.kit_program]), bytes([0xB9, 7, int(127 * self.kit_level)]), bytes([0xB9, 91, 40])]
        ordered = sorted(self._events, key=lambda e: (e[0], e[1]))
        # Every channel is set up in the header first, so a controller change reaches all of a part's.
        for beat, order, kind, data in ordered:
            if kind == "on":
                self._channel(self.parts[data[0]], data[1], header)
        timed = []
        for beat, order, kind, data in ordered:
            if kind in ("on", "off"):
                part = self.parts[data[0]]
                c = part.channels.get(data[1], part.channels.get(0))
                if c is None:
                    c = next(iter(part.channels.values()))
                timed.append((beat, order, bytes([0x90 | c, data[2], data[3]]) if kind == "on" else bytes([0x80 | c, data[2], 0])))
            elif kind == "drum":
                key, v = data
                timed.append((beat, order, bytes([0x99, key, v])))
                timed.append((beat + 0.2, 1, bytes([0x89, key, 0])))
            elif kind == "cc":
                inst, control, value = data
                for c in self.parts[inst].channels.values():
                    timed.append((beat, order, bytes([0xB0 | c, control, max(0, min(127, value))])))
        timed.sort(key=lambda e: (e[0], e[1]))
        tempo = int(60_000_000 / self.bpm)
        body = bytearray(b"\x00\xFF\x51\x03" + tempo.to_bytes(3, "big"))
        for msg in header:
            body += b"\x00" + msg
        last = 0
        for beat, _, msg in timed:
            tick = max(0, int(round(beat * TPB)))
            body += _vlq(tick - last) + msg; last = tick
        end = int((self.beats + self.tail / self.spb) * TPB)
        body += _vlq(max(0, end - last)) + b"\xFF\x2F\x00"
        with open(path, "wb") as f:
            f.write(b"MThd" + struct.pack(">IHHH", 6, 0, 1, TPB) + b"MTrk" + struct.pack(">I", len(body)) + bytes(body))

    def render(self, path, keep_midi=False):
        stem = os.path.splitext(path)[0]
        mid = stem + ".mid"
        self.write_midi(mid)
        fonts = [SOUNDFONT] + ([ORCHESTRA] if os.path.exists(ORCHESTRA) else [])
        raw = tempfile.mktemp(suffix=".wav", dir=os.path.dirname(os.path.abspath(path)))
        cmd = [FLUIDSYNTH, "-ni", "-q", "-r", str(RATE), "-g", "0.4", "-o", "synth.polyphony=512",
               "-o", "synth.reverb.room-size=%.2f" % self.room, "-o", "synth.reverb.damp=0.35",
               "-o", "synth.reverb.width=0.9", "-o", "synth.reverb.level=0.75", "-F", raw] + fonts + [mid]
        subprocess.run(cmd, check=True)
        try:
            seconds = _finish(raw, path, self.beats * self.spb if self.loop else None, self.loudness)
        finally:
            os.remove(raw)
            if not keep_midi:
                os.remove(mid)
        return seconds


def _vlq(n):
    out = [n & 0x7F]; n >>= 7
    while n:
        out.append(0x80 | (n & 0x7F)); n >>= 7
    return bytes(reversed(out))


def _finish(raw, out_path, loop_seconds, loudness):
    """Folds the tail onto the start (or trims trailing silence), sets the loudness, limits the peaks."""
    with wave.open(raw) as w:
        ch = w.getnchannels(); data = array("h", w.readframes(w.getnframes()))
    if loop_seconds is not None:
        n = int(round(loop_seconds * RATE)) * ch
        out = array("f", data[:n]) if len(data) >= n else array("f", data) + array("f", [0.0]) * (n - len(data))
        for i in range(n, len(data)):
            out[i % n] += data[i]
    else:
        end = len(data)
        while end > ch and abs(data[end - 1]) < 8:
            end -= 1
        out = array("f", data[:end])
        fade = min(len(out) // ch, int(0.05 * RATE))
        for k in range(fade):
            for c in range(ch):
                out[len(out) - (fade - k) * ch + c] *= k / fade
    total = sum(x * x for x in out) / max(1, len(out))
    rms_db = 10 * math.log10(max(total, 1e-9) / (32768.0 ** 2))
    g = 10 ** ((loudness - rms_db) / 20) / 32768.0
    # The ceiling sits under check.py's FULL (32000 of 32767), so a limited peak never reads as clipping.
    knee = 0.75; room = 0.965 - knee
    frames = array("h", [0]) * len(out)
    for i, x in enumerate(out):
        y = x * g; a = abs(y)
        if a > knee:
            y = math.copysign(knee + room * math.tanh((a - knee) / room), y)
        frames[i] = int(y * 32767)
    with wave.open(out_path, "wb") as w:
        w.setnchannels(ch); w.setsampwidth(2); w.setframerate(RATE)
        w.writeframes(frames.tobytes())
    return len(out) / ch / RATE


def beat(s, bar, grid, vel=1.0):
    """Drums from a grid per bar, {kind: 'x.o.g...'}: x loud, o medium, g ghost, . rest."""
    for kind, pattern in grid.items():
        step = s.meter / len(pattern)
        for i, c in enumerate(pattern):
            if c in "xog":
                s.hit(kind, bar * s.meter + i * step, vel=vel * {"x": 0.9, "o": 0.62, "g": 0.32}[c])


def roll(s, bar, start=2.0, count=8, kind="snare", step=0.25, low=0.3, high=0.85):
    """A rising roll into the next bar."""
    for q in range(count):
        s.hit(kind, bar * s.meter + start + q * step, vel=low + (high - low) * q / max(1, count - 1))
