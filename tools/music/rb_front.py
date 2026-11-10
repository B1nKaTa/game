"""The front of the soundtrack, each place its own piece: the title, the landings, the Arcade, the
Records Basement and the Unkempt Cemetery. No shared theme: every song has its own key, tempo,
instruments and hook, on the idea and the joke its place has always had.
"""
from band import Band, beat, roll
from kit import melody, prog, comp, bassline, arp
from jb_theme import walking

INFO = {
    "take_a_number": dict(key="G major", bpm=108, meter=4, bars=24, quiet=[(0, 1)],
                          about="Title: a brass-band queue march, clarinet and piccolo, tuba oom-pah, ticket dings."),
    "landing": dict(key="D major", bpm=64, meter=4, bars=16,
                    about="Landings: a breather, harp over soft strings, an oboe and a cello in turn."),
    "the_arcade": dict(key="C major", bpm=148, meter=4, bars=40,
                       about="Arcade and Back Room: a bouncy casino tune, chip lead with a real band, coins and a slot lever."),
    "records_basement": dict(key="Ab major", bpm=140, meter=4, bars=40,
                             about="Dusty office swing: clarinet and muted trumpet, Charleston piano, typewriter breaks, a shout chorus."),
    "unkempt_cemetery": dict(key="E minor", bpm=150, meter=3, bars=52, quiet=[(0, 4), (48, 52)],
                             about="Spooky waltz: a lone violin over bones, a music box answering, ghost choir, the wind."),
}


def _bars(text, count, meter=4):
    p = prog(text, meter)
    assert len(p) == count, "progression has %d bars, not %d" % (len(p), count)
    return p


# ---------------------------------------------------------------------------------------------
# Take a Number: the title. The queue shuffles forward to a little brass band: a clarinet leads the
# march, a tuba oom-pahs, horns answer in the trio and a piccolo trills over them; the ticket
# machine dings between phrases. G major, 108 bpm. 24 bars: ding and roll (2), A clarinet (8),
# B brass trio in C (8), A short with everyone (6).
# ---------------------------------------------------------------------------------------------

TITLE_CHORDS = "G G | G D7 G C G Em A7 D7 | C G D7 G C A7 D D7 | G D7 G C G,D7 G"
TITLE_A = ("D5:.5 B4 G4 B4 D5:1 G5 | F#5:.5 E5 D5 C5 A4:2 | B4:.5 C5 D5 E5 D5:1 B4 | C5:.5 E5 G5 E5 C5:2 | "
           "D5:.5 B4 G4 B4 D5:1 G5 | G5:.5 F#5 E5 D5 B4:2 | C#5:.5 D5 E5 G5 F#5:1 E5 | D5:1 A4 F#4 r")
TITLE_B = ("E4:1.5 G4:.5 C5:2 | B4:1.5 A4:.5 G4:2 | F#4:1 A4 C5 D5 | B4:3 r:1 | "
           "E5:1.5 D5:.5 C5:1 E5 | C#5:1.5 E5:.5 G5:1 E5 | F#5:1 E5 D5 A4 | C5:1 B4 A4 F#4")
TITLE_END = ("D5:.5 B4 G4 B4 D5:1 G5 | F#5:.5 E5 D5 C5 A4:2 | B4:.5 C5 D5 E5 D5:1 B4 | C5:.5 E5 G5 E5 C5:2 | "
             "D5:.5 B4 G4 B4 D5:1 F#5 | G5:2 r:2")


def take_a_number():
    s = Band(108, 24, loudness=-17.0, room=0.5)
    s.part("clarinet", "orch_clarinet", level=0.7, pan=0.1, reverb=0.35)
    s.part("piccolo", "orch_piccolo_short", level=0.55, pan=0.3, reverb=0.4)
    s.part("horn", "orch_horn", level=0.65, pan=-0.2, reverb=0.4)
    s.part("trombone", "orch_trombone", level=0.55, pan=-0.3, reverb=0.35)
    s.part("pah", "orch_horn_short", level=0.45, pan=0.2, reverb=0.35)
    s.part("tuba", "orch_tuba_short", level=0.8, reverb=0.2)
    s.part("glock", "orch_glock", level=0.5, pan=0.35, reverb=0.45)
    s.kit("orchestra", level=0.75)
    p = _bars(TITLE_CHORDS, 24)
    roll(s, 0, start=0.0, count=16, kind="snare", step=0.25, low=0.35, high=0.65)
    roll(s, 1, start=0.0, count=12, kind="snare", step=0.25, low=0.6, high=0.85)
    for bar, parts in enumerate(p):
        if bar < 2:
            continue
        bassline(s, "tuba", bar, parts, [(0, 0.9, 0), (2, 0.9, 7)], low=36, vel=0.8)
        comp(s, "pah", bar, parts, "....x.......x...", low=55, vel=0.5, spread=0.0)
        beat(s, bar, {"kick": "x.......x.......", "snare": "....x..o....x.oo"}, vel=0.7)
        if bar in (9, 17):
            roll(s, bar, start=2.0, count=8)
    s.hit("crash", 2 * 4, vel=0.7)
    s.hit("crash", 18 * 4, vel=0.7)
    melody(s, "clarinet", 2, TITLE_A, bars=8, vel=0.8)
    melody(s, "horn", 10, TITLE_B, bars=8, vel=0.8)
    melody(s, "trombone", 10, TITLE_B, bars=8, vel=0.65, transpose=-12)
    for bar in (11, 13, 15):
        melody(s, "piccolo", bar, "r:3 D6:.25 E6 D6 B5", bars=1, vel=0.6)
    melody(s, "clarinet", 18, TITLE_END, bars=6, vel=0.85)
    melody(s, "horn", 18, TITLE_END, bars=6, vel=0.6, transpose=-12)
    melody(s, "piccolo", 22, "D6:.5 B5 G5 B5 D6:1 F#6 | G6:2 r:2", bars=2, vel=0.6)
    # "Now serving": the ticket machine dings as each phrase ends.
    for bar in (5, 9, 13, 17, 23):
        s.note("glock", "D6", bar * 4 + 3, 0.5, vel=0.6)
        s.note("glock", "B5", bar * 4 + 3.5, 0.5, vel=0.55)
    return s


# ---------------------------------------------------------------------------------------------
# The Landing: a breather between floors. A harp ripples over soft strings; an oboe sings a short
# song, a cello answers it, a flute says goodbye. D major, 64 bpm. 16 bars: harp alone (4), oboe (6),
# cello (4), flute and harp (2).
# ---------------------------------------------------------------------------------------------

LANDING_CHORDS = "Dmaj7 Bm7 Gmaj7 Asus4 Dmaj7 F#m7 Gmaj7 A7 Bm7 Gmaj7 Em7 A7 Dmaj7 Gmaj7 Em7 Asus4"
LANDING_OBOE = "F#5:1.5 E5:.5 D5:1 A4 | C#5:2 E5:2 | D5:1.5 B4:.5 F#5:2 | E5:3 r:1 | F#5:1 A5 F#5:.5 E5 D5:1 | B4:3 r:1"
LANDING_CELLO = "G3:1.5 B3:.5 D4:2 | C#4:2 E4:1 G4 | F#4:3 E4:1 | D4:2 B3:2"


def landing():
    s = Band(64, 16, loudness=-22.0, room=0.75)
    s.part("harp", "orch_harp", level=0.6, reverb=0.55)
    s.part("strings", "slowstrings", level=0.32, reverb=0.65)
    s.part("oboe", "orch_oboe", level=0.6, pan=0.15, reverb=0.55)
    s.part("cello", "orch_cello", level=0.6, pan=-0.15, reverb=0.5)
    s.part("flute", "orch_flute", level=0.5, pan=0.2, reverb=0.6)
    s.part("bass", "orch_bass", level=0.45, reverb=0.4)
    s.part("bells", "orch_bells", level=0.3, pan=-0.3, reverb=0.7)
    p = _bars(LANDING_CHORDS, 16)
    for bar, parts in enumerate(p):
        arp(s, "harp", bar, parts, step=0.5, low=62 if bar % 4 < 2 else 57, octaves=2, vel=0.45, pan=0.0, length=1.5,
            down=bar % 2 == 1)
        if bar >= 2:
            comp(s, "strings", bar, parts, "x---------------", low=54, vel=0.42, spread=0.0)
        if 4 <= bar < 14:
            bassline(s, "bass", bar, parts, [(0, 1.9, 0), (2, 1.9, 0)], low=33, vel=0.5)
    melody(s, "oboe", 4, LANDING_OBOE, bars=6, vel=0.7)
    melody(s, "cello", 10, LANDING_CELLO, bars=4, vel=0.7)
    melody(s, "flute", 14, "B5:1 A5 G5 E5 | D5:2 r:2", bars=2, vel=0.55)
    for bar in (0, 8):
        s.note("bells", "D5", bar * 4, 2, vel=0.4)
        s.note("bells", "A5", bar * 4 + 0.02, 2, vel=0.35)
    return s


# ---------------------------------------------------------------------------------------------
# The Arcade (and the Dealer's Back Room): a bouncy casino tune. A chip lead fronts a real band:
# slap bass, bright piano, brass stabs; the house organ takes a solo over stop-time, and in the
# jackpot breakdown a xylophone climbs while coins pour out. The slot lever cranks at the top.
# C major, 148 bpm, a little swing. 40 bars: A (8), A with brass (8), B organ (8), C jackpot in Ab (8),
# A with everyone (8).
# ---------------------------------------------------------------------------------------------

ARCADE_A_CHORDS = "C Am F G C Am Dm7,G7 C"
ARCADE_CHORDS = " ".join([ARCADE_A_CHORDS, ARCADE_A_CHORDS, "F G Em Am Dm7 G7 Cmaj7 C7", "Ab Bb C C Ab Bb G7 G7", ARCADE_A_CHORDS])
ARCADE_A = ("E5:.5 G5 C6 G5 E5:1 G5 | A5:.5 G5 E5 C5 A4:2 | F5:.5 A5 C6 A5 F5:1 A5 | G5:.5 F5 D5 B4 G4:2 | "
            "C5:.5 E5 G5 C6 E6:1 D6 | C6:.5 B5 A5 E5 C5:2 | D5:.5 F5 A5 C6 B5:1 G5 | C6:1 r:1 G5:.5 E5 C5:1")
ARCADE_B = ("A4:.5 C5 F5 A5 G5 F5 C5 A4 | B4:.5 D5 G5 B5 A5 G5 D5 B4 | G5:1 E5 B4 E5 | C6:1.5 B5:.5 A5:2 | "
            "F5:.5 E5 D5 F5 A5:1 C6 | B5:.5 A5 G5 F5 D5:2 | E5:1 G5 B5 C6 | Bb5:2 r:2")
ARCADE_C = ("C6:.5 Eb6 C6 Ab5 Eb5:2 | D6:.5 F6 D6 Bb5 F5:2 | E6:.5 G6 E6 C6 G5 E5 C5 G4 | C5:4 | "
            "Eb6:.5 C6 Ab5 C6 Eb6:2 | F6:.5 D6 Bb5 D6 F6:2 | G6:.5 F6 D6 B5 G5 F5 D5 B4 | G4:1 r:3")
SLAP = [(0, 0.45, 0), (1, 0.45, 12), (1.5, 0.45, 7), (2, 0.45, 0), (3, 0.45, 12), (3.5, 0.45, 7)]


def _coins(s, bar, at=2.0):
    """Coins tumbling out of the machine: a falling glockenspiel run and a jingle."""
    for k, n in enumerate(("C7", "G6", "E6", "C6", "G5", "E5")):
        s.note("glock", n, bar * 4 + at + k * 0.25, 0.3, vel=0.55 - k * 0.04)
    s.hit("jingle", bar * 4 + at, vel=0.5)
    s.hit("jingle", bar * 4 + at + 0.75, vel=0.4)


def the_arcade():
    s = Band(148, 40, swing=0.1, loudness=-17.5, room=0.4)
    s.part("lead", "squarelead", level=0.5, pan=0.05, reverb=0.3)
    s.part("organ", "percorgan", level=0.55, pan=-0.15, reverb=0.3)
    s.part("piano", "brightpiano", level=0.45, pan=0.25, reverb=0.25)
    s.part("brass", "brass", level=0.45, pan=-0.2, reverb=0.3)
    s.part("bass", "slap", level=0.7, reverb=0.1)
    s.part("xylo", "orch_xylophone", level=0.6, pan=0.2, reverb=0.35)
    s.part("vibes", "vibes", level=0.4, pan=-0.25, reverb=0.4)
    s.part("glock", "orch_glock", level=0.45, pan=0.35, reverb=0.4)
    s.kit("standard", level=0.75)
    p = _bars(ARCADE_CHORDS, 40)
    # The slot lever cranks down and the reels spin up.
    for t in (0.0, 0.25, 0.5):
        s.hit("guiro", t, vel=0.7)
    for bar, parts in enumerate(p):
        a, b, c = bar < 16 or bar >= 32, 16 <= bar < 24, 24 <= bar < 32
        if b:
            bassline(s, "bass", bar, parts, [(0, 0.9, 0), (2.5, 0.45, 7)], low=36, vel=0.8)
            beat(s, bar, {"kick": "x.........x.....", "snare": "x.........x.....", "hat": "x...x...x...x..."}, vel=0.7)
            comp(s, "brass", bar, parts, "x---......x-....", low=58, vel=0.55, spread=0.0)
        elif c:
            bassline(s, "bass", bar, parts, [(0, 0.9, 0), (1.5, 0.45, 7), (2, 0.9, 12), (3.5, 0.45, 7)], low=36, vel=0.75)
            beat(s, bar, {"kick": "x.......x.......", "rim": "....x.......x...", "shaker": "xoxoxoxoxoxoxoxo"}, vel=0.7)
            comp(s, "vibes", bar, parts, "x---....x---....", low=60, vel=0.5, spread=0.0)
        else:
            bassline(s, "bass", bar, parts, SLAP, low=36, vel=0.8)
            beat(s, bar, {"kick": "x.....x...x.....", "snare": "....x.......x...", "hat": "x.x.x.x.x.x.x.x."}, vel=0.75)
            comp(s, "piano", bar, parts, "..x...x...x...x.", low=60, vel=0.45, spread=0.0)
            if 8 <= bar < 16 or bar >= 32:
                comp(s, "brass", bar, parts, "x.....x...x.....", low=58, vel=0.55, spread=0.0)
        if bar in (7, 15, 23, 31, 39):
            roll(s, bar, start=3.0, count=4)
    melody(s, "lead", 0, ARCADE_A, bars=8, vel=0.8)
    melody(s, "lead", 8, ARCADE_A, bars=8, vel=0.8)
    melody(s, "vibes", 8, ARCADE_A, bars=8, vel=0.5, transpose=-12)
    melody(s, "organ", 16, ARCADE_B, bars=8, vel=0.8)
    melody(s, "xylo", 24, ARCADE_C, bars=8, vel=0.8)
    melody(s, "lead", 32, ARCADE_A, bars=8, vel=0.82)
    melody(s, "xylo", 32, ARCADE_A, bars=8, vel=0.55, transpose=12)
    for bar in (3, 11, 27, 35):
        _coins(s, bar)
    # The jackpot: the bells go off and the coins keep coming.
    for k in range(8):
        s.note("glock", ("C7", "G6")[k % 2], 26 * 4 + k * 0.25, 0.3, vel=0.5)
    _coins(s, 27, at=0.0)
    _coins(s, 27, at=2.0)
    s.hit("crash", 24 * 4, vel=0.6)
    s.hit("crash", 32 * 4, vel=0.7)
    return s


# ---------------------------------------------------------------------------------------------
# The Records Basement: dusty office swing. A clarinet files the tune, a muted trumpet answers and
# then takes its own chorus with the clarinet humming under it; the upright piano strides through a
# solo broken up by typewriter clatter; a filing drawer slams into the shout chorus in F minor.
# Ab major, 140 bpm, swung. 40 bars: A clarinet (8), A' trumpet (8), B piano and typewriter (8),
# C shout (8), A clarinet and trumpet (8).
# ---------------------------------------------------------------------------------------------

BASEMENT_A_CHORDS = "Ab6 F7 Bbm7 Eb7 Ab6 C7 Fm7,Bb7 Bbm7,Eb7"
BASEMENT_CHORDS = " ".join([BASEMENT_A_CHORDS, BASEMENT_A_CHORDS, "Db6 Dbm6 Ab6 F7 Bb7 Bb7 Bbm7 Eb7",
                            "Fm Fm C7 C7 Fm Bb7 Eb7 Eb7", BASEMENT_A_CHORDS])
BASEMENT_A = ("C5:.5 Eb5 F5 Ab5 C6:1 Ab5 | A5:.5 Ab5 F5 Eb5 C5:2 | Db5:.5 F5 Ab5 Db6 C6:1 Bb5 | G5:1.5 F5:.5 Eb5:1 r | "
              "C5:.5 Eb5 F5 Ab5 C6:1 Eb6 | E6:.5 Db6 C6 Bb5 G5:2 | Ab5:1 F5 D5:1 Ab5 | G5:.5 F5 Eb5 Db5 C5:1 r")
BASEMENT_A2 = ("Eb5:1 C5:.5 Eb5 F5:1 Ab5 | A5:1.5 F5:.5 C5:2 | Db5:1 F5:.5 Ab5 Bb5:1 Db6 | C6:2 Bb5:1 r | "
               "Eb5:1 C5:.5 Eb5 F5:1 Ab5 | Bb5:.5 C6 Db6 C6 Bb5:1 G5 | F5:1.5 Ab5:.5 D5:1 F5 | Eb5:2 r:2")
BASEMENT_HUM = "C5:4 | C5:4 | Db5:4 | Db5:4 | C5:4 | Bb4:4 | Ab4:4 | G4:4"
BASEMENT_B = ("F5:.5 Ab5 Bb5 Db6 F6:1 Db6 | E6:.5 Db6 Bb5 Ab5 E5:2 | Eb5:.5 F5 Ab5 C6 Eb6:1 C6 | Eb6:.5 C6 A5 F5 Eb5:2 | "
              "D5:.5 F5 Ab5 Bb5 D6:1 Bb5 | Ab5:.5 F5 D5 Bb4 Ab4:2 | Db5:.5 F5 Ab5 Db6 F6:1 Db6 | G5:1 Bb5 Db6 r")
BASEMENT_SHOUT = ("C5:.5 F5 Ab5 C6 r:1 C6:.5 C6 | Db6:.5 C6 Ab5 F5 r:2 | Bb5:.5 G5 E5 C5 r:1 E5:.5 G5 | Bb5:1 G5:.5 E5 C5:2 | "
                  "C5:.5 F5 Ab5 C6 r:1 Eb6:.5 Db6 | D6:1 Ab5:.5 F5 D5:2 | G5:.5 Bb5 Db6 Eb6 G6:1 r | Db6:.5 Bb5 G5 Eb5 Db5:1 r")


def _typewriter(s, bar, start=0.0, keys=8):
    """Somebody types up a memo: a clatter of keys, then the carriage bell."""
    for k in range(keys):
        s.hit("sticks", bar * 4 + start + k * 0.25, vel=0.55 if k % 3 else 0.75)
    s.hit("triangle", bar * 4 + start + keys * 0.25 + 0.25, vel=0.6)


def records_basement():
    s = Band(140, 40, swing=0.14, loudness=-18.0, room=0.45)
    s.part("clarinet", "orch_clarinet", level=0.7, pan=0.4, reverb=0.4)
    s.part("trumpet", "mutedtrumpet", level=0.6, pan=-0.45, reverb=0.4)
    s.part("piano", "orch_piano", level=0.6, pan=0.3, reverb=0.35)
    s.part("brass", "brass", level=0.5, pan=-0.3, reverb=0.35)
    s.part("bass", "upright", level=0.75, reverb=0.1)
    s.kit("jazz", level=0.7)
    p = _bars(BASEMENT_CHORDS, 40)
    for bar, parts in enumerate(p):
        b, shout = 16 <= bar < 24, 24 <= bar < 32
        walking(s, "bass", bar, parts, low=32, vel=0.75)
        if shout:
            beat(s, bar, {"kick": "x.......x.......", "snare": "....x.......x...", "ride": "x..ox..ox..ox..o"}, vel=0.8)
            comp(s, "piano", bar, parts, "x.....x.........", low=53, vel=0.6, spread=0.0)
        elif b and bar % 2 == 1:
            # Stop-time: the band hits beat one and the typewriter fills the rest of the bar.
            beat(s, bar, {"kick": "x...............", "snare": "x..............."}, vel=0.75)
            _typewriter(s, bar, start=1.0, keys=8)
        else:
            beat(s, bar, {"ride": "x..ox..ox..ox..o", "pedalhat": "....o.......o...", "kick": "g.......g......."}, vel=0.7)
            if not b:
                comp(s, "piano", bar, parts, "x.....x.........", low=55, vel=0.45, spread=0.0)
        if bar in (7, 15, 31):
            roll(s, bar, start=3.0, count=4)
    melody(s, "clarinet", 0, BASEMENT_A, bars=8, vel=0.8)
    for bar in (3, 7):
        melody(s, "trumpet", bar, "r:3 Bb4:.5 C5", bars=1, vel=0.65)
    melody(s, "trumpet", 8, BASEMENT_A2, bars=8, vel=0.8)
    melody(s, "clarinet", 8, BASEMENT_HUM, bars=8, vel=0.5, transpose=-12)
    melody(s, "piano", 16, BASEMENT_B, bars=8, vel=0.75)
    # A filing drawer slams shut and the band shouts.
    s.hit("tom_floor", 24 * 4, vel=0.9)
    s.hit("crash", 24 * 4, vel=0.75)
    melody(s, "brass", 24, BASEMENT_SHOUT, bars=8, vel=0.85)
    melody(s, "clarinet", 24, BASEMENT_SHOUT, bars=8, vel=0.7)
    melody(s, "clarinet", 32, BASEMENT_A, bars=8, vel=0.82)
    melody(s, "trumpet", 32, BASEMENT_HUM, bars=8, vel=0.5)
    _typewriter(s, 39, start=2.5, keys=4)
    return s


# ---------------------------------------------------------------------------------------------
# The Unkempt Cemetery: a spooky waltz. A lone violin sings over a tuba "oom" and "pah-pah" knocked
# out on a xylophone like bones; a music box answers each long note; in the middle a ghost choir
# and celesta take it into G major over pizzicato; the wind gets up between sections. E minor, 3/4
# at 150 bpm. 52 bars: wind and music box (4), A violin (16), B choir in G (16), A' (12), the box
# alone (4).
# ---------------------------------------------------------------------------------------------

GRAVE_CHORDS = " ".join(["Em Em Cmaj7 B7",
                         "Em Am B7 Em C Am F#m7b5 B7 Em Am D G C Am B7 Em",
                         "G Em C D G B7 Em E7 Am D G Em C D7 G B7",
                         "Em Am B7 Em C Am B7 Em C Am B7 B7",
                         "Em Cmaj7 Am B7"])
GRAVE_A = ("B4:2 E5:1 | C5:1.5 B4:.5 A4:1 | D#5:2 F#5:1 | E5:3 | G5:2 E5:1 | A5:1.5 G5:.5 E5:1 | C5:2 A4:1 | B4:3 | "
           "E5:1 G5 B5 | C6:2 B5:1 | A5:1.5 F#5:.5 D5:1 | B5:3 | G5:1 E5 C5 | E5:1.5 C5:.5 A4:1 | D#5:1 F#5 A5 | G5:2 r:1")
GRAVE_B = ("D5:2 B4:1 | E5:1.5 G5:.5 B5:1 | C6:2 G5:1 | A5:3 | B5:1 A5 G5 | F#5:1.5 D#5:.5 B4:1 | E5:3 | G#5:2 r:1 | "
           "A5:1 C6 E6 | F#6:2 D6:1 | D6:1.5 B5:.5 G5:1 | E5:3 | E5:1 G5 C6 | A5:1.5 C6:.5 F#5:1 | G5:3 | F#5:1 A5 D#6")
GRAVE_A2 = ("B4:2 E5:1 | C5:1.5 B4:.5 A4:1 | D#5:2 F#5:1 | E5:3 | G5:2 E5:1 | A5:1.5 G5:.5 E5:1 | D#5:2 F#5:1 | E5:3 | "
            "G5:1 E5 C5 | A5:1.5 E5:.5 C5:1 | B4:1 D#5 F#5 | B5:2 r:1")
GRAVE_BOX = "E6:1 B5 G5 | E6:1.5 D6:.5 B5:1 | C6:1 A5 E5 | D#5:2 F#5:1"


def _wind(s, bar, bars=2):
    for n in ("C4", "G4"):
        s.note("wind", n, bar * 3, bars * 3 - 0.5, vel=0.45)


def unkempt_cemetery():
    s = Band(150, 52, meter=3, loudness=-18.5, room=0.7)
    s.part("violin", "orch_violin", level=0.7, pan=0.1, reverb=0.55)
    s.part("box", "musicbox", level=0.5, pan=0.3, reverb=0.6)
    s.part("bones", "orch_xylophone", level=0.5, pan=-0.2, reverb=0.4)
    s.part("tuba", "orch_tuba_short", level=0.7, reverb=0.3)
    s.part("pizz", "orch_pizz", level=0.55, pan=-0.15, reverb=0.45)
    s.part("ghosts", "oohs", level=0.55, pan=0.05, reverb=0.7)
    s.part("celesta", "celesta", level=0.4, pan=0.25, reverb=0.6)
    s.part("pad", "choirpad", level=0.28, reverb=0.7)
    s.part("wind", "seashore", level=0.25, reverb=0.8)
    s.kit("standard", level=0.6)
    p = _bars(GRAVE_CHORDS, 52, meter=3)
    _wind(s, 0, 4)
    _wind(s, 19, 2)
    _wind(s, 48, 4)
    for bar, parts in enumerate(p):
        intro, b, outro = bar < 4, 20 <= bar < 36, bar >= 48
        if intro or outro:
            comp(s, "pad", bar, parts, "x-----", low=52, vel=0.4, spread=0.0)
            continue
        bassline(s, "tuba", bar, parts, [(0, 0.9, 0)], low=33, vel=0.75)
        s.hit("kick", bar * 3, vel=0.4)
        if b:
            comp(s, "pizz", bar, parts, "..x.x.", low=55, vel=0.55, spread=0.0)
            comp(s, "pad", bar, parts, "x-----", low=55, vel=0.35, spread=0.0)
        else:
            comp(s, "bones", bar, parts, "..x.x.", low=60, vel=0.5, spread=0.0)
        if bar in (19, 35, 47):
            s.hit("vibraslap", bar * 3 + 1, vel=0.6)
    melody(s, "box", 0, GRAVE_BOX, bars=4, vel=0.55)
    melody(s, "violin", 4, GRAVE_A, bars=16, vel=0.75)
    for bar, notes in ((7, "r:1 E6:.5 B5 G5:1"), (11, "r:1 F#6:.5 D#6 B5:1"), (15, "r:1 D6:.5 B5 G5:1")):
        melody(s, "box", bar, notes, bars=1, vel=0.5)
    melody(s, "ghosts", 20, GRAVE_B, bars=16, vel=0.7)
    melody(s, "celesta", 20, GRAVE_B, bars=16, vel=0.45, transpose=12)
    melody(s, "violin", 36, GRAVE_A2, bars=12, vel=0.78)
    melody(s, "ghosts", 40, "B4:3 | C5:3 | B4:3 | B4:3 | C5:3 | C5:3 | B4:3 | B4:3", bars=8, vel=0.45)
    melody(s, "box", 48, GRAVE_BOX, bars=4, vel=0.55)
    return s
