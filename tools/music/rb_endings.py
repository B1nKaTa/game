"""The endings and the game-over sting, each its own piece: no theme shared with any other song."""
from band import Band, beat
from kit import melody, prog, comp, bassline, arp
from synth import chord, bass_note

INFO = {
    "ending": dict(key="Eb major", bpm=76, meter=4, bars=26,
                   about="Ending: warm and a little bittersweet; piano, then strings turning minor with a grumbling bassoon, then a music box and harp."),
    "eternal_feud": dict(key="G major", bpm=116, meter=4, bars=32,
                         about="True ending: Harold's trumpet against Gerald's grumpy bassoon, each with his own tune, arguing over a swinging combo and finishing together."),
    "game_over": dict(key="C major", bpm=100, meter=4, bars=2, loop=False,
                      about="Death sting: a cheerful clarinet run that deflates, a tuba sigh, and a bell. Plays once."),
}


def _bars(text, count):
    p = prog(text)
    assert len(p) == count, "progression has %d bars, not %d" % (len(p), count)
    return p


def _walk(s, inst, bar, parts, nxt, low=31, vel=0.7):
    """A walking bass: root, third, fifth, then a half-step into the next bar's root. A bar with two
    chords walks root and fifth of each."""
    target = bass_note(nxt[0][2], low)
    if len(parts) == 1:
        r = bass_note(parts[0][2], low)
        tones = chord(parts[0][2], r)[0]
        line = [r, tones[1], tones[2], target - 1 if target - 1 != tones[2] else target + 1]
    else:
        r1 = bass_note(parts[0][2], low); r2 = bass_note(parts[1][2], low)
        line = [r1, chord(parts[0][2], r1)[0][2], r2, target - 1]
    for b, m in enumerate(line):
        s.note(inst, m, bar * s.meter + b, 0.9, vel=vel * (1.0 if b == 0 else 0.82))


# ---------------------------------------------------------------------------------------------
# The ending: warm, a little bittersweet, a little silly. Eb major, 76 bpm, no drums. A piano sings a
# kind tune over its own broken chords; the strings take a second tune that leans into minor (the
# Abm6), while a bassoon grumbles in the gaps; a music box and a harp go round once more with a
# clarinet holding underneath, the bassoon has the last harrumph, and the piano turns it home.
# 26 bars: piano alone (2), A on piano (8), B on strings (8), C on music box (6), turnaround (2).
# ---------------------------------------------------------------------------------------------

END_A = ("G4:1 Bb4:.5 Eb5:1.5 D5:.5 Bb4 | D5:1.5 C5:.5 Bb4:2 | C5:1 Eb5:.5 G5:1.5 F5:.5 Eb5 | D5:2 r:1 Bb4:.5 C5 | "
         "D5:1 Bb4:.5 G4:1.5 Bb4:.5 Eb5 | G5:1.5 F5:.5 Eb5:1 D5 | C5:.5 D5 Eb5 F5 Ab5:1.5 G5:.5 | F5:3 r:1")
END_B = ("Eb5:1.5 C5:.5 Ab4:1 G4 | F4:1.5 Ab4:.5 B4:2 | Bb4:1.5 D5:.5 F5:1 D5 | Eb5:2 r:1 G4 | "
         "Ab4:1.5 C5:.5 Eb5:1 F5 | Eb5:1.5 B4:.5 Ab4:1 F4 | G4:2 Bb4:1 D5 | C5:.5 Bb4 Ab4 F4 D4:2")
END_C = "G5:1 Bb5:.5 Eb6:1.5 D6:.5 Bb5 | D6:1.5 C6:.5 Bb5:2 | C6:1 Eb6:.5 G6:1.5 F6:.5 Eb6 | D6:2 r:2 | D6:1 Bb5:.5 G5:1.5 Bb5:.5 Eb6 | Eb6:4"
END_C_CLARINET = "Bb4:4 | Bb4:4 | C5:4 | B4:4 | Bb4:4 | Ab4:4"
END_TURN = "G4:.5 Bb4 Eb5 G5 F5:2 | D5:.5 C5 Bb4 Ab4 F4:2"
END_CHORDS = " ".join(["Ebmaj7 Abmaj7",
                       "Ebmaj7 Gm7 Abmaj7 Bb7 Ebmaj7 Cm7 Fm7 Bb7",
                       "Abmaj7 Abm6 Gm7 Cm7 Fm7 Abm6 Ebmaj7 Bb7",
                       "Ebmaj7 Gm7 Abmaj7 Abm6 Ebmaj7 Bb7",
                       "Cm7 Bb7"])
TWO_FEEL = [(0, 1.8, 0), (2, 1.8, 7)]


def ending():
    s = Band(76, 26, loudness=-19.0, room=0.65)
    s.part("piano", "piano", level=0.62, pan=0.1, reverb=0.45)
    s.part("violin", "orch_violin", level=0.66, pan=0.2, reverb=0.55)
    s.part("strings", "slowstrings", level=0.34, reverb=0.6, chorus=0.3)
    s.part("bassoon", "orch_bassoon", level=0.7, pan=-0.3, reverb=0.4)
    s.part("box", "musicbox", level=0.55, pan=0.3, reverb=0.55)
    s.part("harp", "orch_harp", level=0.5, pan=-0.3, reverb=0.5)
    s.part("clarinet", "orch_clarinet", level=0.48, pan=-0.15, reverb=0.5)
    s.part("bass", "upright", level=0.5, reverb=0.2)
    p = _bars(END_CHORDS, 26)
    for bar, parts in enumerate(p):
        intro, a, b, c, turn = bar < 2, 2 <= bar < 10, 10 <= bar < 18, 18 <= bar < 24, bar >= 24
        if intro or a or turn:
            arp(s, "piano", bar, parts, step=0.5, low=48, octaves=2, vel=0.34, pan=0.0, length=0.9)
        if b:
            comp(s, "piano", bar, parts, "x-------x-------", low=55, vel=0.3)
        if b or c:
            comp(s, "strings", bar, parts, "x---------------", low=53, vel=0.5)
        if c:
            arp(s, "harp", bar, parts, step=0.5, low=55, octaves=2, vel=0.42, pan=0.0)
        if not intro:
            bassline(s, "bass", bar, parts, TWO_FEEL, low=31, vel=0.62)
    melody(s, "piano", 2, END_A, bars=8, vel=0.62)
    melody(s, "violin", 10, END_B, bars=8, vel=0.7)
    melody(s, "box", 18, END_C, bars=6, vel=0.6)
    melody(s, "clarinet", 18, END_C_CLARINET, bars=6, vel=0.45)
    melody(s, "piano", 24, END_TURN, bars=2, vel=0.55)
    # The bassoon grumbles into the tunes' gaps, and has the last harrumph.
    for bar, start, notes in ((5, 2, "Bb2:.5 A2 Ab2:1"), (9, 3, "F2:.5 E2"), (13, 2, "C3:.5 B2 Bb2:1"),
                              (17, 2.5, "Ab2:.5 G2 F2"), (23, 2, "Bb2:.5 r Bb1:1")):
        notes_beats = [(n.split(":")[0], float(n.split(":")[1]) if ":" in n else None) for n in notes.split()]
        at = bar * 4 + start; last = 0.5
        for name, d in notes_beats:
            last = d if d is not None else last
            if name != "r":
                s.note("bassoon", name, at, last * 0.7, vel=0.72)
            at += last
    return s


# ---------------------------------------------------------------------------------------------
# Eternal Feud, the true ending: Harold and Gerald, still at it. G major, 116 bpm, a swinging combo
# on brushes. Gerald grumbles his staccato bassoon tune, Harold answers on a cocky trumpet while
# Gerald heckles, then both play their tunes at once (they fit, though neither admits it); the band
# stops while they argue a bar each, a tuba and clarinet join the row, and they finish together,
# each insisting on the last word. 32 bars: vamp (2), Gerald (4), Harold (4), together (8),
# argument (4), together louder (6), last word (2), turnaround (2).
# ---------------------------------------------------------------------------------------------

GERALD_X = "G2:.5 r B2 r D3 r E3:1 | E3:.5 r G3 r B2:1 r:1 | A2:.5 C3 E3 G3 F#3 r E3:1 | D3:.5 r D3 r C3 A2 F#2:1"
GERALD_Y = "B2:.5 r D3 r F#3:1 E3 | G#2:.5 r B2 r D3:1 r | C3:.5 r C3 E3 A3:1 G3 | F#3:.5 E3 D3 C3 A2:1 r"
HAROLD_X = "B4:1 D5:.5 E5:1.5 D5:.5 B4 | G4:1.5 A4:.5 B4:1 r:1 | C5:1 E5:.5 G5:1.5 F#5:.5 E5 | F#5:2 r:2"
HAROLD_Y = ("F#5:1 D5:.5 B4:1.5 A4:.5 B4 | G#4:1 B4:.5 E5:1.5 D5:.5 B4 | C5:.5 B4 A4 G4 E4:1 G4 | "
            "F#4:1 A4:.5 D5:1.5 C5:.5 A4")
FEUD_X = "G6 Em7 Am7 D7"
FEUD_CHORDS = " ".join(["G6 D7", FEUD_X, FEUD_X, FEUD_X, "Bm7 E7 Am7 D7", "Cmaj7 Cm6 Bm7,E7 Am7,D7",
                        FEUD_X, "Am7 D7", "G6 G6", "Am7 D7"])
SWING_KIT = {"ride": "o...o.o.o...o.o.", "pedalhat": "....o.......o...", "kick": "g.......g......."}


def eternal_feud():
    s = Band(116, 32, swing=0.1, loudness=-19.0, room=0.45)
    s.part("trumpet", "orch_trumpet", level=0.62, pan=0.3, reverb=0.35)
    s.part("bassoon", "orch_bassoon_short", level=0.78, pan=-0.3, reverb=0.3)
    s.part("tuba", "orch_tuba_short", level=0.55, pan=-0.35, reverb=0.25)
    s.part("clarinet", "orch_clarinet", level=0.42, pan=0.25, reverb=0.35)
    s.part("piano", "piano", level=0.46, pan=0.1, reverb=0.3)
    s.part("horns", "brass", level=0.3, reverb=0.4)
    s.part("bass", "upright", level=0.66, reverb=0.12)
    s.kit("brush", level=0.68)
    p = _bars(FEUD_CHORDS, 32)
    for bar, parts in enumerate(p):
        argue = 18 <= bar < 22
        nxt = p[(bar + 1) % 32]
        if argue:
            # The band stops to watch: a stab on one and a rim shot after each line.
            comp(s, "piano", bar, parts, "x-..............", low=55, vel=0.5)
            bassline(s, "bass", bar, parts, [(0, 0.9, 0)], low=31, vel=0.8)
            s.hit("rim", bar * 4 + 3.5, vel=0.65)
            continue
        _walk(s, "bass", bar, parts, nxt, vel=0.7)
        comp(s, "piano", bar, parts, "x..x....x..x...." if bar % 2 else "..x...x...x..x..", low=55, vel=0.38)
        beat(s, bar, SWING_KIT, vel=0.75)
        if 22 <= bar < 28:
            comp(s, "horns", bar, parts, "x-------x-------", low=55, vel=0.45)
            beat(s, bar, {"snare": "....g.......o..."}, vel=0.7)
    melody(s, "bassoon", 2, GERALD_X, bars=4, vel=0.82, legato=0.7)
    melody(s, "trumpet", 6, HAROLD_X, bars=4, vel=0.78)
    # Gerald heckles in Harold's gaps.
    melody(s, "bassoon", 7, "r:3 E3:.5 D3", bars=1, vel=0.8, legato=0.7)
    melody(s, "bassoon", 9, "r:2 C3:.5 B2 Bb2 A2", bars=1, vel=0.85, legato=0.7)
    # Both at once.
    melody(s, "bassoon", 10, GERALD_X + " | " + GERALD_Y, bars=8, vel=0.82, legato=0.7)
    melody(s, "trumpet", 10, HAROLD_X + " | " + HAROLD_Y, bars=8, vel=0.78)
    # The argument, a bar each.
    melody(s, "trumpet", 18, "E5:.5 G5 B5:1.5 r:1.5", bars=1, vel=0.85)
    melody(s, "bassoon", 19, "Eb3:.5 Eb3 C3 A2:1 r:1.5", bars=1, vel=0.9, legato=0.7)
    melody(s, "trumpet", 20, "D5:.5 F#5 A5:1 G#5:.5 B5:1 r:.5", bars=1, vel=0.88)
    melody(s, "bassoon", 21, "C3:.5 r A2 r F#2 D2:1 r:.5", bars=1, vel=0.92, legato=0.7)
    # Together again, louder: the tuba sides with Gerald, the clarinet with Harold.
    gerald_more = GERALD_X + " | A2:.5 r C3 r E3:1 G3 | F#3:.5 r D3 r A2:1 r"
    harold_more = HAROLD_X + " | C5:.5 B4 A4 G4 E5:1 C5 | D5:2 F#5:2"
    melody(s, "bassoon", 22, gerald_more, bars=6, vel=0.88, legato=0.7)
    melody(s, "tuba", 22, gerald_more, bars=6, vel=0.7, transpose=-12, legato=0.7)
    melody(s, "trumpet", 22, harold_more, bars=6, vel=0.84)
    melody(s, "clarinet", 22, harold_more, bars=6, vel=0.55, transpose=-12)
    # The last word: they land together, then each has to have one more.
    melody(s, "trumpet", 28, "G5:2 r:2 | r:2 D5:.5 G5 r:1", bars=2, vel=0.85)
    melody(s, "bassoon", 28, "G2:2 r:1 D3:.5 G2 | r:3 G2:.5 r", bars=2, vel=0.9, legato=0.7)
    s.hit("crash", 28 * 4, vel=0.5)
    melody(s, "piano", 30, "C5:.5 B4 A4 G4 E4:1 r | F#4:.5 A4 C5 D5 F#5:1 r", bars=2, vel=0.55)
    return s


# ---------------------------------------------------------------------------------------------
# Game over: a five-second sting, not a loop. A cheerful clarinet run up to the top, which loses
# heart on the way down; the piano's major chord sours to Ab and F minor, a tuba sighs, a bell.
# 2 bars of 4 at 100 bpm, then the ring.
# ---------------------------------------------------------------------------------------------

def game_over():
    s = Band(100, 2, loop=False, tail=1.6, loudness=-17.0, room=0.5)
    s.part("clarinet", "orch_clarinet", level=0.7, pan=0.35, reverb=0.4)
    s.part("piano", "piano", level=0.55, pan=-0.35, reverb=0.45)
    s.part("tuba", "orch_tuba", level=0.72, pan=-0.3, reverb=0.35)
    s.part("bell", "orch_bells", level=0.55, pan=0.4, reverb=0.6)
    s.kit("standard", level=0.6)
    melody(s, "clarinet", 0, "C5:.25 E5 G5 C6 B5:.5 A5 Ab5 G5 Gb5 F5 | Eb5:.75 D5 Db5:1.5 r:1", bars=2, vel=0.75)
    for sym, at, length in (("C6", 0, 1.0), ("Abmaj7", 2.5, 1.2), ("Fm6", 4, 2.2)):
        for m in chord(sym, 55)[0]:
            s.note("piano", m, at, length, vel=0.5)
    s.hit("kick", 0, vel=0.6)
    s.hit("snare", 1, vel=0.5)
    s.note("tuba", "G2", 5, 1, vel=0.72)
    s.note("tuba", "C2", 6, 2, vel=0.66)
    s.note("bell", "C5", 7, 1, vel=0.5)
    return s
