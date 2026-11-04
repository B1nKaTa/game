"""Sound effects for Grandpa, made from scratch: standard-library Python only.

The same toolkit as tools/music/synth.py (envelopes, noise, filters, FM), aimed at short one-shot
sounds. Each sound is a function (rng, variation) -> list of floats at RATE. SOUNDS lists them with
their variation count, their kind (which sets the checks in check.py) and their loudness.
Render with:  py tools/sfx/render.py <out_dir> [name ...]
"""
import math, random

RATE = 22050
TAU = math.tau


def n(seconds):
    return max(1, int(seconds * RATE))


def silence(seconds):
    return [0.0] * n(seconds)


# --- sources -------------------------------------------------------------------------------

def glide(t, dur, f0, f1, curve=1.0):
    """A pitch that moves from f0 to f1 over dur, evenly in pitch (exponential in Hz)."""
    if f1 is None or f1 == f0 or dur <= 0:
        return f0
    k = min(1.0, max(0.0, t / dur)) ** curve
    return f0 * (f1 / f0) ** k


def osc(dur, f0, f1=None, shape="sine", curve=1.0, vib=0.0, vib_rate=5.0, duty=0.5, glide_time=None):
    """An oscillator with a pitch glide and vibrato. Shapes: sine, tri, saw, square, pulse."""
    out = [0.0] * n(dur)
    ph = 0.0
    gt = glide_time if glide_time is not None else dur
    for i in range(len(out)):
        t = i / RATE
        f = glide(t, gt, f0, f1, curve) * (1.0 + vib * math.sin(TAU * vib_rate * t))
        ph = (ph + f / RATE) % 1.0
        if shape == "sine":
            s = math.sin(TAU * ph)
        elif shape == "tri":
            s = 4.0 * abs(ph - 0.5) - 1.0
        elif shape == "saw":
            s = 2.0 * ph - 1.0
        elif shape == "square":
            s = 1.0 if ph < 0.5 else -1.0
        else:
            s = 1.0 if ph < duty else -1.0
        out[i] = s
    return out


def fm(dur, fc, ratio, index, index_decay=0.0, f1=None):
    """Two-operator FM: a sine carrier bent by a sine at ratio times its pitch."""
    out = [0.0] * n(dur)
    pc = pm = 0.0
    for i in range(len(out)):
        t = i / RATE
        f = glide(t, dur, fc, f1)
        pm += f * ratio / RATE
        pc += f / RATE
        idx = index * math.exp(-t * index_decay)
        out[i] = math.sin(TAU * pc + idx * math.sin(TAU * pm))
    return out


def noise(dur, rng):
    return [rng.uniform(-1.0, 1.0) for _ in range(n(dur))]


def partials(dur, freqs, decays, amps=None):
    """A struck object: sine partials, each with its own decay time constant (seconds)."""
    out = [0.0] * n(dur)
    amps = amps or [1.0] * len(freqs)
    for f, d, a in zip(freqs, decays, amps):
        w = TAU * f / RATE
        k = math.exp(-1.0 / (d * RATE))
        e = a
        for i in range(len(out)):
            out[i] += math.sin(w * i) * e
            e *= k
    return out


def glottal(dur, f0, f1=None, curve=1.0, jitter=0.0, rng=None):
    """A buzzing voice source: a soft-cornered saw, with a little pitch jitter for a grumble."""
    out = [0.0] * n(dur)
    ph = 0.0
    j = 0.0
    for i in range(len(out)):
        t = i / RATE
        if rng is not None and i % 64 == 0:
            j = rng.uniform(-jitter, jitter)
        f = glide(t, dur, f0, f1, curve) * (1.0 + j)
        ph = (ph + f / RATE) % 1.0
        out[i] = (2.0 * ph - 1.0) - 0.6 * math.sin(TAU * ph)
    return out


# --- filters -------------------------------------------------------------------------------

def _value(v, i):
    return v[i] if isinstance(v, list) else (v(i / RATE) if callable(v) else v)


def lp(x, cutoff):
    """One-pole lowpass. cutoff is Hz, a list per sample, or a function of time."""
    out = [0.0] * len(x)
    y = 0.0
    for i, s in enumerate(x):
        c = _value(cutoff, i)
        k = 1.0 - math.exp(-TAU * min(c, RATE * 0.45) / RATE)
        y += k * (s - y)
        out[i] = y
    return out


def lp2(x, cutoff):
    return lp(lp(x, cutoff), cutoff)


def hp(x, cutoff):
    low = lp(x, cutoff)
    return [a - b for a, b in zip(x, low)]


def bp(x, freq, q=1.0):
    """A resonant band-pass (RBJ biquad, constant peak gain). freq may change over time."""
    out = [0.0] * len(x)
    x1 = x2 = y1 = y2 = 0.0
    b0 = b2 = a1 = a2 = 0.0
    for i, s in enumerate(x):
        if i % 16 == 0:
            f = min(max(_value(freq, i), 20.0), RATE * 0.45)
            w = TAU * f / RATE
            alpha = math.sin(w) / (2.0 * q)
            a0 = 1.0 + alpha
            b0 = alpha / a0
            b2 = -alpha / a0
            a1 = -2.0 * math.cos(w) / a0
            a2 = (1.0 - alpha) / a0
        y = b0 * s + b2 * x2 - a1 * y1 - a2 * y2
        x2, x1 = x1, s
        y2, y1 = y1, y
        out[i] = y
    return out


def formant(x, freqs, q=6.0, gains=None):
    gains = gains or [1.0] * len(freqs)
    out = [0.0] * len(x)
    for f, g in zip(freqs, gains):
        for i, s in enumerate(bp(x, f, q)):
            out[i] += s * g
    return out


def drive(x, amount):
    norm = math.tanh(amount)
    return [math.tanh(s * amount) / norm for s in x]


# --- envelopes -----------------------------------------------------------------------------

def env_ad(length, attack, decay, hold=0.0):
    """Linear rise over attack, flat for hold, then an exponential fall with time constant decay."""
    out = [0.0] * length
    a = max(1, int(attack * RATE))
    h = int(hold * RATE)
    for i in range(length):
        if i < a:
            out[i] = i / a
        elif i < a + h:
            out[i] = 1.0
        else:
            out[i] = math.exp(-(i - a - h) / (decay * RATE))
    return out


def env_pts(length, points):
    """Straight lines through (seconds, level) points; flat after the last one."""
    out = [0.0] * length
    j = 0
    for i in range(length):
        t = i / RATE
        while j < len(points) - 2 and t > points[j + 1][0]:
            j += 1
        (t0, l0), (t1, l1) = points[j], points[j + 1]
        if t >= t1:
            out[i] = l1
        elif t <= t0:
            out[i] = l0
        else:
            out[i] = l0 + (l1 - l0) * (t - t0) / (t1 - t0)
    return out


def shape(x, env):
    return [a * b for a, b in zip(x, env)]


def ad(x, attack, decay, hold=0.0):
    return shape(x, env_ad(len(x), attack, decay, hold))


def pts(x, points):
    return shape(x, env_pts(len(x), points))


def gain(x, g):
    return [s * g for s in x]


def mix(dur, *layers):
    """layers: (samples, start seconds, gain). The result is dur long."""
    out = [0.0] * n(dur)
    for samples, start, g in layers:
        o = int(start * RATE)
        for i, s in enumerate(samples):
            if 0 <= o + i < len(out):
                out[o + i] += s * g
    return out


def echo(x, delay, feedback, count=4):
    out = list(x)
    d = int(delay * RATE)
    g = feedback
    for k in range(1, count + 1):
        for i, s in enumerate(x):
            if i + d * k < len(out):
                out[i + d * k] += s * g
        g *= feedback
    return out


# --- building blocks shared by many sounds -------------------------------------------------

def click(rng, freq=3000.0, dur=0.012, q=3.0):
    """A tiny bright tick: a burst of filtered noise."""
    return ad(bp(noise(dur, rng), freq, q), 0.0005, dur / 4)


def thump(f0, f1, dur, decay):
    return ad(osc(dur, f0, f1, curve=0.5), 0.001, decay)


def whoosh(rng, dur, f0, fpeak, f1, q=1.2, peak_at=0.45):
    """Air moving past: noise through a band that sweeps up and back down, loudest at peak_at."""
    x = noise(dur, rng)

    def sweep(t):
        k = t / dur
        if k < peak_at:
            return f0 * (fpeak / f0) ** (k / peak_at)
        return fpeak * (f1 / fpeak) ** ((k - peak_at) / (1.0 - peak_at))

    y = bp(x, sweep, q)
    return pts(y, [(0.0, 0.0), (dur * peak_at, 1.0), (dur, 0.0)])


def wood(rng, freq, dur=0.12, decay=0.035):
    """A knock on wood: a short click plus a ringing band of noise and a body tone."""
    body = ad(bp(noise(dur, rng), freq, 9.0), 0.0005, decay)
    tone = ad(osc(dur, freq * 0.5, freq * 0.45), 0.0005, decay * 0.8)
    return mix(dur, (body, 0, 2.2), (tone, 0, 0.5), (click(rng, freq * 3.5, 0.006), 0, 0.6))


def bell(dur, f, decay=0.6, bright=1.0):
    return partials(dur, [f, f * 2.0, f * 2.76, f * 5.4], [decay, decay * 0.5, decay * 0.35, decay * 0.15],
                    [1.0, 0.35 * bright, 0.25 * bright, 0.12 * bright])


def ching(rng, f=2093.0, dur=0.24):
    """A cash-register ching: a bright little bell over a rattle of coins."""
    b = bell(dur, f, 0.12, 1.2)
    b2 = bell(dur, f * 1.5, 0.09, 1.0)
    rattle = coins(rng, 0.12, 4)
    return mix(dur, (b, 0.0, 0.5), (b2, 0.025, 0.4), (rattle, 0.0, 0.5), (click(rng, 4000, 0.008), 0, 0.5))


def coin_clink(rng, f):
    return partials(0.09, [f, f * 1.48, f * 2.33, f * 3.1], [0.04, 0.03, 0.02, 0.012], [1.0, 0.7, 0.45, 0.3])


def coins(rng, dur, count):
    layers = []
    for k in range(count):
        # The first coin lands at once and loudest, so a clink starts on the beat.
        at = 0.0 if k == 0 else rng.uniform(0, dur * 0.7)
        layers.append((coin_clink(rng, rng.uniform(2800, 4600)), at, 1.0 if k == 0 else rng.uniform(0.4, 0.8)))
    return mix(dur + 0.1, *layers)


def stamp(rng, dur=0.18, f=95.0):
    """A rubber stamp coming down on paper over a desk: a soft thunk with a papery slap."""
    th = thump(f * 1.8, f, dur, 0.045)
    slap = ad(lp(noise(dur, rng), 2200), 0.0005, 0.012)
    desk = wood(rng, 380, dur, 0.03)
    return mix(dur, (th, 0, 1.0), (slap, 0, 0.7), (desk, 0, 0.35))


def paper(rng, dur, f0=1800, f1=3500, grain=0.6):
    """Paper sliding or flipping: bright noise, roughened so it rustles."""
    x = noise(dur, rng)
    y = bp(x, lambda t: f0 * (f1 / f0) ** (t / dur), 0.9)
    rough = [1.0 - grain + grain * abs(v) for v in lp(noise(dur, rng), 60)]
    return pts(shape(y, rough), [(0, 0), (dur * 0.25, 1.0), (dur, 0)])


def brass_note(f, dur, rng=None):
    """A warm cheap fanfare horn: a saw whose filter opens with the note, with a little bend up."""
    x = osc(dur, f * 0.985, f, "saw", glide_time=0.04)
    y = lp2(x, lambda t: 600 + 2600 * min(1.0, t / 0.05) * math.exp(-t * 3))
    return pts(y, [(0, 0), (0.015, 1.0), (dur * 0.6, 0.75), (dur, 0.0)])


def tone(f, dur, shape_name="tri", decay=0.15, attack=0.002):
    return ad(osc(dur, f, shape=shape_name), attack, decay)


def arp(freqs, step, note_dur, maker):
    total = step * (len(freqs) - 1) + note_dur
    return mix(total, *[(maker(f, note_dur), i * step, 1.0) for i, f in enumerate(freqs)])


def hz(midi):
    return 440.0 * 2 ** ((midi - 69) / 12.0)


def crackle(rng, dur, rate, size=0.6):
    """Random little pops, like a burning fuse or bubbling."""
    out = [0.0] * n(dur)
    p = rate / RATE
    for i in range(len(out)):
        if rng.random() < p:
            amp = rng.uniform(0.2, 1.0) * size
            for k in range(min(40, len(out) - i)):
                out[i + k] += amp * math.exp(-k / 6.0) * (1 if k % 2 == 0 else -1)
    return out


def bubble(rng, f0, dur=0.08):
    """A bubble: a sine that rises fast as it pops."""
    return ad(osc(dur, f0, f0 * rng.uniform(1.8, 2.4), curve=0.7), 0.003, dur * 0.35)


# --- the voice: Grandpa's grumbles, from a buzz and two formant bands ------------------------

def vowel(rng, dur, f0, f1, formants, jitter=0.02, breath=0.15):
    src = glottal(dur, f0, f1, 1.0, jitter, rng)
    voiced = formant(src, formants, 5.0, [1.0, 0.55, 0.25][:len(formants)])
    air = bp(noise(dur, rng), formants[1], 2.0)
    return [v + a * breath for v, a in zip(voiced, air)]


# === the sounds ============================================================================

# Combat ------------------------------------------------------------------------------------

def cane_swing(rng, v):
    d = 0.17 + 0.02 * v
    return whoosh(rng, d, 500 + 60 * v, 2100 + 150 * v, 800, 1.4, 0.4)


def charged_swing(rng, v):
    d = 0.3
    w = whoosh(rng, d, 260, 1400 + 120 * v, 450, 1.0, 0.45)
    low = pts(osc(d, 70, 110), [(0, 0), (0.12, 1), (d, 0)])
    return mix(d, (w, 0, 1.0), (low, 0, 0.25))


def swing_miss(rng, v):
    d = 0.12
    return whoosh(rng, d, 1500 + 200 * v, 3200, 1800, 1.6, 0.3)


def _cane_hit(rng, v, wood_f, low, punch):
    d = 0.16
    th = thump(low * 2.0, low, d, 0.045)
    crack = ad(hp(noise(d, rng), 1800), 0.0003, 0.008)
    return drive(mix(d, (th, 0, 1.0), (wood(rng, wood_f * (1 + 0.05 * v), d, 0.04), 0, 0.9), (crack, 0, punch)), 1.4)


def combo_hit_a(rng, v):
    return _cane_hit(rng, v, 650, 115, 0.5)


def combo_hit_b(rng, v):
    return _cane_hit(rng, v, 760, 125, 0.6)


def combo_finisher(rng, v):
    d = 0.28
    hit = _cane_hit(rng, v, 560, 95, 0.8)
    clonk = ad(partials(d, [1180, 1770, 2950], [0.06, 0.04, 0.02]), 0.0005, 0.07)
    sub = thump(120, 50, d, 0.09)
    return drive(mix(d, (hit, 0, 1.0), (clonk, 0.004, 0.35), (sub, 0, 0.6)), 1.3)


def charged_hit(rng, v):
    d = 0.38
    sub = thump(130, 38, d, 0.13)
    crunch = ad(lp(noise(d, rng), 2600), 0.0003, 0.06)
    w = wood(rng, 430 + 30 * v, d, 0.07)
    ring = ad(partials(d, [880, 1320], [0.12, 0.08]), 0.001, 0.1)
    return drive(mix(d, (sub, 0, 1.1), (crunch, 0, 0.8), (w, 0, 0.8), (ring, 0.005, 0.15)), 1.8)


def charge_hum(rng, v):
    d = 0.5
    x = osc(d, 110, 220, "saw", vib=0.006, vib_rate=7.0, curve=0.8)
    y = lp(x, lambda t: 400 + 1800 * (t / d))
    fifth = osc(d, 165, 330, curve=0.8)
    return pts(mix(d, (y, 0, 0.8), (fifth, 0, 0.35)), [(0, 0), (0.08, 0.6), (d * 0.85, 1.0), (d, 0)])


def charge_ready(rng, v):
    d = 0.22
    a = ad(fm(d, 1568, 2.0, 1.2, 25), 0.001, 0.06)
    b = ad(osc(d, 2349), 0.001, 0.05)
    return mix(d, (a, 0, 0.7), (b, 0.03, 0.5))


def teeth_throw(rng, v):
    d = 0.26
    layers = [(whoosh(rng, d, 900, 2500, 1200, 1.5, 0.3), 0, 0.35)]
    t = 0.0
    k = 0
    while t < d - 0.02:
        layers.append((click(rng, rng.uniform(2600, 3600), 0.01, 5.0), t, 0.9 * (1 - t / d) + 0.2))
        t += 1 / 30.0 + rng.uniform(-0.004, 0.004)
        k += 1
    return mix(d, *layers)


def teeth_bite(rng, v):
    d = 0.16
    c1 = click(rng, 3000, 0.01, 4.0)
    c2 = click(rng, 2500, 0.012, 4.0)
    crunch = ad(lp(noise(d, rng), 1300), 0.0005, 0.03)
    squelch = ad(bp(noise(d, rng), lambda t: 1000 * (0.4 / 1.0) ** (t / d), 4.0), 0.002, 0.04)
    th = thump(200, 110, d, 0.03)
    return drive(mix(d, (c1, 0, 1.6), (th, 0, 0.5), (c2, 0.022, 0.8), (crunch, 0.022, 0.5), (squelch, 0.02, 0.6)), 1.3)


def teeth_catch(rng, v):
    d = 0.11
    pop = ad(osc(d, 600, 950, curve=0.5), 0.002, 0.03)
    return mix(d, (click(rng, 3200, 0.01, 4.0), 0, 1.6), (click(rng, 2800, 0.01, 4.0), 0.018, 0.7), (pop, 0.02, 0.4))


def dodge(rng, v):
    d = 0.24
    scuff = lambda: pts(lp(bp(noise(0.08, rng), 1400, 0.7), 2500), [(0, 0), (0.01, 1), (0.08, 0)])
    w = whoosh(rng, d, 350, 1300 + 100 * v, 500, 1.0, 0.4)
    return mix(d, (scuff(), 0, 0.7), (scuff(), 0.07, 0.5), (w, 0.02, 0.8))


def player_hurt(rng, v):
    """A grumpy 'oof': a short falling grunt with a breath at its start and a body knock."""
    d = 0.3
    f0 = [175, 160, 190][v]
    voice = vowel(rng, 0.26, f0, f0 * 0.68, [520 - 30 * v, 880, 2400], 0.03, 0.2)
    voice = pts(voice, [(0, 0), (0.012, 1.0), (0.12, 0.8), (0.26, 0)])
    knock = thump(160, 80, d, 0.03)
    return drive(mix(d, (knock, 0, 0.6), (voice, 0.004, 1.0)), 1.5)


def player_death(rng, v):
    d = 1.3
    groan = vowel(rng, 0.9, 165, 82, [560, 850, 2300], 0.04, 0.2)
    groan = pts(groan, [(0, 0), (0.04, 1.0), (0.5, 0.8), (0.9, 0)])
    fall = mix(0.4, (thump(110, 45, 0.4, 0.12), 0, 1.0), (wood(rng, 300, 0.3, 0.05), 0, 0.6))
    notes = mix(0.6, (tone(hz(67), 0.3, "sine", 0.12), 0, 0.4), (tone(hz(63), 0.4, "sine", 0.18), 0.18, 0.4))
    return mix(d, (groan, 0, 1.0), (fall, 0.82, 0.9), (notes, 0.86, 0.6))


def lethal_save(rng, v):
    d = 0.7
    beat = lambda: thump(70, 45, 0.2, 0.05)
    shimmer = pts(mix(0.5, (osc(0.5, 600, 1800, curve=0.7), 0, 0.5), (osc(0.5, 606, 1820, curve=0.7), 0, 0.5)),
                  [(0, 0), (0.1, 1.0), (0.5, 0)])
    return mix(d, (beat(), 0, 1.0), (beat(), 0.16, 0.8), (shimmer, 0.18, 0.4))


def enemy_hit(rng, v):
    d = 0.13
    th = thump(240 + 30 * v, 120, d, 0.03)
    body = ad(bp(noise(d, rng), 1400 + 200 * v, 2.0), 0.0005, 0.025)
    return drive(mix(d, (th, 0, 1.0), (body, 0, 0.9)), 1.3)


def enemy_death(rng, v):
    d = 0.42
    poof = ad(lp(noise(d, rng), lambda t: 3200 * (0.1 ** (t / d))), 0.002, 0.12)
    ghost = pts(osc(0.35, 720 - 60 * v, 150, vib=0.03, vib_rate=11.0), [(0, 0), (0.01, 1.0), (0.35, 0)])
    return mix(d, (poof, 0, 0.9), (ghost, 0.0, 0.45), (thump(180, 70, 0.2, 0.04), 0, 0.5))


def boss_hit(rng, v):
    d = 0.24
    hit = enemy_hit(rng, v)
    ring = ad(partials(d, [420, 655, 1010], [0.1, 0.07, 0.04]), 0.001, 0.12)
    sub = thump(110, 55, d, 0.06)
    return drive(mix(d, (hit, 0, 0.9), (ring, 0, 0.35), (sub, 0, 0.7)), 1.3)


def boss_death(rng, v):
    d = 1.45
    rumble = ad(lp(noise(d, rng), lambda t: 900 * (0.2 ** (t / d))), 0.005, 0.45)
    fall = pts(lp(osc(1.2, 220, 50, "saw", curve=0.6), 900), [(0, 0), (0.02, 1), (1.2, 0)])
    crash = ad(hp(noise(d, rng), 2500), 0.001, 0.15)
    boom = thump(90, 30, d, 0.3)
    return drive(mix(d, (rumble, 0, 0.9), (fall, 0.05, 0.4), (crash, 0, 0.35), (boom, 0, 1.0)), 1.6)


def shield_block(rng, v):
    d = 0.26
    f = 1150 + 60 * v
    metal = partials(d, [f, f * 1.51, f * 2.29, f * 2.96], [0.09, 0.06, 0.04, 0.03], [1.0, 0.7, 0.5, 0.35])
    return mix(d, (metal, 0, 0.8), (click(rng, 4500, 0.01, 2.0), 0, 0.8), (thump(300, 180, d, 0.02), 0, 0.4))


def attack_warning(rng, v):
    """A quiet rising hum, under everything, before a heavy attack."""
    d = 0.2
    x = mix(d, (osc(d, 300, 380), 0, 0.6), (osc(d, 450, 570), 0, 0.25))
    return pts(x, [(0, 0), (0.03, 0.8), (0.14, 1.0), (d, 0)])


def summon(rng, v):
    d = 0.55
    x = fm(d, 220, 1.5, 2.5, 3.0, f1=520)
    wob = [1.0 + 0.3 * math.sin(TAU * 9 * i / RATE) for i in range(len(x))]
    sparkle = ad(hp(noise(d, rng), 5000), 0.2, 0.15)
    return pts(mix(d, (shape(x, wob), 0, 0.7), (sparkle, 0, 0.2)), [(0, 0), (0.1, 1), (0.42, 0.8), (d, 0)])


# Hazards ------------------------------------------------------------------------------------

def ship_horn(rng, v):
    d = 1.5
    a = osc(d, 98, shape="saw")
    b = osc(d, 98.7, shape="saw")
    c = osc(d, 147, shape="saw")
    x = lp2(mix(d, (a, 0, 0.5), (b, 0, 0.5), (c, 0, 0.3)), 650)
    return pts(x, [(0, 0), (0.08, 1.0), (1.2, 0.9), (d, 0)])


def sand_step(rng, v):
    d = 0.13
    grains = shape(bp(noise(d, rng), 1300 + 150 * v, 0.8), [abs(g) for g in lp(noise(d, rng), 300)])
    return pts(lp(grains, 3500), [(0, 0), (0.008, 1.0), (0.04, 0.7), (d, 0)])


def barrier_chime(rng, v):
    d = 0.75
    return mix(d, (bell(0.5, hz(81), 0.3), 0, 0.5), (bell(0.55, hz(77), 0.35), 0.2, 0.5))


def tape_snag(rng, v):
    d = 0.26
    peel = bp(noise(d, rng), lambda t: 450 * (2.2 ** (t / d)), 2.5)
    crk = crackle(rng, d, 160, 0.5)
    return pts(mix(d, (peel, 0, 1.0), (crk, 0, 0.6)), [(0, 0), (0.02, 1), (0.2, 0.7), (d, 0)])


def tape_cut(rng, v):
    d = 0.16
    snip = lambda: ad(partials(0.05, [4100, 5900], [0.01, 0.007]), 0.0003, 0.01)
    tear = ad(bp(noise(0.08, rng), 2400, 1.5), 0.002, 0.02)
    return mix(d, (snip(), 0, 0.8), (snip(), 0.035, 1.0), (tear, 0.04, 0.6))


def organ_chord(rng, v):
    d = 0.95
    out = []
    notes = [hz(50), hz(57), hz(62), hz(65)]
    layers = []
    for f in notes:
        w = TAU * f / RATE
        s = [math.sin(w * i) + 0.6 * math.sin(2 * w * i) + 0.35 * math.sin(3 * w * i) + 0.2 * math.sin(4 * w * i)
             for i in range(n(d))]
        layers.append((s, 0, 0.25))
    x = mix(d, *layers)
    chiff = ad(bp(noise(d, rng), 1800, 1.2), 0.004, 0.03)
    return pts(mix(d, (x, 0, 1.0), (chiff, 0, 0.3)), [(0, 0), (0.04, 1.0), (0.7, 0.85), (d, 0)])


def escalator_hum(rng, v):
    d = 0.8
    w = TAU * 60 / RATE
    hum = [math.sin(w * i) + 0.5 * math.sin(2 * w * i) + 0.3 * math.sin(3 * w * i) for i in range(n(d))]
    layers = [(lp(hum, 400), 0, 0.6)]
    for k in range(int(d * 8)):
        layers.append((click(rng, 1500, 0.015, 3.0), k / 8.0, 0.5))
    return pts(mix(d, *layers), [(0, 0), (0.08, 1.0), (0.65, 1.0), (d, 0)])


def steam_hiss(rng, v):
    d = 0.6
    x = hp(noise(d, rng), 2200 + 300 * v)
    return pts(bp(x, 4500, 0.7), [(0, 0), (0.03, 1.0), (0.35, 0.7), (d, 0)])


# The Thermos ---------------------------------------------------------------------------------

def fuse_hiss(rng, v):
    d = 1.15
    hiss = hp(noise(d, rng), 3000)
    crk = crackle(rng, d, 60, 1.0)
    return pts(mix(d, (hiss, 0, 0.5), (crk, 0, 0.7)), [(0, 0), (0.05, 0.8), (1.05, 1.0), (d, 0)])


def explosion(rng, v):
    """A deep boom: a crack, a falling sub, a rumble that darkens, and debris landing after."""
    d = 1.05
    crack = ad(noise(d, rng), 0.0003, 0.012)
    boom = drive(thump(85 - 8 * v, 32, d, 0.22), 2.0)
    rumble = ad(lp2(noise(d, rng), lambda t: 1200 * (0.12 ** (t / d))), 0.004, 0.3)
    layers = [(crack, 0, 0.8), (boom, 0, 1.0), (rumble, 0, 1.3)]
    t = 0.14
    while t < 0.85:
        piece = wood(rng, rng.uniform(500, 1600), 0.06, 0.012) if rng.random() < 0.5 else click(rng, rng.uniform(1500, 3500), 0.015, 2.0)
        layers.append((piece, t, 0.35 * (1.0 - t)))
        t += rng.uniform(0.03, 0.09)
    return drive(mix(d, *layers), 1.4)


def small_blast(rng, v):
    d = 0.42
    crack = ad(noise(d, rng), 0.0003, 0.01)
    boom = thump(120, 45, d, 0.08)
    rumble = ad(lp(noise(d, rng), 900), 0.002, 0.09)
    return drive(mix(d, (crack, 0, 0.6), (boom, 0, 1.0), (rumble, 0, 0.8)), 1.5)


# Pickups and the world -----------------------------------------------------------------------

def coin(rng, v):
    d = 0.16
    f = [1319, 1397, 1245][v]
    a = ad(osc(0.07, f, shape="square"), 0.001, 0.03)
    b = ad(osc(0.12, f * 1.335, shape="square"), 0.001, 0.05)
    return lp(mix(d, (a, 0, 0.5), (b, 0.045, 0.5), (coin_clink(rng, f * 2.4), 0, 0.3)), 6000)


def pill_heal(rng, v):
    d = 0.42
    rattle = mix(0.12, *[(click(rng, rng.uniform(2500, 4000), 0.008, 4.0), k * 0.025, 0.6) for k in range(4)])
    up = arp([hz(72), hz(76), hz(79), hz(84)], 0.055, 0.18, lambda f, dd: tone(f, dd, "sine", 0.07))
    return mix(d, (rattle, 0, 0.6), (up, 0.08, 0.8))


def thermos_pickup(rng, v):
    d = 0.32
    clunk = mix(0.2, (partials(0.2, [520, 812, 1340], [0.05, 0.035, 0.02]), 0, 0.6), (thump(200, 120, 0.2, 0.03), 0, 0.6))
    slosh = pts(bp(noise(0.22, rng), lambda t: 500 + 400 * math.sin(TAU * 8 * t), 2.0), [(0, 0), (0.05, 1), (0.22, 0)])
    return mix(d, (clunk, 0, 1.0), (slosh, 0.06, 0.6))


def slip_pickup(rng, v):
    d = 0.22
    flick = paper(rng, 0.08, 2500, 5000)
    whistle = ad(osc(0.15, 1200, 2000, curve=0.6), 0.005, 0.05)
    return mix(d, (flick, 0, 0.8), (whistle, 0.04, 0.35))


def item_fanfare(rng, v):
    notes = [hz(67), hz(72), hz(76), hz(79)]
    lead = mix(0.95, (brass_note(notes[0], 0.11), 0, 1), (brass_note(notes[1], 0.11), 0.11, 1),
               (brass_note(notes[2], 0.11), 0.22, 1), (brass_note(notes[3], 0.55), 0.33, 1))
    sparkle = ad(hp(noise(0.95, rng), 6000), 0.3, 0.2)
    return mix(0.95, (lead, 0, 0.8), (bell(0.6, hz(91), 0.25), 0.33, 0.2), (sparkle, 0, 0.1))


def potion_drink(rng, v):
    d = 0.65
    layers = []
    for k in range(3):
        g = pts(bp(noise(0.09, rng), lambda t: 300 + 600 * t / 0.09, 3.0), [(0, 0), (0.01, 1), (0.09, 0)])
        layers.append((g, k * 0.12, 0.8))
        layers.append((bubble(rng, 240 + 30 * k, 0.07), k * 0.12 + 0.03, 0.5))
    layers.append((tone(hz(79), 0.25, "sine", 0.1), 0.42, 0.4))
    layers.append((tone(hz(84), 0.22, "sine", 0.1), 0.46, 0.3))
    return mix(d, *layers)


def chest_open(rng, v):
    d = 0.55
    creak = bp(glottal(0.3, 170, 230, 1.0, 0.08, rng), 900, 4.0)
    creak = pts(creak, [(0, 0), (0.03, 1), (0.25, 0.6), (0.3, 0)])
    latch = mix(0.05, (click(rng, 2500, 0.012, 3.0), 0, 1.0))
    sparkle = arp([hz(84), hz(88), hz(91)], 0.05, 0.2, lambda f, dd: tone(f, dd, "sine", 0.06))
    return mix(d, (latch, 0, 0.8), (creak, 0.02, 0.8), (sparkle, 0.28, 0.35))


def chest_rattle(rng, v):
    d = 0.3
    layers = [(thump(180, 120, 0.15, 0.03), 0, 0.5)]
    for k in range(5):
        layers.append((ad(partials(0.05, [2200 + rng.uniform(-200, 200), 3300], [0.015, 0.01]), 0.0003, 0.012), k * 0.045 + rng.uniform(0, 0.01), 0.7))
    return mix(d, *layers)


def mimic_snarl(rng, v):
    d = 0.6
    growl = glottal(0.5, 85, 70, 1.0, 0.15, rng)
    am = [0.6 + 0.4 * abs(math.sin(TAU * 23 * i / RATE)) for i in range(len(growl))]
    g = formant(shape(growl, am), [600, 1100], 4.0)
    g = drive(pts(g, [(0, 0), (0.04, 1), (0.4, 0.8), (0.5, 0)]), 2.0)
    return mix(d, (g, 0, 1.0), (teeth_bite(rng, 0), 0.38, 0.8))


def wood_break(rng, v):
    d = 0.36
    crack = ad(bp(noise(d, rng), 900 + 100 * v, 1.2), 0.0005, 0.05)
    layers = [(crack, 0, 1.0), (thump(170, 90, d, 0.05), 0, 0.7)]
    for k in range(4):
        layers.append((wood(rng, rng.uniform(700, 1500), 0.07, 0.015), 0.04 + rng.uniform(0, 0.2), 0.4))
    return drive(mix(d, *layers), 1.3)


def rock_break(rng, v):
    d = 0.42
    grains = shape(lp(noise(d, rng), 1600), [abs(g) ** 0.5 for g in lp(noise(d, rng), 120)])
    crunch = ad(grains, 0.0005, 0.09)
    layers = [(crunch, 0, 1.2), (thump(110, 50, d, 0.07), 0, 0.9)]
    for k in range(3):
        layers.append((click(rng, rng.uniform(800, 1800), 0.02, 1.5), 0.08 + rng.uniform(0, 0.25), 0.4))
    return drive(mix(d, *layers), 1.4)


def grass_cut(rng, v):
    d = 0.16
    x = shape(hp(noise(d, rng), 3000), [abs(g) for g in lp(noise(d, rng), 200)])
    return pts(x, [(0, 0), (0.006, 1), (0.05, 0.6), (d, 0)])


def door_open(rng, v):
    d = 0.6
    creak = bp(glottal(0.45, 120, 175, 1.0, 0.1, rng), 700, 5.0)
    creak = pts(creak, [(0, 0), (0.05, 1), (0.4, 0.5), (0.45, 0)])
    latch = click(rng, 1800, 0.015, 3.0)
    return mix(d, (latch, 0, 0.8), (thump(150, 100, 0.15, 0.03), 0, 0.4), (creak, 0.05, 0.8), (thump(120, 70, 0.2, 0.05), 0.48, 0.5))


def door_close(rng, v):
    d = 0.32
    return drive(mix(d, (thump(120, 55, d, 0.07), 0, 1.0), (wood(rng, 420, 0.2, 0.04), 0, 0.7), (click(rng, 2200, 0.012, 3.0), 0.05, 0.5)), 1.4)


def secret_reveal(rng, v):
    d = 0.95
    grind = pts(lp(shape(noise(0.6, rng), [abs(g) for g in lp(noise(0.6, rng), 40)]), 700), [(0, 0), (0.05, 1), (0.6, 0)])
    shimmer = arp([hz(74), hz(78), hz(81), hz(86)], 0.08, 0.45, lambda f, dd: bell(dd, f, 0.18, 0.6))
    return mix(d, (grind, 0, 1.0), (thump(80, 40, 0.4, 0.1), 0, 0.6), (shimmer, 0.3, 0.35))


def stairwell_appear(rng, v):
    d = 0.9
    grind = pts(lp(noise(0.7, rng), lambda t: 900 * (0.3 ** (t / 0.7))), [(0, 0), (0.04, 1), (0.7, 0)])
    chord = mix(0.8, *[(tone(hz(m), 0.8, "tri", 0.3, 0.02), 0, 0.3) for m in (45, 52, 57)])
    return mix(d, (grind, 0, 0.8), (thump(90, 40, 0.4, 0.1), 0, 0.7), (lp(chord, 1200), 0.08, 0.8))


def landing_arrive(rng, v):
    d = 0.75
    chord = mix(0.75, *[(ad(fm(0.75, hz(m), 1.0, 1.4, 6.0), 0.005, 0.28), k * 0.03, 0.3) for k, m in enumerate((60, 64, 67, 72))])
    return chord


# The Arcade --------------------------------------------------------------------------------

def card_flick(rng, dur=0.05, f=3000):
    return pts(bp(noise(dur, rng), f, 1.2), [(0, 0), (0.002, 1.0), (dur, 0)])


def card_shuffle(rng, v):
    d = 0.6
    layers = []
    t = 0.0
    gap = 0.03
    while t < 0.45:
        layers.append((card_flick(rng, 0.018, rng.uniform(2500, 4200)), t, rng.uniform(0.4, 0.8)))
        t += gap
        gap = max(0.009, gap * 0.92)
    layers.append((paper(rng, 0.14, 1500, 3500, 0.3), 0.44, 0.7))
    layers.append((wood(rng, 700, 0.06, 0.012), 0.55, 0.4))
    return mix(d, *layers)


def card_deal(rng, v):
    d = 0.1
    slide = paper(rng, 0.07, 2000 + 300 * v, 4200, 0.3)
    return mix(d, (slide, 0, 0.8), (card_flick(rng, 0.02, 2200), 0.065, 0.6))


def card_flip(rng, v):
    d = 0.08
    return mix(d, (card_flick(rng, 0.03, 3200 + 300 * v), 0, 0.9), (card_flick(rng, 0.025, 1800), 0.025, 0.7))


def chips_bet(rng, v):
    d = 0.2
    chip = lambda f: ad(partials(0.05, [f, f * 1.6, f * 2.4], [0.012, 0.009, 0.006]), 0.0003, 0.012)
    return mix(d, *[(chip(rng.uniform(2600, 3600)), k * rng.uniform(0.03, 0.045), 0.8) for k in range(3 + v)])


def _jingle(freqs, step, last, maker, extra=0.2):
    return arp(freqs, step, last, maker)


def bj_win(rng, v):
    return arp([hz(72), hz(76), hz(79), hz(84)], 0.08, 0.3, lambda f, dd: tone(f, dd, "tri", 0.1))


def bj_lose(rng, v):
    x = arp([hz(64), hz(60)], 0.16, 0.35, lambda f, dd: lp(tone(f, dd, "square", 0.12), 1200))
    return x


def bj_push(rng, v):
    return arp([hz(67), hz(67)], 0.12, 0.2, lambda f, dd: tone(f, dd, "tri", 0.07))


def slot_lever(rng, v):
    d = 0.4
    layers = []
    for k in range(6):
        layers.append((click(rng, 1800 + 100 * k, 0.012, 3.0), k * 0.035, 0.6))
    layers.append((thump(140, 70, 0.2, 0.04), 0.22, 0.9))
    layers.append((ad(partials(0.2, [700, 1080], [0.05, 0.03]), 0.001, 0.04), 0.22, 0.5))
    return mix(d, *layers)


SPIN_TIME = 0.75


def slot_spin(rng, v):
    """The reels whirring: a ticking at 20 a second over a soft hum, as long as the reels spin."""
    d = SPIN_TIME
    layers = [(lp(osc(d, 90, shape="saw"), 500), 0, 0.3)]
    for k in range(int(d * 20)):
        layers.append((click(rng, 2200, 0.008, 3.0), k / 20.0, 0.6))
    return pts(mix(d, *layers), [(0, 0), (0.03, 1), (d - 0.05, 1), (d, 0)])


def slot_stop(rng, v):
    d = 0.1
    return mix(d, (thump(220 + 20 * v, 140, d, 0.02), 0, 0.8), (click(rng, 1500, 0.015, 2.5), 0, 0.8))


def slot_win(rng, v):
    return arp([hz(79), hz(84), hz(88), hz(91), hz(96)], 0.06, 0.3, lambda f, dd: bell(dd, f, 0.12, 0.7))


def slot_jackpot(rng, v):
    """Three skulls: a spooky organ swell under a cascade of bells."""
    d = 1.5
    organ = organ_chord(rng, 0)
    bells = arp([hz(m) for m in (84, 88, 91, 96, 91, 96, 100, 103)], 0.08, 0.4, lambda f, dd: bell(dd, f, 0.15, 0.8))
    return mix(d, (organ, 0, 0.5), (bells, 0.1, 0.5), (coins(rng, 0.8, 10), 0.3, 0.4))


# NPC voices: one short blip per letter group, each voice its own timbre ----------------------

def _blip(x, d):
    return pts(x, [(0, 0), (0.003, 1.0), (d * 0.6, 0.6), (d, 0)])


def blip_smooth(rng, v):
    d = 0.06
    f = 210 * (1 + 0.03 * v)
    return _blip(mix(d, (osc(d, f), 0, 0.8), (osc(d, f * 2), 0, 0.25)), d)


def blip_prim(rng, v):
    d = 0.045
    return _blip(osc(d, 620 * (1 + 0.04 * v), 700 * (1 + 0.04 * v), "tri"), d)


def blip_gruff(rng, v):
    d = 0.06
    x = lp(osc(d, 125 * (1 + 0.04 * v), 110, "square"), 1100)
    grit = lp(noise(d, rng), 1500)
    return _blip(mix(d, (x, 0, 0.8), (grit, 0, 0.25)), d)


def blip_plain(rng, v):
    d = 0.05
    return _blip(lp(osc(d, 300 * (1 + 0.04 * v), shape="pulse", duty=0.25), 2500), d)


def blip_reedy(rng, v):
    d = 0.055
    return _blip(lp(osc(d, 470 * (1 + 0.04 * v), shape="saw", vib=0.03, vib_rate=18), 2200), d)


def blip_mystic(rng, v):
    d = 0.07
    return _blip(fm(d, 400 * (1 + 0.04 * v), 1.41, 1.5, 10, f1=360), d)


def blip_boom(rng, v):
    d = 0.065
    return _blip(drive(lp(osc(d, 105 * (1 + 0.04 * v), 95, "saw"), 900), 2.0), d)


def blip_nasal(rng, v):
    d = 0.05
    return _blip(bp(osc(d, 340 * (1 + 0.04 * v), shape="pulse", duty=0.12), 1500, 2.0), d)


# UI ---------------------------------------------------------------------------------------

def ui_move(rng, v):
    return ad(osc(0.03, 1760, shape="tri"), 0.001, 0.008)


def ui_confirm(rng, v):
    return mix(0.12, (tone(1047, 0.06, "tri", 0.025), 0, 0.7), (tone(1568, 0.08, "tri", 0.03), 0.04, 0.7))


def ui_back(rng, v):
    return mix(0.12, (tone(880, 0.06, "tri", 0.025), 0, 0.7), (tone(587, 0.08, "tri", 0.03), 0.04, 0.7))


def ui_ching(rng, v):
    return ching(rng, 2093 * (1 + 0.03 * v), 0.24)


def ui_denied(rng, v):
    d = 0.2
    x = lp(mix(d, (osc(d, 110, shape="square"), 0, 0.5), (osc(d, 104, shape="square"), 0, 0.5)), 900)
    return pts(x, [(0, 0), (0.004, 1), (0.15, 0.8), (d, 0)])


def form_filed(rng, v):
    return stamp(rng, 0.18, 95 + 8 * v)


def notice_pop(rng, v):
    return mix(0.14, (tone(988, 0.1, "sine", 0.04), 0, 0.6), (tone(1319, 0.1, "sine", 0.04), 0.035, 0.5))


def ticket_ding(rng, v):
    return bell(0.25, 1568, 0.09)


def letter_read(rng, v):
    return mix(0.22, (paper(rng, 0.12, 1500, 3000), 0, 0.8), (paper(rng, 0.1, 2500, 4000), 0.1, 0.6))


def pause_open(rng, v):
    return mix(0.2, (tone(784, 0.1, "sine", 0.04), 0, 0.6), (tone(523, 0.14, "sine", 0.05), 0.05, 0.6), (whoosh(rng, 0.15, 2000, 1200, 500, 1.2, 0.2), 0, 0.15))


def pause_close(rng, v):
    return mix(0.2, (tone(523, 0.1, "sine", 0.04), 0, 0.6), (tone(784, 0.14, "sine", 0.05), 0.05, 0.6), (whoosh(rng, 0.15, 500, 1200, 2000, 1.2, 0.6), 0, 0.15))


def slot_select(rng, v):
    return mix(0.2, (tone(659, 0.12, "tri", 0.05), 0, 0.6), (tone(988, 0.15, "tri", 0.06), 0.05, 0.6))


# The Waiting Room --------------------------------------------------------------------------

def form_buy(rng, v):
    d = 0.42
    return mix(d, (stamp(rng, 0.2, 90 + 6 * v), 0, 1.0), (ching(rng, 2093, 0.24), 0.13, 0.55))


def form_milestone(rng, v):
    d = 0.45
    layers = [(paper(rng, 0.09, 1500 + 400 * k, 3000 + 500 * k, 0.4), k * 0.07, 0.7) for k in range(4)]
    layers.append((tone(hz(84), 0.2, "sine", 0.08), 0.28, 0.25))
    return mix(d, *layers)


def form_pick(rng, v):
    return stamp(rng, 0.2, 105)


def refile(rng, v):
    d = 0.62
    layers = [(paper(rng, 0.08, 1800, 3500, 0.5), k * 0.06, 0.6) for k in range(5)]
    layers.append((stamp(rng, 0.2, 95), 0.4, 1.0))
    return mix(d, *layers)


def form_maxed(rng, v):
    d = 1.0
    horn = mix(0.8, (brass_note(hz(72), 0.12), 0, 1), (brass_note(hz(72), 0.12), 0.13, 1), (brass_note(hz(79), 0.5), 0.26, 1))
    return mix(d, (stamp(rng, 0.2, 90), 0, 1.0), (horn, 0.16, 0.6), (bell(0.5, hz(91), 0.2), 0.42, 0.15))


def form_denied(rng, v):
    d = 0.36
    thud = mix(0.2, (thump(90, 60, 0.2, 0.05), 0, 1.0), (lp(noise(0.2, rng), 600), 0, 0.0))
    buzz = pts(lp(mix(0.25, (osc(0.25, 92, shape="square"), 0, 0.5), (osc(0.25, 87, shape="square"), 0, 0.5)), 700),
               [(0, 0), (0.01, 1), (0.2, 0.7), (0.25, 0)])
    return mix(d, (thud, 0, 1.0), (buzz, 0.05, 0.5))


def plan_deposit(rng, v):
    return coins(rng, 0.1, 2 + v)


def plan_withdraw(rng, v):
    d = 0.8
    return mix(d, (coins(rng, 0.6, 16), 0, 0.8), (thump(160, 100, 0.2, 0.04), 0, 0.3))


def craft(rng, v):
    """Agnes at work: a needle in and out, a thread pulled, two snips, and a little ta-da."""
    d = 1.25
    layers = []
    for k in range(4):
        layers.append((click(rng, 2600, 0.01, 4.0), k * 0.09, 0.5))
        layers.append((ad(bp(noise(0.06, rng), 3200, 2.0), 0.01, 0.015), k * 0.09 + 0.03, 0.4))
    layers.append((paper(rng, 0.18, 2500, 5000, 0.2), 0.38, 0.4))
    layers.append((tape_cut(rng, 0), 0.58, 0.6))
    tada = mix(0.55, (brass_note(hz(72), 0.12), 0, 1.0), (brass_note(hz(79), 0.4), 0.12, 1.0))
    layers.append((tada, 0.72, 0.6))
    return mix(d, *layers)


def brew(rng, v):
    d = 0.65
    layers = [(bubble(rng, rng.uniform(180, 420), rng.uniform(0.05, 0.09)), rng.uniform(0, 0.5), rng.uniform(0.4, 0.8)) for _ in range(9)]
    layers.append((pts(lp(noise(0.6, rng), 500), [(0, 0), (0.1, 1), (0.6, 0)]), 0, 0.25))
    return mix(d, *layers)


def condolence(rng, v):
    return mix(0.55, (bell(0.5, hz(79), 0.2, 0.4), 0, 0.5), (bell(0.45, hz(86), 0.18, 0.4), 0.06, 0.35))


def poster_take(rng, v):
    d = 0.16
    return mix(d, (click(rng, 3500, 0.008, 3.0), 0, 1.4), (thump(260, 180, 0.1, 0.015), 0.003, 0.6), (ad(bp(noise(0.08, rng), 600, 2.0), 0.001, 0.02), 0.003, 0.5))


def bounty_paid(rng, v):
    d = 0.85
    bells = arp([hz(76), hz(79), hz(84), hz(88)], 0.07, 0.35, lambda f, dd: bell(dd, f, 0.12, 0.6))
    return mix(d, (coins(rng, 0.4, 8), 0, 0.6), (bells, 0.05, 0.6))


def department_open(rng, v):
    d = 1.05
    door = door_open(rng, 0)
    horn = mix(0.5, (brass_note(hz(67), 0.12), 0, 1.0), (brass_note(hz(74), 0.35), 0.12, 1.0))
    return mix(d, (door, 0, 0.7), (horn, 0.5, 0.6))


def ticket_print(rng, v):
    d = 0.55
    layers = []
    for k in range(14):
        layers.append((click(rng, 1200 + 400 * (k % 3), 0.02, 2.0), k * 0.028, 0.5))
    motor = pts(lp(osc(0.42, 140, shape="square"), 800), [(0, 0), (0.02, 1), (0.4, 1), (0.42, 0)])
    layers.append((motor, 0, 0.25))
    layers.append((paper(rng, 0.1, 2000, 3500, 0.2), 0.43, 0.6))
    return mix(d, *layers)


def trophy_hang(rng, v):
    d = 0.22
    return mix(d, (wood(rng, 900, 0.08, 0.018), 0, 0.8), (wood(rng, 700, 0.12, 0.025), 0.07, 1.0))


# --- the catalogue -------------------------------------------------------------------------
# name: (function, variations, kind, peak). Kinds set the checks in check.py: hit (fast attack,
# short), ui (under 0.25 s, fast attack), ui_soft (under 0.25 s, paper that swells in), blip (very short), blast (the big one, 0.8 to 1.2 s), and sfx (any
# other one-shot under 1.6 s). peak sets each sound's loudness relative to the others.

SOUNDS = {
    # combat
    "cane_swing": (cane_swing, 3, "sfx", 0.35),
    "charged_swing": (charged_swing, 2, "sfx", 0.6),
    "swing_miss": (swing_miss, 2, "sfx", 0.3),
    "combo_hit_a": (combo_hit_a, 3, "hit", 0.75),
    "combo_hit_b": (combo_hit_b, 3, "hit", 0.78),
    "combo_finisher": (combo_finisher, 2, "hit", 0.85),
    "charged_hit": (charged_hit, 2, "hit", 0.92),
    "charge_hum": (charge_hum, 1, "sfx", 0.3),
    "charge_ready": (charge_ready, 1, "sfx", 0.4),
    "teeth_throw": (teeth_throw, 2, "sfx", 0.5),
    "teeth_bite": (teeth_bite, 3, "hit", 0.75),
    "teeth_catch": (teeth_catch, 2, "hit", 0.5),
    "dodge": (dodge, 3, "sfx", 0.45),
    "player_hurt": (player_hurt, 3, "hit", 0.85),
    "player_death": (player_death, 1, "sfx", 0.9),
    "lethal_save": (lethal_save, 1, "sfx", 0.8),
    "enemy_hit": (enemy_hit, 3, "hit", 0.6),
    "enemy_death": (enemy_death, 3, "hit", 0.65),
    "boss_hit": (boss_hit, 2, "hit", 0.75),
    "boss_death": (boss_death, 1, "sfx", 0.95),
    "shield_block": (shield_block, 2, "hit", 0.6),
    "attack_warning": (attack_warning, 1, "sfx", 0.22),
    "summon": (summon, 1, "sfx", 0.45),
    # hazards
    "ship_horn": (ship_horn, 1, "sfx", 0.7),
    "sand_step": (sand_step, 3, "hit", 0.25),
    "barrier_chime": (barrier_chime, 1, "sfx", 0.4),
    "tape_snag": (tape_snag, 2, "sfx", 0.45),
    "tape_cut": (tape_cut, 2, "hit", 0.5),
    "organ_chord": (organ_chord, 1, "sfx", 0.55),
    "escalator_hum": (escalator_hum, 1, "sfx", 0.35),
    "steam_hiss": (steam_hiss, 2, "sfx", 0.35),
    # the Thermos
    "fuse_hiss": (fuse_hiss, 1, "sfx", 0.3),
    "explosion": (explosion, 2, "blast", 0.97),
    "small_blast": (small_blast, 2, "hit", 0.8),
    # pickups and the world
    "coin": (coin, 3, "ui", 0.4),
    "pill_heal": (pill_heal, 1, "sfx", 0.5),
    "thermos_pickup": (thermos_pickup, 1, "sfx", 0.55),
    "slip_pickup": (slip_pickup, 1, "ui_soft", 0.45),
    "item_fanfare": (item_fanfare, 1, "sfx", 0.6),
    "potion_drink": (potion_drink, 1, "sfx", 0.55),
    "chest_open": (chest_open, 1, "sfx", 0.6),
    "chest_rattle": (chest_rattle, 1, "hit", 0.5),
    "mimic_snarl": (mimic_snarl, 1, "sfx", 0.75),
    "wood_break": (wood_break, 3, "hit", 0.6),
    "rock_break": (rock_break, 2, "hit", 0.65),
    "grass_cut": (grass_cut, 2, "hit", 0.3),
    "door_open": (door_open, 1, "sfx", 0.5),
    "door_close": (door_close, 1, "hit", 0.55),
    "secret_reveal": (secret_reveal, 1, "sfx", 0.65),
    "stairwell_appear": (stairwell_appear, 1, "sfx", 0.6),
    "landing_arrive": (landing_arrive, 1, "sfx", 0.45),
    # the Arcade
    "card_shuffle": (card_shuffle, 1, "sfx", 0.5),
    "card_deal": (card_deal, 3, "ui", 0.45),
    "card_flip": (card_flip, 2, "ui", 0.45),
    "chips_bet": (chips_bet, 2, "ui", 0.45),
    "bj_win": (bj_win, 1, "sfx", 0.45),
    "bj_lose": (bj_lose, 1, "sfx", 0.4),
    "bj_push": (bj_push, 1, "sfx", 0.38),
    "slot_lever": (slot_lever, 1, "sfx", 0.55),
    "slot_spin": (slot_spin, 1, "sfx", 0.35),
    "slot_stop": (slot_stop, 3, "hit", 0.5),
    "slot_win": (slot_win, 1, "sfx", 0.45),
    "slot_jackpot": (slot_jackpot, 1, "sfx", 0.6),
    # NPC voices
    "blip_smooth": (blip_smooth, 2, "blip", 0.3),
    "blip_prim": (blip_prim, 2, "blip", 0.25),
    "blip_gruff": (blip_gruff, 2, "blip", 0.32),
    "blip_plain": (blip_plain, 2, "blip", 0.25),
    "blip_reedy": (blip_reedy, 2, "blip", 0.25),
    "blip_mystic": (blip_mystic, 2, "blip", 0.28),
    "blip_boom": (blip_boom, 2, "blip", 0.32),
    "blip_nasal": (blip_nasal, 2, "blip", 0.25),
    # UI
    "ui_move": (ui_move, 1, "ui", 0.2),
    "ui_confirm": (ui_confirm, 1, "ui", 0.35),
    "ui_back": (ui_back, 1, "ui", 0.33),
    "ui_ching": (ui_ching, 2, "ui", 0.45),
    "ui_denied": (ui_denied, 1, "ui", 0.35),
    "form_filed": (form_filed, 2, "ui", 0.6),
    "notice_pop": (notice_pop, 1, "ui", 0.3),
    "ticket_ding": (ticket_ding, 1, "ui", 0.4),
    "letter_read": (letter_read, 1, "ui_soft", 0.45),
    "pause_open": (pause_open, 1, "ui", 0.35),
    "pause_close": (pause_close, 1, "ui", 0.35),
    "slot_select": (slot_select, 1, "ui", 0.35),
    # the Waiting Room
    "form_buy": (form_buy, 2, "sfx", 0.65),
    "form_milestone": (form_milestone, 1, "sfx", 0.5),
    "form_pick": (form_pick, 1, "hit", 0.6),
    "refile": (refile, 1, "sfx", 0.6),
    "form_maxed": (form_maxed, 1, "sfx", 0.65),
    "form_denied": (form_denied, 1, "sfx", 0.55),
    "plan_deposit": (plan_deposit, 2, "ui", 0.35),
    "plan_withdraw": (plan_withdraw, 1, "sfx", 0.55),
    "craft": (craft, 1, "sfx", 0.6),
    "brew": (brew, 1, "sfx", 0.5),
    "condolence": (condolence, 1, "sfx", 0.35),
    "poster_take": (poster_take, 1, "hit", 0.5),
    "bounty_paid": (bounty_paid, 1, "sfx", 0.55),
    "department_open": (department_open, 1, "sfx", 0.6),
    "ticket_print": (ticket_print, 1, "sfx", 0.45),
    "trophy_hang": (trophy_hang, 1, "hit", 0.55),
}


def render(name, variation):
    func, _, _, peak = SOUNDS[name]
    rng = random.Random("%s/%d" % (name, variation))
    x = func(rng, variation)
    return finish(x, peak)


def finish(x, peak):
    """Removes any DC, smooths the very edges so nothing clicks, and sets the peak."""
    x = hp(x, 20.0)
    fade_in = min(len(x), int(0.0008 * RATE))
    for i in range(fade_in):
        x[i] *= i / fade_in
    fade_out = min(len(x), int(0.006 * RATE))
    for i in range(fade_out):
        x[len(x) - 1 - i] *= i / fade_out
    # What DC the fades leave is spread over the middle, so the file averages to zero.
    mean = sum(x) / len(x)
    body = len(x) - fade_in - fade_out
    if body > 0:
        for i in range(fade_in, len(x) - fade_out):
            x[i] -= mean * len(x) / body
    top = max(1e-9, max(abs(s) for s in x))
    return [s * peak / top for s in x]
