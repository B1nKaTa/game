#!/usr/bin/env python3
"""Convert a curated subset of VSCO 2 Community Edition (CC0, SFZ + WAV) to one SoundFont 2 file.

Usage:
    py tools/music/sfz2sf2.py <vsco_root> <out.sf2> [--mono | --stereo] [--budget-mb N]

    py tools/music/sfz2sf2.py D:\\soundfonts\\vsco2 D:\\soundfonts\\vsco2-ce.sf2

<vsco_root> is the library folder, or any folder above it: the folder that holds the
.sfz files is found automatically. Python standard library only (uses `audioop`, so
Python 3.9 - 3.12). Sample data is streamed to the output, one WAV at a time.

Design
    * Every preset is in bank 1, so it never overrides a General MIDI bank-0 font that
      is loaded alongside. Program numbers follow General MIDI where an instrument
      exists (see PRESETS below); staccato / spiccato / muted / roll variants without a
      GM slot sit on programs 96-110 (documented in the table printed at the end).
    * The string ensemble presets (48, 49, 44, 45, 96) layer violins, violas, cellos and
      basses over split key ranges (the instruments are shared, samples are stored once).
    * Sustaining articulations only. Keyswitch (-KS) files, .ariax files, the drum-kit
      file, the second organ/piano variants and release-trigger regions are skipped.
    * Per instrument: first round robin only; at most 2 velocity layers (when a key
      range has 3 or more layers the softest and the loudest are kept and split at
      velocity 64); 24-bit samples become 16-bit.
    * Stereo samples become linked left/right sample pairs (sampleType 4 / 2, hard
      panned). If the stereo result would exceed the size budget (default 500 MB) the
      converter mixes everything to mono instead (force with --mono / --stereo).
    * SFZ `volume` (dB) is baked into the sample data (SF2 can only attenuate), capped so
      a sample never clips. `ampeg_attack` / `ampeg_release` map to the volume envelope,
      `tune` to coarse/fine tune, pitch_keycenter/key to overriding root key.
    * Trailing near-silence is trimmed from each sample. The lowest / highest zone of each
      instrument plays up to an octave beyond its sampled range (pitched) instead of
      going silent.
    * Level: each instrument gets one common gain so its samples sit near full scale; the
      result is still quiet at FluidSynth's default gain (0.2), so render with `-g 0.6` to
      `-g 1.0` (e.g. `fluidsynth -ni -g 0.8 -r 44100 -F out.wav vsco2-ce.sf2 song.mid`).
    * The library samples carry no loop points; none are generated. Samples are 2-11 s
      long, so very long held notes simply end.
    * Not mapped (logged): trigger=release regions, sw_* keyswitches, lorand/seq
      round robins beyond the first, #define/#include (unused in the chosen files),
      all other opcodes.
"""
import audioop
import math
import os
import re
import struct
import sys

# ----------------------------------------------------------------------------------
# Preset table: program -> (preset name, [(sfz file, key_lo, key_hi), ...])
# More than one part means a layered preset (parts clipped to their key range).
# ----------------------------------------------------------------------------------
ENS_SUS = [("ContrabassSusVB", 0, 47), ("CelloEnsSusVib", 36, 62),
           ("ViolaEnsSusVib", 48, 71), ("ViolinEnsSusVib", 55, 127)]
ENS_QUIET = [("ContrabassSusVB-Quiet", 0, 47), ("CelloEnsSusVib-Quiet", 36, 62),
             ("ViolaEnsSusVib-Quiet", 48, 71), ("ViolinEnsSusVib-Quiet", 55, 127)]
ENS_TREM = [("ContrabassTrem", 0, 47), ("CelloEnsTrem", 36, 62),
            ("ViolaEnsTrem", 48, 71), ("ViolinEnsTrem", 55, 127)]
ENS_PIZZ = [("ContrabassPizz", 0, 47), ("CelloEnsPizz", 36, 62),
            ("ViolaEnsPizz", 48, 71), ("ViolinEnsPizz", 55, 127)]
ENS_SPIC = [("ContrabassSpic", 0, 47), ("CelloEnsSpic", 36, 62),
            ("ViolaEnsSpic", 48, 71), ("ViolinEnsSpic", 55, 127)]


def one(sfz):
    return [(sfz, 0, 127)]


PRESETS = {
    0: ("Upright Piano", one("VSUpright1")),
    9: ("Glockenspiel", one("Glockenspiel")),
    12: ("Marimba", one("Marimba")),
    13: ("Xylophone", one("Xylophone")),
    14: ("Tubular Bells", one("TubularBells")),
    19: ("Church Organ", one("OrganLoud")),
    40: ("Violin", one("SViolinVib")),
    41: ("Viola", one("ViolaEnsSusVib")),
    42: ("Cello", one("CelloEnsSusVib")),
    43: ("Contrabass", one("ContrabassSusVB")),
    44: ("Tremolo Strings", ENS_TREM),
    45: ("Pizzicato Strings", ENS_PIZZ),
    46: ("Harp", one("Harp")),
    47: ("Timpani", one("Timpani")),
    48: ("Strings Ensemble", ENS_SUS),
    49: ("Strings Ens Quiet", ENS_QUIET),
    56: ("Trumpet", one("TrumpetSus")),
    57: ("Trombone", one("TromboneSus")),
    58: ("Tuba", one("TubaSus")),
    59: ("Muted Trumpet", one("TrumpetStraightMuteSus")),
    60: ("French Horn", one("FHornSus")),
    68: ("Oboe", one("OboeSusVib")),
    70: ("Bassoon", one("BassoonSus")),
    71: ("Clarinet", one("ClarinetSus")),
    72: ("Piccolo", one("PiccoloSus")),
    73: ("Flute", one("FluteSusVib")),
    # Non-GM variants (free program numbers)
    96: ("Strings Spiccato", ENS_SPIC),
    97: ("Violin Spiccato", one("SViolinSpic")),
    98: ("Trumpet Staccato", one("TrumpetStac")),
    99: ("Trombone Staccato", one("TromboneStac")),
    100: ("Tuba Staccato", one("TubaStac")),
    101: ("Horn Staccato", one("FHornStac")),
    102: ("Flute Staccato", one("FluteStac")),
    103: ("Oboe Staccato", one("OboeStac")),
    104: ("Clarinet Staccato", one("ClarinetStac")),
    105: ("Bassoon Staccato", one("BassoonStac")),
    106: ("Piccolo Staccato", one("PiccoloStac")),
    107: ("Muted Horn", one("FHornMute")),
    108: ("Harmon Mute Trumpet", one("TrumpetHarmonMuteSus")),
    109: ("Timpani Roll", one("TimpaniRolls")),
}

SKIPPED_NOTE = ("keyswitch (-KS) files, GM-StylePerc drum kit (bank 1 only), OrganQuiet/Pedal, "
                "UprightPiano, Trumpet/Trombone vibrato and non-vibrato alternates, "
                "Flute/Oboe/Contrabass NV and Exp variants, SViolin quiet")

SAMPLE_RATE = 44100
FULL_VEL = (0, 127)
NOTE_BASE = {"c": 0, "d": 2, "e": 4, "f": 5, "g": 7, "a": 9, "b": 11}


class Log:
    def __init__(self):
        self.counts = {}

    def note(self, msg):
        self.counts[msg] = self.counts.get(msg, 0) + 1


LOG = Log()


# ----------------------------------------------------------------------------------
# SFZ parsing
# ----------------------------------------------------------------------------------
def parse_key(v):
    v = v.strip().lower()
    if re.fullmatch(r"-?\d+", v):
        return int(v)
    m = re.fullmatch(r"([a-g])(#|b)?(-?\d+)", v)
    if m:
        n = NOTE_BASE[m.group(1)] + (1 if m.group(2) == "#" else -1 if m.group(2) == "b" else 0)
        return (int(m.group(3)) + 1) * 12 + n
    raise ValueError("bad key " + v)


def parse_sfz(path):
    """Return a list of region dicts with global/group inheritance applied."""
    with open(path, "r", encoding="utf-8", errors="replace") as f:
        text = f.read()
    text = re.sub(r"//[^\n]*", "", text)
    if re.search(r"^\s*#(define|include)", text, re.M):
        LOG.note("%s: #define/#include present, not expanded" % os.path.basename(path))
    m = re.search(r"default_path=(.*)", text)
    return _inherit(text, m.group(1).strip() if m else "")


def _inherit(text, default_path):
    levels = {"global": {}, "master": {}, "group": {}}
    regions = []
    cur = None
    for m in re.finditer(r"<(\w+)>|([A-Za-z_]\w*)=([^\r\n<]*?)(?=\s+[A-Za-z_]\w*=|\s*<|\s*$)",
                         text, re.M):
        if m.group(1):
            h = m.group(1)
            if h == "region":
                cur = {}
                regions.append(cur)
                merged = {}
                for lv in ("global", "master", "group"):
                    merged.update(levels[lv])
                cur["__inherit"] = merged
            elif h == "global":
                levels = {"global": {}, "master": {}, "group": {}}
                cur = levels["global"]
            elif h == "master":
                levels["master"] = {}
                levels["group"] = {}
                cur = levels["master"]
            elif h == "group":
                levels["group"] = {}
                cur = levels["group"]
            else:
                cur = {}
            continue
        if cur is not None:
            cur[m.group(2)] = m.group(3).strip()
    result = []
    for r in regions:
        d = dict(r.pop("__inherit"))
        d.update(r)
        d["__path"] = default_path
        result.append(d)
    return result


def f_or(d, k, default):
    try:
        return float(d[k])
    except (KeyError, ValueError):
        return default


def select_regions(regions, sfz_name):
    """Drop unmappable regions, keep the first round robin and at most 2 velocity layers."""
    cand = []
    for d in regions:
        if "sample" not in d:
            continue
        if d.get("trigger", "attack").lower() in ("release", "release_key"):
            LOG.note("%s: release-trigger regions dropped" % sfz_name)
            continue
        if "sw_last" in d or "sw_lokey" in d:
            LOG.note("%s: keyswitch regions dropped" % sfz_name)
            continue
        try:
            if "key" in d:
                lo = hi = kc = parse_key(d["key"])
            else:
                lo = parse_key(d["lokey"])
                hi = parse_key(d["hikey"])
                kc = parse_key(d.get("pitch_keycenter", d["lokey"]))
        except (KeyError, ValueError):
            LOG.note("%s: region without usable key info dropped" % sfz_name)
            continue
        lov = int(f_or(d, "lovel", 0))
        hiv = int(f_or(d, "hivel", 127))
        # round-robin rank: seq_position and lorand
        rank = int(f_or(d, "seq_position", 1)) * 1000 + int(f_or(d, "lorand", 0) * 100)
        cand.append({"d": d, "lo": lo, "hi": hi, "kc": kc, "lov": lov, "hiv": hiv, "rank": rank})
    # keep best (lowest) round-robin rank per (key range, velocity range)
    best = {}
    for c in cand:
        k = (c["lo"], c["hi"], c["kc"], c["lov"], c["hiv"])
        if k not in best or c["rank"] < best[k]["rank"]:
            best[k] = c
    if len(best) < len(cand):
        LOG.note("%s: round-robin duplicates dropped" % sfz_name)
    # group by key range, thin to 2 velocity layers
    groups = {}
    for c in best.values():
        groups.setdefault((c["lo"], c["hi"], c["kc"]), []).append(c)
    out = []
    for g in groups.values():
        g.sort(key=lambda c: (c["lov"], c["hiv"]))
        # remove full-range regions when specific layers also exist
        if len(g) > 1:
            specific = [c for c in g if (c["lov"], c["hiv"]) != FULL_VEL]
            if specific:
                g = specific
        if len(g) == 1:
            g[0]["lov"], g[0]["hiv"] = 0, 127
        elif len(g) == 2:
            g[0]["lov"], g[0]["hiv"] = 0, 62
            g[1]["lov"], g[1]["hiv"] = 63, 127
        else:
            g = [g[0], g[-1]]
            g[0]["lov"], g[0]["hiv"] = 0, 63
            g[1]["lov"], g[1]["hiv"] = 64, 127
            LOG.note("%s: >2 velocity layers thinned to 2" % sfz_name)
        out.extend(g)
    out.sort(key=lambda c: (c["lo"], c["lov"]))
    return out


# ----------------------------------------------------------------------------------
# WAV reading
# ----------------------------------------------------------------------------------
def read_wav(path):
    """Return (channels, rate, width_bytes, frames, raw_pcm_bytes)."""
    with open(path, "rb") as f:
        data = f.read()
    if data[:4] != b"RIFF" or data[8:12] != b"WAVE":
        raise ValueError("not a WAV: " + path)
    pos = 12
    fmt = None
    pcm = None
    while pos + 8 <= len(data):
        cid = data[pos:pos + 4]
        size = struct.unpack("<I", data[pos + 4:pos + 8])[0]
        body = data[pos + 8:pos + 8 + size]
        if cid == b"fmt ":
            tag, ch, rate, _, _, bits = struct.unpack("<HHIIHH", body[:16])
            if tag not in (1, 0xFFFE):
                raise ValueError("unsupported WAV format %d: %s" % (tag, path))
            fmt = (ch, rate, bits // 8)
        elif cid == b"data":
            pcm = body
            break
        pos += 8 + size + (size & 1)
    if fmt is None or pcm is None:
        raise ValueError("incomplete WAV: " + path)
    ch, rate, width = fmt
    return ch, rate, width, len(pcm) // (ch * width), pcm


def wav_info(path):
    """Header-only read: (channels, rate, width, frames)."""
    with open(path, "rb") as f:
        head = f.read(65536)
    fi = head.find(b"fmt ")
    di = head.find(b"data")
    ch, rate, _, _, bits = struct.unpack("<HIIHH", head[fi + 10:fi + 24])
    n = struct.unpack("<I", head[di + 4:di + 8])[0]
    width = bits // 8
    return ch, rate, width, n // (ch * width)


# ----------------------------------------------------------------------------------
# SF2 writer
# ----------------------------------------------------------------------------------
def pad_name(s, n=20):
    b = s.encode("ascii", "replace")[:n - 1]
    return b + b"\0" * (n - len(b))


def chunk(cid, body):
    if len(body) & 1:
        body += b"\0"
    return cid + struct.pack("<I", len(body)) + body


def gen(oper, amount):
    if isinstance(amount, tuple):
        return struct.pack("<HBB", oper, amount[0], amount[1])
    return struct.pack("<Hh", oper, amount)


G_ATTACK, G_RELEASE, G_PAN, G_KEYRANGE, G_VELRANGE = 34, 38, 17, 43, 44
G_COARSE, G_FINE, G_INSTRUMENT, G_SAMPLEID, G_ROOT = 51, 52, 41, 53, 58


def timecents(sec):
    sec = max(sec, 0.001)
    return max(-12000, min(8000, int(round(1200 * math.log(sec, 2)))))


class Planner:
    """Decides which WAV becomes which SF2 sample(s) and collects instrument zones."""

    def __init__(self, root, stereo):
        self.root = root
        self.stereo = stereo
        self.peaks = {}
        self.samples = {}  # (path, gain_key) -> sample record
        self.sample_list = []
        self.instruments = {}  # sfz stem -> list of zone dicts
        self.inst_order = []

    def headroom_db(self, path):
        if path not in self.peaks:
            ch, rate, width, frames, pcm = read_wav(path)
            peak = audioop.max(pcm, width) or 1
            self.peaks[path] = -20 * math.log10(peak / float(1 << (8 * width - 1))) - 0.5
        return self.peaks[path]

    def sample_for(self, path, gain_db):
        k = (path, round(gain_db * 2) / 2.0)
        if k not in self.samples:
            ch, rate, width, frames = wav_info(path)
            if rate != SAMPLE_RATE:
                LOG.note("non-44.1k sample %s (rate %d) kept at its own rate" % (os.path.basename(path), rate))
            rec = {"path": path, "gain": k[1], "frames": frames, "rate": rate,
                   "name": os.path.splitext(os.path.basename(path))[0], "ch": ch,
                   "idx": None}
            self.samples[k] = rec
            self.sample_list.append(rec)
        return self.samples[k]

    def build_instrument(self, stem, sfz_path):
        if stem in self.instruments:
            return
        regions = parse_sfz(sfz_path)
        chosen = select_regions(regions, stem)
        zones = []
        headroom = []
        for c in chosen:
            d = c["d"]
            wav = os.path.join(self.root, d["__path"].replace("\\", os.sep).replace("/", os.sep),
                               d["sample"].replace("\\", os.sep).replace("/", os.sep))
            if not os.path.isfile(wav):
                LOG.note("%s: missing sample %s" % (stem, d["sample"]))
                continue
            if "ampeg_decay" in d or "ampeg_sustain" in d or "loop_mode" in d:
                LOG.note("%s: ampeg_decay/sustain/loop opcodes ignored" % stem)
            vol = f_or(d, "volume", 0.0)
            headroom.append(self.headroom_db(wav) - vol)
            zones.append({"lo": c["lo"], "hi": c["hi"], "kc": c["kc"], "lov": c["lov"],
                          "hiv": c["hiv"], "attack": f_or(d, "ampeg_attack", 0.001),
                          "release": f_or(d, "ampeg_release", 0.5), "tune": f_or(d, "tune", 0.0),
                          "wav": wav, "vol": vol})
        # One common boost per instrument (75th percentile of the per-sample headroom);
        # relative levels between its regions and velocity layers stay as the SFZ specifies,
        # and individual samples are still capped so they never clip.
        extend_edges(zones)
        hs = sorted(headroom)
        boost = 3.0 * math.floor(max(0.0, hs[(len(hs) * 3) // 4]) / 3.0) if hs else 0.0
        for z in zones:
            z["rec"] = self.sample_for(z["wav"], z["vol"] + boost)
        self.instruments[stem] = zones
        self.inst_order.append(stem)

    def stored_bytes(self):
        total = 0
        for r in self.sample_list:
            n = 2 if (self.stereo and r["ch"] == 2) else 1
            total += n * (r["frames"] + 46) * 2
        return total


def trim_tail(pcm, ch, block=441):
    """Cut trailing near-silence (below -66 dB of the sample's peak), keeping a short pad."""
    frame = 2 * ch
    peak = audioop.max(pcm, 2) or 1
    thresh = max(2, peak // 2000)
    n = len(pcm) // frame
    end = n
    while end > block * 2:
        seg = pcm[(end - block) * frame:end * frame]
        if audioop.max(seg, 2) > thresh:
            break
        end -= block
    end = min(n, end + block)
    return pcm[:end * frame]


def extend_edges(zones, semitones=12):
    """Let the lowest / highest zone of each velocity layer play `semitones` beyond its range
    (pitched, so slightly unnatural) instead of falling silent just outside the sampled range."""
    for lov in {z["lov"] for z in zones}:
        layer = [z for z in zones if z["lov"] == lov]
        lowest = min(layer, key=lambda z: z["lo"])
        highest = max(layer, key=lambda z: z["hi"])
        lowest["lo"] = max(0, lowest["lo"] - semitones)
        highest["hi"] = min(127, highest["hi"] + semitones)


def convert_sample(rec, stereo):
    """Return a list of (suffix, int16 bytes) for the sample."""
    ch, rate, width, frames, pcm = read_wav(rec["path"])
    peak = audioop.max(pcm, width) or 1
    full = float(1 << (8 * width - 1))
    headroom_db = -20 * math.log10(peak / full) - 0.5
    gain_db = min(rec["gain"], headroom_db)
    if gain_db < rec["gain"] - 0.01:
        LOG.note("gain capped to avoid clipping on some samples")
    if abs(gain_db) > 0.01:
        pcm = audioop.mul(pcm, width, 10 ** (gain_db / 20.0))
    if width != 2:
        pcm = audioop.lin2lin(pcm, width, 2)
    pcm = trim_tail(pcm, ch)
    if ch == 1:
        return [("", pcm)]
    if ch != 2:
        raise ValueError("unsupported channel count: " + rec["path"])
    if stereo:
        return [("L", audioop.tomono(pcm, 2, 1, 0)), ("R", audioop.tomono(pcm, 2, 0, 1))]
    return [("", audioop.tomono(pcm, 2, 0.5, 0.5))]


def write_sf2(plan, out_path, presets):
    stereo = plan.stereo
    pad = b"\0" * 92
    shdr = []  # packed 46-byte records
    sample_points = 0

    with open(out_path, "wb") as out:
        out.write(b"RIFF\0\0\0\0sfbk")
        info = chunk(b"ifil", struct.pack("<HH", 2, 1))
        info += chunk(b"isng", b"EMU8000\0")
        info += chunk(b"INAM", b"VSCO 2 CE subset (bank 1)\0")
        info += chunk(b"ICOP", b"CC0 - VSCO 2 Community Edition (Versilian Studios)\0")
        info += chunk(b"ISFT", b"sfz2sf2.py\0")
        info += chunk(b"ICMT", b"Converted from SFZ: bank 1, GM program numbers where one exists.\0")
        out.write(chunk(b"LIST", b"INFO" + info))
        out.write(b"LIST\0\0\0\0sdta")
        out.write(b"smpl\0\0\0\0")
        smpl_start = out.tell()
        total = len(plan.sample_list)
        for i, rec in enumerate(plan.sample_list):
            parts = convert_sample(rec, stereo)
            rec["ids"] = []
            base_idx = len(shdr)
            for suffix, pcm in parts:
                n = len(pcm) // 2
                start = sample_points
                end = start + n
                out.write(pcm)
                out.write(pad)
                sample_points += n + 46
                nm = rec["name"][:17] + (("_" + suffix) if suffix else "")
                kind = 1 if not suffix else (4 if suffix == "L" else 2)
                shdr.append([nm, start, end, start, end, rec["rate"], 60, 0, 0, kind])
                rec["ids"].append(len(shdr) - 1)
            if len(parts) == 2:
                a, b = rec["ids"]
                shdr[a][8] = b
                shdr[b][8] = a
            if (i + 1) % 200 == 0:
                print("  samples %d / %d" % (i + 1, total), file=sys.stderr)
        smpl_end = out.tell()
        # terminal sample record
        shdr.append(["EOS", 0, 0, 0, 0, 0, 0, 0, 0, 0])

        # ---- pdta ----
        ibag, igen, inst = [], [], []
        inst_index = {}
        for stem in plan.inst_order:
            inst_index[stem] = len(inst)
            inst.append(struct.pack("<20sH", pad_name(stem), len(ibag)))
            for z in plan.instruments[stem]:
                rec = z["rec"]
                sides = rec["ids"]
                for sid in sides:
                    ibag.append(struct.pack("<HH", len(igen), 0))
                    g = [gen(G_KEYRANGE, (z["lo"], z["hi"])), gen(G_VELRANGE, (z["lov"], z["hiv"]))]
                    if len(sides) == 2:
                        g.append(gen(G_PAN, -500 if shdr[sid][9] == 4 else 500))
                    g.append(gen(G_ATTACK, timecents(z["attack"])))
                    g.append(gen(G_RELEASE, timecents(z["release"])))
                    coarse = int(round(z["tune"] / 100.0))
                    fine = int(round(z["tune"] - coarse * 100))
                    if coarse:
                        g.append(gen(G_COARSE, coarse))
                    if fine:
                        g.append(gen(G_FINE, fine))
                    g.append(gen(G_ROOT, z["kc"]))
                    g.append(gen(G_SAMPLEID, sid))
                    igen.extend(g)
        inst.append(struct.pack("<20sH", pad_name("EOI"), len(ibag)))
        ibag.append(struct.pack("<HH", len(igen), 0))
        igen.append(gen(0, 0))
        imod = [b"\0" * 10]

        phdr, pbag, pgen = [], [], []
        for prog in sorted(presets):
            name, parts = presets[prog]
            phdr.append(struct.pack("<20sHHHIII", pad_name(name), prog, 1, len(pbag), 0, 0, 0))
            for stem, lo, hi in parts:
                if not plan.instruments.get(stem):
                    continue
                pbag.append(struct.pack("<HH", len(pgen), 0))
                if (lo, hi) != (0, 127):
                    pgen.append(gen(G_KEYRANGE, (lo, hi)))
                pgen.append(gen(G_INSTRUMENT, inst_index[stem]))
        phdr.append(struct.pack("<20sHHHIII", pad_name("EOP"), 0, 0, len(pbag), 0, 0, 0))
        pbag.append(struct.pack("<HH", len(pgen), 0))
        pgen.append(gen(0, 0))
        pmod = [b"\0" * 10]

        shdr_bytes = b"".join(
            struct.pack("<20sIIIIIBbHH", pad_name(s[0]), s[1], s[2], s[3], s[4], s[5], s[6], s[7], s[8], s[9])
            for s in shdr)
        pdta = b"pdta"
        pdta += chunk(b"phdr", b"".join(phdr))
        pdta += chunk(b"pbag", b"".join(pbag))
        pdta += chunk(b"pmod", b"".join(pmod))
        pdta += chunk(b"pgen", b"".join(pgen))
        pdta += chunk(b"inst", b"".join(inst))
        pdta += chunk(b"ibag", b"".join(ibag))
        pdta += chunk(b"imod", b"".join(imod))
        pdta += chunk(b"igen", b"".join(igen))
        pdta += chunk(b"shdr", shdr_bytes)
        out.write(chunk(b"LIST", pdta))
        end = out.tell()
        # patch sizes
        out.seek(4)
        out.write(struct.pack("<I", end - 8))
        # sdta LIST size: starts after INFO list; locate via smpl_start
        smpl_len = smpl_end - smpl_start
        out.seek(smpl_start - 4)
        out.write(struct.pack("<I", smpl_len))
        out.seek(smpl_start - 16)
        out.write(struct.pack("<I", smpl_len + 12))
    return end


def find_sfz_dir(root):
    for dirpath, _, files in os.walk(root):
        if any(f.endswith(".sfz") for f in files):
            return dirpath
    raise SystemExit("no .sfz files under " + root)


def main(argv):
    args = [a for a in argv if not a.startswith("--")]
    flags = [a for a in argv if a.startswith("--")]
    budget = 500
    for a in list(flags):
        if a.startswith("--budget-mb="):
            budget = int(a.split("=", 1)[1])
    if len(args) != 2:
        print(__doc__)
        return 2
    root = find_sfz_dir(args[0])
    out_path = args[1]
    needed = sorted({stem for _, parts in PRESETS.values() for stem, _, _ in parts})
    stereo = "--mono" not in flags
    plan = Planner(root, stereo)
    for stem in needed:
        p = os.path.join(root, stem + ".sfz")
        if not os.path.isfile(p):
            raise SystemExit("missing " + p)
        plan.build_instrument(stem, p)
    est = plan.stored_bytes() / 1048576.0
    print("planned %d samples, stereo estimate %.0f MB" % (len(plan.sample_list), est), file=sys.stderr)
    if "--stereo" not in flags and "--mono" not in flags and est > budget:
        plan.stereo = False
        print("over the %d MB budget, mixing to mono (%.0f MB)" % (budget, plan.stored_bytes() / 1048576.0),
              file=sys.stderr)
    print("converting ...", file=sys.stderr)
    size = write_sf2(plan, out_path, PRESETS)
    print("wrote %s (%.1f MB, %s)" % (out_path, size / 1048576.0, "stereo" if plan.stereo else "mono"))
    print()
    print("%-4s %-22s %s" % ("prog", "preset (bank 1)", "source .sfz"))
    for prog in sorted(PRESETS):
        name, parts = PRESETS[prog]
        print("%-4d %-22s %s" % (prog, name, " + ".join(s + ".sfz" for s, _, _ in parts)))
    print()
    print("not converted:", SKIPPED_NOTE)
    for msg, n in sorted(LOG.counts.items()):
        print("note: %s (x%d)" % (msg, n))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
