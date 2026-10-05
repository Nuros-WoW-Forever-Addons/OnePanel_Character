--[[
    OnePanel_Character - Core.lua
    Character Sheet plugin for OnePanel, featuring interactive 3D player portrait model and equipment slots.
--]]

local addonName, addonTable = ...
local OnePanel = _G.OnePanel
local Utils = _G.OnePanelUtils

local EquipmentSlotsLeft = {
    { id = 1,  name = "HeadSlot",     icon = "Interface\\PaperDoll\\UI-PaperDoll-Slot-Head" },
    { id = 2,  name = "NeckSlot",     icon = "Interface\\PaperDoll\\UI-PaperDoll-Slot-Neck" },
    { id = 3,  name = "ShoulderSlot", icon = "Interface\\PaperDoll\\UI-PaperDoll-Slot-Shoulder" },
    { id = 15, name = "BackSlot",     icon = "Interface\\PaperDoll\\UI-PaperDoll-Slot-Chest" },
    { id = 5,  name = "ChestSlot",    icon = "Interface\\PaperDoll\\UI-PaperDoll-Slot-Chest" },
    { id = 4,  name = "ShirtSlot",    icon = "Interface\\PaperDoll\\UI-PaperDoll-Slot-Shirt" },
    { id = 19, name = "TabardSlot",   icon = "Interface\\PaperDoll\\UI-PaperDoll-Slot-Tabard" },
    { id = 9,  name = "WristSlot",    icon = "Interface\\PaperDoll\\UI-PaperDoll-Slot-Wrists" },
}

local EquipmentSlotsRight = {
    { id = 10, name = "HandsSlot",    icon = "Interface\\PaperDoll\\UI-PaperDoll-Slot-Hands" },
    { id = 6,  name = "WaistSlot",    icon = "Interface\\PaperDoll\\UI-PaperDoll-Slot-Waist" },
    { id = 7,  name = "LegsSlot",     icon = "Interface\\PaperDoll\\UI-PaperDoll-Slot-Legs" },
    { id = 8,  name = "FeetSlot",     icon = "Interface\\PaperDoll\\UI-PaperDoll-Slot-Feet" },
    { id = 11, name = "Finger0Slot",  icon = "Interface\\PaperDoll\\UI-PaperDoll-Slot-Finger" },
    { id = 12, name = "Finger1Slot",  icon = "Interface\\PaperDoll\\UI-PaperDoll-Slot-Finger" },
    { id = 13, name = "Trinket0Slot", icon = "Interface\\PaperDoll\\UI-PaperDoll-Slot-Trinket" },
    { id = 14, name = "Trinket1Slot", icon = "Interface\\PaperDoll\\UI-PaperDoll-Slot-Trinket" },
}

local EquipmentSlotsBottom = {
    { id = 16, name = "MainHandSlot", icon = "Interface\\PaperDoll\\UI-PaperDoll-Slot-MainHand" },
    { id = 17, name = "SecondaryHandSlot", icon = "Interface\\PaperDoll\\UI-PaperDoll-Slot-SecondaryHand" },
    { id = 18, name = "RangedSlot",   icon = "Interface\\PaperDoll\\UI-PaperDoll-Slot-Ranged" },
}

-------------------------------------------------------------------------------
-- Character View Construction
-------------------------------------------------------------------------------

local function CreateCharacterView(parentFrame)
    local container = CreateFrame("Frame", "OnePanel_CharacterContainer", parentFrame)
    container:SetAllPoints(parentFrame)
    
    -- Player Info Header FontString
    local headerText = container:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    headerText:SetPoint("TOP", container, "TOP", 0, -14)
    
    local name = UnitName("player") or "Player"
    local level = UnitLevel("player") or 1
    local race = UnitRace("player") or ""
    local class = UnitClass("player") or ""
    headerText:SetText(string.format("|cffffffff%s|r  |cffffd100Level %d %s %s|r", name, level, race, class))
    container.HeaderText = headerText
    
    -- Central 3D Player Portrait Model
    local model = CreateFrame("PlayerModel", "OnePanel_Character3DPlayerModel", container)
    model:SetSize(360, 440)
    model:SetPoint("CENTER", container, "CENTER", 0, -10)
    model:SetUnit("player")
    model:SetRotation(0)
    container.Model = model
    
    -- Interactive 3D Model Mouse Rotation Handling
    model:EnableMouse(true)
    model:SetScript("OnMouseDown", function(self, button)
        if button == "LeftButton" then
            self.isRotating = true
            self.prevCursorX = GetCursorPosition()
        end
    end)
    
    model:SetScript("OnMouseUp", function(self, button)
        if button == "LeftButton" then
            self.isRotating = false
        end
    end)
    
    model:SetScript("OnUpdate", function(self)
        if self.isRotating then
            local currentX = GetCursorPosition()
            local diff = (currentX - self.prevCursorX) * 0.01
            self:SetRotation(self:GetRotation() + diff)
            self.prevCursorX = currentX
        end
    end)
    
    -- Helper to create equipment slot button
    local function CreateSlotButton(slotInfo, relativeTo, point, relPoint, x, y)
        local btn = CreateFrame("Button", "OnePanel_EqSlot_" .. slotInfo.id, container)
        btn:SetSize(40, 40)
        btn:SetPoint(point, relativeTo, relPoint, x, y)
        btn.slotId = slotInfo.id
        
        -- Slot Border / Background
        local bg = btn:CreateTexture(nil, "BACKGROUND")
        bg:SetTexture("Interface\\Buttons\\UI-Quickslot2")
        bg:SetSize(64, 64)
        bg:SetPoint("CENTER", btn, "CENTER", 0, 0)
        btn.BG = bg
        
        -- Slot Icon
        local icon = btn:CreateTexture(nil, "ARTWORK")
        icon:SetSize(36, 36)
        icon:SetPoint("CENTER", btn, "CENTER", 0, 0)
        icon:SetTexture(slotInfo.icon)
        btn.Icon = icon
        
        -- Hover Highlight
        local hl = btn:CreateTexture(nil, "HIGHLIGHT")
        hl:SetTexture("Interface\\Buttons\\ButtonHilight-Square")
        hl:SetBlendMode("ADD")
        hl:SetAllPoints(icon)
        
        -- Tooltip
        btn:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            local hasItem = GameTooltip:SetInventoryItem("player", self.slotId)
            if not hasItem then
                GameTooltip:SetText(slotInfo.name, 1, 1, 1)
            end
            GameTooltip:Show()
        end)
        btn:SetScript("OnLeave", function()
            GameTooltip_Hide()
        end)
        
        return btn
    end
    
    container.slots = {}
    
    -- Render Left Equipment Column
    local prevBtn = container
    for i, slotInfo in ipairs(EquipmentSlotsLeft) do
        local btn = nil
        if i == 1 then
            btn = CreateSlotButton(slotInfo, container, "TOPLEFT", "TOPLEFT", 20, -50)
        else
            btn = CreateSlotButton(slotInfo, prevBtn, "TOPLEFT", "BOTTOMLEFT", 0, -10)
        end
        prevBtn = btn
        container.slots[slotInfo.id] = btn
    end
    
    -- Render Right Equipment Column
    prevBtn = container
    for i, slotInfo in ipairs(EquipmentSlotsRight) do
        local btn = nil
        if i == 1 then
            btn = CreateSlotButton(slotInfo, container, "TOPRIGHT", "TOPRIGHT", -20, -50)
        else
            btn = CreateSlotButton(slotInfo, prevBtn, "TOPRIGHT", "BOTTOMRIGHT", 0, -10)
        end
        prevBtn = btn
        container.slots[slotInfo.id] = btn
    end
    
    -- Render Bottom Weapon Column
    local mainHand = CreateSlotButton(EquipmentSlotsBottom[1], model, "BOTTOM", "BOTTOM", -50, 10)
    local offHand  = CreateSlotButton(EquipmentSlotsBottom[2], model, "BOTTOM", "BOTTOM", 0, 10)
    local ranged   = CreateSlotButton(EquipmentSlotsBottom[3], model, "BOTTOM", "BOTTOM", 50, 10)
    
    container.slots[16] = mainHand
    container.slots[17] = offHand
    container.slots[18] = ranged
    
    -- Update Equipment Slot Icons
    local function UpdateEquipment()
        for slotId, btn in pairs(container.slots) do
            local texture = GetInventoryItemTexture("player", slotId)
            if texture then
                btn.Icon:SetTexture(texture)
                btn.Icon:SetVertexColor(1, 1, 1, 1)
            else
                -- Find default slot icon
                for _, list in ipairs({EquipmentSlotsLeft, EquipmentSlotsRight, EquipmentSlotsBottom}) do
                    for _, s in ipairs(list) do
                        if s.id == slotId then
                            btn.Icon:SetTexture(s.icon)
                            btn.Icon:SetVertexColor(0.5, 0.5, 0.5, 0.8)
                            break
                        end
                    end
                end
            end
        end
    end
    
    container.UpdateEquipment = UpdateEquipment
    UpdateEquipment()
    
    -- Event Handlers for Gear & Model Refresh
    container:SetScript("OnEvent", function(self, event, arg1)
        if event == "PLAYER_EQUIPMENT_CHANGED" then
            self:UpdateEquipment()
            if self.Model then self.Model:SetUnit("player") end
        elseif event == "UNIT_MODEL_CHANGED" and arg1 == "player" then
            if self.Model then self.Model:SetUnit("player") end
        end
    end)
    
    container:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
    container:RegisterEvent("UNIT_MODEL_CHANGED")
    
    return container
end

-------------------------------------------------------------------------------
-- Plugin Registration
-------------------------------------------------------------------------------

local function RegisterPlugin()
    if not OnePanel then return end
    
    OnePanel:RegisterPlugin({
        id = "Character",
        title = "Character",
        order = 10,
        use3DPortrait = true,
        icon = "Interface\\Icons\\INV_Chest_Chain_05",
        CreateView = CreateCharacterView,
        OnShow = function(container)
            if container and container.Model then
                container.Model:SetUnit("player")
            end
            if container and container.UpdateEquipment then
                container:UpdateEquipment()
            end
        end,
        OnHide = function(container)
        end
    })
end

local eventFrame = CreateFrame("Frame", "OnePanel_Character_EventFrame")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:SetScript("OnEvent", function(self, event)
    RegisterPlugin()
    self:UnregisterEvent("PLAYER_LOGIN")
end)
