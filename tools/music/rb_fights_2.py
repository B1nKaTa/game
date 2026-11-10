"""The deep fights, each its own piece: Mortimer at depth 3, the lounge gone wrong at depth 4,
Augustine at depth 5, and the Chairman of the Board. No shared theme: every fight has its own key,
tempo, palette and hook (see jukebox.py for why).
"""
from band import Band, beat, roll
from kit import melody, prog, at, comp, bassline, arp
from synth import bass_note

INFO = {
    "final_arrangements": dict(key="C# minor", bpm=172, meter=4, bars=40,
                               about="Depth 3 boss, Mortimer: church organ hook over chugging guitar, funeral bells, timpani and choir."),
    "boss_depth_4": dict(key="G minor", bpm=456, meter=6, bars=56,
                         about="Depth 4 boss: the lounge gone wrong as a 6/8 tarantella, accordion, marimba, brass and tambourine."),
    "boss_depth_5": dict(key="Eb minor", bpm=150, meter=4, bars=40,
                         about="Depth 5 boss, Augustine: a sung canon over a drone, chimes, horns and driving short strings."),
    "the_chairman": dict(key="D major / D minor", bpm=168, meter=4, bars=48, quiet=[(8, 12), (41, 48)],
                         about="Final boss: the Chairman's own cheerful muzak stutters, grinds and collapses into choir, organ and orchestra, then restarts."),
}


def _bars(text, count, meter=4):
    p = prog(text, meter)
    assert len(p) == count, "progression has %d bars, not %d" % (len(p), count)
    return p


def power(s, inst, bar, parts, rhythm, low=40, vel=0.75, length=None):
    """Power chords (root, fifth, octave) on a grid such as 'x.x.xxx.': x loud, o soft."""
    step = s.meter / len(rhythm)
    for i, c in enumerate(rhythm):
        if c in "xo":
            root = bass_note(at(parts, i * step), low)
            for m in (root, root + 7, root + 12):
                s.note(inst, m, bar * s.meter + i * step, length or step * 0.9, vel=vel * (1.0 if c == "x" else 0.7))


def ostinato(s, inst, bar, parts, pattern, step=0.25, low=48, vel=0.7, length=None):
    """A figure of semitones above each chord's root, one note every `step` beats, around the bar."""
    t = 0.0; k = 0
    while t < s.meter - 1e-6:
        root = bass_note(at(parts, t), low)
        s.note(inst, root + pattern[k % len(pattern)], bar * s.meter + t, length or step * 0.85, vel=vel)
        t += step; k += 1


# ---------------------------------------------------------------------------------------------
# Final Arrangements: Mortimer the undertaker. C# minor, 172 bpm. A funeral bell tolls over organ
# swells, then the church organ plays Mortimer's hook over chugging guitar and a galloping bass;
# short strings drive the middle under a choir; a stop-time break with the bell; the hook up high
# with a distorted lead; then a climbing tag that falls back to the bell. 40 bars: intro (4), A (8),
# B (8), break (4), A again (8), tag (8).
# ---------------------------------------------------------------------------------------------

FA_A = ("G#5:.5 G#5 C#6:1 B5:.5 G#5 E5:1 | D#5:.5 E5 G#5 E5 C#5:2 | A5:.5 A5 C#6:1 B5:.5 A5 E5:1 | "
        "F#5:.5 G#5 A5 B5 D#6:2 | G#5:.5 G#5 C#6:1 E6:.5 D#6 C#6:1 | B5:.5 C#6 B5 G#5 E5:1 G#5 | "
        "A5:.5 G#5 F#5 E5 F#5:1 A5 | G#5:1.5 F#5:.5 D#5:1 C5")
FA_B = ("C#6:1.5 B5:.5 A5:2 | B5:1.5 A5:.5 F#5:2 | D#6:1 B5 G#5 D#5 | E5:3 G#5:1 | "
        "A5:1 C#6 E6 C#6 | D#6:1.5 C#6:.5 B5:2 | B5:1 G#5 E5 B4 | C5:2 D#5:2")
FA_TAG = ("F#5:.5 A5 C#6 A5 F#5 A5 C#6 A5 | G#5:.5 B5 D#6 B5 G#5 B5 D#6 B5 | A5:.5 C#6 E6 C#6 A5 C#6 E6 C#6 | "
          "B5:.5 D#6 F#6 D#6 B5 D#6 F#6 D#6 | C#6:2 E6:2 | D6:2 F#6:1 A6:1 | D#6:1 F#6 B6:2 | G#6:1 F#6 D#6 C6")
FA_A_CHORDS = "C#m C#m A B C#m C#m F#m G#7"
FA_CHORDS = " ".join(["C#m C#m A G#7", FA_A_CHORDS, "A B G#m C#m F#m B E G#7", "C#m C#m D G#7", FA_A_CHORDS,
                      "F#m G#m A B C#m D B G#7"])


def final_arrangements():
    s = Band(172, 40, loudness=-16.5, room=0.6)
    s.part("organ", "churchorgan", level=0.66, pan=0.05, reverb=0.55)
    s.part("gtr", "distortion", level=0.5, pan=-0.3, reverb=0.15)
    s.part("lead", "overdrive", level=0.5, pan=0.3, reverb=0.3)
    s.part("bass", "pickbass", level=0.72, reverb=0.08)
    s.part("strings", "orch_strings_short", level=0.62, pan=0.15, reverb=0.4)
    s.part("choir", "choir", level=0.5, reverb=0.6)
    s.part("timp", "orch_timpani", level=0.75, reverb=0.4)
    s.part("roll", "orch_timpani_roll", level=0.65, reverb=0.4)
    s.part("bell", "orch_bells", level=0.6, pan=-0.15, reverb=0.7)
    s.kit("power", level=0.8)
    p = _bars(FA_CHORDS, 40)
    for bar, parts in enumerate(p):
        intro, a1, b, brk, a2, tag = bar < 4, 4 <= bar < 12, 12 <= bar < 20, 20 <= bar < 24, 24 <= bar < 32, bar >= 32
        if intro or brk:
            s.note("bell", "C#5", bar * 4, 3.5, vel=0.8)
            comp(s, "organ", bar, parts, "x---------------", low=49, vel=0.6, spread=0.2)
        if intro and bar >= 2:
            s.note("roll", bass_note(at(parts, 0), 37), bar * 4, 3.8, vel=0.5 + 0.2 * (bar - 2))
        if intro and bar == 3:
            roll(s, bar, start=2.0, count=8)
        if a1 or a2:
            power(s, "gtr", bar, parts, "x.x.xxx.x.xxx.x.", low=40, vel=0.75)
            bassline(s, "bass", bar, parts, [(e * 0.5, 0.42, 0) for e in range(8)], low=28, vel=0.85)
            beat(s, bar, {"kick": "x.x...x.x.x...x.", "snare": "....x.......x...", "hat": "x.x.x.x.x.x.x.x."})
            s.note("timp", bass_note(at(parts, 0), 37), bar * 4, 0.9, vel=0.8)
            s.note("timp", bass_note(at(parts, 2), 37), bar * 4 + 2, 0.9, vel=0.65)
            if a2:
                comp(s, "choir", bar, parts, "x---------------", low=52, vel=0.55, spread=0.2)
        if b:
            ostinato(s, "strings", bar, parts, [0, 12, 7, 12, 3, 12, 7, 12], step=0.5, low=48, vel=0.75)
            comp(s, "choir", bar, parts, "x---------------", low=52, vel=0.6, spread=0.2)
            comp(s, "organ", bar, parts, "x--.....x-......", low=55, vel=0.5, spread=0.2)
            power(s, "gtr", bar, parts, "x...x...x...x...", low=40, vel=0.6, length=0.9)
            bassline(s, "bass", bar, parts, [(0, 0.9, 0), (1, 0.9, 0), (2, 0.9, 7), (3, 0.9, 12)], low=28, vel=0.8)
            beat(s, bar, {"kick": "x..x..x.x..x..x.", "snare": "....x.......x...", "ride": "x.x.x.x.x.x.x.x."})
        if brk:
            # Stop-time: the band hits together and holds its breath.
            power(s, "gtr", bar, parts, "x.....x.........", low=40, vel=0.85, length=1.2)
            bassline(s, "bass", bar, parts, [(0, 1.2, 0), (1.5, 1.2, 0)], low=28, vel=0.85)
            beat(s, bar, {"kick": "x.....x.........", "crash": "x...............", "snare": "......x........."})
            s.note("timp", bass_note(at(parts, 0), 37), bar * 4, 0.9, vel=0.85)
            if bar == 23:
                roll(s, bar, start=2.0, count=8)
        if tag:
            ostinato(s, "strings", bar, parts, [0, 7, 12, 7], step=0.25, low=48, vel=0.7)
            power(s, "gtr", bar, parts, "x.x.x.x.x.x.x.x.", low=40, vel=0.7)
            bassline(s, "bass", bar, parts, [(e * 0.5, 0.42, 0) for e in range(8)], low=28, vel=0.85)
            comp(s, "choir", bar, parts, "x-------x-------", low=55, vel=0.6, spread=0.2)
            beat(s, bar, {"kick": "x...x...x...x...", "snare": "..x...x...x...x.", "hat": "xxxxxxxxxxxxxxxx"}, vel=0.85)
        if bar in (11, 19, 31):
            roll(s, bar, start=3.0, count=4)
        if bar in (4, 12, 24, 32):
            s.hit("crash", bar * 4, vel=0.8)
    roll(s, 39, start=2.0, count=8, kind="tom")
    melody(s, "organ", 4, FA_A, bars=8, vel=0.85)
    melody(s, "organ", 12, FA_B, bars=8, vel=0.7, transpose=-12)
    melody(s, "organ", 24, FA_A, bars=8, vel=0.9)
    melody(s, "lead", 24, FA_A, bars=8, vel=0.85, transpose=-12)
    melody(s, "organ", 32, FA_TAG, bars=8, vel=0.85)
    melody(s, "lead", 32, FA_TAG, bars=8, vel=0.8, transpose=-12)
    return s


# ---------------------------------------------------------------------------------------------
# Depth 4: the lounge gone wrong. G minor, a 6/8 tarantella (each beat an eighth, 152 to the dotted
# quarter). The lounge vibes start politely, then the accordion and tambourine take off; marimba and
# accordion race the tune, the brass sing the middle in Bb, the piano spins alone, the tune comes back
# with everyone, and a chromatic run throws it back to the top. 56 bars: intro (4), A twice (16),
# B twice (16), piano break (4), A again (8), tag (8).
# ---------------------------------------------------------------------------------------------

T4_A = ("D5:1 G5 Bb5 A5 G5 F#5 | G5:1 A5 Bb5 D6:3 | C6:1 Bb5 A5 G5 Eb5 G5 | F#5:1 G5 A5 D5:3 | "
        "D5:1 G5 Bb5 D6 C6 Bb5 | Eb6:1 D6 C6 Bb5 G5 Eb5 | C5:1 Eb5 G5 F#5 A5 C6 | Bb5:1 A5 G5 D5:3")
T4_B = ("F5:2 D5:1 Bb5:2 A5:1 | C6:2 A5:1 F5:3 | G5:2 Bb5:1 D6:2 C6:1 | A5:2 F#5:1 D5:3 | "
        "G5:2 Bb5:1 Eb6:2 D6:1 | D6:2 C6:1 Bb5:3 | Eb6:1 D6 C6 Bb5 A5 G5 | F#5:3 A5:3")
T4_TAG = ("G5:1 Bb5 Eb6 G6:3 | F#6:1 D6 A5 F#5:3 | Eb6:1 G6 Eb6 Bb5 G5 Eb5 | D5:1 F#5 A5 D6 F#6 A6 | "
          "G6:1 Eb6 C6 G5 Eb5 C5 | D5:1 F#5 A5 C6 A5 F#5 | G5:3 r:3 | D5:1 Eb5 E5 F#5 G5 A5")
T4_LOUNGE = "Bb5:2 A5:1 G5:3 | D5:6"
T4_A_CHORDS = "Gm Gm Cm D7 Gm Eb Cm,D7 Gm"
T4_B_CHORDS = "Bb F Gm D Eb Bb Cm D7"
T4_CHORDS = " ".join(["Gm Gm Cm D7", T4_A_CHORDS, T4_A_CHORDS, T4_B_CHORDS, T4_B_CHORDS, "Gm Cm D7 D7", T4_A_CHORDS,
                      "Eb D Eb D Cm D Gm D7"])


def boss_depth_4():
    s = Band(456, 56, meter=6, loudness=-16.5, room=0.5)
    s.part("accordion", "accordion", level=0.62, pan=-0.5, reverb=0.3)
    s.part("marimba", "orch_marimba", level=0.75, pan=0.5, reverb=0.35)
    s.part("brass", "brass", level=0.6, pan=-0.15, reverb=0.35)
    s.part("tpt", "orch_trumpet_short", level=0.6, pan=0.3, reverb=0.35)
    s.part("piano", "piano", level=0.6, pan=0.35, reverb=0.35)
    s.part("vibes", "vibes", level=0.5, pan=0.2, reverb=0.5)
    s.part("bass", "upright", level=0.75, reverb=0.1)
    s.part("pizz", "orch_pizz", level=0.6, pan=-0.35, reverb=0.35)
    s.kit("standard", level=0.8)
    p = _bars(T4_CHORDS, 56, meter=6)
    oompah = [(0, 2.6, 0), (3, 2.6, 7)]
    for bar, parts in enumerate(p):
        a1, b, brk = 4 <= bar < 20, 20 <= bar < 36, 36 <= bar < 40
        a2, tag = 40 <= bar < 48, bar >= 48
        if bar < 2:
            comp(s, "vibes", bar, parts, "x-----", low=55, vel=0.45, spread=0.2)
            bassline(s, "bass", bar, parts, [(0, 5.5, 0)], low=31, vel=0.55)
            beat(s, bar, {"ride": "o..o.."}, vel=0.6)
            continue
        if not brk:
            bassline(s, "bass", bar, parts, oompah, low=31, vel=0.85)
            comp(s, "accordion", bar, parts, ".xx.xx", low=55, vel=0.6, spread=0.2)
            beat(s, bar, {"kick": "x..x..", "tambourine": "xooxoo", "snare": "..o..x"})
        if bar == 3:
            roll(s, bar, start=3.0, count=6, step=0.5)
        if a1 or a2 or tag:
            comp(s, "brass", bar, parts, "x..x..", low=55, vel=0.65, spread=0.2)
        if 12 <= bar < 20 or b:
            arp(s, "marimba", bar, parts, step=1.0, low=67, octaves=1, vel=0.5, pan=0.0)
        if b or a2 or tag:
            ostinato(s, "pizz", bar, parts, [0, 12, 7, 12, 3, 12] if bar >= 28 else [0, 7, 12, 7, 12, 7], step=1.0, low=43, vel=0.62)
        if brk:
            arp(s, "piano", bar, parts, step=1.0, low=55, octaves=2, vel=0.6, pan=0.0)
            bassline(s, "bass", bar, parts, [(0, 2.6, 0)], low=31, vel=0.8)
            beat(s, bar, {"kick": "x.....", "tambourine": "x.xx.x"}, vel=0.8)
            if bar == 39:
                roll(s, bar, start=0.0, count=6, step=1.0)
        if bar in (11, 19, 27, 35, 47):
            roll(s, bar, start=3.0, count=6, step=0.5)
        if bar in (4, 20, 40, 48):
            s.hit("crash", bar * 6, vel=0.8)
    s.hit("crash", 54 * 6, vel=0.9)
    melody(s, "vibes", 0, T4_LOUNGE, bars=2, vel=0.6)
    melody(s, "accordion", 4, T4_A, bars=8, vel=0.8)
    melody(s, "marimba", 4, T4_A, bars=8, vel=0.8)
    # The second time round the marimba climbs an octave and the trumpets punch in.
    melody(s, "accordion", 12, T4_A, bars=8, vel=0.8)
    melody(s, "marimba", 12, T4_A, bars=8, vel=0.75, transpose=12)
    melody(s, "brass", 20, T4_B, bars=8, vel=0.8)
    melody(s, "accordion", 20, T4_B, bars=8, vel=0.5, transpose=-12)
    melody(s, "brass", 28, T4_B, bars=8, vel=0.85)
    melody(s, "tpt", 28, T4_B, bars=8, vel=0.7, transpose=12)
    melody(s, "accordion", 40, T4_A, bars=8, vel=0.85)
    melody(s, "marimba", 40, T4_A, bars=8, vel=0.85, transpose=12)
    melody(s, "tpt", 40, T4_A, bars=8, vel=0.75)
    melody(s, "tpt", 48, T4_TAG, bars=8, vel=0.8)
    melody(s, "marimba", 48, T4_TAG, bars=8, vel=0.8)
    return s


# ---------------------------------------------------------------------------------------------
# Depth 5: Augustine. Eb minor, 150 bpm. Chimes fall over a timpani roll; then the horns play
# Augustine's hook over driving short strings; then a sung canon over a drone, the second choir one
# bar behind, the bells marking the phrases; a build on toms and horn stabs; the hook again with
# everything; and the canon once more over the full band, ending on Bb7 back into the chimes.
# 40 bars: intro (4), A (8), canon (8), build (4), A again (8), canon with band (8).
# ---------------------------------------------------------------------------------------------

A5_HOOK = ("Bb4:1.5 Eb5:.5 Gb5:1 F5 | Eb5:.5 Db5 Eb5:3 | D#5:1.5 F#5:.5 B5:1 A#5 | F5:3 D5:1 | "
           "Bb4:1.5 Eb5:.5 Gb5:1 Bb5 | Ab5:.5 Gb5 F5 Eb5 F5:2 | Eb5:1 Gb5 B5 Ab5 | Bb5:2 Ab5:1 F5")
A5_CANON = ["Eb5:1 Gb5 Bb5 Ab5", "Gb5:1.5 F5:.5 Eb5:2", "Db5:1 Eb5 F5 Gb5", "Ab5:2 Gb5:1 F5",
            "Eb5:1 Bb5 Ab5 Gb5", "F5:1.5 Gb5:.5 Ab5:1 F5", "Gb5:1 F5 Eb5 Db5"]
A5_LEAD = " | ".join(A5_CANON) + " | D5:4"
A5_FOLLOW = "r:4 | " + " | ".join(A5_CANON[:6]) + " | F5:4"
A5_A_CHORDS = "Ebm Ebm B Bb Ebm Ebm Abm Bb7"
A5_DRONE = "Ebm Ebm Ebm Ebm Ebm Ebm Ebm Bb7"
A5_CHORDS = " ".join(["Ebm Ebm B Bb", A5_A_CHORDS, A5_DRONE, "B B Bb Bb", A5_A_CHORDS, A5_DRONE])


def boss_depth_5():
    s = Band(150, 40, loudness=-16.5, room=0.7)
    s.part("horn", "orch_horn", level=0.75, pan=-0.1, reverb=0.5)
    s.part("tpt", "orch_trumpet", level=0.6, pan=0.15, reverb=0.5)
    s.part("strings", "orch_strings_short", level=0.7, pan=0.1, reverb=0.45)
    s.part("choir", "choir", level=0.65, pan=-0.2, reverb=0.65)
    s.part("oohs", "oohs", level=0.6, pan=0.2, reverb=0.65)
    s.part("bells", "orch_bells", level=0.6, pan=0.2, reverb=0.7)
    s.part("glock", "orch_glock", level=0.4, pan=-0.2, reverb=0.6)
    s.part("timp", "orch_timpani", level=0.75, reverb=0.45)
    s.part("roll", "orch_timpani_roll", level=0.6, reverb=0.45)
    s.part("bass", "orch_bass", level=0.7, reverb=0.2)
    s.part("pad", "slowstrings", level=0.42, reverb=0.6)
    s.kit("room", level=0.8)
    p = _bars(A5_CHORDS, 40)
    for bar, parts in enumerate(p):
        intro, a1, can, build, a2, can2 = bar < 4, 4 <= bar < 12, 12 <= bar < 20, 20 <= bar < 24, 24 <= bar < 32, bar >= 32
        root = bass_note(at(parts, 0), 39)
        if intro:
            for k, n in enumerate(("Eb6", "Db6", "B5", "Bb5")):
                s.note("bells", n, bar * 4 + k, 1.5, vel=0.7)
            s.note("roll", bass_note(at(parts, 0), 37), bar * 4, 3.8, vel=0.4 + 0.12 * bar)
            comp(s, "oohs", bar, parts, "x---------------", low=51, vel=0.5, spread=0.2)
            if bar == 3:
                roll(s, bar, start=2.0, count=8, kind="tom")
        if a1 or a2:
            ostinato(s, "strings", bar, parts, [0, 0, 7, 0, 12, 0, 7, 0], step=0.25, low=46, vel=0.7)
            bassline(s, "bass", bar, parts, [(0, 0.45, 0), (0.75, 0.45, 0), (1.5, 0.45, 0), (2, 0.45, 0), (2.75, 0.45, 0), (3.5, 0.45, 0)], low=31, vel=0.8)
            beat(s, bar, {"kick": "x..x..x...x..x..", "snare": "....x.......x...", "hat": "x.xxx.xxx.xxx.xx"})
            s.note("timp", root - 12, bar * 4, 0.9, vel=0.8)
            if a2:
                comp(s, "choir", bar, parts, "x-------x-------", low=55, vel=0.6, spread=0.2)
                comp(s, "pad", bar, parts, "x---------------", low=51, vel=0.55, spread=0.2)
        if can or can2:
            # The drone: bass, timpani and strings hold Eb while the choirs chase each other.
            comp(s, "pad", bar, parts, "x---------------", low=51, vel=0.5 if can else 0.6, spread=0.2)
            bassline(s, "bass", bar, parts, [(0, 1.8, 0), (2, 1.8, 0)], low=31, vel=0.7)
            if bar % 2 == 0:
                s.note("bells", "Eb5" if at(parts, 0) == "Ebm" else "Bb4", bar * 4, 2.0, vel=0.65)
            if can:
                beat(s, bar, {"kick": "x.......x.......", "tom": "....o.......o.o."}, vel=0.8)
                s.note("timp", root - 12, bar * 4, 0.9, vel=0.65)
            else:
                ostinato(s, "strings", bar, parts, [0, 7, 12, 7], step=0.25, low=46, vel=0.65)
                beat(s, bar, {"kick": "x..x..x...x..x..", "snare": "....x.......x...", "ride": "x.x.x.x.x.x.x.x."})
                s.note("timp", root - 12, bar * 4, 0.9, vel=0.8)
                s.note("timp", root - 12, bar * 4 + 2, 0.9, vel=0.65)
        if build:
            ostinato(s, "strings", bar, parts, [0, 12, 0, 12], step=0.25, low=46, vel=0.6 + 0.07 * (bar - 20))
            comp(s, "horn", bar, parts, "x..x..x...x.x.x.", low=51, vel=0.7, spread=0.2)
            beat(s, bar, {"tom": "x..x..x.x..x..x.", "kick": "x.......x.......", "snare": "............x.x."}, vel=0.8)
            s.note("roll", root - 12, bar * 4, 3.8, vel=0.5 + 0.1 * (bar - 20))
            comp(s, "choir", bar, parts, "x---------------", low=55 + 2 * (bar - 20), vel=0.6, spread=0.2)
            if bar == 23:
                roll(s, bar, start=2.0, count=8)
        if bar in (11, 19, 31):
            roll(s, bar, start=3.0, count=4)
        if bar in (4, 12, 24, 32):
            s.hit("crash", bar * 4, vel=0.8)
    roll(s, 39, start=2.0, count=8, kind="tom")
    melody(s, "horn", 4, A5_HOOK, bars=8, vel=0.85)
    melody(s, "glock", 8, "r:4 | Bb6:1 Ab6 Gb6 F6 | r:4 | Ab6:1 Gb6 F6 Eb6", bars=4, vel=0.55)
    melody(s, "choir", 12, A5_LEAD, bars=8, vel=0.75)
    melody(s, "oohs", 12, A5_FOLLOW, bars=8, vel=0.7, transpose=-12)
    melody(s, "horn", 24, A5_HOOK, bars=8, vel=0.9)
    melody(s, "tpt", 24, A5_HOOK, bars=8, vel=0.75, transpose=12)
    melody(s, "choir", 32, A5_LEAD, bars=8, vel=0.8)
    melody(s, "oohs", 32, A5_FOLLOW, bars=8, vel=0.75, transpose=-12)
    melody(s, "horn", 32, A5_LEAD, bars=8, vel=0.65, transpose=-12)
    return s


# ---------------------------------------------------------------------------------------------
# The Chairman of the Board. 168 bpm. It opens as his own cheerful corporate muzak in D major (vibes
# and electric piano, a polite rim click); the tape stutters, grinds down and stops; then the same
# tune comes back in D minor at full tilt on brass and distorted guitar; a march-like middle on horns
# and short strings with the choir; then it collapses into a grand half-time finale for choir, church
# organ and the whole orchestra; then it falls apart a note at a time, a clock ticks, and a polite
# chime starts the muzak again. 48 bars: muzak (8), stutter (4), A (8), B (8), finale (12), collapse (8).
# ---------------------------------------------------------------------------------------------

CH_MUZAK = ("F#5:2 A5:1 D6:1 | C#6:2 B5:2 | G5:2 B5:1 E6:1 | D6:2 C#6:2 | "
            "F#5:2 A5:1 D6:1 | F#6:2 E6:1 D6:1 | B5:1 G5:1 C#6:1 E6:1 | D6:4")
CH_STUTTER = ("F#5:.5 F#5 F#5 F#5 F#5:.25 F#5 F#5 F#5 r:1 | "
              "D6:.25 C#6 C6 B5 Bb5 A5 G#5 G5 F#5:.5 F5 E5 Eb5 | r:4 | r:4")
CH_A = ("F5:.5 A5 D6:1 C6:.5 A5 F5:1 | Bb5:.5 A5 F5 D5 F5:2 | G5:.5 Bb5 D6:1 F6:.5 E6 D6:1 | C#6:1.5 A5:.5 E5:1 C#5 | "
        "F5:.5 A5 D6:1 F6:1 E6:.5 D6 | D6:.5 C6 Bb5 A5 Bb5:1 D6 | G5:.5 Bb5 D6 G6 E6 C#6 A5 G5 | F5:1 D5 A4:2")
CH_B = ("D5:1 F5 Bb5:2 | C5:1 E5 G5:2 | C6:1 B5 A5:2 | A5:3 F5:1 | "
        "Bb5:1 A5 G5 D5 | E5:1 A5 C#6:2 | D6:1.5 C6:.5 Bb5:1 F5 | E5:2 G5:2")
CH_FINALE = ("F5:2 A5:1 D6:1 | C6:2 A5:2 | Bb5:2 D6:1 F6:1 | F6:2 D6:2 | G5:2 Bb5:1 D6:1 | D6:2 G6:2 | "
             "E6:2 C#6:1 A5:1 | E6:4 | F6:2 E6:1 D6:1 | D6:2 F6:2 | G6:2 E6:2 | D6:4")
CH_COLLAPSE = "F5:.5 A5 D6:1 r:2 | F5:.5 A5 r:3 | F5:.5 r:3.5 | r:4 | r:4 | r:4 | r:4 | r:4"
CH_A_CHORDS = "Dm Bb Gm A7 Dm Bb Gm,A7 Dm"
CH_CHORDS = " ".join(["Dmaj7 Bm7 Em7 A7 Dmaj7 Bm7 Em7,A7 Dmaj7", "Dmaj7 Dmaj7 Dm A7", CH_A_CHORDS,
                      "Bb C Am Dm Gm A Bb A7", "Dm Dm Bb Bb Gm Gm A A Dm Bb Gm,A Dm", "Dm Dm Dm Dm Dm Dm A7 A7"])


def the_chairman():
    s = Band(168, 48, loudness=-16.5, room=0.6)
    s.part("vibes", "vibes", level=0.6, reverb=0.5)
    s.part("ep", "epiano", level=0.5, reverb=0.4)
    s.part("bass", "fingerbass", level=0.75, reverb=0.08)
    s.part("gtr", "distortion", level=0.5, reverb=0.15)
    s.part("brass", "brass", level=0.62, reverb=0.35)
    s.part("strings", "orch_strings_short", level=0.66, reverb=0.45)
    s.part("horn", "orch_horn", level=0.72, reverb=0.5)
    s.part("tpt", "orch_trumpet", level=0.62, reverb=0.5)
    s.part("choir", "choir", level=0.62, reverb=0.65)
    s.part("organ", "churchorgan", level=0.55, reverb=0.6)
    s.part("timp", "orch_timpani", level=0.75, reverb=0.45)
    s.part("roll", "orch_timpani_roll", level=0.62, reverb=0.45)
    s.kit("power", level=0.8)
    p = _bars(CH_CHORDS, 48)
    for bar, parts in enumerate(p):
        muzak, stut, a, b, fin, col = bar < 8, 8 <= bar < 12, 12 <= bar < 20, 20 <= bar < 28, 28 <= bar < 40, bar >= 40
        root = bass_note(at(parts, 0), 38)
        if muzak:
            comp(s, "ep", bar, parts, "x---..x-x---....", low=57, vel=0.45, spread=0.0)
            bassline(s, "bass", bar, parts, [(0, 1.4, 0), (1.5, 0.45, 7), (2, 1.4, 0), (3.5, 0.45, 7)], low=33, vel=0.6)
            beat(s, bar, {"rim": "...o.....o..o...", "pedalhat": "o.o.o.o.o.o.o.o."}, vel=0.6)
        if stut and bar == 8:
            comp(s, "ep", bar, parts, "xxxx............", low=57, vel=0.45, spread=0.0)
            bassline(s, "bass", bar, parts, [(0, 0.2, 0), (0.25, 0.2, 0), (0.5, 0.2, 0), (0.75, 0.2, 0)], low=33, vel=0.6)
        if stut and bar == 10:
            s.hit("click", bar * 4, vel=0.8)
            s.hit("click", bar * 4 + 0.5, vel=0.5)
        if stut and bar == 11:
            roll(s, bar, start=0.0, count=16, low=0.2, high=0.95)
        if a:
            power(s, "gtr", bar, parts, "x.xxx.xxx.xxx.x.", low=38, vel=0.75)
            bassline(s, "bass", bar, parts, [(e * 0.5, 0.42, 0 if e % 4 else 12) for e in range(8)], low=26, vel=0.85)
            comp(s, "brass", bar, parts, "x.....x.....x...", low=55, vel=0.6, spread=0.0)
            beat(s, bar, {"kick": "x.x...x.x.x...x.", "snare": "....x.......x...", "hat": "x.x.x.x.x.x.x.x."})
        if b:
            ostinato(s, "strings", bar, parts, [0, 7, 12, 7], step=0.5, low=48, vel=0.75)
            comp(s, "choir", bar, parts, "x-------x-------", low=55, vel=0.6, spread=0.0)
            power(s, "gtr", bar, parts, "x..x..x.x..x..x.", low=38, vel=0.65)
            bassline(s, "bass", bar, parts, [(0, 0.9, 0), (1, 0.9, 7), (2, 0.9, 12), (3, 0.9, 7)], low=26, vel=0.8)
            beat(s, bar, {"kick": "x...x...x...x...", "snare": "....x.......x..o", "ride": "x.x.x.x.x.x.x.x."})
            s.note("timp", root - 12, bar * 4, 0.9, vel=0.7)
        if fin:
            # Half time and enormous: organ and choir hold, the strings saw away, the timpani roll.
            comp(s, "organ", bar, parts, "x-------x-------", low=50, vel=0.7, spread=0.0)
            comp(s, "choir", bar, parts, "x-------x-------", low=55, vel=0.7, spread=0.0)
            ostinato(s, "strings", bar, parts, [0, 12, 7, 12], step=0.25, low=48, vel=0.7)
            power(s, "gtr", bar, parts, "x-------x-------", low=38, vel=0.7, length=1.9)
            bassline(s, "bass", bar, parts, [(0, 1.9, 0), (2, 1.9, 0)], low=26, vel=0.85)
            beat(s, bar, {"kick": "x.......x.......", "snare": "........x.......", "crash": "x..............."}, vel=0.85)
            s.note("roll", root - 12, bar * 4, 3.8, vel=0.55)
        if col:
            k = bar - 40
            if k < 3:
                power(s, "gtr", bar, parts, "x...............", low=38, vel=0.7 - 0.15 * k, length=1.0)
                bassline(s, "bass", bar, parts, [(0, 1.0, 0)], low=26, vel=0.8 - 0.15 * k)
                beat(s, bar, {"kick": "x...............", "snare": "x..............." if k == 0 else "................"}, vel=0.8 - 0.2 * k)
            if k == 3:
                comp(s, "organ", bar, parts, "x---------------", low=50, vel=0.35, spread=0.0)
            if 4 <= k < 8:
                beat(s, bar, {"tick": "x...x...x...x..." if k < 7 else "x...x..........."}, vel=0.7)
        if bar in (19, 27):
            roll(s, bar, start=3.0, count=4)
        if bar in (12, 20, 28):
            s.hit("crash", bar * 4, vel=0.9)
    melody(s, "vibes", 0, CH_MUZAK, bars=8, vel=0.7)
    melody(s, "vibes", 8, CH_STUTTER, bars=4, vel=0.7)
    melody(s, "brass", 12, CH_A, bars=8, vel=0.85)
    melody(s, "gtr", 12, CH_A, bars=8, vel=0.65, transpose=-12)
    melody(s, "horn", 20, CH_B, bars=8, vel=0.85)
    melody(s, "tpt", 28, CH_FINALE, bars=12, vel=0.85)
    melody(s, "horn", 28, CH_FINALE, bars=12, vel=0.8, transpose=-12)
    melody(s, "brass", 40, CH_COLLAPSE, bars=8, vel=0.7)
    s.note("vibes", "A5", 47 * 4 + 2, 0.5, vel=0.6)
    s.note("vibes", "F#5", 47 * 4 + 2.5, 0.5, vel=0.6)
    s.note("vibes", "D5", 47 * 4 + 3, 1.0, vel=0.6)
    return s
