"""Floor music, third try: action music for a roguelite, one piece per floor.

Floors are where the fighting is, so each has a full drum kit, a pushing bass, an ostinato and a
hook. They share one shape, so the game sounds like one game: the ostinato alone (4 bars), the hook
(8), the hook doubled (8), a lift with a second tune (8), a breakdown (4), the hook at full weight
(8). Each floor has its own key, tempo, colour and tunes; no tune is shared, and there are no
sound-effect jokes. Tempo and weight rise with depth.
"""
import jb_theme  # noqa: F401  (adds the sus and add chord qualities)
from band import Band, beat, roll
from kit import melody, comp, bassline
from rb2_floors import figure, _bars

SECTIONS = ["intro"] * 4 + ["a1"] * 8 + ["a2"] * 8 + ["lift"] * 8 + ["break"] * 4 + ["a3"] * 8
FULL = {"a1", "a2", "a3"}
BAND = {"a1", "a2", "a3", "lift"}
ALL = {"intro", "a1", "a2", "lift", "break", "a3"}
QUIET = [(0, 4), (28, 32)]

# Bass patterns: (offset, beats, semitones above the root).
E8 = [(e * 0.5, 0.42, 0) for e in range(8)]
OCT8 = [(e * 0.5, 0.42, 12 if e % 2 else 0) for e in range(8)]
GAL = [(e * 0.5, 0.42, 12 if e in (2, 5) else (7 if e == 7 else 0)) for e in range(8)]
SYNC = [(0, 0.7, 0), (0.75, 0.2, 0), (1, 0.45, 0), (1.5, 0.45, 7), (2, 0.7, 0), (2.75, 0.2, 0), (3, 0.45, 12), (3.5, 0.45, 7)]
PISTON = [(0, 0.45, 0), (0.75, 0.2, 0), (1, 0.45, 0), (1.5, 0.45, 0), (2, 0.45, 0), (2.75, 0.2, 0), (3, 0.45, 0), (3.5, 0.45, 7)]
TUMBAO = [(0, 0.45, 0), (1.5, 0.9, 7), (2.5, 0.45, 7), (3, 0.45, 12), (3.5, 0.45, 7)]
WALK4 = [(0, 0.9, 0), (1, 0.9, 7), (2, 0.9, 12), (3, 0.9, 7)]
HOLD = [(0, 1.9, 0), (2, 1.9, 0)]

# Drum grids, one bar each: x loud, o medium, g ghost.
H8 = "x.o.x.o.x.o.x.o."
ROCK = {"kick": "x.....x.x.......", "snare": "....x.......x...", "hat": H8}
ROCK2 = {"kick": "x.....x.x.x.....", "snare": "....x.......x..o", "hat": H8}
DRIVE = {"kick": "x..x..x.x..x..x.", "snare": "....x.......x...", "hat": H8}
RIDE = {"kick": "x.....x.x.....x.", "snare": "....x.......x...", "ride": "x.o.x.o.x.o.x.o.", "ridebell": "x.......x......."}
FOUR = {"kick": "x...x...x...x...", "clap": "....x.......x...", "hat": "g.g.g.g.g.g.g.g.", "openhat": "..o...o...o...o."}
TOMS = {"kick": "x.....x.x.....x.", "snare": "....x.......x...", "tom_floor": "..o...o...o.o...", "hat": "x...x...x...x..."}
LATIN = {"kick": "x..x..x.x..x..x.", "rim": "..o..o....o.o...", "conga": "..o.x...o.x.o.x.", "cowbell": "o...o...o...o...",
         "shaker": "gogogogogogogogo"}
INTRO = {"hat": "g.g.g.g.g.g.g.g.", "kick": "x.......x......."}
BREAK = {"kick": "x.........x.....", "rim": "....o.......o...", "hat": "g.g.g.g.g.g.g.g."}
PAD = "x---------------"
OFF = "..x...x...x...x."


def build(c):
    """One floor from its sheet `c`: parts, ostinatos, comps, bass, drums, two tunes and who plays them."""
    s = Band(c["bpm"], 40, swing=c.get("swing", 0.0), loudness=c.get("loud", -17.5), room=c.get("room", 0.5))
    for name, spec, level, pan, reverb, chorus in c["parts"]:
        s.part(name, spec, level=level, pan=pan, reverb=reverb, chorus=chorus)
    s.kit(c.get("kit", "standard"), level=c.get("kit_level", 0.8))
    a4 = " ".join(c["A"].split()[:4])
    p = _bars(" ".join([a4, c["A"], c["A"], c["B"], a4, c["A"]]), 40)
    for bar, parts in enumerate(p):
        k = SECTIONS[bar]
        first = bar == 0 or SECTIONS[bar - 1] != k
        last = bar == 39 or SECTIONS[bar + 1] != k
        for o in c["ost"]:
            if k in o["on"]:
                step = o.get("step", 0.5)
                figure(s, o["inst"], bar, parts, o["order"], step=step, low=o["low"], vel=o.get("vel", 0.6),
                       length=o.get("length", step * 0.9))
        for m in c.get("comps", []):
            if k in m["on"]:
                r = m["rhythm"]
                comp(s, m["inst"], bar, parts, r if isinstance(r, str) else r[bar % len(r)], low=m["low"], vel=m.get("vel", 0.5))
        pat = c["bass"]["pats"].get(k)
        if pat:
            bassline(s, c["bass"]["inst"], bar, parts, pat, low=c["bass"]["low"], vel=0.82)
        g = c["drums"].get(k)
        if g:
            beat(s, bar, g if isinstance(g, dict) else g[bar % len(g)], vel=c.get("drum_vel", 0.85))
        if first and k in BAND:
            s.hit("crash", bar * 4, vel=0.7)
        if last:
            short = k in ("a1", "a2", "lift", "a3")
            roll(s, bar, start=3.0 if short else 2.0, count=4 if short else 8, kind=c.get("fill", "snare"))
    for sec, start, text in (("a1", 4, c["hook"]), ("a2", 12, c["hook"]), ("lift", 20, c["hook_b"]), ("a3", 32, c["hook"])):
        for inst, transpose, vel in c["lead"][sec]:
            melody(s, inst, start, text, bars=8, vel=vel, transpose=transpose)
    if "extra" in c:
        c["extra"](s, p)
    return s


def _timpani(bars):
    def extra(s, p):
        for bar in bars:
            bassline(s, "timp", bar, p[bar], [(0, 0.9, 0)], low=38, vel=0.75)
    return extra


def _info(key, bpm, about):
    return dict(key=key, bpm=bpm, meter=4, bars=40, quiet=QUIET, about=about)


INFO = {
    "records_basement": _info("D minor", 132, "Records Basement: a low piano riff and a ticking muted guitar, clarinet and vibes on the hook."),
    "unkempt_cemetery": _info("E minor", 144, "Cemetery: galloping strings and harp, a fiddle hook, a bell on the downbeats."),
    "sunset_shores": _info("A major", 138, "Sunset Shores: bright and breezy, strummed guitar and marimba, accordion and flute."),
    "furnace_works": _info("C minor", 126, "Furnace Works: heavy toms, low brass stabs and a marimba piston, horns on the hook."),
    "funeral_parlour": _info("Bb minor", 150, "Funeral Parlour: gothic drive, harpsichord and organ, cello under the tune."),
    "flashback_cinema": _info("G minor", 152, "Flashback Cinema: a chase on piano and strings, violin and clarinet racing."),
    "last_resort_cruise": _info("A minor", 136, "Cruise: hot latin percussion, piano montuno and brass stabs, a trumpet hook."),
    "seance_hotline": _info("F# minor", 140, "Seance Hotline: a glittering arpeggio over synth bass, an eerie voice lead."),
    "terminal_zero": _info("C# minor", 150, "Terminal Zero: four on the floor, synth arpeggios and a bright piano hook."),
    "head_office": _info("F minor", 160, "Head Office: full orchestra at speed, strings, timpani and horns."),
}


# ---------------------------------------------------------------------------------------------
# The Records Basement, depth 1. D minor, 132 bpm. A low piano riff and a muted guitar ticking in
# sixteenths; clarinet takes the hook, vibes join it.
# ---------------------------------------------------------------------------------------------

def records_basement():
    return build(dict(
        bpm=132, kit="standard",
        A="Dm Dm Bb C Dm Dm Bb A7", B="F C Gm A7 F C Bb A7",
        parts=[("piano", "piano", 0.6, -0.3, 0.3, 0), ("gtr", "mutedgtr", 0.55, 0.45, 0.25, 0), ("bass", "fingerbass", 0.8, 0, 0.1, 0),
               ("clar", "orch_clarinet", 0.72, 0.1, 0.35, 0), ("vibes", "vibes", 0.5, -0.15, 0.4, 0),
               ("strs", "orch_strings_short", 0.55, 0.35, 0.4, 0), ("pad", "slowstrings", 0.34, -0.35, 0.5, 0.4)],
        ost=[dict(inst="gtr", order=[0, 2, 1, 2], step=0.25, low=57, vel=0.55, on=ALL),
             dict(inst="piano", order=[0, 0, 3, 0, 2, 0, 1, 0], low=45, vel=0.62, on=FULL | {"break"})],
        comps=[dict(inst="strs", rhythm=OFF, low=60, vel=0.5, on={"a2", "a3", "lift"}),
               dict(inst="pad", rhythm=PAD, low=55, vel=0.5, on={"lift", "a3"})],
        bass=dict(inst="bass", low=26, pats={"intro": HOLD, "a1": SYNC, "a2": SYNC, "lift": E8, "break": HOLD, "a3": SYNC}),
        drums={"intro": INTRO, "a1": ROCK, "a2": [ROCK, ROCK2], "lift": RIDE, "break": BREAK, "a3": DRIVE},
        hook=("D5:.5 F5 A5:1 G5:.5 F5 E5 D5 | F5:1.5 E5:.5 D5:2 | D5:.5 F5 Bb5:1 A5:.5 G5 F5 D5 | E5:1.5 G5:.5 E5:2 | "
              "D5:.5 F5 A5:1 G5:.5 F5 E5 D5 | A5:1.5 G5:.5 F5:1 D5 | Bb5:.5 A5 G5 F5 D5:1 F5 | E5:1 C#5 A4:2"),
        hook_b=("A5:2 C6:1 A5 | G5:2 E5:2 | D5:1 G5:.5 Bb5 A5:1 G5 | E5:3 r:1 | "
                "A5:2 C6:1 A5 | G5:1.5 E5:.5 C5:2 | D5:.5 F5 Bb5:1 A5:.5 G5 F5 D5 | E5:.5 C#5 A4:1 A4:2"),
        lead={"a1": [("clar", 0, 0.78)], "a2": [("clar", 0, 0.8), ("vibes", 0, 0.6)],
              "lift": [("clar", 0, 0.78), ("vibes", 0, 0.55)], "a3": [("clar", 0, 0.85), ("vibes", 12, 0.6)]},
    ))


# ---------------------------------------------------------------------------------------------
# The Unkempt Cemetery, depth 2. E minor, 144 bpm. Short strings gallop, a harp runs above, a
# fiddle plays the hook with a flute, and a bell marks the big downbeats.
# ---------------------------------------------------------------------------------------------

def _cemetery_bells(s, p):
    for bar in (4, 12, 20, 32):
        s.note("bells", "E5", bar * 4, 3.5, vel=0.6)


def unkempt_cemetery():
    return build(dict(
        bpm=144, kit="standard", extra=_cemetery_bells,
        A="Em D C B7 Em D C B7", B="Am Em B7 Em Am Em F#m7b5 B7",
        parts=[("strs", "orch_strings_short", 0.62, -0.35, 0.4, 0), ("harp", "orch_harp", 0.5, 0.45, 0.4, 0),
               ("bass", "fingerbass", 0.8, 0, 0.1, 0), ("violin", "orch_violin", 0.72, 0.1, 0.4, 0),
               ("flute", "orch_flute", 0.52, -0.1, 0.4, 0), ("choir", "choir", 0.34, 0.3, 0.6, 0.3),
               ("bells", "orch_bells", 0.45, -0.2, 0.6, 0)],
        ost=[dict(inst="strs", order=[0, 2, 1, 2, 0, 2, 3, 2], low=52, vel=0.62, on=ALL - {"break"}),
             dict(inst="harp", order=[0, 1, 2, 3, 2, 1], step=0.25, low=64, vel=0.5, on={"a2", "a3", "lift", "break"})],
        comps=[dict(inst="choir", rhythm=PAD, low=55, vel=0.5, on={"lift", "a3"})],
        bass=dict(inst="bass", low=28, pats={"intro": HOLD, "a1": GAL, "a2": GAL, "lift": E8, "break": HOLD, "a3": GAL}),
        drums={"intro": INTRO, "a1": DRIVE, "a2": DRIVE, "lift": RIDE, "break": TOMS, "a3": [DRIVE, ROCK2]},
        hook=("E5:.5 G5 B5:1 A5:.5 G5 F#5 E5 | F#5:.5 A5 D5:1 F#5:1 A5 | G5:.5 E5 C5:1 E5:.5 G5 E5 C5 | D#5:1 F#5 B4:2 | "
              "E5:.5 G5 B5:1 A5:.5 G5 F#5 E5 | F#5:.5 A5 D6:1 C6:.5 B5 A5 F#5 | G5:.5 E5 G5 C6 B5:1 A5 | B5:1 F#5 D#5:2"),
        hook_b=("A5:1.5 C6:.5 E6:2 | B5:1.5 G5:.5 E5:2 | F#5:1 A5 B5 D#6 | E6:3 r:1 | "
                "C6:1.5 A5:.5 E5:2 | G5:1.5 B5:.5 E6:2 | C6:1 A5 F#5 A5 | B5:1 F#5 D#5:2"),
        lead={"a1": [("violin", 0, 0.78)], "a2": [("violin", 0, 0.8), ("flute", 0, 0.6)],
              "lift": [("violin", 0, 0.78), ("flute", 0, 0.6)], "a3": [("violin", 0, 0.85), ("flute", 0, 0.7)]},
    ))


# ---------------------------------------------------------------------------------------------
# Sunset Shores Eternal Care, depth 2. A major with a flat seventh, 138 bpm: the bright one. A
# strummed steel guitar and a marimba drive it, an accordion plays the hook and a flute the lift.
# ---------------------------------------------------------------------------------------------

def sunset_shores():
    full = {"kick": "x..x..x.x..x..x.", "snare": "....x.......x...", "hat": H8, "tambourine": "....o.......o..."}
    return build(dict(
        bpm=138, kit="standard",
        A="A G D A A G D E", B="F#m D A E F#m D E E",
        parts=[("strum", "steel", 0.55, -0.4, 0.25, 0), ("marimba", "orch_marimba", 0.5, 0.45, 0.3, 0),
               ("bass", "fingerbass", 0.8, 0, 0.1, 0), ("acc", "accordion", 0.6, 0.1, 0.35, 0),
               ("flute", "orch_flute", 0.56, -0.1, 0.4, 0), ("pad", "slowstrings", 0.32, 0.3, 0.5, 0.4)],
        ost=[dict(inst="marimba", order=[0, 2, 3, 2, 1, 2, 3, 2], low=57, vel=0.58, on=ALL - {"a1"})],
        comps=[dict(inst="strum", rhythm="x.xox.xox.xox.xo", low=52, vel=0.5, on=BAND | {"intro"}),
               dict(inst="pad", rhythm=PAD, low=57, vel=0.5, on={"lift", "a3"})],
        bass=dict(inst="bass", low=33, pats={"intro": HOLD, "a1": SYNC, "a2": SYNC, "lift": E8, "break": HOLD, "a3": SYNC}),
        drums={"intro": INTRO, "a1": full, "a2": full, "a3": full,
               "lift": dict(RIDE, conga="..o.x...o.x.o.x."),
               "break": {"conga": "..o.x...o.x.o.x.", "shaker": "g.g.g.g.g.g.g.g.", "kick": "x.......x......."}},
        hook=("E5:.5 A5 C#6:1 B5:.5 A5 G5:1 | B5:.5 G5 D5:1 G5:1 B5 | A5:.5 F#5 D5:1 F#5:.5 A5 D6:1 | C#6:1.5 B5:.5 A5:2 | "
              "E5:.5 A5 C#6:1 B5:.5 A5 G5:1 | B5:.5 D6 G5:1 B5:1 D6 | D6:.5 C#6 B5 A5 F#5:1 A5 | B5:1 G#5 E5:2"),
        hook_b=("C#6:2 A5:1 F#5 | A5:1.5 F#5:.5 D5:2 | E5:1 A5 C#6 E6 | D6:.5 C#6 B5:1 G#5:2 | "
                "C#6:2 A5:1 F#5 | A5:1.5 B5:.5 D6:2 | B5:1 G#5 E5 G#5 | B5:.5 C#6 D6 E6 E6:2"),
        lead={"a1": [("acc", 0, 0.75)], "a2": [("acc", 0, 0.78), ("flute", 0, 0.6)],
              "lift": [("flute", 0, 0.8), ("acc", -12, 0.5)], "a3": [("acc", 0, 0.82), ("flute", 0, 0.7)]},
    ))


# ---------------------------------------------------------------------------------------------
# The Furnace Works, depth 2. C minor with a flat second, 126 bpm: the heavy one. Floor toms and
# a marimba piston, low brass stabbing the off-beats, horns on the hook over timpani.
# ---------------------------------------------------------------------------------------------

def furnace_works():
    full = dict(TOMS, cowbell="....o.......o...")
    return build(dict(
        bpm=126, kit="power", fill="tom_lo", extra=_timpani(list(range(12, 20)) + list(range(32, 40))),
        A="Cm Cm Db Cm Cm Cm Ab G", B="Fm Cm Ab G Fm Cm Db G",
        parts=[("low", "orch_trombone_short", 0.62, -0.3, 0.35, 0), ("marimba", "orch_marimba", 0.5, 0.45, 0.3, 0),
               ("bass", "pickbass", 0.8, 0, 0.1, 0), ("horn", "orch_horn", 0.74, 0.1, 0.45, 0),
               ("trumpet", "orch_trumpet", 0.55, -0.15, 0.4, 0), ("pad", "slowstrings", 0.32, 0.35, 0.5, 0.4),
               ("timp", "orch_timpani", 0.6, 0, 0.4, 0)],
        ost=[dict(inst="marimba", order=[0, 2, 1, 2], step=0.25, low=48, vel=0.55, on=ALL)],
        comps=[dict(inst="low", rhythm="x..x..x.x..x..x.", low=43, vel=0.6, on=FULL),
               dict(inst="pad", rhythm=PAD, low=48, vel=0.5, on={"lift", "a3"})],
        bass=dict(inst="bass", low=24, pats={"intro": HOLD, "a1": PISTON, "a2": PISTON, "lift": E8, "break": HOLD, "a3": PISTON}),
        drums={"intro": {"tom_floor": "x..x..x.x..x..x.", "hat": "g.g.g.g.g.g.g.g."}, "a1": full, "a2": full, "a3": full, "lift": RIDE,
               "break": {"tom_floor": "x.....x.x.....x.", "cowbell": "....o.......o...", "hat": "g.g.g.g.g.g.g.g."}},
        hook=("C4:1 Eb4:.5 G4:1.5 F4:.5 Eb4 | G4:1 C4:.5 Eb4:2.5 | F4:1 Ab4:.5 Db5:1.5 C5:.5 Ab4 | G4:3 r:1 | "
              "C4:1 Eb4:.5 G4:1.5 F4:.5 Eb4 | G4:1 Bb4:.5 C5:2.5 | Ab4:.5 G4 Eb4:1 C4:.5 Eb4 Ab4:1 | G4:1 D4 B3:2"),
        hook_b=("Ab4:2 C5:2 | G4:1.5 Eb4:.5 C4:2 | Eb4:1 Ab4 C5 Eb5 | D5:3 r:1 | "
                "Ab4:2 C5:2 | G4:1.5 C5:.5 Eb5:2 | F5:1 Db5 Ab4 F4 | G4:1 D4 B3:2"),
        lead={"a1": [("horn", 0, 0.8)], "a2": [("horn", 0, 0.82), ("trumpet", 0, 0.55)],
              "lift": [("horn", 0, 0.8)], "a3": [("horn", 0, 0.85), ("trumpet", 12, 0.7)]},
    ))


# ---------------------------------------------------------------------------------------------
# Eternal Rest Funeral Parlour, depth 3. Bb minor, 150 bpm: gothic and quick. A harpsichord runs
# under organ stabs, an organ plays the hook and a cello doubles it an octave down.
# ---------------------------------------------------------------------------------------------

def funeral_parlour():
    return build(dict(
        bpm=150, kit="standard",
        A="Bbm Gb Ab Bbm Bbm Gb Ab F7", B="Db Ab Ebm F7 Gb Ab Bbm F7",
        parts=[("harps", "harpsichord", 0.5, -0.4, 0.3, 0), ("organ", "rockorgan", 0.4, 0.4, 0.35, 0.3),
               ("bass", "fingerbass", 0.8, 0, 0.1, 0), ("lead", "percorgan", 0.56, 0.1, 0.35, 0.2),
               ("cello", "orch_cello", 0.66, -0.1, 0.4, 0), ("choir", "choir", 0.34, 0.3, 0.6, 0.3),
               ("strs", "orch_strings_short", 0.5, 0.3, 0.4, 0)],
        ost=[dict(inst="harps", order=[0, 2, 1, 2, 3, 2, 1, 2], low=58, vel=0.58, on=ALL)],
        comps=[dict(inst="organ", rhythm="x--...x-..x--...", low=53, vel=0.5, on=FULL),
               dict(inst="strs", rhythm=OFF, low=58, vel=0.5, on={"a2", "a3"}),
               dict(inst="choir", rhythm=PAD, low=53, vel=0.5, on={"lift", "a3"})],
        bass=dict(inst="bass", low=34, pats={"intro": HOLD, "a1": OCT8, "a2": OCT8, "lift": E8, "break": HOLD, "a3": OCT8}),
        drums={"intro": INTRO, "a1": ROCK, "a2": DRIVE, "lift": RIDE, "break": BREAK, "a3": [DRIVE, ROCK2]},
        hook=("Bb4:.5 Db5 F5:1 Eb5:.5 Db5 C5 Bb4 | Db5:1.5 Bb4:.5 Gb4:2 | C5:.5 Eb5 Ab5:1 Gb5:.5 F5 Eb5 C5 | Db5:1.5 F5:.5 Bb5:2 | "
              "Bb4:.5 Db5 F5:1 Eb5:.5 Db5 C5 Bb4 | Db5:.5 Gb5 Bb5:1 Ab5:1 Gb5 | Ab5:.5 Gb5 F5 Eb5 C5:1 Eb5 | F5:1 C5 A4:2"),
        hook_b=("F5:2 Ab5:1 F5 | Eb5:1.5 C5:.5 Ab4:2 | Gb5:1 Eb5 Bb4 Gb5 | F5:3 r:1 | "
                "Db5:1 Gb5:.5 Bb5:1.5 Ab5:1 | C6:1.5 Ab5:.5 Eb5:2 | Db5:.5 F5 Bb5:1 Ab5:.5 Gb5 F5 Db5 | F5:.5 Eb5 C5:1 A4:2"),
        lead={"a1": [("lead", 0, 0.78)], "a2": [("lead", 0, 0.8), ("cello", -12, 0.7)],
              "lift": [("cello", -12, 0.82), ("lead", 0, 0.5)], "a3": [("lead", 0, 0.85), ("cello", -12, 0.78)]},
    ))


# ---------------------------------------------------------------------------------------------
# The Flashback Cinema, depth 3. G minor, 152 bpm: a chase. A striding piano and string stabs, a
# walking bass, violin on the hook with a clarinet and, at the end, a xylophone.
# ---------------------------------------------------------------------------------------------

def flashback_cinema():
    chase = {"kick": "x...x...x...x...", "snare": "....x.......x...", "ride": "x.xox.xox.xox.xo"}
    return build(dict(
        bpm=152, kit="jazz", kit_level=0.85,
        A="Gm D7 Gm Cm Gm D7 Eb D7", B="Bb F Cm D7 Eb F Gm D7",
        parts=[("piano", "piano", 0.62, -0.35, 0.3, 0), ("strs", "orch_strings_short", 0.55, 0.4, 0.4, 0),
               ("bass", "upright", 0.85, 0, 0.1, 0), ("violin", "orch_violin", 0.72, 0.1, 0.4, 0),
               ("clar", "orch_clarinet", 0.56, -0.1, 0.35, 0), ("xylo", "orch_xylophone", 0.45, 0.3, 0.35, 0),
               ("pad", "slowstrings", 0.32, -0.3, 0.5, 0.4)],
        ost=[dict(inst="piano", order=[0, 3, 2, 3, 1, 3, 2, 3], low=43, vel=0.62, on=ALL)],
        comps=[dict(inst="strs", rhythm=OFF, low=60, vel=0.52, on=FULL),
               dict(inst="pad", rhythm=PAD, low=55, vel=0.5, on={"lift", "a3"})],
        bass=dict(inst="bass", low=31, pats={"intro": HOLD, "a1": WALK4, "a2": WALK4, "lift": E8, "break": HOLD, "a3": WALK4}),
        drums={"intro": INTRO, "a1": chase, "a2": chase, "lift": RIDE, "break": BREAK, "a3": DRIVE},
        hook=("G5:.5 Bb5 D6:1 C6:.5 Bb5 A5 G5 | F#5:.5 A5 C6:1 A5:1 F#5 | G5:.5 Bb5 D6:1 Bb5:.5 G5 D5:1 | Eb5:.5 G5 C6:1 Bb5:.5 A5 G5 Eb5 | "
              "G5:.5 Bb5 D6:1 C6:.5 Bb5 A5 G5 | F#5:.5 A5 D6:1 C6:1 A5 | Bb5:.5 G5 Eb5 G5 Bb5:1 G5 | A5:1 F#5 D5:2"),
        hook_b=("D6:2 Bb5:1 F5 | A5:1.5 F5:.5 C5:2 | Eb5:1 G5 C6 Eb6 | D6:1.5 C6:.5 A5:2 | "
                "G5:1 Bb5:.5 Eb6:1.5 D6:1 | C6:1.5 A5:.5 F5:2 | G5:.5 Bb5 D6:1 C6:.5 Bb5 A5 G5 | F#5:.5 A5 D6:1 D6:2"),
        lead={"a1": [("violin", 0, 0.78)], "a2": [("violin", 0, 0.8), ("clar", 0, 0.62)],
              "lift": [("violin", 0, 0.8), ("clar", -12, 0.55)], "a3": [("violin", 0, 0.85), ("clar", 0, 0.7), ("xylo", 0, 0.55)]},
    ))


# ---------------------------------------------------------------------------------------------
# The Last Resort Cruise, depth 4. A minor, 136 bpm: hot and busy. Congas, cowbell and shaker, a
# piano montuno and a bass tumbao, brass stabs, and a trumpet hook with an alto sax.
# ---------------------------------------------------------------------------------------------

def last_resort_cruise():
    return build(dict(
        bpm=136, kit="standard", fill="timbale", kit_level=0.75,
        A="Am7 D9 Am7 D9 Fmaj7 E7 Am7 E7", B="Dm7 G7 Cmaj7 Fmaj7 Dm7 E7 Am7 E7",
        parts=[("piano", "piano", 0.58, -0.35, 0.3, 0), ("brass", "brass", 0.5, 0.35, 0.35, 0),
               ("bass", "fingerbass", 0.8, 0, 0.1, 0), ("trumpet", "trumpet", 0.68, 0.1, 0.4, 0),
               ("sax", "altosax", 0.52, -0.1, 0.35, 0), ("vibes", "vibes", 0.45, 0.4, 0.4, 0),
               ("pad", "warmpad", 0.28, -0.3, 0.5, 0.4)],
        ost=[dict(inst="vibes", order=[0, 2, 3, 2], low=64, vel=0.5, on={"lift", "break"})],
        comps=[dict(inst="piano", rhythm=["x.x..x.x..x.x.x.", "..x.x..x.x..x.x."], low=57, vel=0.52, on=ALL),
               dict(inst="brass", rhythm=["x--.....x-......", "......x-....x--."], low=58, vel=0.55, on={"a2", "a3"}),
               dict(inst="pad", rhythm=PAD, low=55, vel=0.5, on={"lift"})],
        bass=dict(inst="bass", low=33, pats={"intro": HOLD, "a1": TUMBAO, "a2": TUMBAO, "lift": TUMBAO, "break": HOLD, "a3": TUMBAO}),
        drums={"intro": {"cowbell": "o...o...o...o...", "shaker": "gogogogogogogogo"}, "a1": LATIN, "a2": LATIN, "a3": LATIN,
               "lift": dict(LATIN, ride="x.o.x.o.x.o.x.o."),
               "break": {"conga": "..o.x...o.x.o.x.", "shaker": "gogogogogogogogo", "rim": "..o..o....o.o..."}},
        hook=("E5:.5 A5 C6:1 B5:.5 A5:1 G5:.5 | F#5:1 A5:.5 D5:1.5 F#5:1 | E5:.5 A5 C6:1 B5:.5 A5:1 C6:.5 | D6:1.5 C6:.5 A5:2 | "
              "C6:.5 A5 F5:1 A5:.5 C6:1 A5:.5 | B5:1 G#5:.5 E5:1.5 G#5:1 | A5:.5 C6 E6:1 D6:.5 C6 B5 A5 | B5:1 G#5 E5:2"),
        hook_b=("F5:1.5 A5:.5 D6:2 | B5:1.5 G5:.5 D5:2 | E5:1 G5 B5 E6 | C6:1.5 A5:.5 F5:2 | "
                "F5:1.5 A5:.5 D6:2 | B5:1 G#5 E5 G#5 | A5:.5 C6 E6:1 C6:.5 A5 E5:1 | G#5:.5 B5 E6:1 E6:2"),
        lead={"a1": [("trumpet", 0, 0.78)], "a2": [("trumpet", 0, 0.8), ("sax", 0, 0.62)],
              "lift": [("sax", 0, 0.8)], "a3": [("trumpet", 0, 0.85), ("sax", 0, 0.7)]},
    ))


# ---------------------------------------------------------------------------------------------
# Beyond Calling Psychic Hotline, depth 4. F# minor, 140 bpm: eerie but moving. A glittering
# sixteenth arpeggio over an octave synth bass, a voice-like lead with a glockenspiel on top.
# ---------------------------------------------------------------------------------------------

def seance_hotline():
    full = {"kick": "x.....x.x..x....", "snare": "....x.......x...", "hat": "x.xox.xox.xox.xo"}
    return build(dict(
        bpm=140, kit="electronic", room=0.6,
        A="F#m F#m D E F#m F#m D C#7", B="Bm F#m D C#7 Bm F#m E C#7",
        parts=[("arp", "epiano2", 0.5, -0.4, 0.4, 0.4), ("bass", "synthbass", 0.75, 0, 0.1, 0),
               ("pad", "halopad", 0.3, 0.35, 0.6, 0.4), ("lead", "voicelead", 0.56, 0.1, 0.5, 0.2),
               ("glock", "orch_glock", 0.4, -0.15, 0.5, 0), ("strs", "orch_strings_short", 0.5, 0.4, 0.4, 0),
               ("sq", "squarelead", 0.3, -0.1, 0.4, 0.2)],
        ost=[dict(inst="arp", order=[0, 2, 3, 2, 1, 2, 3, 4], step=0.25, low=54, vel=0.55, on=ALL)],
        comps=[dict(inst="pad", rhythm=PAD, low=54, vel=0.5, on=ALL - {"intro"}),
               dict(inst="strs", rhythm=OFF, low=57, vel=0.5, on={"a2", "a3"})],
        bass=dict(inst="bass", low=30, pats={"intro": HOLD, "a1": OCT8, "a2": OCT8, "lift": E8, "break": HOLD, "a3": OCT8}),
        drums={"intro": INTRO, "a1": full, "a2": full, "lift": FOUR, "break": BREAK, "a3": dict(full, clap="....x.......x...")},
        hook=("C#5:1 F#5:.5 A5:1.5 G#5:.5 F#5 | E5:.5 F#5 C#5:3 | D5:1 F#5:.5 A5:1.5 B5:.5 A5 | G#5:1.5 E5:.5 B4:2 | "
              "C#5:1 F#5:.5 A5:1.5 G#5:.5 F#5 | A5:.5 B5 C#6:3 | D6:.5 C#6 A5 F#5 D5:1 F#5 | G#5:1 F5 C#5:2"),
        hook_b=("D5:2 F#5:1 B5 | A5:1.5 F#5:.5 C#5:2 | D5:1 F#5 A5 D6 | C#6:3 r:1 | "
                "D6:1.5 B5:.5 F#5:2 | A5:1.5 C#6:.5 F#6:2 | E6:1 B5 G#5 E5 | F5:1 G#5 C#6:2"),
        lead={"a1": [("lead", 0, 0.8)], "a2": [("lead", 0, 0.82), ("glock", 12, 0.55)],
              "lift": [("lead", 0, 0.8), ("sq", 0, 0.55)], "a3": [("lead", 0, 0.85), ("glock", 12, 0.6), ("sq", 0, 0.55)]},
    ))


# ---------------------------------------------------------------------------------------------
# Departures, Terminal Zero, depth 5. C# minor, 150 bpm: electronic and fast. Four on the floor,
# a synth arpeggio and octave bass, a bright piano hook with a square lead behind it.
# ---------------------------------------------------------------------------------------------

def terminal_zero():
    return build(dict(
        bpm=150, kit="electronic", room=0.55,
        A="C#m A E B C#m A E G#7", B="A B C#m C#m A B G#m G#7",
        parts=[("arp", "polysynth", 0.42, -0.4, 0.35, 0.3), ("bass", "synthbass2", 0.75, 0, 0.1, 0),
               ("pad", "warmpad", 0.32, 0.35, 0.6, 0.4), ("piano", "brightpiano", 0.64, 0.1, 0.4, 0),
               ("sq", "squarelead", 0.32, -0.15, 0.4, 0.2), ("saw", "sawlead", 0.28, 0.3, 0.4, 0.3)],
        ost=[dict(inst="arp", order=[0, 2, 1, 2, 3, 2, 1, 2], step=0.25, low=56, vel=0.55, on=ALL)],
        comps=[dict(inst="pad", rhythm=PAD, low=56, vel=0.5, on=ALL - {"intro"}),
               dict(inst="saw", rhythm="x--.....x--.....", low=56, vel=0.5, on={"a2", "a3"})],
        bass=dict(inst="bass", low=25, pats={"intro": HOLD, "a1": OCT8, "a2": OCT8, "lift": OCT8, "break": HOLD, "a3": OCT8}),
        drums={"intro": INTRO, "a1": FOUR, "a2": FOUR, "a3": dict(FOUR, snare="....o.......o..o"),
               "lift": {"kick": "x.....x.x.....x.", "clap": "....x.......x...", "hat": "x.o.x.o.x.o.x.o."}, "break": BREAK},
        hook=("G#5:1.5 E5:.5 C#5:1 E5 | A5:1.5 E5:.5 C#5:1 E5 | B5:1.5 G#5:.5 E5:1 G#5 | F#5:1 D#5:.5 B4:2.5 | "
              "G#5:1.5 E5:.5 C#5:1 E5 | A5:1.5 C#6:.5 E6:2 | D#6:.5 E6 B5:1 G#5:.5 B5 E5:1 | D#5:1 F#5 G#5:2"),
        hook_b=("C#6:2 A5:1 E5 | D#6:2 B5:1 F#5 | E6:1.5 D#6:.5 C#6:2 | G#5:.5 C#6 E6:1 C#6:2 | "
                "C#6:2 A5:1 E5 | D#6:1.5 B5:.5 F#5:2 | B5:1 G#5 D#5 G#5 | C6:1 G#5 D#5:2"),
        lead={"a1": [("piano", 0, 0.8)], "a2": [("piano", 0, 0.82), ("sq", 0, 0.6)],
              "lift": [("piano", 0, 0.8), ("sq", 0, 0.55)], "a3": [("piano", 0, 0.88), ("sq", 0, 0.65)]},
    ))


# ---------------------------------------------------------------------------------------------
# Head Office, Eternity Incorporated, depth 5. F minor, 160 bpm: the biggest. Short strings race,
# a piano hammers low, timpani on the downbeats, horns on the hook with trumpets above, an oboe in
# the lift over a choir.
# ---------------------------------------------------------------------------------------------

def head_office():
    return build(dict(
        bpm=160, kit="power", extra=_timpani(list(range(12, 20)) + list(range(32, 40))),
        A="Fm Fm Db Eb Fm Fm Db C7", B="Ab Eb Bbm C7 Db Eb Fm C7",
        parts=[("strs", "orch_strings_short", 0.62, -0.6, 0.4, 0), ("piano", "piano", 0.5, 0.6, 0.3, 0),
               ("bass", "fingerbass", 0.8, 0, 0.1, 0), ("horn", "orch_horn", 0.72, 0.25, 0.45, 0),
               ("trumpet", "orch_trumpet", 0.56, -0.3, 0.4, 0), ("oboe", "orch_oboe", 0.56, 0.3, 0.4, 0),
               ("choir", "choir", 0.36, 0.3, 0.6, 0.3), ("timp", "orch_timpani", 0.6, 0, 0.4, 0)],
        ost=[dict(inst="strs", order=[0, 2, 1, 2, 3, 2, 1, 2], low=53, vel=0.64, on=ALL),
             dict(inst="piano", order=[0, 0, 2, 0, 0, 2, 0, 3], low=41, vel=0.6, on={"a2", "a3", "break"})],
        comps=[dict(inst="choir", rhythm=PAD, low=53, vel=0.52, on={"lift", "a3"})],
        bass=dict(inst="bass", low=29, pats={"intro": HOLD, "a1": GAL, "a2": GAL, "lift": E8, "break": HOLD, "a3": GAL}),
        drums={"intro": INTRO, "a1": ROCK, "a2": DRIVE, "lift": RIDE, "break": TOMS, "a3": [DRIVE, ROCK2]},
        hook=("F4:1 Ab4:.5 C5:1.5 Bb4:.5 Ab4 | G4:.5 Ab4 F4:3 | F4:1 Ab4:.5 Db5:1.5 C5:.5 Ab4 | Bb4:1.5 G4:.5 Eb4:2 | "
              "F4:1 Ab4:.5 C5:1.5 Bb4:.5 Ab4 | C5:.5 Db5 Eb5:1 F5:2 | F5:.5 Eb5 Db5 Ab4 F4:1 Ab4 | G4:1 E4 C4:2"),
        hook_b=("C5:2 Eb5:1 C5 | Bb4:1.5 G4:.5 Eb4:2 | Db5:1 F5 Bb5 Db5 | C5:3 r:1 | "
                "Ab4:1 Db5:.5 F5:1.5 Ab5:1 | G5:1.5 Eb5:.5 Bb4:2 | Ab4:.5 C5 F5:1 Eb5:.5 Db5 C5 Ab4 | G4:.5 Bb4 C5:1 E5:2"),
        lead={"a1": [("horn", 0, 0.82)], "a2": [("horn", 0, 0.84), ("trumpet", 12, 0.62)],
              "lift": [("oboe", 0, 0.8), ("horn", 0, 0.6)], "a3": [("horn", 0, 0.88), ("trumpet", 12, 0.75)]},
    ))
