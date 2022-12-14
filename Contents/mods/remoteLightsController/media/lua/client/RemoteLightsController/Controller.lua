RemoteLC_Controller = {}
-- Initialized to current second. Should be "good enough" to have it be unique
RemoteLC_Controller.InstanceCache = {}

local function lightTableContainsLightData(lightDataTable, lightData)
    for i = 1, #lightDataTable do
        if  lightDataTable[i].x == lightData.x and
            lightDataTable[i].y == lightData.y and
            lightDataTable[i].z == lightData.z and
            lightDataTable[i].bulbColor == lightData.bulbColor then
            return true
        end
    end
    return false
end

function RemoteLC_Controller.getById(controllerId)
    return RemoteLC_Controller.InstanceCache[controllerId]
end

function RemoteLC_Controller:get(item)
    if not item or ( item:getType() ~= "RemoteLightsController" and item:getType() ~= "RGBRemoteLightsController" ) then
        return nil
    end

    local modData = item:getModData()
    local id = modData.RemoteLC_ControllerId

    if id and RemoteLC_Controller.InstanceCache[id] then
        local instance = RemoteLC_Controller.InstanceCache[id]
        instance.controller = item
        if instance.isRunning and not RemoteLC_LightShow.Instances[id] then
            instance.isRunning = false
            instance.isPaused = false
            instance:_updateName()
        end
        return instance
    end

    local o = {}
    o.controller = item
    o.data = {}
    setmetatable(o, self)
    self.__index = self
    o:initialize()
    o:_updateName()
    RemoteLC_Controller.InstanceCache[id] = o
    return o
end

-- Sets defaults for the controller
function RemoteLC_Controller:initialize()
    self.isRunning = self.isRunning or false
    self.isPaused = self.isPaused or false
    self.isRGB = self.controller:getType() == "RGBRemoteLightsController"

    local modData = self.controller:getModData()
    modData.RemoteLC_ControllerId = modData.RemoteLC_ControllerId or getRandomUUID()
    modData.RemoteLC_Mode = modData.RemoteLC_Mode or "Strobe"
    modData.RemoteLC_Speed = modData.RemoteLC_Speed or "Normal"
    modData.RemoteLC_ScannedLightData = modData.RemoteLC_ScannedLightData or {}
    modData.RemoteLC_Color = modData.RemoteLC_Color or {r = 1.0, g = 1.0, b = 1.0, a = 1.0}
    modData.RemoteLC_Brightness = modData.RemoteLC_Brightness or 1.0

    -- TODO: remove this in a future version
    -- This is to remove old light data that doesn't have a bulbName or original color data
    if #modData.RemoteLC_ScannedLightData > 0 then
        local toRemove = {}
        for i, lightData in ipairs(modData.RemoteLC_ScannedLightData) do
            if not lightData.bulbName then
                table.insert(toRemove, i)
            end
        end
        for i = #toRemove, 1, -1 do
            table.remove(modData.RemoteLC_ScannedLightData, toRemove[i])
        end
    end

    self:_updateName()
end

function RemoteLC_Controller:isOnPlayer(player, equippedOnly)

    if equippedOnly then
        local primary = player:getPrimaryHandItem()
        local secondary = player:getSecondaryHandItem()
        return primary == self.controller or secondary == self.controller
    end

    local playerInv = player:getInventory()
    if not playerInv then return false end
    local items = playerInv:getItems()
    if not items then return false end
    for i = 1, items:size() do
        if items:get(i-1) == self.controller then
            return true
        end
    end
    return false
end

function RemoteLC_Controller:getType()
    if self.isRGB then
        return "RGB"
    else
        return "Standard"
    end
end

function RemoteLC_Controller:getId()
    return self.controller:getModData().RemoteLC_ControllerId
end

function RemoteLC_Controller:getMenuData()
    local modData = self.controller:getModData()

    return {
        isPaused = self.isPaused,
        isRunning = self.isRunning,
        type = self:getType(),
        speed = modData.RemoteLC_Speed,
        mode = modData.RemoteLC_Mode,
        color = modData.RemoteLC_Color, -- only relevant for RGB controllers
        brightness = modData.RemoteLC_Brightness, -- only relevant for NON-RGB controllers
        countOfLights = self:_getCountOfLights(),
        countOfLightsByColor = self:_getCountOfLightsByColor(),
    }
end

function RemoteLC_Controller:getLightShowArgs()
    local modData = self.controller:getModData()
    return {
        id = modData.RemoteLC_ControllerId,
        type = self:getType(),
        mode = modData.RemoteLC_Mode,
        speed = modData.RemoteLC_Speed,
        lightDatas = modData.RemoteLC_ScannedLightData,
    }
end

function RemoteLC_Controller:clearLights()
    local modData = self.controller:getModData()
    modData.RemoteLC_ScannedLightData = {}
    self:_updateName()
end

function RemoteLC_Controller:scanForLights(player, range)
    local modData = self.controller:getModData()

    if not modData.RemoteLC_ScannedLightData then
        modData.RemoteLC_ScannedLightData = {}
    end

    local cell = player:getCell()
    local square = player:getSquare()
    local lights = RemoteLC_Utilities.GetLightDatasInRange(cell, square, range)
    local i = 0
    for _, lightData in ipairs(lights) do
        local isCloseEnough = #modData.RemoteLC_ScannedLightData == 0 or RemoteLC_Utilities.IsLightDataCloseEnoughToLightDatas(lightData, modData.RemoteLC_ScannedLightData)
        local isAlreadyAdded = lightTableContainsLightData(modData.RemoteLC_ScannedLightData, lightData)

        if not isCloseEnough then
            player:Say(getText("UI_RemoteLC_LightTooFarFromOtherLights"))
        end

        if isCloseEnough and not isAlreadyAdded and self.isRGB == (lightData.bulbColor == "RGB") then
            table.insert(modData.RemoteLC_ScannedLightData, lightData)
            i = i + 1
        end
    end

    if i == 0 then
        player:Say(getText("UI_RemoteLC_FoundNoNewLights"))
    elseif i == 1 then
        player:Say(getText("UI_RemoteLC_FoundOneLight", tostring(i)))
    else
        player:Say(getText("UI_RemoteLC_FoundLights", tostring(i)))
    end

    self:_updateName()
end

function RemoteLC_Controller:startLightShow()
    local modData = self.controller:getModData()
    self.isRunning = RemoteLC_LightShow.CreateNew(modData.RemoteLC_ControllerId, self:getLightShowArgs())
    self.isPaused = false
    self:_updateName()
end

function RemoteLC_Controller:stopLightShow()
    local modData = self.controller:getModData()

    if RemoteLC_LightShow.Instances[modData.RemoteLC_ControllerId] then
        RemoteLC_LightShow.Instances[modData.RemoteLC_ControllerId]:destroy()
    end

    self.isRunning = false
    self.isPaused = false

    self:_updateName()
end

function RemoteLC_Controller:setPaused(paused)
    local modData = self.controller:getModData()
    self.isPaused = paused
    self:_updateName()

    if RemoteLC_LightShow.Instances[modData.RemoteLC_ControllerId] then
        RemoteLC_LightShow.Instances[modData.RemoteLC_ControllerId]:setPaused(paused)
    end
end

function RemoteLC_Controller:setMode(mode)
    local modData = self.controller:getModData()
    modData.RemoteLC_Mode = mode
    self:_updateName()
end

function RemoteLC_Controller:setSpeed(speed)
    local modData = self.controller:getModData()
    modData.RemoteLC_Speed = speed
    self:_updateName()
end

function RemoteLC_Controller:setColor(color)
    local modData = self.controller:getModData()
    modData.RemoteLC_Color = color
    self:_updateName()
end

function RemoteLC_Controller:setBrightness(brightness)
    local modData = self.controller:getModData()
    modData.RemoteLC_Brightness = brightness
    self:_updateName()
end

function RemoteLC_Controller:toggleLights(state, blubColor)
    local modData = self.controller:getModData()
    local player = getPlayer()

    if not RemoteLC_Utilities.IsPlayerNearLightDatas(player, modData.RemoteLC_ScannedLightData) then
        player:Say(getText("UI_RemoteLC_TooFarAway"))
        return
    end

    local cell = player:getCell()

    if self.isRGB then
        if state then
            RemoteLC_Utilities.SetLightsColorFromData(cell, modData.RemoteLC_ScannedLightData, modData.RemoteLC_Color)
        else
            RemoteLC_Utilities.SetLightsStateFromData(cell, modData.RemoteLC_ScannedLightData, state)
        end
    else
        if type(state) == "boolean" then
            state = state and 1 or 0
        end
        if state > 0.001 then
            state = modData.RemoteLC_Brightness
        end
        local matchingLights = {}
        for _, lightData in ipairs(modData.RemoteLC_ScannedLightData) do
            if blubColor == "All" or lightData.bulbColor == blubColor then
                table.insert(matchingLights, lightData)
            end
        end
        RemoteLC_Utilities.SetLightsStateFromData(cell, matchingLights, state)
    end
end

function RemoteLC_Controller:showUI(fromEquip)
    local player = getPlayer()
    if RemoteLC_ControllerUI.instance and RemoteLC_ControllerUI.instance[self:getId()] then
        return
    end
    local modal = RemoteLC_ControllerUI:new(player, self);
    modal:initialise()
    modal:addToUIManager()
    modal.fromEquip = fromEquip
    if JoypadState.players[player:getPlayerNum()+1] then
        setJoypadFocus(player:getPlayerNum(), modal)
    end
end

function RemoteLC_Controller:_updateName()
    local modData = self.controller:getModData()
    local isRunning = self.isRunning
    local lights = modData.RemoteLC_ScannedLightData

    local data = " (" .. getText("UI_RemoteLC_NumberOfLights", tostring(#lights)) .. ")"
    if isRunning then
        if self.isRGB then
            self.controller:setName(getText("UI_RemoteLC_ActiveRGBLightsController") .. data)
        else
            self.controller:setName(getText("UI_RemoteLC_ActiveLightsController") .. data)
        end
    else
        if self.isRGB then
            self.controller:setName(getText("UI_RemoteLC_RGBRemoteLightsController") .. data)
        else
            self.controller:setName(getText("UI_RemoteLC_RemoteLightsController") .. data)
        end
    end
end

function RemoteLC_Controller:_getCountOfLights()
    local modData = self.controller:getModData()
    if not modData.RemoteLC_ScannedLightData then
        return 0
    end
    return #modData.RemoteLC_ScannedLightData
end

function RemoteLC_Controller:_getCountOfLightsByColor()
    local bulbColors = {}
    local modData = self.controller:getModData()

    if not modData.RemoteLC_ScannedLightData then
        return bulbColors
    end

    for _, lightData in ipairs(modData.RemoteLC_ScannedLightData) do
        if not bulbColors[lightData.bulbColor] then
            bulbColors[lightData.bulbColor] = 1
        else
            bulbColors[lightData.bulbColor] = bulbColors[lightData.bulbColor] + 1
        end
    end
    return bulbColors
end

-- Some utilities to check if the window should be showing
local function checkEquippedItemForController(player, item)
    if player ~= getPlayer() then
        return
    end
    local controller = RemoteLC_Controller:get(item)
    if not controller then
        return
    end
    controller:showUI(true)
end

local function checkFirstLaunch(_, player)
    if player ~= getPlayer() then return end
    local handOne = RemoteLC_Controller:get(player:getPrimaryHandItem())
    local handTwo = RemoteLC_Controller:get(player:getSecondaryHandItem())
    if handOne then
        handOne:showUI(true)
    end
    if handTwo then
        handTwo:showUI(true)
    end
end

Events.OnEquipPrimary.Add(checkEquippedItemForController)
Events.OnEquipSecondary.Add(checkEquippedItemForController)
Events.OnCreatePlayer.Add(checkFirstLaunch)

-- Create all the attachment points
local group = AttachedLocations.getGroup("Human")
group:getOrCreateLocation("RLC Belt Right"):setAttachmentName("rlc_belt_right")
group:getOrCreateLocation("RLC Belt Left"):setAttachmentName("rlc_belt_left")
group:getOrCreateLocation("RLC2 Belt Right"):setAttachmentName("rlc2_belt_right")
group:getOrCreateLocation("RLC2 Belt Left"):setAttachmentName("rlc2_belt_left")

for _,v in pairs(ISHotbarAttachDefinition) do
    if v.type == "SmallBeltLeft" then
        v.attachments.RLC = "RLC Belt Left"
        v.attachments.RLC2 = "RLC2 Belt Left"
    end
    if v.type == "SmallBeltRight" then
        v.attachments.RLC = "RLC Belt Right"
        v.attachments.RLC2 = "RLC Belt Right"
    end
    if v.attachments then 
        for type,slot in pairs(v.attachments) do
            if type == "Walkie" or type == "Gear" then
                v.attachments["RLC"] = slot
                v.attachments["RLC2"] = slot
            end
        end
    end
end