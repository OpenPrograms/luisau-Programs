function printComponents ()
	print ("------------------------------------")
	print ("Available components: ")
	local component = require("component")
	for k, v in component.list() do
		print (k, v)
	end
	print ("------------------------------------")
end

function printDraconicRfStorageData (address)
	print ("Trying to get proxy for "..address)
	local component = require("component")
	local proxy = component.proxy(address)

	print ("MaxEnergyStored "..proxy.getMaxEnergyStored())
	print ("EnergyStored "..proxy.getEnergyStored())
end

function rfStorageLookup (storageName)
	print ("Trying to lookup proxy for " .. storageName .."...")
	local component = require("component")
	for address, componentName in component.list() do
		if componentName == storageName then
			print ("Draconic core found at address: "..address)
			return address
		end
	end
end

printComponents ()

local storageName = "draconic_rf_storage"
local address = rfStorageLookup (storageName)
printDraconicRfStorageData (address)
print ()
