--------------------------------------------------------------------------------
-- energy-monitor v0.1 by luisau
-- OpenComputers program to monitor a single Draconic Evolution Energy Core.
--
-- Requirements:
--    - Place an Adapter Block in contact with one of your Energy Pylons
--    - Connect the Adapter Block through cables to the computer
--    - Only tested with tier 3 computers and screen.
-- Install:
--    oppm install energy-monitor
-- Feedback:
--    Contact me through Discord app: luisau#0826
-- Repository:
--    https://github.com/lpenap/open-computers-programs
--------------------------------------------------------------------------------

require("energy-monitor-lib")

--------------------------------------------------------------------------------
-- Configuration
--------------------------------------------------------------------------------

-- step: run interval in seconds.
local step = 1

-- debug: print aditional debug info (usually at start).
local debug = true

-- name: Name of your Energy Core
local name = "Energy Core"

--------------------------------------------------------------------------------
-- Constants
--------------------------------------------------------------------------------
local storageName = "draconic_rf_storage"
local initDelay = 10
local startX = 1
local startY = 1

--------------------------------------------------------------------------------
-- Prints the current energy values
--------------------------------------------------------------------------------
function printEnergy (core, term)
  local gpu = term.gpu()
  local width, height = gpu.getResolution()
  printHeader (term, startX, startY, name, width)
  term.setCursor(startX + 1, startY + 1)
  term.clearLine()
  term.setCursor(startX + 1, startY + 1)
  gpu.setForeground (0xFFFFFF)
  term.write("         Energy : " ..
    formatNumber(core:getLastEnergyStored()) .. " / " ..
    formatNumber(core:getMaxEnergyStored()) .. "   (" ..
    string.format("%.2f", core:getLastPercentStored()) .. "%)")
end

--------------------------------------------------------------------------------
-- Prints the change on energy levels
--------------------------------------------------------------------------------
function printEnergyChange (change, term)
  term.setCursor(startX + 1, startY + 2)
  term.clearLine()
  term.setCursor(startX + 1, startY + 2)
  local gpu = term.gpu()
  if change >= 0 then
    gpu.setForeground(0x00FF00)
  else
    gpu.setForeground(0xFF00FF)
  end
  term.write(getRotatingBarChar () .. 
    "   Energy Flow : " .. formatNumber(change) .." RF/t")
end

--------------------------------------------------------------------------------
-- Updates values on screen continuously (until interrupted)
--------------------------------------------------------------------------------
function run ()
  local core, term, component =
    init (storageName, "text", debug, initDelay)

  if core == nil then
    return 1
  end

  term.clear()
  os.sleep (step)
  while true do
    local energyChange = core:getEnergyChange()
    printEnergy (core, term)
    printEnergyChange (energyChange, term)
    os.sleep(step)
  end
end


--------------------------------------------------------------------------------
-- Main Program
--------------------------------------------------------------------------------
local exitCode = run ()
if exitCode ~= 0 then
  print ("An internal error occurred. Exit code ".. exitCode)
end

