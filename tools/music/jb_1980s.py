"""Harold's Jukebox, depth 4: the 1980s, Harold in his forties. The Last Resort Cruise, the
Psychic Hotline's night shift, and the depth-4 floor boss."""
from band import Band, beat, roll
from kit import melody, prog, comp, bassline, arp
from jb_theme import THEME_A, THEME_A1, MOTIF, minor

INFO = {
    "last_resort_cruise": dict(key="D major", bpm=100, meter=4, bars=32,
                               about="Last Resort Cruise: breezy yacht-deck pop, electric piano and chorused guitar, an alto sax on the hold theme, the ship's horn."),
    "seance_hotline": dict(key="B minor", bpm=110, meter=4, bars=32,
                           about="Psychic Hotline, night shift: sequenced synth arpeggios and eerie pads, gated toms, the phone ringing, the motif whistled in minor."),
    "boss_depth_4": dict(key="E minor", bpm=160, meter=4, bars=32,
                         about="Depth 4 boss: driving synth rock, distortion guitar and octave synth bass, the hold theme in minor on a soaring lead."),
}


def _bars(text, count):
    p = prog(text)
    assert len(p) == count, "progression has %d bars, not %d" % (len(p), count)
    return p


OCTAVES = [(e * 0.5, 0.42, 12 if e % 2 else 0) for e in range(8)]


# ---------------------------------------------------------------------------------------------
# The Last Resort Cruise: deck music on the way out to sea. Smooth and breezy, D major, 100 bpm,
# straight sixteenths. Chorused electric piano and clean guitar, a fretless bass, a shaker, warm
# pads; an alto sax sings the hold theme, Harold whistles it later. The ship's horn opens.
# 32 bars: horn and keys (4), theme on sax (8), the deck chorus (8), theme on whistle with sax
# fills (8), a turnaround back to the top (4).
# ---------------------------------------------------------------------------------------------

CRUISE_A_CHORDS = "Dmaj9 Bm9 Em9 A13 Dmaj9 Bm9 Em9 A13"
CRUISE_B_CHORDS = "Gmaj9 A6 F#m7 Bm9 Em9 A7sus4 Dmaj9 A7sus4"
CRUISE_CHORDS = " ".join(["Dmaj9 Gmaj9 Em9 A7sus4", CRUISE_A_CHORDS, CRUISE_B_CHORDS, CRUISE_A_CHORDS, "Gmaj9 F#m7 Em9 A7sus4"])
CRUISE_HOOK = ("B4:.5 D5 F#5:1 E5:.5 D5 B4:1 | C#5:.5 E5 A5:1.5 F#5:.5 E5:1 | E5:.5 C#5 A4:1 r:.5 C#5 E5 F#5 | D5:3 r:1 | "
               "G5:.5 F#5 E5 D5 B4:1 G4 | A4:.5 B4 D5 E5 A5:2 | F#5:1.5 E5:.5 D5:1 C#5 | E5:2 r:2")
CRUISE_TURN = "B5:.5 A5 F#5 D5 E5:2 | C#5:.5 E5 A5:1.5 F#5:.5 E5:1 | G5:.5 F#5 E5 D5 B4:2 | A4:.5 B4 D5 E5 A5:2"
CRUISE_BASS = [(0, 1.25, 0), (1.5, 0.5, 0), (2, 0.75, 7), (2.75, 0.5, 12), (3.5, 0.5, 7)]
DECK_BEAT = {"kick": "x.....x...x.....", "snare": "....x.......x...", "hat": "x.x.x.x.x.x.x.x.", "shaker": "gogogogogogogogo"}


def last_resort_cruise():
    s = Band(100, 32, loudness=-17.5, room=0.6)
    s.part("keys", "epiano", level=0.58, pan=-0.15, reverb=0.4, chorus=0.55)
    s.part("gtr", "cleangtr", level=0.45, pan=0.35, reverb=0.35, chorus=0.65)
    s.part("bass", "fretless", level=0.7, reverb=0.12)
    s.part("sax", "altosax", level=0.6, pan=0.05, reverb=0.45)
    s.part("whistle", "whistle", level=0.52, reverb=0.5)
    s.part("pad", "warmpad", level=0.36, reverb=0.6)
    s.part("horn", "tuba", level=0.62, pan=-0.1, reverb=0.7)
    s.kit("room", level=0.72)
    p = _bars(CRUISE_CHORDS, 32)
    for bar, parts in enumerate(p):
        intro, a1, b, a2, turn = bar < 4, 4 <= bar < 12, 12 <= bar < 20, 20 <= bar < 28, bar >= 28
        comp(s, "keys", bar, parts, "x-.x-.x---.x-..." if not intro else "x---------------", low=57, vel=0.5, spread=0.2)
        if bar >= 2:
            bassline(s, "bass", bar, parts, CRUISE_BASS if not intro else [(0, 3.8, 0)], low=33, vel=0.75)
        if intro:
            beat(s, bar, {"shaker": "gogogogogogogogo"} if bar >= 2 else {}, vel=0.7)
            comp(s, "pad", bar, parts, "x---------------", low=55, vel=0.45, spread=0.2)
        else:
            beat(s, bar, DECK_BEAT, vel=0.78)
        if a1 or a2 or turn:
            comp(s, "gtr", bar, parts, "..x...x...x...x.", low=62, vel=0.42, spread=0.2)
        if b:
            arp(s, "gtr", bar, parts, step=0.5, low=62, octaves=2, vel=0.42, pan=0.0)
        if b or a2:
            comp(s, "pad", bar, parts, "x---------------", low=55, vel=0.48, spread=0.2)
        if bar in (11, 19, 27):
            roll(s, bar, start=3.0, count=4, kind="tom", low=0.4, high=0.75)
        if bar in (4, 12, 20):
            s.hit("crash", bar * 4, vel=0.5)
    # The ship's horn: one long blast and a short one, as she leaves port.
    for start, beats in ((0.0, 2.2), (2.75, 0.9)):
        for m in ("D2", "A2"):
            s.note("horn", m, start, beats, vel=0.85, legato=1.0)
    melody(s, "sax", 4, THEME_A, bars=8, vel=0.75, transpose=-3)
    melody(s, "sax", 12, CRUISE_HOOK, bars=8, vel=0.8)
    melody(s, "whistle", 15, "r:2 F#5:.5 A5 B5:1", bars=1, vel=0.6, transpose=12)
    melody(s, "whistle", 19, "r:2 E5:.5 F#5 A5:1", bars=1, vel=0.6, transpose=12)
    melody(s, "whistle", 20, THEME_A, bars=8, vel=0.78, transpose=9)
    for bar, lick in ((21, "r:3 F#5:.25 A5 B5:.5"), (23, "r:3 E5:.25 F#5 A5:.5"), (25, "r:3 F#5:.25 A5 D6:.5")):
        melody(s, "sax", bar, lick, bars=1, vel=0.6)
    melody(s, "sax", 28, CRUISE_TURN, bars=4, vel=0.75)
    return s


# ---------------------------------------------------------------------------------------------
# Beyond Calling Psychic Hotline, Night Shift: the line that is always open. Eighties synth horror,
# B minor, 110 bpm. A sequenced sawtooth arpeggio in sixteenths over an octave synth bass, halo and
# choir pads, an electronic kit with big gated toms. The phone rings; Harold whistles the hold
# theme in minor down the line. 32 bars: ring and sequence (4), A with the minor theme whistled (8),
# B with the lead and choir (8), a break where the phone rings again (4), A again, fuller (8).
# ---------------------------------------------------------------------------------------------

HOTLINE_A_CHORDS = "Bm G Em A Bm G C#m7b5 F#"
HOTLINE_CHORDS = " ".join(["Bm Bm G F#", HOTLINE_A_CHORDS, "Em Bm G F# Em Bm C F#7", "Bm Bm G F#", HOTLINE_A_CHORDS])
HOTLINE_ANSWER = "F#5:1 E5:.5 D5 C#5:1 B4 | D5:1.5 E5:.5 G5:2 | E5:.5 D5 C#5 E5 G5:1 E5 | F#5:2 A#4:2"
HOTLINE_B = ("B4:1.5 E5:.5 G5:1 F#5 | F#5:1.5 D5:.5 B4:2 | D5:1.5 G5:.5 B5:1 A5 | A#5:3 C#6:1 | "
             "B5:1.5 G5:.5 E5:1 G5 | F#5:1 D5 B4 D5 | E5:1.5 G5:.5 C6:1 B5 | A#5:2 E5:1 C#5")
HOTLINE_MOTIF = minor(MOTIF)  # in F minor; played six semitones up, in B minor
HOTLINE_BREAK = HOTLINE_MOTIF + " | A5:.5 F#5 D5:2 r:1 | " + HOTLINE_MOTIF + " | A#5:.5 F#5 C#5:2 r:1"
NIGHT_BEAT = {"kick": "x.......x.x.....", "snare": "....x.......x...", "hat": "x.x.x.x.x.x.x.x."}


def _ring(s, bar):
    """The hotline's phone: two rings."""
    for k in range(2):
        s.note("phone", "C5", bar * 4 + k * 1.5, 1.1, vel=0.75, legato=1.0)


def seance_hotline():
    s = Band(110, 32, loudness=-18.0, room=0.75)
    s.part("seq", "sawlead", level=0.34, reverb=0.35)
    s.part("bass", "synthbass", level=0.66, reverb=0.1)
    s.part("pad", "halopad", level=0.4, reverb=0.7)
    s.part("choir", "choirpad", level=0.38, reverb=0.75)
    s.part("lead", "voicelead", level=0.5, pan=0.1, reverb=0.6)
    s.part("square", "squarelead", level=0.3, pan=-0.3, reverb=0.5)
    s.part("whistle", "whistle", level=0.5, reverb=0.8)
    s.part("phone", "phone", level=0.42, pan=0.45, reverb=0.4)
    s.kit("electronic", level=0.75)
    p = _bars(HOTLINE_CHORDS, 32)
    for bar, parts in enumerate(p):
        intro, a1, b, brk, a2 = bar < 4, 4 <= bar < 12, 12 <= bar < 20, 20 <= bar < 24, bar >= 24
        arp(s, "seq", bar, parts, step=0.25, low=59, octaves=2, vel=0.5 if not brk else 0.38, pan=0.0)
        comp(s, "pad", bar, parts, "x---------------", low=50, vel=0.45, spread=0.2)
        if intro:
            beat(s, bar, {"hat": "o.g.o.g.o.g.o.g.", "kick": "x..............." if bar < 2 else "x.......x......."}, vel=0.75)
            bassline(s, "bass", bar, parts, [(0, 1.8, 0), (2, 1.8, 0)] if bar < 2 else OCTAVES, low=35, vel=0.72)
        elif brk:
            beat(s, bar, {"kick": "o..............."}, vel=0.7)
            bassline(s, "bass", bar, parts, [(0, 1.8, 0), (2, 1.8, 0)], low=35, vel=0.6)
        else:
            bassline(s, "bass", bar, parts, OCTAVES, low=35, vel=0.75)
            beat(s, bar, NIGHT_BEAT, vel=0.78)
        if b:
            comp(s, "choir", bar, parts, "x-------x-------", low=54, vel=0.5, spread=0.2)
            # Big gated toms answer the backbeat; the bar that ends in a roll leaves them to it.
            toms = {"tom_lo": "........x......."} if bar == 19 else {"tom_lo": "........x.......", "tom": "............x.x.", "tom_floor": "..............x."}
            beat(s, bar, toms, vel=0.85)
        if a2:
            beat(s, bar, {"openhat": "..o...o...o...o."}, vel=0.6)
        if bar in (11, 19, 31):
            roll(s, bar, start=2.0, count=8, kind="tom_hi", low=0.3, high=0.68)
        if bar in (4, 12, 24):
            s.hit("crash", bar * 4, vel=0.55)
    _ring(s, 0)
    _ring(s, 20)
    # The theme's first half, turned minor and moved to B, whistled down a bad line; the lead answers.
    melody(s, "whistle", 4, minor(THEME_A1), bars=4, vel=0.72, transpose=6)
    melody(s, "lead", 8, HOTLINE_ANSWER, bars=4, vel=0.7)
    melody(s, "lead", 12, HOTLINE_B, bars=8, vel=0.78)
    melody(s, "whistle", 20, HOTLINE_BREAK, bars=4, vel=0.68, transpose=6)
    melody(s, "whistle", 24, minor(THEME_A1), bars=4, vel=0.75, transpose=6)
    melody(s, "square", 24, minor(THEME_A1), bars=4, vel=0.55, transpose=-6)
    melody(s, "lead", 28, HOTLINE_ANSWER, bars=4, vel=0.75)
    melody(s, "square", 28, HOTLINE_ANSWER, bars=4, vel=0.5, transpose=-12)
    return s


# ---------------------------------------------------------------------------------------------
# Depth 4 boss: a driving synth-rock fight, E minor, 160 bpm. Octave synth bass, chugging power
# chords, synth-brass stabs and a power kit; the hold theme in minor on a soaring saw lead, and a
# distortion guitar doubling it the second time. 32 bars: riff (4), theme (8), the climb (8),
# theme an octave up with guitar (8), tag (4).
# ---------------------------------------------------------------------------------------------

BOSS4_A_CHORDS = "Em G D7 C Em C Am,G Bm"
BOSS4_CHORDS = " ".join(["E5 E5 C5 B5", BOSS4_A_CHORDS, "C D Em Em C D B7 B7", BOSS4_A_CHORDS, "C D B7 B7"])
BOSS4_CLIMB = ("E5:.5 G5 C6 B5 G5:1 E5 | F#5:.5 A5 D6 C6 A5:1 F#5 | G5:.5 B5 E6 D6 B5 G5 E5 G5 | B5:3 r:1 | "
               "C6:.5 B5 G5 E5 C6:1 E6 | D6:.5 C6 A5 F#5 D6:1 F#6 | D#6:1 B5:.5 F#5 A5:1 B5 | F#5:.5 A5 B5 D#6 F#6:2")
BOSS4_TAG = "E6:1 D6 B5 G5 | F#6:1 E6 D6 A5 | D#6:.5 B5 F#5 B5 D#6 F#6 A6 B6 | B6:2 r:2"
DRIVE = {"kick": "x.x.x.x.x.x.x.x.", "snare": "....x.......x..x", "hat": "x.x.x.x.x.x.x.x."}
ROCK = {"kick": "x.x...x.x.x...x.", "snare": "....x.......x...", "hat": "x.x.x.x.x.x.x.x."}


def boss_depth_4():
    s = Band(160, 32, loudness=-16.0, room=0.45)
    s.part("lead", "sawlead", level=0.55, pan=0.05, reverb=0.4)
    s.part("gtrlead", "overdrive", level=0.5, pan=-0.2, reverb=0.35)
    s.part("gtr", "distortion", level=0.48, pan=0.35, reverb=0.2)
    s.part("brass", "synthbrass", level=0.48, pan=-0.3, reverb=0.35)
    s.part("bass", "synthbass", level=0.72, reverb=0.08)
    s.part("pad", "synthstrings", level=0.36, reverb=0.55)
    s.kit("power", level=0.82)
    p = _bars(BOSS4_CHORDS, 32)
    for bar, parts in enumerate(p):
        intro, a1, b, a2, tag = bar < 4, 4 <= bar < 12, 12 <= bar < 20, 20 <= bar < 28, bar >= 28
        bassline(s, "bass", bar, parts, OCTAVES, low=28, vel=0.85)
        comp(s, "gtr", bar, parts, "x.x..x.x..x.x.x." if (intro or b or tag) else "x..x..x...x.....",
             low=40, vel=0.6, spread=0.2, drop=2)
        beat(s, bar, DRIVE if (intro or b) else ROCK, vel=0.85)
        if a1 or a2:
            comp(s, "pad", bar, parts, "x---------------", low=52, vel=0.5, spread=0.2)
        if b or tag:
            comp(s, "brass", bar, parts, "x..x..x...x.....", low=55, vel=0.65, spread=0.2)
        if a2:
            comp(s, "brass", bar, parts, "x-..............", low=55, vel=0.55, spread=0.2)
        if bar in (3, 11, 19, 27):
            roll(s, bar, start=2.0, count=8, kind="tom", low=0.4, high=0.9)
        if bar in (4, 12, 20, 28):
            s.hit("crash", bar * 4, vel=0.7)
    roll(s, 31, start=2.0, count=8, kind="snare", low=0.4, high=0.9)
    melody(s, "lead", 4, minor(THEME_A), bars=8, vel=0.8, transpose=-1)
    melody(s, "lead", 12, BOSS4_CLIMB, bars=8, vel=0.82)
    melody(s, "brass", 12, BOSS4_CLIMB, bars=8, vel=0.45, transpose=-12)
    melody(s, "lead", 20, minor(THEME_A), bars=8, vel=0.85, transpose=11)
    melody(s, "gtrlead", 20, minor(THEME_A), bars=8, vel=0.8, transpose=-1)
    melody(s, "lead", 28, BOSS4_TAG, bars=4, vel=0.85)
    melody(s, "gtrlead", 28, BOSS4_TAG, bars=4, vel=0.7, transpose=-12)
    return s
