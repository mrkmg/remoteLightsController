require "GravyUI"

RemoteLC_ControllerUI = ISPanelJoypad:derive("RemoteLC_ControllerUI")
RemoteLC_ControllerUI.instance = {}
RemoteLC_ControllerUI.messages = {}

local textManager = getTextManager()
local ELEMENT_PADDING = 5
local TEXTS = {
    Activate = getText("UI_RemoteLC_Activate"),
    All = getText("UI_RemoteLC_All"),
    ClearLights = getText("UI_RemoteLC_ClearLights"),
    Deactivate = getText("UI_RemoteLC_Deactivate"),
    DirectLightControl = getText("UI_RemoteLC_DirectLightControl"),
    LightShowModule = getText("UI_RemoteLC_LightShowModule"),
    LightShowStatus = getText("UI_RemoteLC_LightShowStatus"),
    Normal = getText("UI_RemoteLC_Normal"),
    Off = getText("UI_RemoteLC_Off"),
    Pause = getText("UI_RemoteLC_Pause"),
    Paused = getText("UI_RemoteLC_Paused"),
    Quick = getText("UI_RemoteLC_Quick"),
    RemoteLightsController = getText("UI_RemoteLC_RemoteLightsController"),
    RGBRemoteLightsController = getText("UI_RemoteLC_RGBRemoteLightsController"),
    Resume = getText("UI_RemoteLC_Resume"),
    Running = getText("UI_RemoteLC_Running"),
    ScanForLights = getText("UI_RemoteLC_ScanForLights"),
    ScannerModule = getText("UI_RemoteLC_ScannerModule"),
    Slow = getText("UI_RemoteLC_Slow"),
    ToggleOff = getText("UI_RemoteLC_ToggleOff"),
    ToggleOn = getText("UI_RemoteLC_ToggleOn"),
    TotalLightsConnected = getText("UI_RemoteLC_TotalLightsConnected"),
    SelectColor = getText("UI_RemoteLC_SelectColor"),
    Open = getText("UI_RemoteLC_Open"),
    Close = getText("UI_RemoteLC_Close"),
    Brightness = getText("UI_RemoteLC_Brightness"),
}

local function getColors(numColors, numBrights)
    local colors = {}
    for bright=0,numBrights-1,1 do
        table.insert(colors, {r=bright/(numBrights-1), g=bright/(numBrights-1), b=bright/(numBrights-1), a=1})
    end
    for hue=0,numColors-2,1 do
        for bright=1,numBrights,1 do
            local color = Color.HSBtoRGB(hue/(numColors-1), 1.0, bright/numBrights)
            table.insert(colors, {r=color:getRedFloat(), g=color:getGreenFloat(), b=color:getBlueFloat(), a=1})
        end
    end
    return colors
end

-- Make the color picker not render borders on the boxes
-- local function colorPickerRenderOverride(self)
--     ISPanelJoypad.render(self)
--     for i,color in ipairs(self.colors) do
--         local col = (i-1) % self.columns
--         local row = math.floor((i-1) / self.columns)
--         self:drawRect(self.borderSize + col * self.buttonSize, self.borderSize + row * self.buttonSize, self.buttonSize, self.buttonSize, 1.0, color.r, color.g, color.b)
--     end
--     -- for col=1,self.columns do
--     --     self:drawRect(self.borderSize + col * self.buttonSize, self.borderSize, 1, self.buttonSize * self.rows, 1.0, 0.0, 0.0, 0.0)
--     -- end
--     -- for row=1,self.rows do
--     --     self:drawRect(self.borderSize, self.borderSize + row * self.buttonSize, self.buttonSize * self.columns, 1, 1.0, 0.0, 0.0, 0.0)
--     -- end

--     local col = (self.index-1) % self.columns
--     local row = math.floor((self.index-1) / self.columns)
--     self:drawRectBorder(self.borderSize + col * self.buttonSize, self.borderSize + row * self.buttonSize, self.buttonSize + 1, self.buttonSize + 1, 1.0, 1.0, 1.0, 1.0)

--     if self.joyfocus then
--         self:drawRectBorder(0, -self:getYScroll(), self:getWidth(), self:getHeight(), 0.4, 0.2, 1.0, 1.0);
--         self:drawRectBorder(1, 1-self:getYScroll(), self:getWidth()-2, self:getHeight()-2, 0.4, 0.2, 1.0, 1.0);
--     end
-- end

function RemoteLC_ControllerUI:new(player, controller)
    local width = 275
    local height = 300
    if not controller.isRGB then height = height + 30 end
    local playerModData = player:getModData()
    if not playerModData.RemoteLC_ControllerUI_X or not playerModData.RemoteLC_ControllerUI_Y then
        playerModData.RemoteLC_ControllerUI_X = getPlayerScreenLeft(player:getPlayerNum()) + (getPlayerScreenWidth(player:getPlayerNum()) - width) / 2
        playerModData.RemoteLC_ControllerUI_Y = getPlayerScreenTop(player:getPlayerNum()) + (getPlayerScreenHeight(player:getPlayerNum()) - height) / 2
    end
    local o = ISPanelJoypad.new(self, playerModData.RemoteLC_ControllerUI_X, playerModData.RemoteLC_ControllerUI_Y, width, height)
    o.controller = controller
    RemoteLC_ControllerUI.instance[controller:getId()] = o
    return o
end

function RemoteLC_ControllerUI:initialise()
    self.borderColor = {r=0.4, g=0.4, b=0.4, a=1}
    self.backgroundColor = {r=0, g=0, b=0, a=1}
    self.buttonBorderColor = {r=0.7, g=0.7, b=0.7, a=1}
    self.sectionBorderColor = {r=0.4, g=0.4, b=0.4, a=1}
    self.sectionBackgroundColor = {r=0.2, g=0.2, b=0.2, a=1}
    self.moveWithMouse = true
    self.isRGB = self.controller.isRGB

    ISPanelJoypad.initialise(self)

    local window = GravyUI.Node(self.width, self.height)
    local paddedWindow = window:pad(2)
    local splits = {0.2, 0.4, 0.4}
    if not self.isRGB then
        splits = {0.2, 0.45, 0.35}
    end
    local topSection, middleSection, bottomSection = paddedWindow:rows(splits)
    self.titleSlot, self.infoSlot = topSection:rows({0.3, 0.7}, 5)
    local middleLeftCol, middleRightCol = middleSection:cols(2, 5)
    local directControlSection, scannerSection = middleLeftCol:pad(5), middleRightCol:pad(5)
    local lightShowSection = bottomSection:pad(5)

    self:initDirectControl(directControlSection)
    self:initScanner(scannerSection)
    self:initLightShow(lightShowSection)

    if self.isRGB then
        self:initColorPicker()
    end

    -- Close Button
    self.closeButton = window:corner("topRight", 20, 20):makeButton("X", self, RemoteLC_ControllerUI.close)
    self.closeButton.borderColor = self.borderColor
    self:addChild(self.closeButton)

	self:insertNewLineOfButtons(self.toggleOnButton, self.toggleOffButton)
    self:insertNewLineOfButtons(self.scanButton, self.clearLightsButton)
    self:insertNewLineOfButtons(self.startLightShowButton, self.stopLightShowButton)
    self:insertNewLineOfButtons(self.pauseLightShowButton, self.resumeLightShowButton)
    self:insertNewLineOfButtons(self.rgbTestButton, self.closeButton)
    self:updateUI()

    self.intialized = true
end

--- @param node GravyUI.Node
function RemoteLC_ControllerUI:initDirectControl(node)
    self.directControlSection = node
    self.directControlTitleNode, node = node:pad(5):rows({12, 1}, 5)
    local selectorNode, brightnessNode, toggleOnNode, toggleOffNode

    if self.isRGB then
        selectorNode,toggleOnNode, toggleOffNode = node:rows(3, 5)
        self.selectColorButton = selectorNode:makeButton(TEXTS.Open, self, RemoteLC_ControllerUI.selectColor)
        self.selectColorButton.borderColor = self.buttonBorderColor
        self:addChild(self.selectColorButton)
    else
        selectorNode, brightnessNode, toggleOnNode, toggleOffNode = node:rows({0.2, 0.4, 0.2, 0.2}, 5)
        self.colorComboBox = selectorNode:makeComboBox()
        self:addChild(self.colorComboBox)

        local brightnessTitleNode, brightnessSliderNode = brightnessNode:rows(2, 2)
        self.brightnessTitleSlot = brightnessTitleNode

        self.brightnessSlider = brightnessSliderNode:makeSlider(self, function(s,v) s:setBrightness(v) end)
        self.brightnessSlider:setCurrentValue(100)
        self:addChild(self.brightnessSlider)
    end

    self.toggleOnButton = toggleOnNode:makeButton(TEXTS.ToggleOn, self, RemoteLC_ControllerUI.toggleLights, {true})
    self.toggleOnButton.borderColor = self.buttonBorderColor
    self:addChild(self.toggleOnButton)

    self.toggleOffButton = toggleOffNode:makeButton(TEXTS.ToggleOff, self, RemoteLC_ControllerUI.toggleLights, {false})
    self.toggleOffButton.borderColor = self.buttonBorderColor
    self:addChild(self.toggleOffButton)
end

--- @param node GravyUI.Node
function RemoteLC_ControllerUI:initScanner(node)
    self.scannerSection = node
    self.scannerTitleNode, node = node:pad(5):rows({12, 1}, 5)
    local rangeNode, findNode, clearNode = node:rows(3, 5)

    self.rangeComboBox = rangeNode:makeComboBox()
    self:addChild(self.rangeComboBox)
    self.rangeComboBox:addOptionWithData(getText("UI_RemoteLC_Range", tostring(1)), 1)
    self.rangeComboBox:addOptionWithData(getText("UI_RemoteLC_Range", tostring(5)), 5)
    self.rangeComboBox:addOptionWithData(getText("UI_RemoteLC_Range", tostring(10)), 10)
    self.rangeComboBox:addOptionWithData(getText("UI_RemoteLC_Range", tostring(20)), 20)
    self.rangeComboBox.selected = 3

    self.scanButton = findNode:makeButton(TEXTS.ScanForLights, self, RemoteLC_ControllerUI.scanForLights)
    self.scanButton.borderColor = self.buttonBorderColor
    self:addChild(self.scanButton)

    self.clearLightsButton = clearNode:makeButton(TEXTS.ClearLights, self, RemoteLC_ControllerUI.clearLights)
    self.clearLightsButton.borderColor = self.buttonBorderColor
    self:addChild(self.clearLightsButton)
end

--- @param node GravyUI.Node
function RemoteLC_ControllerUI:initLightShow(node)
    self.lightShowSection = node
    local titleNode, bodyNode = node:pad(5):rows({20, 1}, 5)
    self.lightShowTitleNode = titleNode
    local row1, row2, row3 = bodyNode:grid(3, 2, 5, 5)
    local speedNode, modeNode = GravyUI.unpack(row1)
    local activateNode, deactiveNode = GravyUI.unpack(row2)
    local pauseNode, resumeNode = GravyUI.unpack(row3)

    self.speedComboBox = speedNode:makeComboBox()
    self:addChild(self.speedComboBox)
    self.speedComboBox:addOptionWithData(TEXTS.Slow, "Slow")
    self.speedComboBox:addOptionWithData(TEXTS.Normal, "Normal")
    self.speedComboBox:addOptionWithData(TEXTS.Quick, "Quick")

    self.startLightShowButton = activateNode:makeButton(TEXTS.Activate, self, RemoteLC_ControllerUI.startLightShow)
    self.startLightShowButton.borderColor = self.buttonBorderColor
    self:addChild(self.startLightShowButton)

    self.stopLightShowButton = deactiveNode:makeButton(TEXTS.Deactivate, self, RemoteLC_ControllerUI.stopLightShow)
    self.stopLightShowButton.borderColor = self.buttonBorderColor
    self:addChild(self.stopLightShowButton)

    self.pauseLightShowButton = pauseNode:makeButton(TEXTS.Pause, self, RemoteLC_ControllerUI.pauseLightShow)
    self.pauseLightShowButton.borderColor = self.buttonBorderColor
    self:addChild(self.pauseLightShowButton)

    self.resumeLightShowButton = resumeNode:makeButton(TEXTS.Resume, self, RemoteLC_ControllerUI.resumeLightShow)
    self.resumeLightShowButton.borderColor = self.buttonBorderColor
    self:addChild(self.resumeLightShowButton)

    self.modeComboBox = modeNode:makeComboBox()
    self:addChild(self.modeComboBox)
    local modes
    if self.isRGB then
        modes = RemoteLC_LightShow.GetModes("RGB")
    else
        modes = RemoteLC_LightShow.GetModes("Standard")
    end
    for mode, modeData in pairs(modes) do
        self.modeComboBox:addOptionWithData(modeData.name, mode)
    end
end

-- TODO: Clean Up, maybe move to a module
function RemoteLC_ControllerUI:initColorPicker()
    local rows = 10
    local cols = 8
    local colors = getColors(rows, cols)
    self.colorPicker = ISColorPicker:new(0, 0, nil)
    self.colorPicker:initialise()
    self.colorPicker.keepOnScreen = true
    self.colorPicker.buttonSize = 20
    self.colorPicker:setColors(colors, cols, rows)
    self.colorPicker.pickedTarget = self
    self.colorPicker:setPickedFunc(RemoteLC_ControllerUI.setColor)
    self.colorPicker.removeSelfOriginal = self.colorPicker.removeSelf
    self.colorPicker.removeSelf = function() end -- we will close when needed
    self.colorPicker.otherFct = true
    self.colorPicker.originalOnMouseUp = self.colorPicker.onMouseUp
    -- self.colorPicker.render = colorPickerRenderOverride
    self.colorPicker.onMouseUp = function(self, dx, dy) -- prevents choosing color when not clicking on a color
        local x = self:getMouseX()
        local y = self:getMouseY()
        local col = math.floor((x - self.borderSize) / self.buttonSize)
        local row = math.floor((y - self.borderSize) / self.buttonSize)
        if col < 0 then return true end
        if col >= self.columns then return true end
        if row < 0 then return true end
        if row >= self.rows then return true end
        return self:originalOnMouseUp(dx, dy)
    end

    -- make colorPicker move with the UI window
    self.onMouseMoveOriginal = self.onMouseMove
    self.onMouseMove = function(self, x, y)
        self:onMouseMoveOriginal(x, y)
        if self.colorPicker then
            self.colorPicker:setX(self:getX() - self.colorPicker:getWidth())
            self.colorPicker:setY(self:getY(0))
        end
    end

    local colorSliderTop = self.colorPicker.height + 2
    local colorSliderLeft = self.colorPicker.borderSize
    local colorSliderWidth = self.colorPicker.width - self.colorPicker.borderSize * 2
    local colorSliderHeight = 10

    self.colorSliderR = ISSliderPanel:new(colorSliderLeft, colorSliderTop, colorSliderWidth, colorSliderHeight, self, function(s,c) s:setColorCustom("r", c/100) end)
    self.colorSliderR:initialise()
    self.colorSliderR:instantiate()
    self.colorSliderR.sliderColor = {r=0.8, g=0.0, b=0.0, a=1.0}
    self.colorSliderR.sliderMouseOverColor = {r=1.0, g=0.0, b=0.0, a=1.0}
    self.colorSliderR:setDoButtons(false)
    self.colorPicker:addChild(self.colorSliderR)
    colorSliderTop = colorSliderTop + colorSliderHeight + ELEMENT_PADDING

    self.colorSliderG = ISSliderPanel:new(colorSliderLeft, colorSliderTop, colorSliderWidth, colorSliderHeight, self, function(s,c) s:setColorCustom("g", c/100) end)
    self.colorSliderG:initialise()
    self.colorSliderG:instantiate()
    self.colorSliderG.sliderColor = {r=0.0, g=0.8, b=0.0, a=1.0}
    self.colorSliderG.sliderMouseOverColor = {r=0.0, g=1.0, b=0.0, a=1.0}
    self.colorSliderG:setDoButtons(false)
    self.colorPicker:addChild(self.colorSliderG)
    colorSliderTop = colorSliderTop + colorSliderHeight + ELEMENT_PADDING

    self.colorSliderB = ISSliderPanel:new(colorSliderLeft, colorSliderTop, colorSliderWidth, colorSliderHeight, self, function(s,c) s:setColorCustom("b", c/100) end)
    self.colorSliderB:initialise()
    self.colorSliderB:instantiate()
    self.colorSliderB.sliderColor = {r=0.2, g=0.2, b=0.9, a=1.0}
    self.colorSliderB.sliderMouseOverColor = {r=0.2, g=0.2, b=1.0, a=1.0}
    self.colorSliderB:setDoButtons(false)
    self.colorPicker:addChild(self.colorSliderB)
    colorSliderTop = colorSliderTop + colorSliderHeight + ELEMENT_PADDING

    self.colorPicker:setHeight(colorSliderTop + self.colorPicker.borderSize)
end

function RemoteLC_ControllerUI:prerender()
    local playerModData = getPlayer():getModData()
    playerModData.RemoteLC_ControllerUI_X = self:getX()
    playerModData.RemoteLC_ControllerUI_Y = self:getY()

    local now = getTimestampMs()
    if now - (self.lastHoldingCheck or 0) > 500 then
        local player = getPlayer()
        self.lastHoldingCheck = now
        if not self.controller:isOnPlayer(player, self.fromEquip) then
            self:close()
            return
        end
    end

    if self.isRGB then
        if UIManager.UI:contains(self.colorPicker.javaObject) then
            self.selectColorButton:setTitle(TEXTS.Close)
        else
            self.selectColorButton:setTitle(TEXTS.Open)
        end
    end

    -- window
    self:drawRect(0, 0, self.width, self.height, self.backgroundColor.a, self.backgroundColor.r, self.backgroundColor.g, self.backgroundColor.b)
    self:drawRectBorder(0, 0, self.width, self.height, self.borderColor.a, self.borderColor.r, self.borderColor.g, self.borderColor.b)

    if self.isRGB then
        if TEXTS.RGBRemoteLightsController == "RGB Lights Controller" then -- something special for english
            local textManager = getTextManager()
            local fullTextWidth = textManager:MeasureStringX(UIFont.Medium, "RGB Lights Controller")
            local start = self.titleSlot.left + self.titleSlot.width/2 - fullTextWidth/2
            local gLeft = start + textManager:MeasureStringX(UIFont.Medium, "R")
            local bLeft = gLeft + textManager:MeasureStringX(UIFont.Medium, "G")
            local remainderLeft = bLeft + textManager:MeasureStringX(UIFont.Medium, "B") + 3
            self:drawText("R", start, self.titleSlot.top, 1, 0, 0, 1, UIFont.Medium)
            self:drawText("G", gLeft, self.titleSlot.top, 0, 1, 0, 1, UIFont.Medium)
            self:drawText("B", bLeft, self.titleSlot.top, 0.2, 0.2, 1, 1, UIFont.Medium)
            self:drawText(" Lights Controller", remainderLeft, self.titleSlot.top, 1, 1, 1, 1, UIFont.Medium)
        else
            self:drawTextCentre(TEXTS.RGBRemoteLightsController, self.titleSlot.left + self.titleSlot.width/2, self.titleSlot.top, 1, 1, 1, 1, UIFont.Medium)
        end
    else
        self:drawTextCentre(TEXTS.RemoteLightsController, self.titleSlot.left + self.titleSlot.width/2, self.titleSlot.top, 1, 1, 1, 1, UIFont.Medium)

    end

    self.directControlSection:drawRect(self, self.sectionBackgroundColor.a, self.sectionBackgroundColor.r, self.sectionBackgroundColor.g, self.sectionBackgroundColor.b)
    self.directControlSection:drawRectBorder(self, self.sectionBorderColor.a, self.sectionBorderColor.r, self.sectionBorderColor.g, self.sectionBorderColor.b)
    self:drawTextCentre(TEXTS.DirectLightControl, self.directControlTitleNode.left + self.directControlTitleNode.width/2, self.directControlTitleNode.top, 1.0, 1.0, 1.0, 1.0, UIFont.Small)
    if not self.isRGB then
        self:drawText(TEXTS.Brightness, self.brightnessTitleSlot.left, self.brightnessTitleSlot.top, 1.0, 1.0, 1.0, 1.0, UIFont.Small)
    end


    self.scannerSection:drawRect(self, self.sectionBackgroundColor.a, self.sectionBackgroundColor.r, self.sectionBackgroundColor.g, self.sectionBackgroundColor.b)
    self.scannerSection:drawRectBorder(self, self.sectionBorderColor.a, self.sectionBorderColor.r, self.sectionBorderColor.g, self.sectionBorderColor.b)
    self:drawTextCentre(TEXTS.ScannerModule, self.scannerTitleNode.left + self.scannerTitleNode.width/2, self.scannerTitleNode.top, 1.0, 1.0, 1.0, 1.0, UIFont.Small)


    self.lightShowSection:drawRect(self, self.sectionBackgroundColor.a, self.sectionBackgroundColor.r, self.sectionBackgroundColor.g, self.sectionBackgroundColor.b)
    self.lightShowSection:drawRectBorder(self, self.sectionBorderColor.a, self.sectionBorderColor.r, self.sectionBorderColor.g, self.sectionBorderColor.b)
    self:drawTextCentre(TEXTS.LightShowModule, self.lightShowTitleNode.left + self.lightShowTitleNode.width/2, self.lightShowTitleNode.top, 1.0, 1.0, 1.0, 1.0, UIFont.Small)
end

function RemoteLC_ControllerUI:render()
	ISPanelJoypad.render(self)

    local countOfLights = tostring(self.menuData.countOfLights or 0)
    local status = "Unknown"

    if self.menuData.isRunning then
        if self.menuData.isPaused then
            status = TEXTS.Paused
        else
            status = TEXTS.Running
        end
    else
        status = TEXTS.Off
    end

    local slotOne, slotTwo = self.infoSlot:pad(5, 0):rows(2, 2)
    local textWidth = textManager:MeasureStringX(UIFont.Small, TEXTS.TotalLightsConnected)
    self:drawText(TEXTS.TotalLightsConnected, slotOne.left, slotOne.top, 1, 1, 1, 0.5, UIFont.Small)
    self:drawText(countOfLights, slotOne.left + textWidth, slotOne.top, 1, 1, 1, 0.8, UIFont.Small)

    local textWidth = textManager:MeasureStringX(UIFont.Small, TEXTS.LightShowStatus)
    self:drawText(TEXTS.LightShowStatus, slotTwo.left, slotTwo.top, 1, 1, 1, 0.5, UIFont.Small)
    self:drawText(status, slotTwo.left + textWidth, slotTwo.top, 1, 1, 1, 0.8, UIFont.Small)
end

function RemoteLC_ControllerUI:updateColors()
    if self.isRGB then
        self.selectColorButton.backgroundColor = self.menuData.color
        self.selectColorButton.backgroundColorMouseOver = self.menuData.color
        self.colorSliderR:setCurrentValue(math.floor(self.menuData.color.r*100), true)
        self.colorSliderG:setCurrentValue(math.floor(self.menuData.color.g*100), true)
        self.colorSliderB:setCurrentValue(math.floor(self.menuData.color.b*100), true)
        return
    end

    local selectedColor = "All"
    if #self.colorComboBox.options > 0 then
        selectedColor = self.colorComboBox.options[self.colorComboBox.selected].data
    end
    self.colorComboBox:clear()
    self.colorComboBox:addOptionWithData(TEXTS.All, "All")
    for color, count in pairs(self.menuData.countOfLightsByColor) do
        if count > 0 then
            self.colorComboBox:addOptionWithData(getText("ContextMenu_" .. color), color)
        end
    end
    self.colorComboBox.selected = 1
    for i, option in ipairs(self.colorComboBox.options) do
        if option.data == selectedColor then
            self.colorComboBox.selected = i
            break
        end
    end
end

function RemoteLC_ControllerUI:updateUI()
    self:updateMenuData()
    self:updateColors()

    self.speedComboBox.selected = 1
    for i, option in ipairs(self.speedComboBox.options) do
        if option.data == self.menuData.speed then
            self.speedComboBox.selected = i
            break
        end
    end

    self.modeComboBox.selected = 1
    for i, option in ipairs(self.modeComboBox.options) do
        if option.data == self.menuData.mode then
            self.modeComboBox.selected = i
            break
        end
    end

    if self.menuData.isRunning then
        self.toggleOnButton.enable = false
        self.toggleOffButton.enable = false
        self.clearLightsButton.enable = false
        self.scanButton.enable = false
        self.startLightShowButton.enable = false
        self.stopLightShowButton.enable = true
        if self.menuData.isPaused then
            self.pauseLightShowButton.enable = false
            self.resumeLightShowButton.enable = true
        else
            self.pauseLightShowButton.enable = true
            self.resumeLightShowButton.enable = false
        end
    else
        self.toggleOnButton.enable = true
        self.toggleOffButton.enable = true
        self.clearLightsButton.enable = true
        self.scanButton.enable = true
        self.startLightShowButton.enable = true
        self.stopLightShowButton.enable = false
        self.pauseLightShowButton.enable = false
        self.resumeLightShowButton.enable = false
    end
end

function RemoteLC_ControllerUI:updateMenuData()
    self.menuData = self.controller:getMenuData()
end

function RemoteLC_ControllerUI:updateSelectedColor()
    if self.isRGB or #self.colorComboBox.options == 0 then
        return nil
    end
    self.selectedColor = self.colorComboBox.options[self.colorComboBox.selected].data
    return self.selectedColor
end

function RemoteLC_ControllerUI:sendSelectables()
    if not self.intialized then
        return
    end
    self:sendSelectedSpeed()
    self:sendSelectedMode()
end

function RemoteLC_ControllerUI:sendSelectedSpeed()
    if #self.speedComboBox.options == 0 then
        return nil
    end
    self.selectedSpeed = self.speedComboBox.options[self.speedComboBox.selected].data
    self.controller:setSpeed(self.selectedSpeed)
    return self.selectedSpeed
end

function RemoteLC_ControllerUI:sendSelectedMode()
    if #self.modeComboBox.options == 0 then
        return nil
    end
    self.selectedMode = self.modeComboBox.options[self.modeComboBox.selected].data
    self.controller:setMode(self.selectedMode)
    return self.selectedMode
end

function RemoteLC_ControllerUI:scanForLights()
    if not self.intialized then
        return
    end
    self:sendSelectables()
    local range = self.rangeComboBox.options[self.rangeComboBox.selected].data
    if range then
        self.controller:scanForLights(getPlayer(), range)
    end
    self:updateUI()
end

function RemoteLC_ControllerUI:clearLights()
    if not self.intialized then
        return
    end
    self:sendSelectables()
    self.controller:clearLights()
    self:updateUI()
end

function RemoteLC_ControllerUI:toggleLights(_, state)
    if not self.intialized then
        return
    end
    self:sendSelectables()
    if self.isRGB then
        self.controller:toggleLights(state)
    else
        local color = self:updateSelectedColor()
        if color then
            self.controller:toggleLights(state, color)
        end
    end
end

function RemoteLC_ControllerUI:startLightShow()
    if not self.intialized then
        return
    end
    self:sendSelectables()
    self.controller:startLightShow()
    self:updateUI()
end

function RemoteLC_ControllerUI:stopLightShow()
    if not self.intialized then
        return
    end
    self:sendSelectables()
    self.controller:stopLightShow()
    self:updateUI()
end

function RemoteLC_ControllerUI:pauseLightShow()
    if not self.intialized then
        return
    end
    self:sendSelectables()
    self.controller:setPaused(true)
    self:updateUI()
end

function RemoteLC_ControllerUI:resumeLightShow()
    if not self.intialized then
        return
    end
    self:sendSelectables()
    self.controller:setPaused(false)
    self:updateUI()
end

function RemoteLC_ControllerUI:setBrightness(value)
    value = value / 100

    if value > 1.0 then
        value = 1.0
    elseif value < 0 then
        value = 0.0
    end

    if not self.intialized or self.isRGB then
        return
    end

    self:sendSelectables()
    self.controller:setBrightness(value)
    self:updateUI()
end

function RemoteLC_ControllerUI:selectColor()
    if not self.intialized or not self.isRGB then
        return
    end

    if not UIManager.UI:contains(self.colorPicker.javaObject) then
        self.colorPicker:setX(self:getX() - self.colorPicker:getWidth())
        self.colorPicker:setY(self:getY())
        self.colorPicker:addToUIManager()
    else
        self.colorPicker:removeSelfOriginal()
    end
end

function RemoteLC_ControllerUI:setColor(color)
    if not self.intialized or not self.isRGB then
        return
    end
    self.colorPicker.mouseDown = false
    self.controller:setColor(color)
    self.controller:toggleLights(true)
    self.colorSliderR:setCurrentValue(color.r * 100)
    self.colorSliderG:setCurrentValue(color.g * 100)
    self.colorSliderB:setCurrentValue(color.b * 100)
    self:sendSelectables()
    self:updateUI()
end

function RemoteLC_ControllerUI:setColorCustom(component, value)
    if not self.intialized or not self.isRGB then
        return
    end
    local color = {r = self.menuData.color.r, g = self.menuData.color.g, b = self.menuData.color.b, a = self.menuData.color.a}
    color[component] = value
    self.controller:setColor(color)
    self.colorPicker:setInitialColor(Color.new(color.r, color.g, color.b, color.a))
    self:sendSelectables()
    self:updateUI()
end

function RemoteLC_ControllerUI:close()
    RemoteLC_ControllerUI.instance[self.controller:getId()] = nil
    self:sendSelectables()
    self:setVisible(false)
    if self.colorPicker then self.colorPicker:removeSelfOriginal() end
    self:removeFromUIManager()
    local playerNum = getPlayer():getPlayerNum()
    if JoypadState.players[playerNum+1] then
        setJoypadFocus(playerNum, nil)
    end
end
