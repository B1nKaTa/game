"""The game's songs, written as notes for synth.py.

The Waiting Room's hold-music tune is the game's main theme. Boss music quotes it in a minor key,
faster, so the same melody turns up "gone wrong" wherever things get dangerous.
"""
from synth import Song, chord, bass_note


# ---------------------------------------------------------------------------------------------
# Please Hold: the Waiting Room. Easy-listening bossa with a warm pulse lead, 96 bpm, F major.
# 24 bars: A (8), B (8), A again (8), ending on C7 so it loops back to the top.
# ---------------------------------------------------------------------------------------------

HOLD_A1 = [("A4", 1), ("C5", 0.5), ("F5", 1.5), ("E5", 1),
           ("D5", 2), ("r", 0.5), ("C5", 0.5), ("A4", 1),
           ("Bb4", 1), ("D5", 0.5), ("G5", 1.5), ("F5", 1),
           ("E5", 3), ("r", 1)]
HOLD_A2 = [("A4", 1), ("C5", 0.5), ("F5", 1.5), ("E5", 1),
           ("D5", 1), ("F5", 1), ("A5", 1), ("G5", 1),
           ("F5", 1), ("E5", 0.5), ("D5", 1.5), ("C5", 1),
           ("G5", 1), ("E5", 1), ("C5", 2)]
HOLD_B = [("D5", 1.5), ("F5", 0.5), ("A5", 2),
          ("Db5", 1.5), ("F5", 0.5), ("G5", 2),
          ("E5", 1.5), ("C5", 0.5), ("A4", 2),
          ("F#4", 1), ("A4", 1), ("C5", 1), ("D5", 1),
          ("Bb4", 1.5), ("D5", 0.5), ("F5", 2),
          ("E5", 1), ("G5", 1), ("Bb5", 1), ("A5", 0.5), ("G5", 0.5),
          ("A5", 3), ("r", 1),
          ("G5", 1), ("E5", 1), ("C5", 1), ("Bb4", 1)]
HOLD_CHORDS = (["Fmaj7", "Dm7", "Gm7", "C7"] * 2
               + ["Bbmaj7", "Bbm6", "Am7", "D7", "Gm7", "C7", "Fmaj7", "C7"]
               + ["Fmaj7", "Dm7", "Gm7", "C7"] * 2)


def please_hold():
    s = Song(96, 24 * 4, reverb=0.32)
    # Chords: an electric piano comping a bossa rhythm, two bar shapes in turn.
    shapes = [[(0, 1.0), (1.5, 0.5), (3, 0.5)], [(0.5, 0.5), (2, 1.0), (3.5, 0.5)]]
    for bar, sym in enumerate(HOLD_CHORDS):
        notes, _ = chord(sym, 55)
        for off, dur in shapes[bar % 2]:
            for m in notes:
                s.note("epiano", m, bar * 4 + off, dur, vel=0.5, gain=0.33)
        # Bass: root, fifth, root, fifth on the bossa pattern.
        root = bass_note(sym, 36); fifth = root + 7
        for off, dur, m in ((0, 1.5, root), (1.5, 0.5, fifth), (2, 1.5, root), (3.5, 0.5, fifth)):
            s.note("bass", m, bar * 4 + off, dur, vel=0.8, gain=0.85, wet=0.1)
        # Brushes on the eighths, a soft kick, and the clave on a rim.
        for e in range(8):
            s.hit("brush", bar * 4 + e * 0.5, vel=0.7 if e % 2 == 0 else 0.45, gain=0.6)
        s.hit("kick", bar * 4, vel=0.5, gain=0.7, wet=0.1)
        s.hit("kick", bar * 4 + 2, vel=0.4, gain=0.7, wet=0.1)
        clave = [0, 1.5, 3] if bar % 2 == 0 else [1, 2]
        for c in clave:
            s.hit("rim", bar * 4 + c, vel=0.6, gain=0.55)
    # The tune: a warm pulse lead, with vibes joining an octave up the second time round A.
    at = s.line("pulse", 0, HOLD_A1, vel=0.8, gain=0.55)
    at = s.line("pulse", at, HOLD_A2, vel=0.8, gain=0.55)
    at = s.line("vibes", at, HOLD_B, vel=0.75, gain=0.7)
    a3 = at
    at = s.line("pulse", at, HOLD_A1, vel=0.8, gain=0.5)
    s.line("pulse", at, HOLD_A2, vel=0.8, gain=0.5)
    s.line("vibes", a3, HOLD_A1 + HOLD_A2, vel=0.5, gain=0.45, transpose=12)
    # "Your call is important to us": a soft chime as the B section ends.
    for i, n in enumerate(["E6", "C6", "G5"]):
        s.note("bell", n, 15 * 4 + i * 0.75, 1, vel=0.5, gain=0.4)
    return s


# ---------------------------------------------------------------------------------------------
# Final Arrangements: Mortimer Grimsby's boss fight. The hold tune in F minor at 168 bpm, with
# church organ stabs, a driving bass and full drums. 32 bars: intro (4), A (8), B (8), A again
# with the organ (8), and a tag (4) that leads back to the intro.
# ---------------------------------------------------------------------------------------------

BOSS_A = [("Ab4", 1), ("C5", 0.5), ("F5", 1.5), ("Eb5", 1),
          ("Db5", 2), ("r", 0.5), ("C5", 0.5), ("Ab4", 1),
          ("Bb4", 1), ("Db5", 0.5), ("F5", 1.5), ("Eb5", 1),
          ("E5", 3), ("G4", 1),
          ("Ab4", 1), ("C5", 0.5), ("F5", 1.5), ("Eb5", 1),
          ("Db5", 1), ("F5", 1), ("Ab5", 1), ("G5", 1),
          ("F5", 1), ("Eb5", 0.5), ("Db5", 1.5), ("C5", 1),
          ("C5", 0.5), ("E5", 0.5), ("G5", 0.5), ("Bb5", 0.5), ("C6", 2)]
BOSS_B = [("F5", 0.5), ("Ab5", 0.5), ("Db6", 0.5), ("Ab5", 0.5), ("F5", 0.5), ("Ab5", 0.5), ("Db6", 1),
          ("G5", 0.5), ("Bb5", 0.5), ("Eb6", 0.5), ("Bb5", 0.5), ("G5", 0.5), ("Bb5", 0.5), ("Eb6", 1),
          ("E5", 0.5), ("G5", 0.5), ("C6", 0.5), ("G5", 0.5), ("Bb5", 1), ("G5", 1),
          ("Ab5", 2), ("F5", 2),
          ("F5", 0.5), ("Ab5", 0.5), ("Db6", 0.5), ("Ab5", 0.5), ("F5", 0.5), ("Ab5", 0.5), ("Db6", 1),
          ("G5", 0.5), ("Bb5", 0.5), ("Eb6", 0.5), ("F6", 0.5), ("Eb6", 1), ("Bb5", 1),
          ("Db6", 1), ("C6", 0.5), ("Bb5", 0.5), ("Ab5", 1), ("G5", 1),
          ("C6", 1.5), ("Bb5", 0.5), ("G5", 1), ("E5", 1)]
BOSS_TAG = [("F5", 1), ("Ab5", 1), ("C6", 1), ("F6", 1),
            ("Eb6", 1), ("Db6", 1), ("C6", 1), ("Ab5", 1),
            ("G5", 1), ("Bb5", 1), ("C6", 1), ("E6", 1),
            ("G6", 2), ("r", 2)]
BOSS_CHORDS = (["Fm", "Db", "Bbm", "C7"]
               + ["Fm", "Db", "Bbm", "C7", "Fm", "Db", "Bbm", "C7"]
               + ["Db", "Eb", "C7", "Fm", "Db", "Eb", "Bbm", "C7"]
               + ["Fm", "Db", "Bbm", "C7", "Fm", "Db", "Bbm", "C7"]
               + ["Fm", "Db", "C7", "C7"])


def final_arrangements():
    s = Song(168, 32 * 4, reverb=0.22)
    for bar, sym in enumerate(BOSS_CHORDS):
        b = bar * 4
        notes, _ = chord(sym, 53)
        intro = bar < 4
        organ_bar = intro or 20 <= bar < 28
        # Organ: whole-bar chords in the intro, stabs on 1 and the "and" of 2 elsewhere.
        if organ_bar:
            for m in notes:
                if intro:
                    s.note("organ", m, b, 4, vel=0.7, gain=0.5)
                else:
                    s.note("organ", m, b, 1, vel=0.7, gain=0.45)
                    s.note("organ", m, b + 1.5, 0.5, vel=0.6, gain=0.45)
        else:
            for m in notes:
                s.note("thin", m + 12, b, 0.25, vel=0.6, gain=0.25)
                s.note("thin", m + 12, b + 1.5, 0.25, vel=0.5, gain=0.25)
        # Bass: driving eighths, root and octave.
        root = bass_note(sym, 33)
        for e in range(8):
            m = root + (12 if e % 2 else 0)
            s.note("bass", m, b + e * 0.5, 0.45, vel=0.85, gain=0.8, wet=0.05)
            s.note("square", m + 12, b + e * 0.5, 0.3, vel=0.4, gain=0.15, wet=0.05)
        # Drums: four on the floor in the intro, then a driving beat.
        if intro:
            for q in range(4):
                s.hit("kick", b + q, vel=0.9, gain=0.9, wet=0.05)
            if bar == 3:
                for q in range(8):
                    s.hit("snare", b + 2 + q * 0.25, vel=0.4 + q * 0.07, gain=0.6)
        else:
            for k in (0, 1.5, 2):
                s.hit("kick", b + k, vel=0.95, gain=0.95, wet=0.05)
            s.hit("snare", b + 1, vel=0.85, gain=0.75)
            s.hit("snare", b + 3, vel=0.85, gain=0.75)
            for e in range(8):
                s.hit("openhat" if e == 7 else "hat", b + e * 0.5, vel=0.7 if e % 2 else 0.5, gain=0.5)
    # The tune: the hold theme in minor, then the new hook, then the theme an octave up with the organ.
    at = s.line("pulse", 16, BOSS_A, vel=0.9, gain=0.6)
    at = s.line("pulse", at, BOSS_B, vel=0.9, gain=0.55)
    s.line("pulse", at, BOSS_A, vel=0.9, gain=0.5, transpose=12)
    s.line("square", at, BOSS_A, vel=0.7, gain=0.3)
    s.line("pulse", 28 * 4, BOSS_TAG, vel=0.9, gain=0.6)
    s.line("organ", 28 * 4, BOSS_TAG, vel=0.6, gain=0.3, transpose=-12)
    return s


SONGS = {"please_hold": please_hold, "final_arrangements": final_arrangements}
