"""Songs for places: the title, the landing, the Arcade, and one exploration theme per path.

Each path has its own instrument colour and its own joke. Melodies are melody text (see kit.py),
so every bar is counted before anything renders.
"""
from synth import Song, chord, bass_note
from kit import mel, melody, prog, at, comp, bassline, arp, drums, fill
from songs import HOLD_A1, HOLD_A2, walking_bass

BOSSA = ["x---..x-....x-..", "..x-....x---..x-"]
BOSSA_BASS = [(0, 1.5, 0), (1.5, 0.5, 7), (2, 1.5, 0), (3.5, 0.5, 7)]


def _bars(p, count):
    assert len(p) == count, "progression has %d bars, not %d" % (len(p), count)
    return p


# ---------------------------------------------------------------------------------------------
# Take a Number: the title screen. A little queue-shuffle march in Bb, 116 bpm, tuba and snare under
# a chip lead that opens with the hold theme's first notes. A ticket machine dings when a number is
# called. 24 bars: shuffle-in (2), A (8), B on clarinet (8), A again with a music box (6).
# ---------------------------------------------------------------------------------------------

TITLE_HEAD = "F4:.5 D4 F4 Bb4:1.5 A4:.5 G4 | A4:.5 F4 D4:1 r:.5 F4 G4 A4 | Bb4:.5 G4 Bb4 Eb5:1.5 D5:.5 C5 | D5:.5 Bb4 F4:1 r:1 F4:.5 F4"
TITLE_TAIL = "G4:.5 A4 Bb4 C5 D5:1 Bb4 | C5:.5 D5 Eb5 F5 G5:1 E5 | F5:1.5 Eb5:.5 D5 C5 Bb4 A4 | Bb4:1 F4 Bb4 r"
TITLE_END = "Eb5:.5 D5 C5 Bb4 A4:1 C5 | Bb4:2 r:2"
TITLE_B = ("G4:1 Bb4 Eb5:1.5 D5:.5 | C5:1 Bb4 G4:2 | F4:1 Bb4 D5:1.5 C5:.5 | B4:1 D5 F5:2 | "
           "Eb5:1 D5:.5 C5 G4:1 Eb5 | D5:.5 C5 Bb4 A4 C5:2 | Bb4:1 D5:.5 F5 Bb5:1 A5:.5 G5 | F5:1 Eb5 D5 C5")
TITLE_CHORDS = "Bb F7 | Bb Dm7 Eb Bb Gm C7 F7 Bb | Eb Edim Bb G7 Cm F7 Bb F7 | Bb Dm7 Eb Bb Cm7,F7 Bb"


def take_a_number():
    s = Song(116, 24 * 4, reverb=0.28, swing=0.06)
    p = _bars(prog(TITLE_CHORDS), 24)
    for bar, parts in enumerate(p):
        intro, b_part = bar < 2, 10 <= bar < 18
        # Oom: a tuba on the root and the fifth. Pah: soft square chords on 2 and 4.
        bassline(s, "brass", bar, parts, [(0, 0.9, 0), (2, 0.9, 7)], low=34, vel=0.8, gain=0.55)
        bassline(s, "bass", bar, parts, [(0, 0.9, 0), (2, 0.9, 7)], low=34, vel=0.7, gain=0.45)
        comp(s, "square", bar, parts, "..x...x.", low=58, vel=0.5, gain=0.07, spread=0.6)
        if intro:
            drums(s, bar, {"snare": "....o.......o..o", "kick": "x.......x......."}, scale=0.6)
        # The queue shuffles along on a woodblock; the march snare keeps it in step.
        if intro or bar >= 18:
            drums(s, bar, {"woodblock": "x...o...x...o...", "tick": "..o...o...o...o."}, scale=0.8)
        if b_part:
            drums(s, bar, {"kick": "x.......x.......", "snare": "....x.......x...", "shaker": "o.o.o.o.o.o.o.o."}, scale=0.75)
        elif not intro:
            drums(s, bar, {"kick": "x.......x.......", "snare": "....x..o....x.oo"}, scale=0.75)
    # The tune: chip lead, clarinet in the middle, a music box doubling the last A.
    melody(s, "pulse", 2, TITLE_HEAD + " | " + TITLE_TAIL, bars=8, vel=0.85, gain=0.5, transpose=12, wide=True)
    melody(s, "reed", 10, TITLE_B, bars=8, vel=0.8, gain=0.6, pan=-0.15)
    for bar, notes in ((11, "Bb5:.5 G5 E5 Db5"), (13, "D6:.5 B5 G5 F5"), (15, "A5:.5 F5 Eb5 C5")):
        s.line("musicbox", bar * 4 + 2, mel(notes, 2)[0], vel=0.6, gain=0.5, pan=0.4)
    melody(s, "pulse", 18, TITLE_HEAD + " | " + TITLE_END, bars=6, vel=0.85, gain=0.48, transpose=12, wide=True)
    melody(s, "musicbox", 18, TITLE_HEAD + " | " + TITLE_END, bars=6, vel=0.5, gain=0.35, transpose=24, pan=0.35)
    # "Now serving": the ticket machine's ding.
    for beat in (1 * 4 + 3, 9 * 4 + 3, 23 * 4 + 2):
        s.note("bell", "D6", beat, 1, vel=0.5, gain=0.35, pan=0.3)
        s.note("bell", "Bb5", beat + 0.5, 1, vel=0.45, gain=0.35, pan=0.3)
    return s


# ---------------------------------------------------------------------------------------------
# The Landing: a short calm breather between floors. A music box and vibes in Ab, 72 bpm, over soft
# strings; the box hums a slowed turn of the hold theme. 16 bars.
# ---------------------------------------------------------------------------------------------

LANDING_A = ("Eb5:.5 C5 Eb5 Ab5:1.5 G5:.5 F5 | G5:1 Eb5 C5:2 | F5:.5 Db5 F5 Bb5:1.5 Ab5:.5 G5 | Ab5:1 F5 G5:2 | "
             "Eb5:.5 C5 Eb5 Ab5:1.5 G5:.5 F5 | G5:.5 Ab5 C6:1.5 Bb5:.5 Ab5 F5 | Db6:.5 C6 Bb5 Ab5 G5:1 F5 | Eb5:3 r:1")
LANDING_B = "r:1 C5:.5 Db5 F5:1 Ab5 | G5:1.5 F5:.5 Eb5:2 | r:1 Db5:.5 Eb5 F5:1 Ab5 | G5:2 Bb5:2"
LANDING_C = "C6:1.5 Bb5:.5 Ab5:1 Eb5 | F5:1.5 Ab5:.5 C6:2 | Bb5:1 Ab5:.5 F5 Eb5:1 Db5 | C5:2 r:2"
LANDING_CHORDS = "Abmaj7 Fm9 Dbmaj7 Eb7 Abmaj7 Fm7 Bbm6 Eb7 | Dbmaj7 Cm7 Bbm7 Eb7 | Abmaj7 Dbmaj7 Bbm7,Eb7 Eb6"


def landing():
    s = Song(72, 16 * 4, reverb=0.45)
    p = _bars(prog(LANDING_CHORDS), 16)
    for bar, parts in enumerate(p):
        comp(s, "pad", bar, parts, "x---------------", low=53, vel=0.55, gain=0.13, spread=0.7)
        arp(s, "vibes", bar, parts, step=1.0, low=60, octaves=1, vel=0.5, gain=0.16, pan=0.45, length=1.6)
        bassline(s, "bass", bar, parts, [(0, 1.9, 0), (2, 1.9, 7)], low=32, vel=0.6, gain=0.5)
    melody(s, "musicbox", 0, LANDING_A, bars=8, vel=0.75, gain=0.75, pan=-0.15)
    melody(s, "vibes", 8, LANDING_B, bars=4, vel=0.7, gain=0.55, pan=0.2)
    for bar, notes in ((8, "Eb6:.5 C6"), (10, "F6:.5 Db6")):
        s.line("musicbox", bar * 4, mel(notes, 1)[0], vel=0.55, gain=0.5, pan=-0.4)
    melody(s, "musicbox", 12, LANDING_C, bars=4, vel=0.75, gain=0.75, pan=-0.15)
    return s


# ---------------------------------------------------------------------------------------------
# The Arcade (and the Back Room): bouncy casino chiptune in C, 144 bpm with a little swing. A chip
# lead over a triangle bass, offbeat chords, and coins that tumble out after each phrase. 32 bars:
# A, A, B, A.
# ---------------------------------------------------------------------------------------------

ARC_A = ("E5:.5 G5 C6 G5 A5:1 G5 | C#5:.5 E5 A5 E5 G5:1 E5 | F5:.5 A5 D6 A5 C6:1 A5 | B5:.5 A5 G5 F5 D5:1 r | "
         "E5:.5 G5 C6 G5 A5:1 G5 | C#5:.5 E5 A5 C#6 E6:1 C#6 | D6:.5 C6 A5 F5 B5 A5 G5 F5 | E5:1 C5 C6 r")
ARC_A_LAST = ARC_A.rsplit("|", 1)[0] + "| E5:1 C5 G5:.5 F5 E5 D5"
ARC_B = ("A5:1.5 G5:.5 F5:1 C5 | Eb5:1.5 D5:.5 C5:1 A4 | G5:1.5 E5:.5 C5:1 G4 | A4:.5 C#5 E5 G5 Bb5:1 A5 | "
         "A5:1.5 F5:.5 D5:1 A5 | G5:.5 A5 B5 D6 F6:1 D6 | E6:.5 D6 C6 B5 C#6 D6 E6 G6 | F6:.5 E6 D6 C6 B5:1 G5")
ARC_A_CHORDS = "C6 A7 Dm7 G7 C6 A7 Dm7,G7 C6"
ARC_CHORDS = " ".join([ARC_A_CHORDS, ARC_A_CHORDS, "F F#dim C6 A7 Dm7 G7 Em7,A7 Dm7,G7", "C6 A7 Dm7 G7 C6 A7 Dm7,G7 C6,G7"])


def the_arcade():
    s = Song(144, 32 * 4, reverb=0.2, swing=0.12)
    p = _bars(prog(ARC_CHORDS), 32)
    for bar, parts in enumerate(p):
        bassline(s, "tri", bar, parts, [(0, 0.45, 0), (1, 0.45, 12), (2, 0.45, 7), (3, 0.45, 12)], low=36, vel=0.9, gain=0.8)
        bassline(s, "bass", bar, parts, [(0, 0.45, 0), (2, 0.45, 7)], low=36, vel=0.7, gain=0.4)
        comp(s, "square", bar, parts, "..x...x.", low=60, vel=0.5, gain=0.07, spread=0.6)
        drums(s, bar, {"kick": "x.......x.......", "snare": "....x.......x...", "hat": "x.o.x.o.x.o.x.o."}, scale=0.8)
        if bar % 8 == 7:
            fill(s, bar, start=3.0, count=4, gain=0.35)
    melody(s, "pulse", 0, ARC_A, bars=8, vel=0.85, gain=0.5, wide=True)
    melody(s, "pulse", 8, ARC_A, bars=8, vel=0.85, gain=0.45, wide=True)
    melody(s, "musicbox", 8, ARC_A, bars=8, vel=0.4, gain=0.25, transpose=12, pan=0.4)
    melody(s, "square", 16, ARC_B, bars=8, vel=0.8, gain=0.32, pan=-0.1)
    melody(s, "pulse", 24, ARC_A_LAST, bars=8, vel=0.85, gain=0.5, wide=True)
    # Coins after each phrase that has room for them.
    for bar in (3, 11, 27):
        s.line("musicbox", bar * 4 + 3, mel("C6:.25 E6 G6 C7", 1)[0], vel=0.6, gain=0.45, pan=0.5)
    s.line("musicbox", 7 * 4 + 3, mel("G6:.25 E6 G6 C7", 1)[0], vel=0.6, gain=0.45, pan=-0.5)
    return s


# ---------------------------------------------------------------------------------------------
# The Records Basement: dusty office swing in Eb, 132 bpm. A clarinet files the tune away, a muted
# trumpet answers, a piano comps the Charleston and the bass walks; the record crackles, and at the
# end of each A a typewriter clacks and rings its bell. 32 bars, AABA.
# ---------------------------------------------------------------------------------------------

REC_A = ("G4:.5 Bb4 Eb5 G5:1 F5:.5 Eb5:1 | E5:.5 G5 Bb5:1 G5:.5 E5 C5:1 | Ab4:.5 C5 F5:1 Ab5:.5 G5 F5 Eb5 | D5:1 Bb4 r:2 | "
         "G4:.5 Bb4 Eb5 G5:1 F5:.5 Eb5:1 | E5:.5 G5 Bb5 C6 Bb5 G5 E5:1 | F5:.5 Eb5 C5 Ab4 D5 F5 Ab5 Bb5 | G5:1.5 Eb5:.5 r:2")
REC_B = ("Eb5:1 C5:.5 Eb5 Gb5:1 Eb5 | F5:.5 Eb5 C5 Ab4 Gb4:2 | G4:.5 Bb4 Eb5 G5 Bb5:2 | C6:.5 Bb5 G5 Eb5 C5:2 | "
         "F5:1 A4:.5 C5 Eb5:1 C5 | D5:.5 C5 A4 F4 A4:2 | Ab4:1 C5 F5 Ab5 | G5:.5 F5 D5 Bb4 Ab4 F4 D4 Bb3")
REC_A_CHORDS = "Eb6 C7 Fm7 Bb7 Eb6 C7 Fm7,Bb7 Eb6"
REC_CHORDS = " ".join([REC_A_CHORDS, REC_A_CHORDS, "Ab7 Ab7 Eb6 Eb6 F7 F7 Fm7 Bb7", REC_A_CHORDS])


def _typewriter(s, bar):
    for k, t in enumerate((2, 2.25, 2.5, 2.75, 3.0)):
        s.hit("rim", bar * 4 + t, vel=0.7 if k % 2 == 0 else 0.5, gain=0.4, pan=0.5)
    s.note("bell", "E7", bar * 4 + 3.5, 0.5, vel=0.5, gain=0.25, pan=0.5, wet=0.6)
    s.hit("shaker", bar * 4 + 3.75, vel=0.8, gain=0.6, pan=0.5)


def records_basement():
    s = Song(132, 32 * 4, reverb=0.3, swing=0.16)
    p = _bars(prog(REC_CHORDS), 32)
    walking_bass(s, 0, [parts[0][2] for parts in p], low=36, gain=0.85)
    for bar, parts in enumerate(p):
        comp(s, "piano", bar, parts, "x---..x-........", low=55, vel=0.55, gain=0.3, spread=0.5)
        drums(s, bar, {"ride": "x...x.x.x...x.x.", "brush": "....x.......x...", "kick": "o...o...o...o...",
                       "crackle": "x...x...x...x..."}, scale=0.8)
    for bar in (7, 15, 31):
        _typewriter(s, bar)
    melody(s, "reed", 0, REC_A, bars=8, vel=0.85, gain=0.62, pan=-0.15)
    melody(s, "reed", 8, REC_A, bars=8, vel=0.85, gain=0.62, pan=-0.15)
    melody(s, "brass", 16, REC_B, bars=8, vel=0.85, gain=0.5, pan=0.2)
    melody(s, "reed", 24, REC_A, bars=8, vel=0.85, gain=0.62, pan=-0.15)
    for bar in (3, 11, 27):
        s.line("brass", bar * 4 + 2, mel("F5:.5 Ab5 G5 F5", 2)[0], vel=0.8, gain=0.45, pan=0.35)
    return s


# ---------------------------------------------------------------------------------------------
# The Unkempt Cemetery: a spooky waltz in D minor, 3/4 at 156 bpm. A theremin sings over a bass
# "oom" and "pah-pah" chords knocked out on bones; a music box answers every long note, and the wind
# gets up between sections. 48 bars: intro (4), A (16), B in F (16), A again (12).
# ---------------------------------------------------------------------------------------------

CEM_INTRO = "D6:1 F6 A6 | G#6:3 | A6:1 E6 C#6 | A5:3"
CEM_A = ("A4:2 D5:1 | F5:3 | E5:1 D5 Bb4 | G4:3 | A4:2 C#5:1 | E5:3 | G5:1 F5 E5 | D5:3 | "
         "D5:2 F5:1 | Bb5:3 | A5:1 G5 F5 | D5:3 | E5:2 G#5:1 | B5:2 D6:1 | C#6:1 B5 A5 | E5:2 A4:1")
CEM_B = ("C5:2 F5:1 | A5:3 | G5:1 Bb5 G5 | E5:3 | C5:2 E5:1 | G5:2 Bb5:1 | A5:1 G5 F5 | C5:3 | "
         "D5:2 F5:1 | Bb5:3 | A5:1 C6 A5 | F5:3 | G5:2 Bb5:1 | D6:2 Bb5:1 | A5:1 G5 E5 | C#5:2 E5:1")
CEM_A2 = "A4:2 D5:1 | F5:3 | E5:1 D5 Bb4 | G4:3 | A4:2 C#5:1 | E5:3 | G5:1 F5 E5 | D5:3 | Bb4:1 D5 G5 | A5:1 G5 E5 | D5:3 | C#5:2 A4:1"
CEM_CHORDS = ("Dm Dm A7 A7 | Dm Dm Gm Gm A7 A7 Dm Dm Bb Bb Gm Gm E7 E7 A7 A7 | "
              "F F C7 C7 C7 C7 F F Bb Bb F F Gm Gm A7 A7 | Dm Dm Gm Gm A7 A7 Dm Dm Gm A7 Dm A7")


def unkempt_cemetery():
    s = Song(156, 48 * 3, reverb=0.42, meter=3)
    p = _bars(prog(CEM_CHORDS, 3), 48)
    for bar, parts in enumerate(p):
        sym = parts[0][2]
        root = bass_note(sym, 33)
        s.note("bass", root + (7 if bar % 2 else 0), bar * 3, 1, vel=0.85, gain=0.8, wet=0.1)
        s.hit("kick", bar * 3, vel=0.5, gain=0.5, wet=0.05)
        comp(s, "marimba", bar, parts, "..x.x.", low=62, vel=0.6, gain=0.2, spread=0.5)
        comp(s, "pad", bar, parts, "x-----", low=50, vel=0.5, gain=0.07, spread=0.6)
    for bar in (3, 19, 35):
        s.hit("steam", bar * 3 + 1, vel=0.5, gain=0.35, pan=-0.6, wet=0.8)
    melody(s, "musicbox", 0, CEM_INTRO, bars=4, vel=0.65, gain=0.6, pan=0.3)
    at_bar = 4
    for text, count in ((CEM_A, 16), (CEM_B, 16), (CEM_A2, 12)):
        melody(s, "theremin", at_bar, text, bars=count, vel=0.85, gain=0.6, pan=-0.1)
        # The music box answers every note the theremin holds for a whole bar.
        bars = [b.split() for b in text.split("|")]
        for k, tokens in enumerate(bars):
            if len(tokens) == 1 and tokens[0].endswith(":3"):
                bar = at_bar + k
                notes, _ = chord(p[bar][0][2], 74)
                for j, m in enumerate(notes[:3]):
                    s.note("musicbox", m, bar * 3 + 1 + j * 0.5, 0.5, vel=0.5, gain=0.4, pan=0.4)
        at_bar += count
    return s


# ---------------------------------------------------------------------------------------------
# Sunset Shores Eternal Care: easy-listening organ in G, 96 bpm, a gentle foxtrot. The house organ
# plays the tune with a soft guitar on 2 and 4, a flute takes it the second time round, and the bingo
# cage rattles at the end of each A. 24 bars: A, B, A.
# ---------------------------------------------------------------------------------------------

SUN_A = ("B4:1 D5 G5:1.5 F#5:.5 | E5:1 G5 B4:2 | C5:1 E5 A5:1.5 G5:.5 | F#5:1.5 E5:.5 D5:2 | "
         "B4:1 D5 G5:1.5 A5:.5 | B5:1 G#5 E5:2 | C6:1 A5:.5 E5 D5:1 F#5 | G5:3 r:1")
SUN_B = ("E5:1.5 G5:.5 B5:1 C6 | Eb5:1.5 G5:.5 A5:2 | D5:1.5 F#5:.5 A5:1 B5 | G#5:1.5 F#5:.5 E5:2 | "
         "C5:1 E5 A5 G5 | F#5:1 A5 C6:1.5 B5:.5 | B5:1.5 A5:.5 G5:1 E5 | D5:2 C5:1 A4")
SUN_A_CHORDS = "Gmaj7 Em7 Am7 D7 Gmaj7 E7 Am7,D7 Gmaj7"
SUN_CHORDS = " ".join([SUN_A_CHORDS, "Cmaj7 Cm6 Bm7 E7 Am7 D7 G6 D7", SUN_A_CHORDS])


def _bingo(s, bar):
    for q in range(6):
        s.hit("shaker", bar * 4 + 2 + q * 0.25, vel=0.6 + 0.05 * q, gain=0.6, pan=0.5)
    s.hit("woodblock", bar * 4 + 3.5, vel=0.8, gain=0.5, pan=0.5)


def sunset_shores():
    s = Song(96, 24 * 4, reverb=0.32, swing=0.08)
    p = _bars(prog(SUN_CHORDS), 24)
    for bar, parts in enumerate(p):
        comp(s, "guitar", bar, parts, "....x-......x-..", low=52, vel=0.7, gain=0.3, spread=0.4)
        comp(s, "vibes", bar, parts, "x---------------", low=60, vel=0.4, gain=0.1, spread=0.6)
        bassline(s, "bass", bar, parts, [(0, 1.8, 0), (2, 1.3, 7), (3.5, 0.5, 5)], low=36, vel=0.8, gain=0.75)
        drums(s, bar, {"brush": "x.o.x.o.x.o.x.o.", "shaker": ".o.o.o.o.o.o.o.o", "kick": "o.......o......."}, scale=0.7)
    for bar in (7, 23):
        _bingo(s, bar)
    melody(s, "organ", 0, SUN_A, bars=8, vel=0.8, gain=0.62, wide=True)
    s.line("flute", 7 * 4 + 3, mel("D6:.5 B5", 1)[0], vel=0.7, gain=0.5, pan=0.4)
    melody(s, "organ", 8, SUN_B, bars=8, vel=0.8, gain=0.6, wide=True)
    melody(s, "flute", 16, SUN_A, bars=8, vel=0.8, gain=0.65, pan=0.15)
    melody(s, "organ", 16, SUN_A, bars=8, vel=0.6, gain=0.35, transpose=-12, pan=-0.3)
    return s


# ---------------------------------------------------------------------------------------------
# The Furnace Works: industrial brass and clanks in C minor, 120 bpm. A low brass riff and a saw bass
# turn like a machine; a trumpet sings over it, anvils ring in the gaps, metal clanks on the offbeats
# and the pipes let off steam. 28 bars: machine start (4), A (8), B in Eb (8), A again (8).
# ---------------------------------------------------------------------------------------------

FUR_A = ("G4:1.5 C5:.5 Eb5:1 D5 | C5:1 G4 r:2 | Ab4:1.5 C5:.5 Eb5:1 F5 | Eb5:2 r:2 | "
         "F5:1.5 Ab5:.5 G5:1 F5 | Eb5:1 C5 Ab4:2 | B4:1 D5 F5 Ab5 | G5:3 r:1")
FUR_B = ("Bb4:.5 Eb5 G5:2 F5:.5 Eb5 | D5:.5 F5 Bb5:2 Ab5:.5 F5 | C5:.5 Eb5 Ab5:2 G5:.5 F5 | Eb5:1 C5 Ab4:2 | "
         "G4:.5 Bb4 Eb5 G5 Bb5:2 | Ab5:.5 F5 D5 Bb4 F5:2 | Eb5:1 Ab5 C6 Eb6 | D6:1 B5 G5 F5:.5 D5")
FUR_A_CHORDS = "Cm Cm Ab Ab Fm Fm G7 G7"
FUR_CHORDS = " ".join(["Cm Cm Cm Cm", FUR_A_CHORDS, "Eb Bb Ab Ab Eb Bb Ab G7", FUR_A_CHORDS])
FUR_RIFF = [[0, 0, 3, 0, 7, 5, 3, 2], [0, 0, 3, 0, -2, -1]]


def furnace_works():
    s = Song(120, 28 * 4, reverb=0.3)
    p = _bars(prog(FUR_CHORDS), 28)
    for bar, parts in enumerate(p):
        sym = parts[0][2]
        major = not sym[1:].startswith("m") or sym[1:].startswith("maj")
        root = bass_note(sym, 36)
        riff = FUR_RIFF[bar % 2]
        steps = [(e * 0.5, 0.45) for e in range(8)] if len(riff) == 8 else [(e * 0.5, 0.45) for e in range(4)] + [(2, 0.9), (3, 0.9)]
        for (off, dur), semis in zip(steps, riff):
            if semis == 3 and major:
                semis = 4
            s.note("brass", root + 12 + semis, bar * 4 + off, dur, vel=0.75, gain=0.3, pan=-0.2, wet=0.2)
            s.note("synthbass", root + semis, bar * 4 + off, dur, vel=0.8, gain=0.55, wet=0.05)
        if bar < 4:
            drums(s, bar, {"kick": "x...x...x...x...", "clank": "..o...o...o...o."})
        else:
            drums(s, bar, {"kick": "x.....x.x.......", "snare": "....x.......x...", "clank": "..o...o...o...o.",
                           "hat": "x.x.x.x.x.x.x.x."}, scale=0.85)
            if 12 <= bar < 20:
                comp(s, "pad", bar, parts, "x---------------", low=55, vel=0.5, gain=0.1, spread=0.7)
        if bar % 2 == 0:
            s.hit("anvil", bar * 4, vel=0.7, gain=0.3, pan=0.45)
    # Anvils fill the gaps the tune leaves; the pipes let off steam at the end of each section.
    for bar in (5, 7, 25, 27):
        if bar in (5, 25):
            s.hit("anvil", bar * 4 + 2, vel=0.9, gain=0.4, pan=0.5)
            s.hit("anvil", bar * 4 + 3, vel=0.8, gain=0.4, pan=-0.5)
    for bar, beat in ((3, 2), (11, 3), (19, 3), (27, 3)):
        s.hit("steam", bar * 4 + beat, vel=0.8, gain=0.5, pan=-0.5)
    melody(s, "brass", 4, FUR_A, bars=8, vel=0.9, gain=0.5, wide=True)
    melody(s, "brass", 12, FUR_B, bars=8, vel=0.9, gain=0.48, wide=True)
    melody(s, "brass", 20, FUR_A, bars=8, vel=0.9, gain=0.5, wide=True)
    melody(s, "brass", 20, FUR_A, bars=8, vel=0.7, gain=0.25, transpose=-12, pan=0.2)
    return s


# ---------------------------------------------------------------------------------------------
# Eternal Rest Funeral Parlour: a pipe organ getting a bit too jazzy, Bb minor, 104 bpm. It starts on
# the old funeral march, solemn and straight; then a walking bass sneaks in, the brushes follow, the
# organist gives in and swings a minor blues on a jazz organ, catches himself, goes solemn again,
# and can't resist one last lick before the top. 28 bars: solemn (8), sneaking (4), blues (12), solemn (4).
# ---------------------------------------------------------------------------------------------

MARCH = "Bb4:1 Bb4:.75 Bb4:.25 Bb4:1 Db5:.75 C5:.25 | C5:.75 Bb4:.25 Bb4:.75 A4:.25 Bb4:2"
FUN_SOLEMN = (MARCH + " | Db5:1 F5:.75 Eb5:.25 Db5:1 Bb4:1 | C5:1.5 Db5:.5 C5:2 | " + MARCH +
              " | Gb5:1 F5:.75 Eb5:.25 Eb5:1 Db5:.75 C5:.25 | Bb4:3 r:1")
FUN_SNEAK = "Bb4:1 Bb4:.5 Bb4:.5 Bb4:1 Db5:.5 C5:.5 | C5:.5 Bb4:.5 Bb4:.5 A4:.5 Bb4:1 r:1 | Bb4:.5 Db5 E5 F5 Ab5:1 F5 | Ab5:.5 F5 Db5 Bb4 r:2"
FUN_BLUES = ("Eb5:.5 Gb5 Bb5:1 Gb5:.5 Eb5 Db5:1 | Eb5:.5 E5 F5 Gb5 F5:1 Eb5 | "
             "Bb4:1 Bb4:.75 Bb4:.25 Bb4:1 Db5:.75 C5:.25 | Db5:.5 E5 F5 Ab5 Bb5:2 | "
             "Bb5:.5 Ab5 Gb5 E5 F5:1 Db5 | C5:.5 Eb5 A5 C6 Eb6:1 C6 | Db6:.5 Bb5 F5 Db5 Bb4:1 Ab4 | A4:.5 C5 Eb5 F5 Gb5:1 Eb5 | "
             "F5:1.5 Db5:.5 Bb4:1 Ab4:.5 Bb4 | Gb4:.5 Bb4 Db5 Eb5 Gb5:1 Eb5 | F5:.5 Db5 Bb4 Ab4 Bb4 Db5 E5 F5 | Ab5:1 Gb5 F5:2")
FUN_RETURN = MARCH + " | Gb5:1 F5:.75 Eb5:.25 Eb5:1 Db5:.75 C5:.25 | Bb4:3 Db5:.5 E5:.5"
FUN_CHORDS = ("Bbm Bbm Gb F7 Bbm Bbm Ebm,F7 Bbm | Bbm7 Bbm7 Bbm7 Bbm7 | Ebm7 Ebm7 Bbm7 Bbm7 Gb7 F7 Bbm7 F7 Bbm7 Ebm7 Bbm7 F7 | "
              "Bbm Bbm Ebm,F7 Bbm")


def funeral_parlour():
    s = Song(104, 28 * 4, reverb=0.45, swing=0.15)
    p = _bars(prog(FUN_CHORDS), 28)
    walking_bass(s, 8, [parts[0][2] for parts in p[8:24]], low=34, gain=0.85)
    for bar, parts in enumerate(p):
        solemn = bar < 8 or bar >= 24
        if solemn or bar < 12:
            # The pipes hold the chords, with a 16' pedal under them while it is still solemn.
            comp(s, "pipe", bar, parts, "x---", low=53, vel=0.6, gain=0.24, spread=0.5)
            if solemn:
                bassline(s, "pipe", bar, parts, [(0, 4, 0)] if len(parts) == 1 else [(0, 2, 0), (2, 2, 0)], low=41, vel=0.7, gain=0.4)
        else:
            comp(s, "organ", bar, parts, "x--...x-......o-", low=56, vel=0.6, gain=0.22, spread=0.5)
        if 8 <= bar < 12:
            drums(s, bar, {"brush": "....x.......x...", "ride": "o...o.o.o...o.o."}, scale=0.6)
        elif 12 <= bar < 24:
            drums(s, bar, {"ride": "x...x.x.x...x.x.", "brush": "....x.......x...", "kick": "o.......o......."}, scale=0.8)
    for bar in (0, 24):
        s.note("bell", "Bb3", bar * 4, 2, vel=0.6, gain=0.3, pan=-0.3, wet=0.8)
    melody(s, "pipe", 0, FUN_SOLEMN, bars=8, vel=0.8, gain=0.6)
    melody(s, "pipe", 8, FUN_SNEAK, bars=4, vel=0.8, gain=0.6)
    melody(s, "organ", 12, FUN_BLUES, bars=12, vel=0.8, gain=0.62, wide=True)
    melody(s, "pipe", 24, FUN_RETURN, bars=4, vel=0.8, gain=0.6)
    return s


# ---------------------------------------------------------------------------------------------
# The Flashback Cinema, Last Showing: the organ intermission, a slow waltz in Eb, 3/4 at 132 bpm. A
# picture-house organ with a deep tremulant plays the tune over a pedal "oom" and "pah-pah" chords;
# the bells answer its long notes, a clarinet stop takes the sad middle in C minor, and the projector
# clatters on throughout. At the end the reel runs out and the loose film flaps. 48 bars: curtain (4),
# A (16), B in C minor (16), A again with a minor farewell (12).
# ---------------------------------------------------------------------------------------------

CIN_INTRO = "Eb6:1.5 D6:.5 C6:1 | Bb5:3 | C6:1.5 Bb5:.5 Ab5:1 | F5:3"
CIN_A_HEAD = "Bb4:1 Eb5 G5 | Bb5:2 G5:1 | C6:2 Ab5:1 | F5:3 | D5:1 F5 Ab5 | C6:2 Bb5:1 | Ab5:1 G5:.5 F5 D5:1 | Eb5:3"
CIN_A = (CIN_A_HEAD + " | G5:1 Bb5 Db6 | C6:3 | B5:2 Ab5:1 | G5:2 Eb5:1 | "
         "E5:1 G5 Bb5 | Ab5:2 F5:1 | F5:1 Bb5 Ab5 | G5:1 F5 D5")
CIN_B = ("Eb5:2 G5:1 | C6:3 | Ab5:2 C6:1 | Bb5:1 Ab5 F5 | D5:1 F5 B5 | D6:2 B5:1 | C6:1 G5 Eb5 | E5:1 G5 Bb5 | "
         "Ab5:2 F5:1 | D6:2 Ab5:1 | G5:2 Eb5:1 | C6:2 Ab5:1 | F5:2 Ab5:1 | B5:2 D6:1 | Eb6:2 C6:1 | D6:1 C6 Bb5")
CIN_A2 = CIN_A_HEAD + " | B5:2 Ab5:1 | G5:1 F5 Eb5 | Eb5:3 | D5:1 F5 Ab5"
CIN_A_CHORDS = "Eb Eb Fm7 Bb7 Bb7 Fm7 Bb7 Eb"
CIN_CHORDS = " ".join(["Eb Eb Fm7 Bb7", CIN_A_CHORDS, "Eb7 Ab Abm6 Eb C7 Fm7 Bb7 G7",
                       "Cm Cm Fm Fm G7 G7 Cm C7 Fm Bb7 Eb Ab Dm7b5 G7 Cm Bb7", CIN_A_CHORDS, "Abm6 Eb Eb Bb7"])


def flashback_cinema():
    s = Song(132, 48 * 3, reverb=0.42, meter=3)
    p = _bars(prog(CIN_CHORDS, 3), 48)
    for bar, parts in enumerate(p):
        # Oom on the pedals, root and fifth by turns; pah-pah on the organ's lower manual.
        bassline(s, "bass", bar, parts, [(0, 1, 7 if bar % 2 else 0)], low=34, vel=0.85, gain=0.7, wet=0.1)
        bassline(s, "theatre", bar, parts, [(0, 1.5, 7 if bar % 2 else 0)], low=46, vel=0.6, gain=0.22, wet=0.3)
        comp(s, "theatre", bar, parts, "..x-x-", low=55, vel=0.6, gain=0.15, spread=0.6)
        comp(s, "vibes", bar, parts, "x-----", low=67, vel=0.35, gain=0.06, spread=0.7)
        # The projector runs through it all, and the old print crackles.
        drums(s, bar, {"tick": "oooooo", "brush": "x.o.o.", "crackle": "x....."}, scale=0.5)
    # The reel runs out: the loose end of the film flaps round while the organ and bells climb back
    # to the start.
    s.hit("flap", 47 * 3, vel=0.7, gain=0.45, pan=0.4)
    s.hit("flap", 47 * 3 + 1.5, vel=0.5, gain=0.35, pan=0.45)
    s.line("vibes", 47 * 3, mel("D5:1 F5 Ab5", 3)[0], vel=0.55, gain=0.4, pan=-0.3)
    melody(s, "theatre", 0, CIN_INTRO, bars=4, vel=0.75, gain=0.45, wide=True)
    melody(s, "vibes", 0, CIN_INTRO, bars=4, vel=0.45, gain=0.25, pan=0.35)
    at_bar = 4
    for text, count, inst in ((CIN_A, 16, "theatre"), (CIN_B, 16, "reed"), (CIN_A2, 12, "theatre")):
        if inst == "reed":
            melody(s, "reed", at_bar, text, bars=count, vel=0.8, gain=0.5, pan=-0.15)
            melody(s, "theatre", at_bar, text, bars=count, vel=0.6, gain=0.25, transpose=-12, pan=0.2)
        else:
            melody(s, "theatre", at_bar, text, bars=count, vel=0.8, gain=0.55, wide=True)
        # The bells answer every note the tune holds for a whole bar.
        for k, tokens in enumerate(b.split() for b in text.split("|")):
            if len(tokens) == 1 and tokens[0].endswith(":3") and not tokens[0].startswith("r"):
                bar = at_bar + k
                notes, _ = chord(p[bar][0][2], 74)
                for j, m in enumerate(notes[:3]):
                    s.note("vibes", m, bar * 3 + 1 + j * 0.5, 0.5, vel=0.5, gain=0.35, pan=0.4)
        at_bar += count
    return s


# ---------------------------------------------------------------------------------------------
# The Last Resort Cruise: the lounge band, a cha-cha in A, 120 bpm. A muted trumpet fronts it, the
# vibes take the second chorus, a nylon guitar and congas keep the cha-cha going, and the ship's horn
# blows as it loops. 28 bars: horn (2), A (8), A on vibes (8), B (8), tag (2).
# ---------------------------------------------------------------------------------------------

CRU_INTRO = "E5:.5 A5 C#6:1 r:2 | D6:.5 C#6 B5:1 r:2"
CRU_A = ("C#5:1 E5:.5 A5 G#5:1 E5 | D5:.5 F#5 B5:1 A5:.5 F#5 D5:1 | E5:.5 G#5 C#6:1 B5:.5 G#5 E5:1 | A#4:.5 C#5 F#5:1 E5 r | "
         "D5:1 F#5:.5 A5 C#6:1 B5 | G#5:.5 F#5 E5 D5 B4:1 E5 | C#5:1.5 E5:.5 A5:2 | r:2 B4:.5 C#5 D5 E5")
CRU_B = ("F#5:1.5 E5:.5 D5:1 A4 | F5:1.5 E5:.5 D5:1 B4 | E5:1 G#5 B5:1.5 A5:.5 | A#5:1 F#5 C#5:2 | "
         "D5:.5 F#5 A5 C#6 B5:1 A5 | G#5:.5 B5 D6 E6 D6:1 B5 | E5:1 C#5 A#4 C#5 | B4:1 D5 G#5 B5")
CRU_TAG = "A5:2 r:2 | r:4"
CRU_A_CHORDS = "Amaj7 Bm7 C#m7 F#7 Bm7 E7 Amaj7 E7"
CRU_CHORDS = " ".join(["Amaj7 E7", CRU_A_CHORDS, CRU_A_CHORDS, "Dmaj7 Dm6 C#m7 F#7 Bm7 E7 C#m7,F#7 Bm7,E7", "Amaj7 E7"])
CHA_BASS = [(0, 1.5, 0), (1.5, 0.5, 7), (2, 1, 0), (3, 0.5, 7), (3.5, 0.5, 7)]


def last_resort_cruise():
    s = Song(120, 28 * 4, reverb=0.32)
    p = _bars(prog(CRU_CHORDS), 28)
    for bar, parts in enumerate(p):
        bassline(s, "bass", bar, parts, CHA_BASS, low=33, vel=0.85, gain=0.8)
        comp(s, "guitar", bar, parts, "..x-..x-..x-x.x.", low=55, vel=0.65, gain=0.24, spread=0.5)
        drums(s, bar, {"conga": "....x..o....x.o.", "bongo": "x.o...o.x.o...o.", "woodblock": "o...o...o...o...",
                       "shaker": "x.o.x.o.x.o.x.o.", "kick": "x.......x......."}, scale=0.7)
    # The ship's horn as it loops, and two toots before the band starts.
    for m in ("A1", "E2"):
        s.note("brass", m, 27 * 4, 2.5, vel=0.8, gain=0.45, wet=0.9)
        s.note("brass", m, 1 * 4 + 2, 0.4, vel=0.7, gain=0.35, wet=0.9)
        s.note("brass", m, 1 * 4 + 3, 0.4, vel=0.7, gain=0.35, wet=0.9)
    s.hit("steam", 0, vel=0.4, gain=0.3, pan=-0.6, wet=0.9)
    s.hit("steam", 26 * 4 + 2, vel=0.4, gain=0.3, pan=0.6, wet=0.9)
    melody(s, "vibes", 0, CRU_INTRO, bars=2, vel=0.7, gain=0.55, pan=0.3)
    melody(s, "brass", 2, CRU_A, bars=8, vel=0.85, gain=0.55, pan=-0.1)
    melody(s, "vibes", 10, CRU_A, bars=8, vel=0.8, gain=0.6, pan=0.2)
    for bar in (13, 17):
        s.line("brass", bar * 4 + 3, mel("C#6:.5 A#5", 1)[0], vel=0.7, gain=0.4, pan=-0.35)
    melody(s, "brass", 18, CRU_B, bars=8, vel=0.85, gain=0.52, wide=True)
    melody(s, "brass", 26, CRU_TAG, bars=2, vel=0.85, gain=0.55, pan=-0.1)
    return s


# ---------------------------------------------------------------------------------------------
# A piano's left hand, shared with the ending.
# ---------------------------------------------------------------------------------------------


def piano_left_hand(s, bar, parts, low=36, vel=0.45, gain=0.24):
    """Broken chords in eighths: the root low, then up through the chord and back."""
    for e in range(2 * s.meter):
        sym = at(parts, e * 0.5)
        root = bass_note(sym, low)
        tones, _ = chord(sym, root + 12)
        seq = [root, root + 7] + tones[:3] + [tones[1], root + 7, tones[0]]
        s.note("piano", seq[e % len(seq)], bar * s.meter + e * 0.5, 1.2 if e == 0 else 0.9, vel=vel * (1.1 if e == 0 else 1.0),
               gain=gain, pan=-0.25)


# ---------------------------------------------------------------------------------------------
# Beyond Calling Psychic Hotline, Night Shift: a theremin and tremolo in B minor, 84 bpm. The theremin
# glides from note to note over strings pulsing in triplets and a creeping minor line in the chords;
# in the middle, in D, a guitar tremolo-picks the chords while the lava lamps bloop. A crystal ball
# shimmers at each section, and the phone rings: once when the theremin pauses, twice at the top.
# 24 bars: the call (2), A (8), B in D (8), A again (6).
# ---------------------------------------------------------------------------------------------

HOT_INTRO = "r:2 B5:2 | A#5:2 F#5:2"
HOT_A_HEAD = "F#5:3 B4:1 | D5:2 A#5:2 | A5:3 F#5:1"
HOT_A = HOT_A_HEAD + " | G#5:2 F#5:1 D5:1 | B5:3 F#5:1 | G5:2 E5:1 D5:1 | E5:2 A#4:2 | B4:3 r:1"
HOT_B = ("A5:2 F#5:1 C#6:1 | D6:3 B5:1 | G5:2 B5:1 D6:1 | C#6:3 A5:1 | "
         "F#5:2 A5:1 D6:1 | D#6:3 B5:1 | E6:2 D6:1 B5:1 | D6:2 C#6:2")
HOT_A2 = HOT_A_HEAD + " | G#5:2 B5:2 | B5:2 F5:2 | E5:1 C#5 A#4:2"
HOT_LINE = "Bm Bmmaj7 Bm7 Bm6"
HOT_CHORDS = " ".join(["Bm F#7", HOT_LINE, "Gmaj7 Em7 C#m7b5,F#7 Bm", "Dmaj7 Bm7 Em7 A7 Dmaj7 B7 Em7 Gm6,F#7",
                       HOT_LINE, "G7 F#7"])


def _crystal_ball(s, bar, parts):
    """A shimmer up the chord on the music box, as the ball clouds over."""
    notes, _ = chord(parts[0][2], 76)
    for k, m in enumerate(notes + [n + 12 for n in notes]):
        s.note("musicbox", m, bar * 4 + k * 0.125, 0.5, vel=0.35 + 0.04 * k, gain=0.3, pan=-0.5 + 0.13 * k, wet=0.9)


def seance_hotline():
    s = Song(84, 24 * 4, reverb=0.45, tremolo={"pad": (3, 0.8)})
    p = _bars(prog(HOT_CHORDS), 24)
    for bar, parts in enumerate(p):
        middle = 10 <= bar < 18
        # The strings pulse in triplets under everything; vibes ring the chord on the one.
        comp(s, "pad", bar, parts, "x---------------", low=52, vel=0.55, gain=0.16 if not middle else 0.11, spread=0.8)
        if middle:
            # A guitar picks each chord as fast as it can: triplet sixteenths.
            comp(s, "guitar", bar, parts, "xo" * 12, low=55, vel=0.5, gain=0.12, spread=0.5, drop=3)
            if bar % 2:
                for off, pan in ((1.5, -0.5), (3.25, 0.4)):
                    s.hit("bloop", bar * 4 + off, vel=0.6, gain=0.4, pan=pan, wet=0.7)
        else:
            comp(s, "vibes", bar, parts, "x-------x-------", low=60, vel=0.4, gain=0.12, spread=0.6)
        bassline(s, "bass", bar, parts, [(0, 1.4, 0), (1.5, 0.4, 0), (2, 1.4, 7), (3.5, 0.4, 12)], low=35, vel=0.8, gain=0.7)
        if bar >= 2:
            drums(s, bar, {"brush": "x...o...x...o...", "rim": "....o.......o...", "kick": "o.......o......."}, scale=0.6)
    for bar in (0, 10, 18):
        _crystal_ball(s, bar, p[bar])
    # The phone: two rings into the top of the loop, and one when the theremin first stops.
    s.hit("ring", 0, vel=0.8, gain=0.35, pan=0.5)
    s.hit("ring", 23 * 4 + 2, vel=0.8, gain=0.35, pan=0.5)
    s.hit("ring", 9 * 4 + 3, vel=0.6, gain=0.25, pan=0.55)
    melody(s, "theremin", 0, HOT_INTRO, bars=2, vel=0.6, gain=0.4, pan=-0.1, glide=0.12, legato=1.0)
    melody(s, "theremin", 2, HOT_A, bars=8, vel=0.85, gain=0.6, pan=-0.1, glide=0.12, legato=1.0)
    melody(s, "theremin", 10, HOT_B, bars=8, vel=0.85, gain=0.55, wide=True, glide=0.15, legato=1.0)
    melody(s, "theremin", 18, HOT_A2, bars=6, vel=0.85, gain=0.6, pan=-0.1, glide=0.12, legato=1.0)
    return s


# ---------------------------------------------------------------------------------------------
# Departures, Terminal Zero: airport-lounge synth in E, 116 bpm. A soft glassy lead, a pad, a little
# sequencer arpeggio and a gentle beat. The public-address chime opens each section with the hold
# theme's first notes, the departures board clacks over, and at the end the chimes play the whole
# opening of the hold theme as an announcement. 32 bars: chime (2), A, B, A, the announcement (6).
# ---------------------------------------------------------------------------------------------

TERM_A = ("G#5:1.5 B5:.5 E5:1 F#5 | G#5:.5 E5 C#5:1 r:2 | A5:1.5 C#6:.5 E5:1 F#5 | D#5:.5 F#5 B5:1 r:2 | "
          "G#5:1.5 B5:.5 E6:1 D#6:.5 B5 | G#5:1 F#5:.5 D#5 B4:2 | C#5:.5 E5 A5 C#6 B5:1 A5 | F#5:2 D#5:1 B4")
TERM_B = ("E5:1 G#5 C#6:2 | B5:1.5 G#5:.5 D#5:2 | C#6:1 B5 A5 E5 | G#5:4 | "
          "A5:1 F#5 C#5 E5 | D#5:1 F#5 B5 D#6 | E6:1.5 C#6:.5 A5:1 G#5 | F#5:2 r:2")
TERM_A_CHORDS = "Emaj7 C#m7 Amaj7 B7 Emaj7 G#m7 Amaj7 B7"
TERM_CHORDS = " ".join(["Emaj7 B7", TERM_A_CHORDS, "C#m7 G#m7 Amaj7 Emaj7 F#m7 G#m7 Amaj7 B7", TERM_A_CHORDS,
                        "Amaj7 B7 Emaj7 C#m7 Amaj7 B7"])


def _chime(s, beat, notes=("B4", "G#4", "B4", "E5"), step=0.75):
    for k, n in enumerate(notes):
        s.note("bell", n, beat + k * step, 1.5, vel=0.55, gain=0.45, pan=0.25, wet=0.9)


def terminal_zero():
    s = Song(116, 32 * 4, reverb=0.4)
    p = _bars(prog(TERM_CHORDS), 32)
    for bar, parts in enumerate(p):
        edge = bar < 2 or bar >= 26
        comp(s, "pad", bar, parts, "x---------------", low=52, vel=0.55, gain=0.13, spread=0.8)
        arp(s, "thin", bar, parts, step=0.25, low=64, octaves=2, vel=0.45, gain=0.07, pan=0.6, wet=0.7)
        if edge:
            drums(s, bar, {"hat": "o.o.o.o.o.o.o.o."}, scale=0.6)
            bassline(s, "synthbass", bar, parts, [(0, 1.8, 0), (2, 1.8, 7)], low=36, vel=0.7, gain=0.45)
        else:
            drums(s, bar, {"kick": "x.......x.......", "clap": "....x.......x...", "hat": "o.o.o.o.o.o.o.o."}, scale=0.75)
            bassline(s, "synthbass", bar, parts, [(0, 0.75, 0), (1.5, 0.5, 0), (2, 0.75, 7), (3.5, 0.5, 12)], low=36, vel=0.8, gain=0.55)
    _chime(s, 0)
    _chime(s, 17 * 4 + 2, ("B5", "G#5", "B5", "E6"), 0.5)
    for bar, beat in ((1, 2), (9, 3), (25, 2), (31, 0)):
        s.hit("flap", bar * 4 + beat, vel=0.7, gain=0.45, pan=0.4)
    melody(s, "glass", 2, TERM_A, bars=8, vel=0.85, gain=0.6, wide=True)
    melody(s, "glass", 10, TERM_B, bars=8, vel=0.85, gain=0.58, wide=True)
    melody(s, "glass", 18, TERM_A, bars=8, vel=0.85, gain=0.6, wide=True)
    # The announcement: the hold theme's opening, on the chimes.
    s.line("bell", 26 * 4, HOLD_A1[:10], vel=0.55, gain=0.45, transpose=-1, pan=0.2)
    s.line("vibes", 28 * 4, HOLD_A1[:10], vel=0.5, gain=0.4, transpose=-1, pan=-0.2)
    return s


# ---------------------------------------------------------------------------------------------
# Head Office, Eternity Incorporated: corporate hold music that turns sinister, C, 100 bpm. It opens
# as bland hold music (the hold theme itself, on a flute, in C). Then the tune slides into minor and a
# theremin creeps in under it; then a choir sings the theme slowed down over pipe organ while the
# vibes keep up the cheerful comping; then only a clock ticks, until the chime and the bland bossa
# snap back as if nothing happened. 28 bars: A (8), B (8), C (8), D (4).
# ---------------------------------------------------------------------------------------------

HO_B = ("G4:.5 Eb4 G4 C5:1.5 B4:.5 Ab4 | B4:.5 G4 Eb4:2 r:1 | Ab4:.5 F4 Ab4 D5:1.5 C5:.5 B4 | C5:.5 Ab4 B4:2 r:1 | "
        "C5:.5 Ab4 C5 Eb5:1.5 D5:.5 C5 | D5:.5 C5 Ab4:2 r:1 | F4:.5 Ab4 B4 D5:1.5 C5:.5 B4 | B4:3 r:1")
HO_C = "G4:2 Eb4 | G4:2 C5 | B4:2 Ab4 | B4:4 | G4:2 Eb4 | G4:2 C5 | Db5:2 F5 | D5:2 B4"
HO_CHORDS = "Cmaj9 Am9 Dm9 G13 Cmaj9 Am9 Dm9 G13 | Cm Cm Fm6 G7 Ab Fm Dm7b5 G7 | Cm Abmaj7 G7b9 G7 Cm Abmaj7 Db G7 | Cm G7 Cmaj9 G13"


def head_office():
    s = Song(100, 28 * 4, reverb=0.36, swing=0.08)
    p = _bars(prog(HO_CHORDS), 28)
    for bar, parts in enumerate(p):
        bland, creep, dark = bar < 8 or bar >= 26, 8 <= bar < 16, 16 <= bar < 24
        if bland or creep:
            comp(s, "epiano", bar, parts, BOSSA[bar % 2], low=55, vel=0.5, gain=0.28, spread=0.5)
            bassline(s, "bass", bar, parts, BOSSA_BASS, low=36, vel=0.8, gain=0.8)
            drums(s, bar, {"rim": "x.....x.....x..." if bar % 2 == 0 else "....x...x.......", "shaker": "o.x.o.x.o.x.o.x.",
                           "kick": "x.........o....."}, scale=0.65)
        if creep:
            s.note("pad", bass_note(parts[0][2], 36), bar * 4, 4, vel=0.6, gain=0.14)
        if dark:
            comp(s, "vibes", bar, parts, BOSSA[bar % 2], low=60, vel=0.4, gain=0.16, spread=0.6)
            comp(s, "pipe", bar, parts, "x---------------", low=50, vel=0.6, gain=0.2, spread=0.5)
            for e in range(8):
                s.note("synthbass", bass_note(parts[0][2], 24) + (12 if e % 2 else 0), bar * 4 + e * 0.5, 0.4, vel=0.75, gain=0.45, wet=0.05)
            drums(s, bar, {"kick": "x.......x.......", "tom": "............x...", "tick": "x...x...x...x..."}, scale=0.8)
        if bar in (24, 25):
            drums(s, bar, {"tick": "x...x...x...x..."}, scale=0.9)
            s.note("pad", bass_note(parts[0][2], 36), bar * 4, 4, vel=0.5, gain=0.1)
            s.note("choir", "C4" if bar == 24 else "B3", bar * 4, 3.5, vel=0.4, gain=0.25)
    # "Your call is important to us."
    for i, n in enumerate(["E6", "C6", "G5"]):
        s.note("bell", n, 27 * 4 + 1 + i * 0.5, 1, vel=0.45, gain=0.4, pan=0.3)
    s.line("flute", 0, HOLD_A1 + HOLD_A2, vel=0.8, gain=0.62, transpose=-5, bars=8)
    s.line("vibes", 0, HOLD_A1 + HOLD_A2, vel=0.45, gain=0.25, transpose=7, pan=0.35, bars=8)
    melody(s, "flute", 8, HO_B, bars=8, vel=0.8, gain=0.6, wide=True)
    melody(s, "theremin", 8, HO_B, bars=8, vel=0.6, gain=0.3, transpose=-12, pan=-0.3)
    melody(s, "choir", 16, HO_C, bars=8, vel=0.75, gain=0.55)
    melody(s, "pipe", 16, HO_C, bars=8, vel=0.6, gain=0.25, transpose=-12)
    return s
