"""Renders the jukebox songs through FluidSynth, then checks each one.

    py tools/music/render_band.py <out_dir> [song ...]

With no song names it renders them all. Needs FluidSynth and the SoundFonts (see band.py).
"""
import os, sys, time
from multiprocessing import Pool

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)


def _render(job):
    name, out_dir = job
    import jukebox
    started = time.time()
    try:
        seconds = jukebox.song(name)().render(os.path.join(out_dir, name + ".wav"))
    except Exception as e:  # one broken song must not stop the rest
        return name, "%s: FAILED %s: %s" % (name, type(e).__name__, e)
    return name, "%s: %.1f s of music in %.0f s" % (name, seconds, time.time() - started)


def main():
    if len(sys.argv) < 2:
        print(__doc__)
        return 2
    import jukebox, check
    from catalog import SONG_INFO
    out_dir = sys.argv[1]
    os.makedirs(out_dir, exist_ok=True)
    for mod, err in jukebox.BROKEN.items():
        print("module %s FAILED to load: %s" % (mod, err))
    names = sys.argv[2:] or list(jukebox.BAND_INFO)
    unknown = [n for n in names if n not in jukebox.BAND_INFO]
    if unknown:
        print("unknown songs: %s" % ", ".join(unknown))
        return 2
    failed = 0
    with Pool(min(len(names), max(1, (os.cpu_count() or 2) - 1))) as pool:
        for name, line in pool.imap_unordered(_render, [(n, out_dir) for n in names]):
            print(line, flush=True)
            if "FAILED" in line:
                failed += 1
                continue
            SONG_INFO[name] = jukebox.BAND_INFO[name]
            summary, problems = check.check_song(os.path.join(out_dir, name + ".wav"), name)
            print("   " + summary + ("   PROBLEMS: " + "; ".join(problems) if problems else "   ok"), flush=True)
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
