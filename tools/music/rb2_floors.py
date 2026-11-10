"""Floor music, second try, made the way the Waiting Room is: background first.

Few instruments, one steady groove that carries the loop, the mood of the place rather than its
jokes, one melody voice that comes and goes, long calm phrases and a section where it drops back.
Floors get a little more pulse than the Waiting Room, for the fighting, and nothing more.
"""
from band import Band, beat
from kit import melody, prog, comp, bassline
from synth import chord
from kit import at

INFO = {
    "records_basement": dict(key="D minor", bpm=96, meter=4, bars=40, quiet=[(0, 2), (20, 28)],
                             about="Records Basement: dim and dusty, a muted guitar ostinato, upright bass, brushes, a low clarinet."),
}


def _bars(text, count):
    p = prog(text)
    assert len(p) == count, "progression has %d bars, not %d" % (len(p), count)
    return p


def figure(s, inst, bar, parts, order, step=0.5, low=57, vel=0.55, length=0.45):
    """An ostinato: chord tones in a fixed order of indexes, one every `step` beats."""
    t = 0.0; k = 0
    while t < s.meter - 1e-6:
        notes, _ = chord(at(parts, t), low)
        i = order[k % len(order)]
        m = notes[i % len(notes)] + 12 * (i // len(notes))
        s.note(inst, m, bar * s.meter + t, length, vel=vel * (1.0 if k % 4 == 0 else 0.85))
        t += step; k += 1


# ---------------------------------------------------------------------------------------------
# The Records Basement: endless filing cabinets under a flickering light, dusty, a little lonely,
# and Harold pressing on through it. D minor, 96 bpm, straight eighths. A muted guitar plays the same
# two-bar figure the whole way, like a lamp humming; an upright bass and brushes keep it walking; a
# Rhodes sets the chords; a low clarinet sings only in the middle of the loop. 40 bars: the guitar
# alone (4), the band (8), the clarinet (8), dropped back to guitar, bass and vibes (8), the
# clarinet again over soft strings (8), the band thinning out to the guitar (4).
# ---------------------------------------------------------------------------------------------

BASEMENT_A = "Dm9 Dm9 Bbmaj7 Bbmaj7 Gm9 Gm9 A7sus4 A7"
BASEMENT_B = "Fmaj7 C Dm9 Bbmaj7 Gm7 Am7 Bbmaj7 A7"
BASEMENT_C = "Dm9 Em7 Dm9 Em7 Dm9 Em7 Bbmaj7 A7sus4"
BASEMENT_CHORDS = " ".join(["Dm9 Dm9 Bbmaj7 A7sus4", BASEMENT_A, BASEMENT_B, BASEMENT_C, BASEMENT_B, "Dm9 Dm9 Bbmaj7 A7"])
CLARINET = ("A4:1.5 C5:.5 E5:2 | D5:1 C5:.5 G4:2.5 | F4:.5 A4 C5:1 E5:1.5 D5:.5 | D5:3 r:1 | "
            "Bb4:1.5 D5:.5 F5:2 | E5:1 C5:.5 A4:2.5 | D5:.5 C5 Bb4 A4 F4:2 | E4:1 G4 C#5:2")
CLARINET_2 = ("A4:1.5 C5:.5 E5:2 | D5:1 C5:.5 G4:2.5 | F4:.5 A4 C5:1 E5:1.5 D5:.5 | D5:3 r:1 | "
              "Bb4:1.5 D5:.5 F5:2 | E5:1 C5:.5 A4:2.5 | D5:.5 E5 F5 G5 A5:2 | G5:1 E5 C#5:2")
LAMP = [0, 2, 1, 3, 2, 1, 4, 1]  # the guitar's figure


def records_basement():
    s = Band(96, 40, loudness=-20.0, room=0.5)
    s.part("gtr", "mutedgtr", level=0.62, pan=-0.5, reverb=0.35)
    s.part("bass", "upright", level=0.66, reverb=0.12)
    s.part("rhodes", "epiano", level=0.42, pan=0.5, reverb=0.4, chorus=0.25)
    s.part("clarinet", "orch_clarinet", level=0.6, pan=0.1, reverb=0.45)
    s.part("vibes", "vibes", level=0.34, pan=0.5, reverb=0.5)
    s.part("strings", "slowstrings", level=0.28, pan=-0.3, reverb=0.6, chorus=0.4)
    s.kit("brush", level=0.68)
    p = _bars(BASEMENT_CHORDS, 40)
    for bar, parts in enumerate(p):
        intro, a, b1, c, b2, outro = bar < 4, 4 <= bar < 12, 12 <= bar < 20, 20 <= bar < 28, 28 <= bar < 36, bar >= 36
        figure(s, "gtr", bar, parts, LAMP, low=57, vel=0.6 if intro or outro else 0.52)
        if bar >= 2:
            bassline(s, "bass", bar, parts, [(0, 1.4, 0), (1.5, 0.45, 0), (2, 1.4, 7), (3.5, 0.45, 10)] if not c else [(0, 3.8, 0)], low=31, vel=0.7)
        if intro or outro:
            beat(s, bar, {"rim": "....o.......o..."}, vel=0.55)
        elif c:
            beat(s, bar, {"shaker": "g.g.g.g.g.g.g.g."}, vel=0.6)
        else:
            beat(s, bar, {"kick": "o.......o.....g.", "snare": "....o.......o...", "shaker": "g.g.g.g.g.g.g.g."}, vel=0.72)
        if intro and bar >= 2:
            comp(s, "rhodes", bar, parts, "x---------------", low=53, vel=0.3)
        if a or b1 or b2:
            comp(s, "rhodes", bar, parts, "x-------...o----" if a else "x---------------", low=53, vel=0.38)
        if c:
            comp(s, "vibes", bar, parts, "x-------x-------", low=60, vel=0.36)
        if b2:
            comp(s, "strings", bar, parts, "x---------------", low=57, vel=0.45)
    melody(s, "clarinet", 12, CLARINET, bars=8, vel=0.68)
    melody(s, "clarinet", 28, CLARINET_2, bars=8, vel=0.72)
    return s
