"""Fight songs: the shared mini-boss theme, a floor boss theme per depth, and the Chairman.

Every floor boss quotes the hold theme in its own way: depth 1 plays it straight in minor as an 8-bit
hook, depth 2 stretches it into long brass notes over a machine riff, depth 3 (Final Arrangements, in
songs.py) gives it to the organ, depth 4 throws it into a triplet tarantella, depth 5 turns it upside
down and sings it in canon, and the Chairman's music starts as the hold music itself and breaks it.
"""
from synth import Song, chord, bass_note
from kit import mel, melody, prog, at, comp, bassline, arp, drums, fill
from songs import HOLD_A1
from places import BOSSA, BOSSA_BASS, _bars

GALLOP = [(e * 0.5, 0.42, 12 if e in (2, 5) else (7 if e == 7 else 0)) for e in range(8)]
OCTAVES = [(e * 0.5, 0.42, 12 if e % 2 else 0) for e in range(8)]
ROCK = {"kick": "x.....x.x.......", "snare": "....x.......x...", "hat": "x.x.x.x.x.x.x.x."}


# ---------------------------------------------------------------------------------------------
# Mini boss: tense but lighter than a floor boss, E minor, 152 bpm. A chip lead and a galloping saw
# bass; the break slips in the hold theme's opening, in minor, on a soft synth. 32 bars: intro (2),
# A (8), B (8), A (8), break (4), tag (2).
# ---------------------------------------------------------------------------------------------

MINI_A = ("E5:.5 G5 B5 E6 D6 B5 G5:1 | E5:.5 G5 C6 E6 D6:1 C6 | D6:.5 C6 A5 F#5 D5:1 F#5 | D#5:.5 F#5 A5 B5 D#6:2 | "
          "E6:.5 D6 B5 G5 E5:1 G5:.5 B5 | C6:.5 B5 G5 E5 C5:1 E5 | A5:.5 G5 E5 C5 B4 C#5 D#5 F#5 | E5:2 r:1 B4")
MINI_B = ("E5:1 G5:.5 C6:1.5 B5:.5 A5 | F#5:1 A5:.5 D6:1.5 C6:.5 A5 | B5:1 F#5:.5 D5:1.5 F#5:.5 B5 | G5:3 r:1 | "
          "A5:1 C6:.5 E6:1.5 D6:.5 C6 | D6:1 C6:.5 A5:1.5 F#5:.5 D5 | G5:.5 F#5 G5 A5 B5:1 D6 | D#6:.5 C6 B5 A5 F#5:1 D#5")
MINI_BREAK = "B4:.5 G4 B4 E5:1.5 D5:.5 C5 | D5:.5 B4 G4:2 r:1 | C5:.5 A4 C5 F#5:1.5 E5:.5 D#5 | E5:.5 C5 D#5:2 r:1"
MINI_TAG = "B4:.5 D#5 F#5 A5 B5 A5 F#5 D#5 | B4:1 r:3"
MINI_A_CHORDS = "Em C D B7 Em C Am,B7 Em"
MINI_CHORDS = " ".join(["Em Em", MINI_A_CHORDS, "C D Bm Em Am D G B7", MINI_A_CHORDS, "Em C Am B7", "B7 B7"])


def mini_boss():
    s = Song(152, 32 * 4, reverb=0.22)
    p = _bars(prog(MINI_CHORDS), 32)
    for bar, parts in enumerate(p):
        brk = 26 <= bar < 30
        bassline(s, "synthbass", bar, parts, [(0, 0.9, 0), (2, 0.9, 0)] if brk else GALLOP, low=33, vel=0.85, gain=0.6)
        if bar < 2:
            drums(s, bar, {"kick": "x...x...x...x...", "hat": "x.x.x.x.x.x.x.x."}, scale=0.8)
        elif brk:
            drums(s, bar, {"kick": "x.......x.......", "hat": "..o...o...o...o."}, scale=0.7)
        else:
            drums(s, bar, {"kick": "x.......x.x.....", "snare": "....x.......x...", "hat": "x.x.x.x.x.x.x.x."}, scale=0.8)
            comp(s, "square", bar, parts, "x-....x-........", low=55, vel=0.5, gain=0.08, spread=0.5)
        if 10 <= bar < 18:
            arp(s, "thin", bar, parts, step=0.25, low=64, octaves=2, vel=0.45, gain=0.07, pan=0.55)
        if bar in (9, 17, 25):
            fill(s, bar, start=3.0, count=4, gain=0.4)
    fill(s, 31, start=2.0, count=8, gain=0.45)
    melody(s, "pulse", 2, MINI_A, bars=8, vel=0.88, gain=0.55, wide=True)
    melody(s, "square", 10, MINI_B, bars=8, vel=0.85, gain=0.36)
    melody(s, "pulse", 18, MINI_A, bars=8, vel=0.88, gain=0.55, wide=True)
    melody(s, "glass", 26, MINI_BREAK, bars=4, vel=0.85, gain=0.6, wide=True)
    melody(s, "pulse", 30, MINI_TAG, bars=2, vel=0.88, gain=0.5, wide=True)
    s.hit("crash", 2 * 4, vel=0.6, gain=0.35)
    s.hit("crash", 18 * 4, vel=0.6, gain=0.35)
    return s


# ---------------------------------------------------------------------------------------------
# Depth 1 boss: D minor, 160 bpm, all chip. The hold theme played straight in minor, short and
# snappy on a square wave, over a triangle bass jumping octaves. 32 bars: intro (4), A (8), B (8),
# A an octave up (8), tag (4).
# ---------------------------------------------------------------------------------------------

B1_A = ("A4:.5 F4 A4 D5:1.5 C#5:.5 Bb4 | C#5:.5 A4 F4:2 r:.5 A4 | Bb4:.5 G4 Bb4 E5:1.5 D5:.5 C#5 | D5:.5 Bb4 C#5:2 r:1 | "
        "A4:.5 F4 A4 D5:1.5 C#5:.5 D5 | F5:.5 E5 D5 A5:1.5 G5:.5 F5 | E5:.5 D5 C#5 E5 G5 Bb5 A5:1 | D5:2 r:2")
B1_B = ("F5:.5 D5 F5 Bb5:1 A5:.5 G5 F5 | G5:.5 E5 G5 C6:1 Bb5:.5 A5 G5 | A5:.5 E5 C5 E5 A5:1 G5 | F5:1.5 E5:.5 D5:2 | "
        "Bb5:.5 G5 D5 G5 Bb5:1 A5 | G5:.5 E5 C5 E5 G5:1 Bb5 | F5:.5 A5 C6 A5 F5:1 A5 | E5:.5 C#5 A4 C#5 E5:1 G5")
B1_TAG = "D6:1 A5 F5 D5 | D6:1 Bb5 F5 D5 | G5:.5 A5 Bb5 C6 D6 E6 F6 G6 | A6:2 r:2"
B1_A_CHORDS = "Dm Dm Gm6 A7 Dm F A7 Dm"
B1_CHORDS = " ".join(["Dm Dm Bb A7", B1_A_CHORDS, "Bb C Am Dm Gm C7 F A7", B1_A_CHORDS, "Dm Bb Gm A7"])


def boss_depth_1():
    s = Song(160, 32 * 4, reverb=0.2)
    p = _bars(prog(B1_CHORDS), 32)
    for bar, parts in enumerate(p):
        bassline(s, "tri", bar, parts, OCTAVES, low=38, vel=0.9, gain=0.72)
        bassline(s, "bass", bar, parts, [(0, 0.45, 0), (1, 0.45, 0), (2, 0.45, 0), (3, 0.45, 0)], low=38, vel=0.7, gain=0.4)
        if bar < 4:
            drums(s, bar, {"kick": "x...x...x...x...", "hat": "xoxoxoxoxoxoxoxo"}, scale=0.7)
        else:
            drums(s, bar, {"kick": "x.....x.x.......", "snare": "....x.......x...", "hat": "xoxoxoxoxoxoxoxo"}, scale=0.75)
        if bar < 4 or 12 <= bar < 20 or bar >= 28:
            arp(s, "thin", bar, parts, step=0.25, low=62, octaves=2, vel=0.45, gain=0.12, pan=0.85)
        else:
            comp(s, "pulse", bar, parts, "..x...x...x...x.", low=57, vel=0.45, gain=0.07, spread=0.85)
    fill(s, 3, gain=0.45); fill(s, 11, start=2.0, gain=0.4); fill(s, 27, start=2.0, gain=0.4)
    for bar in (4, 20):
        s.hit("crash", bar * 4, vel=0.6, gain=0.35)
    melody(s, "square", 4, B1_A, bars=8, vel=0.9, gain=0.5, legato=0.6, wide=True)
    melody(s, "pulse", 12, B1_B, bars=8, vel=0.88, gain=0.5, wide=True)
    melody(s, "pulse", 20, B1_A, bars=8, vel=0.88, gain=0.42, transpose=12, legato=0.6, wide=True)
    melody(s, "square", 20, B1_A, bars=8, vel=0.7, gain=0.25, legato=0.6, pan=-0.3)
    melody(s, "pulse", 28, B1_TAG, bars=4, vel=0.88, gain=0.48, wide=True)
    return s


# ---------------------------------------------------------------------------------------------
# Depth 2 boss: G minor, 150 bpm, brass and organ over a machine riff. A fast pulse hook, then the
# hold theme stretched out to twice its length on brass, like a slow siren over the riff. 32 bars:
# intro (4), A (8), the stretched theme (8), A with brass (8), tag (4).
# ---------------------------------------------------------------------------------------------

B2_A = ("G5:.5 D5 G5 Bb5 A5 G5 F#5 G5 | D5:1 Bb4 G4 A4:.5 Bb4 | C5:.5 Eb5 G5 Bb5 A5:1 G5 | F5:.5 A5 C6 A5 F5:1 D5 | "
        "G5:.5 D5 G5 Bb5 D6 C6 Bb5 A5 | Bb5:1 G5 D5:2 | Eb5:.5 G5 C6 Eb6 D6:1 C6 | A5:.5 F#5 D5 F#5 A5:1 C6")
B2_AUG = "D5:1 Bb4 D5 G5 | _:2 F#5:1 Eb5 | F#5:1 D5 Bb4:2 | _:2 r:2 | Eb5:1 C5 Eb5 A5 | _:2 G5:1 F#5 | G5:1 Eb5 F#5:2 | _:2 r:2"
B2_TAG = "Eb5:1 Eb5:.5 Eb5 r:2 | D5:1 D5:.5 D5 r:2 | G5:.5 Bb5 D6 G6 F#6:2 | D6:2 r:2"
B2_A_CHORDS = "Gm Gm Eb F Gm Gm Cm D7"
B2_CHORDS = " ".join(["Gm Gm Gm D7", B2_A_CHORDS, "Gm Gm,D7b9 D7,Gm Gm Cm6 Cm6,D7 Cm,D7 D7", B2_A_CHORDS, "Eb D7 Gm D7"])
B2_RIFF = [0, 0, 3, 0, 5, 0, 6, 5]


def boss_depth_2():
    s = Song(150, 32 * 4, reverb=0.25)
    p = _bars(prog(B2_CHORDS), 32)
    for bar, parts in enumerate(p):
        aug = 12 <= bar < 20
        for e, semis in enumerate(B2_RIFF):
            sym = at(parts, e * 0.5)
            major = not sym[1:].startswith("m") or sym[1:].startswith("maj")
            m = bass_note(sym, 31) + (4 if semis == 3 and major else semis)
            s.note("synthbass", m, bar * 4 + e * 0.5, 0.42, vel=0.85, gain=0.6, wet=0.05)
            s.note("square", m + 12, bar * 4 + e * 0.5, 0.3, vel=0.4, gain=0.06, pan=0.3, wet=0.1)
        if aug:
            comp(s, "organ", bar, parts, "x---------------", low=55, vel=0.6, gain=0.18, spread=0.5)
            arp(s, "thin", bar, parts, step=0.25, low=67, octaves=2, vel=0.45, gain=0.08, pan=0.6)
        elif bar >= 4:
            comp(s, "organ", bar, parts, "x--...x-........", low=55, vel=0.65, gain=0.2, spread=0.5)
        drums(s, bar, ROCK if bar >= 4 else {"kick": "x...x...x...x...", "hat": "x.x.x.x.x.x.x.x."}, scale=0.8)
        if bar in (4, 12, 20, 28):
            s.hit("crash", bar * 4, vel=0.6, gain=0.35)
    fill(s, 3, gain=0.45); fill(s, 19, gain=0.45); fill(s, 31, gain=0.45)
    melody(s, "pulse", 4, B2_A, bars=8, vel=0.9, gain=0.55, wide=True)
    melody(s, "brass", 12, B2_AUG, bars=8, vel=0.9, gain=0.55, wide=True)
    melody(s, "brass", 12, B2_AUG, bars=8, vel=0.75, gain=0.28, transpose=-12, pan=-0.2)
    melody(s, "pulse", 20, B2_A, bars=8, vel=0.9, gain=0.5, wide=True)
    melody(s, "brass", 20, B2_A, bars=8, vel=0.75, gain=0.28, transpose=-12, pan=0.2)
    melody(s, "brass", 28, B2_TAG, bars=4, vel=0.9, gain=0.55, wide=True)
    return s


# ---------------------------------------------------------------------------------------------
# Depth 4 boss: A minor, 168 bpm, a triplet tarantella for the lounge gone wrong. Brass and marimba
# hurl the hold theme in triplets, a piano takes the middle, and in the break the piano plays the
# theme slow while the marimba spins. 36 bars: intro (4), A (8), B (8), break (4), A (8), tag (4).
# ---------------------------------------------------------------------------------------------

B4_A = ("E5:2/3 C5:1/3 E5:1 A5:1 G#5:2/3 F5:1/3 | G#5:2/3 E5:1/3 C5:2 r:2/3 E5:1/3 | "
        "F5:2/3 D5:1/3 F5:1 B5:1 A5:2/3 G#5:1/3 | A5:2/3 F5:1/3 G#5:2 r:1 | "
        "E5:2/3 C5:1/3 E5:1 A5:1 B5:2/3 C6:1/3 | D6:2/3 C6:1/3 A5:1 F5:1 A5:2/3 C6:1/3 | "
        "B5:2/3 A5:1/3 F5:2/3 D5:1/3 G#5:2/3 F5:1/3 E5:2/3 D5:1/3 | C5:1 A4 r:2")
B4_B = ("G5:2/3 E5:1/3 G5:2/3 C6:1/3 E6:2 | D6:2/3 B5:1/3 G5:2/3 D5:1/3 G5:2 | C6:2/3 A5:1/3 E5:2/3 C5:1/3 A5:2 | "
        "G5:2/3 E5:1/3 B4:2/3 E5:1/3 G5:2 | A5:2/3 F5:1/3 C5:2/3 F5:1/3 A5:1 C6 | E6:2/3 C6:1/3 G5:2/3 E5:1/3 C6:2 | "
        "D6:2/3 A5:1/3 F5:2/3 D5:1/3 A5:1 F5 | E5:2/3 G#5:1/3 B5:2/3 D6:1/3 E6:1 r")
B4_BREAK = "E5:1 C5 E5 A5 | _:2 G#5:1 F5 | G#5:1 E5 C5:2 | B4:1 D5 E5 G#5"
B4_TAG = "A5:2/3 C6:1/3 F6:1 E6:2/3 D6:1/3 C6:1 | B5:2/3 G#5:1/3 E5:1 G#5:2/3 B5:1/3 D6:1 | C6:1 A5 E5 C5 | B4:1 E5 G#5 B5"
B4_A_CHORDS = "Am Am Dm6 E7 Am F Dm,E7 Am"
B4_CHORDS = " ".join(["Am Am Dm E7", B4_A_CHORDS, "C G Am Em F C Dm E7", "Am Am,E7b9 E7,Am E7", B4_A_CHORDS, "F E7 Am E7"])


def boss_depth_4():
    s = Song(168, 36 * 4, reverb=0.25)
    p = _bars(prog(B4_CHORDS), 36)
    for bar, parts in enumerate(p):
        brk = 20 <= bar < 24
        bassline(s, "bass", bar, parts, [(0, 0.6, 0), (1, 0.6, 7), (2, 0.6, 0), (3, 0.6, 7)], low=33, vel=0.85, gain=0.85)
        comp(s, "piano", bar, parts, "..x..x..x..x", low=57, vel=0.6, gain=0.2, spread=0.5)
        if brk or bar < 4:
            arp(s, "marimba", bar, parts, step=1 / 3, low=64, octaves=2, vel=0.6, gain=0.2, pan=0.45)
        if not brk:
            drums(s, bar, {"kick": "x.....x.....", "snare": "...x.....x..", "hat": "x.ox.ox.ox.o"}, scale=0.8)
        else:
            drums(s, bar, {"hat": "x.ox.ox.ox.o"}, scale=0.6)
        if bar in (3, 19, 35):
            for q in range(6):
                s.hit("tom", bar * 4 + 2 + q / 3, vel=0.5 + 0.08 * q, gain=0.5)
        if bar in (4, 24):
            s.hit("crash", bar * 4, vel=0.6, gain=0.35)
    melody(s, "brass", 4, B4_A, bars=8, vel=0.9, gain=0.5, wide=True)
    melody(s, "marimba", 4, B4_A, bars=8, vel=0.8, gain=0.35, pan=0.3)
    melody(s, "piano", 12, B4_B, bars=8, vel=0.8, gain=0.6, pan=-0.1)
    melody(s, "marimba", 12, B4_B, bars=8, vel=0.6, gain=0.2, transpose=12, pan=0.4)
    melody(s, "piano", 20, B4_BREAK, bars=4, vel=0.75, gain=0.6)
    melody(s, "brass", 24, B4_A, bars=8, vel=0.9, gain=0.48, wide=True)
    melody(s, "marimba", 24, B4_A, bars=8, vel=0.8, gain=0.35, transpose=12, pan=0.3)
    melody(s, "brass", 32, B4_TAG, bars=4, vel=0.9, gain=0.5, wide=True)
    return s


# ---------------------------------------------------------------------------------------------
# Depth 5 boss, Augustine: E minor, 148 bpm. The hold theme upside down: every step it took up now
# goes down. A brass call over saw strings and a choir; then the upside-down theme in canon, a second
# voice one bar behind; a new driving hook; and the upside-down theme again with the choir. The
# public-address chime opens it, once the right way up and once inverted. 36 bars.
# ---------------------------------------------------------------------------------------------

B5_INV = ("B4:.5 D5 B4 F#4:1.5 G4:.5 A4 | G4:.5 B4 D5:2 r:1 | A4:.5 C5 A4 E4:1.5 F#4:.5 G4 | F#4:.5 A4 G4:2 r:1 | "
          "B4:.5 D5 B4 F#4:1.5 G4:.5 F#4 | E4:1.5 F#4:.5 G4 B4:1.5 | A4:.5 B4 C5 D5 E5 F5 G5:1 | F#5:1.5 E5:.5 D#5:2")
B5_C = ("E5:.5 G5 C6:1 B5:.5 G5 E5:1 | F#5:.5 A5 D6:1 C6:.5 A5 F#5:1 | G5:.5 B5 E6:1 D6:.5 B5 G5 F#5 | E5:3 r:1 | "
        "E5:.5 G5 C6:1 B5:.5 G5 E6:1 | D6:.5 C6 A5:1 F#5:.5 A5 D6:1 | D#6:.5 B5 F#5 D#5 B4:1 F#5 | D#5:2 r:2")
B5_A_CHORDS = "Em9 G Am C Em9 Cmaj7 Am B7"
B5_CHORDS = " ".join(["Em F Em B7", B5_A_CHORDS, B5_A_CHORDS, "C D Em Em C D B7 B7", B5_A_CHORDS])


def boss_depth_5():
    s = Song(148, 36 * 4, reverb=0.3)
    p = _bars(prog(B5_CHORDS), 36)
    for bar, parts in enumerate(p):
        canon = 12 <= bar < 20
        comp(s, "pad", bar, parts, "x---------------", low=52, vel=0.6, gain=0.14, spread=0.8)
        bassline(s, "synthbass", bar, parts, OCTAVES, low=28, vel=0.85, gain=0.6)
        if bar < 4 or canon:
            drums(s, bar, {"kick": "x.......x.......", "hat": "..o...o...o...o."}, scale=0.8)
        else:
            drums(s, bar, {"kick": "x...x...x...x...", "snare": "....x.......x...", "hat": "..x...x...x...x."}, scale=0.8)
        if 20 <= bar < 28:
            arp(s, "thin", bar, parts, step=0.25, low=64, octaves=2, vel=0.45, gain=0.08, pan=0.6)
        if bar in (4, 20, 28):
            s.hit("crash", bar * 4, vel=0.6, gain=0.35)
    fill(s, 3, gain=0.45); fill(s, 19, gain=0.45); fill(s, 27, gain=0.45)
    # The chime: the hold theme's opening the right way up, then upside down.
    s.line("bell", 0, mel("B5:.5 G5 B5 E6:2.5")[0], vel=0.55, gain=0.45, pan=0.25)
    s.line("bell", 2 * 4, mel("B5:.5 D6 B5 F#5:2.5")[0], vel=0.55, gain=0.45, pan=-0.25)
    melody(s, "brass", 4, B5_INV, bars=8, vel=0.9, gain=0.55, wide=True)
    melody(s, "choir", 4, B5_INV, bars=8, vel=0.7, gain=0.3, transpose=-12)
    melody(s, "pulse", 12, B5_INV, bars=8, vel=0.88, gain=0.45, transpose=12, wide=True)
    seven = " | ".join(B5_INV.split("|")[:7])
    melody(s, "square", 13, seven, bars=7, vel=0.75, gain=0.3, pan=-0.35)
    melody(s, "pulse", 20, B5_C, bars=8, vel=0.88, gain=0.5, wide=True)
    melody(s, "brass", 28, B5_INV, bars=8, vel=0.9, gain=0.55, wide=True)
    melody(s, "choir", 28, B5_INV, bars=8, vel=0.75, gain=0.4)
    return s


# ---------------------------------------------------------------------------------------------
# The Chairman of the Board: the final boss, and the hold music finally breaks down. F, 168 bpm.
# It starts as the hold music itself, half speed and cheerful, and then the tape stutters and grinds
# to a halt. What comes back is the hold theme in F minor at full tilt, then the Chairman's own hook,
# then the theme sung slowly by a choir over pipe organ while glitched scraps of it fly past, then the
# theme a half step higher with everything. Then it falls apart a note at a time, the tape stops, a
# clock ticks, and the "your call is important to us" chime starts the hold music again. 48 bars.
# ---------------------------------------------------------------------------------------------

CH_A = ("C5:.5 Ab4 C5 F5:1.5 E5:.5 Db5 | E5:.5 C5 Ab4:2 r:1 | Db5:.5 Bb4 Db5 G5:1.5 F5:.5 E5 | F5:.5 Db5 E5:2 r:1 | "
        "C5:.5 Ab4 C5 F5:1.5 E5:.5 Db5 | E5:.5 F5 Ab5:1.5 G5:.5 F5 Db5 | Bb5:.5 Ab5 G5 F5 E5 Db5 C5:1 | G5:1.5 E5:.5 C5:1 r")
CH_B = ("F5:.5 Ab5 Db6:1 C6:.5 Ab5 F5:1 | G5:.5 Bb5 Eb6:1 Db6:.5 Bb5 G5:1 | G5:.5 C6 Eb6:1 D6:.5 C6 G5:1 | Ab5:.5 F5 C5:1 F5:2 | "
        "Bb5:.5 Db6 F6 Db6 Bb5:1 F5 | C6:.5 Bb5 G5 E5 C5:1 E5 | F5:.5 Ab5 Db6 F6 Eb6:1 Db6 | C6:.5 Bb5 G5 E5 G5 Bb5 C6:1")
CH_C = "C5:1 Ab4 C5 F5 | _:2 E5:1 Db5 | E5:1 C5 Ab4:2 | _:2 r:2 | Db5:1 Bb4 Db5 G5 | _:2 F5:1 E5 | F5:1 Db5 E5:2 | _:2 r:2"
CH_STUTTER = "C5:.25 C5 C5 C5 C5 C5 C5 C5 A4 A4 A4 A4 C5 C5 F5:.5"
CH_SCRAP = "C6:.25 C6 Ab5 Ab5 C6 C6 F6 F6"
CH_COLLAPSE = "C#5:.5 A4 C#5 F#5:1.5 r:1 | C#5:.5 A4 C#5 r:2.5 | C#5:.5 A4 r:3 | C#5:.5 r:3.5"
CH_CHORDS = ("Fmaj9 Fmaj9 Dm9 Dm9 | Fmaj9 Fmaj9 C7 C7 | Fm Fm Bbm C7 Fm Db Bbm C7 | Db Eb Cm Fm Bbm C7 Db C7 | "
             "Fm Fm,C7b9 C7,Fm Fm Bbm6 Bbm6,C7 Db,C7 C7 | F#m F#m Bm C#7 F#m D Bm C#7 | F#m F#m F#m F#m | F#m C7 C7 C7")
CH_A_FULL = ("Fm Fm Bbm C7 Fm Db Bbm C7", "F#m F#m Bm C#7 F#m D Bm C#7")


def the_chairman():
    s = Song(168, 48 * 4, reverb=0.3)
    p = _bars(prog(CH_CHORDS), 48)
    # Bars 0-3: the hold music, at half speed, as if nothing were wrong.
    for pair in (0, 2):
        sym = p[pair][0][2]
        notes, _ = chord(sym, 55)
        for off, dur in ((0, 2), (3, 1), (6, 1)):
            for k, m in enumerate(notes):
                s.note("epiano", m, pair * 4 + off, dur, vel=0.5, gain=0.3, pan=-0.35 + 0.23 * k)
        root = bass_note(sym, 36)
        for off, dur, m in ((0, 3, root), (3, 1, root + 7), (4, 3, root), (7, 1, root + 7)):
            s.note("bass", m, pair * 4 + off, dur, vel=0.85, gain=0.85, wet=0.08)
        for e in range(8):
            s.hit("brush", pair * 4 + e, vel=0.7 if e % 2 == 0 else 0.45, gain=0.55, pan=-0.3)
            s.hit("shaker", pair * 4 + e, vel=0.6, gain=0.5, pan=0.45)
        for c in (0, 3, 6):
            s.hit("rim", pair * 4 + c, vel=0.6, gain=0.5, pan=0.2)
    s.line("pulse", 0, [(n, d * 2) for n, d in HOLD_A1[:10]], vel=0.85, gain=0.6, wide=True, bars=4)
    # Bars 4-5: the tape stutters, then grinds to a halt.
    melody(s, "pulse", 4, CH_STUTTER, bars=1, vel=0.85, gain=0.55, legato=0.5, wide=True)
    for q in range(4):
        s.hit("zap", 4 * 4 + q, vel=0.7, gain=0.5)
    s.hit("crash", 4 * 4, vel=0.7, gain=0.4)
    for m in chord("Fmaj9", 55)[0] + [bass_note("F", 36)]:
        s.note("tapestop", m, 5 * 4, 4, vel=0.8, gain=0.4)
    # Bars 6-7: something else boots up.
    for m in chord("C7", 52)[0]:
        s.note("choir", m, 6 * 4, 8, vel=0.7, gain=0.3)
    for e in range(16):
        s.note("synthbass", bass_note("C", 24) + (12 if e % 2 else 0), 6 * 4 + e * 0.5, 0.4, vel=0.5 + 0.03 * e, gain=0.55, wet=0.05)
        s.hit("kick", 6 * 4 + e * 0.5, vel=0.5 + 0.03 * e, gain=0.7, wet=0.05)
    fill(s, 7, start=0.0, count=16, gain=0.5)
    # Bars 8-39: the fight.
    for bar in range(8, 40):
        parts = p[bar]
        aug = 24 <= bar < 32
        bassline(s, "synthbass", bar, parts, OCTAVES, low=29, vel=0.85, gain=0.6)
        if aug:
            comp(s, "pipe", bar, parts, "x---------------", low=53, vel=0.6, gain=0.22, spread=0.6)
            arp(s, "thin", bar, parts, step=0.25, low=65, octaves=2, vel=0.45, gain=0.09, pan=0.6)
            drums(s, bar, {"kick": "x.......x.......", "snare": "........x.......", "hat": "x.x.x.x.x.x.x.x."}, scale=0.85)
        else:
            comp(s, "pipe", bar, parts, "x--...x-........", low=53, vel=0.65, gain=0.2, spread=0.6)
            drums(s, bar, ROCK, scale=0.85)
        if 16 <= bar < 24:
            comp(s, "choir", bar, parts, "x---------------", low=55, vel=0.55, gain=0.16, spread=0.7)
        if bar in (8, 16, 24, 32):
            s.hit("crash", bar * 4, vel=0.7, gain=0.4)
        if bar in (15, 23, 31):
            fill(s, bar, gain=0.45)
    melody(s, "brass", 8, CH_A, bars=8, vel=0.9, gain=0.55, wide=True)
    melody(s, "pulse", 8, CH_A, bars=8, vel=0.75, gain=0.22, transpose=12, pan=0.3)
    melody(s, "pulse", 16, CH_B, bars=8, vel=0.9, gain=0.55, wide=True)
    melody(s, "choir", 24, CH_C, bars=8, vel=0.8, gain=0.55)
    melody(s, "pipe", 24, CH_C, bars=8, vel=0.6, gain=0.3, transpose=-12)
    for bar in (25, 27, 29, 31):
        s.line("square", bar * 4 + 2, mel(CH_SCRAP, 2)[0], vel=0.6, gain=0.2, legato=0.6, pan=0.5 if bar % 4 == 1 else -0.5)
        s.hit("zap", bar * 4 + 2, vel=0.5, gain=0.3)
    melody(s, "brass", 32, CH_A, bars=8, vel=0.9, gain=0.55, transpose=1, wide=True)
    melody(s, "pulse", 32, CH_A, bars=8, vel=0.75, gain=0.22, transpose=13, pan=0.3)
    melody(s, "choir", 32, CH_A, bars=8, vel=0.6, gain=0.22, transpose=-11)
    # Bars 40-43: it falls apart a note at a time, and the band drops out with it.
    for bar in range(40, 44):
        parts = p[bar]
        if bar < 43:
            bassline(s, "synthbass", bar, parts, OCTAVES if bar == 40 else [(0, 1.5, 0)], low=29, vel=0.8, gain=0.55)
        if bar == 40:
            drums(s, bar, ROCK, scale=0.8)
        elif bar == 41:
            drums(s, bar, {"kick": "x.......x......."}, scale=0.8)
        comp(s, "pipe", bar, parts, "x---", low=53, vel=0.55 - 0.1 * (bar - 40), gain=0.2, spread=0.6)
    melody(s, "pulse", 40, CH_COLLAPSE, bars=4, vel=0.85, gain=0.55, wide=True)
    # Bars 44-47: the tape stops, a clock ticks, and the chime starts the hold music over.
    for m in chord("F#m", 54)[0] + [bass_note("F#", 36)]:
        s.note("tapestop", m, 44 * 4, 4, vel=0.8, gain=0.4)
    drums(s, 45, {"tick": "x...x...x...x..."}); drums(s, 46, {"tick": "x...x...x...x..."}); drums(s, 47, {"tick": "x...x..."})
    for i, n in enumerate(["E6", "C6", "G5"]):
        s.note("bell", n, 46 * 4 + 2 + i * 1.0, 2, vel=0.5, gain=0.45, pan=0.3)
    return s
