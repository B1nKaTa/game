"""The later paths, each its own piece for real instruments: the Last Resort Cruise, the Psychic
Hotline, Terminal Zero and Head Office. Each keeps its first concept and joke, with new tunes."""
import synth
from band import Band, beat, roll
from kit import mel, melody, prog, comp, bassline, arp
import jb_theme  # noqa: F401  (registers the extra chord qualities: 7sus4, mmaj7 and so on)

INFO = {
    "last_resort_cruise": dict(key="Eb major", bpm=116, meter=4, bars=32,
                               about="Last Resort Cruise: the lounge band's cha-cha, muted trumpet, vibes, piano montuno, the ship's horn."),
    "seance_hotline": dict(key="F# minor (B in A)", bpm=76, meter=4, bars=30,
                           about="Psychic Hotline: a gliding theremin over triplet strings, tremolo guitar, lava-lamp bloops, the phone."),
    "terminal_zero": dict(key="Db major", bpm=104, meter=4, bars=30,
                          about="Terminal Zero: airport-lounge synth, PA chimes and the departures board clacking."),
    "head_office": dict(key="G major / G minor", bpm=108, meter=4, bars=28, quiet=[(24, 26)],
                        about="Head Office: bland corporate muzak that turns sinister, choir and organ, a ticking clock, then a cheery snap back."),
}


def _comp(s, inst, bar, parts, rhythm, **kw):
    """Chords in one place: each part keeps its own pan, so it stays on one MIDI channel."""
    comp(s, inst, bar, parts, rhythm, spread=0.0, **kw)


def _bars(text, count):
    p = prog(text)
    assert len(p) == count, "progression has %d bars, not %d" % (len(p), count)
    return p


# ---------------------------------------------------------------------------------------------
# The Last Resort Cruise: the lounge band on the sun deck. A cha-cha in Eb, 116 bpm. The ship's horn
# and the sea open it; a muted trumpet fronts the band, the vibes and a flute take the second tune,
# then the pianist's montuno with a nylon guitar solo and string stabs, the trumpet and flute
# together, and the horn again as it loops. 32 bars: horn (2), A (8), B (8), C (8), A short (4), tag (2).
# ---------------------------------------------------------------------------------------------

CRUISE_A = ("G5:1 Bb5:.5 D6:1.5 C6:.5 Bb5 | G5:1.5 Eb5:.5 C5:1 r:.5 D5 | Eb5:.5 F5 Ab5 C6 Bb5:1 Ab5 | G5:1 F5 D5:.5 Eb5 F5:1 | "
            "Bb5:1 G5:.5 D5:1.5 F5:.5 G5 | E5:1.5 G5:.5 Bb5:1 C6 | Ab5:.5 G5 F5 Eb5 D5:1 Bb4 | Eb5:2 r:1 Bb4:.5 C5")
CRUISE_B = ("C6:.5 Bb5 Ab5 G5 Eb5:1 C5 | F5:.5 Ab5 B5 Bb5 Ab5:1 F5 | D6:1.5 Bb5:.5 G5:1 F5 | E5:.5 G5 Bb5 C6 Db6:1 C6 | "
            "Ab5:1 C6:.5 Eb6:1.5 C6:.5 Ab5 | D6:1 Bb5:.5 F5 Ab5:2 | G5:.5 Bb5 D6 Bb5 E5:1 G5 | F5:1.5 Ab5:.5 D5:1 Bb4")
CRUISE_B_FLUTE = "Eb5:2 C5 | Ab4:2 F4 | Bb4:2 D5 | E5:2 G5 | C5:2 Eb5 | D5:2 F5 | Bb4:2 E5 | Ab4:2 D5"
CRUISE_C = ("G4:1 Bb4:.5 Eb5:1.5 D5:.5 C5 | A4:1.5 C5:.5 Eb5:1 F5 | D5:.5 F5 A5 F5 D5:1 Bb4 | G4:2 r:1 Bb4:.5 C5 | "
            "Eb5:1 C5:.5 Ab4:1.5 G4:.5 Ab4 | C5:1 Ab4:.5 F4 Ab4:1 C5 | Bb4:.5 D5 F5 D5 G5:2 | F5:1 D5 Ab4 Bb4")
CRUISE_A_CHORDS = "Ebmaj7 Cm7 Fm7 Bb7 Gm7 C7 Fm7,Bb7 Ebmaj7"
CRUISE_CHORDS = " ".join(["Ebmaj7 Bb7", CRUISE_A_CHORDS, "Abmaj7 Db9 Gm7 C7 Fm7 Bb7 Gm7,C7 Fm7,Bb7",
                          "Cm7 F7 Bbmaj7 Ebmaj7 Abmaj7 Fm7 Gm7 Bb7", "Ebmaj7 Cm7 Fm7 Bb7", "Ebmaj7 Bb7"])
CHA_BASS = [(0, 1.0, 0), (1.5, 0.5, 7), (2, 1.0, 12), (3, 0.5, 7), (3.5, 0.5, 5)]
CHA_PERC = {"cowbell": "x...o...x...o...", "guiro": "x.oox.oox.oox.oo", "conga": "....o.x.....o.xx",
            "claves": "x..x...x..x.x...", "kick": "x.......x......."}


def last_resort_cruise():
    s = Band(116, 32, loudness=-18.0, room=0.5)
    s.part("trumpet", "orch_trumpet_mute", level=0.7, pan=-0.1, reverb=0.35)
    s.part("vibes", "vibes", level=0.6, pan=0.2, reverb=0.4)
    s.part("flute", "orch_flute", level=0.55, pan=0.25, reverb=0.4)
    s.part("piano", "piano", level=0.5, pan=0.3, reverb=0.3)
    s.part("gtr", "nylon", level=0.6, pan=-0.3, reverb=0.3)
    s.part("bass", "fingerbass", level=0.72, reverb=0.1)
    s.part("stabs", "orch_strings_short", level=0.5, reverb=0.4)
    s.part("horn", "tuba", level=0.7, reverb=0.7)
    s.part("sea", "seashore", level=0.35, reverb=0.3)
    s.part("gulls", "bird", level=0.2, pan=0.5, reverb=0.6)
    s.kit("standard", level=0.7)
    p = _bars(CRUISE_CHORDS, 32)
    for bar, parts in enumerate(p):
        horn, a1, b, c, a2, tag = bar < 2, 2 <= bar < 10, 10 <= bar < 18, 18 <= bar < 26, 26 <= bar < 30, bar >= 30
        if bar >= 1:  # the band joins under the horn's toots, a bar before the trumpet
            bassline(s, "bass", bar, parts, CHA_BASS, low=31, vel=0.8)
            beat(s, bar, CHA_PERC, vel=0.7)
            _comp(s, "gtr", bar, parts, "..x-..x-..x-x.x." if not c else "..x...x...x.....", low=55, vel=0.5)
        if bar == 1 or a1 or a2:
            _comp(s, "piano", bar, parts, "x.....x.x.......", low=58, vel=0.42)
        if b:
            _comp(s, "piano", bar, parts, "x-......x-......", low=60, vel=0.35)
            beat(s, bar, {"shaker": "x.o.x.o.x.o.x.o."}, vel=0.5)
        if c:
            # The pianist's montuno, with string stabs answering.
            _comp(s, "piano", bar, parts, "x.x..x.x..x.x.x.", low=60, vel=0.5)
            _comp(s, "stabs", bar, parts, "......x.......x.", low=62, vel=0.55)
            beat(s, bar, {"timbale": "............o.oo"}, vel=0.6)
        if bar in (9, 17, 25):
            roll(s, bar, start=3.0, count=4, kind="timbale")
    # The ship's horn: a long blast to open, two toots before the band, a blast as it loops.
    for m in ("Eb2", "Bb1"):
        s.note("horn", m, 0, 2.2, vel=0.85)
        s.note("horn", m, 30 * 4 + 2, 5.5, vel=0.85)
    for t in (2.5, 3.25):
        s.note("horn", "Eb2", t, 0.5, vel=0.75)
    s.note("sea", "C4", 0, 7.5, vel=0.6)
    s.note("sea", "C4", 30 * 4, 7.5, vel=0.55)
    for t, n in ((1.0, "G6"), (1.3, "E6"), (5.5, "A6"), (121.0, "G6"), (121.4, "D6")):
        s.note("gulls", n, t, 0.25, vel=0.5)
    melody(s, "trumpet", 2, CRUISE_A, bars=8, vel=0.82)
    melody(s, "vibes", 10, CRUISE_B, bars=8, vel=0.75)
    melody(s, "flute", 10, CRUISE_B_FLUTE, bars=8, vel=0.55)
    melody(s, "gtr", 18, CRUISE_C, bars=8, vel=0.78, transpose=12)
    a_half = CRUISE_A.split(" | ")[:4]
    melody(s, "trumpet", 26, " | ".join(a_half), bars=4, vel=0.85)
    melody(s, "flute", 26, " | ".join(a_half), bars=4, vel=0.6, transpose=12)
    melody(s, "vibes", 30, "Eb6:.5 Bb5 G5 Eb5 D5:2 | r:4", bars=2, vel=0.6)
    s.hit("crash", 2 * 4, vel=0.5)
    return s


# ---------------------------------------------------------------------------------------------
# Beyond Calling Psychic Hotline, Night Shift: a theremin glides over strings pulsing in triplets
# and a minor line creeping down inside the chords. F# minor, 76 bpm. The phone rings to open; in the
# middle, in A, a guitar tremolo-picks while the lava lamps bloop; then a reading by candlelight,
# harp and oboe over plucked cellos; then the theremin again. A crystal ball shimmers at each section.
# 30 bars: the call (2), A (8), B in A (8), the reading (8), A short (4).
# ---------------------------------------------------------------------------------------------

SEANCE_A = ("C#5:2 F#5:1.5 G#5:.5 | A5:2.5 G#5:.5 F5:1 | E5:3 C#5:1 | D#5:2 F#5:1 A5 | "
            "C#6:3 A5:1 | D6:1.5 C#6:.5 B5:1 F#5 | D5:1 B4 F5 G#5 | C#6:2 B5:1 G#5")
SEANCE_B = ("E5:1 A5 C#6:2 | D6:1.5 C#6:.5 A5:2 | G#5:1 E5 B4:2 | C#5:1 D5 F#5:2 | "
            "A5:2 F#5:1 D5 | G#5:1.5 B5:.5 D6:2 | C#6:3 E5:1 | F5:2 G#5:2")
SEANCE_READING = ("F#5:1.5 E5:.5 D5:1 C#5 | B4:1 G#4 F4:2 | F#4:.5 A4 C#5 F#5 E5:2 | D5:3 r:1 | "
                  "B4:.5 D5 F#5 A5 B5:2 | G#5:1.5 F5:.5 C#5:2 | A5:1 F#5 D5 C#5 | B4:1 G#4 F4:2")
SEANCE_A_CHORDS = "F#m F#mmaj7 F#m7 F#m6 Dmaj7 Bm7 G#m7b5,C#7 C#7"
SEANCE_CHORDS = " ".join(["F#m C#7", SEANCE_A_CHORDS, "Amaj7 Bm7 C#m7 Dmaj7 Bm7 E7 Amaj7 C#7",
                          "Bm7 C#7 F#m Dmaj7 Bm7 C#7 Dmaj7 C#7", "F#m F#mmaj7 F#m7 F#m6"])


def _glide(s, part, bar, text, vel=0.75):
    """A theremin line: a wide leap slides in through two quick notes, as a hand moving off the antenna."""
    notes, _ = mel(text, s.meter)
    t = bar * s.meter; prev = None
    for name, d in notes:
        if name == "r":
            prev = None; t += d
            continue
        m = synth.midi(name)
        if prev is not None and abs(m - prev) >= 3:
            gap = m - prev; step = 1 if gap > 0 else -1
            s.note(part, prev + step * max(1, abs(gap) // 3), t, 0.08, vel=vel * 0.55, legato=1.0)
            s.note(part, prev + step * max(2, 2 * abs(gap) // 3), t + 0.08, 0.08, vel=vel * 0.65, legato=1.0)
            s.note(part, m, t + 0.16, d - 0.16, vel=vel)
        else:
            s.note(part, m, t, d, vel=vel)
        prev = m; t += d


def _shimmer(s, beat_at, low="F#5"):
    """The crystal ball: a quick harp run up and a high bell."""
    base = synth.midi(low)
    for k, iv in enumerate((0, 3, 7, 10, 12, 15, 19, 22)):
        s.note("harp", base + iv, beat_at + k * 0.125, 1.0, vel=0.5 + 0.04 * k)
    s.note("bell", base + 24, beat_at + 1.0, 2.0, vel=0.4)


def seance_hotline():
    s = Band(76, 30, loudness=-19.0, room=0.75)
    s.part("theremin", "voicelead", level=0.6, pan=0.05, reverb=0.65)
    s.part("pulse", "orch_strings_short", level=0.48, reverb=0.55)
    s.part("pad", "slowstrings", level=0.32, reverb=0.7)
    s.part("gtr", "cleangtr", level=0.45, pan=-0.3, reverb=0.6)
    s.part("lamps", "kalimba", level=0.45, pan=0.35, reverb=0.8)
    s.part("harp", "orch_harp", level=0.55, pan=0.3, reverb=0.6)
    s.part("bell", "orch_glock", level=0.35, pan=-0.2, reverb=0.8)
    s.part("oboe", "orch_oboe", level=0.6, pan=-0.1, reverb=0.5)
    s.part("cellos", "orch_pizz", level=0.6, reverb=0.4)
    s.part("bass", "fretless", level=0.55, reverb=0.3)
    s.part("phone", "phone", level=0.45, pan=0.4, reverb=0.4)
    s.kit("room", level=0.6)
    s.cc("theremin", 0, 1, 70)
    p = _bars(SEANCE_CHORDS, 30)
    for bar, parts in enumerate(p):
        call, a1, b, reading, a2 = bar < 2, 2 <= bar < 10, 10 <= bar < 18, 18 <= bar < 26, bar >= 26
        if call or a1 or a2:
            _comp(s, "pulse", bar, parts, "xooxooxooxoo", low=54, vel=0.42)
            _comp(s, "pad", bar, parts, "x---------------", low=48, vel=0.45)
        if not call and not reading:
            bassline(s, "bass", bar, parts, [(0, 1.9, 0), (2, 1.9, 0)], low=30, vel=0.6)
            beat(s, bar, {"kick": "x.......x.......", "rim": "........o.......", "shaker": "..g...g...g...g."}, vel=0.6)
        if b:
            _comp(s, "gtr", bar, parts, "oooooooooooooooo", low=57, vel=0.32, drop=3)
            _comp(s, "pad", bar, parts, "x---------------", low=52, vel=0.4)
            if bar % 2 == 1:
                notes, _ = synth.chord(parts[0][2], 62)
                for k, m in enumerate(reversed(notes)):
                    s.note("lamps", m + 12, bar * 4 + 1.5 + k * 0.33, 0.5, vel=0.45)
        if reading:
            arp(s, "harp", bar, parts, step=0.5, low=57, octaves=2, vel=0.42, pan=0.0)
            bassline(s, "cellos", bar, parts, [(0, 0.9, 0), (1, 0.9, 7), (2, 0.9, 12), (3, 0.9, 7)], low=36, vel=0.6)
            _comp(s, "pad", bar, parts, "x---------------", low=50, vel=0.35)
        if bar in (9, 17):
            roll(s, bar, start=3.0, count=4, kind="tom_lo", low=0.25, high=0.6)
    for bar in (2, 10, 18, 26):
        _shimmer(s, bar * 4)
    # The phone: two rings at the top, one in the gap before the reading, one as it loops.
    for t in (0.0, 4.0, 17 * 4 + 2, 29 * 4 + 1):
        s.note("phone", "C5", t, 1.6, vel=0.7)
    _glide(s, "theremin", 2, SEANCE_A, vel=0.78)
    _glide(s, "theremin", 10, SEANCE_B, vel=0.72)
    melody(s, "oboe", 18, SEANCE_READING, bars=8, vel=0.65)
    _glide(s, "theremin", 26, " | ".join(SEANCE_A.split(" | ")[:4]), vel=0.8)
    return s


# ---------------------------------------------------------------------------------------------
# Departures, Terminal Zero: airport-lounge synth in Db, 104 bpm. The public-address chime opens it
# and the departures board clatters over; a bell-toned electric piano carries the first tune over a
# sequencer and a gentle beat, a soprano sax the second, then a floating half-time stretch with a
# flute, and a last announcement. 30 bars: chime (2), A (8), B (8), C (8), announcement (4).
# ---------------------------------------------------------------------------------------------

TERM_A = ("F5:1 Ab5:.5 C6:1.5 Bb5:.5 Ab5 | Gb5:1.5 Eb5:.5 Bb4:2 | Ab5:1 C6:.5 Eb6:1.5 Db6:.5 C6 | Bb5:3 r:1 | "
          "Db6:1 Bb5:.5 F5:1.5 Ab5:1 | Gb5:1 Bb5:.5 Db6:1.5 Eb6:1 | F6:1.5 Db6:.5 Bb5:1 Gb5 | Ab5:2 Eb5:1 Gb5")
TERM_B = ("F5:1.5 Db5:.5 Bb4:1 Ab4 | Bb4:1 Db5:.5 F5:2.5 | Eb5:.5 F5 Ab5 C6 Ab5:2 | Gb5:1.5 Eb5:.5 C5:2 | "
          "Db5:1 F5 Ab5 Bb5 | Bb5:1.5 Ab5:.5 F5:1 Db5 | Gb5:1 Eb5 Bb4 Db5 | C5:2 Eb5:1 r:1")
TERM_C = "Bb5:3 Ab5:1 | Ab5:2 F5 | Gb5:3 Eb5:1 | F5:4 | Db6:3 Bb5:1 | C6:2 Ab5 | Bb5:2 Gb5 | Ab5:2 Eb5"
TERM_CHORDS = " ".join(["Dbmaj7 Ab7sus4", "Dbmaj7 Ebm7 Fm7 Gbmaj7 Bbm7 Ebm7 Gbmaj7 Ab7sus4",
                        "Bbm7 Gbmaj7 Dbmaj7 Ab7 Bbm7 Gbmaj7 Ebm7 Ab7", "Gbmaj7 Fm7 Ebm7 Dbmaj7 Gbmaj7 Fm7 Ebm7 Ab7sus4",
                        "Dbmaj7 Gbmaj7 Dbmaj7 Ab7sus4"])


def _chime(s, beat_at, up=False):
    """The PA chime: three tones down (an announcement) or up (its end)."""
    for k, n in enumerate(("Db5", "F5", "Ab5") if up else ("Ab5", "F5", "Db5")):
        s.note("chime", n, beat_at + k * 0.75, 1.6, vel=0.6)


def _board(s, beat_at, flips=12):
    """The departures board: a clatter of flaps settling."""
    for k in range(flips):
        s.hit("click" if k % 3 else "sticks", beat_at + k * 0.125, vel=0.35 + 0.25 * (1 - k / flips))


def terminal_zero():
    s = Band(104, 30, loudness=-18.0, room=0.65)
    s.part("keys", "epiano2", level=0.58, pan=0.1, reverb=0.45, chorus=0.3)
    s.part("sax", "sopranosax", level=0.55, pan=-0.1, reverb=0.45)
    s.part("flute", "flute", level=0.5, pan=0.15, reverb=0.6)
    s.part("seq", "polysynth", level=0.35, pan=0.2, reverb=0.4)
    s.part("pad", "halopad", level=0.38, reverb=0.7)
    s.part("strings", "slowstrings", level=0.3, reverb=0.6)
    s.part("bass", "synthbass2", level=0.6, reverb=0.15)
    s.part("chime", "vibes", level=0.55, pan=-0.2, reverb=0.6)
    s.kit("electronic", level=0.6)
    p = _bars(TERM_CHORDS, 30)
    for bar, parts in enumerate(p):
        intro, a, b, c, d = bar < 2, 2 <= bar < 10, 10 <= bar < 18, 18 <= bar < 26, bar >= 26
        _comp(s, "pad", bar, parts, "x---------------", low=53, vel=0.5)
        if a or b:
            arp(s, "seq", bar, parts, step=0.25, low=65, octaves=2, vel=0.4, pan=0.0)
            bassline(s, "bass", bar, parts, [(0, 0.9, 0), (1.5, 0.4, 0), (2, 0.9, 7), (3.5, 0.4, 12)], low=37, vel=0.7)
            beat(s, bar, {"kick": "x.....x...x.....", "rim": "....x.......x...", "hat": "o.o.o.o.o.o.o.o."}, vel=0.62)
        if b:
            beat(s, bar, {"shaker": "gogogogogogogogo"}, vel=0.5)
            _comp(s, "strings", bar, parts, "x---------------", low=58, vel=0.42)
        if c:
            bassline(s, "bass", bar, parts, [(0, 3.8, 0)], low=37, vel=0.55)
            arp(s, "seq", bar, parts, step=0.5, low=68, octaves=1, vel=0.3, pan=0.0)
            beat(s, bar, {"rim": "........o.......", "hat": "..g...g...g...g."}, vel=0.55)
            _comp(s, "strings", bar, parts, "x---------------", low=55, vel=0.38)
        if d:
            beat(s, bar, {"hat": "o.o.o.o.o.o.o.o."}, vel=0.45)
            bassline(s, "bass", bar, parts, [(0, 1.9, 0), (2, 1.9, 7)], low=37, vel=0.55)
        if bar in (9, 17):
            roll(s, bar, start=3.0, count=4, kind="tom_hi", low=0.3, high=0.6)
    _chime(s, 0)
    _board(s, 1 * 4 + 1)
    _chime(s, 26 * 4)
    _board(s, 27 * 4, flips=16)
    _chime(s, 29 * 4 + 1, up=True)
    melody(s, "keys", 2, TERM_A, bars=8, vel=0.75, transpose=-12)
    melody(s, "sax", 10, TERM_B, bars=8, vel=0.78)
    melody(s, "flute", 18, TERM_C, bars=8, vel=0.68)
    melody(s, "keys", 18, "r:4 | r:2 Ab5:.5 F5 Db5 Eb5 | r:4 | r:2 Db6:.5 Ab5 F5 Ab5 | r:4 | r:2 Eb6:.5 C6 Ab5 C6 | r:4 | r:4",
           bars=8, vel=0.45, transpose=-12)
    melody(s, "keys", 26, "r:4 | r:4 | F5:1 Ab5:.5 C6:2.5 | Bb5:1 Ab5 Eb5:2", bars=4, vel=0.7, transpose=-12)
    return s


# ---------------------------------------------------------------------------------------------
# Head Office, Eternity Incorporated: bland, sunny corporate muzak in G, 108 bpm, flute over a soft
# bossa. Then it slides into G minor while a bassoon creeps underneath; then a choir sings slowly over
# pipe organ and tremolo strings, while the vibes go on comping cheerfully as if nothing were wrong;
# then only the office clock ticks, until a cheery chime and the muzak snap back.
# 28 bars: muzak (8), minor (8), choir (8), the clock (2) and the snap back (2).
# ---------------------------------------------------------------------------------------------

OFFICE_A = ("B5:1 D6:.5 B5 A5:1 G5 | E5:2 G5:1 B5 | C6:1 A5:.5 E5 G5:1 A5 | F#5:3 r:1 | "
            "D6:1 B5:.5 F#5 A5:1 B5 | G#5:2 B5:1 D6 | C6:.5 B5 A5 G5 E5:1 C5 | D5:2 r:1 A4:.5 B4")
OFFICE_B = ("Bb5:1 D6:.5 Bb5 A5:1 G5 | Eb5:2 G5:1 Bb5 | C6:1 Eb6:.5 D6 C6:1 Bb5 | F#5:3 r:1 | "
            "D6:1 Bb5:.5 G5 A5:1 Bb5 | C6:2 Eb6:1 Ab5 | G5:.5 F5 Eb5 D5 C5:1 Eb5 | D5:2 r:2")
OFFICE_CREEP = "G2:2 F#2 | Eb3:2 D3 | C3:2 Eb3 | D3:2 C3 | Bb2:2 A2 | Ab2:2 C3 | Eb3:2 G2 | F#2:2 D2"
OFFICE_CHOIR = "G4:4 | Bb4:2 A4 | G4:4 | Eb4:4 | C5:4 | Bb4:2 G4 | A4:4 | F#4:4"
OFFICE_CHORDS = " ".join(["Gmaj7 Em7 Am7 D7 Bm7 E7 Am7 D7", "Gm Eb Cm7 D7 Gm Ab Cm D7",
                          "Gm Gm Eb Eb Cm Cm D7 D7", "Gm Gm Am7 D7"])
BOSSA_BASS = [(0, 1.5, 0), (1.5, 0.5, 7), (2, 1.5, 0), (3.5, 0.5, 7)]


def head_office():
    s = Band(108, 28, loudness=-18.5, room=0.55)
    s.part("flute", "flute", level=0.6, pan=0.1, reverb=0.4)
    s.part("keys", "epiano", level=0.45, pan=-0.2, reverb=0.35)
    s.part("vibes", "vibes", level=0.45, pan=0.3, reverb=0.4)
    s.part("gtr", "nylon", level=0.45, pan=-0.3, reverb=0.3)
    s.part("bass", "fingerbass", level=0.62, reverb=0.1)
    s.part("bassoon", "orch_bassoon", level=0.62, pan=-0.15, reverb=0.4)
    s.part("choir", "choir", level=0.55, reverb=0.7)
    s.part("organ", "churchorgan", level=0.42, reverb=0.7)
    s.part("trem", "tremstrings", level=0.4, reverb=0.6)
    s.part("timp", "orch_timpani_roll", level=0.55, reverb=0.6)
    s.kit("standard", level=0.62)
    p = _bars(OFFICE_CHORDS, 28)
    for bar, parts in enumerate(p):
        a, b, c, clock, snap = bar < 8, 8 <= bar < 16, 16 <= bar < 24, 24 <= bar < 26, bar >= 26
        if a or b or snap:
            bassline(s, "bass", bar, parts, BOSSA_BASS, low=31, vel=0.7)
            _comp(s, "gtr", bar, parts, "x..x..x...x..x..", low=55, vel=0.42)
            beat(s, bar, {"rim": "x..x..x...x..x..", "shaker": "o.g.o.g.o.g.o.g.", "kick": "x.......x......."}, vel=0.55)
        if a or snap:
            _comp(s, "keys", bar, parts, "x-------x-------", low=57, vel=0.38)
        if b or c:
            _comp(s, "vibes", bar, parts, "..x...x...x...x.", low=62, vel=0.42)
        if c:
            _comp(s, "organ", bar, parts, "x---------------", low=50, vel=0.55)
            _comp(s, "trem", bar, parts, "x---------------", low=43, vel=0.45, drop=2)
            beat(s, bar, {"kick": "x...............", "tom_floor": "........o......."}, vel=0.55)
        if clock:
            beat(s, bar, {"tick": "x...x...x...x...", "woodblock": "..o...o...o...o."}, vel=0.6)
        if bar in (7, 15):
            roll(s, bar, start=3.0, count=4, kind="rim", low=0.3, high=0.6)
    for bar in (16, 20):
        s.note("timp", "G2", bar * 4, 3.5, vel=0.55)
    melody(s, "flute", 0, OFFICE_A, bars=8, vel=0.72)
    melody(s, "flute", 8, OFFICE_B, bars=8, vel=0.7)
    melody(s, "bassoon", 8, OFFICE_CREEP, bars=8, vel=0.68)
    melody(s, "choir", 16, OFFICE_CHOIR, bars=8, vel=0.7)
    # The cheery chime, and the muzak picks itself up as if nothing happened.
    for k, n in enumerate(("G5", "B5", "D6")):
        s.note("vibes", n, 26 * 4 + k * 0.5, 1.5, vel=0.65)
    melody(s, "flute", 26, "r:2 E5:.5 F#5 G5 A5 | B5:1 A5:.5 G5 F#5:1 D5", bars=2, vel=0.72)
    return s
