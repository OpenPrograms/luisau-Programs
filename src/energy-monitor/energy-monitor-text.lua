--[[
  oc-energy-monitor v0.1 by luisau
  OpenComputers program to monitor a single
  Draconic Evolution Energy Core.

  Requirements:
    - Place an Adapter Block in contact with one of your Energy Pylons
    - Connect the Adapter Block through cables to the computer
    - Only tested with tier 3 computers.
  Install:
    oppm install oc-energy-monitor
  Executables:
    energy-monitor-text     Text only monitor.
    energy-monitor-graphic  Graphic histogram version.
  Feedback:
    Contact me through Discord app.
  Repository:
    https://github.com/lpenap/oc-energy-monitor
]]

require("energy-monitor-lib")

-- Configuration -----------------------------------------------------

-- step: run interval in seconds.
local step = 1

-- debug: print aditional debug info (usually at start).
local debug = true

-- Constants ---------------------------------------------------------
local storageName = "draconic_rf_storage"
local initDelay = 10

-- Functions ---------------------------------------------------------

function printEnergy (core, term)
  term.setCursor(2, 1)
  term.clearLine()
  term.setCursor(2, 1)
  term.write("Energy Core (RF): " ..
    formatNumber(core.getLastEnergyStored()) .. " / " ..
    formatNumber(core.getMaxEnergyStored()) .. "   (" ..
    string.format("%.2f", core.getLastPercentStored()) .. "%)")
end

function printEnergyChange (change, term)
  term.setCursor(2, 2)
  term.clearLine()
  term.setCursor(2, 2)
  local gpu = term.gpu()
  if change >= 0 then
    gpu.setForeground(0x00FF00)
  else
    gpu.setForeground(0xFF00FF)
  end
  term.write("    Energy Flow : " .. formatNumber(change) .." RF/t")
  gpu.setForeground(0xFFFFFF)
end

function run ()
  local core, term, component =
    init (storageName, "text", debug, initDelay)

  if core == nil then
    return 1
  end

  term.clear()
  os.sleep (step)
  while true do
    local energyChange = core.getEnergyChange()
    printEnergy (core, term)
    printEnergyChange (energyChange, term)
    os.sleep(step)
  end
end


-- Main Program ------------------------------------------------------
local exitCode = run ()
if exitCode ~= 0 then
  print ("An internal error occurred. Exit code ".. exitCode)
end

