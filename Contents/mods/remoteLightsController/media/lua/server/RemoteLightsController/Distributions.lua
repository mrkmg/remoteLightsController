require 'Items/Distributions'
SuburbsDistributions = SuburbsDistributions or {};

local function addDist(name, type, val)
    if not SuburbsDistributions or not SuburbsDistributions or not SuburbsDistributions.all then return end

    if SuburbsDistributions.all[name] then
        table.insert(SuburbsDistributions.all[name].items, type)
        table.insert(SuburbsDistributions.all[name].items, val)
    end
end

addDist("Outfit_FiremanStripper", "RemoteLightsController.RemoteLightsController", 1)
addDist("Outfit_PoliceStripper", "RemoteLightsController.RemoteLightsController", 1)
addDist("Outfit_Stripper", "RemoteLightsController.RemoteLightsController", 1)
addDist("Outfit_StripperBlack", "RemoteLightsController.RemoteLightsController", 1)
addDist("Outfit_StripperNaked", "RemoteLightsController.RemoteLightsController", 1)
addDist("Outfit_StripperPink", "RemoteLightsController.RemoteLightsController", 1)

addDist("Outfit_FiremanStripper", "RemoteLightsController.RGBRemoteLightsController", 0.25)
addDist("Outfit_PoliceStripper", "RemoteLightsController.RGBRemoteLightsController", 0.25)
addDist("Outfit_Stripper", "RemoteLightsController.RGBRemoteLightsController", 0.25)
addDist("Outfit_StripperBlack", "RemoteLightsController.RGBRemoteLightsController", 0.25)
addDist("Outfit_StripperNaked", "RemoteLightsController.RGBRemoteLightsController", 0.25)
addDist("Outfit_StripperPink", "RemoteLightsController.RGBRemoteLightsController", 0.25)