"""The ending songs and the game-over sting."""
from synth import Song, chord, bass_note
from kit import mel, melody, prog, comp, bassline, drums
from songs import HOLD_A1, HOLD_A2, HOLD_A_CHORDS
from places import BOSSA, BOSSA_BASS, _bars, piano_left_hand


# ---------------------------------------------------------------------------------------------
# The ending: warm, a little bittersweet, a little silly. F, 84 bpm. A piano plays the hold theme
# slowly and kindly; the strings take a new tune that turns from major to minor and back, while a
# bassoon grumbles in the gaps; and a music box plays the theme's opening once more, with a ding.
# 20 bars: A (8), B (8), A short (4).
# ---------------------------------------------------------------------------------------------

END_B = ("D5:1.5 C5:.5 Bb4:1 F5 | Db5:1.5 C5:.5 Bb4:1 G4 | C5:1.5 E5:.5 G5:1 A5 | F#5:2 r:1 A4 | "
         "Bb4:1.5 D5:.5 F5:1 G5 | E5:1.5 D5:.5 C5:1 Bb4 | A4:1 C5 F5 E5:.5 F5 | G5:2 r:2")
END_CHORDS = " ".join(HOLD_A_CHORDS) + " | Bbmaj7 Bbm6 Am7 D7 Gm7 C7 Fmaj7 C7 | " + " ".join(HOLD_A_CHORDS[:4])


def ending():
    s = Song(84, 20 * 4, reverb=0.45)
    p = _bars(prog(END_CHORDS), 20)
    for bar, parts in enumerate(p):
        if bar < 8:
            piano_left_hand(s, bar, parts, low=36, vel=0.42, gain=0.22)
        elif bar < 16:
            comp(s, "piano", bar, parts, "x-------x-------", low=55, vel=0.45, gain=0.2, spread=0.5)
        else:
            comp(s, "vibes", bar, parts, "x-------x-------", low=60, vel=0.4, gain=0.15, spread=0.6)
        comp(s, "pad", bar, parts, "x---------------", low=53, vel=0.45, gain=0.08 if bar < 8 or bar >= 16 else 0.05, spread=0.8)
        bassline(s, "bass", bar, parts, [(0, 1.9, 0), (2, 1.9, 7)], low=33, vel=0.6, gain=0.5)
    s.line("piano", 0, HOLD_A1 + HOLD_A2, vel=0.7, gain=0.62, pan=0.15, bars=8)
    melody(s, "pad", 8, END_B, bars=8, vel=0.75, gain=0.5, wide=True)
    melody(s, "piano", 8, END_B, bars=8, vel=0.5, gain=0.22, pan=0.2)
    s.line("bassoon", 11 * 4 + 2, mel("D3:.5 C3 A2 F#2", 2)[0], vel=0.8, gain=0.55, legato=0.7, pan=-0.3)
    s.line("bassoon", 15 * 4 + 2, mel("C3:.5 r G2:1", 2)[0], vel=0.8, gain=0.55, legato=0.7, pan=-0.3)
    s.line("musicbox", 16 * 4, HOLD_A1, vel=0.7, gain=0.6, transpose=12, pan=-0.1, bars=4)
    s.note("bell", "C6", 19 * 4 + 3, 1, vel=0.5, gain=0.35, pan=0.3)
    s.note("bell", "A5", 19 * 4 + 3.5, 1, vel=0.45, gain=0.35, pan=0.3)
    return s


# ---------------------------------------------------------------------------------------------
# Eternal Feud, the true ending: a duet in F, 120 bpm, swinging gently over the hold music's bossa.
# Harold has the hold theme on the chip lead; Gerald, the neighbour, has a grumpy staccato bassoon
# tune. Gerald starts, Harold answers, Gerald gets louder, then they play both at once (the tunes
# fit), argue a bar each, and finish together, each insisting on the last word. 28 bars.
# ---------------------------------------------------------------------------------------------

GERALD = "F3:.5 r F3 r E3 F3 A3:1 | D3:.5 r D3 E3 F3 r A3 G#3 | G3:.5 r Bb3 r D4:1 C#4 | C4:.5 Bb3 G3 E3 C3:1 r"
GERALD2 = "A3:.5 r A3 G3 F3:1 C3 | D3:.5 F3 A3 C4 B3:1 Bb3 | A3:.5 r G3 r F3 E3 D3:1 | C3:1 E3:.5 G3 C4:1 r"
FEUD_CHORDS = " ".join(HOLD_A_CHORDS[:4] * 5) + " | F C7 F C7 | F Gm7,C7 F C13"


def eternal_feud():
    s = Song(120, 28 * 4, reverb=0.3, swing=0.08)
    p = _bars(prog(FEUD_CHORDS), 28)
    for bar, parts in enumerate(p):
        argue = 20 <= bar < 24
        if argue:
            # The band stops to watch: a stab on one, a held chord, and a rim shot after each line.
            comp(s, "epiano", bar, parts, "x-......x-------", low=55, vel=0.55, gain=0.28, spread=0.5)
            comp(s, "pad", bar, parts, "x---------------", low=55, vel=0.5, gain=0.1, spread=0.7)
            bassline(s, "bass", bar, parts, [(0, 0.9, 0), (2, 1.9, 7)], low=36, vel=0.85, gain=0.8)
            drums(s, bar, {"brush": "x...o...x...o...", "kick": "x.......o......."}, scale=0.65)
            s.hit("rim", bar * 4 + 3.5, vel=0.7, gain=0.45, pan=0.2)
        else:
            comp(s, "epiano", bar, parts, BOSSA[bar % 2], low=55, vel=0.5, gain=0.26, spread=0.5)
            bassline(s, "bass", bar, parts, BOSSA_BASS, low=36, vel=0.8, gain=0.75)
            drums(s, bar, {"brush": "x.o.x.o.x.o.x.o.", "rim": "x.....x.....x..." if bar % 2 == 0 else "....x...x.......",
                           "kick": "x.........o....."}, scale=0.65)
    gerald = dict(vel=0.85, gain=0.62, legato=0.6, pan=-0.3)
    harold = dict(vel=0.85, gain=0.5, wide=True)
    melody(s, "bassoon", 0, GERALD, bars=4, **gerald)
    s.line("pulse", 4 * 4, HOLD_A1, bars=4, **harold)
    s.line("bassoon", 5 * 4 + 3, mel("C#3:.5 D3", 1)[0], **gerald)
    s.line("bassoon", 7 * 4 + 3, mel("G2:.5 C3", 1)[0], **gerald)
    melody(s, "bassoon", 8, GERALD, bars=4, **dict(gerald, gain=0.72))
    melody(s, "brass", 8, GERALD, bars=4, vel=0.75, gain=0.3, legato=0.6, pan=-0.45)
    s.line("pulse", 12 * 4, HOLD_A1 + HOLD_A2, bars=8, **harold)
    melody(s, "bassoon", 12, GERALD + " | " + GERALD2, bars=8, **gerald)
    # The argument, a bar each.
    melody(s, "pulse", 20, "C5:.5 A4 C5 F5:1.5 r:1", bars=1, **harold)
    melody(s, "bassoon", 21, "E3:.5 E3 G3 C4:1.5 r:1", bars=1, **gerald)
    melody(s, "pulse", 22, "A5:.5 F5 A5 C6:1.5 r:1", bars=1, **harold)
    melody(s, "bassoon", 23, "Bb3:.5 G3 E3 C3:1.5 r:1", bars=1, **gerald)
    # Together, and each wants the last word.
    melody(s, "pulse", 24, "F5:1 A5 C6 A5 | Bb5:1 G5 E5:2 | F5:2 r:2 | r:2 C6:.5 r:1.5", bars=4, **harold)
    melody(s, "bassoon", 24, "F3:1 C3 A2 C3 | G2:1 Bb2 C3:2 | r:2 F2:1 r | r:3 C3:.5 r:.5", bars=4, **gerald)
    return s


# ---------------------------------------------------------------------------------------------
# Game over: a five-second sting, not a loop. The hold theme starts cheerfully and deflates down a
# chromatic slide, a tuba sighs, and a bell closes it: please take a number.
# ---------------------------------------------------------------------------------------------

def game_over():
    s = Song(96, 6, reverb=0.4, meter=6, loop=False, tail=1.7)
    melody(s, "pulse", 0, "C5:.5 A4 C5 F5:1 E5:.5 Eb5 D5 Db5:1.5 r:.5", bars=1, vel=0.85, gain=0.6, wide=True)
    for m in chord("F", 55)[0]:
        s.note("epiano", m, 0, 2.5, vel=0.5, gain=0.3)
    for m in chord("Bbm", 53)[0]:
        s.note("epiano", m, 3.5, 2, vel=0.45, gain=0.28)
    s.note("brass", "F2", 4.5, 1.5, vel=0.75, gain=0.45)
    s.note("bass", "F2", 4.5, 1.5, vel=0.7, gain=0.5)
    s.note("bell", "F4", 5.5, 1, vel=0.5, gain=0.4, pan=0.2)
    s.hit("brush", 5.5, vel=0.5, gain=0.3)
    return s
