# Music

The game's music is written as notes in Python and rendered to WAV files with the standard library
only. The WAVs are large, so they are not in git: render them before playing or exporting, from the
project folder:

```
py tools/music/render.py audio/music
```

That writes every song to `audio/music/<id>.wav` (about two and a half minutes on a desktop). Open
the project in Godot once afterwards, or run `--headless --path . --import`, so the new files are
imported. Without them the game runs fine, only silently.

To render just some songs, name them: `py tools/music/render.py audio/music please_hold landing`.

## Checking a render

```
py tools/music/check.py audio/music
```

prints each song's length, peak, loudness range, stereo width and loop seam, and fails a song that
clips, drops into a hole, sits in mono, or jumps at the loop point. Every melody's bars are counted
while it renders, so a miscounted bar stops the render with its number.

`py tools/music/harmony.py` renders nothing and takes seconds: it lists long melody notes that rub a
semitone against the chords under them. A few are meant; many in one song usually mean a chord list
written in the wrong order.

## The files

- `synth.py`: the instruments, drums, reverb and the `Song` that mixes and writes a loop.
- `kit.py`: shorthand for melodies (`"C5:.5 A4 C5 F5:1.5 | ..."`), chords, comping, bass and drums.
- `songs.py`: Please Hold (the main theme) and Final Arrangements, with its second take kept.
- `places.py`, `fights.py`, `endings.py`: the rest of the soundtrack.
- `catalog.py`: every song by the id the game asks for, with its key and tempo.

Which song plays where is `MusicRules` (`scripts/core/music_rules.gd`); `MusicPlayer` plays it.

## Harold's Jukebox (real instruments)

A second set of songs is played by sampled instruments instead of the synth: `band.py` records a
song's notes, writes MIDI and renders it with FluidSynth through SoundFonts. The soundtrack's idea is
Harold's life on a jukebox: each depth is the next decade (1950s to 1990s), every path keeps its joke
in that decade's style, and Harold's whistle carries the hold theme (`jb_theme.py`) through all of it.

```
py tools/music/render_band.py <out_dir> [song ...]
```

renders and checks the `jb_*.py` songs listed in `jukebox.py`, by the game's own song ids. It needs,
outside the project (paths in `band.py`, or the environment variables it names):

- FluidSynth 2.6.2 for Windows (the release zip, not the source),
- GeneralUser GS (`GeneralUser-GS.sf2`; free for commercial use),
- optionally the VSCO 2 Community Edition orchestra (CC0), converted once with
  `py tools/music/sfz2sf2.py <vsco_root> <out.sf2>`; without it, `orch_*` parts use General MIDI.

The jukebox songs are not wired into the game yet: they render to a listening folder until chosen.
