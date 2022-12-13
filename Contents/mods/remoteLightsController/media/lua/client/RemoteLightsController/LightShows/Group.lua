RemoteLC_LightShow = RemoteLC_LightShow or {}
RemoteLC_LightShow.Modes = RemoteLC_LightShow.Modes or {}
RemoteLC_LightShow.Modes.Group = {
    type = "Standard",
    name = getText("UI_RemoteLC_Group"),
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

function RemoteLC_LightShow.Modes.Group.init(lightShowArgs)
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

    local lastGroupIndexes = {}
    for i = 1, #groups do
        lastGroupIndexes[i] = 1
    end

    return {
        lightDatas = groups,
        lastGroupIndexes = lastGroupIndexes,
    }
end

function RemoteLC_LightShow.Modes.Group.run(lightShow, data)
    if not data.lightDatas then
        lightShow:destroy()
        return
    end


    local cell = getCell()
    for i, group in ipairs(data.lightDatas) do
        RemoteLC_Utilities.SetLightStateFromData(cell, group[data.lastGroupIndexes[i]], false, true)
        data.lastGroupIndexes[i] = ZombRand(1, #group + 1)
        RemoteLC_Utilities.SetLightStateFromData(cell, group[data.lastGroupIndexes[i]], true, true)
    end
end