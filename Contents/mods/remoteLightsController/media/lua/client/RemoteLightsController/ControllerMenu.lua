ISInventoryMenuElements = ISInventoryMenuElements or {};

function ISInventoryMenuElements.ContextRemoteLightsController()
    local self = ISMenuElement.new();
    self.invMenu = ISContextManager.getInstance().getInventoryMenu();

    function self.init()
        self.controller = nil
    end

    function self.createMenu(item)
        self.controller = RemoteLC_Controller:get(item)
        if not self.controller or not self.controller:isOnPlayer(getPlayer()) then
            self.controller = nil
            return
        end
        self.invMenu.context:addOption(getText("UI_RemoteLC_ShowController"), self.invMenu, self.showUI)
    end

    function self.showUI()
        self.controller:showUI()
    end

    return self;
end