"""Floor music for the nine paths after the Records Basement, made the way the Waiting Room is.

Same rules as rb2_floors.py: background first. Each place has four to six instruments, one groove
that never stops, one melody voice that sings for a while and leaves, and a stretch where the band
drops back. No shared tune, no sound-effect jokes; each place has its own key, tempo and colour.
"""
import jb_theme  # noqa: F401  (adds the sus and add chord qualities)
from band import Band, beat
from kit import melody, prog, comp, bassline, at
from synth import chord
from rb2_floors import figure, _bars

INFO = {
    "unkempt_cemetery": dict(key="E minor", bpm=104, meter=3, bars=48, quiet=[(0, 4), (28, 36)],
                             about="Cemetery: night mist, a harp turning in three, a cello singing, a celesta far off."),
    "sunset_shores": dict(key="A major", bpm=72, meter=4, bars=32, quiet=[(0, 2), (12, 20)],
                          about="Sunset Shores: golden hour by the sea, a nylon guitar rocking in triplets, an accordion."),
    "furnace_works": dict(key="C minor", bpm=100, meter=4, bars=40, quiet=[(0, 4), (20, 28)],
                          about="Furnace Works: heat and big slow machines, a marimba pulse, low toms, a horn far down the hall."),
    "funeral_parlour": dict(key="Bb minor", bpm=76, meter=4, bars=32, quiet=[(0, 4), (20, 24)],
                            about="Funeral Parlour: velvet and candles, a hushed organ, a slow walking bass, a cello."),
    "flashback_cinema": dict(key="Eb major", bpm=112, meter=3, bars=48, quiet=[(0, 4), (28, 36)],
                             about="Flashback Cinema: an old film's waltz on piano, a violin remembering, a music box."),
    "last_resort_cruise": dict(key="E major", bpm=104, meter=4, bars=40, quiet=[(0, 4), (20, 28)],
                               about="Cruise: the night deck, a soft bossa on Rhodes and bass, a muted trumpet."),
    "seance_hotline": dict(key="F# minor", bpm=80, meter=4, bars=32, quiet=[(0, 4), (20, 24)],
                           about="Seance Hotline: the night shift, a tremolo electric piano, a fretless bass, a low flute."),
    "terminal_zero": dict(key="Db major", bpm=100, meter=4, bars=40, quiet=[(0, 4), (20, 28)],
                          about="Terminal Zero: an airport at four in the morning, bell piano over pads and a soft pulse."),
    "head_office": dict(key="G minor", bpm=92, meter=4, bars=36, quiet=[(0, 4), (20, 28)],
                        about="Head Office: the top floor, polished and cold, a piano figure, plucked strings, an oboe."),
}


def triplets(s, inst, bar, parts, order, low=57, vel=0.5, length=0.5):
    """Chord tones in triplets, three to a beat: a rocking 12/8 arpeggio."""
    for k in range(s.meter * 3):
        t = k / 3.0
        notes, _ = chord(at(parts, min(t, s.meter - 0.01)), low)
        i = order[k % len(order)]
        m = notes[i % len(notes)] + 12 * (i // len(notes))
        s.note(inst, m, bar * s.meter + t, length, vel=vel * (1.0 if k % 3 == 0 else 0.8))


# ---------------------------------------------------------------------------------------------
# The Unkempt Cemetery: night, mist, long grass over the stones. E minor, in three, 104 bpm. A harp
# turns the same six notes, a bass holds each bar, a cello sings in the middle and at the end, and a
# celesta answers once from far off. 48 bars: harp (4), with bass (8), cello (8), celesta answers
# (8), harp and pad alone, half as busy (8), cello over strings (8), harp (4).
# ---------------------------------------------------------------------------------------------

CEM_A = "Em Em Cmaj7 Cmaj7 Am7 Am7 B7sus4 B7"
CEM_B = "G D Em Cmaj7 Am7 Em Cmaj7 B7"
CEM_C = "Em D Cmaj7 D Em D Cmaj7 B7sus4"
CEM_CHORDS = " ".join(["Em Em Cmaj7 B7sus4", CEM_A, CEM_B, CEM_A, CEM_C, CEM_B, "Em Em Cmaj7 B7"])
CEM_CELLO = "B3:2 D4:1 | A3:3 | G3:1 B3 E4 | E4:3 | C4:2 E4:1 | B3:3 | E4:1 D4 C4 | B3:3"
CEM_CELLO_2 = "B3:2 D4:1 | F#4:3 | G4:1 F#4 E4 | E4:3 | C4:2 E4:1 | G4:2 F#4:1 | E4:1 D4 C4 | D#4:3"
CEM_CELESTA = "r:3 | B5:1 G5 E5 | r:3 | E5:1 G5 B5 | r:3 | C6:1 A5 E5 | r:3 | F#5:1 A5 B5"


def unkempt_cemetery():
    s = Band(104, 48, meter=3, loudness=-21.0, room=0.75)
    s.part("harp", "orch_harp", level=0.7, pan=-0.4, reverb=0.5)
    s.part("bass", "fretless", level=0.55, reverb=0.25)
    s.part("cello", "orch_cello", level=0.66, pan=0.2, reverb=0.5)
    s.part("celesta", "celesta", level=0.4, pan=0.55, reverb=0.7)
    s.part("pad", "slowstrings", level=0.3, pan=0.3, reverb=0.7, chorus=0.4)
    s.kit("brush", level=0.5)
    p = _bars(CEM_CHORDS, 48)
    for bar, parts in enumerate(p):
        intro, drop, outro = bar < 4, 28 <= bar < 36, bar >= 44
        if drop:
            figure(s, "harp", bar, parts, [0, 2, 3], step=1.0, low=52, vel=0.5, length=0.95)
        else:
            figure(s, "harp", bar, parts, [0, 2, 3, 2, 1, 2], low=52, vel=0.58 if intro or outro else 0.5, length=0.6)
        if not intro:
            bassline(s, "bass", bar, parts, [(0, 2.8, 0)], low=28, vel=0.62)
        if not (intro or drop or outro):
            beat(s, bar, {"pedalhat": "..g.g.", "shaker": "g.g.g."}, vel=0.5)
        if bar >= 12 and not outro:
            comp(s, "pad", bar, parts, "x-----", low=55, vel=0.42 if not drop else 0.5)
    melody(s, "cello", 12, CEM_CELLO, bars=8, vel=0.66)
    melody(s, "celesta", 20, CEM_CELESTA, bars=8, vel=0.5)
    melody(s, "cello", 36, CEM_CELLO_2, bars=8, vel=0.7)
    return s


# ---------------------------------------------------------------------------------------------
# Sunset Shores Eternal Care: golden hour by the sea, nobody in a hurry. A major, 72 bpm, rocking in
# triplets like a slow tide. A nylon guitar rolls the chords, an upright bass leans on one and
# three, brushes whisper, and an accordion plays the tune twice with a rest between. 32 bars: guitar
# (4), accordion (8), guitar and vibes alone (8), accordion over strings (8), guitar (4).
# ---------------------------------------------------------------------------------------------

SHORE_A = "Amaj7 F#m7 Dmaj7 E7sus4 Amaj7 F#m7 Bm7 E7"
SHORE_B = "Dmaj7 C#m7 Bm7 E7 Dmaj7 C#m7 Bm7 E7sus4"
SHORE_CHORDS = " ".join(["Amaj7 F#m7 Dmaj7 E7sus4", SHORE_A, SHORE_B, SHORE_A, "Amaj7 F#m7 Dmaj7 E7"])
SHORE_TUNE = ("E5:2 C#5:1 E5 | A5:3 r:1 | F#5:2 D5:1 F#5 | E5:3 r:1 | "
              "C#5:2 E5:1 A5 | G#5:1 F#5 C#5:2 | D5:1.5 C#5:.5 B4:2 | B4:3 r:1")
SHORE_TUNE_2 = ("E5:2 C#5:1 E5 | A5:3 r:1 | F#5:2 D5:1 F#5 | E5:3 r:1 | "
                "C#5:2 E5:1 A5 | C#6:1 B5 A5:2 | F#5:1.5 E5:.5 D5:2 | E5:3 r:1")


def sunset_shores():
    s = Band(72, 32, loudness=-21.0, room=0.55)
    s.part("gtr", "nylon", level=0.7, pan=-0.45, reverb=0.35)
    s.part("bass", "upright", level=0.6, reverb=0.12)
    s.part("accordion", "accordion", level=0.46, pan=0.2, reverb=0.45)
    s.part("vibes", "vibes", level=0.36, pan=0.55, reverb=0.5)
    s.part("strings", "slowstrings", level=0.28, pan=0.35, reverb=0.6, chorus=0.4)
    s.kit("brush", level=0.6)
    p = _bars(SHORE_CHORDS, 32)
    for bar, parts in enumerate(p):
        intro, drop, outro = bar < 4, 12 <= bar < 20, bar >= 28
        triplets(s, "gtr", bar, parts, [0, 2, 3, 1, 2, 3], low=52, vel=0.55 if intro or outro or drop else 0.48)
        if bar >= 2:
            bassline(s, "bass", bar, parts, [(0, 1.9, 0), (2, 1.9, 7)], low=33, vel=0.66)
        if not (intro or drop or outro):
            beat(s, bar, {"snare": "...o.....o..", "pedalhat": "......g....."}, vel=0.5)
        if drop:
            comp(s, "vibes", bar, parts, "x-------x-------", low=60, vel=0.38)
        if bar >= 20 and not outro:
            comp(s, "strings", bar, parts, "x---------------", low=57, vel=0.44)
    melody(s, "accordion", 4, SHORE_TUNE, bars=8, vel=0.62)
    melody(s, "accordion", 20, SHORE_TUNE_2, bars=8, vel=0.66)
    return s


# ---------------------------------------------------------------------------------------------
# The Furnace Works: heat, and big slow machines that never stop. C minor, 100 bpm. A marimba pulses
# in eighths like a piston, a bass keeps to the root, low toms and a shaker turn over, and a horn
# calls twice from far down the hall. 40 bars: marimba (4), the machine (8), horn (8), marimba,
# bass and low strings alone (8), horn over strings (8), marimba (4).
# ---------------------------------------------------------------------------------------------

FURN_A = "Cm Cm Abmaj7 Abmaj7 Fm7 Fm7 G7sus4 G7"
FURN_B = "Ab Bb Cm Cm Ab Bb Gsus4 G"
FURN_C = "Cm Bb Ab Bb Cm Bb Ab G7sus4"
FURN_CHORDS = " ".join(["Cm Cm Abmaj7 G7sus4", FURN_A, FURN_B, FURN_C, FURN_B, "Cm Cm Abmaj7 G7"])
FURN_HORN = "C4:3 Eb4:1 | D4:3 F4:1 | G4:4 | r:2 G3:1 C4 | Eb4:3 C4:1 | F4:3 D4:1 | G4:2 C4:2 | B3:3 r:1"
FURN_PISTON = [(0, 0.45, 0), (1, 0.45, 0), (1.5, 0.45, 0), (2, 0.45, 0), (3, 0.45, 0), (3.5, 0.45, 7)]


def furnace_works():
    s = Band(100, 40, loudness=-20.0, room=0.6)
    s.part("marimba", "orch_marimba", level=0.66, pan=-0.45, reverb=0.35)
    s.part("bass", "fingerbass", level=0.66, reverb=0.1)
    s.part("horn", "orch_horn", level=0.6, pan=0.25, reverb=0.6)
    s.part("strings", "slowstrings", level=0.3, pan=0.4, reverb=0.6, chorus=0.4)
    s.part("piano", "piano", level=0.4, pan=0.5, reverb=0.4)
    s.kit("room", level=0.6)
    p = _bars(FURN_CHORDS, 40)
    for bar, parts in enumerate(p):
        intro, drop, outro = bar < 4, 20 <= bar < 28, bar >= 36
        figure(s, "marimba", bar, parts, [0, 1, 2, 1, 0, 1, 3, 1], low=48, vel=0.6 if intro or outro else 0.52)
        if bar >= 2:
            bassline(s, "bass", bar, parts, [(0, 3.8, 0)] if drop or intro else FURN_PISTON, low=24, vel=0.7)
        if not (intro or drop or outro):
            beat(s, bar, {"kick": "o.......o.......", "tom_floor": "......g.......g.", "shaker": "g.g.g.g.g.g.g.g.",
                          "rim": "....o.......o..."}, vel=0.7)
            comp(s, "piano", bar, parts, "..........o-....", low=48, vel=0.34)
        if bar >= 12 and not outro:
            comp(s, "strings", bar, parts, "x---------------", low=43, vel=0.42 if not drop else 0.5)
    melody(s, "horn", 12, FURN_HORN, bars=8, vel=0.62)
    melody(s, "horn", 28, FURN_HORN, bars=8, vel=0.68)
    return s


# ---------------------------------------------------------------------------------------------
# Eternal Rest Funeral Parlour: velvet, candles and whispering. Bb minor, 76 bpm, a light swing. A
# reed organ holds the chords very softly, an upright bass walks in two, brushes stir, a piano
# drops one low figure a bar, and a cello sings twice. 32 bars: organ and bass (4), the room (8),
# cello (8), organ and bass alone (4), cello (8).
# ---------------------------------------------------------------------------------------------

PARL_A = "Bbm9 Bbm9 Gbmaj7 Gbmaj7 Ebm7 Ebm7 F7sus4 F7"
PARL_B = "Dbmaj7 Ab Bbm7 Gbmaj7 Ebm7 Bbm7 Gbmaj7 F7"
PARL_CHORDS = " ".join(["Bbm9 Bbm9 Gbmaj7 F7sus4", PARL_A, PARL_B, "Bbm9 Gbmaj7 Ebm7 F7sus4", PARL_B])
PARL_CELLO = "F4:2 Ab4:2 | Eb4:3 C4:1 | Db4:2 F4:2 | Bb3:3 r:1 | Gb4:2 Bb4:2 | Ab4:1 F4 Db4:2 | Bb3:2 Db4:2 | C4:3 r:1"


def funeral_parlour():
    s = Band(76, 32, swing=0.08, loudness=-21.0, room=0.65)
    s.part("organ", "reedorgan", level=0.36, pan=-0.4, reverb=0.55, chorus=0.3)
    s.part("bass", "upright", level=0.64, reverb=0.12)
    s.part("piano", "piano", level=0.46, pan=0.5, reverb=0.45)
    s.part("cello", "orch_cello", level=0.66, pan=0.15, reverb=0.5)
    s.kit("brush", level=0.62)
    p = _bars(PARL_CHORDS, 32)
    for bar, parts in enumerate(p):
        intro, drop = bar < 4, 20 <= bar < 24
        comp(s, "organ", bar, parts, "x---------------", low=53, vel=0.5)
        bassline(s, "bass", bar, parts, [(0, 1.9, 0), (2, 1.4, 7), (3.5, 0.45, 10)] if not (intro or drop) else [(0, 3.8, 0)],
                 low=34, vel=0.68)
        if not (intro or drop):
            beat(s, bar, {"snare": "g.g.o.g.g.g.o.g.", "pedalhat": "....g.......g..."}, vel=0.5)
            figure(s, "piano", bar, parts, [0, 2, 1, 3], step=1.0, low=58, vel=0.36, length=0.9)
    melody(s, "cello", 12, PARL_CELLO, bars=8, vel=0.66)
    melody(s, "cello", 24, PARL_CELLO, bars=8, vel=0.7)
    return s


# ---------------------------------------------------------------------------------------------
# The Flashback Cinema, Last Showing: an old film running for nobody, warm and a little sad. Eb
# major, a waltz at 112 bpm. A piano plays the waltz, a bass marks each bar, a soft shaker keeps
# time like a reel, a violin remembers the tune, and a music box plays it back. 48 bars: piano
# (4), the waltz (8), violin (8), violin's second strain (8), music box alone with the piano (8),
# violin over strings (8), piano (4).
# ---------------------------------------------------------------------------------------------

CINE_A = "Eb Eb Cm7 Cm7 Abmaj7 Abmaj7 Bb7sus4 Bb7"
CINE_B = "Abmaj7 Bb Gm7 Cm7 Fm7 Bb7 Eb Bb7"
CINE_CHORDS = " ".join(["Eb Cm7 Abmaj7 Bb7", CINE_A, CINE_A, CINE_B, CINE_A, CINE_B, "Eb Cm7 Abmaj7 Bb7"])
CINE_TUNE = "G4:2 Bb4:1 | Eb5:3 | D5:2 C5:1 | G4:3 | Ab4:2 C5:1 | Eb5:2 D5:1 | C5:3 | Bb4:2 r:1"
CINE_TUNE_B = "C5:2 Eb5:1 | D5:3 | Bb4:2 D5:1 | Eb5:2 G5:1 | F5:2 Ab5:1 | G5:1 F5 D5 | Eb5:3 | D5:2 r:1"


def flashback_cinema():
    s = Band(112, 48, meter=3, loudness=-21.0, room=0.6)
    s.part("piano", "piano", level=0.56, pan=-0.4, reverb=0.4)
    s.part("bass", "upright", level=0.6, reverb=0.12)
    s.part("violin", "orch_violin", level=0.6, pan=0.25, reverb=0.5)
    s.part("box", "musicbox", level=0.46, pan=0.5, reverb=0.6)
    s.part("strings", "slowstrings", level=0.28, pan=0.4, reverb=0.6, chorus=0.4)
    s.kit("brush", level=0.5)
    p = _bars(CINE_CHORDS, 48)
    for bar, parts in enumerate(p):
        intro, drop, outro = bar < 4, 28 <= bar < 36, bar >= 44
        comp(s, "piano", bar, parts, "..x.x.", low=55, vel=0.4 if not drop else 0.32)
        root = chord(at(parts, 0), 43)[0][0]
        s.note("piano", root, bar * 3, 0.9, vel=0.45)
        if not intro:
            bassline(s, "bass", bar, parts, [(0, 2.6, 0)], low=31, vel=0.64)
        if not (intro or drop or outro):
            beat(s, bar, {"shaker": "g.g.g.", "pedalhat": "..g.g."}, vel=0.5)
        if bar >= 36 and not outro:
            comp(s, "strings", bar, parts, "x-----", low=58, vel=0.44)
    melody(s, "violin", 12, CINE_TUNE, bars=8, vel=0.62)
    melody(s, "violin", 20, CINE_TUNE_B, bars=8, vel=0.66)
    melody(s, "box", 28, CINE_TUNE, bars=8, vel=0.5, transpose=12)
    melody(s, "violin", 36, CINE_TUNE_B, bars=8, vel=0.7)
    return s


# ---------------------------------------------------------------------------------------------
# The Last Resort Cruise: the night deck, lights on black water. E major, 104 bpm, a soft bossa. A
# Rhodes plays the rhythm, an upright bass rocks under it, a shaker and a rim click keep it moving,
# and a muted trumpet plays twice; in between, vibes take its second strain alone. 40 bars: Rhodes
# and shaker (4), the band (8), trumpet (8), vibes with Rhodes and bass (8), trumpet over a pad
# (8), Rhodes (4).
# ---------------------------------------------------------------------------------------------

CRUISE_A = "Emaj7 C#m7 F#m7 B7 Emaj7 C#m7 F#m7 B7sus4"
CRUISE_B = "Amaj7 G#m7 F#m7 B7 Amaj7 G#m7 C#m7 B7"
CRUISE_CHORDS = " ".join(["Emaj7 C#m7 F#m7 B7sus4", CRUISE_A, CRUISE_A, CRUISE_B, CRUISE_A, "Emaj7 C#m7 F#m7 B7"])
CRUISE_TUNE = ("B4:1.5 G#4:.5 B4:2 | E5:3 r:1 | C#5:1.5 A4:.5 C#5:2 | B4:3 r:1 | "
               "G#4:1.5 B4:.5 E5:2 | D#5:1 C#5 G#4:2 | A4:1.5 G#4:.5 F#4:2 | F#4:3 r:1")
CRUISE_TUNE_B = "C#5:2 E5:2 | D#5:3 B4:1 | A4:2 C#5:2 | B4:3 r:1 | C#5:2 E5:2 | D#5:1 B4 G#4:2 | E5:2 C#5:2 | D#5:3 r:1"
BOSSA_BASS = [(0, 1.4, 0), (1.5, 0.45, 7), (2, 1.4, 7), (3.5, 0.45, 0)]


def last_resort_cruise():
    s = Band(104, 40, loudness=-20.5, room=0.5)
    s.part("rhodes", "epiano", level=0.56, pan=-0.4, reverb=0.4, chorus=0.3)
    s.part("bass", "upright", level=0.64, reverb=0.12)
    s.part("trumpet", "mutedtrumpet", level=0.5, pan=0.2, reverb=0.5)
    s.part("vibes", "vibes", level=0.44, pan=0.5, reverb=0.5)
    s.part("pad", "warmpad", level=0.26, pan=0.35, reverb=0.6, chorus=0.4)
    s.kit("jazz", level=0.55)
    p = _bars(CRUISE_CHORDS, 40)
    for bar, parts in enumerate(p):
        intro, drop, outro = bar < 4, 20 <= bar < 28, bar >= 36
        comp(s, "rhodes", bar, parts, "x--.x-...x-.x-.." if bar % 2 == 0 else "..x-.x-..x-...x-", low=54, vel=0.44)
        beat(s, bar, {"shaker": "g.g.g.g.g.g.g.g."}, vel=0.55)
        if bar >= 2:
            bassline(s, "bass", bar, parts, BOSSA_BASS, low=33, vel=0.66)
        if not (intro or drop or outro):
            beat(s, bar, {"rim": "o..o..o...o.o..." if bar % 2 == 0 else "..o..o..o...o...", "kick": "g.....g.g.....g."}, vel=0.6)
        if bar >= 28 and not outro:
            comp(s, "pad", bar, parts, "x---------------", low=56, vel=0.44)
    melody(s, "trumpet", 12, CRUISE_TUNE, bars=8, vel=0.6)
    melody(s, "vibes", 20, CRUISE_TUNE_B, bars=8, vel=0.52)
    melody(s, "trumpet", 28, CRUISE_TUNE, bars=8, vel=0.64)
    return s


# ---------------------------------------------------------------------------------------------
# Beyond Calling Psychic Hotline, Night Shift: late, quiet, a lamp left on. F# minor, 80 bpm. An
# electric piano trembles through one slow figure, a fretless bass slides under it, a hi-hat ticks
# softly, a pad glows, and a low flute speaks twice. 32 bars: piano (4), the room (8), flute (8),
# piano and pad alone (4), flute (8).
# ---------------------------------------------------------------------------------------------

SEANCE_A = "F#m9 F#m9 Dmaj7 Dmaj7 Bm7 Bm7 C#7sus4 C#7"
SEANCE_B = "Dmaj7 E F#m7 F#m7 Dmaj7 E C#7sus4 C#7"
SEANCE_CHORDS = " ".join(["F#m9 F#m9 Dmaj7 C#7sus4", SEANCE_A, SEANCE_B, "F#m9 Dmaj7 Bm7 C#7sus4", SEANCE_B])
SEANCE_FLUTE = "A4:2 C#5:2 | B4:3 G#4:1 | A4:4 | r:2 C#5:1 E5 | F#5:2 E5:2 | D5:1 B4 G#4:2 | F#4:2 B4:2 | G#4:3 r:1"


def seance_hotline():
    s = Band(80, 32, loudness=-21.0, room=0.7)
    s.part("keys", "epiano2", level=0.56, pan=-0.4, reverb=0.5, chorus=0.5)
    s.part("bass", "fretless", level=0.6, reverb=0.2)
    s.part("flute", "orch_flute", level=0.62, pan=0.2, reverb=0.6)
    s.part("pad", "halopad", level=0.24, pan=0.45, reverb=0.7, chorus=0.4)
    s.part("vibes", "vibes", level=0.34, pan=0.55, reverb=0.6)
    s.kit("brush", level=0.5)
    p = _bars(SEANCE_CHORDS, 32)
    for bar, parts in enumerate(p):
        intro, drop = bar < 4, 20 <= bar < 24
        figure(s, "keys", bar, parts, [0, 2, 1, 3, 2, 1, 3, 2], low=54, vel=0.52 if intro or drop else 0.46, length=0.7)
        comp(s, "pad", bar, parts, "x---------------", low=57, vel=0.42)
        if not intro:
            bassline(s, "bass", bar, parts, [(0, 2.8, 0), (3, 0.9, 7)] if not drop else [(0, 3.8, 0)], low=30, vel=0.64)
        if not (intro or drop):
            beat(s, bar, {"pedalhat": "..g...g...g...g.", "rim": "............o...", "kick": "g..............."}, vel=0.5)
            if bar % 2 == 1:
                comp(s, "vibes", bar, parts, "........o-------", low=66, vel=0.34)
    melody(s, "flute", 12, SEANCE_FLUTE, bars=8, vel=0.62)
    melody(s, "flute", 24, SEANCE_FLUTE, bars=8, vel=0.66)
    return s


# ---------------------------------------------------------------------------------------------
# Departures, Terminal Zero: an airport at four in the morning, clean, empty and humming. Db major,
# 100 bpm. A bell-toned piano runs one figure, pads hold the air, a kick breathes on every beat
# under a soft hat, and a real piano drops a few high notes twice. 40 bars: bells (4), the pulse
# (8), piano (8), bells and pads with no drums (8), piano over the full pulse (8), bells (4).
# ---------------------------------------------------------------------------------------------

TERM_A = "Dbmaj7 Dbmaj7 Bbm7 Bbm7 Gbmaj7 Gbmaj7 Ab7sus4 Ab7sus4"
TERM_B = "Gbmaj7 Ab Fm7 Bbm7 Gbmaj7 Ab Dbmaj7 Ab7sus4"
TERM_CHORDS = " ".join(["Dbmaj7 Dbmaj7 Gbmaj7 Ab7sus4", TERM_A, TERM_B, TERM_A, TERM_B, "Dbmaj7 Dbmaj7 Gbmaj7 Ab7sus4"])
TERM_PIANO = "F5:3 Ab5:1 | Eb5:4 | C5:3 Eb5:1 | Db5:4 | Bb4:3 Db5:1 | C5:2 Eb5:2 | F5:4 | Eb5:3 r:1"


def terminal_zero():
    s = Band(100, 40, loudness=-20.5, room=0.75)
    s.part("bells", "epiano2", level=0.54, pan=-0.45, reverb=0.55, chorus=0.4)
    s.part("pad", "warmpad", level=0.32, pan=0.4, reverb=0.7, chorus=0.5)
    s.part("bass", "synthbass2", level=0.5, reverb=0.1)
    s.part("piano", "piano", level=0.52, pan=0.3, reverb=0.7)
    s.kit("electronic", level=0.5)
    p = _bars(TERM_CHORDS, 40)
    for bar, parts in enumerate(p):
        intro, drop, outro = bar < 4, 20 <= bar < 28, bar >= 36
        figure(s, "bells", bar, parts, [0, 2, 3, 2, 1, 2, 3, 4], low=56, vel=0.5 if intro or drop or outro else 0.44, length=0.6)
        comp(s, "pad", bar, parts, "x---------------", low=53, vel=0.46)
        if bar >= 2:
            bassline(s, "bass", bar, parts, [(0, 3.8, 0)] if intro or drop or outro else [(0, 1.4, 0), (1.5, 0.45, 0), (2, 1.9, 0)],
                     low=25, vel=0.6)
        if not (intro or drop or outro):
            beat(s, bar, {"kick": "o...o...o...o...", "hat": "..g...g...g...g.", "clap": "............g..."}, vel=0.55)
    melody(s, "piano", 12, TERM_PIANO, bars=8, vel=0.56)
    melody(s, "piano", 28, TERM_PIANO, bars=8, vel=0.6, transpose=12)
    return s


# ---------------------------------------------------------------------------------------------
# Head Office, Eternity Incorporated: the top floor, polished, cold and very quiet. G minor, 92
# bpm. A piano repeats one figure, strings pluck the off-beats, a bass holds the floor, a rim and a
# shaker tick, and an oboe speaks twice. 36 bars: piano (4), the office (8), oboe (8), piano, bass
# and low strings alone (8), oboe over strings (8).
# ---------------------------------------------------------------------------------------------

OFFICE_A = "Gm9 Gm9 Ebmaj7 Ebmaj7 Cm7 Cm7 D7sus4 D7"
OFFICE_B = "Ebmaj7 F Gm7 Gm7 Cm7 D7 Gm7 D7"
OFFICE_C = "Gm9 F Ebmaj7 F Gm9 F Ebmaj7 D7sus4"
OFFICE_CHORDS = " ".join(["Gm9 Gm9 Ebmaj7 D7sus4", OFFICE_A, OFFICE_B, OFFICE_C, OFFICE_B])
OFFICE_OBOE = "G4:2 Bb4:2 | A4:3 C5:1 | D5:4 | r:2 Bb4:1 A4 | G4:2 Eb5:2 | D5:1 C5 A4:2 | Bb4:2 G4:2 | F#4:3 r:1"


def head_office():
    s = Band(92, 36, loudness=-20.5, room=0.6)
    s.part("piano", "piano", level=0.56, pan=-0.4, reverb=0.45)
    s.part("pizz", "orch_pizz", level=0.56, pan=0.45, reverb=0.4)
    s.part("bass", "upright", level=0.6, reverb=0.12)
    s.part("oboe", "orch_oboe", level=0.56, pan=0.15, reverb=0.55)
    s.part("strings", "slowstrings", level=0.3, pan=0.3, reverb=0.6, chorus=0.4)
    s.kit("brush", level=0.55)
    p = _bars(OFFICE_CHORDS, 36)
    for bar, parts in enumerate(p):
        intro, drop = bar < 4, 20 <= bar < 28
        figure(s, "piano", bar, parts, [0, 2, 1, 2, 3, 2, 1, 2], low=55, vel=0.52 if intro or drop else 0.46, length=0.5)
        if bar >= 2:
            bassline(s, "bass", bar, parts, [(0, 1.9, 0), (2, 1.9, 0)] if not drop else [(0, 3.8, 0)], low=31, vel=0.64)
        if not (intro or drop):
            comp(s, "pizz", bar, parts, "..x...x...x...x.", low=58, vel=0.42)
            beat(s, bar, {"rim": "....o.......o...", "shaker": "g.g.g.g.g.g.g.g."}, vel=0.5)
        if bar >= 12:
            comp(s, "strings", bar, parts, "x---------------", low=50, vel=0.42 if not drop else 0.5)
    melody(s, "oboe", 12, OFFICE_OBOE, bars=8, vel=0.6)
    melody(s, "oboe", 28, OFFICE_OBOE, bars=8, vel=0.64)
    return s
