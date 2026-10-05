--[[
    OnePanel_Character - Core.lua
    Character Sheet plugin featuring 3D player portrait model, equipment slots,
    and embedded right-side details panel with Stats, Outfits, and Titles sub-tabs.
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
-- Stats Calculation Helper
-------------------------------------------------------------------------------

local function FetchPlayerStats()
    local stats = {}
    
    -- General Stats
    table.insert(stats, { header = "General" })
    table.insert(stats, { label = "Health:", val = tostring(UnitHealthMax("player") or 0) })
    
    local powerType, powerToken = UnitPowerType("player")
    local powerMax = UnitPowerMax("player") or 0
    local powerLabel = powerToken and (powerToken:sub(1,1):upper() .. powerToken:sub(2):lower() .. ":") or "Power:"
    table.insert(stats, { label = powerLabel, val = tostring(powerMax) })
    
    local speed = math.floor((GetUnitSpeed("player") or 7) / 7 * 100 + 0.5)
    table.insert(stats, { label = "Movement Speed:", val = speed .. "%" })
    
    -- Primary Attributes
    table.insert(stats, { header = "Primary Attributes" })
    local statNames = { "Strength:", "Agility:", "Stamina:", "Intellect:", "Spirit:" }
    for i = 1, 5 do
        local _, stat = UnitStat("player", i)
        table.insert(stats, { label = statNames[i], val = tostring(stat or 0) })
    end
    
    -- Weapons & Defense
    table.insert(stats, { header = "Combat" })
    local minDmg, maxDmg = UnitDamage("player")
    minDmg = math.floor(minDmg or 0)
    maxDmg = math.floor(maxDmg or 0)
    table.insert(stats, { label = "Main Hand Damage:", val = minDmg .. " - " .. maxDmg })
    
    local baseAP, posAP, negAP = UnitAttackPower("player")
    local ap = (baseAP or 0) + (posAP or 0) + (negAP or 0)
    table.insert(stats, { label = "Attack Power:", val = tostring(ap) })
    
    local _, effectiveArmor = UnitArmor("player")
    table.insert(stats, { label = "Armor:", val = tostring(effectiveArmor or 0) })
    
    return stats
end

-------------------------------------------------------------------------------
-- Character View Construction
-------------------------------------------------------------------------------

local function CreateCharacterView(parentFrame)
    local container = CreateFrame("Frame", "OnePanel_CharacterContainer", parentFrame)
    container:SetAllPoints(parentFrame)
    
    -- Main 3D Model Area (Left Side)
    local leftArea = CreateFrame("Frame", "OnePanel_CharacterLeftArea", container)
    leftArea:SetPoint("TOPLEFT", container, "TOPLEFT", 0, 0)
    leftArea:SetPoint("BOTTOMLEFT", container, "BOTTOMLEFT", 0, 0)
    leftArea:SetWidth(460)
    
    -- Central 3D Player Portrait Model
    local model = CreateFrame("PlayerModel", "OnePanel_Character3DPlayerModel", leftArea)
    model:SetSize(320, 420)
    model:SetPoint("CENTER", leftArea, "CENTER", 0, -10)
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
        if button == "LeftButton" then self.isRotating = false end
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
        local btn = CreateFrame("Button", "OnePanel_EqSlot_" .. slotInfo.id, leftArea)
        btn:SetSize(38, 38)
        btn:SetPoint(point, relativeTo, relPoint, x, y)
        btn.slotId = slotInfo.id
        
        local bg = btn:CreateTexture(nil, "BACKGROUND")
        bg:SetTexture("Interface\\Buttons\\UI-Quickslot2")
        bg:SetSize(60, 60)
        bg:SetPoint("CENTER", btn, "CENTER", 0, 0)
        btn.BG = bg
        
        local icon = btn:CreateTexture(nil, "ARTWORK")
        icon:SetSize(34, 34)
        icon:SetPoint("CENTER", btn, "CENTER", 0, 0)
        icon:SetTexture(slotInfo.icon)
        btn.Icon = icon
        
        local hl = btn:CreateTexture(nil, "HIGHLIGHT")
        hl:SetTexture("Interface\\Buttons\\ButtonHilight-Square")
        hl:SetBlendMode("ADD")
        hl:SetAllPoints(icon)
        
        btn:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            local hasItem = GameTooltip:SetInventoryItem("player", self.slotId)
            if not hasItem then
                GameTooltip:SetText(slotInfo.name, 1, 1, 1)
            end
            GameTooltip:Show()
        end)
        btn:SetScript("OnLeave", function() GameTooltip_Hide() end)
        
        return btn
    end
    
    container.slots = {}
    
    -- Render Left Equipment Column
    local prevBtn = leftArea
    for i, slotInfo in ipairs(EquipmentSlotsLeft) do
        local btn = nil
        if i == 1 then
            btn = CreateSlotButton(slotInfo, leftArea, "TOPLEFT", "TOPLEFT", 12, -20)
        else
            btn = CreateSlotButton(slotInfo, prevBtn, "TOPLEFT", "BOTTOMLEFT", 0, -8)
        end
        prevBtn = btn
        container.slots[slotInfo.id] = btn
    end
    
    -- Render Right Equipment Column
    prevBtn = leftArea
    for i, slotInfo in ipairs(EquipmentSlotsRight) do
        local btn = nil
        if i == 1 then
            btn = CreateSlotButton(slotInfo, leftArea, "TOPRIGHT", "TOPRIGHT", -12, -20)
        else
            btn = CreateSlotButton(slotInfo, prevBtn, "TOPRIGHT", "BOTTOMRIGHT", 0, -8)
        end
        prevBtn = btn
        container.slots[slotInfo.id] = btn
    end
    
    -- Render Bottom Weapon Row
    local mainHand = CreateSlotButton(EquipmentSlotsBottom[1], model, "BOTTOM", "BOTTOM", -46, 5)
    local offHand  = CreateSlotButton(EquipmentSlotsBottom[2], model, "BOTTOM", "BOTTOM", 0, 5)
    local ranged   = CreateSlotButton(EquipmentSlotsBottom[3], model, "BOTTOM", "BOTTOM", 46, 5)
    container.slots[16] = mainHand
    container.slots[17] = offHand
    container.slots[18] = ranged
    
    ---------------------------------------------------------------------------
    -- Right Embedded Details Sub-Panel (Stats, Outfits, Titles)
    ---------------------------------------------------------------------------
    
    local subPanel = CreateFrame("Frame", "OnePanel_CharacterSubPanel", container)
    subPanel:SetPoint("TOPRIGHT", container, "TOPRIGHT", -10, -12)
    subPanel:SetPoint("BOTTOMRIGHT", container, "BOTTOMRIGHT", -10, 12)
    subPanel:SetWidth(300)
    
    if Utils and Utils.FrameHelper then
        Utils.FrameHelper:ApplyBackdrop(subPanel,
            "Interface\\FrameGeneral\\UI-Background-Marble",
            "Interface\\Tooltips\\UI-Tooltip-Border",
            16, 16, { left = 4, right = 4, top = 4, bottom = 4 }
        )
    end
    container.SubPanel = subPanel
    
    -- Sub-Tab Buttons Bar Header
    local subTabBar = CreateFrame("Frame", "OnePanel_CharacterSubTabBar", subPanel)
    subTabBar:SetPoint("TOPLEFT", subPanel, "TOPLEFT", 6, -6)
    subTabBar:SetPoint("TOPRIGHT", subPanel, "TOPRIGHT", -6, -6)
    subTabBar:SetHeight(38)
    
    local subTabs = {
        { id = "stats",   title = "Stats",   icon = "Interface\\Icons\\Paperdoll_Stat_Strength" },
        { id = "outfits", title = "Outfits", icon = "Interface\\Icons\\INV_Armor_Chest_Plate_06" },
        { id = "titles",  title = "Titles",  icon = "Interface\\Icons\\INV_Scroll_03" },
    }
    
    subPanel.activeTab = "stats"
    subPanel.tabButtons = {}
    subPanel.views = {}
    
    -- Sub-View Container
    local subContentView = CreateFrame("Frame", "OnePanel_CharacterSubContentView", subPanel)
    subContentView:SetPoint("TOPLEFT", subTabBar, "BOTTOMLEFT", 0, -6)
    subContentView:SetPoint("BOTTOMRIGHT", subPanel, "BOTTOMRIGHT", -6, 6)
    subPanel.ContentView = subContentView
    
    -- 1. Stats Sub-View
    local statsView = CreateFrame("ScrollFrame", "OnePanel_StatsSubView", subContentView, "UIPanelScrollFrameTemplate")
    statsView:SetAllPoints(subContentView)
    
    local statsContent = CreateFrame("Frame", "OnePanel_StatsContent", statsView)
    statsContent:SetSize(270, 500)
    statsView:SetScrollChild(statsContent)
    subPanel.views["stats"] = statsView
    
    local function RefreshStatsDisplay()
        if not statsContent.labels then statsContent.labels = {} end
        for _, obj in ipairs(statsContent.labels) do obj:Hide() end
        
        local stats = FetchPlayerStats()
        local yOffset = -8
        local labelIdx = 1
        
        for _, entry in ipairs(stats) do
            if entry.header then
                local fontHeader = statsContent.labels[labelIdx] or statsContent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                fontHeader:ClearAllPoints()
                fontHeader:SetPoint("TOPLEFT", statsContent, "TOPLEFT", 12, yOffset)
                fontHeader:SetText("|cffffcc00" .. entry.header .. "|r")
                fontHeader:Show()
                statsContent.labels[labelIdx] = fontHeader
                labelIdx = labelIdx + 1
                yOffset = yOffset - 22
            elseif entry.label then
                local fontLabel = statsContent.labels[labelIdx] or statsContent:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
                fontLabel:ClearAllPoints()
                fontLabel:SetPoint("TOPLEFT", statsContent, "TOPLEFT", 16, yOffset)
                fontLabel:SetText("|cffffd100" .. entry.label .. "|r")
                fontLabel:Show()
                statsContent.labels[labelIdx] = fontLabel
                labelIdx = labelIdx + 1
                
                local fontVal = statsContent.labels[labelIdx] or statsContent:CreateFontString(nil, "OVERLAY", "GameFontHighlightRight")
                fontVal:ClearAllPoints()
                fontVal:SetPoint("TOPRIGHT", statsContent, "TOPRIGHT", -24, yOffset)
                fontVal:SetText(entry.val or "")
                fontVal:Show()
                statsContent.labels[labelIdx] = fontVal
                labelIdx = labelIdx + 1
                
                yOffset = yOffset - 18
            end
        end
    end
    statsView.Refresh = RefreshStatsDisplay
    
    -- 2. Outfits Sub-View
    local outfitsView = CreateFrame("Frame", "OnePanel_OutfitsSubView", subContentView)
    outfitsView:SetAllPoints(subContentView)
    local outfitsText = outfitsView:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    outfitsText:SetPoint("TOP", outfitsView, "TOP", 0, -20)
    outfitsText:SetText("|cff00ccffEquipment Manager / Outfits|r")
    subPanel.views["outfits"] = outfitsView
    
    -- 3. Titles Sub-View
    local titlesView = CreateFrame("Frame", "OnePanel_TitlesSubView", subContentView)
    titlesView:SetAllPoints(subContentView)
    local titlesText = titlesView:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    titlesText:SetPoint("TOP", titlesView, "TOP", 0, -20)
    titlesText:SetText("|cffffcc00Character Titles|r")
    subPanel.views["titles"] = titlesView
    
    -- Switch Sub-Tab Handler
    local function SwitchSubTab(tabId)
        subPanel.activeTab = tabId
        for id, view in pairs(subPanel.views) do
            if id == tabId then
                view:Show()
                if view.Refresh then view:Refresh() end
            else
                view:Hide()
            end
        end
        for id, btn in pairs(subPanel.tabButtons) do
            if id == tabId then
                btn.Glow:Show()
                btn.Icon:SetVertexColor(1, 1, 1, 1)
            else
                btn.Glow:Hide()
                btn.Icon:SetVertexColor(0.6, 0.6, 0.6, 1)
            end
        end
    end
    
    -- Render Sub-Tab Buttons
    local numTabs = #subTabs
    local tabWidth = math.floor(288 / numTabs)
    for i, tabInfo in ipairs(subTabs) do
        local btn = CreateFrame("Button", "OnePanel_CharSubTab_" .. tabInfo.id, subTabBar)
        btn:SetSize(tabWidth - 4, 32)
        btn:SetPoint("LEFT", subTabBar, "LEFT", (i - 1) * tabWidth + 2, 0)
        
        local icon = btn:CreateTexture(nil, "ARTWORK")
        icon:SetSize(22, 22)
        icon:SetPoint("LEFT", btn, "LEFT", 8, 0)
        icon:SetTexture(tabInfo.icon)
        btn.Icon = icon
        
        local label = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        label:SetPoint("LEFT", icon, "RIGHT", 6, 0)
        label:SetText(tabInfo.title)
        btn.Label = label
        
        local glow = btn:CreateTexture(nil, "OVERLAY")
        glow:SetTexture("Interface\\Buttons\\CheckButtonHilight")
        glow:SetBlendMode("ADD")
        glow:SetAllPoints(btn)
        glow:Hide()
        btn.Glow = glow
        
        btn:SetScript("OnClick", function() SwitchSubTab(tabInfo.id) end)
        subPanel.tabButtons[tabInfo.id] = btn
    end
    
    SwitchSubTab("stats")
    
    ---------------------------------------------------------------------------
    -- Equipment Update Handler
    ---------------------------------------------------------------------------
    
    local function UpdateEquipment()
        for slotId, btn in pairs(container.slots) do
            local texture = GetInventoryItemTexture("player", slotId)
            if texture then
                btn.Icon:SetTexture(texture)
                btn.Icon:SetVertexColor(1, 1, 1, 1)
            else
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
        if statsView.Refresh then statsView:Refresh() end
    end
    
    container.UpdateEquipment = UpdateEquipment
    UpdateEquipment()
    
    -- Event Listener
    container:SetScript("OnEvent", function(self, event, arg1)
        if event == "PLAYER_EQUIPMENT_CHANGED" or event == "UNIT_STATS" or event == "PLAYER_DAMAGE_DONE_MODS" then
            self:UpdateEquipment()
            if self.Model then self.Model:SetUnit("player") end
        elseif event == "UNIT_MODEL_CHANGED" and arg1 == "player" then
            if self.Model then self.Model:SetUnit("player") end
        end
    end)
    
    container:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
    container:RegisterEvent("UNIT_STATS")
    container:RegisterEvent("PLAYER_DAMAGE_DONE_MODS")
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
