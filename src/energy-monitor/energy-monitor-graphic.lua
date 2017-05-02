--------------------------------------------------------------------------------
-- energy-monitor v0.1 by luisau
-- OpenComputers program to monitor a single Draconic Evolution Energy Core.
--
-- Requirements:
--    - Place an Adapter Block in contact with one of your Energy Pylons
--    - Connect the Adapter Block through cables to the computer
--    - Only tested with tier 3 computers.
-- Install:
--    oppm install energy-monitor
-- Feedback:
--    Contact me through Discord app: luisau#0826
-- Repository:
--    https://github.com/lpenap/oc-energy-monitor
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
local initDelay = 1

--------------------------------------------------------------------------------
-- Prints the current energy values
--------------------------------------------------------------------------------
function printEnergy (core, term)
  local gpu = term.gpu()
  local w, h = gpu.getResolution()
  gpu.fill(1,1,w,h, " ")
  local startX = 1
  local startY = 1
  term.setCursor(startX, startY)
  term.clearLine()
  term.setCursor(startX, startY)
  term.write (name .." [energy-monitor v0.1]")
  gpu.setBackground(0xFF0000)
  gpu.fill (startX, startY+1, w, 3, " ")
  local currentWidth = math.ceil (core:getLastPercentStored() * w / 100)

  gpu.setBackground(0x00FF00)
  gpu.fill (startX, startY+1, currentWidth, 3, " ")

  gpu.setForeground(0x000000)
  if currentWidth < (w - 10) then
    gpu.setBackground(0xFF0000)
    term.setCursor(currentWidth+2, startY+2)
  else
    gpu.setBackground(0x00FF00)
    term.setCursor(w - 16, startY+2)
  end
  term.write (string.format("%.2f", core:getLastPercentStored()) .. "%")

  --  gpu.setBackground(0x00FF00)
  --  gpu.fill (startX, startY+1, currentWidth, 3, " ")


  gpu.setBackground(0x000000)
  gpu.setForeground(0xFFFFFF)
  term.setCursor (startX, startY+4)
  term.write (formatNumber(core:getLastEnergyStored()) .. " / " ..
    formatNumber(core:getMaxEnergyStored()))
end

--------------------------------------------------------------------------------
-- Prints the change on energy levels
--------------------------------------------------------------------------------
function printEnergyChange (change, term)
  term.setCursor(2, 10)
  term.clearLine()
  term.setCursor(2, 10)
  local gpu = term.gpu()
  if change >= 0 then
    gpu.setForeground(0x00FF00)
  else
    gpu.setForeground(0xFF00FF)
  end
  term.write("    Energy Flow : " .. formatNumber(change) .." RF/t")
  gpu.setForeground(0xFFFFFF)
end

--------------------------------------------------------------------------------
-- Updates values on screen continuously (until interrupted)
--------------------------------------------------------------------------------
function run ()
  local core, term, component =
    init (storageName, "graphic", debug, initDelay)

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
