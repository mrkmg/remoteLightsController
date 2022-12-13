RemoteLC_LightShow = RemoteLC_LightShow or {}
RemoteLC_LightShow.Modes = RemoteLC_LightShow.Modes or {}
RemoteLC_LightShow.Modes.Strobe = {
    type = "Both",
    name = getText("UI_RemoteLC_Strobe"),
}

function RemoteLC_LightShow.Modes.Strobe.init(lightShowArgs)
    return {
        strobeState = false,
    }
end

function RemoteLC_LightShow.Modes.Strobe.run(lightShow, data)
    if not lightShow.data.lightDatas then
        lightShow:destroy()
        return
    end

    data.strobeState = not data.strobeState
    RemoteLC_Utilities.SetLightsStateFromData(getCell(), lightShow.data.lightDatas, data.strobeState, true)
end