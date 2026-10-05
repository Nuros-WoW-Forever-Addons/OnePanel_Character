--[[
    OnePanel_Character - Core.lua
    Character Sheet plugin featuring 3D player model with authentic Blizzard controls,
    race-specific background art, equipment slots, collapsible side panel, framed headers,
    alternating row colors, resistance icons, and custom translucent sub-tab tooltips.
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

-- Correct WoW Resistance School Indices: 2: Fire, 3: Nature, 4: Frost, 5: Shadow, 6: Arcane
local ResistanceSchools = {
    { id = 6, name = "Arcane", icon = "Interface\\PaperDollInfoFrame\\SpellSchoolIcon7" },
    { id = 2, name = "Fire",   icon = "Interface\\PaperDollInfoFrame\\SpellSchoolIcon3" },
    { id = 4, name = "Frost",  icon = "Interface\\PaperDollInfoFrame\\SpellSchoolIcon5" },
    { id = 3, name = "Nature", icon = "Interface\\PaperDollInfoFrame\\SpellSchoolIcon4" },
    { id = 5, name = "Shadow", icon = "Interface\\PaperDollInfoFrame\\SpellSchoolIcon6" },
}

-------------------------------------------------------------------------------
-- Safe Stats Calculation Helper
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
    
    local rawSpeed = GetUnitSpeed and GetUnitSpeed("player") or 7
    local speed = math.floor((rawSpeed or 7) / 7 * 100 + 0.5)
    table.insert(stats, { label = "Movement Speed:", val = speed .. "%" })
    
    -- Primary Attributes
    table.insert(stats, { header = "Primary Attributes" })
    local statNames = { "Strength:", "Agility:", "Stamina:", "Intellect:", "Spirit:" }
    for i = 1, 5 do
        local _, stat = UnitStat("player", i)
        table.insert(stats, { label = statNames[i], val = tostring(stat or 0) })
    end
    
    -- Weapons
    table.insert(stats, { header = "Weapons" })
    local minDmg, maxDmg = UnitDamage("player")
    minDmg = math.floor(minDmg or 0)
    maxDmg = math.floor(maxDmg or 0)
    table.insert(stats, { label = "Main Hand:", val = minDmg .. " - " .. maxDmg })
    
    local baseAP, posAP, negAP = UnitAttackPower("player")
    local ap = (baseAP or 0) + (posAP or 0) + (negAP or 0)
    table.insert(stats, { label = "Attack Power:", val = tostring(ap) })
    
    -- Modifiers
    table.insert(stats, { header = "Modifiers" })
    local crit = (GetCritChance and GetCritChance()) or 0
    local critVal = (type(crit) == "number") and crit or 0
    table.insert(stats, { label = "Critical Strike:", val = string.format("%.1f%%", critVal) })
    
    local haste = (GetHaste and GetHaste()) or 0
    local hasteVal = (type(haste) == "number") and haste or 0
    table.insert(stats, { label = "Haste:", val = string.format("%.1f%%", hasteVal) })
    
    -- Defense
    table.insert(stats, { header = "Defense" })
    local dodge = (GetDodgeChance and GetDodgeChance()) or 0
    local dodgeVal = (type(dodge) == "number") and dodge or 0
    table.insert(stats, { label = "Dodge:", val = string.format("%.1f%%", dodgeVal) })
    
    local _, effectiveArmor = UnitArmor("player")
    table.insert(stats, { label = "Armor:", val = tostring(effectiveArmor or 0) })
    
    -- Resistances (Wrapped in pcall for safety)
    table.insert(stats, { header = "Resistances" })
    for _, res in ipairs(ResistanceSchools) do
        local ok, baseRes = pcall(UnitResistance, "player", res.id)
        local valStr = (ok and type(baseRes) == "number") and tostring(baseRes) or "0"
        table.insert(stats, { label = res.name .. ":", val = valStr, icon = res.icon })
    end
    
    return stats
end

-------------------------------------------------------------------------------
-- Custom Translucent Popup Tooltip Helper
-------------------------------------------------------------------------------

local function CreateCustomPopupTooltip()
    if _G.OnePanel_CustomTooltip then return _G.OnePanel_CustomTooltip end
    
    local tooltip = CreateFrame("Frame", "OnePanel_CustomTooltip", UIParent)
    tooltip:SetSize(160, 36)
    tooltip:SetFrameStrata("TOOLTIP")
    tooltip:Hide()
    
    local bg = tooltip:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(tooltip)
    bg:SetColorTexture(0, 0, 0, 0.85)
    
    if Utils and Utils.FrameHelper then
        Utils.FrameHelper:ApplyBackdrop(tooltip,
            nil,
            "Interface\\Tooltips\\UI-Tooltip-Border",
            16, 16, { left = 4, right = 4, top = 4, bottom = 4 }
        )
    end
    
    local text = tooltip:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    text:SetPoint("CENTER", tooltip, "CENTER", 0, 0)
    tooltip.Text = text
    
    function tooltip:ShowText(anchorFrame, titleText)
        self.Text:SetText(titleText)
        local width = math.max(140, self.Text:GetStringWidth() + 24)
        self:SetSize(width, 34)
        self:SetPoint("BOTTOM", anchorFrame, "TOP", 0, 6)
        self:Show()
    end
    
    return tooltip
end

-------------------------------------------------------------------------------
-- Character View Construction
-------------------------------------------------------------------------------

local function CreateCharacterView(parentFrame)
    local container = CreateFrame("Frame", "OnePanel_CharacterContainer", parentFrame)
    container:SetAllPoints(parentFrame)
    
    local popupTooltip = CreateCustomPopupTooltip()
    
    -- Main 3D Model & Equipment Area (Left Side)
    local leftArea = CreateFrame("Frame", "OnePanel_CharacterLeftArea", container)
    leftArea:SetPoint("TOPLEFT", container, "TOPLEFT", 0, 0)
    leftArea:SetPoint("BOTTOMLEFT", container, "BOTTOMLEFT", 0, 0)
    leftArea:SetWidth(460)
    
    -- Race-Specific Character Background Art
    local _, raceFile = UnitRace("player")
    raceFile = raceFile or "NightElf"
    if raceFile == "Scourge" then raceFile = "Scourge" end
    local bgTexturePath = "Interface\\PaperDollHeaderFooters\\UI-PaperDoll-Background-" .. raceFile
    
    local modelBg = leftArea:CreateTexture(nil, "BACKGROUND", nil, -7)
    modelBg:SetPoint("TOPLEFT", leftArea, "TOPLEFT", 10, -10)
    modelBg:SetPoint("BOTTOMRIGHT", leftArea, "BOTTOMRIGHT", -10, 10)
    modelBg:SetTexture(bgTexturePath)
    modelBg:SetTexCoord(0, 1, 0, 1)
    
    local modelVignette = leftArea:CreateTexture(nil, "BORDER")
    modelVignette:SetAllPoints(modelBg)
    modelVignette:SetColorTexture(0, 0, 0, 0.25)
    
    -- Central 3D Player Portrait Model
    local model = CreateFrame("PlayerModel", "OnePanel_Character3DPlayerModel", leftArea)
    model:SetSize(320, 420)
    model:SetPoint("CENTER", leftArea, "CENTER", 0, -10)
    model:SetUnit("player")
    model.facing = 0
    model.camScale = 1.0
    container.Model = model
    
    -- Safe Rotation Helper
    local function RotateModel(delta)
        if not model then return end
        if model.SetFacing then
            local cur = (model.GetFacing and model:GetFacing()) or model.facing or 0
            local newFacing = cur + delta
            model.facing = newFacing
            model:SetFacing(newFacing)
        elseif model.SetRotation then
            local cur = (model.GetRotation and model:GetRotation()) or model.facing or 0
            local newRot = cur + delta
            model.facing = newRot
            model:SetRotation(newRot)
        end
    end
    
    -- Interactive Mouse Drag Rotation
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
            RotateModel(diff)
            self.prevCursorX = currentX
        end
    end)
    
    ---------------------------------------------------------------------------
    -- 3D Model Control Toolbar (Centered at Top of Model Container)
    ---------------------------------------------------------------------------
    
    local toolbar = CreateFrame("Frame", "OnePanel_3DModelToolbar", leftArea)
    toolbar:SetSize(130, 24)
    toolbar:SetPoint("TOP", leftArea, "TOP", 0, -14)
    toolbar:SetFrameLevel(leftArea:GetFrameLevel() + 20)
    
    local function CreateBlizzardModelButton(name, normalTex, pushedTex, tooltipText, onClick)
        local btn = CreateFrame("Button", name, toolbar)
        btn:SetSize(22, 22)
        btn:SetNormalTexture(normalTex)
        if pushedTex then btn:SetPushedTexture(pushedTex) end
        btn:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight", "ADD")
        
        btn:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:SetText(tooltipText, 1, 1, 1)
            GameTooltip:Show()
        end)
        btn:SetScript("OnLeave", function() GameTooltip_Hide() end)
        btn:SetScript("OnClick", onClick)
        return btn
    end
    
    local btnZoomIn = CreateBlizzardModelButton("OnePanel_BtnZoomIn", 
        "Interface\\Minimap\\UI-Minimap-ZoomIn-Up",
        "Interface\\Minimap\\UI-Minimap-ZoomIn-Down",
        "Zoom In", function()
            model.camScale = math.max(0.4, model.camScale - 0.15)
            if model.SetCamDistanceScale then model:SetCamDistanceScale(model.camScale) end
        end)
    btnZoomIn:SetPoint("LEFT", toolbar, "LEFT", 0, 0)
    
    local btnZoomOut = CreateBlizzardModelButton("OnePanel_BtnZoomOut", 
        "Interface\\Minimap\\UI-Minimap-ZoomOut-Up",
        "Interface\\Minimap\\UI-Minimap-ZoomOut-Down",
        "Zoom Out", function()
            model.camScale = math.min(2.5, model.camScale + 0.15)
            if model.SetCamDistanceScale then model:SetCamDistanceScale(model.camScale) end
        end)
    btnZoomOut:SetPoint("LEFT", btnZoomIn, "RIGHT", 3, 0)
    
    local btnRotLeft = CreateBlizzardModelButton("OnePanel_BtnRotLeft", 
        "Interface\\Buttons\\UI-RotationLeft-Button-Up",
        "Interface\\Buttons\\UI-RotationLeft-Button-Down",
        "Rotate Left", function()
            RotateModel(-0.3)
        end)
    btnRotLeft:SetPoint("LEFT", btnZoomOut, "RIGHT", 3, 0)
    
    local btnRotRight = CreateBlizzardModelButton("OnePanel_BtnRotRight", 
        "Interface\\Buttons\\UI-RotationRight-Button-Up",
        "Interface\\Buttons\\UI-RotationRight-Button-Down",
        "Rotate Right", function()
            RotateModel(0.3)
        end)
    btnRotRight:SetPoint("LEFT", btnRotLeft, "RIGHT", 3, 0)
    
    local btnReset = CreateBlizzardModelButton("OnePanel_BtnReset", 
        "Interface\\Buttons\\UI-RefreshButton",
        "Interface\\Buttons\\UI-RefreshButton",
        "Reset Portrait", function()
            model.camScale = 1.0
            model.facing = 0
            if model.SetCamDistanceScale then model:SetCamDistanceScale(1.0) end
            if model.SetFacing then model:SetFacing(0) elseif model.SetRotation then model:SetRotation(0) end
            model:SetUnit("player")
        end)
    btnReset:SetPoint("LEFT", btnRotRight, "RIGHT", 3, 0)
    
    ---------------------------------------------------------------------------
    -- Equipment Slot Buttons
    ---------------------------------------------------------------------------
    
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
    
    local prevBtn = leftArea
    for i, slotInfo in ipairs(EquipmentSlotsLeft) do
        local btn = (i == 1) and CreateSlotButton(slotInfo, leftArea, "TOPLEFT", "TOPLEFT", 12, -20)
                             or CreateSlotButton(slotInfo, prevBtn, "TOPLEFT", "BOTTOMLEFT", 0, -8)
        prevBtn = btn
        container.slots[slotInfo.id] = btn
    end
    
    prevBtn = leftArea
    for i, slotInfo in ipairs(EquipmentSlotsRight) do
        local btn = (i == 1) and CreateSlotButton(slotInfo, leftArea, "TOPRIGHT", "TOPRIGHT", -12, -20)
                             or CreateSlotButton(slotInfo, prevBtn, "TOPRIGHT", "BOTTOMRIGHT", 0, -8)
        prevBtn = btn
        container.slots[slotInfo.id] = btn
    end
    
    local mainHand = CreateSlotButton(EquipmentSlotsBottom[1], model, "BOTTOM", "BOTTOM", -46, 5)
    local offHand  = CreateSlotButton(EquipmentSlotsBottom[2], model, "BOTTOM", "BOTTOM", 0, 5)
    local ranged   = CreateSlotButton(EquipmentSlotsBottom[3], model, "BOTTOM", "BOTTOM", 46, 5)
    container.slots[16] = mainHand
    container.slots[17] = offHand
    container.slots[18] = ranged
    
    ---------------------------------------------------------------------------
    -- Collapsible Side Panel & Arrow Collapse Button
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
    
    -- Visible Collapsible Arrow Button above right equipment slots
    local collapseBtn = CreateFrame("Button", "OnePanel_CollapseButton", container)
    collapseBtn:SetSize(22, 22)
    collapseBtn:SetPoint("TOPRIGHT", leftArea, "TOPRIGHT", -8, -14)
    collapseBtn:SetFrameLevel(subPanel:GetFrameLevel() + 20)
    collapseBtn:SetNormalTexture("Interface\\Buttons\\UI-SpellbookSearch-DrillDown")
    collapseBtn:SetPushedTexture("Interface\\Buttons\\UI-SpellbookSearch-DrillDown")
    collapseBtn:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight", "ADD")
    container.CollapseButton = collapseBtn
    
    collapseBtn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText("Toggle Side Details Panel", 1, 1, 1)
        GameTooltip:Show()
    end)
    collapseBtn:SetScript("OnLeave", function() GameTooltip_Hide() end)
    
    collapseBtn:SetScript("OnClick", function()
        local isExpanded = OnePanel and OnePanel.isExpanded
        local newState = not isExpanded
        if OnePanel and OnePanel.SetPanelExpanded then
            OnePanel:SetPanelExpanded(newState)
        end
        if newState then
            subPanel:Show()
            collapseBtn:SetNormalTexture("Interface\\Buttons\\UI-SpellbookSearch-DrillDown")
        else
            subPanel:Hide()
            collapseBtn:SetNormalTexture("Interface\\Buttons\\UI-SpellbookSearch-DrillDown")
        end
    end)
    
    -- Sub-Tab Bar Header
    local subTabBar = CreateFrame("Frame", "OnePanel_CharacterSubTabBar", subPanel)
    subTabBar:SetPoint("TOPLEFT", subPanel, "TOPLEFT", 6, -6)
    subTabBar:SetPoint("TOPRIGHT", subPanel, "TOPRIGHT", -6, -6)
    subTabBar:SetHeight(38)
    
    local subTabs = {
        { id = "stats",   title = "Character Stats",   usePortrait = true },
        { id = "outfits", title = "Equipment Manager", icon = "Interface\\PaperDollInfoFrame\\UI-EquipmentManager-Toggle" },
        { id = "titles",  title = "Titles",            icon = "Interface\\Icons\\INV_Scroll_11" },
    }
    
    subPanel.activeTab = "stats"
    subPanel.tabButtons = {}
    subPanel.views = {}
    
    -- Sub-View Content Container
    local subContentView = CreateFrame("Frame", "OnePanel_CharacterSubContentView", subPanel)
    subContentView:SetPoint("TOPLEFT", subTabBar, "BOTTOMLEFT", 0, -32)
    subContentView:SetPoint("BOTTOMRIGHT", subPanel, "BOTTOMRIGHT", -6, 6)
    subPanel.ContentView = subContentView
    
    ---------------------------------------------------------------------------
    -- Sub-View 1: Character Stats List
    ---------------------------------------------------------------------------
    
    local statsView = CreateFrame("ScrollFrame", "OnePanel_StatsSubView", subContentView, "UIPanelScrollFrameTemplate")
    statsView:SetAllPoints(subContentView)
    
    local statsContent = CreateFrame("Frame", "OnePanel_StatsContent", statsView)
    statsContent:SetSize(270, 600)
    statsView:SetScrollChild(statsContent)
    subPanel.views["stats"] = statsView
    
    local function RefreshStatsDisplay()
        if not statsContent.elements then statsContent.elements = {} end
        for _, el in ipairs(statsContent.elements) do el:Hide() end
        
        local stats = FetchPlayerStats()
        local yOffset = -4
        local elIdx = 1
        local dataRowCounter = 0
        
        for _, entry in ipairs(stats) do
            if entry.header then
                dataRowCounter = 0
                local headerBtn = statsContent.elements[elIdx]
                if not headerBtn then
                    headerBtn = CreateFrame("Button", nil, statsContent, "UIPanelButtonTemplate")
                    headerBtn:Disable()
                end
                headerBtn:ClearAllPoints()
                headerBtn:SetSize(264, 22)
                headerBtn:SetPoint("TOPLEFT", statsContent, "TOPLEFT", 4, yOffset)
                headerBtn:SetText(entry.header)
                headerBtn:Show()
                statsContent.elements[elIdx] = headerBtn
                elIdx = elIdx + 1
                yOffset = yOffset - 26
            elseif entry.label then
                dataRowCounter = dataRowCounter + 1
                
                local rowFrame = statsContent.elements[elIdx]
                if not rowFrame then
                    rowFrame = CreateFrame("Frame", nil, statsContent)
                    rowFrame.bg = rowFrame:CreateTexture(nil, "BACKGROUND")
                    rowFrame.bg:SetAllPoints(rowFrame)
                    
                    rowFrame.icon = rowFrame:CreateTexture(nil, "ARTWORK")
                    rowFrame.icon:SetSize(16, 16)
                    rowFrame.icon:SetPoint("LEFT", rowFrame, "LEFT", 6, 0)
                    
                    rowFrame.label = rowFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
                    
                    rowFrame.val = rowFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightRight")
                    rowFrame.val:SetPoint("RIGHT", rowFrame, "RIGHT", -6, 0)
                end
                
                rowFrame:ClearAllPoints()
                rowFrame:SetSize(264, 20)
                rowFrame:SetPoint("TOPLEFT", statsContent, "TOPLEFT", 4, yOffset)
                
                if dataRowCounter % 2 == 1 then
                    rowFrame.bg:SetColorTexture(0.12, 0.12, 0.12, 0.5)
                else
                    rowFrame.bg:SetColorTexture(0, 0, 0, 0)
                end
                
                if entry.icon then
                    rowFrame.icon:SetTexture(entry.icon)
                    rowFrame.icon:Show()
                    rowFrame.label:SetPoint("LEFT", rowFrame.icon, "RIGHT", 6, 0)
                else
                    rowFrame.icon:Hide()
                    rowFrame.label:SetPoint("LEFT", rowFrame, "LEFT", 8, 0)
                end
                
                rowFrame.label:SetText("|cffffd100" .. entry.label .. "|r")
                rowFrame.val:SetText(entry.val or "")
                rowFrame:Show()
                
                statsContent.elements[elIdx] = rowFrame
                elIdx = elIdx + 1
                yOffset = yOffset - 21
            end
        end
        
        statsContent:SetHeight(math.abs(yOffset) + 30)
    end
    statsView.Refresh = RefreshStatsDisplay
    
    -- Sub-View 2: Outfits
    local outfitsView = CreateFrame("Frame", "OnePanel_OutfitsSubView", subContentView)
    outfitsView:SetAllPoints(subContentView)
    local outfitsText = outfitsView:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    outfitsText:SetPoint("TOP", outfitsView, "TOP", 0, -20)
    outfitsText:SetText("|cff00ccffEquipment Manager / Outfits|r")
    subPanel.views["outfits"] = outfitsView
    
    -- Sub-View 3: Titles
    local titlesView = CreateFrame("Frame", "OnePanel_TitlesSubView", subContentView)
    titlesView:SetAllPoints(subContentView)
    local titlesText = titlesView:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    titlesText:SetPoint("TOP", titlesView, "TOP", 0, -20)
    titlesText:SetText("|cffffcc00Character Titles|r")
    subPanel.views["titles"] = titlesView
    
    -- Switch Sub-Tab Handler
    local function SwitchSubTab(targetTabId)
        subPanel.activeTab = targetTabId
        for id, view in pairs(subPanel.views) do
            if id == targetTabId then
                view:Show()
                if type(view.Refresh) == "function" then
                    pcall(view.Refresh, view)
                end
            else
                view:Hide()
            end
        end
        for id, btn in pairs(subPanel.tabButtons) do
            if id == targetTabId then
                if btn.Glow then btn.Glow:Show() end
                if btn.Icon then btn.Icon:SetVertexColor(1, 1, 1, 1) end
            else
                if btn.Glow then btn.Glow:Hide() end
                if btn.Icon then btn.Icon:SetVertexColor(0.6, 0.6, 0.6, 1) end
            end
        end
    end
    
    -- Sub-Tab Bar Icons (Centered at Top)
    for i, tabInfo in ipairs(subTabs) do
        local tabId = tabInfo.id
        local btn = CreateFrame("Button", "OnePanel_CharSubTab_" .. tabId, subTabBar)
        btn:SetSize(32, 32)
        btn:SetPoint("TOPLEFT", subTabBar, "TOPLEFT", 12 + (i - 1) * 42, -2)
        
        local bg = btn:CreateTexture(nil, "BACKGROUND")
        bg:SetTexture("Interface\\Buttons\\UI-Quickslot2")
        bg:SetSize(52, 52)
        bg:SetPoint("CENTER", btn, "CENTER", 0, 0)
        
        local icon = btn:CreateTexture(nil, "ARTWORK")
        icon:SetSize(28, 28)
        icon:SetPoint("CENTER", btn, "CENTER", 0, 0)
        
        if tabInfo.usePortrait then
            SetPortraitTexture(icon, "player")
            btn.isPortrait = true
        else
            icon:SetTexture(tabInfo.icon)
        end
        btn.Icon = icon
        
        local glow = btn:CreateTexture(nil, "OVERLAY")
        glow:SetTexture("Interface\\Buttons\\CheckButtonHilight")
        glow:SetBlendMode("ADD")
        glow:SetAllPoints(btn)
        glow:Hide()
        btn.Glow = glow
        
        btn:SetScript("OnEnter", function(self)
            if popupTooltip then
                popupTooltip:ShowText(self, tabInfo.title)
            end
        end)
        btn:SetScript("OnLeave", function()
            if popupTooltip then popupTooltip:Hide() end
        end)
        
        btn:SetScript("OnClick", function()
            SwitchSubTab(tabId)
        end)
        
        subPanel.tabButtons[tabId] = btn
    end
    
    -- Level & Class Title Header (Centered under sub-tabs)
    local levelClassText = subPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    levelClassText:SetPoint("TOP", subTabBar, "BOTTOM", 0, -4)
    local lvl = UnitLevel("player") or 1
    local cls = UnitClass("player") or ""
    levelClassText:SetText(string.format("|cffffffffLevel %d|r |cffffcc00%s|r", lvl, cls))
    
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
        elseif event == "UNIT_MODEL_CHANGED" or event == "UNIT_PORTRAIT_UPDATE" then
            if arg1 == "player" or arg1 == nil then
                if self.Model then self.Model:SetUnit("player") end
                if subPanel.tabButtons["stats"] and subPanel.tabButtons["stats"].isPortrait then
                    SetPortraitTexture(subPanel.tabButtons["stats"].Icon, "player")
                end
            end
        end
    end)
    
    container:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
    container:RegisterEvent("UNIT_STATS")
    container:RegisterEvent("PLAYER_DAMAGE_DONE_MODS")
    container:RegisterEvent("UNIT_MODEL_CHANGED")
    container:RegisterEvent("UNIT_PORTRAIT_UPDATE")
    
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
            if container and container.SubPanel and container.SubPanel.tabButtons and container.SubPanel.tabButtons["stats"] then
                local btn = container.SubPanel.tabButtons["stats"]
                if btn.isPortrait and btn.Icon then
                    SetPortraitTexture(btn.Icon, "player")
                end
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
