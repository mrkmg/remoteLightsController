local CommandHandlers = {}
local commands = RemoteLC_Utilities.wireNames.commands
local moduleName = RemoteLC_Utilities.wireNames.module

CommandHandlers[commands.SetLightStateFromData] = function(player, args)
    local square = player:getSquare()
    RemoteLC_Utilities.Log("User " .. player:getUsername() .. " remotely activated a light from position " .. square:getX() .. ", " .. square:getY() .. ", " .. square:getZ())
    local lightData = args[1]
    local state = args[2]
    local cell = player:getCell()
    RemoteLC_Utilities.SetLightStateFromData(cell, lightData, state)
end

CommandHandlers[commands.SetLightsStateFromData] = function(player, args)
    local square = player:getSquare()
    RemoteLC_Utilities.Log("User " .. player:getUsername() .. " remotely activated a group of lights from position " .. square:getX() .. ", " .. square:getY() .. ", " .. square:getZ())
    local lightDatas = args[1]
    local state = args[2]
    local cell = player:getCell()
    RemoteLC_Utilities.SetLightsStateFromData(cell, lightDatas, state)
end

CommandHandlers[commands.SetLightColorFromData] = function(player, args)
    local square = player:getSquare()
    RemoteLC_Utilities.Log("User " .. player:getUsername() .. " remotely changed the color of a light from position " .. square:getX() .. ", " .. square:getY() .. ", " .. square:getZ())
    local lightData = args[1]
    local color = args[2]
    local cell = player:getCell()
    RemoteLC_Utilities.SetLightColorFromData(cell, lightData, color)
end

CommandHandlers[commands.SetLightsColorFromData] = function(player, args)
    local square = player:getSquare()
    RemoteLC_Utilities.Log("User " .. player:getUsername() .. " remotely changed the color of a group of lights from position " .. square:getX() .. ", " .. square:getY() .. ", " .. square:getZ())
    local lightDatas = args[1]
    local color = args[2]
    local cell = player:getCell()
    RemoteLC_Utilities.SetLightsColorFromData(cell, lightDatas, color)
end

CommandHandlers[commands.SetLightBrightnessFromData] = function(player, args)
    local square = player:getSquare()
    RemoteLC_Utilities.Log("User " .. player:getUsername() .. " remotely changed the brightness of a light from position " .. square:getX() .. ", " .. square:getY() .. ", " .. square:getZ())
    local lightData = args[1]
    local brightness = args[2]
    local cell = player:getCell()
    RemoteLC_Utilities.SetLightBrightnessFromData(cell, lightData, brightness)
end

CommandHandlers[commands.SetLightsBrightnessFromData] = function(player, args)
    local square = player:getSquare()
    RemoteLC_Utilities.Log("User " .. player:getUsername() .. " remotely changed the brightness of a group of lights from position " .. square:getX() .. ", " .. square:getY() .. ", " .. square:getZ())
    local lightDatas = args[1]
    local brightness = args[2]
    local cell = player:getCell()
    RemoteLC_Utilities.SetLightsBrightnessFromData(cell, lightDatas, brightness)
end

CommandHandlers[commands.LightShowCreate] = function(player, args)
    local square = player:getSquare()
    RemoteLC_Utilities.Log("User " .. player:getUsername() .. " started a light show " .. args[1] .. " from position " .. square:getX() .. ", " .. square:getY() .. ", " .. square:getZ())
    sendServerCommand(moduleName, commands.LightShowCreate, args)
    RemoteLC_ShowTracker:track(player, args[1], args[2])
end

CommandHandlers[commands.LightShowUpdate] = function(player, args)
    RemoteLC_Utilities.Debug("User " .. player:getUsername() .. " updated a light show " .. args[1])
    RemoteLC_ShowTracker:update(args[1])
end

CommandHandlers[commands.LightShowDestroy] = function(player, args)
    local square = player:getSquare()
    RemoteLC_Utilities.Debug("User " .. player:getUsername() .. " stopped a light show " .. args[1] .. " from position " .. square:getX() .. ", " .. square:getY() .. ", " .. square:getZ())
    sendServerCommand(moduleName, commands.LightShowDestroy, args)
    RemoteLC_ShowTracker:remove(args[1])
end

CommandHandlers[commands.LightShowSetPaused] = function(player, args)
    sendServerCommand(moduleName, commands.LightShowSetPaused, args)
end

CommandHandlers[commands.LightShowRequestRunning] = function(player, args)
    RemoteLC_ShowTracker:notifyOfRunningShows(player)
end

local function handleClientCommand(module, command, player, args)
    if module ~= moduleName then
        return
    end

    if not CommandHandlers[command] then
        RemoteLC_Utilities.Debug("Error | Unknown command '" .. command .. "'")
        return
    end
    
    CommandHandlers[command](player, args)
end

Events.OnClientCommand.Add(handleClientCommand)