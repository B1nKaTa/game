"""Renders the songs to loopable WAV files, several at once.

    py tools/music/render.py <out_dir> [song ...]

With no song names it renders them all. Each song starts the noise generator from the same seed,
so a song sounds the same however many are rendered and in whatever order.
"""
import os, sys, time
from multiprocessing import Pool

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))


def _render(job):
    name, out_dir = job
    import synth
    from catalog import SONGS
    synth._rng.seed(7)
    started = time.time()
    song = SONGS[name]()
    path = os.path.join(out_dir, name + ".wav")
    seconds = song.render(path)
    return "%s: %.1f s of music in %.0f s -> %s" % (name, seconds, time.time() - started, path)


def main():
    if len(sys.argv) < 2:
        print(__doc__)
        return 2
    from catalog import SONGS
    out_dir = sys.argv[1]
    os.makedirs(out_dir, exist_ok=True)
    names = sys.argv[2:] or list(SONGS)
    unknown = [n for n in names if n not in SONGS]
    if unknown:
        print("unknown songs: %s" % ", ".join(unknown))
        return 2
    with Pool(min(len(names), max(1, (os.cpu_count() or 2) - 1))) as pool:
        for line in pool.imap_unordered(_render, [(n, out_dir) for n in names]):
            print(line, flush=True)
    return 0


if __name__ == "__main__":
    sys.exit(main())
