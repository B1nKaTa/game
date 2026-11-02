# Lessons

- 2026-11-02: A signal connected to a lambda that captures self made a RefCounted cycle and printed exit-time leak warnings → connect the signal's own callable, like changed.emit, instead.
- 2026-11-02: Task 6 brief connected Player to health.died with a lambda capturing self, which the existing lesson forbids → copy briefs through LESSONS.md first and connect the signal's own callable (died.emit).
- 2026-11-02: Piping tools/test.ps1 through tail hid its failing exit code during a RED check → read the summary line ("N tests, M failed") or keep the real exit code before piping.
- 2026-11-02: Passing bash-style /c/... paths into a PowerShell System.Drawing Save failed with a GDI+ error → use C:\ paths when PowerShell calls Windows .NET APIs.
- 2026-11-02: The opening's full-screen ColorRect (default mouse_filter STOP) swallowed mouse clicks so _unhandled_input never saw `attack` → set mouse_filter = IGNORE on decorative full-screen Controls (backgrounds, hints) that sit over scenes using _unhandled_input.
- 2026-11-02: Setting global_position on a Node2D before add_child set the local position instead, so a thrown cane spawned far outside the room → add the node to the tree first, then set global_position.
- 2026-11-02: A physics probe must put the arena where the headless mouse (0,0) lies in the aim direction, since the player aims at the mouse → offset the arena instead of faking input.
- 2026-11-02: A thrown cane measured its flight from 32-bit Vector2 positions, so rounding stalled it just short of its range and it never dropped → track distance in a float and never use position deltas to decide when movement ends.
- 2026-11-02: A parse error in tools/smoke_driver.gd (a stray form feed from a PowerShell escape) made tools/smoke.ps1 hang forever instead of failing, because the autoload failed to create the driver → if smoke runs far past its usual minute, run Godot directly with output redirected and read the first error; and in PowerShell strings use `n and `t, never a backtick before f.
- 2026-11-02: Engine.time_scale = 0 still runs physics ticks, only their delta becomes 0, so a probe counting physics frames wrongly showed no freeze → measure a freeze by summing _physics_process delta, and time hit stop with Time.get_ticks_usec in _process.
- 2026-11-02: A flying coin that pays on arrival can be lost when the room is freed or the player dies mid-flight → pay when the flight starts and make the flight cosmetic.
- 2026-11-02: Decorative nodes under a room that is set to PROCESS_MODE_DISABLED at run end freeze mid-animation → give effects like DeathBurst process_mode ALWAYS.
