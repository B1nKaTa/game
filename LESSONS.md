# Lessons

- 2026-11-02: A signal connected to a lambda that captures self made a RefCounted cycle and printed exit-time leak warnings → connect the signal's own callable, like changed.emit, instead.
- 2026-11-02: Task 6 brief connected Player to health.died with a lambda capturing self, which the existing lesson forbids → copy briefs through LESSONS.md first and connect the signal's own callable (died.emit).
- 2026-11-02: Piping tools/test.ps1 through tail hid its failing exit code during a RED check → read the summary line ("N tests, M failed") or keep the real exit code before piping.
- 2026-11-02: Passing bash-style /c/... paths into a PowerShell System.Drawing Save failed with a GDI+ error → use C:\ paths when PowerShell calls Windows .NET APIs.
