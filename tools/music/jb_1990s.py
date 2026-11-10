"""Harold's Jukebox, depth 5: the 1990s, Harold in his fifties. Terminal Zero, Head Office, and the
depth-5 floor boss."""
from band import Band, beat, roll
from kit import melody, prog, comp, bassline, arp
from jb_theme import THEME_A, THEME_A1, THEME_B, THEME_A_CHORDS, MOTIF, minor

INFO = {
    "terminal_zero": dict(key="F major", bpm=128, meter=4, bars=32,
                          about="Terminal Zero: dreamy 90s trance, gated pads and a rolling bass, PA chimes, the whistle floating the hold theme."),
    "head_office": dict(key="C major / C minor", bpm=122, meter=4, bars=32,
                        about="Head Office: slick 90s corporate house, piano stabs and the hold theme as the piano hook, a brief minor turn."),
    "boss_depth_5": dict(key="E minor", bpm=152, meter=4, bars=36,
                         about="Depth 5 boss (Augustine): 90s big-beat fight, breakbeats and distorted bass, the hold theme upside down and in canon."),
}


def _bars(text, count):
    p = prog(text)
    assert len(p) == count, "progression has %d bars, not %d" % (len(p), count)
    return p


# ---------------------------------------------------------------------------------------------
# Departures, Terminal Zero: the airport to the afterlife. Dreamy 90s trance, F major, 128 bpm.
# A halo pad, a gated synth chord and a rolling sixteenth bass; the PA goes ding-dong; Harold
# whistles the motif as the hook, then the whole theme in the breakdown, and a saw lead carries it
# in the drop. 32 bars: boarding (4), groove with the whistled hook (8), breakdown (8), drop (8),
# taxiing out (4).
# ---------------------------------------------------------------------------------------------

TZ_CHORDS = " ".join(["Fmaj7 Dm7 Bbmaj7 C7sus4", "Fmaj7 Dm7 Bbmaj7 C7sus4 Fmaj7 Dm7 Bbmaj7 C7sus4",
                      THEME_A_CHORDS, THEME_A_CHORDS, "Bbmaj7 Bbmaj7 C7sus4 C7"])
TZ_HOOKS = [MOTIF, "E5:.5 C5 A4:1 r:2", MOTIF, "D5:.5 C5 G4:1 r:2"]
ROLLING = [(b + o, 0.2, 0) for b in range(4) for o in (0.25, 0.5, 0.75)]
TZ_GATE = "x.x.xx.x.x.xx.x."


def terminal_zero():
    s = Band(128, 32, loudness=-17.5, room=0.75)
    s.part("pad", "halopad", level=0.5, reverb=0.7)
    s.part("gate", "polysynth", level=0.42, pan=-0.15, reverb=0.5)
    s.part("arp", "squarelead", level=0.3, pan=0.2, reverb=0.55, chorus=0.3)
    s.part("sparkle", "crystal", level=0.36, pan=0.3, reverb=0.8)
    s.part("lead", "sawlead", level=0.42, reverb=0.5, chorus=0.4)
    s.part("whistle", "whistle", level=0.5, reverb=0.65)
    s.part("chime", "vibes", level=0.5, pan=-0.3, reverb=0.7)
    s.part("bass", "synthbass", level=0.62, reverb=0.1)
    s.kit("electronic", level=0.75)
    p = _bars(TZ_CHORDS, 32)
    for bar, parts in enumerate(p):
        intro, groove, brk, drop, out = bar < 4, 4 <= bar < 12, 12 <= bar < 20, 20 <= bar < 28, bar >= 28
        comp(s, "pad", bar, parts, "x---------------", low=53, vel=0.5, spread=0.0)
        if groove or drop or (out and bar < 30):
            bassline(s, "bass", bar, parts, ROLLING, low=33, vel=0.75)
            comp(s, "gate", bar, parts, TZ_GATE, low=60, vel=0.45, spread=0.0)
            arp(s, "arp", bar, parts, step=0.25, low=65, octaves=2, vel=0.35, pan=0.0, length=0.2)
            beat(s, bar, {"kick": "x...x...x...x...", "openhat": "..o...o...o...o.", "clap": "....o.......o...",
                          "hat": "g.g.g.g.g.g.g.g."}, vel=0.85)
        else:
            bassline(s, "bass", bar, parts, [(0, 3.8, 0)], low=33, vel=0.5 if brk else 0.6)
            beat(s, bar, {"hat": "g.g.g.g.g.g.g.g."} if intro or out or bar >= 16 else {}, vel=0.7)
            if bar >= 2 and intro:
                beat(s, bar, {"openhat": "..o...o...o...o."}, vel=0.6)
        if brk:
            arp(s, "sparkle", bar, parts, step=1.0, low=72, octaves=1, vel=0.4, pan=0.0, length=1.6)
        if groove:
            melody(s, "whistle", bar, TZ_HOOKS[(bar - 4) % 4], bars=1, vel=0.72, transpose=12)
        if drop and bar % 2 == 0:
            arp(s, "sparkle", bar, parts, step=2.0, low=77, octaves=1, vel=0.3, pan=0.0, length=2.0)
    roll(s, 11, start=3.0, count=4)
    roll(s, 19, start=0.0, count=16, low=0.15, high=0.8)
    s.hit("crash", 4 * 4, vel=0.55)
    s.hit("crash", 20 * 4, vel=0.65)
    # The breakdown: the pad drops back and swells into the drop; the whistle sings the theme.
    s.cc("pad", 12 * 4, 11, 80)
    s.swell("pad", 16 * 4, 16, 80, 127)
    melody(s, "whistle", 12, THEME_A, bars=8, vel=0.76, transpose=12)
    melody(s, "lead", 20, THEME_A, bars=8, vel=0.72)
    melody(s, "whistle", 20, THEME_A, bars=8, vel=0.55, transpose=12)
    # "Ding-dong": the PA before an announcement; three tones when the breakdown opens.
    for bar, notes in ((0, ("A5", "F5")), (12, ("C6", "A5", "F5")), (30, ("A5", "F5"))):
        for k, n in enumerate(notes):
            s.note("chime", n, bar * 4 + k * 1.0, 1.8, vel=0.62)
    return s


# ---------------------------------------------------------------------------------------------
# Head Office, Eternity Incorporated: slick 90s corporate house, C major, 122 bpm. Off-beat piano
# stabs, an octave-bouncing synth bass, claps and open hats; the hold theme is the piano hook, high
# and doubled in octaves. The phone rings, the whistle takes the middle over swelling strings, then
# the memo turns ominous (C minor, choir and tremolo strings) until a lift chime snaps everyone
# back on message. 32 bars: intro (4), A (8), B (8), minor turn (4), A again (8).
# ---------------------------------------------------------------------------------------------

HO_A = "Cmaj7 Am7 Dm7 G7 Cmaj7 Am7 Dm7 G7"
HO_CHORDS = " ".join(["Cmaj7 Am7 Dm7 G7", HO_A, "Fmaj7 Bb9 Em7 A7 Dm7 G7 Cmaj7 G7", "Cm7 Abmaj7 Dm7b5 G7b9", HO_A])
HO_BASS = [(0.5, 0.4, 0), (1.5, 0.4, 0), (2.5, 0.4, 0), (3.0, 0.25, 12), (3.5, 0.4, 0)]
HO_STABS = "..x...x..x..x..."


def head_office():
    s = Band(122, 32, loudness=-17.5, room=0.55)
    s.part("piano", "brightpiano", level=0.62, pan=0.1, reverb=0.35)
    s.part("stabs", "piano", level=0.48, pan=-0.15, reverb=0.3)
    s.part("bass", "synthbass2", level=0.62, reverb=0.08)
    s.part("strings", "strings", level=0.42, reverb=0.55)
    s.part("trem", "tremstrings", level=0.42, reverb=0.6)
    s.part("choir", "choir", level=0.45, reverb=0.65)
    s.part("whistle", "whistle", level=0.5, reverb=0.5)
    s.part("bells", "bells", level=0.45, pan=0.25, reverb=0.6)
    s.part("phone", "phone", level=0.3, pan=-0.4, reverb=0.4)
    s.kit("electronic", level=0.75)
    p = _bars(HO_CHORDS, 32)
    for bar, parts in enumerate(p):
        intro, a1, b, turn, a2 = bar < 4, 4 <= bar < 12, 12 <= bar < 20, 20 <= bar < 24, bar >= 24
        if turn:
            bassline(s, "bass", bar, parts, [(0, 1.8, 0), (2, 1.8, 0)], low=24, vel=0.7)
            comp(s, "choir", bar, parts, "x---------------", low=52, vel=0.55, spread=0.0)
            comp(s, "trem", bar, parts, "x---------------", low=48, vel=0.6, spread=0.0)
            beat(s, bar, {"kick": "x.......x.......", "hat": "..g...g...g...g."}, vel=0.8)
            continue
        bassline(s, "bass", bar, parts, HO_BASS, low=24, vel=0.75)
        comp(s, "stabs", bar, parts, HO_STABS, low=55, vel=0.55 if intro else 0.5, spread=0.0)
        grid = {"kick": "x...x...x...x...", "hat": "g.g.g.g.g.g.g.g."}
        if bar >= 2:
            grid.update({"clap": "....x.......x...", "openhat": "..o...o...o...o."})
        if not intro:
            grid["shaker"] = "gogogogogogogogo"
        beat(s, bar, grid, vel=0.82)
        if b:
            comp(s, "strings", bar, parts, "x---------------", low=55, vel=0.55, spread=0.0)
        if a2:
            comp(s, "strings", bar, parts, "x---------------", low=60, vel=0.4, spread=0.0)
    for bar in (12, 14, 16, 18):
        s.swell("strings", bar * 4, 8, 45, 120)
    s.cc("strings", 24 * 4, 11, 110)
    roll(s, 3, start=3.0, count=4, kind="clap")
    roll(s, 11, start=3.0, count=4)
    roll(s, 23, start=2.0, count=8, kind="tom_lo", low=0.4, high=0.9)
    roll(s, 31, start=3.0, count=4)
    for bar in (4, 12, 24):
        s.hit("crash", bar * 4, vel=0.55)
    # The phone on the desk, before anyone sits down.
    for t in (1 * 4, 1 * 4 + 1.0):
        s.note("phone", "C5", t, 0.75, vel=0.6)
    # The hook: high piano in octaves, the whistle in the middle, the memo in minor, the lift chime.
    melody(s, "piano", 4, THEME_A, bars=8, vel=0.78, transpose=7)
    melody(s, "piano", 4, THEME_A, bars=8, vel=0.5, transpose=-5)
    melody(s, "whistle", 12, THEME_B, bars=8, vel=0.74, transpose=7)
    melody(s, "piano", 20, minor(THEME_A1), bars=4, vel=0.62, transpose=-5)
    melody(s, "piano", 20, minor(THEME_A1), bars=4, vel=0.5, transpose=-17)
    for k, n in enumerate(("C6", "G5")):
        s.note("bells", n, 24 * 4 + k * 0.75, 1.5, vel=0.6)
    melody(s, "piano", 24, THEME_A, bars=8, vel=0.8, transpose=7)
    melody(s, "whistle", 24, THEME_A, bars=8, vel=0.55, transpose=7)
    return s


# ---------------------------------------------------------------------------------------------
# Depth 5 boss (Augustine): a 90s big-beat fight, E minor, 152 bpm. Breakbeats on the power kit,
# a distorted bass riff over a sub, orchestra hits. The hold theme is turned upside down (a
# diatonic mirror of its first four bars) on distorted guitar, then sung in canon by choir and
# strings, then set right again, in minor, on brass in a half-time stomp. 36 bars: hits (4),
# mirror (8), canon (8), half-time (8), mirror again (8).
# ---------------------------------------------------------------------------------------------

# The theme's first four bars mirrored around its fifth: every step up becomes a step down.
INV1 = "B4:.5 D5 B4 F#4:1.5 G4:.5 A4 | G4:.5 B4 D5:2 r:1 | A4:.5 C5 A4 E4:1.5 F#4:.5 G4 | F#4:.5 A4 G4:2 r:1"
INV2 = "B4:.5 D5 B4 F#4:1.5 G4:.5 A4 | G4:.5 B4 D5:2 r:1 | A4:.5 C5 A4 E4:1.5 F#4:.5 G4 | F#4:.5 A4 D#5:2 r:1"
B5_MIRROR = "Bm G Am D Bm G Am B7"
B5_CHORDS = " ".join(["Em Em C B7", B5_MIRROR, "Bm G Am D Bm G Am D",
                      "Em7 Cmaj7 F#m7b5 B7b9 Em7 Cmaj7 Am7 Bm7", B5_MIRROR])
B5_RIFF = [(0, 0.7, 0), (0.75, 0.2, 0), (1, 0.45, 12), (1.5, 0.45, 0), (2, 0.7, 0), (2.75, 0.2, 0), (3, 0.45, 10), (3.5, 0.45, 7)]
BREAK_A = {"kick": "x.....x...x.....", "snare": "....x..g.g..x..g", "hat": "x.x.x.x.x.x.x.x.", "openhat": "..............o."}
BREAK_B = {"kick": "x.x.......x..x..", "snare": "....x.......x..o", "ride": "x.x.x.x.x.x.x.x."}


def boss_depth_5():
    s = Band(152, 36, loudness=-16.5, room=0.55)
    s.part("lead", "distortion", level=0.55, pan=0.15, reverb=0.3)
    s.part("riff", "distortion", level=0.5, pan=-0.2, reverb=0.15)
    s.part("sub", "synthbass", level=0.6, reverb=0.05)
    s.part("hit", "orchhit", level=0.5, reverb=0.5)
    s.part("choir", "choir", level=0.55, reverb=0.6)
    s.part("strings", "orch_strings", level=0.5, reverb=0.55)
    s.part("brass", "brass", level=0.58, reverb=0.45)
    s.part("timp", "orch_timpani", level=0.6, reverb=0.5)
    s.kit("power", level=0.85)
    p = _bars(B5_CHORDS, 36)
    for bar, parts in enumerate(p):
        intro, a1, canon, half, a2 = bar < 4, 4 <= bar < 12, 12 <= bar < 20, 20 <= bar < 28, bar >= 28
        bassline(s, "sub", bar, parts, [(0, 1.9, 0), (2, 1.9, 0)], low=28, vel=0.8)
        if half:
            beat(s, bar, {"kick": "x.........x.....", "snare": "........x.......", "hat": "o...o...o...o..."}, vel=0.9)
            bassline(s, "riff", bar, parts, [(0, 1.9, 0), (2, 1.4, 0), (3.5, 0.45, 7)], low=40, vel=0.85)
            bassline(s, "timp", bar, parts, [(0, 1.0, 0), (2, 1.0, 7)], low=40, vel=0.75)
            comp(s, "choir", bar, parts, "x---------------", low=52, vel=0.6, spread=0.0)
            comp(s, "strings", bar, parts, "x---------------", low=55, vel=0.5, spread=0.0)
            comp(s, "hit", bar, parts, "x...............", low=55, vel=0.7, spread=0.0)
            if bar % 2 == 0:
                s.hit("crash", bar * 4, vel=0.6)
            continue
        if bar >= 2:
            beat(s, bar, BREAK_B if canon else BREAK_A, vel=0.9)
        bassline(s, "riff", bar, parts, B5_RIFF, low=40, vel=0.85)
        if intro or a2 or bar % 2 == 0:
            comp(s, "hit", bar, parts, "x.....x.........", low=55, vel=0.75, spread=0.0)
        if canon:
            comp(s, "lead", bar, parts, "x-.x-.x-x-.x-.x-", low=52, vel=0.55, spread=0.0)
        if a2:
            comp(s, "brass", bar, parts, "x.....x...x.....", low=55, vel=0.6, spread=0.0)
        if bar in (11, 19, 35):
            roll(s, bar, start=2.0, count=8, low=0.4, high=0.95)
    roll(s, 3, start=0.0, count=16, kind="tom_floor", low=0.3, high=0.9)
    for bar in (4, 12, 28):
        s.hit("crash", bar * 4, vel=0.7)
    # Upside down, then in canon (the strings a bar behind, an octave up), then right way up in minor.
    melody(s, "lead", 4, INV1 + " | " + INV2, bars=8, vel=0.82)
    melody(s, "choir", 12, INV1 + " | " + INV1, bars=8, vel=0.75)
    melody(s, "strings", 13, INV1 + " | " + " | ".join(INV1.split(" | ")[:3]), bars=7, vel=0.7, transpose=12)
    melody(s, "brass", 20, minor(THEME_A), bars=8, vel=0.82, transpose=-1)
    melody(s, "lead", 28, INV1 + " | " + INV2, bars=8, vel=0.85)
    melody(s, "choir", 28, INV1 + " | " + INV2, bars=8, vel=0.6, transpose=12)
    return s
