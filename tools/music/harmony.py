"""A quick harmony check that renders nothing.

    py tools/music/harmony.py [song ...]

Builds each song with the synth switched off, records every note, and lists the melody notes a beat
or longer that sit a semitone away from something the accompaniment is playing at that moment
(without the accompaniment also playing the melody's note). Some rubs are meant (blue notes, a
canon, the hold theme's own ninths); a song with many usually has a chord written in the wrong place.
"""
import os, sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import synth  # noqa: E402

_notes = []
_line = synth.Song.line


def _note(self, inst, name_or_midi, start_beat, beats, vel=0.8, gain=1.0, wet=1.0, pan=0.0, wide=False, legato=0.95):
    m = name_or_midi if isinstance(name_or_midi, int) else synth.midi(name_or_midi)
    _notes.append((getattr(self, "_melodic", False), inst, start_beat, beats, m))


def _melodic_line(self, *args, **kwargs):
    self._melodic = True
    try:
        return _line(self, *args, **kwargs)
    finally:
        self._melodic = False


def main():
    synth.Song.note = _note
    synth.Song.line = _melodic_line
    synth.Song.hit = lambda *a, **k: None
    from catalog import SONG_INFO
    names = sys.argv[1:] or list(SONG_INFO)
    for name in names:
        _notes.clear()
        s = SONG_INFO[name]["fn"]()
        melody = [n for n in _notes if n[0] and n[3] >= 0.9 and n[1] not in ("bell", "bassoon")]
        backing = [n for n in _notes if not n[0] and n[1] != "tapestop"]
        rubs = []
        for _, inst, start, _, m in melody:
            sounding = {b[4] % 12 for b in backing if b[2] - 1e-6 <= start < b[2] + min(b[3], 4) - 0.05}
            pc = m % 12
            if sounding and pc not in sounding and ((pc + 1) % 12 in sounding or (pc - 1) % 12 in sounding):
                bar = int(start // s.meter)
                rubs.append("bar %d beat %.2f: %s %s over %s" % (bar, start - bar * s.meter, inst, m, sorted(sounding)))
        print("%s: %d long melody notes, %d semitone rubs" % (name, len(melody), len(rubs)))
        for r in rubs:
            print("    " + r)
    return 0


if __name__ == "__main__":
    sys.exit(main())
