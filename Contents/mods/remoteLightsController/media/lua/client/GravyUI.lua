if GravyUI and GravyUI.Version >= 1.1 then return end

require "ISUI/ISComboBox"
require "ISUI/ISButton"
require "RadioCom/ISUIRadio/ISSliderPanel"
require "ISUI/ISTextEntryBox"
require "ISUI/ISTickBox"

GravyUI = {}
GravyUI.Version = 1.1

--- @class Vec2
--- @field x number
--- @field y number
local Vec2 = {x = 0, y = 0}
Vec2.__index = Vec2
function Vec2:new(o, x, y)
    o = o or {}
    setmetatable(o, self)
    o.x = x
    o.y = y
    return o
end
function Vec2:__add(b) return self:new(nil, self.x + b.x, self.y + b.y) end

function Vec2:__sub(b) return Vec2:new(nil, self.x - b.x, self.y - b.y) end

local function vec2(x, y) return Vec2:new(nil, x, y) end

local function unpack(t, i)
    i = i or 1
    if t[i] ~= nil then return t[i], unpack(t, i + 1) end
end

--- @class Rect
--- @field topLeft Vec2
--- @field bottomRight Vec2
--- @field width number
--- @field height number
--- @field center Vec2
local function rect(v1, v2)
    return {
        topLeft = v1,
        bottomRight = v2,
        width = v2.x - v1.x,
        height = v2.y - v1.y,
        center = vec2(v1.x + (v2.x - v1.x) / 2, v1.y + (v2.y - v1.y) / 2)
    }
end


--- @class GravyUI.Node
--- @field rect Rect
--- @field left number
--- @field top number
--- @field right number
--- @field bottom number
--- @field width number
--- @field height number
--- @field parentNode GravyUI.Node|nil
--- @field childNodes GravyUI.Node[]
local Node = {}
Node.__index = Node

local function node(width, height) return Node:new(width, height) end

--- @param width number
--- @param height number
--- @return GravyUI.Node
--- @overload fun(self: GravyUI.Node, rect: Rect): GravyUI.Node
function Node:new(width, height)
    if height ~= nil then width = rect(vec2(0, 0), vec2(width, height)) end
    if width.topLeft == nil then error("Invalid arguments to Node:new") end
    local o = {
        rect = width,
        left = width.topLeft.x,
        top = width.topLeft.y,
        right = width.bottomRight.x,
        bottom = width.bottomRight.y,
        width = width.width,
        height = width.height,
        childNodes = {}
    }
    setmetatable(o, self)
    o.__index = o
    return o
end

--- Creates a child node of this node with the given rect
--- @param rect Rect
--- @return GravyUI.Node
function Node:child(rect)
    local child = node(rect)
    child.parentNode = self
    table.insert(self.childNodes, child)
    return child
end

--- Creates a new node scaled by a factor of x and y, centered on the same point as this node
--- @param x number
--- @param y number
--- @return GravyUI.Node
function Node:scale(x, y)
    if y == nil then y = x end
    return self:resize(x * self.rect.width, y * self.rect.height)
end

--- Creates a new node of size width and height, centered on the same point as this node
--- @param width number
--- @param height number
--- @return GravyUI.Node
function Node:resize(width, height)
    local vec = vec2(width / 2, height / 2)
    return self:child(rect(self.rect.center - vec, self.rect.center + vec))
end

--- @param left number if <= 1, then it is a percentage of the parent's width, otherwise it is a pixel value
--- @param top number if <= 1, then it is a percentage of the parent's height, otherwise it is a pixel value
--- @param right number if <= 1, then it is a percentage of the parent's width, otherwise it is a pixel value
--- @param bottom number if <= 1, then it is a percentage of the parent's height, otherwise it is a pixel value
--- @overload fun(self: GravyUI.Node, leftRight: number, topBottom: number): GravyUI.Node
--- @overload fun(self: GravyUI.Node, allSides: number): GravyUI.Node
--- @return GravyUI.Node
function Node:pad(left, top, right, bottom)
    local topLeft, bottomRight

    if bottom ~= nil then
        if math.abs(left) <= 1 then left = left * self.rect.width end
        if math.abs(top) <= 1 then top = top * self.rect.height end
        if math.abs(right) <= 1 then right = right * self.rect.width end
        if math.abs(bottom) <= 1 then bottom = bottom * self.rect.height end
        topLeft = vec2(left, top)
        bottomRight = vec2(right, bottom)
    elseif top ~= nil then
        if math.abs(left) <= 1 then left = left * self.rect.width end
        if math.abs(top) <= 1 then top = top * self.rect.height end
        topLeft = vec2(left, top)
        bottomRight = vec2(left, top)
    elseif left ~= nil then
        if math.abs(left) <= 1 then
            topLeft = vec2(left * self.rect.width, left * self.rect.height)
        else
            topLeft = vec2(left, left)
        end
        bottomRight = topLeft
    else
        error("Invalid number of arugments to pad")
    end

    local newrect = rect(self.rect.topLeft + topLeft,
                         self.rect.bottomRight - bottomRight)
    return self:child(newrect)
end

--- @param splits number[]|number if <= 1, then it is a percentage of the parent's width, otherwise it is a pixel value
--- @param margin number|nil if <= 1, then it is a percentage of the parent's width, otherwise it is a pixel value
--- @return GravyUI.Node,GravyUI.Node,GravyUI.Node,GravyUI.Node,GravyUI.Node,GravyUI.Node,GravyUI.Node,GravyUI.Node,GravyUI.Node
function Node:cols(splits, margin)
    margin = margin or 0
    if math.abs(margin) <= 1 then margin = (margin * self.rect.width) end
    local numSplits
    if type(splits) == "number" then
        numSplits = splits
        splits = {}
        for i = 1, numSplits do table.insert(splits, 1 / numSplits) end
    else
        numSplits = #splits
    end
    local availableSize = self.rect.width - margin * (numSplits - 1)
    for i = 1, numSplits do
        if math.abs(splits[i]) > 1 then
            availableSize = availableSize - splits[i]
        end
    end
    local nodes = {}
    local offset = 0
    for i = 1, numSplits do
        local split = splits[i]
        if math.abs(split) <= 1 then split = (split * availableSize) end
        local topLeft = self.rect.topLeft + vec2((i - 1) * margin + offset, 0)
        local bottomRight = topLeft + vec2(split, self.rect.height)
        table.insert(nodes, self:child(rect(topLeft, bottomRight)))
        offset = offset + split
    end
    return unpack(nodes)
end

--- @param splits number[]|number if <= 1, then it is a percentage of the parent's width, otherwise it is a pixel value
--- @param margin number|nil if <= 1, then it is a percentage of the parent's width, otherwise it is a pixel value
--- @return GravyUI.Node,GravyUI.Node,GravyUI.Node,GravyUI.Node,GravyUI.Node,GravyUI.Node,GravyUI.Node,GravyUI.Node,GravyUI.Node
function Node:rows(splits, margin)
    margin = margin or 0
    if math.abs(margin) <= 1 then margin = (margin * self.rect.height) end
    local numSplits
    if type(splits) == "number" then
        numSplits = splits
        splits = {}
        for _ = 1, numSplits do table.insert(splits, 1 / numSplits) end
    else
        numSplits = #splits
    end
    local availableSize = self.rect.height - margin * (numSplits - 1)
    for i = 1, numSplits do
        if math.abs(splits[i]) > 1 then
            availableSize = availableSize - splits[i]
        end
    end
    local nodes = {}
    local offset = 0
    for i = 1, numSplits do
        local split = splits[i]
        if math.abs(split) <= 1 then split = (split * availableSize) end
        local topLeft = self.rect.topLeft + vec2(0, (i - 1) * margin + offset)
        local bottomRight = topLeft + vec2(self.rect.width, split)
        table.insert(nodes, self:child(rect(topLeft, bottomRight)))
        offset = offset + split
    end
    return unpack(nodes)
end

--- @param rowSplits number[]|number if <= 1, then it is a percentage of the parent's width, otherwise it is a pixel value
--- @param colSplits number[]|number if <= 1, then it is a percentage of the parent's width, otherwise it is a pixel value
--- @param rowMargin number|nil if <= 1, then it is a percentage of the parent's width, otherwise it is a pixel value
--- @param colMargin number|nil if <= 1, then it is a percentage of the parent's width, otherwise it is a pixel value
--- @return GravyUI.Node[],GravyUI.Node[],GravyUI.Node[],GravyUI.Node[],GravyUI.Node[],GravyUI.Node[],GravyUI.Node[],GravyUI.Node[],GravyUI.Node[]
function Node:grid(rowSplits, colSplits, rowMargin, colMargin)
    local nodes = {}
    for _, rowNode in ipairs({self:rows(rowSplits, rowMargin)}) do
        table.insert(nodes, {rowNode:cols(colSplits, colMargin)})
    end
    return unpack(nodes)
end

--- @param x number if <= 1, then it is a percentage of the parent's width, otherwise it is a pixel value
--- @param y number if <= 1, then it is a percentage of the parent's width, otherwise it is a pixel value
--- @return GravyUI.Node
function Node:offset(x, y)
    if math.abs(x) <= 1 then x = x * self.rect.width end
    if math.abs(y) <= 1 then y = y * self.rect.height end
    local offset = vec2(x, y)
    return self:child(rect(self.rect.topLeft + offset,
                           self.rect.bottomRight + offset))
end


--- @param corner string "topLeft"|"topRight"|"bottomLeft"|"bottomRight"
--- @param w number if <= 1, then it is a percentage of the parent's width, otherwise it is a pixel value
--- @param h number if <= 1, then it is a percentage of the parent's width, otherwise it is a pixel value
function Node:corner(corner, w, h)
    if w <= 1 then w = w * self.width end
    if h <= 1 then h = h * self.height end
    if corner == "topLeft" then
        return self:child(rect(self.rect.topLeft, self.rect.topLeft + vec2(w, h)))
    elseif corner == "topRight" then
        return self:child(rect(vec2(self.right - w, self.top),
                               vec2(self.right, self.top + h)))
    elseif corner == "bottomLeft" then
        return self:child(rect(vec2(self.left, self.bottom - h),
                               vec2(self.left + w, self.bottom)))
    elseif corner == "bottomRight" then
        return self:child(rect(vec2(self.right - w, self.bottom - h),
                               vec2(self.right, self.bottom)))
    else
        return print("Invalid corner for GravyUI.Node:corner")
    end
end

--- @param angle number
--- @param xDistance number if <= 1, then it is a percentage of the parent's width, otherwise it is a pixel value
--- @param yDistance number if <= 1, then it is a percentage of the parent's width, otherwise it is a pixel value
--- @return GravyUI.Node
function Node:radial(angle, xDistance, yDistance)
    if yDistance == nil then yDistance = xDistance end
    if math.abs(xDistance) <= 1 then xDistance = xDistance * self.rect.width end
    if math.abs(yDistance) <= 1 then yDistance = yDistance * self.rect.width end

    local xs = xDistance * math.sin(angle)
    local ys = yDistance * math.cos(angle)
    return self:offset(xs, ys)
end

--- @param x number
--- @param y number
--- @return boolean
function Node:contains(x, y)
    return self.left <= x and x <= self.right and self.top <= y and y <= self.bottom
end

--- @param text string
--- @param target any|nil
--- @param callback function|nil
--- @param args any[]|nil
function Node:makeButton(text, target, callback, args)
    local button = ISButton:new(self.left, self.top, self.width, self.height, text, target, callback)
    button.anchorTop = true
    button.anchorLeft = true
    if args then button.onClickArgs = args end
    button:initialise()
    button:instantiate()
    return button
end

--- @param target any|nil
--- @param callback function|nil
function Node:makeSlider(target, callback)
    local slider = ISSliderPanel:new(self.left, self.top, self.width, self.height, target, callback)
    slider.anchorTop = true
    slider.anchorLeft = true
    slider:initialise()
    slider:instantiate()
    return slider
end

--- @param target any|nil
--- @param callback function|nil
function Node:makeComboBox(target, callback)
    local comboBox = ISComboBox:new(self.left, self.top, self.width, self.height, target, callback)
    comboBox.anchorTop = true
    comboBox.anchorLeft = true
    comboBox:initialise()
    return comboBox
end

--- @param title string
function Node:makeTextBox(title)
    local textBox = ISTextEntryBox:new(title, self.left, self.top, self.width, self.height)
    textBox.anchorTop = true
    textBox.anchorLeft = true
    textBox:initialise()
    return textBox
end

function Node:makeTickBox(target, callback)
    return ISTickBox:new(self.left, self.top, self.width, self.height, "", target, callback)
end

function Node:drawRect(uiElement, a, r, g, b)
    uiElement:drawRect(self.left, self.top, self.width, self.height, a, r, g, b)
end

function Node:drawRectBorder(uiElement, a, r, g, b)
    uiElement:drawRectBorder(self.left, self.top, self.width, self.height, a, r, g, b)
end

GravyUI.Rect = rect
GravyUI.Vec2 = vec2
GravyUI.Node = node
GravyUI.unpack = unpack