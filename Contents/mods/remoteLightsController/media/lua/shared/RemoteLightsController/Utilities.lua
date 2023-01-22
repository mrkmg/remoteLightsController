RemoteLC_Utilities = {}
RemoteLC_Utilities.MAX_SCAN_DISTANCE = 50
RemoteLC_Utilities.wireNames = {
    module = "RemoteLC",
    commands = {
        SetLightStateFromData = "SetLightStateFromData",
        SetLightsStateFromData = "SetLightsStateFromData",
        SetLightColorFromData = "SetLightColorFromData",
        SetLightsColorFromData = "SetLightsColorFromData",
        LightShowCreate = "LightShowCreate",
        LightShowSetPaused = "LightShowSetPaused",
        LightShowDestroy = "LightShowDestroy",
        LightShowUpdate = "LightShowUpdate",
        LightShowRequestRunning = "LightShowRequestRunning",
        SetLightBrightnessFromData = "SetLightBrightnessFromData",
        SetLightsBrightnessFromData = "SetLightsBrightnessFromData",
    },
}

local function getRemoteControlledBulb(object)
    if not object then
        return nil
    end

    if not instanceof(object, "IsoLightSwitch") then
        return nil
    end

    local bulbName = object:getBulbItem()
    if not bulbName then
        return nil
    end

    if bulbName:sub(-16) ~= "RemoteControlled" then
        return nil
    end

    return bulbName
end

local function getLightDataFromObject(square, object)
    local bulbName = getRemoteControlledBulb(object)
    if not bulbName then
        return nil
    end

    local item = getScriptManager():getItem(bulbName)
    if not item then
        return nil
    end

    local bulbColor = bulbName:sub(33, -17)
    if bulbColor == "" then
        bulbColor = "White"
    end

    local invItem = InventoryItemFactory.CreateItem(bulbName)
    local r = invItem:getColorRed()
    local g = invItem:getColorGreen()
    local b = invItem:getColorBlue()

    return {
        x = square:getX(),
        y = square:getY(),
        z = square:getZ(),
        r = r,
        g = g,
        b = b,
        bulbName = bulbName,
        bulbColor = bulbColor,
    }
end

local function getLightFromData(cell, lightData)
    local square = cell:getGridSquare(lightData.x, lightData.y, lightData.z)
    if not square then
        return nil
    end
    local objects = square:getObjects()
    if not objects then
        return nil
    end
    for i = 0, objects:size() - 1, 1 do
        local object = objects:get(i)
        local bulbName = getRemoteControlledBulb(object)
        if bulbName and bulbName == lightData.bulbName then
            return object
        end
    end
    return nil
end

local function getBoundsOfLightDatas(lightDatas)
    local minX, minY, maxX, maxY = 9999999, 9999999, -9999999, -9999999
    for _, lightData in ipairs(lightDatas) do
        if lightData.x < minX then
            minX = lightData.x
        end
        if lightData.y < minY then
            minY = lightData.y
        end
        if lightData.x > maxX then
            maxX = lightData.x
        end
        if lightData.y > maxY then
            maxY = lightData.y
        end
    end
    return minX, minY, maxX, maxY
end

local function getCenterOfLightDatas(lightDatas)
    local minX, minY, maxX, maxY = getBoundsOfLightDatas(lightDatas)
    return math.floor((minX + maxX) / 2), math.floor((minY + maxY) / 2)
end

function RemoteLC_Utilities.Debug(string)
    if getDebug() then
        print("RemoteLC | Debug | " .. string)
    end
end

function RemoteLC_Utilities.Log(string)
    print("RemoteLC | Log | " .. string)
end

function RemoteLC_Utilities.DistanceBetweenSquareAndLightData(square, lightData)
    if not square or not lightData then
        return 0
    end
    local x1, y1 = square:getX(), square:getY()
    local x2, y2 = lightData.x, lightData.y
    return math.sqrt((x2 - x1) ^ 2 + (y2 - y1) ^ 2)
end

function RemoteLC_Utilities.GetLightDatasInRange(cell, square, range)
    local sX = square:getX()
    local sY = square:getY()
    local sZ = square:getZ()
    local lights = {}

    for x = -range, range, 1 do
        for y = -range, range, 1 do
            repeat -- work around for no continue, not often called
                local iSquare = cell:getGridSquare(sX + x, sY + y, sZ)
                if not iSquare then
                    break
                end

                local objects = iSquare:getObjects()
                if not objects then
                    break
                end

                for j = 0, objects:size() - 1, 1 do
                    local object = objects:get(j)
                    local lightData = getLightDataFromObject(iSquare, object)
                    if lightData then
                        table.insert(lights, lightData)
                    end
                end
            until true
        end
    end

    return lights
end

function RemoteLC_Utilities.InitializeController(item)
    if not isServer() then
        -- don't really need a reference to the controller, but this will initialize it
        RemoteLC_Controller:get(item)
    end
end

-- don't call this in a loop, use RemoteLC_Utilities.SetLightsStateFromData instead
function RemoteLC_Utilities.SetLightStateFromData(cell, lightData, state, onlyClient)
    if type(state) == "boolean" then
        state = state and 1 or 0
    end

    if isClient() and not onlyClient then
        sendClientCommand(getPlayer(), "RemoteLC", "SetLightStateFromData", {lightData, state})
        return
    end

    local light = getLightFromData(cell, lightData)
    if not light then
        return
    end

    if state < 0.001 then
        if onlyClient then
            light:switchLight(false)
            return
        end
        light:syncIsoObject(true, 0, nil)
        return
    end

    if lightData.bulbColor ~= "RGB" then
        light:setPrimaryR(lightData.r * state)
        light:setPrimaryG(lightData.g * state)
        light:setPrimaryB(lightData.b * state)
    end

    if not isServer() then
        light:switchLight(true)
    else
        light:syncIsoObject(true, 1, nil)
    end
end

-- state is value from 0 to 1
function RemoteLC_Utilities.SetLightsStateFromData(cell, lightDatas, state, onlyClient)
    if isClient() then
        if not onlyClient then
            sendClientCommand(getPlayer(), "RemoteLC", "SetLightsStateFromData", {lightDatas, state})
            return
        end
    end
    for _, lightData in ipairs(lightDatas) do
        RemoteLC_Utilities.SetLightStateFromData(cell, lightData, state, onlyClient)
    end
end

-- don't call this in a loop, use RemoteLC_Utilities.SetLightsColorFromData instead
function RemoteLC_Utilities.SetLightColorFromData(cell, lightData, color, onlyClient)
    if lightData.bulbColor ~= "RGB" then
        return
    end

    if isClient() and not onlyClient then
        sendClientCommand(getPlayer(), RemoteLC_Utilities.wireNames.module, RemoteLC_Utilities.wireNames.commands.SetLightColorFromData, {lightData, color})
        return
    end

    local light = getLightFromData(cell, lightData)

    if not light then
        return
    end

    light:setPrimaryR(color.r)
    light:setPrimaryG(color.g)
    light:setPrimaryB(color.b)
    if onlyClient then
        light:switchLight(false)
        light:switchLight(true)
    else
        light:syncCustomizedSettings(nil)
        light:syncIsoObject(true, 1, nil)
    end
end

function RemoteLC_Utilities.SetLightsColorFromData(cell, lightDatas, colorOrcolors, onlyClient)
    local colors = {}
    if colorOrcolors.r then
        for _ in ipairs(lightDatas) do
            table.insert(colors, colorOrcolors)
        end
        colorOrcolors = {colorOrcolors}
    else
        colors = colorOrcolors
    end

    if #lightDatas ~= #colors then
        return
    end
    if isClient() then
        if not onlyClient then
            sendClientCommand(getPlayer(), RemoteLC_Utilities.wireNames.module, RemoteLC_Utilities.wireNames.commands.SetLightsColorFromData, {lightDatas, colors})
            return
        end
    end
    for i, lightData in ipairs(lightDatas) do
        RemoteLC_Utilities.SetLightColorFromData(cell, lightData, colors[i], onlyClient)
    end
end

function RemoteLC_Utilities.IsPlayerNearLightDatas(player, lightDatas)
    local minX, minY, maxX, maxY = getBoundsOfLightDatas(lightDatas)
    if not minX or not minY or not maxX or not maxY then
        return false
    end
    local playerSquare = player:getSquare()
    local playerX, playerY = playerSquare:getX(), playerSquare:getY()
    if playerX < minX - RemoteLC_Utilities.MAX_SCAN_DISTANCE or playerX > maxX + RemoteLC_Utilities.MAX_SCAN_DISTANCE then
        return false
    end
    if playerY < minY - RemoteLC_Utilities.MAX_SCAN_DISTANCE or playerY > maxY + RemoteLC_Utilities.MAX_SCAN_DISTANCE then
        return false
    end
    return true
end

function RemoteLC_Utilities.IsLightDataCloseEnoughToLightDatas(lightData, lightDatas)
    local x1, y1 = getCenterOfLightDatas(lightDatas)
    local x2, y2 = lightData.x, lightData.y
    if x1 < x2 - RemoteLC_Utilities.MAX_SCAN_DISTANCE or x1 > x2 + RemoteLC_Utilities.MAX_SCAN_DISTANCE then
        return false
    end
    if y1 < y2 - RemoteLC_Utilities.MAX_SCAN_DISTANCE or y1 > y2 + RemoteLC_Utilities.MAX_SCAN_DISTANCE then
        return false
    end
    return true
end

function RemoteLC_Utilities.CreateColorWithShiftData(delta)
    delta = delta or 0.01
    local h = ZombRand(0, 100)/100
    local color = Color.HSBtoRGB(h, 1.0, 1.0)
    return {
        color = {r = color:getRedFloat(), g = color:getGreenFloat(), b = color:getBlueFloat(), a = 1.0},
        h = h,
        delta = delta,
        dir = true,
    }
end
function RemoteLC_Utilities.ShiftColorHue(colorWithShiftData)
    if ZombRand(0, 10) == 1 then
        colorWithShiftData.d = not colorWithShiftData.d
    end

    colorWithShiftData.h = colorWithShiftData.h + (colorWithShiftData.dir and colorWithShiftData.delta or -colorWithShiftData.delta)
    if colorWithShiftData.h > 1.0 then
        colorWithShiftData.h = colorWithShiftData.h - 1.0
    elseif colorWithShiftData.h < 0.0 then
        colorWithShiftData.h = colorWithShiftData.h + 1.0
    end

    local color = Color.HSBtoRGB(colorWithShiftData.h, 1.0, 1.0)
    colorWithShiftData.color.r = color:getRedFloat()
    colorWithShiftData.color.g = color:getGreenFloat()
    colorWithShiftData.color.b = color:getBlueFloat()
end