require "RemoteLightsController/Config"

RemoteLC_Options = RemoteLC_Options or {}
RemoteLC_LightShow = RemoteLC_LightShow or {}
RemoteLC_LightShow.Modes = RemoteLC_LightShow.Modes or {}
RemoteLC_LightShow.Instances = {}
RemoteLC_ShowTracker = RemoteLC_ShowTracker or {}

function RemoteLC_LightShow.GetModes(type)
    local modes = {}
    for k, v in pairs(RemoteLC_LightShow.Modes) do
        if v.type == type or v.type == "Both" then
            modes[k] = v
        end
    end
    return modes
end

function RemoteLC_LightShow.CreateNew(id, lightShowArgs)
    local mode = RemoteLC_LightShow.Modes[lightShowArgs.mode]
    if not mode then
        RemoteLC_Utilities.Debug("Error creating light show for mode: '" .. lightShowArgs.mode .. "'")
        return false
    end

    local player = getPlayer()
    if not RemoteLC_Utilities.IsPlayerNearLightDatas(player, lightShowArgs.lightDatas) then
        player:Say(getText("UI_RemoteLC_TooFarAway"))
        return false
    end

    local data = {
        id = lightShowArgs.id,
        mode = lightShowArgs.mode,
        speed = lightShowArgs.speed,
        lightDatas = lightShowArgs.lightDatas,
        runnerData = mode.init(lightShowArgs),
    }
    RemoteLC_Utilities.SetLightsStateFromData(getPlayer():getCell(), lightShowArgs.lightDatas, false)

    RemoteLC_Utilities.Debug("Creating light show " .. id)
    local show = RemoteLC_LightShow:new(id, data)
    if not show then
        return
    end
    show.data.owner = true

    if isClient() then
        sendClientCommand(getPlayer(), RemoteLC_Utilities.wireNames.module, RemoteLC_Utilities.wireNames.commands.LightShowCreate, {id, data, 0})
    end

    return true
end

function RemoteLC_LightShow:new(id, lightShowArgs, runningTime)
    if not lightShowArgs then
        RemoteLC_Utilities.Debug("Missing lightShowArgs: '" .. id .. "'")
        return nil
    end

    if RemoteLC_LightShow.Instances[id] then
        RemoteLC_Utilities.Debug("Light show already exists: '" .. id .. "'")
        return RemoteLC_LightShow.Instances[id]
    end

    RemoteLC_Utilities.Debug("Passed checks for new light show " .. id)
    local o = {}
    o.data = { id = id }
    setmetatable(o, self)
    self.__index = self
    o:initialize(lightShowArgs, runningTime or 0)
    RemoteLC_LightShow.Instances[o.data.id] = o
    return o
end

function RemoteLC_LightShow:initialize(lightShowArgs, runningTime)    
    local ts = getTimestampMs()
    self.data.isOwner = false
    self.data.isPaused = false
    self.data.startTsMs = ts - runningTime
    self.data.lastActionTsMs = ts
    self.data.lastUpdateTsMs = ts
    self.data.timeBetweenActions = 1

    for k, v in pairs(lightShowArgs) do
        self.data[k] = v
    end

    if RemoteLC_LightShow.Modes[self.data.mode].speeds then
        self.data.timeBetweenActions = RemoteLC_LightShow.Modes[self.data.mode].speeds[self.data.speed]
    elseif self.data.speed == "Quick" then
        self.data.timeBetweenActions = 500
    elseif self.data.speed == "Normal" then
        self.data.timeBetweenActions = 750
    elseif self.data.speed == "Slow" then
        self.data.timeBetweenActions = 1000
    end

    self.data.runner = RemoteLC_LightShow.Modes[self.data.mode].run
    if not self.data.runner then
        RemoteLC_Utilities.Debug("Error creating light show, runner not found for mode: '" .. self.data.mode .. "'")
        return
    end

    local player = getPlayer()    
    if RemoteLC_Utilities.IsPlayerNearLightDatas(player, self.data.lightDatas) then

        if RemoteLC_Options.light_sensitivity then
            RemoteLC_Utilities.SetLightsStateFromData(getPlayer():getCell(), self.data.lightDatas, true, true)
        else
            RemoteLC_Utilities.SetLightsStateFromData(getPlayer():getCell(), self.data.lightDatas, false, true)
            self.data.runner(self, self.data.runnerData)
        end
    end
end

function RemoteLC_LightShow:update()
    if RemoteLC_Options.light_sensitivity then return end
    local ts = getTimestampMs()
    local player = getPlayer()

    if self.data.owner and ts - self.data.lastUpdateTsMs > 5000 then -- every 5 seconds send an update to server
        sendClientCommand(getPlayer(), RemoteLC_Utilities.wireNames.module, RemoteLC_Utilities.wireNames.commands.LightShowUpdate, {self.data.id})
        self.data.lastUpdateTsMs = ts
    end

    if ts - self.data.startTsMs > 300000 then -- if the light show is older than 5 minutes, destroy it
        self:destroy()
        return
    end

    if self.data.isPaused then
        return
    end

    if not RemoteLC_Utilities.IsPlayerNearLightDatas(player, self.data.lightDatas) then
        return
    end

    if ts - self.data.lastActionTsMs < self.data.timeBetweenActions then
        return
    end

    if not self:verifyOwnerState(player) then
        return
    end

    self.data.lastActionTsMs = ts
    self.data.runner(self, self.data.runnerData)
end

function RemoteLC_LightShow:verifyOwnerState(player)
    if not self.owner then
        return true
    end
    local controller = RemoteLC_Controller.getById(self.data.id)
    if not controller or not controller:isOnPlayer(player) then
        self:destroy()
        return false
    end
    return true
end

function RemoteLC_LightShow:setPaused(paused, fromRemote)
    if not fromRemote and isClient() then
        sendClientCommand(getPlayer(), RemoteLC_Utilities.wireNames.module, RemoteLC_Utilities.wireNames.commands.LightShowSetPaused, {self.data.id, paused, true})
    else
        self.data.isPaused = paused
    end
end

function RemoteLC_LightShow:destroy(fromRemote)
    if not fromRemote and isClient() then
        sendClientCommand(getPlayer(), RemoteLC_Utilities.wireNames.module, RemoteLC_Utilities.wireNames.commands.LightShowDestroy, {self.data.id, true})
    else
        RemoteLC_LightShow.Instances[self.data.id] = nil
    end
end

function RemoteLC_LightShow.updateProcessInstances(ticks)
    for _, v in pairs(RemoteLC_LightShow.Instances) do
        if v then
            v:update()
        end
    end
end

Events.OnTick.Add(RemoteLC_LightShow.updateProcessInstances);

if isClient() then
    local lightShowRequests = {}
    local hasHandler = false

    -- This will delay seconds to allow the environment to be created first.
    -- This is needed because the light show may be created before the
    -- lights are created.
    local function CheckForLightShowRequest()
        local tsMs = getTimestampMs()
        for i, request in ipairs(lightShowRequests) do
            if tsMs - request[2] > 2000 then
                table.remove(lightShowRequests, i)
                sendClientCommand(request[1], RemoteLC_Utilities.wireNames.module, RemoteLC_Utilities.wireNames.commands.LightShowRequestRunning, nil)
            end
        end
        if #lightShowRequests == 0 then
            Events.OnTick.Remove(CheckForLightShowRequest)
            hasHandler = false
        end
    end

    Events.OnCreatePlayer.Add(function (idx, player)
        table.insert(lightShowRequests, {player, getTimestampMs()})
        RemoteLC_Utilities.Debug("Player " .. tostring(idx) .. " scheduling a sync request")
        if not hasHandler then
            hasHandler = true
            Events.OnTick.Add(CheckForLightShowRequest)
        end
    end)
end
