"""Harold's Jukebox: every band song by the id the game asks for, with what the checks need to know.

Each jb_*.py module lists its own songs in an INFO dict, {id: dict(key, bpm, meter, bars, about,
quiet?, loop?)}, with a function of the same name as the id. The ids are the game's own (see
MusicRules), so a jukebox song replaces the synth song of that id once it is chosen. Fields match
catalog.SONG_INFO. A module that fails to import is reported and skipped, so one song still being
written cannot stop the others rendering.
"""
import importlib

MODULES = ["jb_timeless", "jb_1950s", "jb_1960s", "jb_1970s", "jb_1980s", "jb_1990s", "jb_chairman"]

BAND_INFO = {}
BROKEN = {}
for _name in MODULES:
    try:
        _mod = importlib.import_module(_name)
    except ModuleNotFoundError as e:
        if e.name != _name:
            BROKEN[_name] = "%s: %s" % (type(e).__name__, e)
        continue
    except Exception as e:
        BROKEN[_name] = "%s: %s" % (type(e).__name__, e)
        continue
    for _id, _info in _mod.INFO.items():
        BAND_INFO[_id] = dict(_info, mod=_name)


def song(name):
    return getattr(importlib.import_module(BAND_INFO[name]["mod"]), name)
