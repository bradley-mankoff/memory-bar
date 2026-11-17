# memory_bar

macOS menu bar app that shows memory pressure and per process memory use, modeled on usage-bar. The Boss wants Activity Monitor reduced to memory only in the menu bar.

Status: new repo, private remote, awaiting Project Manager spec and scaffold.

## Memory use record

The app samples Memory Used and the ten largest processes by Memory footprint about once a minute. It keeps the last 24 hours in `~/Library/Application Support/MemoryBar/memory-use.jsonl`, one JSON object per line, oldest first, capped at 2 MiB so the window outlives a restart without growing without bound.

Each line holds `time`, `memoryUsed`, `appMemory`, `wiredMemory`, `compressed` and `topProcesses` (`pid`, `name`, `footprintBytes`). A drop of several GB is a fall in `memoryUsed` between two lines; the processes in the earlier line's `topProcesses` that are smaller or missing in the later one are the processes that released it.
