# energy-monitor
OpenComputers Lua program to monitor a Draconic Energy Core. Comes with a text and
a graphic version.

[![Graphic version](https://github.com/OpenPrograms/luisau-Programs/tree/develop/src/energy-monitor/screenshots/energy-monitor-01.png)](https://github.com/OpenPrograms/luisau-Programs/tree/develop/src/energy-monitor/screenshots/energy-monitor-01.png)

## Features
- Text and Graphic version:
  - Current energy stored / Max energy capacity.
  - Percent indicator of stored energy.
  - Net energy flow of the core (positive or negative).
  - Supports for big amounts (format numbers up to Peta RF for easy reading).
  - Threshold configuration for a redstone signal output.
  - Signal output indicator.
- Graphic version:
  - Current energy stored progress bar indicator.
  - Energy flow histogram: Visually show energy flow values for a histogram. The amount of values stored is adjusted according to screen resolution. 
  - Automatic resize of histogram to show proportional values of positive and negative flow.
  - Low / High Peaks indicators

## Requirements
- Place an Adapter Block in contact with one of your Energy Pylons
- Connect the Adapter Block through cables to the computer
- Only tested with tier 3 computers and screens (3 wide x 2 high)
- A redstone card (tier 2) is required to emit a redstone signal when the threshold is reached (can be disabled in the config). This will work with redstone bundled cables/conduits only (has not been tested with vanilla redstone). The signal is emitted from the bottom of the computer by default.

## Install
```
oppm install energy-monitor
```

## Configuration
You will need to edit either **/usr/bin/energy-monitor-text** or **/usr/bin/energy-monitor-graphic** and adjust this settings
```
-- redstoneSide: Side to emit a redstone signal when the threshold is reached
-- nil to disable this feature (i.e.: local side = nil  )
local side = sides.bottom

-- threshold: Minimum threshold required to emit a redstone signal
-- Valid values: 1 to 100
local threshold = 75

-- step: Run interval in seconds.
local step = 1

-- debug: Print aditional debug info (usually at start).
local debug = true

-- name: Name of your Energy Core
local name = "Energy Core"
```

## Executable
```
energy-monitor
```

## Screenshots

### Graphic Version
[![Graphic version 02](https://github.com/OpenPrograms/luisau-Programs/tree/develop/src/energy-monitor/screenshots/energy-monitor-02.png)](https://github.com/OpenPrograms/luisau-Programs/tree/develop/src/energy-monitor/screenshots/energy-monitor-02.png)
[![Graphic version 03](https://github.com/OpenPrograms/luisau-Programs/tree/develop/src/energy-monitor/screenshots/energy-monitor-03.png)](https://github.com/OpenPrograms/luisau-Programs/tree/develop/src/energy-monitor/screenshots/energy-monitor-03.png)

## Exit codes
- **1** : Address for energy core not found, check your network cables and check that the EnergyPylon is connected to the computer through Adapter/Cables
