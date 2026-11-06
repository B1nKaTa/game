"""Shorthand for writing songs: melodies as text with checked bars, chord progressions, comping,
bass patterns, arpeggios and drum grids.

A melody is text such as "C5:.5 A4 C5 F5:1.5 | E5:2 r:2". Each token is a note (or r for a rest) and
its length in beats; a token with no length keeps the last one. `_:2` ties two more beats onto the
note before. Every `|` must fall exactly on a bar line, and the whole melody must fill whole bars, so
a miscounted bar stops the render with the bar's number.
"""
from synth import chord, bass_note


def _beats(text):
    if "/" in text:
        a, b = text.split("/")
        return float(a or 1) / float(b)
    return float(text)


def mel(text, meter=4):
    """Parses melody text into (name, beats) pairs. Returns (notes, bars)."""
    notes = []; pos = 0.0; dur = 1.0; bar = 1
    for tok in text.split():
        if tok == "|":
            assert abs(pos - bar * meter) < 1e-6, "bar %d holds %g beats, not %d: %s" % (bar, pos - (bar - 1) * meter, meter, text[:50])
            bar += 1
            continue
        name, _, d = tok.partition(":")
        if d:
            dur = _beats(d)
        if name == "_":
            last, b = notes[-1]
            notes[-1] = (last, b + dur)
        else:
            notes.append((name, dur))
        pos += dur
    assert abs(pos - bar * meter) < 1e-6, "last bar %d holds %g beats, not %d: %s" % (bar, pos - (bar - 1) * meter, meter, text[:50])
    return notes, bar


def melody(s, inst, bar, text, bars=None, **kw):
    """Plays melody text from a bar. Checks the bar count when `bars` is given. Returns the bar after."""
    notes, count = mel(text, s.meter)
    assert bars is None or count == bars, "melody has %d bars, not %d: %s" % (count, bars, text[:50])
    s.line(inst, bar * s.meter, notes, bars=count, **kw)
    return bar + count


def prog(text, meter=4):
    """'Fmaj9 Dm9 Gm7,C7' -> per bar, a list of (offset, beats, symbol); a comma splits a bar evenly."""
    bars = []
    for tok in text.split():
        if tok == "|":
            continue
        parts = tok.split(",")
        step = meter / len(parts)
        bars.append([(k * step, step, p) for k, p in enumerate(parts)])
    return bars


def at(parts, offset):
    """The chord sounding at an offset within a bar."""
    for off, beats, sym in parts:
        if off - 1e-6 <= offset < off + beats - 1e-6:
            return sym
    return parts[-1][2]


def _hits(rhythm, meter):
    """A grid like 'x--.o-..' -> (offset, beats, velocity): x loud, o soft, - holds, . rests."""
    step = meter / len(rhythm); out = []
    for i, c in enumerate(rhythm):
        if c in "xo":
            k = i + 1
            while k < len(rhythm) and rhythm[k] == "-":
                k += 1
            out.append((i * step, (k - i) * step, 1.0 if c == "x" else 0.6))
    return out


def comp(s, inst, bar, parts, rhythm, low=55, vel=0.6, gain=0.3, spread=0.5, wet=1.0, transpose=0, drop=None):
    """Chords on a rhythm grid, voiced upward from `low` and spread across the stereo field."""
    for off, beats, v in _hits(rhythm, s.meter):
        # A held chord is struck again where the harmony changes under it.
        for p_off, p_beats, sym in parts:
            a = max(off, p_off); b = min(off + beats, p_off + p_beats)
            if b - a < 1e-6:
                continue
            notes, _ = chord(sym, low)
            if drop is not None:
                notes = notes[:drop]
            for k, m in enumerate(notes):
                pan = -spread + 2 * spread * k / max(1, len(notes) - 1)
                s.note(inst, m + transpose, bar * s.meter + a, b - a, vel=vel * v * (1.0 if a == off else 0.8), gain=gain, wet=wet, pan=pan)


def _flat_fifth(sym):
    """Whether a chord's fifth is flattened (dim, m7b5), so a bass 'fifth' must follow it."""
    return sym.endswith("dim") or sym.endswith("m7b5")


def bassline(s, inst, bar, parts, pattern, low=36, vel=0.85, gain=0.85, wet=0.08, pan=0.0):
    """pattern: (offset, beats, semitones above the chord's root) tuples."""
    for off, beats, semis in pattern:
        sym = at(parts, off)
        if semis % 12 == 7 and _flat_fifth(sym):
            semis -= 1
        m = bass_note(sym, low) + semis
        s.note(inst, m, bar * s.meter + off, beats, vel=vel * (1.0 if off == 0 else 0.85), gain=gain, wet=wet, pan=pan)


def arp(s, inst, bar, parts, step=0.25, low=60, octaves=2, vel=0.5, gain=0.15, pan=0.5, wet=0.6, beats=None, down=False, length=None):
    """Runs up (or down) the chord tones every `step` beats, alternating left and right."""
    total = beats if beats is not None else s.meter
    k = 0; t = 0.0
    while t < total - 1e-6:
        notes, _ = chord(at(parts, t), low)
        tones = [m + 12 * o for o in range(octaves) for m in notes]
        if down:
            tones = tones[::-1]
        s.note(inst, tones[k % len(tones)], bar * s.meter + t, length or step * 0.9, vel=vel, gain=gain,
               pan=pan if k % 2 else -pan, wet=wet)
        k += 1; t += step


DRUM_MIX = {"kick": (0.85, 0.0, 0.05), "snare": (0.55, 0.05, 0.4), "clap": (0.35, -0.05, 0.4),
            "hat": (0.35, 0.35, 0.3), "openhat": (0.3, 0.35, 0.3), "shaker": (0.5, 0.45, 0.3),
            "brush": (0.5, -0.3, 0.4), "rim": (0.45, 0.2, 0.4), "crash": (0.35, -0.2, 0.5),
            "ride": (0.4, 0.4, 0.3), "clank": (0.5, -0.4, 0.5), "anvil": (0.4, 0.45, 0.6),
            "steam": (0.5, -0.5, 0.5), "tom": (0.6, -0.25, 0.3), "bongo": (0.45, 0.3, 0.3),
            "conga": (0.5, -0.3, 0.3), "woodblock": (0.45, 0.35, 0.4), "tick": (0.4, -0.35, 0.3),
            "crackle": (0.35, 0.0, 0.1), "zap": (0.4, 0.0, 0.3), "cricket": (0.3, 0.6, 0.6),
            "flap": (0.4, 0.4, 0.3), "ring": (0.35, 0.5, 0.5), "bloop": (0.4, -0.4, 0.6)}


def drums(s, bar, grid, scale=1.0, swap=None):
    """grid: {kind: 'x...o...'}; each string is one bar, x loud and o soft."""
    for kind, pattern in grid.items():
        gain, pan, wet = DRUM_MIX[kind]
        step = s.meter / len(pattern)
        for i, c in enumerate(pattern):
            if c in "xo":
                s.hit(kind, bar * s.meter + i * step, vel=0.9 if c == "x" else 0.55, gain=gain * scale, wet=wet, pan=pan)


def fill(s, bar, start=2.0, count=8, kind="snare", step=0.25, gain=0.5):
    """A rising roll into the next bar."""
    for q in range(count):
        s.hit(kind, bar * s.meter + start + q * step, vel=0.4 + 0.5 * q / max(1, count - 1), gain=gain, wet=0.4)
