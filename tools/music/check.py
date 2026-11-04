"""Checks rendered songs by the numbers, since nobody can listen inside a test run.

    py tools/music/check.py <dir with the WAVs> [song ...]

For each song: the length against its bars and tempo, the peak and any samples pinned at the top
(clipping), the loudness of every second (a hole is a second 15 dB under the song's median that is
not in a bar range the catalog marks quiet), the stereo width (left/right correlation and side
energy), and the loop seam (the jump from the last sample to the first against the song's biggest
ordinary steps, and the loudness either side of it). A song marked mono in the catalog (the restored first take of
Final Arrangements, kept as it was) skips the width check. It also adds up every note list in songs.py,
which holds the hand-written tuple melodies, bar by bar. Exits 1 if anything fails.
"""
import math, os, sys, wave
from array import array

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import songs  # noqa: E402
from catalog import SONG_INFO  # noqa: E402

FULL = 32000


def db(x):
    return 20 * math.log10(max(x, 1e-9))


def check_note_lists():
    bad = []
    for name, value in vars(songs).items():
        if isinstance(value, list) and value and all(isinstance(v, tuple) and len(v) == 2 and isinstance(v[0], str) for v in value):
            total = sum(b for _, b in value)
            if abs(total / 4 - round(total / 4)) > 1e-6:
                bad.append("%s: %g beats" % (name, total))
    return bad


def check_song(path, name):
    info = SONG_INFO[name]
    with wave.open(path) as w:
        rate = w.getframerate(); n = w.getnframes(); ch = w.getnchannels()
        data = array("h"); data.frombytes(w.readframes(n))
    left = data[0::2]; right = data[1::2]
    problems = []
    seconds = n / rate
    loop = info.get("loop", True)
    want = info["bars"] * info["meter"] * 60.0 / info["bpm"]
    if loop and abs(seconds - want) > 2.0 / rate:
        problems.append("length %.3f s, expected %.3f" % (seconds, want))
    peak = max(max(left), -min(left), max(right), -min(right))
    pinned = sum(1 for x in left if abs(x) >= FULL - 50) + sum(1 for x in right if abs(x) >= FULL - 50)
    if pinned > 0:
        problems.append("%d samples at the ceiling" % pinned)
    # Loudness per second, of the mid signal.
    per = []
    for s0 in range(0, n - rate // 2, rate):
        s1 = min(n, s0 + rate)
        acc = 0.0
        for i in range(s0, s1, 2):
            m = (left[i] + right[i]) * 0.5
            acc += m * m
        per.append(db(math.sqrt(acc / ((s1 - s0) / 2)) / FULL))
    med = sorted(per)[len(per) // 2]
    quiet = info.get("quiet", [])
    spb = 60.0 / info["bpm"] * info["meter"]
    holes = []
    for k, level in enumerate(per):
        if level < med - 15:
            if not any(a * spb - 1 <= k and k + 1 <= b * spb + 1 for a, b in quiet):
                holes.append(k)
    if holes and loop:
        problems.append("quiet holes at seconds %s" % holes)
    # Stereo width.
    sl = sr = slr = side = mid = 0.0
    for i in range(0, n, 3):
        a = left[i]; b = right[i]
        sl += a * a; sr += b * b; slr += a * b
        side += (a - b) * (a - b); mid += (a + b) * (a + b)
    corr = slr / math.sqrt(max(1.0, sl * sr))
    side_db = 10 * math.log10(max(1e-9, side) / max(1e-9, mid))
    if not info.get("mono") and (corr > 0.97 or side_db < -22):
        problems.append("narrow stereo (corr %.3f, side %.1f dB)" % (corr, side_db))
    # The seam. A drum may start exactly on the first sample, so the jump is held against the song's
    # own sharpest onsets (the 99.99th percentile step), not its ordinary ones.
    steps = sorted(abs(left[i + 1] - left[i]) for i in range(0, n - 1))
    p999 = steps[int(len(steps) * 0.9999)]
    jump = max(abs(left[0] - left[-1]), abs(right[0] - right[-1]))
    w = rate // 4
    head = math.sqrt(sum(left[i] * left[i] for i in range(w)) / w)
    tail = math.sqrt(sum(left[i] * left[i] for i in range(n - w, n)) / w)
    seam_db = db(head / FULL) - db(tail / FULL)
    ends_quiet = any(b == info["bars"] for _, b in quiet)
    if loop and (jump > p999 or (abs(seam_db) > 12 and not ends_quiet)):
        problems.append("seam jump %d (p99.9 step %d), head-tail %.1f dB" % (jump, p999, seam_db))
    if not loop and abs(left[-1]) + abs(right[-1]) > 200:
        problems.append("sting does not end in silence")
    line = ("%-22s %5.1f s  peak %5.1f dB  loud %5.1f..%5.1f dB (median %5.1f)  corr %.2f side %5.1f dB  seam %4d/%4d %+5.1f dB"
            % (name, seconds, db(peak / FULL), min(per), max(per), med, corr, side_db, jump, p999, seam_db))
    return line, problems


def main():
    if len(sys.argv) < 2:
        print(__doc__)
        return 2
    folder = sys.argv[1]
    names = sys.argv[2:] or list(SONG_INFO)
    failed = 0
    bad = check_note_lists()
    print("note lists in songs.py: %s" % ("all fill whole bars" if not bad else "; ".join(bad)))
    failed += len(bad)
    for name in names:
        path = os.path.join(folder, name + ".wav")
        if not os.path.exists(path):
            print("%-22s MISSING" % name)
            failed += 1
            continue
        line, problems = check_song(path, name)
        print(line + ("" if not problems else "\n    FAIL: " + "; ".join(problems)))
        failed += bool(problems)
    print("%d songs, %d failed" % (len(names), failed))
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
