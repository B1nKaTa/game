# Lessons

- 2026-11-02: A signal connected to a lambda that captures self made a RefCounted cycle and printed exit-time leak warnings → connect the signal's own callable, like changed.emit, instead.
- 2026-11-02: Task 6 brief connected Player to health.died with a lambda capturing self, which the existing lesson forbids → copy briefs through LESSONS.md first and connect the signal's own callable (died.emit).
