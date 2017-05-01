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
local component = require("component")
local term = require ("term")

-- Configuration -----------------------------------------------------

-- step: run interval in seconds.
local step = 1

-- debug: print aditional debug info (usually at start).
local debug = true

-- Constants ---------------------------------------------------------
local storageName = "draconic_rf_storage"
local initDelay = 3

-- Functions ---------------------------------------------------------
function printDebugInfo ()
  print ("------------------------------------------")
  print ("Available components: ")
  for k, v in component.list() do
    print ("  ".. k, v)
  end
  print ("------------------------------------------")
end

function printCoreValuesRaw (address)
  print ("Trying to get proxy for "..address)
  local proxy = component.proxy(address)

  print ("MaxEnergyStored (RF raw) "..proxy.getMaxEnergyStored())
  print ("    EnergyStore (RF raw) "..proxy.getEnergyStored())
  print ("------------------------------------------")
end

function rfStorageLookup (storageName)
  print ("Trying to lookup address for " .. storageName .. "...")
  for address, componentName in component.list() do
    if componentName == storageName then
      print (storageName .. " found at address: "..address)
      return address
    end
  end
  print ("Address not found for " .. storageName)
  return nil
end

function formatNumber(number)
  local output = string.format("%.3f", number)
  local unitVal = {1000000000000, 1000000000, 1000000, 1000}
  local unit = {"T", "G", "M", "k"}

  for i = 1,4 do
    if number >= unitVal[i] then
      local x = number / unitVal[i]
      output = string.format("%.3f", x) .. unit[i]
      break
    end
  end
  return output
end

function init ()
  local address = nil
  if debug then
    printDebugInfo()
  end

  local gpu = term.gpu()
  gpu.setResolution(80, 25)

  address = rfStorageLookup (storageName)
  if address == nil then
    print ("Couldn't found required component address, exiting...")
    return nil, gpu
  end

  if debug then
    printCoreValuesRaw(address)
    print ("Waiting ".. initDelay .. " secs before starting...")
    os.sleep (initDelay)
  end

  print ("Starting up!, gathering initial values...")
  return address, gpu
end

function run ()
  local address, gpu = init ()
  if address == nil then
    return
  end

  local coreProxy = component.proxy(address)
  local lastEnergy = coreProxy.getEnergyStored()
  local maxEnergy = coreProxy.getMaxEnergyStored()
  term.clear()
  os.sleep (step)
  while true do
    term.setCursor(2, 1)
    term.clearLine()
    term.setCursor(2, 1)

    currentEnergy = coreProxy.getEnergyStored()
    local percent = currentEnergy / maxEnergy * 100.0
    term.write("Energy Core (RF): " ..
      formatNumber(currentEnergy) .. " / " ..
      formatNumber(maxEnergy) .. "   (" ..
      string.format("%.2f", percent) .. "%)")

    local energyChange = (currentEnergy - lastEnergy) / (20 * step)
    term.setCursor(2, 2)
    term.clearLine()
    term.setCursor(2, 2)
    if energyChange >= 0 then
      gpu.setForeground(0x00FF00)
    else
      gpu.setForeground(0xFF00FF)
    end
    term.write("    Energy Flow : " ..
      formatNumber(energyChange) ..
      " RF/t")
    gpu.setForeground(0xFFFFFF)

    lastEnergy = currentEnergy
    os.sleep(step)
  end
end


-- Main Program ------------------------------------------------------
run ()


