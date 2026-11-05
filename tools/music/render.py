"""Renders the songs in songs.py to loopable WAV files.

    py tools/music/render.py <out_dir> [song ...]

With no song names it renders them all.
"""
import os, sys, time

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from songs import SONGS  # noqa: E402


def main():
    if len(sys.argv) < 2:
        print(__doc__)
        return 2
    out_dir = sys.argv[1]
    os.makedirs(out_dir, exist_ok=True)
    names = sys.argv[2:] or list(SONGS)
    for name in names:
        started = time.time()
        song = SONGS[name]()
        path = os.path.join(out_dir, name + ".wav")
        seconds = song.render(path)
        print("%s: %.1f s of music in %.0f s -> %s" % (name, seconds, time.time() - started, path))
    return 0


if __name__ == "__main__":
    sys.exit(main())
