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
    
    local okHp, maxHp = pcall(UnitHealthMax, "player")
    table.insert(stats, { label = "Health:", val = okHp and tostring(maxHp or 0) or "0" })
    
    local okType, powerType, powerToken = pcall(UnitPowerType, "player")
    local powerLabel = (okType and powerToken) and (powerToken:sub(1,1):upper() .. powerToken:sub(2):lower() .. ":") or "Power:"
    local okPower, maxPower = pcall(UnitPowerMax, "player")
    table.insert(stats, { label = powerLabel, val = okPower and tostring(maxPower or 0) or "0" })
    
    local okSpeed, speedStr = pcall(function()
        local rawSpeed = GetUnitSpeed and GetUnitSpeed("player")
        if not rawSpeed then return "100%" end
        local speed = math.floor((rawSpeed / 7) * 100 + 0.5)
        return speed .. "%"
    end)
    table.insert(stats, { label = "Movement Speed:", val = okSpeed and speedStr or "100%" })
    
    -- Primary Attributes
    table.insert(stats, { header = "Primary Attributes" })
    local statNames = { "Strength:", "Agility:", "Stamina:", "Intellect:", "Spirit:" }
    for i = 1, 5 do
        local okStat, _, stat = pcall(UnitStat, "player", i)
        local valStr = (okStat and stat) and tostring(stat) or "0"
        table.insert(stats, { label = statNames[i], val = valStr })
    end
    
    -- Weapons
    table.insert(stats, { header = "Weapons" })
    local okDmg, dmgStr = pcall(function()
        local minDmg, maxDmg = UnitDamage("player")
        return math.floor(minDmg or 0) .. " - " .. math.floor(maxDmg or 0)
    end)
    table.insert(stats, { label = "Main Hand:", val = okDmg and dmgStr or "0 - 0" })
    
    local okAP, apStr = pcall(function()
        local baseAP, posAP, negAP = UnitAttackPower("player")
        local ap = (baseAP or 0) + (posAP or 0) + (negAP or 0)
        return tostring(ap)
    end)
    table.insert(stats, { label = "Attack Power:", val = okAP and apStr or "0" })
    
    -- Modifiers
    table.insert(stats, { header = "Modifiers" })
    local okCrit, critStr = pcall(function()
        local crit = GetCritChance and GetCritChance()
        return string.format("%.1f%%", crit or 0)
    end)
    table.insert(stats, { label = "Critical Strike:", val = okCrit and critStr or "0.0%" })
    
    local okHaste, hasteStr = pcall(function()
        local haste = GetHaste and GetHaste()
        return string.format("%.1f%%", haste or 0)
    end)
    table.insert(stats, { label = "Haste:", val = okHaste and hasteStr or "0.0%" })
    
    -- Defense
    table.insert(stats, { header = "Defense" })
    local okDodge, dodgeStr = pcall(function()
        local dodge = GetDodgeChance and GetDodgeChance()
        return string.format("%.1f%%", dodge or 0)
    end)
    table.insert(stats, { label = "Dodge:", val = okDodge and dodgeStr or "0.0%" })
    
    local okArmor, armorStr = pcall(function()
        local _, effectiveArmor = UnitArmor("player")
        return tostring(effectiveArmor or 0)
    end)
    table.insert(stats, { label = "Armor:", val = okArmor and armorStr or "0" })
    
    -- Resistances (Wrapped in pcall for safety)
    table.insert(stats, { header = "Resistances" })
    for _, res in ipairs(ResistanceSchools) do
        local okRes, baseRes = pcall(UnitResistance, "player", res.id)
        local valStr = (okRes and type(baseRes) == "number") and tostring(baseRes) or "0"
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
    leftArea:SetWidth(338)
    
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
    -- Central 3D Player Portrait Model (Matches CharacterModelScene at Frame Level 50)
    local model = CreateFrame("PlayerModel", "OnePanel_Character3DPlayerModel", leftArea)
    model:SetSize(398, 404)
    model:SetPoint("TOPLEFT", leftArea, "TOPLEFT", 0, 0)
    model:SetPoint("BOTTOMRIGHT", leftArea, "BOTTOMRIGHT", 0, 0)
    model:SetFrameLevel(50)
    model:SetUnit("player")
    model.facing = 0
    model.camScale = 1.0
    model.targetCamScale = 1.0
    container.Model = model
    
    -- Safe Rotation Helper
    local function RotateModel(delta)
        if not model then return end
        model.facing = (model.facing or 0) + delta
        if model.SetFacing then
            pcall(function() model:SetFacing(model.facing) end)
        elseif model.SetRotation then
            pcall(function() model:SetRotation(model.facing) end)
        end
    end

    -- Safe Zoom Helper (Fine-grained Target Scale)
    local function ZoomModel(delta)
        if not model then return end
        local currentTarget = model.targetCamScale or model.camScale or 1.0
        model.targetCamScale = math.max(0.35, math.min(2.5, currentTarget + delta))
    end
    
    -- Safe Reset Helper
    local function ResetModel()
        if not model then return end
        model.facing = 0
        model.camScale = 1.0
        model.targetCamScale = 1.0
        if model.SetFacing then
            pcall(function() model:SetFacing(0) end)
        elseif model.SetRotation then
            pcall(function() model:SetRotation(0) end)
        end
        if model.SetCamDistanceScale then
            pcall(function() model:SetCamDistanceScale(1.0) end)
        end
        if model.SetPortraitZoom then
            pcall(function() model:SetPortraitZoom(0) end)
        end
        pcall(function() model:SetUnit("player") end)
    end
    
    -- Interactive Mouse Drag Rotation & Scroll Wheel Zoom with Target Lerp
    model:EnableMouse(true)
    model:EnableMouseWheel(true)
    model:SetScript("OnMouseDown", function(self, button)
        if button == "LeftButton" then
            self.isRotating = true
            self.prevCursorX = GetCursorPosition()
        end
    end)
    model:SetScript("OnMouseUp", function(self, button)
        if button == "LeftButton" then self.isRotating = false end
    end)
    model:SetScript("OnMouseWheel", function(self, delta)
        if delta > 0 then
            ZoomModel(-0.03)
        else
            ZoomModel(0.03)
        end
    end)
    model:SetScript("OnUpdate", function(self, elapsed)
        if self.isRotating then
            local currentX = GetCursorPosition()
            local diff = (currentX - self.prevCursorX) * 0.01
            RotateModel(diff)
            self.prevCursorX = currentX
        end
        
        -- Smooth Zoom Lerp Interpolation
        if self.targetCamScale then
            local curScale = self.camScale or 1.0
            if math.abs(curScale - self.targetCamScale) > 0.0005 then
                local newScale = curScale + (self.targetCamScale - curScale) * math.min(1.0, elapsed * 12)
                self.camScale = newScale
                
                if self.SetCamDistanceScale then
                    pcall(function() self:SetCamDistanceScale(newScale) end)
                end
                if self.SetPortraitZoom then
                    local pZoom = math.max(0, math.min(1, (1.0 - newScale) / 0.65))
                    pcall(function() self:SetPortraitZoom(pZoom) end)
                end
            end
        end
    end)
    
    ---------------------------------------------------------------------------
    -- 3D Model Control Toolbar (Matches CharacterModelScene.ControlFrame)
    ---------------------------------------------------------------------------
    
    local toolbar = CreateFrame("Frame", "OnePanel_3DModelToolbar", leftArea)
    toolbar:SetSize(176, 32)
    toolbar:SetPoint("TOP", leftArea, "TOP", 0, -20)
    toolbar:SetFrameLevel(120)
    toolbar:SetAlpha(0)
    
    -- Mouseover Auto-Fade for Toolbar
    leftArea:HookScript("OnUpdate", function(self, elapsed)
        if leftArea:IsMouseOver() or toolbar:IsMouseOver() then
            if toolbar:GetAlpha() < 1 then
                toolbar:SetAlpha(math.min(1, toolbar:GetAlpha() + elapsed * 6))
            end
        else
            if toolbar:GetAlpha() > 0 then
                toolbar:SetAlpha(math.max(0, toolbar:GetAlpha() - elapsed * 4))
            end
        end
    end)
    
    local function CreateBlizzardModelButton(name, iconAtlas, iconFallback, tooltipText, onClickAction, onHoldAction)
        local btn = CreateFrame("Button", name, toolbar)
        btn:SetSize(32, 32)
        
        -- Normal Background (common-button-square-gray-up)
        local normBg = btn:CreateTexture(nil, "BACKGROUND")
        local setUp = pcall(function() normBg:SetAtlas("common-button-square-gray-up", true) end)
        if not setUp or not normBg:GetTexture() then
            normBg:SetTexture("Interface\\Buttons\\UI-SquareButton-Up")
        end
        normBg:SetAllPoints(btn)
        btn:SetNormalTexture(normBg)
        
        -- Pushed Background (common-button-square-gray-down)
        local pushBg = btn:CreateTexture(nil, "BACKGROUND")
        local setDown = pcall(function() pushBg:SetAtlas("common-button-square-gray-down", true) end)
        if not setDown or not pushBg:GetTexture() then
            pushBg:SetTexture("Interface\\Buttons\\UI-SquareButton-Down")
        end
        pushBg:SetAllPoints(btn)
        btn:SetPushedTexture(pushBg)
        
        -- Icon (ARTWORK overlay)
        local icon = btn:CreateTexture(nil, "ARTWORK")
        local setIcon = pcall(function() icon:SetAtlas(iconAtlas, true) end)
        if not setIcon or not icon:GetTexture() then
            icon:SetTexture(iconFallback)
        end
        icon:SetSize(20, 20)
        icon:SetPoint("CENTER", btn, "CENTER", 0, 0)
        btn.Icon = icon
        
        -- Highlight
        local hl = btn:CreateTexture(nil, "HIGHLIGHT")
        hl:SetTexture("Interface\\Buttons\\UI-Common-MouseHilight")
        hl:SetBlendMode("ADD")
        hl:SetAllPoints(btn)
        
        btn:SetScript("OnMouseDown", function(self, button)
            if button == "LeftButton" then self.isHolding = true end
        end)
        btn:SetScript("OnMouseUp", function(self, button)
            if button == "LeftButton" then self.isHolding = false end
        end)
        btn:SetScript("OnUpdate", function(self, elapsed)
            if self.isHolding and onHoldAction then onHoldAction(elapsed) end
        end)
        btn:SetScript("OnClick", function(self, button)
            if button == "LeftButton" and onClickAction then onClickAction() end
        end)
        
        btn:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:SetText(tooltipText, 1, 1, 1)
            GameTooltip:Show()
        end)
        btn:SetScript("OnLeave", function() GameTooltip_Hide() end)
        return btn
    end
    
    local btnZoomIn = CreateBlizzardModelButton("OnePanel_BtnZoomIn", 
        "common-icon-zoomin", "Interface\\Buttons\\UI-PlusButton-Up",
        "Zoom In", 
        function() ZoomModel(-0.03) end,
        function(elapsed) ZoomModel(-0.35 * elapsed) end)
    btnZoomIn:SetPoint("LEFT", toolbar, "LEFT", 0, 0)
    
    local btnZoomOut = CreateBlizzardModelButton("OnePanel_BtnZoomOut", 
        "common-icon-zoomout", "Interface\\Buttons\\UI-MinusButton-Up",
        "Zoom Out", 
        function() ZoomModel(0.03) end,
        function(elapsed) ZoomModel(0.35 * elapsed) end)
    btnZoomOut:SetPoint("LEFT", btnZoomIn, "RIGHT", 4, 0)
    
    local btnRotLeft = CreateBlizzardModelButton("OnePanel_BtnRotLeft", 
        "common-icon-rotateleft", "Interface\\Buttons\\UI-RotationLeft-Button-Up",
        "Rotate Left", 
        function() RotateModel(-0.15) end,
        function(elapsed) RotateModel(-1.8 * elapsed) end)
    btnRotLeft:SetPoint("LEFT", btnZoomOut, "RIGHT", 4, 0)
    
    local btnRotRight = CreateBlizzardModelButton("OnePanel_BtnRotRight", 
        "common-icon-rotateright", "Interface\\Buttons\\UI-RotationRight-Button-Up",
        "Rotate Right", 
        function() RotateModel(0.15) end,
        function(elapsed) RotateModel(1.8 * elapsed) end)
    btnRotRight:SetPoint("LEFT", btnRotLeft, "RIGHT", 4, 0)
    
    local btnReset = CreateBlizzardModelButton("OnePanel_BtnReset", 
        "common-icon-undo", "Interface\\Buttons\\UI-RefreshButton",
        "Reset Model & Camera", 
        function() ResetModel() end,
        nil)
    btnReset:SetPoint("LEFT", btnRotRight, "RIGHT", 4, 0)
    
    ---------------------------------------------------------------------------
    -- Equipment Slot Buttons (Matches Native Anchors & Frame Level 101)
    ---------------------------------------------------------------------------
    
    local function CreateSlotButton(slotInfo, relativeTo, point, relPoint, x, y)
        local btn = CreateFrame("Button", "OnePanel_EqSlot_" .. slotInfo.id, leftArea)
        btn:SetSize(37, 37)
        btn:SetPoint(point, relativeTo, relPoint, x, y)
        btn:SetFrameLevel(101)
        btn.slotId = slotInfo.id
        
        btn:RegisterForClicks("LeftButtonUp", "RightButtonUp")
        btn:RegisterForDrag("LeftButton")
        
        local bg = btn:CreateTexture(nil, "BACKGROUND")
        bg:SetTexture("Interface\\Buttons\\UI-Quickslot2")
        bg:SetSize(58, 58)
        bg:SetPoint("CENTER", btn, "CENTER", 0, 0)
        btn.BG = bg
        
        local icon = btn:CreateTexture(nil, "ARTWORK")
        icon:SetSize(37, 37)
        icon:SetPoint("CENTER", btn, "CENTER", 0, 0)
        icon:SetTexture(slotInfo.icon)
        btn.Icon = icon
        
        local border = btn:CreateTexture(nil, "OVERLAY")
        border:SetSize(37, 37)
        border:SetPoint("CENTER", btn, "CENTER", 0, 0)
        border:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
        border:SetBlendMode("ADD")
        border:Hide()
        btn.Border = border
        
        local hl = btn:CreateTexture(nil, "HIGHLIGHT")
        hl:SetTexture("Interface\\Buttons\\ButtonHilight-Square")
        hl:SetBlendMode("ADD")
        hl:SetAllPoints(icon)
        
        btn:SetScript("OnClick", function(self, button)
            if InCombatLockdown and InCombatLockdown() then
                if UIErrorsFrame then
                    UIErrorsFrame:AddMessage("Cannot swap equipment in combat!", 1, 0.1, 0.1)
                end
                return
            end
            
            if button == "LeftButton" then
                PickupInventoryItem(self.slotId)
            elseif button == "RightButton" then
                if GetInventoryItemTexture("player", self.slotId) then
                    PickupInventoryItem(self.slotId)
                    if CursorHasItem() then
                        local autoEquip = _G.AutoEquipCursorItem or _G.PutItemInBackpack
                        if type(autoEquip) == "function" then
                            autoEquip()
                        else
                            pcall(PickupContainerItem, 0, 0)
                        end
                    end
                end
            end
            
            if container and container.UpdateEquipment then
                container:UpdateEquipment()
            end
        end)
        
        btn:SetScript("OnDragStart", function(self)
            if InCombatLockdown and InCombatLockdown() then return end
            PickupInventoryItem(self.slotId)
        end)
        
        btn:SetScript("OnReceiveDrag", function(self)
            if InCombatLockdown and InCombatLockdown() then return end
            PickupInventoryItem(self.slotId)
        end)
        
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
        local btn = (i == 1) and CreateSlotButton(slotInfo, leftArea, "TOPLEFT", "TOPLEFT", 24, -60)
                             or CreateSlotButton(slotInfo, prevBtn, "TOPLEFT", "BOTTOMLEFT", 0, -4)
        prevBtn = btn
        container.slots[slotInfo.id] = btn
    end
    
    prevBtn = leftArea
    for i, slotInfo in ipairs(EquipmentSlotsRight) do
        local btn = (i == 1) and CreateSlotButton(slotInfo, leftArea, "TOPRIGHT", "TOPRIGHT", -20, -60)
                             or CreateSlotButton(slotInfo, prevBtn, "TOPRIGHT", "BOTTOMRIGHT", 0, -4)
        prevBtn = btn
        container.slots[slotInfo.id] = btn
    end
    
    local mainHand = CreateSlotButton(EquipmentSlotsBottom[1], leftArea, "BOTTOM", "BOTTOM", -40, 30)
    local offHand  = CreateSlotButton(EquipmentSlotsBottom[2], leftArea, "BOTTOM", "BOTTOM", 0, 30)
    local ranged   = CreateSlotButton(EquipmentSlotsBottom[3], leftArea, "BOTTOM", "BOTTOM", 40, 30)
    container.slots[16] = mainHand
    container.slots[17] = offHand
    container.slots[18] = ranged
    
    -- Native Right-Side Collapse / Expand Toggle Button (Anchored to TOPRIGHT of leftArea at -6,-6)
    local toggleBtn = CreateFrame("Button", "OnePanel_RightSideToggleButton", leftArea)
    toggleBtn:SetSize(28, 28)
    toggleBtn:SetPoint("TOPRIGHT", leftArea, "TOPRIGHT", -6, -6)
    toggleBtn:SetFrameLevel(510)
    
    local toggleIcon = toggleBtn:CreateTexture(nil, "ARTWORK")
    toggleIcon:SetAllPoints(toggleBtn)
    local setNorm = pcall(function() toggleIcon:SetTexture(130869) end)
    if not setNorm or not toggleIcon:GetTexture() then
        toggleIcon:SetTexture("Interface\\Buttons\\UI-SpellbookSearch-DrillDown")
    end
    toggleBtn.Icon = toggleIcon
    
    local toggleHilight = toggleBtn:CreateTexture(nil, "HIGHLIGHT")
    local setHilight = pcall(function() toggleHilight:SetTexture(130757) end)
    if not setHilight or not toggleHilight:GetTexture() then
        toggleHilight:SetTexture("Interface\\Buttons\\UI-Common-MouseHilight")
    end
    toggleHilight:SetBlendMode("ADD")
    toggleHilight:SetAllPoints(toggleBtn)
    
    local function UpdateToggleIcon()
        if OnePanel and OnePanel.isExpanded then
            toggleIcon:SetTexCoord(0, 1, 0, 1)
        else
            toggleIcon:SetTexCoord(1, 0, 0, 1)
        end
    end
    toggleBtn.UpdateIcon = UpdateToggleIcon
    UpdateToggleIcon()
    
    toggleBtn:SetScript("OnClick", function()
        if OnePanel and OnePanel.SetPanelExpanded then
            OnePanel:SetPanelExpanded(not OnePanel.isExpanded)
        end
        UpdateToggleIcon()
    end)
    
    toggleBtn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText((OnePanel and OnePanel.isExpanded) and "Collapse Side Panel" or "Expand Side Panel", 1, 1, 1)
        GameTooltip:Show()
    end)
    toggleBtn:SetScript("OnLeave", function() GameTooltip_Hide() end)
    
    container.RightSideToggleButton = toggleBtn

    ---------------------------------------------------------------------------
    -- Collapsible Side Panel & Subtab Header
    ---------------------------------------------------------------------------
    
    local subPanel = CreateFrame("Frame", "OnePanel_CharacterSubPanel", container)
    subPanel:SetPoint("TOPRIGHT", container, "TOPRIGHT", -10, -12)
    subPanel:SetPoint("BOTTOMRIGHT", container, "BOTTOMRIGHT", -10, 12)
    subPanel:SetWidth(208)
    
    if Utils and Utils.FrameHelper then
        Utils.FrameHelper:ApplyBackdrop(subPanel,
            "Interface\\FrameGeneral\\UI-Background-Marble",
            "Interface\\Tooltips\\UI-Tooltip-Border",
            16, 16, { left = 4, right = 4, top = 4, bottom = 4 }
        )
    end
    container.SubPanel = subPanel
    
    -- Sync subPanel visibility with OnePanel master expand state
    if OnePanel then
        subPanel:SetShown(OnePanel.isExpanded ~= false)
    end
    if Utils and Utils.EventBus then
        Utils.EventBus:Register("ONEPANEL_EXPAND_STATE_CHANGED", function(isExpanded)
            if subPanel and subPanel.SetShown then
                subPanel:SetShown(isExpanded)
            end
            if toggleBtn and toggleBtn.UpdateIcon then
                toggleBtn:UpdateIcon()
            end
        end)
    end
    
    -- Sub-Tab Bar Header
    local subTabBar = CreateFrame("Frame", "OnePanel_PaperDollSidebarTabs", subPanel)
    subTabBar:SetSize(208, 48)
    subTabBar:SetPoint("TOP", subPanel, "TOP", 0, -4)
    
    local subTabs = {
        { id = "stats",   title = "Character Stats",   usePortrait = true },
        { id = "outfits", title = "Equipment Manager", icon = "Interface\\PaperDollInfoFrame\\UI-EquipmentManager-Toggle" },
        { id = "titles",  title = "Titles",            icon = "Interface\\Icons\\INV_Scroll_11" },
    }
    
    subPanel.activeTab = "stats"
    subPanel.tabButtons = {}
    subPanel.views = {}
    
    -- Level & Class Title Header (Centered under sub-tabs with equal 4px padding)
    local levelClassText = subPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    levelClassText:SetPoint("TOP", subTabBar, "TOP", 0, -46)
    local lvl = UnitLevel("player") or 1
    local cls = UnitClass("player") or ""
    levelClassText:SetText(string.format("|cffffffffLevel %d|r |cffffcc00%s|r", lvl, cls))
    
    -- Sub-View Content Container (Starts 4px below Level header)
    local subContentView = CreateFrame("Frame", "OnePanel_CharacterSubContentView", subPanel)
    subContentView:SetPoint("TOPLEFT", subPanel, "TOPLEFT", 4, -68)
    subContentView:SetPoint("BOTTOMRIGHT", subPanel, "BOTTOMRIGHT", -4, 6)
    subPanel.ContentView = subContentView
    
    ---------------------------------------------------------------------------
    -- Sub-View 1: Character Stats List
    ---------------------------------------------------------------------------
    
    local statsView = CreateFrame("ScrollFrame", "OnePanel_StatsSubView", subContentView, "UIPanelScrollFrameTemplate")
    statsView:SetAllPoints(subContentView)
    
    -- Mouse Wheel Smooth Scrolling (24px step per scroll tick)
    statsView:EnableMouseWheel(true)
    statsView:SetScript("OnMouseWheel", function(self, delta)
        local cur = self:GetVerticalScroll()
        local maxScroll = self:GetVerticalScrollRange()
        local step = 24
        local newScroll = math.max(0, math.min(maxScroll, cur - (delta * step)))
        self:SetVerticalScroll(newScroll)
    end)
    
    -- Scrollbar Anchor & Arrow Buttons Step Override (Inside subPanel marble background, right of 174px table)
    local sbName = statsView:GetName() .. "ScrollBar"
    local scrollBar = _G[sbName]
    if scrollBar then
        scrollBar:ClearAllPoints()
        scrollBar:SetPoint("TOPRIGHT", subContentView, "TOPRIGHT", -6, -18)
        scrollBar:SetPoint("BOTTOMRIGHT", subContentView, "BOTTOMRIGHT", -6, 18)
        scrollBar:SetValueStep(20)
        local upBtn = _G[sbName .. "ScrollUpButton"]
        local downBtn = _G[sbName .. "ScrollDownButton"]
        if upBtn then
            upBtn:SetScript("OnClick", function()
                local cur = statsView:GetVerticalScroll()
                statsView:SetVerticalScroll(math.max(0, cur - 20))
            end)
        end
        if downBtn then
            downBtn:SetScript("OnClick", function()
                local cur = statsView:GetVerticalScroll()
                local maxScroll = statsView:GetVerticalScrollRange()
                statsView:SetVerticalScroll(math.min(maxScroll, cur + 20))
            end)
        end
    end
    
    local statsContent = CreateFrame("Frame", "OnePanel_StatsContent", statsView)
    statsContent:SetSize(180, 600)
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
                headerBtn:SetSize(174, 22)
                headerBtn:SetPoint("TOPLEFT", statsContent, "TOPLEFT", 3, yOffset)
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
                    rowFrame.icon:SetPoint("LEFT", rowFrame, "LEFT", 4, 0)
                    
                    rowFrame.label = rowFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
                    
                    rowFrame.val = rowFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightRight")
                    rowFrame.val:SetPoint("RIGHT", rowFrame, "RIGHT", -4, 0)
                end
                
                rowFrame:ClearAllPoints()
                rowFrame:SetSize(174, 20)
                rowFrame:SetPoint("TOPLEFT", statsContent, "TOPLEFT", 3, yOffset)
                
                if dataRowCounter % 2 == 1 then
                    rowFrame.bg:SetColorTexture(0.12, 0.12, 0.12, 0.5)
                else
                    rowFrame.bg:SetColorTexture(0, 0, 0, 0)
                end
                
                if entry.icon then
                    rowFrame.icon:SetTexture(entry.icon)
                    rowFrame.icon:Show()
                    rowFrame.label:SetPoint("LEFT", rowFrame.icon, "RIGHT", 4, 0)
                else
                    rowFrame.icon:Hide()
                    rowFrame.label:SetPoint("LEFT", rowFrame, "LEFT", 6, 0)
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
                if btn.TabSelected then btn.TabSelected:Show() end
                if btn.Icon then btn.Icon:SetVertexColor(1, 1, 1, 1) end
            else
                if btn.TabSelected then btn.TabSelected:Hide() end
                if btn.Icon then btn.Icon:SetVertexColor(0.6, 0.6, 0.6, 1) end
            end
        end
    end
    
    -- Sub-Tab Bar Icons (Matches PaperDollSidebarTab: CheckButton 42x42 with UI-Character-Info-StatTab atlases)
    local startX = math.floor((208 - (42 * 3)) / 2) -- 41px centered
    
    for i, tabInfo in ipairs(subTabs) do
        local tabId = tabInfo.id
        local btn = CreateFrame("CheckButton", "OnePanel_CharSubTab_" .. tabId, subTabBar)
        btn:SetSize(42, 42)
        btn:SetPoint("TOPLEFT", subTabBar, "TOPLEFT", startX + (i - 1) * 42, 0)
        
        -- Background Icon (Layer: BACKGROUND)
        local icon = btn:CreateTexture(nil, "BACKGROUND")
        icon:SetSize(36, 33)
        icon:SetPoint("CENTER", btn, "CENTER", 0, 0)
        
        if tabInfo.usePortrait then
            SetPortraitTexture(icon, "player")
            btn.isPortrait = true
        else
            icon:SetTexture(tabInfo.icon)
        end
        btn.Icon = icon
        
        -- Border Ring Texture (Layer: BORDER, Atlas: UI-Character-Info-StatTab)
        local tabBorder = btn:CreateTexture(nil, "BORDER")
        local setBorder = pcall(function() tabBorder:SetAtlas("UI-Character-Info-StatTab", true) end)
        if not setBorder or not tabBorder:GetTexture() then
            tabBorder:SetTexture(8175457)
        end
        tabBorder:SetAllPoints(btn)
        btn.TabBorder = tabBorder
        
        -- Selected Active Overlay (Layer: OVERLAY, Atlas: UI-Character-Info-StatTab-Selected)
        local tabSelected = btn:CreateTexture(nil, "OVERLAY", nil, 1)
        local setSelected = pcall(function() tabSelected:SetAtlas("UI-Character-Info-StatTab-Selected", true) end)
        if not setSelected or not tabSelected:GetTexture() then
            tabSelected:SetTexture(8175457)
        end
        tabSelected:SetAllPoints(btn)
        tabSelected:Hide()
        btn.TabSelected = tabSelected
        
        -- Hover Highlight
        local tabHilight = btn:CreateTexture(nil, "HIGHLIGHT")
        tabHilight:SetTexture("Interface\\Buttons\\UI-Common-MouseHilight")
        tabHilight:SetAllPoints(btn)
        tabHilight:SetBlendMode("ADD")
        
        btn:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText(tabInfo.title, 1, 1, 1)
            GameTooltip:Show()
        end)
        btn:SetScript("OnLeave", function()
            GameTooltip_Hide()
        end)
        
        btn:SetScript("OnClick", function()
            SwitchSubTab(tabId)
        end)
        
        subPanel.tabButtons[tabId] = btn
    end
    
    SwitchSubTab("stats")
    
    ---------------------------------------------------------------------------
    -- Equipment Update Handler
    ---------------------------------------------------------------------------
    
    local function UpdateEquipment()
        for slotId, btn in pairs(container.slots) do
            local texture = GetInventoryItemTexture("player", slotId)
            local isLocked = IsInventoryItemLocked and IsInventoryItemLocked(slotId)
            
            if texture then
                btn.Icon:SetTexture(texture)
                if isLocked then
                    btn.Icon:SetVertexColor(0.4, 0.4, 0.4, 1)
                    btn.Icon:SetDesaturated(true)
                else
                    btn.Icon:SetVertexColor(1, 1, 1, 1)
                    btn.Icon:SetDesaturated(false)
                end
                
                local quality = GetInventoryItemQuality and GetInventoryItemQuality("player", slotId)
                if quality and quality > 1 and GetItemQualityColor then
                    local r, g, b = GetItemQualityColor(quality)
                    if btn.Border then
                        btn.Border:SetVertexColor(r, g, b, 1)
                        btn.Border:Show()
                    end
                else
                    if btn.Border then btn.Border:Hide() end
                end
            else
                if btn.Border then btn.Border:Hide() end
                btn.Icon:SetDesaturated(false)
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
        if event == "PLAYER_EQUIPMENT_CHANGED" or event == "UNIT_STATS" or event == "PLAYER_DAMAGE_DONE_MODS" or event == "ITEM_LOCK_CHANGED" or event == "CURSOR_CHANGED" then
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
    container:RegisterEvent("ITEM_LOCK_CHANGED")
    container:RegisterEvent("CURSOR_CHANGED")
    
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
            if OnePanel and OnePanel.SetHeaderPortrait then
                OnePanel:SetHeaderPortrait(nil, nil, false)
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
