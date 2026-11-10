"""The middle paths, each its own piece: Sunset Shores, the Furnace Works, the Funeral Parlour and the
Flashback Cinema. Each keeps its path's old idea and joke, with new tunes and real instruments."""
from band import Band, beat, roll
from kit import melody, prog, comp, bassline, arp
from jb_theme import walking  # generic helpers only; also adds the extra chord qualities

INFO = {
    "sunset_shores": dict(key="Eb major", bpm=92, meter=4, bars=32,
                          about="Sunset Shores: the house organ's tea-dance foxtrot by the sea, a flute and an accordion, waves and the bingo cage."),
    "furnace_works": dict(key="E minor", bpm=126, meter=4, bars=36,
                          about="Furnace Works: a staccato low-brass machine riff, horn and trumpet over it, clanks, anvils and steam."),
    "funeral_parlour": dict(key="G minor", bpm=100, meter=4, bars=32,
                            about="Funeral Parlour: a solemn pipe-organ march that slips into a shuffling minor blues on a jazz organ, then catches itself."),
    "flashback_cinema": dict(key="F major (B in D minor)", bpm=138, meter=3, bars=56,
                             about="Flashback Cinema: the picture-house organ's intermission waltz, bells, harp and a clarinet; the projector clicks and the reel runs out."),
}


def _bars(text, count, meter=4):
    p = prog(text, meter)
    assert len(p) == count, "progression has %d bars, not %d" % (len(p), count)
    return p


TWO_FEEL = [(0, 1.8, 0), (2, 1.8, 7)]


# ---------------------------------------------------------------------------------------------
# Sunset Shores Eternal Care: the tea dance in the lounge with the sea outside. Eb major, 92 bpm, a
# gentle swing. The house organ leads the foxtrot over nylon guitar on 2 and 4, brushes and an
# upright bass; a flute takes the middle over vibes, an accordion leads a tea-dance strain in Ab,
# and the organ comes home with the flute holding long notes above it. The waves wash in at the top
# and the bingo cage rattles at the end of every strain. 32 bars: waves (2), A organ (8), B flute
# (8), C accordion in Ab (8), A organ and flute (6).
# ---------------------------------------------------------------------------------------------

SUN_A = ("G4:1 Bb4 D5:1.5 C5:.5 | Bb4:1 G4:.5 Eb4 G4:2 | Ab4:1 C5 Eb5:1.5 D5:.5 | C5:1.5 Bb4:.5 Ab4:1 F4 | "
         "D5:1 F5 Bb5:1.5 A5:.5 | G5:1 E5:.5 C5 Bb4:2 | Ab4:.5 C5 F5 Ab5 G5:1 F5 | Eb5:3 r:1")
SUN_B = ("C6:1.5 Bb5:.5 Ab5:1 Eb5 | B5:1.5 Ab5:.5 F5:2 | Bb5:1 G5:.5 F5 D5:1 Bb4 | C5:.5 E5 G5 Bb5 A5:2 | "
         "Ab5:1.5 G5:.5 F5:1 C5 | D5:1 F5 Ab5:1.5 G5:.5 | G5:1 Bb5 E5 G5 | F5:2 D5:1 r:1")
SUN_C = ("Eb5:.5 F5 Eb5 C5 Ab4:2 | F5:.5 Gb5 F5 Eb5 Db5:1 B4 | C5:.5 Eb5 Ab5 C6 Bb5:1 Ab5 | A5:1.5 F5:.5 Eb5:1 C5 | "
         "Db5:.5 F5 Ab5 F5 Db5:1 Bb4 | G4:.5 Bb4 Db5 Eb5 G5:2 | F5:1 Eb5 C5 Ab4 | D5:1 F5 Ab5 D6")
SUN_A2 = ("G4:1 Bb4 D5:1.5 C5:.5 | Bb4:1 G4:.5 Eb4 G4:2 | Ab4:1 C5 Eb5:1.5 D5:.5 | C5:1.5 Bb4:.5 Ab4:1 F4 | "
          "G4:1 Bb4 Eb5:1.5 D5:.5 | Eb5:2 r:2")
SUN_COUNTER = "Eb6:4 | Eb6:2 D6:2 | C6:4 | D6:4 | Bb5:4 | Ab5:4"
SUN_CHORDS = " ".join(["Ebmaj7 Bb7sus4",
                       "Ebmaj7 Cm7 Fm7 Bb7 Gm7 C7 Fm7,Bb7 Ebmaj7",
                       "Abmaj7 Abm6 Gm7 C7 Fm7 Bb7 Gm7,C7 Fm7,Bb7",
                       "Ab6 Db9 Ab6 F7 Bbm7 Eb7 Ab6 Bb7",
                       "Ebmaj7 Cm7 Fm7 Bb7 Ebmaj7 Bb7sus4"])


def _bingo(s, bar):
    """The cage turns, a ball drops, the caller's bell."""
    for q in range(8):
        s.hit("shaker", bar * 4 + 2 + q * 0.2, vel=0.35 + 0.05 * q)
    s.hit("woodblock", bar * 4 + 3.7, vel=0.7)
    s.note("bells", "G5", bar * 4 + 3.75, 0.25, vel=0.4)


def sunset_shores():
    s = Band(92, 32, swing=0.12, loudness=-18.0, room=0.55)
    s.part("organ", "organ", level=0.62, reverb=0.4, chorus=0.4)
    s.part("gtr", "nylon", level=0.5, pan=-0.3, reverb=0.3)
    s.part("bass", "upright", level=0.66, reverb=0.12)
    s.part("flute", "orch_flute", level=0.66, pan=0.15, reverb=0.45)
    s.part("vibes", "vibes", level=0.38, pan=0.35, reverb=0.5)
    s.part("accordion", "accordion", level=0.55, pan=-0.1, reverb=0.35)
    s.part("strings", "slowstrings", level=0.32, reverb=0.6)
    s.part("waves", "seashore", level=0.38, reverb=0.3)
    s.part("bells", "orch_bells", level=0.4, pan=0.3, reverb=0.5)
    s.kit("brush", level=0.68)
    p = _bars(SUN_CHORDS, 32)
    for bar, parts in enumerate(p):
        intro, a1, b, c, a2 = bar < 2, 2 <= bar < 10, 10 <= bar < 18, 18 <= bar < 26, bar >= 26
        comp(s, "gtr", bar, parts, "....x.......x...", low=52, vel=0.5, spread=0.15)
        if intro:
            comp(s, "organ", bar, parts, "x---------------", low=55, vel=0.4, spread=0.1)
            continue
        if a1 or a2:
            bassline(s, "bass", bar, parts, TWO_FEEL, low=31, vel=0.72)
        else:
            walking(s, "bass", bar, parts, low=31, vel=0.7)
        beat(s, bar, {"snare": "....o.......o...", "pedalhat": "....g.......g...", "kick": "g.......g......."}, vel=0.75)
        if c:
            beat(s, bar, {"ride": "o..go..go..go..g"}, vel=0.4)
        if b or c:
            comp(s, "organ", bar, parts, "x-------x-------", low=55, vel=0.33, spread=0.1)
        if b:
            arp(s, "vibes", bar, parts, step=1.0, low=67, octaves=1, vel=0.3, pan=0.0, length=0.9)
        if c or a2:
            comp(s, "strings", bar, parts, "x---------------", low=55, vel=0.4, spread=0.1)
        if bar in (9, 17, 25):
            _bingo(s, bar)
        if bar in (17, 25, 31):
            roll(s, bar, start=3.0, count=4, low=0.25, high=0.55)
    # The sea outside the lounge windows.
    s.note("waves", "C4", 0, 7.5, vel=0.55)
    s.note("waves", "G3", 30 * 4, 7.5, vel=0.45)
    melody(s, "organ", 2, SUN_A, bars=8, vel=0.78)
    melody(s, "flute", 10, SUN_B, bars=8, vel=0.75)
    melody(s, "accordion", 18, SUN_C, bars=8, vel=0.75)
    melody(s, "organ", 26, SUN_A2, bars=6, vel=0.8)
    melody(s, "flute", 26, SUN_COUNTER, bars=6, vel=0.55)
    return s


# ---------------------------------------------------------------------------------------------
# The Furnace Works: the machine hall. E minor, 126 bpm. Staccato trombones and tubas turn a riff
# like a crankshaft, the kit and the clanks lock to it, a horn sings the tune over the top; the
# trumpet takes a brighter strain in G over spiccato strings; then the furnace door opens: a
# half-time breakdown of timpani, choir, a low brass chorale and a cello, an anvil on every bar;
# and the machine starts up again with horn and trumpet together. The steam lets off (a rising
# hiss) before each section. 36 bars: start-up (4), A (8), B (8), furnace (8), A again (8).
# ---------------------------------------------------------------------------------------------

FUR_RIFF = [(e * 0.5, 0.4, off) for e, off in enumerate((0, 0, 7, 0, 0, 12, 0, 10))]
FUR_HORN = ("E4:1.5 G4:.5 B4:2 | A4:.5 G4 F#4 G4 E4:2 | C5:1.5 B4:.5 G4:1 E4 | F#4:1 A4 D5:2 | "
            "E5:1.5 D5:.5 C5:1 A4 | B4:.5 C5 B4 A4 E4:2 | D#5:1.5 C5:.5 B4:1 A4 | F#4:3 r:1")
FUR_TRUMPET = ("B4:.5 D5 G5:2 F#5:.5 E5 | F#5:1 A5:.5 F#5 D5:2 | G5:.5 F#5 E5 B4 E5:2 | C5:1 E5 G5 C6 | "
               "B5:1.5 A5:.5 G5:1 D5 | F#5:.5 G5 A5 F#5 D5:2 | E5:1 G5 C6:1.5 B5:.5 | A5:1 F#5 D#5:2")
FUR_CELLO = "E3:2 G3:2 | F#3:2 B2:2 | E3:1 G3 C4:2 | B3:2 A3:2 | A3:1.5 C4:.5 E4:2 | D4:2 C4:2 | B3:1.5 A3:.5 F#3:2 | D#3:4"
FUR_LONG = "B4:4 | B4:2 C5:2 | E5:4 | D5:4 | C5:4 | E5:4 | D#5:4 | B4:4"
FUR_A_CHORDS = "Em Em C D Am Am B7 B7"
FUR_CHORDS = " ".join(["Em Em Em Em", FUR_A_CHORDS, "G D Em C G D C B7", "Em Em C C Am Am B7 B7", FUR_A_CHORDS])


def furnace_works():
    s = Band(126, 36, loudness=-17.5, room=0.6)
    s.part("tbn_riff", "orch_trombone_short", level=0.72, pan=-0.45, reverb=0.25)
    s.part("tuba_riff", "orch_tuba_short", level=0.75, reverb=0.2)
    s.part("horn", "orch_horn", level=0.72, pan=-0.25, reverb=0.4)
    s.part("trumpet", "orch_trumpet", level=0.66, pan=0.4, reverb=0.4)
    s.part("spic", "orch_strings_short", level=0.55, pan=0.45, reverb=0.35)
    s.part("cello", "orch_cello", level=0.7, pan=-0.2, reverb=0.45)
    s.part("chorale", "orch_trombone", level=0.55, pan=0.3, reverb=0.45)
    s.part("choir", "choir", level=0.4, reverb=0.6)
    s.part("timp", "orch_timpani", level=0.7, reverb=0.4)
    s.part("steam", "reversecymbal", level=0.42, reverb=0.3)
    s.part("stabs", "brass", level=0.45, pan=0.3, reverb=0.3)
    s.kit("room", level=0.8)
    p = _bars(FUR_CHORDS, 36)
    for bar, parts in enumerate(p):
        start, a1, b, furnace, a2 = bar < 4, 4 <= bar < 12, 12 <= bar < 20, 20 <= bar < 28, bar >= 28
        if not furnace:
            bassline(s, "tbn_riff", bar, parts, FUR_RIFF, low=40, vel=0.75)
            bassline(s, "tuba_riff", bar, parts, FUR_RIFF[::2] if start else FUR_RIFF, low=28, vel=0.75)
            if start:
                # The machine's belts: spiccato strings ticking on the root from the first bar.
                bassline(s, "spic", bar, parts, [(e * 0.5, 0.3, 12) for e in range(8)], low=40, vel=0.45 + 0.05 * bar)
        if start:
            beat(s, bar, {"cowbell": "x.......x.......", "triangle_mute": "..o...o...o...o."}, vel=0.7)
            if bar >= 2:
                beat(s, bar, {"kick": "x...x...x...x..."}, vel=0.7)
        elif a1 or a2:
            beat(s, bar, {"kick": "x.....x.x.......", "snare": "....x.......x...", "hat": "x.x.x.x.x.x.x.x.",
                          "timbale": "......o.......o."}, vel=0.8)
            if a2:
                beat(s, bar, {"cowbell": "..o...o...o...o."}, vel=0.55)
                comp(s, "stabs", bar, parts, "x.......x.x.....", low=52, vel=0.5, spread=0.1)
        elif b:
            beat(s, bar, {"kick": "x.......x.x.....", "snare": "....x.......x...", "ride": "x.o.x.o.x.o.x.o.",
                          "tom_lo": "............o.o."}, vel=0.8)
            arp(s, "spic", bar, parts, step=0.25, low=59, octaves=1, vel=0.5, pan=0.0)
        else:
            # The furnace door: half time, heavy and slow.
            beat(s, bar, {"kick": "x.......x.......", "snare": "........x.......", "agogo": "............x..."}, vel=0.8)
            comp(s, "chorale", bar, parts, "x-------x-------", low=45, vel=0.6, spread=0.1)
            comp(s, "choir", bar, parts, "x---------------", low=52, vel=0.45, spread=0.1)
            s.note("timp", 28 if bar % 2 == 0 else 35, bar * 4, 1, vel=0.75)
            s.note("timp", 35 if parts[0][2].startswith("B") else 28, bar * 4 + 2.5, 1, vel=0.55)
        if bar in (11, 19, 27, 35):
            roll(s, bar, start=2.0, count=8, kind="snare" if bar != 27 else "tom_floor")
        if bar in (4, 12, 28):
            s.hit("crash", bar * 4, vel=0.75)
            s.note("timp", 28, bar * 4, 1, vel=0.85)
    # The pipes let off steam, rising into each new section.
    for bar in (3, 11, 19, 27):
        s.note("steam", "C4", bar * 4, 4, vel=0.6)
    melody(s, "horn", 4, FUR_HORN, bars=8, vel=0.82)
    melody(s, "trumpet", 12, FUR_TRUMPET, bars=8, vel=0.8)
    melody(s, "cello", 20, FUR_CELLO, bars=8, vel=0.75)
    melody(s, "horn", 28, FUR_HORN, bars=8, vel=0.85)
    melody(s, "trumpet", 28, FUR_LONG, bars=8, vel=0.6)
    return s


# ---------------------------------------------------------------------------------------------
# Eternal Rest Funeral Parlour: the organist who cannot stay solemn. G minor, 100 bpm. A pipe organ
# plays a dotted funeral march over pedal notes, choir, timpani and a tolling bell; a blue note slips
# in and an upright bass sneaks in under it; then he gives up and shuffles a minor blues on a jazz
# organ with brushes and a muted trumpet; a big chord, he catches himself, the march again - and one
# last lick on the jazz organ sneaks into the top. 32 bars: march (8), sneaking (4), blues (12),
# caught (8).
# ---------------------------------------------------------------------------------------------

FUN_MARCH = ("D5:1 D5:.75 D5:.25 G5:2 | F#5:.75 G5:.25 A5:1 Bb5:2 | G5:1 Eb5:.75 F5:.25 G5:1 Bb5 | A5:2 F#5:1 D5 | "
             "D5:1 D5:.75 D5:.25 Bb5:2 | C6:.75 Bb5:.25 A5:1 G5:1 Eb5 | D5:1 F#5 A5 C6 | Bb5:3 r:1")
FUN_SNEAK = "D5:1 D5:.75 D5:.25 G5:1 Bb5 | C6:.75 Db6:.25 C6:1 Bb5:1 G5 | D5:.5 F5 G5 Bb5 Db6:1 C6 | Bb5:.5 A5 F#5 D5 C5:2"
FUN_BLUES = ("G4:2/3 Bb4:1/3 D5:2/3 F5:1/3 G5:1.5 r:.5 | Bb5:2/3 A5:1/3 G5:2/3 F5:1/3 D5:2 | "
             "F5:2/3 G5:1/3 Bb5:2/3 C6:1/3 Db6:1 C6 | Bb5:2/3 G5:1/3 F5:2/3 D5:1/3 G5:2 | "
             "Eb5:2/3 G5:1/3 Bb5:2/3 C6:1/3 Eb6:1.5 r:.5 | D6:2/3 C6:1/3 Bb5:2/3 G5:1/3 Gb5:1 F5 | "
             "G5:2/3 F5:1/3 D5:2/3 Bb4:1/3 G4:2 | r:2 D5:2/3 F5:1/3 G5:2/3 Bb5:1/3 | "
             "Db6:1.5 Bb5:.5 G5:2/3 Eb5:1/3 Db5:1 | C6:1.5 A5:.5 F#5:2/3 D5:1/3 C5:1 | "
             "Bb4:2/3 D5:1/3 F5:2/3 G5:1/3 Bb5:2 | A5:2/3 F#5:1/3 D5:2/3 C5:1/3 A4:2")
FUN_ANSWERS = ("r:4 | r:4 | r:4 | r:3 Bb4:2/3 C5:1/3 | r:4 | r:4 | r:4 | Bb4:2/3 C5:1/3 Db5:1 r:2 | "
               "r:4 | r:4 | r:3 D5:2/3 F5:1/3 | r:4")
FUN_CAUGHT = ("D5:1 D5:.75 D5:.25 G5:2 | G5:.75 Eb5:.25 C5:1 Eb5:2 | F#5:1 A5 D6:2 | Bb5:3 r:1 | "
              "D5:1 D5:.75 D5:.25 Bb4:2 | Eb5:1 G5 Bb5:2 | A5:2 F#5:2 | D5:2 r:2")
FUN_LICK = "r:2 A5:2/3 C6:1/3 Bb5:2/3 F#5:1/3"
FUN_CHORDS = " ".join(["Gm Gm Eb D7 Gm Cm D7 Gm", "Gm Cm Gm D7",
                       "Gm7 Gm7 Gm7 Gm7 Cm7 Cm7 Gm7 Gm7 Eb7 D7 Gm7 D7",
                       "Gm Cm D7 Gm Gm Eb D7 D7"])
SHUFFLE = {"ride": "x.ox.ox.ox.o", "pedalhat": "...x.....x..", "snare": "..g..g..g..g"}


def funeral_parlour():
    s = Band(100, 32, loudness=-18.0, room=0.7)
    s.part("pipe", "churchorgan", level=0.62, reverb=0.6)
    s.part("pipe_chords", "churchorgan", level=0.42, reverb=0.6)
    s.part("pedal", "churchorgan", level=0.55, reverb=0.5)
    s.part("jazz", "organ", level=0.62, pan=0.1, reverb=0.3, chorus=0.3)
    s.part("jazz_comp", "percorgan", level=0.4, pan=-0.15, reverb=0.3)
    s.part("bass", "upright", level=0.7, reverb=0.12)
    s.part("trumpet", "orch_trumpet_mute", level=0.55, pan=0.3, reverb=0.4)
    s.part("bell", "orch_bells", level=0.45, pan=-0.2, reverb=0.6)
    s.part("timp", "orch_timpani", level=0.55, reverb=0.5)
    s.part("choir", "choir", level=0.36, reverb=0.7)
    s.kit("brush", level=0.72)
    p = _bars(FUN_CHORDS, 32)
    for bar, parts in enumerate(p):
        march, sneak, blues, caught = bar < 8, 8 <= bar < 12, 12 <= bar < 24, bar >= 24
        sym = parts[0][2]
        root_timp = 31 if sym.startswith("G") else (38 if sym.startswith("D") else 36)
        if march or caught:
            comp(s, "pipe_chords", bar, parts, "x-------x-------", low=55, vel=0.45, spread=0.1)
            bassline(s, "pedal", bar, parts, TWO_FEEL, low=31, vel=0.6)
            comp(s, "choir", bar, parts, "x---------------", low=55, vel=0.4 if march else 0.48, spread=0.1)
            s.note("timp", root_timp, bar * 4, 1, vel=0.45)
            s.note("timp", root_timp, bar * 4 + 2, 1, vel=0.35)
            if bar % 2 == 0:
                s.note("bell", "G4", bar * 4, 2, vel=0.5)
        if sneak:
            comp(s, "pipe_chords", bar, parts, "x---------------", low=55, vel=0.38, spread=0.1)
            walking(s, "bass", bar, parts, low=31, vel=0.62)
            beat(s, bar, {"snare": "..g..g..g..g", "pedalhat": "...g.....g.."}, vel=0.7)
        if blues:
            walking(s, "bass", bar, parts, low=31, vel=0.75)
            beat(s, bar, SHUFFLE, vel=0.75)
            comp(s, "jazz_comp", bar, parts, "...x.....x..", low=55, vel=0.5, spread=0.1)
        if bar == 11:
            roll(s, bar, start=3.0, count=4, low=0.25, high=0.6)
        if bar == 23:
            for k in range(3):
                s.hit("snare", bar * 4 + 3 + k / 3.0, vel=0.4 + 0.15 * k)
    # The big chord where he catches himself.
    s.hit("crash", 24 * 4, vel=0.6)
    s.note("timp", 31, 24 * 4, 2, vel=0.9)
    melody(s, "pipe", 0, FUN_MARCH, bars=8, vel=0.78)
    melody(s, "pipe", 8, FUN_SNEAK, bars=4, vel=0.75)
    melody(s, "jazz", 12, FUN_BLUES, bars=12, vel=0.8)
    melody(s, "trumpet", 12, FUN_ANSWERS, bars=12, vel=0.7)
    melody(s, "pipe", 24, FUN_CAUGHT, bars=8, vel=0.8)
    melody(s, "jazz", 31, FUN_LICK, bars=1, vel=0.75)
    return s


# ---------------------------------------------------------------------------------------------
# The Flashback Cinema, Last Showing: the intermission. A waltz in F, 3/4 at 138 bpm. A harp sweeps
# up as the organ swells; the picture-house organ plays the waltz on "oom-pah-pah", the glockenspiel
# answering its long notes; a clarinet takes a sad strain in D minor over pizzicato strings; the
# organ returns with strings singing under it; then the reel runs out - the film flaps loose - and a
# harp and celesta play us back to the curtain. The projector clicks the whole way through.
# 56 bars: curtain (4), A (16), B in D minor (16), A again (12), the reel runs out (8).
# ---------------------------------------------------------------------------------------------

CIN_A_HEAD = ("C5:1 F5 A5 | C6:2 A5:1 | D6:1.5 C6:.5 A5:1 | F5:3 | Bb5:1 G5 D5 | E5:2 G5:1 | A5:1 G5 F5 | E5:3")
CIN_A = CIN_A_HEAD + " | C5:1 F5 A5 | C#6:2 A5:1 | D6:1 F6 E6 | D6:3 | D6:1 Bb5 G5 | Bb5:1 G5 E5 | F5:2 G5:1 | F5:3"
CIN_B = ("A4:1 D5 F5 | E5:2 D5:1 | D5:1 G5 Bb5 | A5:3 | G5:1 E5 C#5 | E5:2 A4:1 | D5:1 F5 A5 | D5:3 | "
         "D5:1 F5 Bb5 | A5:2 F5:1 | G5:1.5 A5:.5 Bb5:1 | C#5:3 | D5:1 E5 F5 | G5:1 A5 Bb5 | A5:2 G5:1 | E5:3")
CIN_A2 = CIN_A_HEAD + " | F5:1 A5 D6 | D6:1 Bb5 G5 | Bb5:1 G5 E5 | F5:3"
CIN_STRINGS = "A4:3 | C5:3 | F5:3 | D5:3 | D5:3 | C5:3 | C5:3 | C#5:3 | D5:3 | D5:3 | C5:3 | A4:3"
CIN_CODA = "D5:1 F5 Bb5 | Db5:1 F5 Bb5 | C5:1 F5 A5 | F#5:2 A5:1 | G5:1 Bb5 D6 | E5:1 G5 Bb5 | A5:3 | G5:1.5 E5:.5 C5:1"
CIN_GLOCK = "r:1 A5:.5 C6 F6:1"
CIN_CHORDS = " ".join(["F F Bb C7",
                       "F F Dm Dm Gm C7 F C7 F A7 Dm Dm Gm C7 F F",
                       "Dm Dm Gm Gm A7 A7 Dm Dm Bb Bb Gm A7 Dm Gm A7 A7",
                       "F F Dm Dm Gm C7 F A7 Dm Gm C7 F",
                       "Bb Bbm6 F D7 Gm C7 F C7"])


def flashback_cinema():
    s = Band(138, 56, meter=3, loudness=-18.5, room=0.65)
    s.part("organ", "organ", level=0.62, reverb=0.5, chorus=0.6)
    s.part("organ_chords", "organ", level=0.4, reverb=0.5, chorus=0.6)
    s.part("pedal", "organ", level=0.52, reverb=0.4)
    s.part("glock", "orch_glock", level=0.42, pan=0.3, reverb=0.6)
    s.part("bells", "orch_bells", level=0.4, pan=-0.3, reverb=0.6)
    s.part("clarinet", "orch_clarinet", level=0.66, pan=0.1, reverb=0.5)
    s.part("pizz", "orch_pizz", level=0.6, pan=-0.1, reverb=0.4)
    s.part("strings", "slowstrings", level=0.38, reverb=0.6)
    s.part("harp", "orch_harp", level=0.55, pan=0.15, reverb=0.55)
    s.part("celesta", "celesta", level=0.5, pan=-0.1, reverb=0.6)
    s.kit("brush", level=0.6)
    p = _bars(CIN_CHORDS, 56, meter=3)
    for bar, parts in enumerate(p):
        curtain, a1, b, a2, reel = bar < 4, 4 <= bar < 20, 20 <= bar < 36, 36 <= bar < 48, bar >= 48
        # The projector, clicking along all the way.
        beat(s, bar, {"click": "g.g.g."}, vel=0.7)
        if curtain or reel:
            arp(s, "harp", bar, parts, step=0.5, low=53, octaves=2, vel=0.5, pan=0.0)
        if curtain:
            comp(s, "organ_chords", bar, parts, "x-----", low=53, vel=0.5, spread=0.1)
        if a1 or a2:
            bassline(s, "pedal", bar, parts, [(0, 0.9, 7 if bar % 2 else 0)], low=29, vel=0.6)
            comp(s, "organ_chords", bar, parts, "..x.x.", low=53, vel=0.42, spread=0.1)
        if b:
            bassline(s, "pizz", bar, parts, [(0, 0.9, 0)], low=38, vel=0.7)
            comp(s, "pizz", bar, parts, "..x.x.", low=57, vel=0.5, spread=0.1)
            comp(s, "strings", bar, parts, "x-----", low=53, vel=0.38, spread=0.1)
            beat(s, bar, {"pedalhat": "..g.g."}, vel=0.6)
        if a2:
            beat(s, bar, {"snare": "..g.g.", "kick": "g....."}, vel=0.6)
        if reel:
            comp(s, "strings", bar, parts, "x-----", low=53, vel=0.32, spread=0.1)
        if bar in (19, 35):
            roll(s, bar, start=1.5, count=6, low=0.2, high=0.5)
    # The curtain opens on a swell; the reel ends with a tubular bell.
    s.swell("organ_chords", 0, 12, low=35, high=110)
    s.cc("organ_chords", 12, 11, 110)
    for bar in (7, 11, 15, 19, 39, 43):
        melody(s, "glock", bar, CIN_GLOCK, bars=1, vel=0.55)
    melody(s, "organ", 4, CIN_A, bars=16, vel=0.78)
    melody(s, "clarinet", 20, CIN_B, bars=16, vel=0.72)
    melody(s, "organ", 36, CIN_A2, bars=12, vel=0.8)
    melody(s, "strings", 36, CIN_STRINGS, bars=12, vel=0.48)
    melody(s, "celesta", 48, CIN_CODA, bars=8, vel=0.6)
    # The reel runs out: the loose end flaps fast, then slower and slower.
    t = 48 * 3.0; gap = 0.2
    while t < 50 * 3.0:
        s.hit("sticks", t, vel=0.55); t += gap; gap *= 1.18
    s.note("bells", "F4", 54 * 3, 3, vel=0.45)
    return s
