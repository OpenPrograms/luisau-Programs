local component = require("component")
local term = require ("term")

EnergyCore = {}
EnergyCore.__index = EnergyCore

function EnergyCore:create(coreProxy)
  local _core ={}
  setmetatable (_core, EnergyCore)
  _core.proxy = coreProxy
  _core.lastTicks = getCurrentTicks ()
  _core.lastEnergyStored = coreProxy.getEnergyStored()
  _core.percent = _core.lastEnergyStored / coreProxy.getMaxEnergyStored() * 100.0
  return _core
end

function EnergyCore:getLastTicks()
  return self.lastTicks
end

function EnergyCore:getMaxEnergyStored()
  return self.proxy.getMaxEnergyStored()
end

function EnergyCore:getEnergyStored()
  return self.proxy.getEnergyStored()
end

function EnergyCore:getLastEnergyStored()
  return self.lastEnergyStored
end

function EnergyCore:getEnergyChange()
  local currentEnergy = self.proxy.getEnergyStored()
  local currentTicks = getCurrentTicks ()
  local change = (currentEnergy - self.lastEnergyStored) / (currentTicks - self.lastTicks)
  self.lastEnergyStored = currentEnergy
  self.lastTicks = currentTicks
  self.percent = currentEnergy / self.proxy.getMaxEnergyStored() * 100.0
  return change
end

function EnergyCore:getLastPercentStored()
  return self.percent
end

function EnergyCore:getCurrentPercentStored()
  return self.proxy.getEnergyStored() / self.proxy.getMaxEnergyStored() * 100.0
end

function getCurrentTicks ()
  return ((os.time() * 1000) / 60 /60) - 6000
end

function printComponentList ()
  print ("Available components: ")
  for k, v in component.list() do
    print ("  ".. k, v)
  end
  print ("------------------------------------------")
  print()
end

function printCoreValuesRaw (core)
  print ("MaxEnergyStored (RF raw) ".. core.getMaxEnergyStored())
  print ("    EnergyStore (RF raw) ".. core.getEnergyStored())
  print ("------------------------------------------")
  print()
end

function rfStorageLookup (storageName)
  local addressFound = nil
  print ("Trying to lookup address for " .. storageName .. "...")
  for address, componentName in component.list() do
    if componentName == storageName then
      print (storageName .. " found at address: "..address)
      addressFound = address
      break
    end
  end
  if addressFound == nil then
    print ("Address not found for " .. storageName)
  end
  print ("------------------------------------------")
  print()
  return addressFound
end

function resetScreen (mode)
  local gpu = term.gpu()
  local maxW, maxH = gpu.maxResolution()

  if mode == "text" then
    gpu.setResolution(math.max(80, maxW), math.max(25, maxH))
  else
    -- set max res and depth for graphic mode
    local gpu = term.gpu()
    gpu.setResolution (maxW, maxH)

    local maxDepth = gpu.maxDepth()
    gpu.setDepth(maxDepth)
  end

  local w, h = gpu.getResolution()
  gpu.fill(1, 1, w, h, " ")
  gpu.setBackground(0x000000)
  gpu.setForeground(0xFFFFFF)
  return gpu
end

function formatNumber(number)
  local output = string.format("%.3f", number)
  local unitVal = {1000000000000000, 1000000000000, 1000000000, 1000000, 1000}
  local unit = {"P", "T", "G", "M", "k"}

  for i = 1,4 do
    if number >= unitVal[i] then
      local x = number / unitVal[i]
      output = string.format("%.3f", x) .. unit[i]
      break
    end
  end
  return output
end

function init (storageName, mode, debug, initDelay)
  local gpu = resetScreen(mode)

  if debug then
    printComponentList()
  end

  local address = rfStorageLookup (storageName)
  if address == nil then
    print ("Couldn't find required component address, exiting...")
    return nil, term, component
  end
  local proxy = component.proxy(address)
  local core = EnergyCore.create(proxy)

  if debug then
    printCoreValuesRaw(core)
  end

  print ("Waiting ".. initDelay .. " secs before starting...")
  os.sleep (initDelay)

  return core, term, component
end
