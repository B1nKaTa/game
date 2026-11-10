"""Harold's Jukebox, depth 1: the 1950s, when Harold was a boy with a skiffle board and a quiff.

The Records Basement swings along as skiffle and rock'n'roll; its floor boss is the same decade
with the brakes off. Both are built on the hold theme (jb_theme).
"""
from synth import bass_note
from band import Band, beat, roll
from kit import melody, prog, comp, bassline
from jb_theme import THEME_A, MOTIF, minor

INFO = {
    "records_basement": dict(key="G major", bpm=160, meter=4, bars=32,
                             about="Records Basement: 1950s skiffle, washboard and slap bass, twangy guitar, honking sax, typewriter clatter, the whistle on the hold theme."),
    "boss_depth_1": dict(key="E minor", bpm=184, meter=4, bars=32,
                         about="Depth 1 boss: frantic rockabilly, pounding piano and slap bass gallop, the hold theme in minor as a honking sax riff."),
}


def _bars(text, count):
    p = prog(text)
    assert len(p) == count, "progression has %d bars, not %d" % (len(p), count)
    return p


def _is_minor(sym):
    q = sym.lstrip("ABCDEFG#b")
    return q.startswith("m") and not q.startswith("maj")


def boogie(s, inst, bar, parts, low=33, vel=0.75):
    """A walking boogie bass on the beats: root, third, fifth, sixth (or seventh), counted from the
    start of each chord, so a chord that arrives mid-bar starts again on its root."""
    for b in range(s.meter):
        off, _, sym = next(p for p in parts if p[0] - 1e-6 <= b < p[0] + p[1] - 1e-6)
        if _is_minor(sym):
            steps = [0, 3, 7, 10]
        else:
            steps = [0, 4, 7, 10 if sym.endswith("7") and "maj" not in sym else 9]
        m = bass_note(sym, low) + steps[int(b - off) % 4]
        s.note(inst, m, bar * s.meter + b, 0.85, vel=vel * (1.0 if b == off else 0.85))


# ---------------------------------------------------------------------------------------------
# The Records Basement: depth 1, the filing basement, 1955. Skiffle and rock'n'roll in G, 160 bpm
# with a shuffle: a washboard (cabasa and guiro), slap upright bass, a twangy clean guitar strumming
# and a honky-tonk piano. The typewriters clatter in the intro and ding at the end of a line.
# 32 bars: typewriters (2), A on tenor sax (8), B whistle on the hold theme (8), C twang guitar
# lead (8), A again on sax with the whistle's motif to turn round (6).
# ---------------------------------------------------------------------------------------------

BASEMENT_CHORDS = " ".join(["G6 G6",
                            "G6 G6 C6 G6 D7 C6 G6 D7",
                            "G6 Em7 Am7 D7 G6 Em7 Am7 D7",
                            "C6 C7 G6 G6 A7 A7 D7 D7",
                            "G6 C6 G6 D7 C6,D7 G6,D7"])
BASEMENT_SAX = ("D4:.5 E4 G4 A4 B4:1 A4:.5 G4 | B4:1.5 A4:.5 G4:1 r:1 | E4:.5 G4 A4 C5 E5:1 D5:.5 C5 | "
                "D5:1.5 B4:.5 G4:1 r:.5 D4 | F#4:.5 A4 C5 D5 F#5:1 E5:.5 D5 | E5:1 C5:.5 A4 G4:1 E4 | "
                "G4:.5 B4 D5 E5 D5:1 B4 | A4:1 F#4:.5 A4 D5:2")
BASEMENT_SAX_BACK = ("D4:.5 E4 G4 A4 B4:1 A4:.5 G4 | B4:1.5 A4:.5 G4:1 r:1 | E4:.5 G4 A4 C5 E5:1 D5:.5 C5 | "
                     "D5:1.5 B4:.5 G4:1 r:.5 D4 | E5:1 C5 D5 F#4 | G4:2 r:2")
BASEMENT_TWANG = ("G4:.5 A4 C5 E5 G5:1 E5 | Bb4:.5 C5 E5 G5 Bb5:1 G5 | B4:.5 D5 G5:1.5 E5:.5 D5:1 | "
                  "B4:2 r:1 D5:.5 E5 | C#5:.5 E5 G5 A5 G5:1 E5 | C#5:1.5 A4:.5 E4:1 r:1 | "
                  "F#4:.5 A4 C5 D5 F#5 A5 C6:1 | A5:.5 F#5 D5 C5 A4:2")
# Typewriters: a clatter of keys, then the carriage bell.
CLATTER = "x.xox.x.oxx.x.o."


def records_basement():
    s = Band(160, 32, swing=0.14, loudness=-17.5, room=0.4)
    s.part("bass", "upright", level=0.8, reverb=0.1)
    s.part("gtr", "cleangtr", level=0.5, pan=-0.35, reverb=0.25)
    s.part("twang", "cleangtr", level=0.62, pan=0.2, reverb=0.4)
    s.part("piano", "honkytonk", level=0.45, pan=0.35, reverb=0.25)
    s.part("sax", "tenorsax", level=0.66, pan=0.1, reverb=0.3)
    s.part("whistle", "whistle", level=0.55, reverb=0.45)
    s.kit("standard", level=0.72)
    p = _bars(BASEMENT_CHORDS, 32)
    for bar, parts in enumerate(p):
        intro, a1, b, c, a2 = bar < 2, 2 <= bar < 10, 10 <= bar < 18, 18 <= bar < 26, bar >= 26
        # The washboard and the slap of the bass never stop.
        beat(s, bar, {"cabasa": "o.g.o.g.o.g.o.g.", "rim": "..g...g...g...g."}, vel=0.8)
        if intro:
            beat(s, bar, {"click": CLATTER, "sticks": "....o.......o..."}, vel=0.75)
            if bar == 1:
                s.hit("triangle", bar * 4 + 3.5, vel=0.7)
            boogie(s, "bass", bar, parts, vel=0.65)
            continue
        boogie(s, "bass", bar, parts)
        beat(s, bar, {"kick": "x.......x.......", "snare": "....x.......x...", "guiro": "o.......o......."}, vel=0.8)
        comp(s, "gtr", bar, parts, "x.o.x.o.x.o.x.o.", low=55, vel=0.42, spread=0.0)
        if b:
            comp(s, "piano", bar, parts, "x...o...x...o...", low=60, vel=0.34, spread=0.0)
        if c:
            beat(s, bar, {"hat": "x.o.x.o.x.o.x.o."}, vel=0.6)
            comp(s, "piano", bar, parts, "..x...x...x...x.", low=60, vel=0.42, spread=0.0)
        if bar in (9, 17, 25):
            roll(s, bar, start=3.0, count=4)
        if bar == 17:
            beat(s, bar, {"click": "........x.xox.x."}, vel=0.6)
            s.hit("triangle", bar * 4 + 3.75, vel=0.6)
    for bar in (2, 18, 26):
        s.hit("crash", bar * 4, vel=0.6)
    melody(s, "sax", 2, BASEMENT_SAX, bars=8, vel=0.82)
    # The hold theme moved to G, whistled up high, with the sax holding soft notes under it.
    melody(s, "whistle", 10, THEME_A, bars=8, vel=0.75, transpose=14)
    for bar, n in ((10, "G3"), (12, "A3"), (14, "G3"), (16, "A3")):
        s.note("sax", n, bar * 4, 7.5, vel=0.4)
    melody(s, "twang", 18, BASEMENT_TWANG, bars=8, vel=0.8)
    melody(s, "sax", 26, BASEMENT_SAX_BACK, bars=6, vel=0.85)
    # The whistle turns the record round: the theme's motif, in G.
    melody(s, "whistle", 31, MOTIF, bars=1, vel=0.72, transpose=14)
    return s


# ---------------------------------------------------------------------------------------------
# Depth 1 boss: rockabilly with the brakes off. E minor, 184 bpm, straight. The hold theme in minor
# is the riff: the tenor sax honks it, the piano pounds eighth-note chords over a boogie left hand,
# the slap bass gallops. 32 bars: drums, gallop and the riff low (4), A theme on sax (8), B a sax
# break over the subdominant (8), A on sax and twang guitar in unison with a crash on every bar (8),
# stop-time hits and the riff to go round (4).
# ---------------------------------------------------------------------------------------------

BOSS1_A_CHORDS = "Em G F#m7b5 B7 Em Cmaj7 Am7 B7"
BOSS1_CHORDS = " ".join(["Em Em Em B7", BOSS1_A_CHORDS, "Am7 Am7 Em Em C7 B7 Em B7", BOSS1_A_CHORDS, "Em C7 Em,B7 B7"])
BOSS1_RIFF = "B3:.5 G3 B3 E4:1.5 D4:.5 C4 | B3:.5 D#4 F#4 A4 B4:2"
BOSS1_B = ("A4:.5 C5 E5 G5 A5:1 G5:.5 E5 | G5:.5 E5 C5 A4 C5:1 r:1 | B4:.5 E5 G5 B5 E6:1 D6:.5 B5 | "
           "G5:1.5 E5:.5 B4:2 | E5:.5 G5 Bb5 C6 Bb5:1 G5 | F#5:.5 A5 D#5 F#5 B4:2 | "
           "E5:.5 G5 B5 G5 E5 D5 B4 G4 | F#4:.5 A4 B4 D#5 F#5:1 A5")
BOSS1_TAG = "B4:.5 G4 B4 E5:1.5 D5:.5 C5 | C5:.5 E5 G5 Bb5:2.5 | B4:.5 G4 B4 E5 D#5:1 F#5 | B5:1 A5 F#5 D#5"
GALLOP = [(e * 0.5, 0.42, (0, 12, 7, 12)[e % 4]) for e in range(8)]
LEFT_HAND = [(e * 0.5, 0.45, 12 if e % 2 else 0) for e in range(8)]


def boss_depth_1():
    s = Band(184, 32, loudness=-16.0, room=0.35)
    s.part("bass", "upright", level=0.85, reverb=0.08)
    s.part("piano", "brightpiano", level=0.58, pan=0.5, reverb=0.2)
    s.part("left", "brightpiano", level=0.5, pan=-0.45, reverb=0.15)
    s.part("sax", "tenorsax", level=0.72, pan=0.05, reverb=0.25)
    s.part("bari", "barisax", level=0.5, pan=-0.4, reverb=0.2)
    s.part("twang", "cleangtr", level=0.6, pan=-0.55, reverb=0.3)
    s.part("stab", "jazzgtr", level=0.45, pan=0.6, reverb=0.2)
    s.kit("standard", level=0.85)
    p = _bars(BOSS1_CHORDS, 32)
    theme = minor(THEME_A)
    for bar, parts in enumerate(p):
        intro, a1, b, a2, tag = bar < 4, 4 <= bar < 12, 12 <= bar < 20, 20 <= bar < 28, bar >= 28
        if tag:
            # Stop-time: the band hits the downbeat and the and-of-two, then holds its breath.
            comp(s, "piano", bar, parts, "x.....x.........", low=55, vel=0.85, spread=0.0)
            bassline(s, "bass", bar, parts, [(0, 0.45, 0), (1.5, 0.45, 0)], low=28, vel=0.9)
            bassline(s, "left", bar, parts, [(0, 0.45, 0), (1.5, 0.45, 0)], low=40, vel=0.85)
            beat(s, bar, {"kick": "x.....x.........", "crash": "x...............", "snare": "......x........."})
            if bar >= 30:
                roll(s, bar, start=0.0 if bar == 31 else 2.0, count=16 if bar == 31 else 8, kind="snare", step=0.25)
            continue
        bassline(s, "bass", bar, parts, GALLOP, low=28, vel=0.85)
        bassline(s, "left", bar, parts, LEFT_HAND, low=40, vel=0.7)
        if intro:
            beat(s, bar, {"kick": "x...x...x...x...", "tom_lo": "....x.......x.x.", "hat": "x.x.x.x.x.x.x.x."})
            continue
        comp(s, "piano", bar, parts, "xoxoxoxoxoxoxoxo", low=58, vel=0.55, spread=0.0)
        beat(s, bar, {"kick": "x.....x.x.......", "snare": "....x.......x...", "hat": "x.x.x.x.x.x.x.x."})
        if a1 or a2:
            comp(s, "stab", bar, parts, "x-..x-..x-..x-..", low=59, vel=0.5, spread=0.0)
        if b:
            beat(s, bar, {"ride": "x.o.x.o.x.o.x.o.", "tom": "..............xo"}, vel=0.8)
        if a2:
            s.hit("crash", bar * 4, vel=0.65)
        if bar in (11, 19, 27):
            roll(s, bar, start=2.0, count=8)
    melody(s, "sax", 2, BOSS1_RIFF, bars=2, vel=0.85)
    melody(s, "bari", 2, BOSS1_RIFF, bars=2, vel=0.8, transpose=-12)
    # The hold theme in minor, moved down to E.
    melody(s, "sax", 4, theme, bars=8, vel=0.88, transpose=-1)
    melody(s, "bari", 4, theme, bars=8, vel=0.7, transpose=-13)
    melody(s, "sax", 12, BOSS1_B, bars=8, vel=0.9)
    melody(s, "sax", 20, theme, bars=8, vel=0.92, transpose=-1)
    melody(s, "twang", 20, theme, bars=8, vel=0.85, transpose=-1)
    melody(s, "bari", 20, theme, bars=8, vel=0.75, transpose=-13)
    melody(s, "sax", 28, BOSS1_TAG, bars=4, vel=0.92)
    s.hit("crash", 4 * 4, vel=0.7)
    s.hit("crash", 12 * 4, vel=0.6)
    return s
