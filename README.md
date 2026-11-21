# memory_bar

memory_bar is a macOS menu bar item that shows the numbers of Activity Monitor's Memory tab,
plus the Mac's total CPU use. Its label is Memory Used and the Mac's total CPU use, colored by how much of the Mac's
memory is in use: green below half, yellow to seven eighths, red above. Its popup shows Memory Used with Physical Memory, Cached Files, Swap Used,
App Memory, Wired Memory, Compressed and Total CPU Used, then every process by
memory footprint, largest first, with a search field that filters by process name. It needs
no root: per-process footprints come from `proc_pid_rusage` for the user's own processes and
from `top` for the rest. `GLOSSARY.md` defines each number the way Activity Monitor does.

## Memory use record

The app samples Memory Used and the ten largest processes by Memory footprint about once a minute. It keeps the last 24 hours in `~/Library/Application Support/MemoryBar/memory-use.jsonl`, one JSON object per line, oldest first, capped at 2 MiB so the window outlives a restart without growing without bound.

Each line holds `time`, `memoryUsed`, `appMemory`, `wiredMemory`, `compressed` and `topProcesses` (`pid`, `name`, `footprintBytes`). A drop of several GB is a fall in `memoryUsed` between two lines; the processes in the earlier line's `topProcesses` that are smaller or missing in the later one are the processes that released it.

## Install

```sh
./install.sh
```

That builds the app with `swift build -c release`, installs it as
`~/Applications/MemoryBar.app`, signs it ad hoc, and loads the login job
`com.bradley-mankoff.memorybar` from `~/Library/LaunchAgents`, which opens it at login and
restarts it after a crash. It needs macOS 13 or later and a Swift toolchain
(`xcode-select --install`).

To remove it, run `launchctl bootout gui/$(id -u)/com.bradley-mankoff.memorybar`, then delete
`~/Applications/MemoryBar.app` and `~/Library/LaunchAgents/com.bradley-mankoff.memorybar.plist`.

## Tests

```sh
swift test
```

## Acknowledgements

memory_bar copies its numbers, names and layout from Apple's Activity Monitor, so that a
reading in the bar means what the same reading means there. It is not affiliated with Apple.

## License

MIT. See [LICENSE](LICENSE).
