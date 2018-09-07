-- Resolve relative path for "Console.lua".
local ConsoleLibaryPath = shell.resolve("Console.lua")
-- "Console.lua" not found -> error.
if (not fs.exists(ConsoleLibaryPath)) then
  error("[FATAL ERROR] Can't find libary \"" .. ConsoleLibaryPath .. "\".")
-- "Console.lua" not loadable -> error.
if(not os.loadAPI(ConsoleLibaryPath))
  error("[FATAL ERROR] Can't load libary \"" .. ConsoleLibaryPath .. "\".")

-- The name or side of the ME Interface.
local interfaceSide  = "back"

-- The export direction (target inventory) relative to the ME Interface.
local exportDirection = "north"

-- The export program tick interval. Recommended range is between 5 and 60 seconds.
local tickInterval    = 5

--================================================================================================--

-- Internal variables
local interface = peripheral.wrap(interfaceSide)
local exports   = {}

-- Main
local function mainTick()
  print("Getting available items from interface \"\"")
  local items = interface.getAvailableItems()
  for index, item in pairs(exports) do
    local fingerprint = {}
    local itemCount = 0
    for _, a in pairs(items) do
      if ((a.fingerprint.id == item.fingerprint.id) and 
          ((item.fingerprint.dmg == nil) or (a.fingerprint.dmg == item.fingerprint.dmg)) and 
          ((item.fingerprint.nbt_hash == nil) or 
          (a.fingerprint.nbt_hash == item.fingerprint.nbt_hash))) then
        fingerprint = a.fingerprint
        itemCount = a.size
        break
      end
    end
    itemCount = itemCount - item.preserve
    if (itemCount > 0) then
      print("Exportiere [" .. item.name .. "]")
      print("  id      : " .. fingerprint.id)
      print("  dmg     : " .. fingerprint.dmg)
      print("  nbt_hash: " .. fingerprint.nbt_hash)
      print("  Anzahl  : " .. itemCount + item.preserve)
      print("  Mindestbestand: " .. item.preserve)
      while (itemCount > 0) do
        -- Prevent "Too long without yielding" error
        local loopTimerId = os.startTimer(0.1) 
        while (true) do
          local amount = 64
          if (itemCount < amount) then
            amount = itemCount
          end
          local status = interface.exportItem(fingerprint, exportDirection, amount)
          itemCount = itemCount - status.size
          if (status.size ~= amount) then
            print("Container space exceeded.")
            return
          end
          local event, timerId = os.pullEvent("timer")    
          if (timerId == loopTimerId) then
            break
          end
        end

      end
    end
  end
end

-- Prints informations about the programm settings.
local function printConstInfo()
  Console.WriteLine(Console.Type.Config, "Interface side:   ".. interfaceSide)
  Console.WriteLine(Console.Type.Config, "Export direction: ".. exportDirection)
  Console.WriteLine(Console.Type.Config, "Tick interval:    ".. tickInterval)
end

local function main()
  -- Write startup things.
  Console.PrintLine("=")
  printConstInfo()
  Console.PrintLine("=")

  -- Parse interfaces.
  Console.WriteLine(Console.Type.Init, "Parsing given interface.")
  interface = peripheral.wrap(interfaceSide)

  -- Read "items.cfg"
  -- Todo: Name of the file adjustable.
  Console.WriteLine(Console.Type.Init, "Reading \"items.cfg\".")
  local itemsCfgPath = shell.resolve("items.cfg")
  -- File "items.cfg" does not exist -> error.
  if (not fs.exists(itemsCfgPath)) then
    error("There is no \"items.cfg\" file.")
  end
  -- Load and serialize items.cfg.
  local f = fs.open(itemsCfgPath, "r")
  exports = textutils.unserialise(f.readAll())
  f.close()
  
  print("[INIT] Programm startup done.")
  printLine() -- line
  while (true) do
    mainTick()
    local loopTimerId = os.startTimer(tickInterval) 
    while (true) do
      local event, timerId = os.pullEvent("timer")    
      if (timerId == loopTimerId) then
        break
      end
    end
  end
end

while true do
  -- Prevent "not attached" error
  pcall(main())
end