"""The game's songs, written as notes for synth.py.

The Waiting Room's hold-music tune is the game's main theme. Boss music quotes it in a minor key,
faster, so the same melody turns up "gone wrong" wherever things get dangerous.
"""
from synth import Song, chord, bass_note, NOTE_PC


def _root_pc(symbol):
    root = symbol[:2] if len(symbol) > 1 and symbol[1] in "#b" else symbol[:1]
    return NOTE_PC[root], symbol[len(root):]


def walking_bass(song, start_bar, symbols, low=36, gain=0.9):
    """Quarter-note walking bass: root, third, fifth, then a half step into the next root."""
    for k, sym in enumerate(symbols):
        pc, qual = _root_pc(sym)
        root = low + ((pc - low) % 12)
        minor = qual.startswith("m") and not qual.startswith("maj")
        third = root + (3 if minor else 4)
        fifth = root + 7
        nxt = symbols[(k + 1) % len(symbols)]
        npc, _ = _root_pc(nxt)
        nroot = low + ((npc - low) % 12)
        approach = nroot - 1 if nroot > root or nroot + 12 - root > 6 else nroot + 1
        b = (start_bar + k) * 4
        for q, m in enumerate((root, third, fifth, approach)):
            song.note("bass", m, b + q, 0.9, vel=0.85 if q == 0 else 0.7, gain=gain, wet=0.08)


# ---------------------------------------------------------------------------------------------
# Please Hold: the Waiting Room. Swinging bossa lounge, 104 bpm, F major. A warm chorused lead
# sings the tune and a cheesy muted trumpet answers it; in the middle the trumpet takes the tune.
# 24 bars: A (8), B (8), A again (8) with vibes above, ending on C13 so it loops to the top.
# ---------------------------------------------------------------------------------------------

HOLD_A1 = [("C5", 0.5), ("A4", 0.5), ("C5", 0.5), ("F5", 1.5), ("E5", 0.5), ("D5", 0.5),
           ("E5", 0.5), ("C5", 0.5), ("A4", 2), ("r", 1),
           ("D5", 0.5), ("Bb4", 0.5), ("D5", 0.5), ("G5", 1.5), ("F5", 0.5), ("E5", 0.5),
           ("F5", 0.5), ("D5", 0.5), ("E5", 2), ("r", 1)]
HOLD_A2 = [("C5", 0.5), ("A4", 0.5), ("C5", 0.5), ("F5", 1.5), ("E5", 0.5), ("D5", 0.5),
           ("E5", 0.5), ("F5", 0.5), ("A5", 1.5), ("G5", 0.5), ("F5", 0.5), ("D5", 0.5),
           ("Bb5", 0.5), ("A5", 0.5), ("G5", 0.5), ("F5", 0.5), ("E5", 0.5), ("D5", 0.5), ("C5", 1),
           ("G5", 1.5), ("E5", 0.5), ("C5", 1), ("r", 1)]
# The trumpet's answers, dropped into the gaps the tune leaves: (bar within A, beat, notes).
HOLD_ANSWERS = [(1, 3, [("G4", 0.5), ("A4", 0.5)]),
                (3, 3, [("G4", 0.25), ("A4", 0.25), ("Bb4", 0.5)]),
                (7, 3, [("E4", 0.5), ("G4", 0.5)])]
HOLD_B = [("D5", 1), ("F5", 0.5), ("A5", 1.5), ("G5", 0.5), ("F5", 0.5),
          ("G5", 1), ("F5", 0.5), ("Db5", 1.5), ("Bb4", 1),
          ("E5", 1), ("C5", 0.5), ("A4", 1.5), ("G4", 0.5), ("A4", 0.5),
          ("F#4", 0.5), ("A4", 0.5), ("C5", 0.5), ("D5", 0.5), ("F#5", 1), ("A5", 1),
          ("G5", 1.5), ("F5", 0.5), ("D5", 1), ("Bb4", 1),
          ("A4", 0.5), ("Bb4", 0.5), ("C5", 0.5), ("E5", 0.5), ("G5", 1), ("Bb5", 1),
          ("A5", 3), ("r", 1),
          ("G5", 0.5), ("F5", 0.5), ("E5", 0.5), ("D5", 0.5), ("C5", 1), ("r", 1)]
HOLD_B_ANSWERS = [(1, 3, [("Bb5", 0.5), ("G5", 0.5)]), (3, 3, [("C6", 0.5), ("A5", 0.5)]),
                  (6, 3, [("C6", 0.25), ("A5", 0.25), ("F5", 0.5)])]
HOLD_A_CHORDS = ["Fmaj9", "Dm9", "Gm9", "C13"] * 2
HOLD_B_CHORDS = ["Bbmaj9", "Eb9", "Am7", "D7b9", "Gm9", "C13", "Fmaj9", "C13"]
HOLD_CHORDS = HOLD_A_CHORDS + HOLD_B_CHORDS + HOLD_A_CHORDS


def please_hold():
    s = Song(104, 24 * 4, reverb=0.34, swing=0.1)
    shapes = [[(0, 1.0), (1.5, 0.5), (3, 0.5)], [(0.5, 0.5), (2, 1.0), (3.5, 0.5)]]
    for bar, sym in enumerate(HOLD_CHORDS):
        b = bar * 4
        notes, _ = chord(sym, 55)
        for off, dur in shapes[bar % 2]:
            for k, m in enumerate(notes):
                s.note("epiano", m, b + off, dur, vel=0.5, gain=0.3, pan=-0.35 + 0.23 * k)
        # Bossa bass in the A sections; the B section walks.
        if not 8 <= bar < 16:
            root = bass_note(sym, 36)
            for off, dur, m in ((0, 1.5, root), (1.5, 0.5, root + 7), (2, 1.5, root), (3.5, 0.5, root + 7)):
                s.note("bass", m, b + off, dur, vel=0.85, gain=0.9, wet=0.08)
        # Drums: brushes and a shaker on the eighths, a soft kick, the clave on a rim.
        for e in range(8):
            s.hit("brush", b + e * 0.5, vel=0.7 if e % 2 == 0 else 0.45, gain=0.55, pan=-0.3)
            s.hit("shaker", b + e * 0.5, vel=0.8 if e % 2 else 0.5, gain=0.6, pan=0.45)
        s.hit("kick", b, vel=0.55, gain=0.75, wet=0.08)
        s.hit("kick", b + 2.5, vel=0.4, gain=0.6, wet=0.08)
        for c in ([0, 1.5, 3] if bar % 2 == 0 else [1, 2]):
            s.hit("rim", b + c, vel=0.6, gain=0.5, pan=0.2)
    walking_bass(s, 8, HOLD_B_CHORDS)

    # The tune and its answers.
    at = s.line("pulse", 0, HOLD_A1 + HOLD_A2, vel=0.85, gain=0.62, wide=True)
    for bar, beat, notes in HOLD_ANSWERS:
        s.line("brass", bar * 4 + beat, notes, vel=0.8, gain=0.55, pan=0.35)
    s.line("brass", at, HOLD_B, vel=0.85, gain=0.62, pan=0.1)
    for bar, beat, notes in HOLD_B_ANSWERS:
        s.line("vibes", (8 + bar) * 4 + beat, notes, vel=0.7, gain=0.55, pan=-0.4)
    at = 16 * 4
    s.line("pulse", at, HOLD_A1 + HOLD_A2, vel=0.85, gain=0.58, wide=True)
    s.line("vibes", at, HOLD_A1 + HOLD_A2, vel=0.5, gain=0.4, transpose=12, pan=-0.3)
    for bar, beat, notes in HOLD_ANSWERS:
        s.line("brass", (16 + bar) * 4 + beat, notes, vel=0.8, gain=0.55, pan=0.35)
    # "Your call is important to us": a soft chime as the B section ends.
    for i, n in enumerate(["E6", "C6", "G5"]):
        s.note("bell", n, 15 * 4 + 2 + i * 0.5, 1, vel=0.45, gain=0.4, pan=0.3)
    return s


# ---------------------------------------------------------------------------------------------
# Final Arrangements: Mortimer Grimsby's boss fight. The hold tune in F minor at 172 bpm, with
# church organ, a saw bass, fast arpeggios and full drums. 36 bars: intro (4), A (8), B (8),
# a hushed breakdown (4), A a half step higher (8), and a tag (4) that drops back into the intro.
# ---------------------------------------------------------------------------------------------

BOSS_A = [("Ab4", 0.5), ("F4", 0.5), ("Ab4", 0.5), ("C5", 1.5), ("Bb4", 0.5), ("Ab4", 0.5),
          ("Bb4", 0.5), ("Ab4", 0.5), ("F4", 2), ("C5", 0.5), ("Eb5", 0.5),
          ("Db5", 0.5), ("Bb4", 0.5), ("Db5", 0.5), ("F5", 1.5), ("Eb5", 0.5), ("Db5", 0.5),
          ("Db5", 0.5), ("C5", 0.5), ("E5", 2), ("G5", 0.5), ("Bb5", 0.5),
          ("Ab5", 0.5), ("F5", 0.5), ("Ab5", 0.5), ("C6", 1.5), ("Bb5", 0.5), ("Ab5", 0.5),
          ("Bb5", 0.5), ("C6", 0.5), ("Db6", 1.5), ("C6", 0.5), ("Bb5", 0.5), ("Ab5", 0.5),
          ("Gb5", 0.5), ("F5", 0.5), ("Eb5", 0.5), ("Db5", 0.5), ("C5", 0.5), ("Bb4", 0.5), ("Ab4", 1),
          ("G4", 0.5), ("Bb4", 0.5), ("C5", 0.5), ("E5", 0.5), ("G5", 0.5), ("Bb5", 0.5), ("C6", 1)]
BOSS_A_CHORDS = ["Fm", "Fm", "Bbm", "C7", "Fm", "Db", "Bbm", "C7"]
BOSS_B = [("F5", 0.5), ("Ab5", 0.5), ("Db6", 0.5), ("Ab5", 0.5), ("F5", 0.5), ("Ab5", 0.5), ("Db6", 1),
          ("G5", 0.5), ("Bb5", 0.5), ("Eb6", 0.5), ("Bb5", 0.5), ("G5", 0.5), ("Bb5", 0.5), ("Eb6", 1),
          ("E5", 0.5), ("G5", 0.5), ("C6", 0.5), ("G5", 0.5), ("Bb5", 1), ("G5", 1),
          ("Ab5", 1.5), ("G5", 0.5), ("F5", 2),
          ("F5", 0.5), ("Ab5", 0.5), ("Db6", 0.5), ("Ab5", 0.5), ("F5", 0.5), ("Ab5", 0.5), ("Db6", 1),
          ("G5", 0.5), ("Bb5", 0.5), ("Eb6", 0.5), ("F6", 0.5), ("Eb6", 1), ("Bb5", 1),
          ("Db6", 1), ("C6", 0.5), ("Bb5", 0.5), ("Ab5", 1), ("G5", 1),
          ("C6", 1.5), ("Bb5", 0.5), ("G5", 1), ("E5", 1)]
BOSS_B_CHORDS = ["Db", "Eb", "C7", "Fm", "Db", "Eb", "Bbm", "C7"]
BREAK_TUNE = [("Ab4", 2), ("C5", 1), ("F5", 1), ("Eb5", 2), ("Db5", 2),
              ("Bb4", 2), ("Db5", 1), ("F5", 1), ("E5", 2), ("G5", 1), ("C6", 1)]
BREAK_CHORDS = ["Fm", "Db", "Bbm", "C7"]
UP_CHORDS = ["F#m", "F#m", "Bm", "C#7", "F#m", "D", "Bm", "C#7"]
TAG = [("F5", 1), ("Ab5", 1), ("C6", 1), ("F6", 1),
       ("Eb6", 1), ("Db6", 1), ("C6", 1), ("Ab5", 1),
       ("G5", 0.5), ("Ab5", 0.5), ("Bb5", 0.5), ("C6", 0.5), ("Db6", 0.5), ("E6", 0.5), ("F6", 1),
       ("G6", 2), ("r", 2)]
TAG_CHORDS = ["Fm", "Db", "C7", "C7"]
BOSS_CHORDS = (["Fm", "Db", "Bbm", "C7"] + BOSS_A_CHORDS + BOSS_B_CHORDS + BREAK_CHORDS
               + UP_CHORDS + TAG_CHORDS)


def _drums(s, b, fill=False):
    for k in (0, 1.5, 2):
        s.hit("kick", b + k, vel=0.95, gain=0.9, wet=0.04)
    for k in (1, 3):
        s.hit("snare", b + k, vel=0.85, gain=0.6, pan=0.05)
        s.hit("clap", b + k, vel=0.6, gain=0.25, pan=-0.05)
    for e in range(8):
        s.hit("openhat" if e == 7 else "hat", b + e * 0.5, vel=0.65 if e % 2 else 0.45, gain=0.4, pan=0.35)
    if fill:
        for q in range(8):
            s.hit("snare", b + 2 + q * 0.25, vel=0.5 + q * 0.06, gain=0.55)


def final_arrangements():
    s = Song(164, 36 * 4, reverb=0.26)
    for bar, sym in enumerate(BOSS_CHORDS):
        b = bar * 4
        intro, breakdown = bar < 4, 20 <= bar < 24
        notes, _ = chord(sym, 53)
        # Organ: held chords in the intro and the breakdown, stabs elsewhere.
        for k, m in enumerate(notes):
            pan = -0.3 + 0.3 * k
            if intro or breakdown:
                s.note("organ", m, b, 4, vel=0.7, gain=0.45 if intro else 0.38, pan=pan)
            else:
                s.note("organ", m, b, 0.75, vel=0.7, gain=0.32, pan=pan)
                s.note("organ", m, b + 1.5, 0.5, vel=0.6, gain=0.28, pan=pan)
        # Fast arpeggios across the chord, left and right in turn.
        if 12 <= bar < 20:
            arp = notes + [notes[0] + 12]
            for q in range(16):
                s.note("thin", arp[q % len(arp)] + 12, b + q * 0.25, 0.2, vel=0.5, gain=0.12,
                       pan=-0.5 if q % 2 else 0.5, wet=0.6)
        # Bass: driving eighths with an octave jump, or a heartbeat in the breakdown.
        root = bass_note(sym, 29)
        if breakdown:
            s.note("synthbass", root, b, 0.5, vel=0.8, gain=0.7)
            s.note("synthbass", root, b + 0.75, 0.5, vel=0.6, gain=0.6)
            s.hit("kick", b, vel=0.7, gain=0.7, wet=0.05)
            s.hit("kick", b + 0.75, vel=0.5, gain=0.6, wet=0.05)
        else:
            for e in range(8):
                m = (root if root >= 36 else root + 12) + (12 if e in (3, 7) else 0)
                s.note("bass", m, b + e * 0.5, 0.42, vel=0.85, gain=0.8, wet=0.03)
                if e % 2 == 0:
                    s.note("synthbass", m, b + e * 0.5, 0.3, vel=0.6, gain=0.25, wet=0.03)
        # Drums.
        if intro:
            for q in range(4):
                s.hit("kick", b + q, vel=0.95, gain=0.95, wet=0.04)
            if bar == 3:
                for q in range(8):
                    s.hit("snare", b + 2 + q * 0.25, vel=0.4 + q * 0.07, gain=0.55)
        elif not breakdown:
            _drums(s, b, fill=bar in (11, 19, 31))
        if bar in (4, 24):
            s.hit("crash", b, vel=0.7, gain=0.4, pan=-0.2)
    # The tune: the hold theme in minor, the new hook, the theme hushed on vibes, then a half step up.
    s.line("pulse", 4 * 4, BOSS_A, vel=0.9, gain=0.62, wide=True)
    s.line("pulse", 12 * 4, BOSS_B, vel=0.9, gain=0.58, wide=True)
    s.line("vibes", 20 * 4, BREAK_TUNE, vel=0.75, gain=0.7)
    s.line("pulse", 24 * 4, BOSS_A, vel=0.9, gain=0.55, transpose=1, wide=True)
    s.line("organ", 24 * 4, BOSS_A, vel=0.55, gain=0.2, transpose=-11)
    s.line("pulse", 32 * 4, TAG, vel=0.9, gain=0.62, wide=True)
    s.line("organ", 32 * 4, TAG, vel=0.6, gain=0.3, transpose=-12)
    return s


SONGS = {"please_hold": please_hold, "final_arrangements": final_arrangements}
