"""Checks the rendered sounds by numbers, since nobody can listen from a script.

    py tools/sfx/check.py <dir>

Every file must read as mono 16-bit, never clip, carry no DC offset, fall inside its kind's length
range, and (for hits, UI and blips) start fast. Files must match sfx.py's catalogue one for one.
Prints one line per file and a summary, and exits 1 on any failure.
"""
import math, os, sys, wave
from array import array

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import sfx  # noqa: E402
from render import file_names  # noqa: E402

# kind: (shortest, longest seconds, longest time to reach half the peak, or None)
LIMITS = {
    "ui": (0.02, 0.25, 0.012),
    "ui_soft": (0.02, 0.25, None),
    "blip": (0.02, 0.08, 0.006),
    "hit": (0.04, 0.5, 0.010),
    "blast": (0.8, 1.2, 0.010),
    "sfx": (0.05, 1.6, None),
}
CLIP = 32767
DC_LIMIT = 0.001
# Under this level a sound counts as silent: a check that it is audible at all.
QUIET_PEAK = 0.1


def read(path):
    with wave.open(path, "rb") as w:
        if w.getnchannels() != 1 or w.getsampwidth() != 2:
            raise ValueError("not mono 16-bit")
        rate = w.getframerate()
        data = array("h")
        data.frombytes(w.readframes(w.getnframes()))
    return rate, data


def check_file(path, kind):
    problems = []
    rate, data = read(path)
    if rate != sfx.RATE:
        problems.append("rate %d" % rate)
    samples = [s / 32768.0 for s in data]
    length = len(samples) / rate
    peak = max(abs(s) for s in samples)
    clipped = sum(1 for s in data if abs(s) >= CLIP)
    dc = sum(samples) / len(samples)
    rms = math.sqrt(sum(s * s for s in samples) / len(samples))
    half = next(i for i, s in enumerate(samples) if abs(s) >= peak * 0.5) / rate
    low, high, attack = LIMITS[kind]
    if clipped:
        problems.append("%d clipped samples" % clipped)
    if abs(dc) > DC_LIMIT:
        problems.append("DC offset %.4f" % dc)
    if not low <= length <= high:
        problems.append("length %.3f s outside %.2f-%.2f" % (length, low, high))
    if attack is not None and half > attack:
        problems.append("slow attack: half peak at %.1f ms" % (half * 1000))
    if peak < QUIET_PEAK:
        problems.append("too quiet: peak %.3f" % peak)
    if abs(samples[-1]) > 0.01:
        problems.append("ends on %.3f, not silence" % samples[-1])
    return problems, (length, peak, dc, half, rms)


def main():
    if len(sys.argv) < 2:
        print(__doc__)
        return 2
    folder = sys.argv[1]
    expected = {}
    for name, (_, _, kind, _) in sfx.SOUNDS.items():
        for f in file_names(name):
            expected[f] = (name, kind)
    present = {f for f in os.listdir(folder) if f.endswith(".wav")}
    failures = 0
    for f in sorted(present - set(expected)):
        print("FAIL %s: not in the catalogue" % f)
        failures += 1
    for f in sorted(set(expected) - present):
        print("FAIL %s: missing" % f)
        failures += 1
    total_bytes = 0
    worst = {"peak": 0.0, "dc": 0.0}
    for f in sorted(present & set(expected)):
        name, kind = expected[f]
        path = os.path.join(folder, f)
        total_bytes += os.path.getsize(path)
        try:
            problems, (length, peak, dc, half, rms) = check_file(path, kind)
        except Exception as error:  # a file that will not read is a failure, not a crash
            print("FAIL %s: %s" % (f, error))
            failures += 1
            continue
        worst["peak"] = max(worst["peak"], peak)
        worst["dc"] = max(worst["dc"], abs(dc))
        status = "FAIL" if problems else "ok  "
        print("%s %-26s %-5s %.3f s  peak %.2f  rms %.3f  dc %+.5f  half-peak %.1f ms %s" % (
            status, f, kind, length, peak, rms, dc, half * 1000, "; ".join(problems)))
        if problems:
            failures += 1
    print("%d files, %.2f MB, highest peak %.3f, largest DC %.5f, %d failed" % (
        len(present), total_bytes / 1048576.0, worst["peak"], worst["dc"], failures))
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
