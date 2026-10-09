#Requires AutoHotkey v2.0
#SingleInstance Force
#Warn

; Metadata baked into teams-cocaine.exe by Ahk2Exe (Explorer > Properties > Details).
;@Ahk2Exe-SetName Keep Alive
;@Ahk2Exe-SetDescription Keeps presence apps showing you as active and the PC awake
;@Ahk2Exe-SetVersion 1.0.1
;@Ahk2Exe-SetCopyright Copyright (c) 2026 Rémi Ducceschi - MIT License
;@Ahk2Exe-SetMainIcon coffee.ico

; Keeps you looking active, in two complementary ways:
;  1. A zero-pixel mouse nudge resets the user-input idle timer, which is what
;     presence apps (e.g. Teams) and inactivity lock policies look at. It only
;     fires once you have been idle, so it never injects input while you work.
;  2. SetThreadExecutionState tells Windows power management that the system
;     and display are required, which blocks sleep and display-off.
; Both can be paused and resumed together from the tray menu.

ES_CONTINUOUS       := 0x80000000
ES_SYSTEM_REQUIRED  := 0x00000001
ES_DISPLAY_REQUIRED := 0x00000002

NUDGE_INTERVAL_MS := 60000   ; how often the timer checks
IDLE_THRESHOLD_MS := 50000   ; only nudge if no input for this long

; Required: while paused there is no timer, hotkey or window left, and without
; this call AutoHotkey would treat the script as finished and exit.
Persistent()

; The compiled exe carries the icon; when run as a script, load it from disk if present.
if (!A_IsCompiled && FileExist(A_ScriptDir "\coffee.ico"))
    TraySetIcon(A_ScriptDir "\coffee.ico")

; Tray menu: a Pause toggle (checked while paused) and Exit. Double-click toggles Pause.
A_TrayMenu.Delete()
A_TrayMenu.Add("Pause", TogglePause)
A_TrayMenu.Add()
A_TrayMenu.Add("Exit", (*) => ExitApp())
A_TrayMenu.Default := "Pause"

OnExit((*) => SetActive(false))
SetActive(true)

; Turns both mechanisms on or off together.
SetActive(on) {
    flags := ES_CONTINUOUS | (on ? ES_SYSTEM_REQUIRED | ES_DISPLAY_REQUIRED : 0)
    DllCall("kernel32\SetThreadExecutionState", "UInt", flags)
    SetTimer(KeepAwake, on ? NUDGE_INTERVAL_MS : 0)
    A_IconTip := "Keep Alive - " (on ? "running" : "paused")
}

TogglePause(*) {
    static paused := false
    paused := !paused
    SetActive(!paused)
    if paused
        A_TrayMenu.Check("Pause")
    else
        A_TrayMenu.Uncheck("Pause")
}

KeepAwake() {
    if (A_TimeIdle >= IDLE_THRESHOLD_MS)
        MouseMove(0, 0, 0, "R")
}
