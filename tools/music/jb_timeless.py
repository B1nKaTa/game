"""Harold's Jukebox, the songs outside the decades: the Waiting Room, the title and the landings."""
from band import Band, beat, roll
from kit import melody, prog, comp, bassline, arp
from jb_theme import THEME_A, THEME_B, THEME_A_CHORDS, THEME_B_CHORDS, MOTIF, travis

INFO = {
    "please_hold": dict(key="F major", bpm=80, meter=4, bars=32,
                        about="Waiting Room: a calm porch afternoon, fingerpicked guitar and brushes, Harold whistling the hold theme."),
    "take_a_number": dict(key="Bb major", bpm=112, meter=4, bars=24, quiet=[(0, 2)],
                          about="Title: a coin in the jukebox, the whistle alone, then a jaunty brass shuffle."),
    "landing": dict(key="Ab major", bpm=70, meter=4, bars=16,
                    about="Landings: between records, music box and celesta, the motif whistled far away."),
}

TWO_FEEL = [(0, 1.8, 0), (2, 1.8, 7)]


def _bars(text, count):
    p = prog(text)
    assert len(p) == count, "progression has %d bars, not %d" % (len(p), count)
    return p


# ---------------------------------------------------------------------------------------------
# Please Hold: the Waiting Room. Calm and warm, never elevator music: a sunny afternoon on the
# porch. F major, 80 bpm, a light swing. A fingerpicked steel guitar, brushes and an upright bass;
# Harold whistles the hold theme, a clarinet takes the middle, a few birds. 32 bars: guitar alone
# (4), whistle (8), clarinet (8), whistle with vibes and strings (8), a piano goodbye (4).
# ---------------------------------------------------------------------------------------------

PORCH_OUTRO = "Bb4:.5 A4 Bb4 D5:1.5 C5:.5 Bb4 | A4:2 C5:2 | Bb4:.5 A4 G4 F4 G4:2 | E4:2 r:2"
PORCH_CHORDS = " ".join(["Fmaj7 Dm7 Bbmaj7 C7sus4", THEME_A_CHORDS, THEME_B_CHORDS, THEME_A_CHORDS, "Bbmaj7 Am7 Gm7 C7"])


def please_hold():
    s = Band(80, 32, swing=0.08, loudness=-21.0, room=0.5)
    s.part("gtr", "steel", level=0.72, pan=-0.25, reverb=0.3)
    s.part("bass", "upright", level=0.62, reverb=0.15)
    s.part("piano", "piano", level=0.5, pan=0.3, reverb=0.45)
    s.part("whistle", "whistle", level=0.52, pan=0.05, reverb=0.5)
    s.part("clarinet", "orch_clarinet", level=0.62, pan=0.1, reverb=0.45)
    s.part("strings", "slowstrings", level=0.34, reverb=0.6)
    s.part("vibes", "vibes", level=0.36, pan=0.4, reverb=0.5)
    s.part("birds", "bird", level=0.22, pan=0.6, reverb=0.6)
    s.kit("brush", level=0.7)
    p = _bars(PORCH_CHORDS, 32)
    for bar, parts in enumerate(p):
        intro, a1, b, a2, outro = bar < 4, 4 <= bar < 12, 12 <= bar < 20, 20 <= bar < 28, bar >= 28
        travis(s, "gtr", bar, parts, low=55, bass_low=40, vel=0.62 if intro or outro else 0.55)
        if bar >= 2:
            bassline(s, "bass", bar, parts, TWO_FEEL, low=29, vel=0.7)
        if not intro:
            beat(s, bar, {"snare": "....o.......o...", "pedalhat": "....g.......g...", "kick": "g.......g......."}, vel=0.75)
        if b:
            beat(s, bar, {"ride": "o...o...o...o..."}, vel=0.45)
        if a1 and bar % 2 == 0:
            comp(s, "piano", bar, parts, "x-------........", low=53, vel=0.32)
        if b or a2:
            comp(s, "strings", bar, parts, "x---------------", low=53, vel=0.5)
        if a2:
            comp(s, "piano", bar, parts, "....o-......o-..", low=57, vel=0.3)
            arp(s, "vibes", bar, parts, step=1.0, low=65, octaves=1, vel=0.32, pan=0.0, length=0.9)
    melody(s, "whistle", 4, THEME_A, bars=8, vel=0.75, transpose=12)
    melody(s, "clarinet", 12, THEME_B, bars=8, vel=0.7)
    melody(s, "whistle", 20, THEME_A, bars=8, vel=0.78, transpose=12)
    melody(s, "piano", 28, PORCH_OUTRO, bars=4, vel=0.5)
    # A couple of birds in the garden, at the start and at the end.
    for bar, notes in ((0, ("E7", "G7", "E7")), (2, ("D7", "F7")), (29, ("E7", "G7", "E7", "C7"))):
        for k, n in enumerate(notes):
            s.note("birds", n, bar * 4 + 1.5 + k * 0.22, 0.18, vel=0.5)
    return s


# ---------------------------------------------------------------------------------------------
# Take a Number: the title. A coin drops into the jukebox, the needle finds the groove, and Harold
# whistles the motif alone before a jaunty brass-and-guitar shuffle picks it up. Bb major, 112 bpm.
# 24 bars: coin and whistle (2), A on trumpet with whistle answers (8), B on saxes (8), A on
# whistle and band (6).
# ---------------------------------------------------------------------------------------------

TITLE_CHORDS = " ".join(["Bb Bb", "Bb6 Gm7 Cm7 F7 Bb6 Gm7 Cm7 F7", "Ebmaj7 Ab9 Dm7 G7 Cm7 F7 Bb6 F7", "Bb6 Gm7 Cm7 F7 Bb6 F7"])
SHUFFLE = {"kick": "x.....x.x.......", "snare": "....x.......x...", "hat": "x..ox..ox..ox..o"}


def take_a_number():
    s = Band(112, 24, swing=0.16, loudness=-17.0, room=0.45)
    s.part("whistle", "whistle", level=0.55, reverb=0.45)
    s.part("trumpet", "trumpet", level=0.6, pan=0.15, reverb=0.35)
    s.part("sax", "tenorsax", level=0.6, pan=-0.2, reverb=0.35)
    s.part("brass", "brass", level=0.42, reverb=0.35)
    s.part("gtr", "jazzgtr", level=0.5, pan=-0.35, reverb=0.25)
    s.part("piano", "honkytonk", level=0.42, pan=0.35, reverb=0.3)
    s.part("bass", "upright", level=0.72, reverb=0.1)
    s.kit("jazz", level=0.75)
    p = _bars(TITLE_CHORDS, 24)
    # The coin, the arm, the needle.
    for t, kind in ((0.0, "click"), (0.25, "click"), (1.0, "sticks"), (1.5, "sticks")):
        s.hit(kind, t, vel=0.6)
    melody(s, "whistle", 0, "r:2.5 F5:.5 D5 F5 | Bb5:1.5 A5:.5 G5:1 r:1", bars=2, vel=0.7, transpose=12)
    for bar, parts in enumerate(p):
        if bar < 2:
            continue
        bassline(s, "bass", bar, parts, [(0, 0.9, 0), (1, 0.9, 4), (2, 0.9, 7), (3, 0.9, 9)], low=34, vel=0.75)
        beat(s, bar, SHUFFLE, vel=0.75)
        comp(s, "gtr", bar, parts, "..x...x...x...x.", low=55, vel=0.45)
        comp(s, "piano", bar, parts, "x.......x.......", low=60, vel=0.35)
        if 10 <= bar < 18:
            comp(s, "brass", bar, parts, "x-.....x-.......", low=58, vel=0.5)
        if bar in (9, 17):
            roll(s, bar, start=3.0, count=4)
    title_a = "F4:.5 D4 F4 Bb4:1.5 A4:.5 G4 | A4:.5 F4 D4:2 r:1 | G4:.5 Eb4 G4 C5:1.5 Bb4:.5 A4 | Bb4:.5 G4 A4:2 r:1"
    title_a2 = "F4:.5 D4 F4 Bb4:1.5 A4:.5 G4 | A4:.5 Bb4 D5:1.5 C5:.5 Bb4 G4 | Eb5:.5 D5 C5 Bb4 A4 G4 F4:1 | C5:1.5 A4:.5 F4:1 r:1"
    title_b = ("G4:1 Bb4:.5 D5:1.5 C5:.5 Bb4 | C5:1 Bb4:.5 Gb4:1.5 Eb4:1 | A4:1 F4:.5 D4:1.5 C4:.5 D4 | "
               "B3:.5 D4 F4 G4 B4:1 D5 | C5:1.5 Bb4:.5 G4:1 Eb4 | D4:.5 Eb4 F4 A4 C5:1 Eb5 | D5:3 r:1 | C5:.5 Bb4 A4 G4 F4:1 r:1")
    melody(s, "trumpet", 2, title_a + " | " + title_a2, bars=8, vel=0.8, transpose=12)
    for bar in (3, 5, 7, 9):
        melody(s, "whistle", bar, "r:3 F5:.5 G5", bars=1, vel=0.6, transpose=12)
    melody(s, "sax", 10, title_b, bars=8, vel=0.8, transpose=12)
    melody(s, "whistle", 18, title_a + " | F4:.5 D4 F4 Bb4:1.5 A4:.5 G4 | Bb4:2 r:2", bars=6, vel=0.78, transpose=24)
    melody(s, "trumpet", 18, title_a + " | F4:.5 D4 F4 Bb4:1.5 A4:.5 G4 | Bb4:2 r:2", bars=6, vel=0.6, transpose=12)
    s.hit("crash", 2 * 4, vel=0.6)
    return s


# ---------------------------------------------------------------------------------------------
# The Landing: between records. The jukebox's arm lifts, a soft hum while it finds the next one: a
# music box and celesta over warm pads, the motif whistled far away. Ab major, 70 bpm, 16 bars.
# ---------------------------------------------------------------------------------------------

LANDING_CHORDS = "Abmaj7 Fm7 Dbmaj7 Eb7sus4 Abmaj7 Cm7 Dbmaj7 Eb7 Fm7 Dbmaj7 Bbm7 Eb7 Abmaj7 Dbmaj7 Bbm7 Eb7sus4"


def landing():
    s = Band(70, 16, loudness=-22.0, room=0.7)
    s.part("box", "musicbox", level=0.55, pan=0.25, reverb=0.6)
    s.part("celesta", "celesta", level=0.45, pan=-0.25, reverb=0.6)
    s.part("pad", "warmpad", level=0.42, reverb=0.7)
    s.part("strings", "slowstrings", level=0.3, reverb=0.7)
    s.part("whistle", "whistle", level=0.32, reverb=0.85)
    s.part("bass", "fretless", level=0.42, reverb=0.3)
    p = _bars(LANDING_CHORDS, 16)
    for bar, parts in enumerate(p):
        comp(s, "pad", bar, parts, "x---------------", low=51, vel=0.5)
        if bar >= 4:
            comp(s, "strings", bar, parts, "x---------------", low=58, vel=0.42)
            bassline(s, "bass", bar, parts, [(0, 3.8, 0)], low=32, vel=0.55)
        arp(s, "celesta" if bar % 4 < 2 else "box", bar, parts, step=0.5, low=68, octaves=2, vel=0.4, pan=0.3)
    # The motif, whistled far off in Ab, twice, and answered by the music box.
    for bar in (4, 12):
        melody(s, "whistle", bar, "Eb5:.5 C5 Eb5 Ab5:1.5 G5:.5 F5 | G5:.5 Eb5 C5:2 r:1", bars=2, vel=0.6, transpose=12)
        melody(s, "box", bar + 2, "r:2 Eb6:.5 C6 Ab5 F5 | G5:4", bars=2, vel=0.5)
    return s
