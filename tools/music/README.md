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
