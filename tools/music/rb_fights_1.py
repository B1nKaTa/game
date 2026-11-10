"""Fight songs, real instruments: the shared mini boss and the floor bosses of depths 1 and 2.

Each keeps its old song's idea (fights.py) with all-new material and quotes no shared theme, so no
two fights sound alike: the mini boss is a light orchestral chase, depth 1 a chip-lead rock fight,
depth 2 brass and organ over a machine riff.
"""
from band import Band, beat, roll
from kit import melody, prog, comp, bassline, arp
from synth import bass_note

INFO = {
    "mini_boss": dict(key="C# minor", bpm=158, meter=4, bars=32,
                      about="Mini boss: a light orchestral chase, short strings, xylophone and piccolo hook, horn calls over a galloping bass."),
    "boss_depth_1": dict(key="B minor", bpm=172, meter=4, bars=36,
                         about="Depth 1 boss: a punchy chip-lead rock fight on real drums, slap bass, orchestra hits and a stop-time run section."),
    "boss_depth_2": dict(key="F# minor", bpm=152, meter=4, bars=32,
                         about="Depth 2 boss: brass and organ over a sixteenth-note machine riff, clanking metal, a long brass siren."),
}


def _bars(text, count):
    p = prog(text)
    assert len(p) == count, "progression has %d bars, not %d" % (len(p), count)
    return p


# ---------------------------------------------------------------------------------------------
# Mini boss: tense but lighter than any floor boss, a chase. C# minor, 158 bpm. Short strings run
# an ostinato over a galloping bass; a xylophone and piccolo carry the hook, horns call across the
# middle, then a semitone-crawling break and a stop-time turnaround. 32 bars: strings alone (2),
# hook (8), horn calls (8), hook doubled (8), break (4), stops (2).
# ---------------------------------------------------------------------------------------------

MINI_HOOK = ("G#5:.5 C#6 E6 D#6 C#6 G#5 E5:1 | F#5:.5 G#5 E5 C#5 B4:1 C#5 | C#6:.5 E6 A6 G#6 E6:1 C#6 | "
             "D#6:.5 F#6 B6 A6 F#6:1 D#6 | G#5:.5 C#6 E6 D#6 C#6 G#5 E5:1 | E5:.5 F#5 G#5 B5 C#6:2 | "
             "A5:.5 C#6 F#6 E6 C#6:1 A5 | G#5:.5 C6 D#6 F#6 G#6:1 r:1")
MINI_CALLS = ("E4:1.5 A4:.5 C#5:2 | D#5:1.5 C#5:.5 B4:2 | B4:1 D#5 G#5:2 | G#5:1.5 E5:.5 C#5:2 | "
              "C#5:1.5 F#5:.5 A5:2 | G#5:1 F#5 D#5:2 | E5:1 C#5 A4 C#5 | D#5:2 C5:2")
MINI_CRAWL = "G#4:4 | A4:4 | G#4:4 | A4:2 B4:2"
MINI_HOOK_CHORDS = "C#m C#m A B C#m C#m F#m G#7"
MINI_CHORDS = " ".join(["C#m C#m", MINI_HOOK_CHORDS, "A B G#m C#m F#m G#m A G#7", MINI_HOOK_CHORDS, "C#m D C#m D", "A G#7"])
GALLOP = [(b + o, d, 0) for b in range(4) for o, d in ((0, 0.45), (0.5, 0.2), (0.75, 0.2))]


def mini_boss():
    s = Band(158, 32, loudness=-16.5, room=0.45)
    s.part("ostinato", "orch_strings_short", level=0.66, pan=-0.15, reverb=0.3)
    s.part("pizz", "orch_pizz", level=0.6, pan=0.2, reverb=0.3)
    s.part("bass", "fingerbass", level=0.74, reverb=0.08)
    s.part("xylo", "orch_xylophone", level=0.62, pan=0.25, reverb=0.35)
    s.part("piccolo", "orch_piccolo_short", level=0.42, pan=0.3, reverb=0.4)
    s.part("violins", "orch_violin_short", level=0.5, pan=-0.3, reverb=0.35)
    s.part("horns", "orch_horn", level=0.66, pan=-0.1, reverb=0.45)
    s.part("stabs", "orch_trumpet_short", level=0.45, pan=0.15, reverb=0.35)
    s.part("timp", "orch_timpani", level=0.62, reverb=0.4)
    s.kit("standard", level=0.78)
    p = _bars(MINI_CHORDS, 32)
    for bar, parts in enumerate(p):
        intro, hook, calls, hook2, brk, stops = bar < 2, 2 <= bar < 10, 10 <= bar < 18, 18 <= bar < 26, 26 <= bar < 30, bar >= 30
        if stops:
            comp(s, "ostinato", bar, parts, "x..x..x.........", low=52, vel=0.9, spread=0)
            comp(s, "stabs", bar, parts, "x..x..x.........", low=60, vel=0.85, spread=0)
            beat(s, bar, {"kick": "x..x..x.........", "crash": "x..............."}, vel=0.9)
            s.note("timp", 49 if bar == 30 else 44, bar * 4, 1, vel=0.85)
            if bar == 31:
                roll(s, bar, start=2.0, count=8, high=0.95)
            continue
        if brk:
            arp(s, "pizz", bar, parts, step=0.5, low=49, octaves=2, vel=0.7, pan=0.0)
            bassline(s, "bass", bar, parts, [(0, 0.9, 0), (1, 0.9, 0), (2, 0.9, 0), (3, 0.9, 0)], low=25, vel=0.7)
            beat(s, bar, {"tom_lo": "x...x...x...x...", "tom": "..o...o...o...o."}, vel=0.7 + 0.06 * (bar - 26))
            s.note("timp", 49, bar * 4, 1, vel=0.75)
            continue
        arp(s, "ostinato", bar, parts, step=0.5, low=49, octaves=2, vel=0.72, pan=0.0)
        if not intro:
            bassline(s, "bass", bar, parts, GALLOP, low=25, vel=0.78)
        if intro:
            beat(s, bar, {"hat": "x.o.x.o.x.o.x.o."}, vel=0.6)
            if bar == 1:
                roll(s, bar, start=2.0, count=8)
        elif calls:
            beat(s, bar, {"kick": "x...x...x...x...", "tom_lo": "..x...x...x..xx.", "snare": "....x.......x..."}, vel=0.8)
            comp(s, "stabs", bar, parts, "..x...x...x...x.", low=60, vel=0.55, spread=0)
        else:
            beat(s, bar, {"kick": "x.....x...x.....", "snare": "....x.......x...", "hat": "x.o.x.o.x.o.x.o."}, vel=0.8)
        if bar in (2, 10, 18):
            s.hit("crash", bar * 4, vel=0.75)
            s.note("timp", 49, bar * 4, 1, vel=0.8)
        if bar in (9, 17, 25):
            roll(s, bar, start=3.0, count=4)
    melody(s, "xylo", 2, MINI_HOOK, bars=8, vel=0.82)
    melody(s, "piccolo", 2, MINI_HOOK, bars=8, vel=0.6)
    melody(s, "horns", 10, MINI_CALLS, bars=8, vel=0.82)
    melody(s, "xylo", 18, MINI_HOOK, bars=8, vel=0.85)
    melody(s, "violins", 18, MINI_HOOK, bars=8, vel=0.7, transpose=-12)
    melody(s, "horns", 26, MINI_CRAWL, bars=4, vel=0.6)
    # The last stop runs up into the top of the loop.
    melody(s, "violins", 31, "r:2 G#4:.25 A4 B4 C5 C#5 D#5 E5 F#5", bars=1, vel=0.85)
    melody(s, "xylo", 31, "r:2 G#5:.25 A5 B5 C6 C#6 D#6 E6 F#6", bars=1, vel=0.75)
    s.swell("horns", 26 * 4, 16, low=60, high=127)
    s.cc("horns", 30 * 4, 11, 127)
    return s


# ---------------------------------------------------------------------------------------------
# Depth 1 boss: snappy and punchy, chip-flavoured. B minor, 172 bpm. A square-wave lead carries the
# hook over real drums, an octave-popping slap bass and orchestra hits; a saw lead and overdrive
# chords take the middle, then a stop-time section where the band hits and the square runs fill
# the gaps. 36 bars: build (4), hook (8), saw lead (8), stop-time (8), hook up an octave (8).
# ---------------------------------------------------------------------------------------------

B1_HOOK = ("B4:.5 B4 D5 F#5 E5:.25 F#5 E5:.5 D5 C#5 | B4:1 F#4:.5 A4 B4:2 | G5:.5 F#5 E5 D5 B4 D5 G5:1 | "
           "A5:.5 G5 F#5 E5 C#5:1 A4 | B4:.5 B4 D5 F#5 E5:.25 F#5 E5:.5 D5 C#5 | D5:.5 C#5 B4 D5 F#5:1 B5 | "
           "G5:.5 F#5 E5 G5 B5 A5 G5 E5 | F#5:.5 E5 C#5 A#4 F#4:2")
B1_SAW = ("D5:1.5 B4:.5 G4:1 B4 | C#5:1.5 E5:.5 A5:2 | A5:1 F#5:.5 C#5:1.5 E5:1 | D5:3 r:1 | "
          "B5:1.5 A5:.5 G5:1 D5 | E5:1.5 F#5:.5 G5:1 A5 | B5:1 G5:.5 E5:1.5 G5:1 | A#5:2 F#5:2")
B1_ANSWERS = "r:4 | r:4 | r:4 | r:3 F#5:.25 E5 D5 C#5 | r:4 | r:4 | r:4 | r:3 C#6:.25 A#5 F#5 C#5"
B1_RUNS = ("r:1 B4:.25 C#5 D5 F#5 r:1 D5:.25 F#5 A5 B5 | r:1 G4:.25 B4 D5 G5 r:1 F#5:.25 E5 D5 B4 | "
           "r:1 B4:.25 C#5 D5 F#5 r:1 D5:.25 F#5 A5 B5 | r:1 D5:.25 G5 B5 D6 r:1 C#6:.25 B5 A5 G5 | "
           "r:1 E5:.25 G5 B5 E6 r:1 D6:.25 B5 G5 E5 | r:1 F#5:.25 A#5 C#6 F#6 r:1 E6:.25 C#6 A#5 F#5 | "
           "r:1 G5:.25 B5 E6 G6 r:1 F#6:.25 E6 D6 B5 | F#6:1 E6 C#6 A#5")
B1_HOOK_CHORDS = "Bm Bm G A Bm Bm Em F#7"
B1_CHORDS = " ".join(["Bm Bm G A", B1_HOOK_CHORDS, "G A F#m Bm G A Em F#", "Bm G Bm G Em F# Em F#7", B1_HOOK_CHORDS])
POP = [(e * 0.5, 0.4, s) for e, s in enumerate([0, 0, 12, 0, 7, 0, 12, 7])]


def boss_depth_1():
    s = Band(172, 36, loudness=-16.5, room=0.4)
    s.part("square", "squarelead", level=0.5, pan=0.1, reverb=0.25)
    s.part("saw", "sawlead", level=0.46, pan=-0.1, reverb=0.3)
    s.part("arp", "squarelead", level=0.3, pan=0.3, reverb=0.3)
    s.part("bass", "slap", level=0.76, reverb=0.05)
    s.part("gtr", "overdrive", level=0.5, pan=-0.3, reverb=0.2)
    s.part("hit", "orchhit", level=0.55, reverb=0.4)
    s.part("strings", "orch_strings_short", level=0.5, pan=0.25, reverb=0.35)
    s.kit("power", level=0.8)
    p = _bars(B1_CHORDS, 36)
    for bar, parts in enumerate(p):
        intro, hook, saw, stop, hook2 = bar < 4, 4 <= bar < 12, 12 <= bar < 20, 20 <= bar < 28, bar >= 28
        if stop:
            comp(s, "hit", bar, parts, "x.....x.........", low=54, vel=0.9, spread=0)
            comp(s, "gtr", bar, parts, "x-....x-........", low=47, vel=0.85, spread=0, drop=2)
            comp(s, "strings", bar, parts, "x.....x.........", low=54, vel=0.85, spread=0)
            bassline(s, "bass", bar, parts, [(0, 0.4, 0), (1.5, 0.4, 0)], low=35, vel=0.9)
            beat(s, bar, {"kick": "x.....x.........", "crash": "x.....x.........", "snare": "x.....x........."}, vel=0.9)
            if bar == 27:
                roll(s, bar, start=2.0, count=8, high=0.95)
            continue
        bassline(s, "bass", bar, parts, POP, low=35, vel=0.82 if not intro else 0.7)
        if intro:
            arp(s, "arp", bar, parts, step=0.25, low=59 + 2 * bar, octaves=2, vel=0.55, pan=0.0)
            comp(s, "hit", bar, parts, "x...............", low=54, vel=0.85, spread=0)
            beat(s, bar, {"kick": "x...x...x...x...", "hat": "x.x.x.x.x.x.x.x." if bar >= 2 else "x...x...x...x..."}, vel=0.75)
            if bar == 3:
                roll(s, bar, start=2.0, count=8)
            continue
        beat(s, bar, {"kick": "x.....x.x.....x.", "snare": "....x.......x...", "hat": "x.o.x.o.x.o.x.o."}, vel=0.82)
        if saw:
            comp(s, "gtr", bar, parts, "x-.x-.x-x-.x-.x.", low=47, vel=0.7, spread=0, drop=2)
            arp(s, "arp", bar, parts, step=0.5, low=66, octaves=1, vel=0.42, pan=0.0)
        else:
            comp(s, "strings", bar, parts, "..x...x...x...x.", low=59, vel=0.55, spread=0)
        if hook2:
            comp(s, "gtr", bar, parts, "x-.x-.x-x-.x-.x.", low=47, vel=0.62, spread=0, drop=2)
            if bar % 2 == 0:
                comp(s, "hit", bar, parts, "x...............", low=54, vel=0.8, spread=0)
        if bar in (4, 12, 28):
            s.hit("crash", bar * 4, vel=0.8)
            comp(s, "hit", bar, parts, "x...............", low=54, vel=0.9, spread=0)
        if bar in (11, 19, 35):
            roll(s, bar, start=3.0, count=4)
    melody(s, "square", 4, B1_HOOK, bars=8, vel=0.85)
    melody(s, "saw", 12, B1_SAW, bars=8, vel=0.85)
    melody(s, "square", 12, B1_ANSWERS, bars=8, vel=0.8)
    melody(s, "square", 20, B1_RUNS, bars=8, vel=0.85)
    melody(s, "square", 28, B1_HOOK, bars=8, vel=0.88, transpose=12)
    melody(s, "saw", 28, B1_HOOK, bars=8, vel=0.65)
    return s


# ---------------------------------------------------------------------------------------------
# Depth 2 boss: brass and organ over a machine. F# minor, 152 bpm. A sixteenth-note synth-bass riff
# grinds like a press, with clanking metal on the off-beats; a rock organ plays the hook, then the
# trombones and horns sound a long siren over sustained organ, a menacing half-step breakdown with
# timpani, and the hook again under long brass. 32 bars: machine alone (4), organ hook (8), brass
# siren (8), breakdown (4), hook with brass (8).
# ---------------------------------------------------------------------------------------------

B2_HOOK = ("F#5:.5 C#5 F#5 A5 G#5:.25 A5 G#5:.5 F#5:1 | E5:.5 F#5 C#5:1 A4:.5 B4 C#5:1 | D5:.5 F#5 A5 D6 C#6 A5 F#5:1 | "
           "E5:.5 G#5 B5 E6 D6:1 B5 | F#5:.5 C#5 F#5 A5 G#5:.25 A5 G#5:.5 F#5:1 | A5:.5 G#5 F#5 E5 F#5:2 | "
           "D6:.5 C#6 B5 F#5 D5:1 B4 | G#4:.5 C#5 F5 G#5 B5:1 G#5")
B2_SIREN = "A4:4 | B4:2 G#4:2 | C#5:4 | A4:2 C#5:2 | D5:4 | E5:2 B4:2 | F#5:2 D5:2 | F5:4"
B2_COUNTER = "F#4:4 | E4:4 | F#4:4 | G#4:4 | A4:4 | C#5:4 | B4:4 | G#4:4"
B2_HOOK_CHORDS = "F#m F#m D E F#m F#m Bm C#7"
B2_CHORDS = " ".join(["F#m F#m F#m C#7", B2_HOOK_CHORDS, "D E C#m F#m D E Bm C#", "F#m G F#m G", B2_HOOK_CHORDS])
MACHINE = [0, 0, 12, 0, 0, 0, 10, 0, 0, 0, 7, 0, 5, 0, 3, 0]
MACHINE_ACCENT = "x..x..x.x..x..x."


def _machine(s, bar, parts, low=30, half=False):
    """The press: a sixteenth-note riff off each chord's root, accented in threes."""
    step = 0.5 if half else 0.25
    for e in range(int(4 / step)):
        k = e * (2 if half else 1)
        sym = parts[0][2] if len(parts) == 1 else [p[2] for p in parts if p[0] <= k * 0.25 + 1e-6][-1]
        semis = MACHINE[k % 16]
        qual = sym[2:] if len(sym) > 1 and sym[1] in "#b" else sym[1:]
        if semis == 3 and (not qual.startswith("m") or qual.startswith("maj")):
            semis = 4
        accent = MACHINE_ACCENT[k % 16] == "x"
        s.note("machine", bass_note(sym, low) + semis, bar * 4 + e * step, step * 0.8, vel=0.9 if accent else 0.62)


def boss_depth_2():
    s = Band(152, 32, loudness=-16.5, room=0.55)
    s.part("machine", "synthbass2", level=0.72, reverb=0.08)
    s.part("organ", "rockorgan", level=0.6, pan=0.15, reverb=0.35)
    s.part("organarp", "percorgan", level=0.32, pan=-0.2, reverb=0.35)
    s.part("trombones", "orch_trombone", level=0.7, pan=-0.15, reverb=0.45)
    s.part("horns", "orch_horn", level=0.62, pan=0.2, reverb=0.5)
    s.part("stabs", "orch_trombone_short", level=0.6, reverb=0.4)
    s.part("timp", "orch_timpani", level=0.68, reverb=0.45)
    s.kit("room", level=0.8)
    p = _bars(B2_CHORDS, 32)
    for bar, parts in enumerate(p):
        intro, hook, siren, brk, hook2 = bar < 4, 4 <= bar < 12, 12 <= bar < 20, 20 <= bar < 24, bar >= 24
        _machine(s, bar, parts, half=brk)
        # The works clank on the off-beats; an anvil marks every other bar.
        beat(s, bar, {"cowbell": "..o...o...o...o.", "triangle_mute": "g.g.g.g.g.g.g.g."}, vel=0.6 if brk else 0.75)
        if bar % 2 == 0:
            s.hit("timbale_hi", bar * 4, vel=0.8)
        if intro:
            if bar >= 2:
                beat(s, bar, {"kick": "x...x...x...x..."}, vel=0.8)
            if bar == 3:
                roll(s, bar, start=2.0, count=8)
            continue
        if brk:
            for b in (0, 2):
                s.note("timp", 42 if parts[0][2] == "F#m" else 43, bar * 4 + b, 1, vel=0.85)
            comp(s, "stabs", bar, parts, "x..x..x.........", low=46, vel=0.85, spread=0)
            beat(s, bar, {"tom_lo": "x..x..x.........", "tom_floor": "........x.x.x.x." if bar == 23 else "........x...x..."}, vel=0.8)
            if bar == 23:
                roll(s, bar, start=2.0, count=8, high=0.95)
            continue
        beat(s, bar, {"kick": "x..x..x.x..x....", "snare": "....x.......x...", "hat": "x.o.x.o.x.o.x.o."}, vel=0.82)
        if siren:
            comp(s, "organ", bar, parts, "x-------x-------", low=54, vel=0.6, spread=0)
            arp(s, "organarp", bar, parts, step=0.25, low=66, octaves=2, vel=0.45, pan=0.0)
            beat(s, bar, {"ride": "x.o.x.o.x.o.x.o."}, vel=0.5)
        else:
            comp(s, "stabs", bar, parts, "x.......x.......", low=50, vel=0.6, spread=0)
        if bar in (4, 12, 24):
            s.hit("crash", bar * 4, vel=0.8)
            s.note("timp", 42, bar * 4, 1, vel=0.85)
        if bar in (11, 19, 31):
            roll(s, bar, start=3.0, count=4)
    melody(s, "organ", 4, B2_HOOK, bars=8, vel=0.85)
    melody(s, "trombones", 12, B2_SIREN, bars=8, vel=0.85)
    melody(s, "horns", 12, B2_SIREN, bars=8, vel=0.75, transpose=12)
    melody(s, "organ", 24, B2_HOOK, bars=8, vel=0.88)
    melody(s, "horns", 24, B2_COUNTER, bars=8, vel=0.72)
    melody(s, "trombones", 24, B2_COUNTER, bars=8, vel=0.62, transpose=-12)
    return s
