"""Harold's Jukebox, depth 3: the 1970s, Harold in his thirties. The Funeral Parlour's grand prog
rock, the Flashback Cinema's funky film-score groove, and Mortimer's prog and hard-rock fight."""
from synth import bass_note
from band import Band, beat, roll
from kit import melody, prog, comp, bassline, arp, at
from jb_theme import THEME_A, THEME_A1, THEME_A2, THEME_B, THEME_B_CHORDS, MOTIF, minor

INFO = {
    "funeral_parlour": dict(key="F minor", bpm=96, meter=4, bars=32,
                            about="Funeral Parlour: grand 70s prog rock, church organ, a synth lead, mellotron choir, the hold theme in minor and Harold whistling at the wake."),
    "flashback_cinema": dict(key="D minor (B in F)", bpm=104, meter=4, bars=32,
                             about="Flashback Cinema: a funky 70s film-score groove, 16th guitar chops, slap bass, lush strings, the hold theme on a cool flute."),
    "final_arrangements": dict(key="F minor", bpm=160, meter=4, bars=32,
                               about="Depth 3 boss (Mortimer): prog and hard-rock fight, distortion guitar duelling a Hammond, timpani and choir, the hold theme in minor as the riff."),
}


def _bars(text, count):
    p = prog(text)
    assert len(p) == count, "progression has %d bars, not %d" % (len(p), count)
    return p


def _power(s, inst, bar, parts, rhythm, low=40, vel=0.7):
    """Power chords (root, fifth, octave) on a 16-step grid; '-' holds."""
    step = s.meter / len(rhythm)
    for i, c in enumerate(rhythm):
        if c not in "xo":
            continue
        k = i + 1
        while k < len(rhythm) and rhythm[k] == "-":
            k += 1
        sym = at(parts, i * step)
        root = bass_note(sym, low)
        fifth = 6 if sym.endswith("dim") or sym.endswith("m7b5") else 7
        v = vel * (1.0 if c == "x" else 0.7)
        for m in (root, root + fifth, root + 12):
            s.note(inst, m, bar * s.meter + i * step, (k - i) * step, vel=v)


def _timp_roll(s, inst, bar, note, start=2.0, beats=2.0, low=0.3, high=0.85):
    n = int(beats / 0.125)
    for q in range(n):
        s.note(inst, note, bar * s.meter + start + q * 0.125, 0.12, vel=low + (high - low) * q / max(1, n - 1))


# ---------------------------------------------------------------------------------------------
# Eternal Rest: the Funeral Parlour. Grand 70s prog rock, a little tongue-in-cheek. F minor, 96 bpm.
# A church organ opens alone over timpani; the band comes in on a 3+3+2 riff under a synth lead; the
# organ takes the hold theme in minor with a mellotron choir behind it; then an odd-accented break
# where Harold whistles the motif at the wake; a grand turnaround back to the organ.
# 32 bars: organ (4), synth lead (8), organ theme (8), whistle break (8), turnaround (4).
# ---------------------------------------------------------------------------------------------

PARLOUR_LEAD = ("F4:1 Ab4:.5 C5 F5:1.5 Eb5:.5 | Db5:.5 C5 Ab4:1 G4:.5 Ab4 C5:1 | Db5:1.5 F5:.5 Ab5:1 G5:.5 F5 | "
                "G5:2 Eb5:1 Bb4 | Bb4:.5 Db5 F5 Bb5:1.5 Ab5:.5 F5 | Ab5:1 G5:.5 F5 C5:2 | "
                "Db5:.5 Eb5 F5 Gb5 Bb5:1 Ab5 | G5:.5 E5 C5 Bb4 G4:1 E4")
PARLOUR_INTRO = "Fm Db Bbm C7"
PARLOUR_A = "Fm Fm Db Eb Bbm Fm Gb C7"
PARLOUR_B = "Fm Dbmaj7 Gm7b5 Cm Fm Dbmaj7 Gm7b5 C7"
PARLOUR_C = "Fm Fm Db Db Bbm Bbm C7 C7"
PARLOUR_D = "Db Eb C7sus4 C7"
PARLOUR_CHORDS = " ".join([PARLOUR_INTRO, PARLOUR_A, PARLOUR_B, PARLOUR_C, PARLOUR_D])
RIFF_332 = [(0, 1.4, 0), (1.5, 1.4, 0), (3, 0.9, 12)]
ODD = [(0, 0.7, 0), (0.75, 0.7, 0), (1.5, 0.7, 7), (2.25, 0.7, 0), (3, 0.45, 12), (3.5, 0.45, 7)]


def funeral_parlour():
    s = Band(96, 32, loudness=-18.0, room=0.75)
    s.part("church", "churchorgan", level=0.62, reverb=0.6)
    s.part("hammond", "rockorgan", level=0.45, pan=0.3, reverb=0.35)
    s.part("lead", "sawlead", level=0.46, pan=-0.1, reverb=0.45, chorus=0.3)
    s.part("bass", "pickbass", level=0.7, reverb=0.1)
    s.part("strings", "slowstrings", level=0.4, reverb=0.6)
    s.part("choir", "choir", level=0.45, reverb=0.65)
    s.part("timp", "orch_timpani", level=0.5, reverb=0.5)
    s.part("whistle", "whistle", level=0.5, pan=0.1, reverb=0.55)
    s.kit("power", level=0.68)
    p = _bars(PARLOUR_CHORDS, 32)
    for bar, parts in enumerate(p):
        intro, a, b, c, d = bar < 4, 4 <= bar < 12, 12 <= bar < 20, 20 <= bar < 28, bar >= 28
        root = bass_note(at(parts, 0), 29)
        if intro:
            # The organ alone, pedal and chord, with the timpani under each change.
            comp(s, "church", bar, parts, "x---------------", low=53, vel=0.6, spread=0.2)
            s.note("church", root, bar * 4, 3.9, vel=0.6)
            s.note("timp", root + 12, bar * 4, 1.0, vel=0.7)
            if bar == 3:
                _timp_roll(s, "timp", bar, root + 12 + 7, start=2.0, beats=2.0)
            continue
        if a or d:
            bassline(s, "bass", bar, parts, RIFF_332, low=29, vel=0.85)
            comp(s, "hammond", bar, parts, "x-----x-----x---", low=55, vel=0.55, spread=0.2)
            comp(s, "church", bar, parts, "x---------------", low=48, vel=0.4, spread=0.2)
            beat(s, bar, {"kick": "x.....x.....o...", "snare": "....x.......x...", "hat": "x.x.x.x.x.x.x.x."}, vel=0.85)
        if b:
            bassline(s, "bass", bar, parts, [(0, 1.9, 0), (2, 1.9, 7)], low=29, vel=0.75)
            comp(s, "choir", bar, parts, "x---------------", low=53, vel=0.55, spread=0.2)
            comp(s, "strings", bar, parts, "x-------x-------", low=57, vel=0.5, spread=0.2)
            beat(s, bar, {"kick": "x.......x.......", "snare": "....x.......x...", "ride": "x...x...x...x..."}, vel=0.75)
            if bar % 4 == 0:
                s.note("timp", bass_note(at(parts, 0), 41), bar * 4, 1.0, vel=0.75)
        if c:
            # The odd-accented break: 3+3+3+3+2+2 sixteenths, organ and bass together, softer drums.
            bassline(s, "bass", bar, parts, ODD, low=29, vel=0.75)
            comp(s, "hammond", bar, parts, "x--x--x--x--x-x-", low=55, vel=0.45, spread=0.2)
            comp(s, "strings", bar, parts, "x---------------", low=53, vel=0.38, spread=0.2)
            beat(s, bar, {"kick": "x..x..x..x..x.x.", "snare": "....o.......o...", "hat": "o.o.o.o.o.o.o.o."}, vel=0.7)
        if d:
            comp(s, "choir", bar, parts, "x---------------", low=53, vel=0.6, spread=0.2)
            s.note("timp", bass_note(at(parts, 0), 41), bar * 4, 1.0, vel=0.8)
        if bar in (11, 19, 27):
            roll(s, bar, start=3.0, count=4, kind="tom", low=0.45, high=0.75)
    _timp_roll(s, "timp", 31, bass_note("C7", 41), start=2.0, beats=2.0, low=0.4, high=0.9)
    s.hit("crash", 4 * 4, vel=0.6)
    s.hit("crash", 12 * 4, vel=0.6)
    s.hit("crash", 28 * 4, vel=0.6)
    melody(s, "lead", 4, PARLOUR_LEAD, bars=8, vel=0.8)
    # The organ sings the hold theme in F minor.
    melody(s, "church", 12, minor(THEME_A), bars=8, vel=0.7)
    melody(s, "church", 12, minor(THEME_A), bars=8, vel=0.5, transpose=-12)
    # Harold, whistling at the wake.
    whistle = minor(MOTIF) + " | Eb5:.5 C5 Ab4:2 r:1 | r:4 | r:2 C5:.5 Db5 Eb5 F5"
    melody(s, "whistle", 20, whistle, bars=4, vel=0.72, transpose=12)
    melody(s, "whistle", 24, "Db5:.5 Bb4 Db5 F5:1.5 Eb5:.5 Db5 | C5:2 r:2 | r:4 | r:4", bars=4, vel=0.72, transpose=12)
    melody(s, "lead", 26, "r:4 | Bb4:.5 C5 Db5 E5 G5:1 Bb5", bars=2, vel=0.7)
    # The grand turnaround: lead and organ together.
    melody(s, "lead", 28, "Ab5:1.5 F5:.5 Db5:2 | Bb5:1.5 G5:.5 Eb5:2 | F5:1 E5:.5 F5 G5:2 | C6:2 r:2", bars=4, vel=0.85)
    return s


# ---------------------------------------------------------------------------------------------
# The Flashback Cinema, Last Showing: a funky 70s film-score groove. D minor, 104 bpm. Hats and
# congas open on a muted-guitar chop; the flute plays the hold theme cool over lush strings; a
# brass-and-strings hook answered by Harold's whistle; the theme's middle lifts into F major with a
# string swell; a breakdown where the whistle has the motif over bass and congas alone.
# 32 bars: groove (4), flute theme (8), hook (8), lift (8), breakdown (4).
# ---------------------------------------------------------------------------------------------

CINEMA_INTRO = "Dm7 Dm7 Dm7 Dm7"
CINEMA_A = "Dm7 Bbmaj7 Gm7 C7 Dm7 Bbmaj7 Gm7 A7"
CINEMA_HOOK = "Gm7 Gm7 Dm7 Dm7 Gm7 Gm7 Bbmaj7 A7"
CINEMA_D = "Dm7 Dm7 Bbmaj7 A7"
CINEMA_CHORDS = " ".join([CINEMA_INTRO, CINEMA_A, CINEMA_HOOK, THEME_B_CHORDS, CINEMA_D])
HOOK = ("D5:.5 F5 G5:1 Bb5:.5 A5 G5:1 | F5:.75 D5:.25 F5:1 r:2 | A4:.5 C5 D5:1 F5:.5 E5 D5:1 | C5:.75 A4:.25 C5:1 r:2 | "
        "D5:.5 F5 G5:1 Bb5:.5 C6 D6:1 | C6:.75 Bb5:.25 G5:1 r:2 | F5:.5 A5 Bb5 D6 C6:1 A5 | G5:.5 E5 C#5 E5 A5:2")
SLAP = [(0, 0.45, 0), (0.75, 0.2, 12), (1.5, 0.45, 0), (2.25, 0.2, 7), (2.5, 0.45, 7), (3.25, 0.2, 12), (3.5, 0.4, 0)]
FUNK = {"kick": "x..x..x...x..x..", "snare": "....x.......x...", "hat": "xoxoxoxoxoxoxoxo"}
CONGAS = {"conga": "..o..x.o..o.x..o", "conga_hi": "o.......o......."}


def flashback_cinema():
    s = Band(104, 32, swing=0.04, loudness=-17.5, room=0.55)
    s.part("flute", "flute", level=0.62, pan=0.1, reverb=0.45)
    s.part("whistle", "whistle", level=0.5, pan=-0.1, reverb=0.5)
    s.part("chops", "mutedgtr", level=0.5, pan=-0.35, reverb=0.2)
    s.part("gtr", "cleangtr", level=0.42, pan=0.35, reverb=0.3, chorus=0.4)
    s.part("bass", "slap", level=0.68, reverb=0.08)
    s.part("rhodes", "epiano", level=0.45, pan=0.25, reverb=0.35, chorus=0.3)
    s.part("strings", "orch_strings", level=0.48, reverb=0.6)
    s.part("brass", "brass", level=0.5, pan=-0.05, reverb=0.35)
    s.kit("standard", level=0.75)
    p = _bars(CINEMA_CHORDS, 32)
    for bar, parts in enumerate(p):
        intro, a, hook, lift, brk = bar < 4, 4 <= bar < 12, 12 <= bar < 20, 20 <= bar < 28, bar >= 28
        beat(s, bar, CONGAS, vel=0.7 if not brk else 0.8)
        if brk:
            bassline(s, "bass", bar, parts, SLAP, low=38, vel=0.72)
            beat(s, bar, {"kick": "x.........x.....", "hat": "..o...o...o...o."}, vel=0.6)
            continue
        beat(s, bar, FUNK if not intro else {"hat": "xoxoxoxoxoxoxoxo", "kick": "x.........x....." if bar >= 2 else "................"}, vel=0.8)
        comp(s, "chops", bar, parts, "x.ox.o.xx.o.x.ox", low=62, vel=0.5, spread=0.0, transpose=0)
        if bar >= 2:
            bassline(s, "bass", bar, parts, SLAP, low=38, vel=0.85)
        if a or lift:
            comp(s, "strings", bar, parts, "x---------------", low=57, vel=0.5, spread=0.2)
            comp(s, "rhodes", bar, parts, "..x...x...x..x..", low=57, vel=0.42, spread=0.2)
        if a and bar in (7, 11):
            comp(s, "brass", bar, parts, "..........x.x-..", low=58, vel=0.65, spread=0.2)
        if hook:
            if bar % 2:
                comp(s, "brass", bar, parts, "..x...x.....x-..", low=58, vel=0.45, spread=0.2)
            comp(s, "gtr", bar, parts, "x-------........", low=55, vel=0.4, spread=0.2)
        if lift:
            arp(s, "gtr", bar, parts, step=0.5, low=62, octaves=2, vel=0.35, pan=0.0)
        if bar in (3, 11, 19, 27):
            roll(s, bar, start=3.0, count=4, kind="snare", low=0.4, high=0.8)
    s.swell("strings", 20 * 4, 8, low=60, high=127)
    s.hit("crash", 4 * 4, vel=0.65)
    s.hit("crash", 20 * 4, vel=0.6)
    melody(s, "flute", 4, THEME_A, bars=8, vel=0.78, transpose=12)
    melody(s, "brass", 12, HOOK, bars=8, vel=0.78)
    melody(s, "strings", 12, HOOK, bars=8, vel=0.55, transpose=12)
    # Harold answers the hook in its gaps with the theme's pickup.
    for bar in (13, 15, 17):
        melody(s, "whistle", bar, "r:2 C5:.5 A4 C5 F5", bars=1, vel=0.68, transpose=12)
    melody(s, "flute", 20, THEME_B, bars=8, vel=0.8, transpose=12)
    melody(s, "whistle", 28, MOTIF + " | E5:.5 C5 A4:2 r:1 | D5:.5 Bb4 D5 F5:1.5 E5:.5 D5 | C#5:2 r:2", bars=4, vel=0.72, transpose=12)
    return s


# ---------------------------------------------------------------------------------------------
# Final Arrangements: the depth 3 boss, Mortimer the undertaker. 70s prog and hard rock, F minor,
# 160 bpm. Timpani and organ stabs; the hold theme in minor as the riff, distortion guitar and
# Hammond in unison; a duel trading two-bar licks; a halftime with choir and a soaring guitar; the
# riff again, a descending tag back to the top.
# 32 bars: stabs (2), riff (8), duel (8), halftime (8), riff and tag (6).
# ---------------------------------------------------------------------------------------------

FA_INTRO = "Fm Fm"
FA_RIFF = "Fm Dbmaj7 Gm7b5 Cm Fm Dbmaj7 Gm7b5 C7"
FA_DUEL = "Bbm Bbm Fm Fm Db Eb C7 C7"
FA_HALF = "Db Db Bbm Bbm Gb Gb C7 C7"
FA_END = "Fm Dbmaj7 Gm7b5 C7 Db C7"
FA_CHORDS = " ".join([FA_INTRO, FA_RIFF, FA_DUEL, FA_HALF, FA_END])
DUEL_ORGAN_1 = "F5:.5 Db5 Bb4 Db5 F5 Ab5 Bb5:1 | Ab5:.5 F5 Db5 F5 Bb4:2"
DUEL_GTR_1 = "C5:.5 Ab4 F4 Ab4 C5 Eb5 F5:1 | Eb5:.5 C5 Ab4 C5 F4:2"
DUEL_ORGAN_2 = "F5:.5 Ab5 Db6 Ab5 F5 Db5 Ab4:1 | G4:.5 Bb4 Eb5 G5 Bb5:2"
DUEL_GTR_2 = "C5:.5 E5 G5 Bb5 C6:1 Bb5 | G5:.5 E5 Db5 Bb4 G4:1 E4"
SOAR = ("Ab4:2 Db5:1 F5 | Eb5:1.5 Db5:.5 C5:1 Ab4 | Bb4:2 Db5:1 F5 | Gb5:1.5 F5:.5 Db5:2 | "
        "Gb5:2 Bb5:1 Db6 | C6:1.5 Bb5:.5 Ab5:1 Gb5 | G5:2 Bb5:1 C6 | Db6:1 C6 Bb5:.5 G5 E5 C5")
FA_TAG = "Ab5:.5 G5 F5 Eb5 Db5 C5 Bb4 Ab4 | G4:1 C5 E5 G5"
DRIVE = [(e * 0.5, 0.42, 12 if e in (3, 7) else 0) for e in range(8)]


def final_arrangements():
    s = Band(160, 32, loudness=-16.0, room=0.55, humanize=0.004)
    s.part("gtr", "distortion", level=0.55, pan=-0.3, reverb=0.25)
    s.part("rhythm", "overdrive", level=0.42, pan=0.3, reverb=0.2)
    s.part("hammond", "rockorgan", level=0.55, pan=0.3, reverb=0.3)
    s.part("church", "churchorgan", level=0.48, reverb=0.6)
    s.part("bass", "pickbass", level=0.72, reverb=0.05)
    s.part("choir", "choir", level=0.5, reverb=0.65)
    s.part("strings", "orch_strings", level=0.42, reverb=0.55)
    s.part("timp", "orch_timpani", level=0.72, reverb=0.45)
    s.kit("power", level=0.8)
    p = _bars(FA_CHORDS, 32)
    rock = {"kick": "x.x...x.x.x...x.", "snare": "....x.......x...", "hat": "x.x.x.x.x.x.x.x."}
    for bar, parts in enumerate(p):
        intro, riff, duel, half, end = bar < 2, 2 <= bar < 10, 10 <= bar < 18, 18 <= bar < 26, bar >= 26
        root = bass_note(at(parts, 0), 41)
        if intro:
            # Stabs: organ and timpani on the same hits, the choir swelling under them.
            comp(s, "church", bar, parts, "x-..x-..x-......", low=53, vel=0.75, spread=0.2)
            for off in (0, 1, 2):
                s.note("timp", root, bar * 4 + off, 0.9, vel=0.85)
            comp(s, "choir", bar, parts, "x---------------", low=53, vel=0.5, spread=0.2)
            if bar == 1:
                _timp_roll(s, "timp", bar, root, start=3.0, beats=1.0, low=0.5, high=0.95)
            continue
        if not half:
            bassline(s, "bass", bar, parts, DRIVE, low=29, vel=0.9)
            beat(s, bar, rock if not duel else dict(rock, ride="x.x.x.x.x.x.x.x.", hat="................"), vel=0.9)
        if riff or end:
            _power(s, "rhythm", bar, parts, "x-.x-.x-x-.x-.x-", low=41, vel=0.6)
        if duel:
            _power(s, "rhythm", bar, parts, "x-x-x-x-x-x-x-x-", low=41, vel=0.5)
            comp(s, "strings", bar, parts, "x---------------", low=55, vel=0.45, spread=0.2)
        if half:
            bassline(s, "bass", bar, parts, [(0, 1.9, 0), (2, 0.9, 0), (3, 0.9, 12)], low=29, vel=0.85)
            beat(s, bar, {"kick": "x.......x.x.....", "snare": "........x.......", "hat": "x...x...x...x..."}, vel=0.9)
            comp(s, "choir", bar, parts, "x---------------", low=53, vel=0.62, spread=0.2)
            comp(s, "church", bar, parts, "x-------x-------", low=48, vel=0.5, spread=0.2)
            if bar % 2 == 0:
                s.note("timp", root, bar * 4, 1.0, vel=0.85)
                s.hit("crash", bar * 4, vel=0.6)
        if end:
            if bar < 30:
                s.note("timp", root, bar * 4, 0.9, vel=0.85)
            comp(s, "choir", bar, parts, "x---------------", low=53, vel=0.55, spread=0.2)
        if bar in (9, 17, 25):
            roll(s, bar, start=2.0, count=8, kind="tom", low=0.5, high=0.95)
    _timp_roll(s, "timp", 31, bass_note("C7", 41), start=2.0, beats=2.0, low=0.5, high=0.95)
    for bar in (2, 10, 26):
        s.hit("crash", bar * 4, vel=0.8)
    # The riff: the hold theme in F minor, guitar an octave under the Hammond.
    melody(s, "gtr", 2, minor(THEME_A), bars=8, vel=0.85, transpose=-12)
    melody(s, "hammond", 2, minor(THEME_A), bars=8, vel=0.75)
    # The duel, two bars each.
    melody(s, "hammond", 10, DUEL_ORGAN_1, bars=2, vel=0.85)
    melody(s, "gtr", 12, DUEL_GTR_1, bars=2, vel=0.88)
    melody(s, "hammond", 14, DUEL_ORGAN_2, bars=2, vel=0.85)
    melody(s, "gtr", 16, DUEL_GTR_2, bars=2, vel=0.9)
    # Halftime: the guitar soars over the choir.
    melody(s, "gtr", 18, SOAR, bars=8, vel=0.85, transpose=-12)
    melody(s, "strings", 18, SOAR, bars=8, vel=0.5)
    # The riff once more, then the tag down to the top.
    melody(s, "gtr", 26, minor(THEME_A1) + " | " + FA_TAG, bars=6, vel=0.88, transpose=-12)
    melody(s, "hammond", 26, minor(THEME_A1) + " | " + FA_TAG, bars=6, vel=0.78)
    return s
