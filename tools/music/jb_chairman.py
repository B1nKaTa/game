"""Harold's Jukebox, the final boss: the Chairman, and the jukebox breaking."""
import synth
from band import Band, beat, roll
from kit import mel, melody, prog, comp, bassline, arp
from jb_theme import THEME_A, THEME_A1, THEME_A2, minor, walking

INFO = {
    "the_chairman": dict(key="F major, F minor, Ab major", bpm=166, meter=4, bars=48,
                         quiet=[(7, 8), (15, 16), (23, 24), (31, 32), (37, 38), (46, 48)],
                         about="Final boss: the hold theme skipping through every decade of the jukebox, then an orchestral, choir and organ finale in F minor that collapses and restarts."),
}


def _bars(text, count):
    p = prog(text)
    assert len(p) == count, "progression has %d bars, not %d" % (len(p), count)
    return p


def _first(text, n):
    """The first n bars of melody text."""
    return " | ".join(text.split(" | ")[:n])


def _power(parts):
    """The same bar with every chord as a bare power chord (root, fifth, octave)."""
    out = []
    for off, beats, sym in parts:
        root = sym[:2] if len(sym) > 1 and sym[1] in "#b" else sym[:1]
        out.append((off, beats, root + "5"))
    return out


def _tremolo(s, part, bar, text, transpose=0, vel=0.75, step=0.25):
    """Surf picking: every note of the melody re-struck each `step` beats."""
    notes, count = mel(text, s.meter)
    t = bar * s.meter
    for name, beats in notes:
        if name != "r":
            m = synth.midi(name) + transpose
            k = 0.0
            while k < beats - 1e-6:
                s.note(part, m, t + k, step * 0.9, vel=vel * (1.0 if k == 0 else 0.78))
                k += step
        t += beats
    return bar + count


def _skip(s, bar, voices):
    """The record skips: the same half beat five times, a dead stop, then the needle drops back.
    voices: (part, midi note) pairs struck together on each repeat."""
    t0 = bar * s.meter
    for k in range(5):
        t = t0 + k * 0.5
        for part, m in voices:
            s.note(part, m, t, 0.4, vel=0.85 - 0.07 * k)
        s.hit("snare", t, vel=0.7 - 0.06 * k)
        s.hit("kick", t, vel=0.6)
    s.hit("click", t0 + 3.25, vel=0.75)
    s.hit("sticks", t0 + 3.5, vel=0.6)
    s.hit("click", t0 + 3.75, vel=0.5)


# ---------------------------------------------------------------------------------------------
# The Chairman: the final boss, and the jukebox breaking. 166 bpm throughout. The hold theme is
# played by every decade in turn, and every change is a record skip: one half beat stuck five
# times, a dead stop, the needle dropping. 50s rock'n'roll in F (sax, boogie piano, walking bass),
# 60s surf in F minor (tremolo-picked guitar, floor toms), 70s prog in F minor (organ arpeggios
# and a saw lead in 3+3+2), 80s synth in Ab (saw lead, synth brass, gated snare), 90s breakbeat
# in F minor (distorted riff, orchestra hits, a riser), then the finale in F minor: horns sing the
# whole minor theme over choir, organ, driving short strings, power chords and timpani. It
# collapses: a falling chromatic line, the drums slowing apart, the needle, and round again.
# 48 bars: 50s (8), 60s (8), 70s (8), 80s (8), 90s (6), finale (8), collapse (2).
# ---------------------------------------------------------------------------------------------

CH_CHORDS = " ".join(["F6 Dm7 Gm7 C7 F6 Dm7 Gm7 C7",
                      "Fm Db Bbm6 Db Fm Db Bbm7 C7",
                      "Fm Db Bbm7 Cm7 Fm Db Bbm6 C7",
                      "Ab Fm Bbm7 Eb Ab Fm Bbm7 C7",
                      "Fm Db Bbm6 C7b9 C7 C7",
                      "Fm Dbmaj7 Gm7b5 C7b9 Fm Db Bbm7 C7",
                      "Fm Fm"])
ROOT_FIFTH = [(0, 0.45, 0), (0.5, 0.45, 0), (1, 0.45, 7), (1.5, 0.45, 7), (2, 0.45, 0), (2.5, 0.45, 0), (3, 0.45, 7), (3.5, 0.45, 12)]
THREE_THREE_TWO = [(0, 0.7, 0), (0.75, 0.7, 0), (1.5, 0.45, 12), (2, 0.7, 0), (2.75, 0.7, 7), (3.5, 0.45, 10)]
EIGHTHS = [(k * 0.5, 0.45, 0) for k in range(8)]
BREAK_RIFF = [(0, 0.7, 0), (0.75, 0.2, 0), (1, 0.45, 12), (1.5, 0.45, 0), (2, 0.7, 0), (2.75, 0.2, 3), (3, 0.45, 10), (3.5, 0.45, 7)]
DRUMS = {
    "50s": {"kick": "x.......x.......", "snare": "....x.......x...", "ride": "x.x.x.x.x.x.x.x."},
    "60s": {"kick": "x.......x.......", "snare": "....x.......x...", "tom_floor": "o.o.o.o.o.o.o.o."},
    "70s": {"kick": "x..x..x.x..x..x.", "snare": "......x.......x.", "hat": "x.x.x.x.x.x.x.x."},
    "80s": {"kick": "x.......x.......", "snare": "....x.......x...", "hat": "x.x.x.x.x.x.x.x.", "tom": "..............o."},
    "90s": {"kick": "x.....x...x.....", "snare": "....x..g.g..x..g", "hat": "xgxgxgxgxgxgxgxg"},
    "fin": {"kick": "x...x...x...x...", "snare": "....x.......x...", "hat": "x.x.x.x.x.x.x.x."},
}
SKIPS = {7: "50s", 15: "60s", 23: "70s", 31: "80s", 37: "90s"}


def the_chairman():
    s = Band(166, 48, loudness=-16.5, room=0.55)
    s.part("sax", "tenorsax", level=0.62, pan=0.15, reverb=0.3)
    s.part("piano", "honkytonk", level=0.5, pan=-0.25, reverb=0.25)
    s.part("bass", "pickbass", level=0.66, reverb=0.08)
    s.part("surf", "cleangtr", level=0.6, pan=-0.15, reverb=0.7)
    s.part("organ", "rockorgan", level=0.5, pan=0.2, reverb=0.35)
    s.part("synth", "sawlead", level=0.48, pan=0.05, reverb=0.4, chorus=0.3)
    s.part("sbrass", "synthbrass", level=0.48, pan=-0.1, reverb=0.4)
    s.part("sbass", "synthbass", level=0.6, reverb=0.05)
    s.part("dist", "distortion", level=0.5, pan=-0.2, reverb=0.2)
    s.part("hit", "orchhit", level=0.5, reverb=0.5)
    s.part("choir", "choir", level=0.55, reverb=0.6)
    s.part("horn", "orch_horn", level=0.65, pan=0.1, reverb=0.5)
    s.part("strings", "orch_strings_short", level=0.55, pan=0.05, reverb=0.5)
    s.part("timp", "orch_timpani_roll", level=0.6, reverb=0.5)
    s.kit("power", level=0.85)
    p = _bars(CH_CHORDS, 48)
    for bar, parts in enumerate(p):
        if bar in SKIPS:
            continue
        if bar < 8:
            walking(s, "bass", bar, parts, low=36, vel=0.75)
            comp(s, "piano", bar, parts, "x.x.x.x.x.x.x.x.", low=55, vel=0.42, spread=0.0)
            beat(s, bar, DRUMS["50s"], vel=0.85)
        elif bar < 16:
            bassline(s, "bass", bar, parts, ROOT_FIFTH, low=36, vel=0.75)
            comp(s, "organ", bar, parts, "x-------x-------", low=55, vel=0.32, spread=0.0)
            beat(s, bar, DRUMS["60s"], vel=0.85)
        elif bar < 24:
            bassline(s, "bass", bar, parts, THREE_THREE_TWO, low=36, vel=0.8)
            arp(s, "organ", bar, parts, step=0.25, low=53, octaves=2, vel=0.45, pan=0.0)
            beat(s, bar, DRUMS["70s"], vel=0.85)
        elif bar < 32:
            bassline(s, "sbass", bar, parts, EIGHTHS, low=32, vel=0.8)
            comp(s, "sbrass", bar, parts, "x.....x...x.....", low=56, vel=0.6, spread=0.0)
            beat(s, bar, DRUMS["80s"], vel=0.88)
        elif bar < 38:
            bassline(s, "dist", bar, parts, BREAK_RIFF, low=40, vel=0.85)
            bassline(s, "sbass", bar, parts, [(0, 1.9, 0), (2, 1.9, 0)], low=29, vel=0.8)
            if bar < 36:
                comp(s, "hit", bar, parts, "x.....x.........", low=55, vel=0.72, spread=0.0)
                beat(s, bar, DRUMS["90s"], vel=0.9)
            else:
                # The riser: the snare tightening, hits climbing, the horns waking up.
                roll(s, bar, start=0.0, count=16, low=0.3, high=0.95)
                for k in range(4):
                    s.note("hit", 60 + 3 * k, bar * 4 + k, 0.5, vel=0.5 + 0.12 * k)
                s.note("timp", 41, bar * 4, 3.9, vel=0.8)
        elif bar < 46:
            bassline(s, "bass", bar, parts, EIGHTHS, low=29, vel=0.85)
            bassline(s, "sbass", bar, parts, [(0, 3.8, 0)], low=29, vel=0.7)
            comp(s, "choir", bar, parts, "x-------x-------", low=53, vel=0.68, spread=0.0)
            comp(s, "organ", bar, parts, "x---x---x---x---", low=48, vel=0.5, spread=0.0)
            comp(s, "strings", bar, parts, "x.x.x.x.x.x.x.x.", low=55, vel=0.62, spread=0.0)
            comp(s, "dist", bar, _power(parts), "x.x.x.x.x.x.x.x.", low=41, vel=0.65, spread=0.0)
            comp(s, "hit", bar, parts, "x...............", low=55, vel=0.7, spread=0.0)
            beat(s, bar, DRUMS["fin"], vel=0.92)
            s.hit("crash", bar * 4, vel=0.6 if bar % 2 else 0.75)
            if bar >= 44:
                s.note("timp", 41, bar * 4, 3.9, vel=0.7 + 0.1 * (bar - 44))
    for bar in (8, 16, 24, 32):
        s.hit("crash", bar * 4, vel=0.6)
    s.hit("crash", 38 * 4, vel=0.85)
    # The theme, decade by decade. Each skip sticks on the last note the decade played.
    melody(s, "sax", 0, THEME_A1 + " | " + _first(THEME_A2, 3), bars=7, vel=0.82)
    _skip(s, 7, [("sax", 72), ("bass", 36), ("piano", 64)])
    _tremolo(s, "surf", 8, minor(THEME_A1) + " | " + _first(minor(THEME_A2), 3), transpose=-12, vel=0.8)
    _skip(s, 15, [("surf", 60), ("bass", 36), ("organ", 67)])
    melody(s, "synth", 16, minor(THEME_A2) + " | " + _first(minor(THEME_A1), 3), bars=7, vel=0.8)
    melody(s, "organ", 16, minor(THEME_A2) + " | " + _first(minor(THEME_A1), 3), bars=7, vel=0.5, transpose=-12)
    _skip(s, 23, [("synth", 75), ("bass", 36), ("organ", 63)])
    melody(s, "synth", 24, THEME_A1 + " | " + _first(THEME_A2, 3), bars=7, vel=0.82, transpose=3)
    _skip(s, 31, [("synth", 75), ("sbass", 36), ("sbrass", 64)])
    melody(s, "synth", 32, minor(THEME_A1), bars=4, vel=0.82)
    _skip(s, 37, [("dist", 48), ("sbass", 36), ("hit", 60)])
    # The finale: the whole theme in F minor, horns over the choir, short strings above them.
    melody(s, "horn", 38, minor(THEME_A), bars=8, vel=0.88)
    melody(s, "synth", 38, minor(THEME_A), bars=8, vel=0.55, transpose=12)
    s.cc("choir", 38 * 4, 11, 127)
    # The collapse: a falling chromatic line, the drums slowing apart, silence, the needle.
    t0 = 46 * 4
    for part, shift in (("organ", 0), ("horn", -12), ("choir", -12)):
        s.line(part, t0, [("F5", 0.25), ("E5", 0.25), ("Eb5", 0.5), ("D5", 0.5), ("Db5", 0.75), ("C5", 0.75),
                          ("B4", 1.0), ("Bb4", 1.5), ("r", 2.5)], vel=0.7, transpose=shift, bars=2)
    s.swell("choir", t0, 6, 127, 30)
    s.note("sbass", 29, t0, 5.0, vel=0.75)
    s.note("timp", 41, t0, 2.0, vel=0.6)
    for k, t in enumerate((0.0, 0.5, 1.25, 2.25, 3.5, 5.0)):
        s.hit("snare", t0 + t, vel=0.8 - 0.1 * k)
    s.hit("kick", t0, vel=0.8)
    s.hit("click", t0 + 7.0, vel=0.7)
    s.hit("sticks", t0 + 7.5, vel=0.6)
    return s
