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

local component = require("component")
local term = require ("term")
local side = require ("sides")
local color = require ("color")
local event = require ("event")

-- Menu array and index
local menuOptions = {"x"}
local menuIndexExit = 1

local running = true

-- Event registry
event.listen("key_up", handleEvent)
event.listen("interrupted", handleEvent)
--------------------------------------------------------------------------------
-- Class to handle energy core values
--------------------------------------------------------------------------------
EnergyCore = {
  proxy = nil,
  lastTicks = 0,
  lastEnergyStored = 0,
  percent = 0,
  threshold = 75,
  signalActive = false
}

function EnergyCore:create(address, threshold)
  _core ={}
  setmetatable (_core, self)
  self.__index = self
  self.proxy = component.proxy(address)
  self.lastTicks = getCurrentTicks ()
  self.lastEnergyStored = self.proxy.getEnergyStored()
  self.percent = self.lastEnergyStored / self.proxy.getMaxEnergyStored() * 100.0
  self.threshold = threshold
  self.signalActive = false
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

function EnergyCore:getThreshold()
  return self.threshold
end

function EnergyCore:isSignalActive()
  return self.signalActive
end

function EnergyCore:setSignal(active)
  self.signalActive = active
end

--------------------------------------------------------------------------------
-- Class to handle energy histogram
--------------------------------------------------------------------------------
Histogram = {
  term = nil,
  highPeak = 1,
  lowPeak = -1,
  history = {},
  startX = 1,
  startY = 1,
  lastX = 1,
  zeroHeight = 1
}

function Histogram:create (term, startX, startY)
  o = {}
  setmetatable (o, self)
  self.__index = self

  self.term = term
  self.highPeak = 0
  self.lowPeak = 0
  self.history = {}
  self.startX = startX
  self.startY = startY
  self.lastX = 1
  self.zeroHeight = 1

  return o
end

function Histogram:render (energyChange)
  -- detect max size available to show history
  local gpu = self.term.gpu()
  local w, h = gpu.getResolution()
  local maxW = w - self.startX
  local maxH = h - self.startY - 3

  -- add energy change and remove older values that doesn't fit
  if self.lastX <= maxW then
    self.history[self.lastX] = energyChange
    self.lastX = self.lastX + 1
  else
    while self.lastX > maxW do
      -- if screen res changed reduce the history to fit
      table.remove(self.history, 1)
      self.lastX = self.lastX - 1
    end
    self.history[self.lastX] = energyChange
    self.lastX = self.lastX + 1
  end

  -- update peaks
  self.lowPeak, self.highPeak = getLowHigh(self.history, self.lastX-1)

  -- debugHistory (self.history, self.startX, self.lastX,
  --    self.lowPeak, self.highPeak, self.term)

  -- adjust histogram X axis
  local energyHeight = self.highPeak + math.abs(self.lowPeak)

  local axisPercent = self.highPeak / energyHeight
  self.zeroHeight = math.floor (maxH * axisPercent)

  -- print energy change
  self.term.setCursor (self.startX, self.startY)
  gpu.setBackground (0x000000)
  if energyChange >= 0 then
    gpu.setForeground(0x00FF00)
  else
    gpu.setForeground(0xFF00FF)
  end
  self.term.write (getRotatingBarChar() ..
    " Energy Flow: " .. formatNumber(energyChange) .." RF/t")

  -- print high peak and low peak
  gpu.setForeground(0xBBBBBB)
  local high = formatNumber (self.highPeak)
  local low = formatNumber (self.lowPeak)
  self.term.setCursor (w - string.len (high) - 11, self.startY)
  self.term.write ("High: ".. high .. " RF/t")
  self.term.setCursor (w - string.len (low) - 10, h )
  self.term.write ("Low: ".. low .. " RF/t")

  -- render histogram
  gpu.fill (self.startX, self.startY + 1,
    w - self.startX, h - self.startY - 1, " ")
  gpu.setBackground(0xBBBBBB)
  gpu.fill (self.startX, self.startY + self.zeroHeight+1, maxW, 1, " ")
  for i=1, self.lastX-1 do
    if self.history[i] > 0 then
      local columnHeight = math.ceil (
        (self.history[i] / self.highPeak) * self.zeroHeight)
      gpu.setBackground (0x00BB00)
      gpu.fill (self.startX+i-1, self.startY+(self.zeroHeight-columnHeight)+1,
        1, columnHeight, " ")
    elseif self.history[i] < 0 then
      local columnHeight = math.ceil(
        math.abs(self.history[i] / self.lowPeak) * (maxH - self.zeroHeight))
      gpu.setBackground (0xBB0000)
      gpu.fill (self.startX+i-1, self.startY+self.zeroHeight+2,
        1, columnHeight, " ")
    else
      gpu.setForeground (0x000000)
      gpu.setBackground(0xBBBBBB)
      self.term.setCursor (self.startX+i-1, self.startY+self.zeroHeight+1)
      self.term.write ("-")
    end -- if
  end -- for
  gpu.setBackground(0x000000)
end -- function Histogram:render

--------------------------------------------------------------------------------
-- Checks threshold and emits redstone signal
--------------------------------------------------------------------------------
function checkThreshold (term, core, startX, side)
  if side ~= nil then
    local gpu = term.gpu()

    if core:isSignalActive() then
      -- turn off if we are at 100%
      if core:getLastPercentStored() == 100 then
        core:setSignal (false)
        emitRedstoneSitnal (side, false)
      end
    else
      -- turn on if we reached below the threshold
      if core:getLastPercentStored() < core:getThreshold() then
        core:setSignal (true)
        emitRedstoneSitnal (side, true)
      end
    end

    local thresholdText = "[ Signal Inactive ]"
    local thresholdText2 = "set: "..core:getThreshold().. "%+"
    gpu.setForeground (0xFF0000)
    gpu.setBackground (0x000000)

    if core:isSignalActive() then
      thresholdText = "[ Signal Active ]"
      gpu.setForeground (0x000000)
      gpu.setBackground (0xFF0000)
    end

    local w, h = gpu.getResolution()
    term.setCursor (startX, h)
    term.write (thresholdText)

    gpu.setForeground (0xBBBBBB)
    gpu.setBackground (0x000000)
    term.setCursor (startX + 20, h)
    term.write (thresholdText2)
  end -- if side ~= nil
end

function emitRedstoneSignal (side, turnOn)
  if side ~= nil then
    local address = componentLookup("redstone", false)
    if address ~= nil then
      local proxy = component.proxy(address)
      local value = 0
      if turnOn then
        value = 255
      end
      proxy.setBundledOutput (side, color.red, value)
    end
  end -- if side ~= nil
end

--------------------------------------------------------------------------------
-- Prints the application header
--------------------------------------------------------------------------------
function printHeader(term, x, y, name, maxX)
  local gpu = term.gpu()
  term.setCursor(x, y)
  term.clearLine()
  term.setCursor(x, y)
  gpu.setForeground(0xFFFFFF)
  term.write (name)
  local credits = "[energy-monitor v0.1]"
  term.setCursor (maxX - string.len(credits), y)
  gpu.setForeground (0xBBBBBB)
  term.write (credits)
end

--------------------------------------------------------------------------------
-- Gets the next step of a rotating text bar (single character work indicator)
--------------------------------------------------------------------------------
local rotatingBar = {"-", "\\", "|", "/"}
local rotatingBarIndex = 1
function getRotatingBarChar ()
  local currentChar = rotatingBar[rotatingBarIndex]
  if rotatingBarIndex == 4 then
    rotatingBarIndex = 1
  else
    rotatingBarIndex = rotatingBarIndex + 1
  end
  return currentChar
end

--------------------------------------------------------------------------------
-- Debug function to print history values
-- Use this instead of painting bars while for debugging
--------------------------------------------------------------------------------
function debugHistory (history, startX, lastX, lowPeak, highPeak, term)
  local toShowBegin = 1
  if lastX-1 > 10 then
    toShowBegin = lastX - 10
  end

  term.setCursor (startX, 8)
  term.write ("history size: ".. lastX .. " ".. lowPeak .. " - ".. highPeak)
  local beginLine = 9
  for i  = toShowBegin, lastX-1 do
    term.setCursor (startX, beginLine)
    beginLine = beginLine + 1
    term.write(i .. " : ".. formatNumber(history[i]).." RF/t")
  end
end

--------------------------------------------------------------------------------
-- Gets the lowest and highest value from an array
--------------------------------------------------------------------------------
function getLowHigh (array, size)
  local low, high = 0, 0
  for i = 1, size do
    if array[i] == nil then
      break
    end
    if array[i] > high then
      high = array[i]
    end
    if array[i] < low then
      low = array[i]
    end
  end
  return low, high
end

--------------------------------------------------------------------------------
-- Gets the current tick
--------------------------------------------------------------------------------
function getCurrentTicks ()
  return ((os.time() * 1000) / 60 /60) - 6000
end

--------------------------------------------------------------------------------
-- Prints the available components (debug info)
--------------------------------------------------------------------------------
function printComponentList ()
  print ("Available components: ")
  for k, v in component.list() do
    print ("  ".. k, v)
  end
  print ("------------------------------------------")
  print()
end

--------------------------------------------------------------------------------
-- Prints raw energy core values (debug info)
--
-- @param core EnergyCore instance
--------------------------------------------------------------------------------
function printCoreValuesRaw (core)
  print ("MaxEnergyStored (RF raw) ".. core:getMaxEnergyStored())
  print ("    EnergyStore (RF raw) ".. core:getEnergyStored())
  print ("------------------------------------------")
  print()
end

--------------------------------------------------------------------------------
-- Finds the address of a component
--
-- @param storageName Name of the component
--
-- @return The address of the component as string
--------------------------------------------------------------------------------
function componentLookup (componentName, debug)
  if debug then
    print ("Trying to lookup address for " .. componentName .. "...")
  end
  for address, name in component.list() do
    if name == componentName then
      if debug then
        print (componentName .. " found at address: "..address)
        print ("------------------------------------------")
      end
      return address
    end
  end
  if debug then
    print ("Address lookup failed for component "..componentName)
    print ("------------------------------------------")
    print()
  end
  return nil
end

--------------------------------------------------------------------------------
-- Resets the screen for a given mode
--
-- @param mode It could be "text" or "graphic".
--
-- @return The gpu API instance.
--------------------------------------------------------------------------------
function resetScreen (mode)
  local gpu = term.gpu()
  local maxW, maxH = gpu.maxResolution()

  if mode == "text" then
    gpu.setResolution(math.min(80, maxW), math.min(25, maxH))
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

--------------------------------------------------------------------------------
-- Formats a number with proper MKS unit prefix
--
-- @params  number The number to format.
--
-- @return The formated number as string with unit prefix.
--------------------------------------------------------------------------------
function formatNumber(number)
  local output = string.format("%.2f", number)
  local unitVal = {1000000000000000, 1000000000000, 1000000000, 1000000, 1000}
  local unit = {"P", "T", "G", "M", "k"}
  local units = 5

  local toConvert = math.abs(number)
  local sign = ""

  for i = 1, units do
    if toConvert >= unitVal[i] then
      local x = toConvert / unitVal[i]
      if number < 0 then
        sign = "-"
      end
      output = sign .. string.format("%.2f", x) .. unit[i]
      break
    end
  end

  return output
end

--------------------------------------------------------------------------------
-- Initializes the energy monitor program
--
-- @param storageName Component name to lookup;
--         use draconic_rf_storage for DE EnergyCore.
-- @param mode "text" or "graphics" used to properly initialize the screen.
-- @param debug If true, prints additional info.
-- @param initDelay Initial delay prior to main cycle start.
-- @param threshold Minimum energy level required to start emiting a redstone
--         signal.
--
-- @return  core An EnergyCore data structure instance.
-- @return  term Instance of term API.
-- @return  component Instance of component API.
--------------------------------------------------------------------------------
function init (storageName, mode, debug, initDelay, threshold)
  local gpu = resetScreen(mode)

  if debug then
    printComponentList()
  end

  local address = componentLookup (storageName, true)
  if address == nil then
    print ("Couldn't find required component address, exiting...")
    return nil, term, component
  end
  local core = EnergyCore:create(address, threshold)

  if debug then
    printCoreValuesRaw(core)
  end

  print ("Waiting ".. initDelay .. " secs before starting...")
  os.sleep (initDelay)

  return core, term, component
end

function isRunning()
  return running
end

function cleanUp()
  gpu.setForeground (0xFFFFFF)
  gpu.setBackground (0x000000)
end

function handleEvent(eventID, ...)
  if (eventID) then
    energyLibEventHandlers[eventID](...)
  end
end

function unknownEvent()
-- do nothing if the event wasn't relevant
end

-- table that holds all event handlers
-- in case no match can be found returns the dummy function unknownEvent
local energyLibEventHandlers = setmetatable({},
  {
    __index = function()
      return unknownEvent
    end
  })

function energyLibHandlers.key_up(adress, char, code, playerName)
  if (char == menuOptions[menuIndexExit]) then
    running = false
    cleanUp()
  end
end

function energyLibHandlers.interrupted(adress, char, code, playerName)
  running = false
  cleanUp()
end

return Histogram
