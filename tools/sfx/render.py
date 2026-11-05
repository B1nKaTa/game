"""Renders the sounds in sfx.py to short mono 16-bit WAV files.

    py tools/sfx/render.py <out_dir> [name ...]

With no names it renders them all. A sound with one variation is <name>.wav; one with more is
<name>_1.wav, <name>_2.wav and so on, which the game's SoundBank picks between at random.
"""
import os, sys, time, wave
from array import array

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import sfx  # noqa: E402


def file_names(name):
    count = sfx.SOUNDS[name][1]
    if count == 1:
        return [name + ".wav"]
    return ["%s_%d.wav" % (name, k + 1) for k in range(count)]


def write(path, samples):
    frames = array("h", [max(-32767, min(32767, int(round(s * 32767)))) for s in samples])
    with wave.open(path, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(sfx.RATE)
        w.writeframes(frames.tobytes())


def main():
    if len(sys.argv) < 2:
        print(__doc__)
        return 2
    out_dir = sys.argv[1]
    os.makedirs(out_dir, exist_ok=True)
    names = sys.argv[2:] or list(sfx.SOUNDS)
    started = time.time()
    count = 0
    for name in names:
        for k, file_name in enumerate(file_names(name)):
            write(os.path.join(out_dir, file_name), sfx.render(name, k))
            count += 1
    print("%d files from %d sounds in %.0f s -> %s" % (count, len(names), time.time() - started, out_dir))
    return 0


if __name__ == "__main__":
    sys.exit(main())
