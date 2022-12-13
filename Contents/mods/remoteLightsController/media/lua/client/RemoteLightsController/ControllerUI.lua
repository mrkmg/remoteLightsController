RemoteLC_ControllerUI = ISPanelJoypad:derive("RemoteLC_ControllerUI")
RemoteLC_ControllerUI.instance = {}
RemoteLC_ControllerUI.messages = {}

local textManager = getTextManager()
local FONT_SMALL_HEIGHT = textManager:getFontHeight(UIFont.Small)
local FONT_MEDIUM_HEIGHT = textManager:getFontHeight(UIFont.Medium)
local BUTTON_HEIGHT = math.max(FONT_SMALL_HEIGHT + 3 * 2, 25)
local CLOSE_BUTTON_SIZE = 20
local EDGE_PADDING = 12
local ELEMENT_PADDING = 5
local SECTION_PADDING = 20
local SECTION_BORDER_PADDING = 5
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

function RemoteLC_ControllerUI:initialise()
    self.borderColor = {r=0.4, g=0.4, b=0.4, a=1}
    self.backgroundColor = {r=0, g=0, b=0, a=1}
    self.buttonBorderColor = {r=0.7, g=0.7, b=0.7, a=1}
    self.sectionBorderColor = {r=0.4, g=0.4, b=0.4, a=1}
    self.sectionBackgroundColor = {r=0.2, g=0.2, b=0.2, a=1}
    self.moveWithMouse = true
    self.isRGB = self.controller.isRGB

    ISPanelJoypad.initialise(self)

    self.widths = {
        ClearLights = textManager:MeasureStringX(UIFont.Small, TEXTS.ClearLights),
        DirectLightControl = textManager:MeasureStringX(UIFont.Small, TEXTS.DirectLightControl),
        LightShowStatus = textManager:MeasureStringX(UIFont.Small, TEXTS.LightShowStatus),
        ScanForLights = textManager:MeasureStringX(UIFont.Small, TEXTS.ScanForLights),
        ScannerModule = textManager:MeasureStringX(UIFont.Small, TEXTS.ScannerModule),
        ToggleOff = textManager:MeasureStringX(UIFont.Small, TEXTS.ToggleOff),
        ToggleOn = textManager:MeasureStringX(UIFont.Small, TEXTS.ToggleOn),
        TotalLightsConnected = textManager:MeasureStringX(UIFont.Small, TEXTS.TotalLightsConnected),
    }
    self.halfSectionWidth = math.max(
        self.widths.DirectLightControl,
        self.widths.ScannerModule,
        self.widths.ToggleOn,
        self.widths.ToggleOff,
        self.widths.ScanForLights,
        self.widths.ClearLights
    )
    self.fullSectionWidth = self.halfSectionWidth * 2 + SECTION_PADDING

    local sectionStartTop =
        FONT_MEDIUM_HEIGHT + ELEMENT_PADDING + -- Title
        FONT_SMALL_HEIGHT + ELEMENT_PADDING +  -- Total Lights
        FONT_SMALL_HEIGHT + ELEMENT_PADDING +  -- Light Show Status
        SECTION_PADDING +                      -- Padding under header
        FONT_SMALL_HEIGHT + ELEMENT_PADDING    -- Section Titles

    local columnTop = sectionStartTop
    -- Toggle Section
    local left = EDGE_PADDING
    if self.isRGB then
        self.selectColorButton = ISButton:new(left, columnTop, self.halfSectionWidth, BUTTON_HEIGHT, TEXTS.Open, self)
        self.selectColorButton.anchorLeft = true
        self.selectColorButton.anchorTop = true
        self.selectColorButton:setOnClick(RemoteLC_ControllerUI.selectColor, self)
        self.selectColorButton:initialise()
        self.selectColorButton:instantiate()
        self.selectColorButton.borderColor = self.buttonBorderColor
        self:addChild(self.selectColorButton)
        columnTop = columnTop + BUTTON_HEIGHT + ELEMENT_PADDING
    else
        self.colorComboBox = ISComboBox:new(left, columnTop, self.halfSectionWidth, BUTTON_HEIGHT)
        self.colorComboBox:initialise()
        self:addChild(self.colorComboBox)
        columnTop = columnTop + BUTTON_HEIGHT + ELEMENT_PADDING

        self.brightnessLabelPosition = {x=left, y=columnTop}
        columnTop = columnTop + FONT_SMALL_HEIGHT + ELEMENT_PADDING -- brightness Title

        self.brightnessSlider = ISSliderPanel:new(left, columnTop, self.halfSectionWidth, 10, self, function(s,v) s:setBrightness(v/100) end)
        self.brightnessSlider:initialise()
        self.brightnessSlider:instantiate()
        self.brightnessSlider:setCurrentValue(100)
        self:addChild(self.brightnessSlider)
        columnTop = columnTop + 10 + ELEMENT_PADDING
    end

    self.toggleOnButton = ISButton:new(left, columnTop, self.halfSectionWidth, BUTTON_HEIGHT, TEXTS.ToggleOn, self)
    self.toggleOnButton.anchorLeft = true
    self.toggleOnButton.anchorTop = true
    self.toggleOnButton:setOnClick(RemoteLC_ControllerUI.toggleLights, true)
    self.toggleOnButton:initialise()
    self.toggleOnButton:instantiate()
    self.toggleOnButton.borderColor = self.buttonBorderColor
    self:addChild(self.toggleOnButton)
    columnTop = columnTop + BUTTON_HEIGHT + ELEMENT_PADDING

    self.toggleOffButton = ISButton:new(left, columnTop, self.halfSectionWidth, BUTTON_HEIGHT, TEXTS.ToggleOff, self)
    self.toggleOffButton.anchorLeft = true
    self.toggleOffButton.anchorTop = true
    self.toggleOffButton:setOnClick(RemoteLC_ControllerUI.toggleLights, false)
    self.toggleOffButton:initialise()
    self.toggleOffButton:instantiate()
    self.toggleOffButton.borderColor = self.buttonBorderColor
    self:addChild(self.toggleOffButton)
    columnTop = columnTop + BUTTON_HEIGHT + ELEMENT_PADDING

    local firstColumnBottom = columnTop

    -- Scanner Section
    left = EDGE_PADDING + self.halfSectionWidth + SECTION_PADDING
    columnTop = sectionStartTop

    self.rangeComboBox = ISComboBox:new(left, columnTop, self.halfSectionWidth, BUTTON_HEIGHT)
    self.rangeComboBox:initialise()
    self:addChild(self.rangeComboBox)
    self.rangeComboBox:addOptionWithData(getText("UI_RemoteLC_Range", tostring(1)), 1)
    self.rangeComboBox:addOptionWithData(getText("UI_RemoteLC_Range", tostring(5)), 5)
    self.rangeComboBox:addOptionWithData(getText("UI_RemoteLC_Range", tostring(10)), 10)
    self.rangeComboBox:addOptionWithData(getText("UI_RemoteLC_Range", tostring(20)), 20)
    self.rangeComboBox.selected = 3
    columnTop = columnTop + BUTTON_HEIGHT + ELEMENT_PADDING

    self.scanButton = ISButton:new(left, columnTop, self.halfSectionWidth, BUTTON_HEIGHT, TEXTS.ScanForLights, self)
    self.scanButton.anchorLeft = true
    self.scanButton.anchorTop = true
    self.scanButton:setOnClick(RemoteLC_ControllerUI.scanForLights)
    self.scanButton:initialise()
    self.scanButton:instantiate()
    self.scanButton.borderColor = self.buttonBorderColor
    self:addChild(self.scanButton)
    columnTop = columnTop + BUTTON_HEIGHT + ELEMENT_PADDING

    self.clearLightsButton = ISButton:new(left, columnTop, self.halfSectionWidth, BUTTON_HEIGHT, TEXTS.ClearLights, self)
    self.clearLightsButton.anchorLeft = true
    self.clearLightsButton.anchorTop = true
    self.clearLightsButton:setOnClick(RemoteLC_ControllerUI.clearLights)
    self.clearLightsButton:initialise()
    self.clearLightsButton:instantiate()
    self.clearLightsButton.borderColor = self.buttonBorderColor
    self:addChild(self.clearLightsButton)
    columnTop = columnTop + BUTTON_HEIGHT + ELEMENT_PADDING

    -- Light Show Section
    local lightShowTotalWidth = self.fullSectionWidth
    local lightShowColumnWidth = math.ceil((lightShowTotalWidth - ELEMENT_PADDING) / 2)
    local lightShowSectionTop = math.max(columnTop, firstColumnBottom) + SECTION_PADDING + FONT_SMALL_HEIGHT + ELEMENT_PADDING
    -- Light Show Left Column
    left = EDGE_PADDING
    columnTop = lightShowSectionTop
    self.speedComboBox = ISComboBox:new(left, columnTop, lightShowColumnWidth, BUTTON_HEIGHT)
    self.speedComboBox:initialise()
    self:addChild(self.speedComboBox)
    self.speedComboBox:addOptionWithData(TEXTS.Slow, "Slow")
    self.speedComboBox:addOptionWithData(TEXTS.Normal, "Normal")
    self.speedComboBox:addOptionWithData(TEXTS.Quick, "Quick")
    columnTop = columnTop + BUTTON_HEIGHT + ELEMENT_PADDING

    self.startLightShowButton = ISButton:new(left, columnTop, lightShowColumnWidth, BUTTON_HEIGHT, TEXTS.Activate, self)
    self.startLightShowButton.anchorTop = true
    self.startLightShowButton:setOnClick(RemoteLC_ControllerUI.startLightShow)
    self.startLightShowButton:initialise()
    self.startLightShowButton:instantiate()
    self.startLightShowButton.borderColor = self.buttonBorderColor
    self:addChild(self.startLightShowButton)
    columnTop = columnTop + BUTTON_HEIGHT + ELEMENT_PADDING

    self.pauseLightShowButton = ISButton:new(left, columnTop, lightShowColumnWidth, BUTTON_HEIGHT, TEXTS.Pause, self)
    self.pauseLightShowButton.anchorTop = true
    self.pauseLightShowButton:setOnClick(RemoteLC_ControllerUI.pauseLightShow)
    self.pauseLightShowButton:initialise()
    self.pauseLightShowButton:instantiate()
    self.pauseLightShowButton.borderColor = self.buttonBorderColor
    self:addChild(self.pauseLightShowButton)
    columnTop = columnTop + BUTTON_HEIGHT + ELEMENT_PADDING

    -- Light Show Right Column
    columnTop = lightShowSectionTop
    left = EDGE_PADDING + lightShowColumnWidth + ELEMENT_PADDING
    self.modeComboBox = ISComboBox:new(left, columnTop, lightShowColumnWidth, BUTTON_HEIGHT)
    self.modeComboBox:initialise()
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
    columnTop = columnTop + BUTTON_HEIGHT + ELEMENT_PADDING

    self.stopLightShowButton = ISButton:new(left, columnTop, lightShowColumnWidth, BUTTON_HEIGHT, TEXTS.Deactivate, self)
    self.stopLightShowButton.anchorTop = true
    self.stopLightShowButton:setOnClick(RemoteLC_ControllerUI.stopLightShow)
    self.stopLightShowButton:initialise()
    self.stopLightShowButton:instantiate()
    self.stopLightShowButton.borderColor = self.buttonBorderColor
    self:addChild(self.stopLightShowButton)
    columnTop = columnTop + BUTTON_HEIGHT + ELEMENT_PADDING

    self.resumeLightShowButton = ISButton:new(left, columnTop, lightShowColumnWidth, BUTTON_HEIGHT, TEXTS.Resume, self)
    self.resumeLightShowButton.anchorTop = true
    self.resumeLightShowButton:setOnClick(RemoteLC_ControllerUI.resumeLightShow)
    self.resumeLightShowButton:initialise()
    self.resumeLightShowButton:instantiate()
    self.resumeLightShowButton.borderColor = self.buttonBorderColor
    self:addChild(self.resumeLightShowButton)
    columnTop = columnTop + BUTTON_HEIGHT + ELEMENT_PADDING

    self:setWidth(EDGE_PADDING * 2 + self.fullSectionWidth)
    self:setHeight(columnTop + EDGE_PADDING - ELEMENT_PADDING)

    if self.isRGB then
        local rows = 10
        local cols = 8
        local colors = getColors(rows, cols)
        self.colorPicker = ISColorPicker:new(0, 0, nil)
        self.colorPicker:initialise()
        self.colorPicker.keepOnScreen = true
        self.colorPicker:setColors(colors, cols, rows)
        self.colorPicker.pickedTarget = self
        self.colorPicker:setPickedFunc(RemoteLC_ControllerUI.setColor)
        self.colorPicker.removeSelfOriginal = self.colorPicker.removeSelf
        self.colorPicker.removeSelf = function() end -- we will close when needed
        self.colorPicker.otherFct = true
        self.colorPicker.originalOnMouseUp = self.colorPicker.onMouseUp
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

        self.colorSliderR = ISSliderPanel:new(colorSliderLeft, colorSliderTop, colorSliderWidth, BUTTON_HEIGHT, self, function(s,c) s:setColorCustom("r", c/100) end)
        self.colorSliderR:initialise()
        self.colorSliderR:instantiate()
        self.colorSliderR.sliderColor = {r=0.8, g=0.0, b=0.0, a=1.0}
        self.colorSliderR.sliderMouseOverColor = {r=1.0, g=0.0, b=0.0, a=1.0}
        self.colorSliderR:setDoButtons(false)
        self.colorPicker:addChild(self.colorSliderR)
        colorSliderTop = colorSliderTop + BUTTON_HEIGHT + ELEMENT_PADDING

        self.colorSliderG = ISSliderPanel:new(colorSliderLeft, colorSliderTop, colorSliderWidth, BUTTON_HEIGHT, self, function(s,c) s:setColorCustom("g", c/100) end)
        self.colorSliderG:initialise()
        self.colorSliderG:instantiate()
        self.colorSliderG.sliderColor = {r=0.0, g=0.8, b=0.0, a=1.0}
        self.colorSliderG.sliderMouseOverColor = {r=0.0, g=1.0, b=0.0, a=1.0}
        self.colorSliderG:setDoButtons(false)
        self.colorPicker:addChild(self.colorSliderG)
        colorSliderTop = colorSliderTop + BUTTON_HEIGHT + ELEMENT_PADDING

        self.colorSliderB = ISSliderPanel:new(colorSliderLeft, colorSliderTop, colorSliderWidth, BUTTON_HEIGHT, self, function(s,c) s:setColorCustom("b", c/100) end)
        self.colorSliderB:initialise()
        self.colorSliderB:instantiate()
        self.colorSliderB.sliderColor = {r=0.2, g=0.2, b=0.9, a=1.0}
        self.colorSliderB.sliderMouseOverColor = {r=0.2, g=0.2, b=1.0, a=1.0}
        self.colorSliderB:setDoButtons(false)
        self.colorPicker:addChild(self.colorSliderB)
        colorSliderTop = colorSliderTop + BUTTON_HEIGHT + ELEMENT_PADDING

        self.colorPicker:setHeight(colorSliderTop + self.colorPicker.borderSize)
    end

    -- Close Button
    self.closeButton = ISButton:new(self:getWidth() - CLOSE_BUTTON_SIZE, 0, CLOSE_BUTTON_SIZE, CLOSE_BUTTON_SIZE, "X", self, RemoteLC_ControllerUI.close)
    self.closeButton.anchorLeft = true
    self.closeButton.anchorTop = true
    self.closeButton:initialise()
    self.closeButton:instantiate()
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

    self:drawRect(0, 0, self.width, self.height, self.backgroundColor.a, self.backgroundColor.r, self.backgroundColor.g, self.backgroundColor.b)
    self:drawRectBorder(0, 0, self.width, self.height, self.borderColor.a, self.borderColor.r, self.borderColor.g, self.borderColor.b)

    local topSectionLeft, topSectionTop
    if self.isRGB then
        if TEXTS.RGBRemoteLightsController == "RGB Lights Controller" then -- something special for english
            local textManager = getTextManager()
            local fullWidth = textManager:MeasureStringX(UIFont.Medium, "RGB Lights Controller")
            local start = self:getWidth() / 2 - fullWidth / 2
            local gLeft = start + textManager:MeasureStringX(UIFont.Medium, "R")
            local bLeft = gLeft + textManager:MeasureStringX(UIFont.Medium, "G")
            local remainderLeft = bLeft + textManager:MeasureStringX(UIFont.Medium, "B") + 3
            self:drawText("R", start, EDGE_PADDING, 1, 0, 0, 1, UIFont.Medium)
            self:drawText("G", gLeft, EDGE_PADDING, 0, 1, 0, 1, UIFont.Medium)
            self:drawText("B", bLeft, EDGE_PADDING, 0.2, 0.2, 1, 1, UIFont.Medium)
            self:drawText(" Lights Controller", remainderLeft, EDGE_PADDING, 1, 1, 1, 1, UIFont.Medium)
        else
            self:drawTextCentre(TEXTS.RGBRemoteLightsController, self:getWidth() / 2, EDGE_PADDING, 1, 1, 1, 1, UIFont.Medium)
        end
        
        topSectionLeft = self.selectColorButton:getX() - SECTION_BORDER_PADDING
        topSectionTop = self.selectColorButton:getY() - ELEMENT_PADDING - FONT_SMALL_HEIGHT - SECTION_BORDER_PADDING
    else
        self:drawTextCentre(TEXTS.RemoteLightsController, self:getWidth() / 2, EDGE_PADDING, 1, 1, 1, 1, UIFont.Medium)

        topSectionLeft = self.colorComboBox:getX() - SECTION_BORDER_PADDING
        topSectionTop = self.colorComboBox:getY() - ELEMENT_PADDING - FONT_SMALL_HEIGHT - SECTION_BORDER_PADDING
    end

    local left = topSectionLeft
    local top = topSectionTop

    local width = self.halfSectionWidth + SECTION_BORDER_PADDING*2
    local height = self.toggleOffButton:getY() + self.toggleOffButton:getHeight() - top + SECTION_BORDER_PADDING
    self:drawRect(left, top, width, height, self.sectionBackgroundColor.a, self.sectionBackgroundColor.r, self.sectionBackgroundColor.g, self.sectionBackgroundColor.b)
    self:drawRectBorder(left, top, width, height, self.sectionBorderColor.a, self.sectionBorderColor.r, self.sectionBorderColor.g, self.sectionBorderColor.b)
    self:drawTextCentre(TEXTS.DirectLightControl, left + width/2, top + SECTION_BORDER_PADDING, 1.0, 1.0, 1.0, 1.0, UIFont.Small)
    if not self.isRGB then
        self:drawText(TEXTS.Brightness, self.brightnessLabelPosition.x, self.brightnessLabelPosition.y, 1.0, 1.0, 1.0, 1.0, UIFont.Small)
    end

    left = self.rangeComboBox:getX() - SECTION_BORDER_PADDING
    local height = self.clearLightsButton:getY() + self.clearLightsButton:getHeight() - top + SECTION_BORDER_PADDING
    self:drawRect(left, top, width, height, self.sectionBackgroundColor.a, self.sectionBackgroundColor.r, self.sectionBackgroundColor.g, self.sectionBackgroundColor.b)
    self:drawRectBorder(left, top, width, height, self.sectionBorderColor.a, self.sectionBorderColor.r, self.sectionBorderColor.g, self.sectionBorderColor.b)
    self:drawTextCentre(TEXTS.ScannerModule, left + width/2, top + 3, 1.0, 1.0, 1.0, 1.0, UIFont.Small)

    left = self.speedComboBox:getX() - SECTION_BORDER_PADDING
    top = self.speedComboBox:getY() - ELEMENT_PADDING - FONT_SMALL_HEIGHT - SECTION_BORDER_PADDING
    width = self.fullSectionWidth + SECTION_BORDER_PADDING*2
    height = self.pauseLightShowButton:getY() + self.pauseLightShowButton:getHeight() - top + SECTION_BORDER_PADDING
    self:drawRect(left, top, width, height, self.sectionBackgroundColor.a, self.sectionBackgroundColor.r, self.sectionBackgroundColor.g, self.sectionBackgroundColor.b)
    self:drawRectBorder(left, top, width, height, self.sectionBorderColor.a, self.sectionBorderColor.r, self.sectionBorderColor.g, self.sectionBorderColor.b)
    self:drawTextCentre(TEXTS.LightShowModule, left + width/2, top + SECTION_BORDER_PADDING, 1.0, 1.0, 1.0, 1.0, UIFont.Small)
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


    local top = EDGE_PADDING + FONT_MEDIUM_HEIGHT + ELEMENT_PADDING
    self:drawText(TEXTS.TotalLightsConnected, EDGE_PADDING, top, 1, 1, 1, 0.5, UIFont.Small)
    self:drawText(countOfLights, EDGE_PADDING + self.widths.TotalLightsConnected, top, 1, 1, 1, 0.8, UIFont.Small)

    top = EDGE_PADDING + FONT_MEDIUM_HEIGHT + FONT_SMALL_HEIGHT + ELEMENT_PADDING*2
    self:drawText(TEXTS.LightShowStatus, EDGE_PADDING, top, 1, 1, 1, 0.5, UIFont.Small)
    self:drawText(status, EDGE_PADDING + self.widths.LightShowStatus, top, 1, 1, 1, 0.8, UIFont.Small)
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

function RemoteLC_ControllerUI:new(player, controller)
    local width = 200
    local height = 400
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
