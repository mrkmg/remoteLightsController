RemoteLC_LightShow = RemoteLC_LightShow or {}
RemoteLC_LightShow.Modes = RemoteLC_LightShow.Modes or {}
RemoteLC_LightShow.Modes.Random = {
    type = "Standard",
    name = getText("UI_RemoteLC_Random"),
}

function RemoteLC_LightShow.Modes.Random.init(lightShowArgs)
    return {
        randomOn = {},
    }
end

function RemoteLC_LightShow.Modes.Random.run(lightShow, data)
    if not lightShow.data.lightDatas or not data.randomOn then
        lightShow:destroy()
        return
    end

    local cell = getCell()
    RemoteLC_Utilities.SetLightsStateFromData(cell, data.randomOn, false, true)
    for i in pairs(data.randomOn) do
        data.randomOn[i] = nil
    end
    local added = {}
    for _ = 1, ZombRand(1, #lightShow.data.lightDatas + 1) do
        local j = ZombRand(1, #lightShow.data.lightDatas + 1)
        if not added[j] then
            table.insert(data.randomOn, lightShow.data.lightDatas[j])
            added[j] = true
        end
    end
    RemoteLC_Utilities.SetLightsStateFromData(cell, data.randomOn, true, true)
end