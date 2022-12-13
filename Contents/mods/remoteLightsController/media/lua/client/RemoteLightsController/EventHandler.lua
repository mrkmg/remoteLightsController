local CommandHandlers = {}
local commands = RemoteLC_Utilities.wireNames.commands

CommandHandlers[commands.LightShowCreate] = function(args)
    local id = args[1]
    local lightShowArgs = args[2]
    local runningTime = args[3]
    RemoteLC_Utilities.Debug("Creating light show " .. id)
    RemoteLC_LightShow:new(id, lightShowArgs, runningTime)
end

CommandHandlers[commands.LightShowSetPaused] = function(args)
    local id = args[1]
    local paused = args[2]
    local lightShow = RemoteLC_LightShow.Instances[id]
    if lightShow then
        lightShow:setPaused(paused, true)
    end
end

CommandHandlers[commands.LightShowDestroy] = function(args)
    local id = args[1]
    local lightShow = RemoteLC_LightShow.Instances[id]
    RemoteLC_Utilities.Debug("Destroying light show " .. id)
    if lightShow then
        lightShow:destroy(true)
    end
end

local function handleServerCommand(module, command, args)
    if module ~= RemoteLC_Utilities.wireNames.module then
        return
    end

    if not CommandHandlers[command] then
        RemoteLC_Utilities.Debug("Error | Unknown command '" .. command .. "'")
        return
    end
    
    CommandHandlers[command](args)
    
end

Events.OnServerCommand.Add(handleServerCommand)