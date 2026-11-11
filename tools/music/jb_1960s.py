"""Harold's Jukebox, depth 2: the 1960s, Harold in his twenties.

Three paths, three corners of the decade: spooky surf rock in the Cemetery, sweet soul at Sunset
Shores, a fuzzy garage stomp in the Furnace Works; the floor boss throws all of it at you. Every song
is built on the hold theme (jb_theme).
"""
import synth
from synth import bass_note, chord
from band import Band, beat, roll
from kit import mel, melody, prog, comp, bassline, at
from jb_theme import THEME_A, THEME_A2, THEME_B, minor

INFO = {
    "unkempt_cemetery": dict(key="A minor", bpm=168, meter=4, bars=32,
                             about="Cemetery: spooky surf rock, tremolo-picked reverb guitar, combo organ, rattling bones, the whistle ghosting the hold theme in minor."),
    "sunset_shores": dict(key="Bb major", bpm=104, meter=4, bars=32,
                          about="Sunset Shores: sweet seaside soul, horns on the hold theme, tambourine and organ, waves and gulls, the whistle on the bridge."),
    "furnace_works": dict(key="D minor", bpm=150, meter=4, bars=32, quiet=[(0, 2)],
                          about="Furnace Works: a fuzzy garage stomp, overdrive riff, stomp-and-clap drums, clanking metal, the whistle on the minor hold theme."),
    "boss_depth_2": dict(key="G minor", bpm=176, meter=4, bars=32,
                         about="Depth 2 boss: fuzz guitars, galloping surf toms and brass blasting the hold theme in minor."),
}


def _bars(text, count):
    p = prog(text)
    assert len(p) == count, "progression has %d bars, not %d" % (len(p), count)
    return p


def surf_line(s, inst, bar, text, bars, transpose=0, vel=0.8, hold=1.0, step=0.25):
    """A surf lead: notes of `hold` beats or longer are tremolo-picked (repeated every `step`), shorter
    ones picked once."""
    notes, count = mel(text, s.meter)
    assert count == bars, "surf line has %d bars, not %d: %s" % (count, bars, text[:40])
    t = bar * s.meter
    for name, beats in notes:
        if name != "r":
            m = synth.midi(name) + transpose
            if beats >= hold:
                k = 0
                while k * step < beats - 1e-6:
                    s.note(inst, m, t + k * step, step * 0.9, vel=vel * (0.95 if k % 2 == 0 else 0.75))
                    k += 1
            else:
                s.note(inst, m, t, beats * 0.95, vel=vel)
        t += beats


def power(s, inst, bar, parts, rhythm="x.x.x.x.x.x.x.x.", low=40, vel=0.7, octave=True):
    """Power chords (root, fifth, octave) on a grid, following the chord roots."""
    step = s.meter / len(rhythm)
    for i, c in enumerate(rhythm):
        if c in "xo":
            off = i * step
            root = bass_note(at(parts, off), low)
            for m in (root, root + 7) + ((root + 12,) if octave else ()):
                s.note(inst, m, bar * s.meter + off, step * 0.9, vel=vel * (1.0 if c == "x" else 0.7))


# ---------------------------------------------------------------------------------------------
# The Unkempt Cemetery: depth 2, 1963. Spooky surf rock in A minor, 168 bpm, straight: a clean
# guitar drowned in reverb, tremolo-picking its long notes; a cheesy combo organ; a muted rhythm
# guitar and pick bass chugging eighths; surf drums heavy on the toms. Bones rattle (the vibraslap)
# at the ends of phrases. 32 bars: tom rumble and organ (4), A surf lead (8), B the whistle ghosting
# the hold theme in minor (8), C an organ break over the toms (8), A again to turn round (4).
# ---------------------------------------------------------------------------------------------

GRAVE_CHORDS = " ".join(["Am Am F E7",
                         "Am Am G G F F E7 E7",
                         "Am C Bm7b5 E7 Am Fmaj7 Dm7 E7",
                         "Dm Dm Am Am Bb Bb E7 E7",
                         "Am G F E7"])
GRAVE_LEAD = ("A4:.5 C5 E5 A5:1.5 G5:.5 E5 | C5:2 r:1 E5:.5 D5 | B4:.5 D5 G5:1.5 F5:.5 D5:1 | B4:3 r:1 | "
              "A4:.5 C5 F5 A5 G5:1 F5 | C5:2 A4:2 | G#4:.5 B4 D5 E5 G#5:1 F5:.5 D5 | E5:4")
GRAVE_BACK = "A4:.5 C5 E5 A5:1.5 G5:.5 E5 | D5:.5 B4 G4 B4 D5:2 | C5:.5 A4 F4 A4 C5:2 | B4:.5 G#4 E4 G#4 B4:1 r:1"
GRAVE_ORGAN = ("D5:.5 F5 A5 D6 C6:1 A5 | F5:1.5 E5:.5 D5:2 | C5:.5 E5 A5 C6 B5:1 A5 | E5:3 r:1 | "
               "D5:.5 F5 Bb5 D6 C6:1 Bb5 | F5:1.5 D5:.5 Bb4:2 | G#5:.5 B5 D6 E6 D6 B5 G#5 E5 | F5:1 E5 D5 G#4")
EIGHTHS = [(e * 0.5, 0.45, 12 if e == 7 else 0) for e in range(8)]


def unkempt_cemetery():
    s = Band(168, 32, loudness=-17.5, room=0.75)
    s.part("lead", "cleangtr", level=0.66, pan=0.15, reverb=0.8)
    s.part("rhythm", "mutedgtr", level=0.5, pan=-0.45, reverb=0.3)
    s.part("organ", "percorgan", level=0.48, pan=0.45, reverb=0.5)
    s.part("bass", "pickbass", level=0.75, reverb=0.1)
    s.part("whistle", "whistle", level=0.5, pan=-0.1, reverb=0.9)
    s.part("ghost", "choirpad", level=0.3, reverb=0.8)
    s.kit("room", level=0.8)
    p = _bars(GRAVE_CHORDS, 32)
    for bar, parts in enumerate(p):
        intro, a1, b, c, a2 = bar < 4, 4 <= bar < 12, 12 <= bar < 20, 20 <= bar < 28, bar >= 28
        if intro:
            # The toms rumble in under a held organ chord.
            for q in range(16):
                s.hit("tom_floor", bar * 4 + q * 0.25, vel=0.25 + 0.5 * (bar * 16 + q) / 64)
            comp(s, "organ", bar, parts, "x---------------", low=57, vel=0.55, spread=0.0)
            if bar >= 2:
                bassline(s, "bass", bar, parts, EIGHTHS, low=33, vel=0.7)
            continue
        bassline(s, "bass", bar, parts, EIGHTHS, low=33, vel=0.8)
        power(s, "rhythm", bar, parts, "x.o.x.o.x.o.x.o.", low=40, vel=0.6, octave=False)
        if c:
            beat(s, bar, {"kick": "x.......x.......", "snare": "....x.......x...", "tom_lo": "x..x..x.x..x..x.", "tom": "..........x....."})
        else:
            beat(s, bar, {"kick": "x.....x.x.......", "snare": "....x.......x...", "ride": "x.o.x.o.x.o.x.o."}, vel=0.85)
        if a1 or a2:
            comp(s, "organ", bar, parts, "..x-..x-..x-..x-", low=57, vel=0.45, spread=0.0)
        if b:
            comp(s, "organ", bar, parts, "x---------------", low=52, vel=0.38, spread=0.0)
            comp(s, "ghost", bar, parts, "x---------------", low=57, vel=0.45, spread=0.0)
        # Rattling bones at the end of each phrase.
        if bar in (7, 11, 15, 19, 23, 27, 31):
            s.hit("vibraslap", bar * 4 + 3, vel=0.7)
        if bar in (11, 19, 27):
            roll(s, bar, start=2.0, count=8, kind="tom")
    for bar in (4, 20, 28):
        s.hit("crash", bar * 4, vel=0.65)
    surf_line(s, "lead", 4, GRAVE_LEAD, 8, vel=0.82)
    # The hold theme in minor, moved to A, whistled like something left over from the night before.
    melody(s, "whistle", 12, minor(THEME_A), bars=8, vel=0.72, transpose=4)
    surf_line(s, "lead", 12, "A3:4 | C4:4 | B3:4 | G#3:4 | A3:4 | F3:4 | D4:4 | E4:4", 8, vel=0.4)
    melody(s, "organ", 20, GRAVE_ORGAN, bars=8, vel=0.75)
    surf_line(s, "lead", 28, GRAVE_BACK, 4, vel=0.85)
    return s


# ---------------------------------------------------------------------------------------------
# Sunset Shores: depth 2, a care home by the sea, 1966. Sweet soul in Bb, 104 bpm with a lilt: a
# syncopated finger bass, clean guitar chops on two and four, a warm drawbar organ, tambourine. An
# alto sax sings the verse; the horn section plays the hold theme as the chorus; Harold whistles the
# middle eight. Waves wash in and gulls cry at the top. 32 bars: waves and groove (2), verse (8),
# chorus on the theme (8), whistled bridge (8), chorus again and a turnaround (6).
# ---------------------------------------------------------------------------------------------

SHORES_CHORDS = " ".join(["Bb6 Bb6",
                          "Bb6 Eb9 Bb6 Eb9 Gm7 C7 Cm7 F7",
                          "Bbmaj7 Gm7 Cm7 F7 Bbmaj7 Gm7 Cm7 F7",
                          "Ebmaj7 Ab9 Dm7 G7 Cm7 F7 Bbmaj7 F7",
                          "Bbmaj7 Gm7 Cm7 F7 Ebmaj7 F7"])
SHORES_VERSE = ("F4:.5 G4 Bb4:1 D5:.5 C5 Bb4:1 | G4:1.5 F4:.5 Db5:1 C5 | Bb4:.5 C5 D5 F5 G5:1 F5 | "
                "Eb5:1.5 Db5:.5 Bb4:2 | D5:.5 F5 G5 Bb5 A5:1 G5 | E5:1.5 G5:.5 Bb5:1 G5 | "
                "Eb5:.5 D5 C5 Bb4 G4:1 Bb4 | A4:.5 C5 Eb5 F5 A5:2")
SHORES_TURN = "G5:.5 F5 Eb5 D5 C5:1 Bb4 | A4:.5 C5 F5 A5 r:2"
SOUL_BASS = [(0, 0.7, 0), (0.75, 0.25, 0), (1.5, 0.5, 7), (2, 0.75, 12), (3, 0.5, 9), (3.5, 0.5, 7)]


def sunset_shores():
    s = Band(104, 32, swing=0.05, loudness=-17.5, room=0.5)
    s.part("bass", "fingerbass", level=0.78, reverb=0.08)
    s.part("gtr", "cleangtr", level=0.45, pan=-0.45, reverb=0.25)
    s.part("organ", "organ", level=0.4, pan=0.35, reverb=0.35)
    s.part("alto", "altosax", level=0.62, pan=0.05, reverb=0.35)
    s.part("trumpet", "trumpet", level=0.6, pan=0.25, reverb=0.35)
    s.part("tenor", "tenorsax", level=0.55, pan=-0.25, reverb=0.35)
    s.part("bone", "trombone", level=0.45, pan=-0.1, reverb=0.35)
    s.part("strings", "orch_strings", level=0.4, pan=0.5, reverb=0.5)
    s.part("whistle", "whistle", level=0.55, reverb=0.45)
    s.part("sea", "seashore", level=0.35, reverb=0.4)
    s.part("gulls", "bird", level=0.2, pan=-0.5, reverb=0.7)
    s.kit("standard", level=0.72)
    p = _bars(SHORES_CHORDS, 32)
    for bar, parts in enumerate(p):
        intro, verse, chorus, bridge, back = bar < 2, 2 <= bar < 10, 10 <= bar < 18, 18 <= bar < 26, bar >= 26
        bassline(s, "bass", bar, parts, SOUL_BASS, low=34, vel=0.78)
        beat(s, bar, {"kick": "x......x..x.....", "snare": "....x.......x...", "hat": "x.o.x.o.x.o.x.o."}, vel=0.75)
        beat(s, bar, {"tambourine": "o.g.x.g.o.g.x.g." if (chorus or back) else "....x.......x..."}, vel=0.7)
        comp(s, "gtr", bar, parts, "....x.......x...", low=62, vel=0.5, spread=0.0)
        comp(s, "organ", bar, parts, "x---------------", low=53, vel=0.45 if (verse or bridge or intro) else 0.55, spread=0.0)
        if chorus or back:
            comp(s, "strings", bar, parts, "x-------x-------", low=65, vel=0.45, spread=0.0)
            comp(s, "bone", bar, parts, "x-------x-------", low=50, vel=0.45, spread=0.0, drop=2)
        if verse:
            # The horns answer the singer on the and-of-four.
            if bar % 2 == 1:
                comp(s, "trumpet", bar, parts, "..............x.", low=62, vel=0.55, spread=0.0, drop=1)
                comp(s, "tenor", bar, parts, "..............x.", low=55, vel=0.55, spread=0.0, drop=1)
        if bar in (9, 17, 25):
            roll(s, bar, start=3.0, count=4, low=0.25, high=0.6)
    # Waves at the top, a gull or two.
    s.note("sea", "C4", 0, 8, vel=0.7)
    for k, n in enumerate(("A6", "F6", "A6")):
        s.note("gulls", n, 1 + k * 0.4, 0.3, vel=0.5)
    melody(s, "alto", 2, SHORES_VERSE, bars=8, vel=0.8)
    # The chorus: the hold theme in Bb, trumpet and tenor an octave apart.
    melody(s, "trumpet", 10, THEME_A, bars=8, vel=0.8, transpose=5)
    melody(s, "tenor", 10, THEME_A, bars=8, vel=0.72, transpose=-7)
    melody(s, "whistle", 18, THEME_B, bars=8, vel=0.78, transpose=5)
    melody(s, "trumpet", 26, THEME_A2, bars=4, vel=0.82, transpose=5)
    melody(s, "tenor", 26, THEME_A2, bars=4, vel=0.74, transpose=-7)
    melody(s, "alto", 30, SHORES_TURN, bars=2, vel=0.8)
    return s


# ---------------------------------------------------------------------------------------------
# The Furnace Works: depth 2, 1967. A fuzzy garage stomp in D minor, 150 bpm: an overdriven guitar
# riff doubled in fifths, stomp-and-clap drums on four, a pick bass, a screaming rock organ, and the
# works clanking along on cowbell, timbale and a muted triangle. 32 bars: the riff alone, then the
# band (4), A organ tune over the riff (8), B the whistle on the minor hold theme over power chords
# (8), C a clanking breakdown that builds (8), A again to turn round (4).
# ---------------------------------------------------------------------------------------------

FURNACE_CHORDS = " ".join(["Dm Dm Dm A7",
                           "Dm Dm Dm Dm Bb Bb A7 A7",
                           "Dm F Em7b5 A7 Dm Bbmaj7 Gm7 A7",
                           "Dm Dm Dm Dm Gm Gm A7 A7",
                           "Dm Dm Bb A7"])
RIFF = ["D3:.5 D3 F3 G3 D3 C4 A3 G3", "D3:.5 D3 F3 G3 Bb3:1 A3"]
FURNACE_ORGAN = ("A4:1 D5 F5:1.5 E5:.5 | D5:.5 C5 A4:3 | A4:1 D5 G5:1.5 F5:.5 | E5:.5 D5 C5:1 A4:2 | "
                 "Bb4:.5 D5 F5 Bb5 A5:1 F5 | D5:2 r:1 F5 | E5:.5 C#5 E5 G5 A5:2 | G5:1 E5 C#5 A4")
FURNACE_BACK = "A4:1 D5 F5:1.5 E5:.5 | D5:.5 C5 A4:3 | Bb4:.5 D5 F5 Bb5 A5:1 F5 | G5:1 E5 C#5 A4"
CLANKS = {"cowbell": "x.....o...x.....", "timbale": "......x.......o.", "triangle_mute": "..o.......o....."}


def riff(s, inst, bar, parts, vel=0.75):
    """The riff, moved to the bar's chord root (D, Bb or A), each note doubled a fifth up."""
    shift = (chord(at(parts, 0))[1] - 2) % 12
    shift = shift - 12 if shift > 5 else shift
    notes, _ = mel(RIFF[bar % 2], s.meter)
    t = bar * s.meter
    for name, beats in notes:
        m = synth.midi(name) + shift
        for n in (m, m + 7):
            s.note(inst, n, t, beats * 0.9, vel=vel)
        t += beats


def furnace_works():
    s = Band(150, 32, loudness=-17.0, room=0.45)
    s.part("fuzz", "overdrive", level=0.62, pan=-0.35, reverb=0.25)
    s.part("chug", "distortion", level=0.45, pan=0.45, reverb=0.2)
    s.part("bass", "pickbass", level=0.78, reverb=0.08)
    s.part("organ", "rockorgan", level=0.55, pan=0.2, reverb=0.35)
    s.part("whistle", "whistle", level=0.62, pan=0.05, reverb=0.4)
    s.kit("power", level=0.82)
    p = _bars(FURNACE_CHORDS, 32)
    for bar, parts in enumerate(p):
        intro, a1, b, c, a2 = bar < 4, 4 <= bar < 12, 12 <= bar < 20, 20 <= bar < 28, bar >= 28
        beat(s, bar, CLANKS, vel=0.75 if not c else 0.9)
        if b:
            power(s, "chug", bar, parts, "x.o.x.o.x.o.x.o.", low=38, vel=0.55)
            bassline(s, "bass", bar, parts, [(e * 0.5, 0.45, 0) for e in range(8)], low=26, vel=0.8)
        elif c and bar < 24:
            # The breakdown: the riff drops out, only bass, drums and metal.
            bassline(s, "bass", bar, parts, [(0, 0.9, 0), (1.5, 0.45, 0), (2, 0.9, 12), (3.5, 0.45, 0)], low=26, vel=0.85)
            comp(s, "organ", bar, parts, "x.......x.....x.", low=57, vel=0.6, spread=0.0)
        else:
            riff(s, "fuzz", bar, parts, vel=0.8)
            if bar >= 2:
                bassline(s, "bass", bar, parts, [(e * 0.5, 0.45, 0) for e in range(8)], low=26, vel=0.8)
        if c and bar >= 24:
            riff(s, "fuzz", bar, parts, vel=0.6 + 0.08 * (bar - 24))
            power(s, "chug", bar, parts, "x...x...x...x...", low=38, vel=0.5 + 0.08 * (bar - 24))
        if bar >= 2:
            if c and bar < 24:
                beat(s, bar, {"kick": "x.......x.......", "snare": "........x.......", "clap": "........x......."})
            else:
                beat(s, bar, {"kick": "x...x...x...x...", "snare": "....x.......x...", "clap": "....x.......x...", "hat": "x.x.x.x.x.x.x.x."}, vel=0.85)
        if bar in (11, 19, 31):
            roll(s, bar, start=3.0, count=4)
        if bar == 27:
            roll(s, bar, start=0.0, count=16, low=0.2, high=0.9)
    for bar in (4, 12, 24, 28):
        s.hit("crash", bar * 4, vel=0.7)
    melody(s, "organ", 4, FURNACE_ORGAN, bars=8, vel=0.8)
    # The hold theme in minor, moved to D, whistled over the furnace.
    melody(s, "whistle", 12, minor(THEME_A), bars=8, vel=0.8, transpose=9)
    melody(s, "organ", 12, "D4:4 | F4:4 | E4:4 | E4:4 | D4:4 | D4:4 | D4:4 | C#4:4", bars=8, vel=0.4)
    melody(s, "organ", 28, FURNACE_BACK, bars=4, vel=0.82)
    return s


# ---------------------------------------------------------------------------------------------
# Depth 2 boss: the whole decade at once, G minor, 176 bpm. Surf toms gallop, a fuzz guitar
# tremolo-picks power chords, brass blasts the hold theme in minor, a rock organ swells under it.
# 32 bars: toms and tremolo (4), A brass on the theme (8), B a distorted lead over brass stabs (8),
# A brass, organ and fuzz together with crashes (8), stop-time hits and a tom roll round (4).
# ---------------------------------------------------------------------------------------------

BOSS2_A_CHORDS = "Gm Bb Am7b5 D7 Gm Ebmaj7 Cm7 D7"
BOSS2_CHORDS = " ".join(["Gm Gm Gm D7", BOSS2_A_CHORDS, "Cm Cm Gm Gm Eb Eb D7 D7", BOSS2_A_CHORDS, "Gm Eb D7 D7"])
BOSS2_LEAD = ("C5:.5 Eb5 G5 C6 Bb5:1 G5 | Eb5:1.5 D5:.5 C5:2 | D5:.5 G5 Bb5 D6 C6:1 Bb5 | G5:3 r:1 | "
              "Eb5:.5 G5 Bb5 Eb6 D6:1 Bb5 | G5:1.5 F5:.5 Eb5:2 | F#5:.5 A5 C6 D6 C6 A5 F#5 D5 | A5:1 F#5 D5 A4")
BOSS2_TAG = "D5:.5 Bb4 D5 G5:1.5 F5:.5 Eb5 | G5:.5 Eb5 Bb4 Eb5 G5:2 | F#5:4 | A5:2 D5:2"
SURF_GALLOP = "x.xxx.xxx.xxx.xx"


def boss_depth_2():
    s = Band(176, 32, loudness=-16.0, room=0.5)
    s.part("fuzz", "overdrive", level=0.55, pan=-0.45, reverb=0.3)
    s.part("lead", "distortion", level=0.6, pan=0.3, reverb=0.4)
    s.part("brass", "brass", level=0.62, pan=0.2, reverb=0.35)
    s.part("trumpet", "trumpet", level=0.6, pan=0.4, reverb=0.35)
    s.part("bone", "trombone", level=0.55, pan=-0.25, reverb=0.3)
    s.part("organ", "rockorgan", level=0.5, pan=-0.1, reverb=0.4)
    s.part("bass", "pickbass", level=0.8, reverb=0.08)
    s.part("timp", "orch_timpani", level=0.55, reverb=0.4)
    s.kit("power", level=0.85)
    p = _bars(BOSS2_CHORDS, 32)
    theme = minor(THEME_A)
    for bar, parts in enumerate(p):
        intro, a1, b, a2, tag = bar < 4, 4 <= bar < 12, 12 <= bar < 20, 20 <= bar < 28, bar >= 28
        if tag and bar < 30:
            comp(s, "brass", bar, parts, "x.....x.........", low=55, vel=0.9, spread=0.0)
            power(s, "fuzz", bar, parts, "x.....x.........", low=40, vel=0.9)
            bassline(s, "bass", bar, parts, [(0, 0.45, 0), (1.5, 0.45, 0)], low=31, vel=0.9)
            beat(s, bar, {"kick": "x.....x.........", "crash": "x...............", "snare": "......x........."})
            continue
        if tag:
            for q in range(16):
                s.hit("tom_lo" if q % 4 < 2 else "tom", bar * 4 + q * 0.25, vel=0.4 + 0.5 * ((bar - 30) * 16 + q) / 32)
            s.note("timp", bass_note(at(parts, 0), 38), bar * 4, 1, vel=0.8)
            continue
        bassline(s, "bass", bar, parts, [(e * 0.5, 0.45, 12 if e in (3, 7) else 0) for e in range(8)], low=31, vel=0.85)
        beat(s, bar, {"tom_lo": SURF_GALLOP, "tom": "....x.......x..."}, vel=0.7 if intro or b else 0.5)
        if intro:
            power(s, "fuzz", bar, parts, "x" * 16, low=40, vel=0.55 + 0.1 * bar)
            if bar == 3:
                s.swell("organ", bar * 4, 4, 30, 127)
                comp(s, "organ", bar, parts, "x---------------", low=55, vel=0.7, spread=0.0)
            continue
        beat(s, bar, {"kick": "x.x...x.x.x...x.", "snare": "....x.......x...", "hat": "x.x.x.x.x.x.x.x."})
        if a1 or a2:
            power(s, "fuzz", bar, parts, "x.x.x.x.x.x.x.x.", low=40, vel=0.65)
            comp(s, "organ", bar, parts, "x---------------", low=55, vel=0.55, spread=0.0)
            if bar % 2 == 0:
                s.note("timp", bass_note(at(parts, 0), 38), bar * 4, 1, vel=0.75)
        if b:
            power(s, "fuzz", bar, parts, "x" * 16, low=40, vel=0.5)
            comp(s, "brass", bar, parts, "..x...x...x..x..", low=58, vel=0.75, spread=0.0)
        if a2:
            s.hit("crash", bar * 4, vel=0.6 if bar % 2 else 0.75)
        if bar in (11, 19, 27):
            roll(s, bar, start=2.0, count=8)
    s.hit("crash", 4 * 4, vel=0.75)
    s.hit("crash", 12 * 4, vel=0.7)
    # The hold theme in minor, moved to G, blasted on brass with the trombones an octave down.
    melody(s, "trumpet", 4, theme, bars=8, vel=0.85, transpose=2)
    melody(s, "bone", 4, theme, bars=8, vel=0.8, transpose=-10)
    melody(s, "lead", 12, BOSS2_LEAD, bars=8, vel=0.85)
    melody(s, "trumpet", 20, theme, bars=8, vel=0.9, transpose=2)
    melody(s, "organ", 20, theme, bars=8, vel=0.75, transpose=2)
    melody(s, "lead", 20, theme, bars=8, vel=0.7, transpose=-10)
    melody(s, "bone", 20, theme, bars=8, vel=0.85, transpose=-10)
    melody(s, "trumpet", 28, BOSS2_TAG, bars=4, vel=0.9)
    return s
