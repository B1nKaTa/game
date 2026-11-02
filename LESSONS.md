# Lessons

- 2026-11-02: A signal connected to a lambda that captures self made a RefCounted cycle and printed exit-time leak warnings → connect the signal's own callable, like changed.emit, instead.
