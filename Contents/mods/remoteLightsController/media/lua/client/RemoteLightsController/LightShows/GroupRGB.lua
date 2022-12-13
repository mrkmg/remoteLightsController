RemoteLC_LightShow = RemoteLC_LightShow or {}
RemoteLC_LightShow.Modes = RemoteLC_LightShow.Modes or {}
RemoteLC_LightShow.Modes.GroupRGB = {
    type = "RGB",
    name = getText("UI_RemoteLC_Group"),
    speeds = {Slow = 50, Normal = 50, Quick = 50}, -- always 20 fps
}

local function areTouching(lightDataOne, lightDataTwo)
    if lightDataOne.z ~= lightDataTwo.z then
        return false
    end
    if lightDataOne.x < lightDataTwo.x - 1 or lightDataOne.x > lightDataTwo.x + 1 then
        return false
    end
    if lightDataOne.y < lightDataTwo.y - 1 or lightDataOne.y > lightDataTwo.y + 1 then
        return false
    end
    return true
end

function RemoteLC_LightShow.Modes.GroupRGB.init(lightShowArgs)
    local nextGroupId = 1
    local groups = {}
    for _, lightData in ipairs(lightShowArgs.lightDatas) do
        local foundGroup = nil
        for _, group in ipairs(groups) do
            if foundGroup then
                break
            end
            for _, groupLightData in ipairs(group) do
                if areTouching(lightData, groupLightData) then
                    foundGroup = group
                    break
                end
            end
        end
        if foundGroup then
            table.insert(foundGroup, lightData)
        else
            groups[nextGroupId] = { lightData }
            nextGroupId = nextGroupId + 1
        end
    end

    local delta = 0.001
    if lightShowArgs.speed == "Slow" then
        delta = 0.001
    elseif lightShowArgs.speed == "Normal" then
        delta = 0.005
    elseif lightShowArgs.speed == "Quick" then
        delta = 0.01
    end

    local lastGroupColors = {}
    for i = 1, #groups do
        lastGroupColors[i] = RemoteLC_Utilities.CreateColorWithShiftData(delta)
    end

    return {
        lightDatas = groups,
        lastGroupColors = lastGroupColors,
    }
end

function RemoteLC_LightShow.Modes.GroupRGB.run(lightShow, data)
    if not data.lightDatas then
        lightShow:destroy()
        return
    end

    local cell = getCell()
    for i, group in ipairs(data.lightDatas) do
        RemoteLC_Utilities.ShiftColorHue(data.lastGroupColors[i])
        RemoteLC_Utilities.SetLightsColorFromData(cell, group, data.lastGroupColors[i].color, true)
    end
end