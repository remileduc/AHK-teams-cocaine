Keep Alive
==========

A small [AutoHotkey v2](https://www.autohotkey.com/) script that keeps you looking active. Presence-tracking apps such as Teams see a user who never goes idle, and the machine itself never sleeps, locks or turns off its display.

How it works
------------

- **Simulated activity.** Whenever you have been idle for about a minute, the script nudges the mouse by zero pixels. Windows registers this as real input and resets its idle timer, which is what Teams and similar apps read to decide whether you are away. The cursor does not move, and nothing is sent while you are actually working.
- **Stay awake.** As a bonus, the script asks Windows power management to keep the system and display on, so no sleep and no screen-off.

Both effects stop as soon as the script exits.

Usage
-----

Run `teams-cocaine.exe`. It sits in the system tray as a coffee cup, with no window. Right-click the icon for **Pause** (a checkmark shows while paused; double-clicking the icon toggles it too) or **Exit**.

If you have AutoHotkey v2 installed you can run `teams-cocaine.ahk` directly instead.

Building
--------

After editing `teams-cocaine.ahk`, double-click `build.cmd` to recompile `teams-cocaine.exe`. It requires AutoHotkey v2 with the Ahk2Exe compiler installed.

GitHub Actions builds the exe on every push with the current AutoHotkey v2 release from winget and the newest Ahk2Exe release from GitHub. Grab it from the workflow run artifacts, or from the [releases page](../../releases): pushing a `vX.Y.Z` tag that matches the `;@Ahk2Exe-SetVersion` line publishes a release with the exe attached.

License
-------

MIT, see [LICENSE](LICENSE).

The tray icon is "Hot beverage" from [Fluent Emoji](https://github.com/microsoft/fluentui-emoji) by Microsoft, also MIT licensed.
