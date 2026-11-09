# memory_bar

A macOS menu bar app that shows memory load and total CPU load from Activity Monitor.

## Language

**Memory Used**:
Total RAM now in use, equal to App Memory plus Wired Memory plus Compressed.
_Avoid_: Used

**Physical Memory**:
Total RAM installed on the Mac.
_Avoid_: Total memory

**App Memory**:
RAM used by apps and their data.
_Avoid_: App

**Wired Memory**:
RAM locked by the system that cannot be paged out.
_Avoid_: Wired

**Compressed**:
RAM compressed by the system to fit more into physical memory.
_Avoid_: Compressed memory

**Cached Files**:
RAM holding recently used files for fast reuse.
_Avoid_: Cache, File Cache

**Swap Used**:
Disk space used as overflow when RAM is full.
_Avoid_: Swap

**Memory Pressure**:
How hard the Mac works to manage RAM, shown as a graph with green, yellow, and red zones.
_Avoid_: Pressure

**Process Name**:
The name of a running process as Activity Monitor shows it.
_Avoid_: Process, app name

**Memory footprint**:
Physical RAM used by one process, the value in the Activity Monitor Memory column.
_Avoid_: RSS, memory size

**Total CPU Used**:
Share of CPU capacity now in use, equal to System plus User, which is 100 minus Idle.
_Avoid_: CPU, load, cores in use

**Total cores**:
The number of CPU cores reported by the system.
_Avoid_: Cores, CPUs

**Bar label**:
Text in the menu bar when the popup is closed, showing used memory, a middle dot, and Total CPU Used.
_Avoid_: Title, label

**Search field**:
A text box that filters the process list by case insensitive substring on Process Name.
_Avoid_: Search, filter
