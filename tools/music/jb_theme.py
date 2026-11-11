"""Harold's Jukebox: the shared material every jukebox song is built from.

The soundtrack is Harold's life on a jukebox: each depth plays the next decade of it (he is 18 in
1960), every path keeps its own joke in that decade's style, and Harold's whistle carries the hold
theme through all of it. Styles only, never anyone's song.

The hold theme is written here once, in F major, as melody text (see kit.py). Songs transpose it
(`melody(..., transpose=...)`), bend it into minor with `minor()`, or quote a phrase of it.
"""
import synth
from synth import chord, bass_note
from kit import at

# Extra chord qualities the jukebox songs use (synth.py's own songs never ask for these).
synth.QUALITY.update({"add9": [0, 4, 7, 14], "sus2": [0, 2, 7], "7sus4": [0, 5, 7, 10], "aug": [0, 4, 8],
                      "madd9": [0, 3, 7, 14], "5": [0, 7, 12], "6add9": [0, 4, 9, 14], "dim7": [0, 3, 6, 9],
                      "maj7#11": [0, 4, 11, 18], "m7add11": [0, 3, 10, 17]})

# The hold theme in F. A is two four-bar halves over THEME_A_CHORDS; B is eight bars over THEME_B_CHORDS.
THEME_A1 = "C5:.5 A4 C5 F5:1.5 E5:.5 D5 | E5:.5 C5 A4:2 r:1 | D5:.5 Bb4 D5 G5:1.5 F5:.5 E5 | F5:.5 D5 E5:2 r:1"
THEME_A2 = "C5:.5 A4 C5 F5:1.5 E5:.5 D5 | E5:.5 F5 A5:1.5 G5:.5 F5 D5 | Bb5:.5 A5 G5 F5 E5 D5 C5:1 | G5:1.5 E5:.5 C5:1 r:1"
THEME_A = THEME_A1 + " | " + THEME_A2
THEME_B = ("D5:1 F5:.5 A5:1.5 G5:.5 F5 | G5:1 F5:.5 Db5:1.5 Bb4:1 | E5:1 C5:.5 A4:1.5 G4:.5 A4 | "
           "F#4:.5 A4 C5 D5 F#5:1 A5 | G5:1.5 F5:.5 D5:1 Bb4 | A4:.5 Bb4 C5 E5 G5:1 Bb5 | A5:3 r:1 | "
           "G5:.5 F5 E5 D5 C5:1 r:1")
THEME_A_CHORDS = "Fmaj7 Dm7 Gm7 C7 Fmaj7 Dm7 Gm7 C7"
THEME_B_CHORDS = "Bbmaj7 Eb9 Am7 D7 Gm7 C7 Fmaj7 C7"
# The theme's opening bar alone: the motif players should hum.
MOTIF = "C5:.5 A4 C5 F5:1.5 E5:.5 D5"

_MINOR = {"A": "Ab", "E": "Eb", "D": "Db"}  # F major -> F minor: lower the 3rd, 6th and 7th


def minor(text):
    """The theme in F minor: every A, D and E (natural) flattened. Sharps and flats are left alone."""
    out = []
    for tok in text.split():
        name, sep, dur = tok.partition(":")
        if len(name) >= 2 and name[0] in _MINOR and name[1].isdigit():
            name = _MINOR[name[0]] + name[1:]
        out.append(name + sep + dur)
    return " ".join(out)


def travis(s, inst, bar, parts, low=55, bass_low=40, vel=0.6, pinch=True):
    """Fingerpicked guitar: the thumb alternates root and fifth on the beats, the fingers pick chord
    tones on the off-beats, and a pinch adds the top note on beats one and three."""
    for b in range(s.meter):
        sym = at(parts, b)
        root = bass_note(sym, bass_low)
        fifth = 6 if sym.endswith("dim") or sym.endswith("m7b5") else 7
        thumb = root if b % 2 == 0 else root + fifth - (12 if root + fifth > bass_low + 14 else 0)
        s.note(inst, thumb, bar * s.meter + b, 0.95, vel=vel)
        notes, _ = chord(sym, low)
        if pinch and b % 2 == 0:
            s.note(inst, notes[-1], bar * s.meter + b, 0.9, vel=vel * 0.75)
        s.note(inst, notes[(b + 1) % len(notes)], bar * s.meter + b + 0.5, 0.9, vel=vel * 0.7)


def walking(s, inst, bar, parts, low=36, vel=0.7):
    """A walking bass: root, chord tone, chord tone, then a step into the next bar's root."""
    sym = at(parts, 0)
    root = bass_note(sym, low)
    third = 3 if "m" in sym.replace("maj", "") else 4
    for b, m in enumerate([root, root + third, root + 7, root + 10 if "7" in sym else root + 9]):
        s.note(inst, m, bar * s.meter + b, 0.9, vel=vel * (1.0 if b == 0 else 0.85))
