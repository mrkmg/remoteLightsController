RemoteLC_ShowTracker = RemoteLC_ShowTracker or {}
RemoteLC_ShowTracker.running = {}

function RemoteLC_ShowTracker:isRunning(controllerId)
    return self.running[controllerId] ~= nil
end

function RemoteLC_ShowTracker:track(player, controllerId, data)
    self.running[controllerId] = {
        tsMs = getTimestampMs(),
        data = data,
        player = player,
    }
end

function RemoteLC_ShowTracker:update(controllerId)
    RemoteLC_Utilities.Debug("updating show " .. controllerId)
    if not self:isRunning(controllerId) then
        RemoteLC_Utilities.Debug("tried to update show but " .. controllerId .. " is not running")
        return
    end
    self.running[controllerId].tsMs = getTimestampMs()
end

function RemoteLC_ShowTracker:remove(controllerId)
    if not self:isRunning(controllerId) then
        return
    end
    self.running[controllerId] = nil
end

function RemoteLC_ShowTracker:notifyOfRunningShows(player)
    RemoteLC_Utilities.Debug("player " .. player:getUsername() .. " joined, checking for running shows")
    local tsMs = getTimestampMs()
    for controllerId, data in pairs(self.running) do
        RemoteLC_Utilities.Debug("syncing show " .. controllerId .. " to player " .. player:getUsername())
        sendServerCommand(player, RemoteLC_Utilities.wireNames.module, RemoteLC_Utilities.wireNames.commands.LightShowCreate, {controllerId, data.data, tsMs - data.tsMs})
    end
end

function RemoteLC_ShowTracker:verify()
    local tsMs = getTimestampMs()
    for controllerId, data in pairs(self.running) do
        if tsMs - data.tsMs > 30000 then -- if the server hasn't received an update about the show in the past 30 seconds, assume it's dead
            RemoteLC_Utilities.Debug("show " .. controllerId .. " is dead, destroying it")
            sendServerCommand(RemoteLC_Utilities.wireNames.module, RemoteLC_Utilities.wireNames.commands.LightShowDestroy, {controllerId, true})
            self:remove(controllerId)
        end
    end
end

-- This only needs to happen in an MP environment
if isServer() then
    Events.OnTick.Add(function () RemoteLC_ShowTracker:verify() end)
end