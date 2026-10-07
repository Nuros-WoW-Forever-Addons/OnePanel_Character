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
    
    -- Dedicated Background Container bounded inside leftArea frame insets
    local bgContainer = CreateFrame("Frame", "OnePanel_CharacterBgContainer", leftArea)
    bgContainer:SetClipsChildren(true)
    bgContainer:SetPoint("TOPLEFT", leftArea, "TOPLEFT", 10, -12)
    bgContainer:SetPoint("BOTTOMRIGHT", leftArea, "BOTTOMRIGHT", -4, 12)
    
    if Utils and Utils.FrameHelper then
        Utils.FrameHelper:ApplyBackdrop(bgContainer,
            "Interface\\FrameGeneral\\UI-Background-Marble",
            "Interface\\Tooltips\\UI-Tooltip-Border",
            16, 16, { left = 4, right = 4, top = 4, bottom = 4 }
        )
    end
    
    local RefreshPlayerModel = nil
    
    local function UpdateRaceBackgroundArt()
        if Utils and Utils.FrameHelper then
            Utils.FrameHelper:ApplyBackdrop(bgContainer,
                "Interface\\FrameGeneral\\UI-Background-Marble",
                "Interface\\Tooltips\\UI-Tooltip-Border",
                16, 16, { left = 4, right = 4, top = 4, bottom = 4 }
            )
        end
        return true
    end
    
    container.UpdateRaceBackgroundArt = UpdateRaceBackgroundArt
    
    -- Central 3D Player Portrait Model (Matches CharacterModelScene at Frame Level 50)
    local model = CreateFrame("PlayerModel", "OnePanel_Character3DPlayerModel", leftArea)
    model:SetPoint("TOPLEFT", leftArea, "TOPLEFT", 0, 0)
    model:SetPoint("BOTTOMRIGHT", leftArea, "BOTTOMRIGHT", 0, 0)
    model:SetFrameLevel(50)
    container.Model = model
    
    -- Form-aware Model Refresh & Camera/Scale Setup
    local function RefreshPlayerModel()
        if not model then return end
        pcall(function() model:SetUnit("player") end)
        
        local baseCamScale = 1.0
        local basePosY = 0     -- Horizontal offset (0 = centered)
        local basePosZ = -0.04 -- Vertical offset (raised up inside viewport)
        
        local form = GetShapeshiftForm and GetShapeshiftForm()
        local formID = GetShapeshiftFormID and GetShapeshiftFormID()
        local powerType = UnitPowerType and UnitPowerType("player")
        
        local isBear = (form == 1) or (formID == 1) or (formID == 5487) or (powerType == 1) or (powerType == (Enum and Enum.PowerType and Enum.PowerType.Rage))
        local isCat = (form == 2) or (formID == 5) or (formID == 768) or (powerType == 3) or (powerType == (Enum and Enum.PowerType and Enum.PowerType.Energy))
        
        if isBear or (form and form > 0) then
            if isBear then
                baseCamScale = 1.50
                basePosY = 0
                basePosZ = -0.22
            elseif isCat then
                baseCamScale = 1.30
                basePosY = 0
                basePosZ = -0.15
            else
                baseCamScale = 1.50
                basePosY = 0
                basePosZ = -0.22
            end
        end
        
        model.baseCamScale = baseCamScale
        model.basePosY = basePosY
        model.basePosZ = basePosZ
        model.camScale = baseCamScale
        model.targetCamScale = baseCamScale
        model.facing = 0
        
        if model.SetFacing then
            pcall(function() model:SetFacing(0) end)
        elseif model.SetRotation then
            pcall(function() model:SetRotation(0) end)
        end
        if model.SetCamDistanceScale then
            pcall(function() model:SetCamDistanceScale(baseCamScale) end)
        end
        if model.SetPosition then
            pcall(function() model:SetPosition(0, basePosY, basePosZ) end)
        end
    end
    
    container.RefreshPlayerModel = RefreshPlayerModel
    
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
        local base = model.baseCamScale or 1.0
        local currentTarget = model.targetCamScale or model.camScale or base
        model.targetCamScale = math.max(0.35 * base, math.min(2.5 * base, currentTarget + delta))
    end
    
    -- Safe Reset Helper
    local function ResetModel()
        RefreshPlayerModel()
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
            local base = self.baseCamScale or 1.0
            local curScale = self.camScale or base
            if math.abs(curScale - self.targetCamScale) > 0.0005 then
                local newScale = curScale + (self.targetCamScale - curScale) * math.min(1.0, elapsed * 12)
                self.camScale = newScale
                
                if self.SetCamDistanceScale then
                    pcall(function() self:SetCamDistanceScale(newScale) end)
                end
                local posY = self.basePosY or 0
                local posZ = self.basePosZ or -0.08
                if self.SetPosition then
                    pcall(function() self:SetPosition(0, posY, posZ) end)
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
    
    local btnRotLeft = CreateBlizzardModelButton("OnePanel_BtnRotLeft", 
        "common-icon-rotateleft", "Interface\\Buttons\\UI-RotationLeft-Button-Up",
        "Rotate Left", 
        function() RotateModel(-0.15) end,
        function(elapsed) RotateModel(-1.8 * elapsed) end)
    btnRotLeft:SetPoint("CENTER", toolbar, "CENTER", 0, 0)
    
    local btnZoomOut = CreateBlizzardModelButton("OnePanel_BtnZoomOut", 
        "common-icon-zoomout", "Interface\\Buttons\\UI-MinusButton-Up",
        "Zoom Out", 
        function() ZoomModel(0.03) end,
        function(elapsed) ZoomModel(0.35 * elapsed) end)
    btnZoomOut:SetPoint("RIGHT", btnRotLeft, "LEFT", 2, 0)
    
    local btnZoomIn = CreateBlizzardModelButton("OnePanel_BtnZoomIn", 
        "common-icon-zoomin", "Interface\\Buttons\\UI-PlusButton-Up",
        "Zoom In", 
        function() ZoomModel(-0.03) end,
        function(elapsed) ZoomModel(-0.35 * elapsed) end)
    btnZoomIn:SetPoint("RIGHT", btnZoomOut, "LEFT", 2, 0)
    
    local btnRotRight = CreateBlizzardModelButton("OnePanel_BtnRotRight", 
        "common-icon-rotateright", "Interface\\Buttons\\UI-RotationRight-Button-Up",
        "Rotate Right", 
        function() RotateModel(0.15) end,
        function(elapsed) RotateModel(1.8 * elapsed) end)
    btnRotRight:SetPoint("LEFT", btnRotLeft, "RIGHT", -2, 0)
    
    local btnReset = CreateBlizzardModelButton("OnePanel_BtnReset", 
        "common-icon-undo", "Interface\\Buttons\\UI-RefreshButton",
        "Reset Model & Camera", 
        function() ResetModel() end,
        nil)
    btnReset:SetPoint("LEFT", btnRotRight, "RIGHT", -2, 0)
    
    ---------------------------------------------------------------------------
    -- Equipment Slot Item Selector Flyout
    ---------------------------------------------------------------------------
    
    local function GetItemsForSlot(slotID)
        local items = {}
        
        local slotEquipTypes = {
            [1]  = { "INVTYPE_HEAD" },
            [2]  = { "INVTYPE_NECK" },
            [3]  = { "INVTYPE_SHOULDER" },
            [15] = { "INVTYPE_CLOAK" },
            [5]  = { "INVTYPE_CHEST", "INVTYPE_ROBE" },
            [4]  = { "INVTYPE_BODY" },
            [19] = { "INVTYPE_TABARD" },
            [9]  = { "INVTYPE_WRIST" },
            [10] = { "INVTYPE_HAND" },
            [6]  = { "INVTYPE_WAIST" },
            [7]  = { "INVTYPE_LEGS" },
            [8]  = { "INVTYPE_FEET" },
            [11] = { "INVTYPE_FINGER" },
            [12] = { "INVTYPE_FINGER" },
            [13] = { "INVTYPE_TRINKET" },
            [14] = { "INVTYPE_TRINKET" },
            [16] = { "INVTYPE_WEAPON", "INVTYPE_2HWEAPON", "INVTYPE_WEAPONMAINHAND" },
            [17] = { "INVTYPE_WEAPON", "INVTYPE_WEAPONOFFHAND", "INVTYPE_SHIELD", "INVTYPE_HOLDABLE" },
            [18] = { "INVTYPE_RANGED", "INVTYPE_RANGEDRIGHT", "INVTYPE_THROWN", "INVTYPE_RELIC" },
        }
        
        local validTypes = slotEquipTypes[slotID]
        if not validTypes then return items end
        
        local validMap = {}
        for _, t in ipairs(validTypes) do validMap[t] = true end
        
        local getItemInfoFunc = (C_Item and C_Item.GetItemInfo) or GetItemInfo
        local getItemInfoInstantFunc = (C_Item and C_Item.GetItemInfoInstant) or GetItemInfoInstant
        
        for bag = 0, 4 do
            local numSlots = C_Container and C_Container.GetContainerNumSlots and C_Container.GetContainerNumSlots(bag) or (GetContainerNumSlots and GetContainerNumSlots(bag))
            if numSlots then
                for slot = 1, numSlots do
                    local link = C_Container and C_Container.GetContainerItemLink and C_Container.GetContainerItemLink(bag, slot) or (GetContainerItemLink and GetContainerItemLink(bag, slot))
                    if link then
                        local equipLoc, texture
                        if getItemInfoInstantFunc then
                            local ok, _, _, _, eLoc, icon = pcall(getItemInfoInstantFunc, link)
                            if ok then
                                equipLoc = eLoc
                                texture = icon
                            end
                        end
                        
                        local name, quality, itemLevel
                        if getItemInfoFunc then
                            local ok, n, _, q, iLvl, _, _, _, _, eLoc, tex = pcall(getItemInfoFunc, link)
                            if ok then
                                name = n
                                quality = q
                                itemLevel = iLvl
                                if not equipLoc then equipLoc = eLoc end
                                if not texture then texture = tex end
                            end
                        end
                        
                        if equipLoc and validMap[equipLoc] then
                            table.insert(items, {
                                link = link,
                                name = name or "Item",
                                quality = quality or 1,
                                itemLevel = itemLevel or 0,
                                texture = texture or "Interface\\Icons\\INV_Misc_QuestionMark",
                                bag = bag,
                                slot = slot,
                            })
                        end
                    end
                end
            end
        end
        
        return items
    end

    local function ShowEquipmentSlotFlyout(anchorFrame, slotInfo)
        if not _G["OnePanel_EquipmentFlyout"] then
            local flyout = CreateFrame("Frame", "OnePanel_EquipmentFlyout", UIParent)
            flyout:SetFrameStrata("DIALOG")
            flyout:SetFrameLevel(1000)
            flyout:SetClampedToScreen(true)
            
            if Utils and Utils.FrameHelper then
                Utils.FrameHelper:ApplyBackdrop(flyout,
                    "Interface\\FrameGeneral\\UI-Background-Marble",
                    "Interface\\Tooltips\\UI-Tooltip-Border",
                    16, 16, { left = 4, right = 4, top = 4, bottom = 4 }
                )
            end
            
            local scrollFrame = CreateFrame("ScrollFrame", "OnePanel_EquipmentFlyoutScroll", flyout, "UIPanelScrollFrameTemplate")
            scrollFrame:SetPoint("TOPLEFT", flyout, "TOPLEFT", 6, -6)
            scrollFrame:SetPoint("BOTTOMRIGHT", flyout, "BOTTOMRIGHT", -24, 6)
            
            local content = CreateFrame("Frame", "OnePanel_EquipmentFlyoutContent", scrollFrame)
            content:SetSize(180, 180)
            scrollFrame:SetScrollChild(content)
            flyout.Content = content
        end
        
        local flyout = _G["OnePanel_EquipmentFlyout"]
        flyout.currentSlotId = slotInfo.id
        
        -- Position flyout next to anchor frame
        flyout:ClearAllPoints()
        local x = anchorFrame:GetCenter() or 0
        local screenW = UIParent:GetWidth() or 1000
        
        if x > (screenW / 2) then
            flyout:SetPoint("TOPRIGHT", anchorFrame, "TOPLEFT", -6, 0)
        else
            flyout:SetPoint("TOPLEFT", anchorFrame, "TOPRIGHT", 6, 0)
        end
        
        local bagItems = GetItemsForSlot(slotInfo.id)
        local currentTexture = GetInventoryItemTexture("player", slotInfo.id)
        local hasEquipped = currentTexture ~= nil
        
        local content = flyout.Content
        if not content.buttons then content.buttons = {} end
        for _, b in ipairs(content.buttons) do b:Hide() end
        
        local flyoutButtons = {}
        
        -- 1. If an item is currently equipped, the first item in the grid is the Unequip button
        if hasEquipped then
            table.insert(flyoutButtons, {
                isUnequip = true,
                name = "Unequip Item",
                texture = currentTexture,
            })
        end
        
        -- 2. Add all compatible items from bags
        for _, item in ipairs(bagItems) do
            table.insert(flyoutButtons, item)
        end
        
        if #flyoutButtons == 0 then
            local emptyMsg = content.emptyMsg
            if not emptyMsg then
                emptyMsg = content:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
                emptyMsg:SetPoint("CENTER", content, "CENTER", 0, 0)
                emptyMsg:SetText("|cffaaaaaaNo items available|r")
                content.emptyMsg = emptyMsg
            end
            emptyMsg:Show()
            flyout:SetSize(150, 60)
            content:SetSize(130, 48)
            flyout:Show()
            return
        elseif content.emptyMsg then
            content.emptyMsg:Hide()
        end
        
        local btnSize = 37
        local cols = math.min(#flyoutButtons, 4) -- Up to 4 columns per row
        local rows = math.ceil(#flyoutButtons / cols)
        local spacing = 4
        
        for idx, entry in ipairs(flyoutButtons) do
            local btn = content.buttons[idx]
            if not btn then
                btn = CreateFrame("Button", nil, content)
                btn:SetSize(btnSize, btnSize)
                
                local bg = btn:CreateTexture(nil, "BACKGROUND")
                bg:SetTexture("Interface\\Buttons\\UI-Quickslot2")
                bg:SetSize(58, 58)
                bg:SetPoint("CENTER", btn, "CENTER", 0, 0)
                btn.BG = bg
                
                local icon = btn:CreateTexture(nil, "ARTWORK")
                icon:SetSize(33, 33)
                icon:SetPoint("CENTER", btn, "CENTER", 0, 0)
                icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
                btn.Icon = icon
                
                local border = btn:CreateTexture(nil, "OVERLAY")
                border:SetSize(33, 33)
                border:SetPoint("CENTER", btn, "CENTER", 0, 0)
                border:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
                border:SetBlendMode("ADD")
                btn.Border = border
                
                local unequipCross = btn:CreateTexture(nil, "OVERLAY", nil, 2)
                unequipCross:SetTexture("Interface\\Buttons\\UI-Group-Loot-Pass-Up")
                unequipCross:SetSize(33, 33)
                unequipCross:SetPoint("CENTER", btn, "CENTER", 0, 0)
                btn.UnequipCross = unequipCross
                
                local hl = btn:CreateTexture(nil, "HIGHLIGHT")
                hl:SetTexture("Interface\\Buttons\\ButtonHilight-Square")
                hl:SetBlendMode("ADD")
                hl:SetAllPoints(icon)
                
                content.buttons[idx] = btn
            end
            
            local col = (idx - 1) % cols
            local row = math.floor((idx - 1) / cols)
            
            btn:ClearAllPoints()
            btn:SetPoint("TOPLEFT", content, "TOPLEFT", col * (btnSize + spacing), -row * (btnSize + spacing))
            
            if entry.isUnequip then
                btn.Icon:SetTexture(entry.texture or slotInfo.icon)
                btn.Icon:SetDesaturated(true)
                btn.Icon:SetVertexColor(0.6, 0.6, 0.6, 0.7)
                btn.UnequipCross:Show()
                btn.Border:Hide()
                
                btn:SetScript("OnEnter", function(self)
                    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                    GameTooltip:SetText("Unequip Slot", 1, 0.3, 0.3)
                    GameTooltip:AddLine("Click to remove equipped item.", 0.8, 0.8, 0.8)
                    GameTooltip:Show()
                end)
                btn:SetScript("OnLeave", function() GameTooltip_Hide() end)
                
                btn:SetScript("OnClick", function()
                    if GetInventoryItemTexture("player", slotInfo.id) then
                        PickupInventoryItem(slotInfo.id)
                        if CursorHasItem() then
                            local autoEquip = _G.AutoEquipCursorItem or _G.PutItemInBackpack
                            if type(autoEquip) == "function" then
                                autoEquip()
                            else
                                pcall(PickupContainerItem, 0, 0)
                            end
                        end
                    end
                    flyout:Hide()
                end)
            else
                btn.UnequipCross:Hide()
                btn.Icon:SetTexture(entry.texture)
                btn.Icon:SetDesaturated(false)
                btn.Icon:SetVertexColor(1, 1, 1, 1)
                
                local r, g, b = 1, 1, 1
                if entry.quality and GetItemQualityColor then
                    r, g, b = GetItemQualityColor(entry.quality)
                end
                if entry.quality and entry.quality > 1 then
                    btn.Border:SetVertexColor(r, g, b, 1)
                    btn.Border:Show()
                else
                    btn.Border:Hide()
                end
                
                btn:SetScript("OnEnter", function(self)
                    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                    GameTooltip:SetHyperlink(entry.link)
                    GameTooltip:Show()
                end)
                btn:SetScript("OnLeave", function() GameTooltip_Hide() end)
                
                btn:SetScript("OnClick", function()
                    if C_Container and C_Container.UseContainerItem then
                        C_Container.UseContainerItem(entry.bag, entry.slot)
                    elseif UseContainerItem then
                        UseContainerItem(entry.bag, entry.slot)
                    end
                    flyout:Hide()
                end)
            end
            
            btn:Show()
        end
        
        local gridW = cols * (btnSize + spacing) - spacing + 12
        local gridH = rows * (btnSize + spacing) - spacing + 12
        local maxH = 210
        local actualH = math.min(maxH, gridH)
        
        content:SetSize(cols * (btnSize + spacing), rows * (btnSize + spacing))
        flyout:SetSize(gridW + 28, actualH + 16)
        flyout:Show()
    end

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
            
            if CursorHasItem() then
                PickupInventoryItem(self.slotId)
            else
                local flyout = _G["OnePanel_EquipmentFlyout"]
                if flyout and flyout:IsShown() and flyout.currentSlotId == slotInfo.id then
                    flyout:Hide()
                else
                    ShowEquipmentSlotFlyout(self, slotInfo)
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
        
        -- Popout Flyout Arrow Button (Appears next to slot when Equipment Manager sub-tab is active)
        local arrow = CreateFrame("Button", nil, btn)
        arrow:SetFrameLevel(btn:GetFrameLevel() + 5)
        
        local isLeftSlot = false
        for _, s in ipairs(EquipmentSlotsLeft) do
            if s.id == slotInfo.id then isLeftSlot = true break end
        end
        local isRightSlot = false
        for _, s in ipairs(EquipmentSlotsRight) do
            if s.id == slotInfo.id then isRightSlot = true break end
        end
        local isBottomSlot = not isLeftSlot and not isRightSlot
        
        if isLeftSlot then
            arrow:SetSize(20, 43)
            arrow:SetPoint("LEFT", btn, "RIGHT", -2, 0)
        elseif isRightSlot then
            arrow:SetSize(20, 43)
            arrow:SetPoint("RIGHT", btn, "LEFT", 2, 0)
        else
            arrow:SetSize(43, 20)
            arrow:SetPoint("BOTTOM", btn, "TOP", 0, -2)
        end
        
        local normalTex = arrow:CreateTexture(nil, "ARTWORK")
        normalTex:SetAllPoints(arrow)
        local setAtlasNorm = pcall(function() normalTex:SetAtlas("UI-Character-Info-Button-PullSide", true) end)
        if not setAtlasNorm or not normalTex:GetTexture() then
            normalTex:SetTexture(8175457)
        end
        if isLeftSlot and normalTex.SetTexCoord then
            normalTex:SetTexCoord(1, 0, 0, 1) -- Chevron points RIGHT towards center/flyout
        elseif isRightSlot and normalTex.SetTexCoord then
            normalTex:SetTexCoord(0, 1, 0, 1) -- Chevron points LEFT towards center/flyout
        elseif isBottomSlot and normalTex.SetRotation then
            normalTex:SetRotation(math.pi / 2) -- Chevron points UP towards paperdoll model
        end
        arrow:SetNormalTexture(normalTex)
        
        local pushedTex = arrow:CreateTexture(nil, "ARTWORK")
        pushedTex:SetAllPoints(arrow)
        local setAtlasPushed = pcall(function() pushedTex:SetAtlas("UI-Character-Info-Button-PullSide-Pressed", true) end)
        if not setAtlasPushed or not pushedTex:GetTexture() then
            pushedTex:SetTexture(8175457)
        end
        if isLeftSlot and pushedTex.SetTexCoord then
            pushedTex:SetTexCoord(1, 0, 0, 1)
        elseif isRightSlot and pushedTex.SetTexCoord then
            pushedTex:SetTexCoord(0, 1, 0, 1)
        elseif isBottomSlot and pushedTex.SetRotation then
            pushedTex:SetRotation(math.pi / 2)
        end
        arrow:SetPushedTexture(pushedTex)
        
        local highlightTex = arrow:CreateTexture(nil, "HIGHLIGHT")
        highlightTex:SetAllPoints(arrow)
        local setAtlasHl = pcall(function() highlightTex:SetAtlas("UI-Character-Info-Button-PullSide", true) end)
        if not setAtlasHl or not highlightTex:GetTexture() then
            highlightTex:SetTexture(8175457)
        end
        if isLeftSlot and highlightTex.SetTexCoord then
            highlightTex:SetTexCoord(1, 0, 0, 1)
        elseif isRightSlot and highlightTex.SetTexCoord then
            highlightTex:SetTexCoord(0, 1, 0, 1)
        elseif isBottomSlot and highlightTex.SetRotation then
            highlightTex:SetRotation(math.pi / 2)
        end
        highlightTex:SetBlendMode("ADD")
        arrow:SetHighlightTexture(highlightTex)
        
        arrow:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText("Choose item for " .. slotInfo.name, 1, 1, 1)
            GameTooltip:Show()
        end)
        arrow:SetScript("OnLeave", function() GameTooltip_Hide() end)
        
        arrow:SetScript("OnClick", function()
            local flyout = _G["OnePanel_EquipmentFlyout"]
            if flyout and flyout:IsShown() and flyout.currentSlotId == slotInfo.id then
                flyout:Hide()
            else
                ShowEquipmentSlotFlyout(btn, slotInfo)
            end
        end)
        
        arrow:Hide()
        btn.FlyoutArrow = arrow

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
    
    -- Native Right-Side Collapse / Expand Toggle Button (Anchored to TOPRIGHT of leftArea at -14,-18)
    local toggleBtn = CreateFrame("Button", "OnePanel_RightSideToggleButton", leftArea)
    toggleBtn:SetSize(28, 28)
    toggleBtn:SetPoint("TOPRIGHT", leftArea, "TOPRIGHT", -14, -18)
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
    
    ---------------------------------------------------------------------------
    -- Sub-View 2: Equipment Manager / Outfits
    ---------------------------------------------------------------------------
    local outfitsView = CreateFrame("Frame", "OnePanel_OutfitsSubView", subContentView)
    outfitsView:SetAllPoints(subContentView)
    subPanel.views["outfits"] = outfitsView
    
    -- Top Action Buttons (+ New Set & Save Current)
    local newSetBtn = CreateFrame("Button", "OnePanel_NewSetBtn", outfitsView, "UIPanelButtonTemplate")
    newSetBtn:SetSize(86, 22)
    newSetBtn:SetPoint("TOPLEFT", outfitsView, "TOPLEFT", 4, -4)
    newSetBtn:SetText("+ New Set")
    
    local saveCurrentBtn = CreateFrame("Button", "OnePanel_SaveCurrentBtn", outfitsView, "UIPanelButtonTemplate")
    saveCurrentBtn:SetSize(86, 22)
    saveCurrentBtn:SetPoint("TOPRIGHT", outfitsView, "TOPRIGHT", -22, -4)
    saveCurrentBtn:SetText("Save Current")
    
    -- Equipment Sets Scroll View
    local outfitsScroll = CreateFrame("ScrollFrame", "OnePanel_OutfitsScroll", outfitsView, "UIPanelScrollFrameTemplate")
    outfitsScroll:SetPoint("TOPLEFT", outfitsView, "TOPLEFT", 0, -32)
    outfitsScroll:SetPoint("BOTTOMRIGHT", outfitsView, "BOTTOMRIGHT", 0, 0)
    outfitsScroll:EnableMouseWheel(true)
    outfitsScroll:SetScript("OnMouseWheel", function(self, delta)
        local cur = self:GetVerticalScroll()
        local maxScroll = self:GetVerticalScrollRange()
        local step = 28
        self:SetVerticalScroll(math.max(0, math.min(maxScroll, cur - (delta * step))))
    end)
    
    -- Custom ScrollBar Position
    local outfitsSbName = outfitsScroll:GetName() .. "ScrollBar"
    local outfitsScrollBar = _G[outfitsSbName]
    if outfitsScrollBar then
        outfitsScrollBar:ClearAllPoints()
        outfitsScrollBar:SetPoint("TOPRIGHT", outfitsView, "TOPRIGHT", -4, -48)
        outfitsScrollBar:SetPoint("BOTTOMRIGHT", outfitsView, "BOTTOMRIGHT", -4, 18)
    end
    
    local outfitsContent = CreateFrame("Frame", "OnePanel_OutfitsContent", outfitsScroll)
    outfitsContent:SetSize(176, 400)
    outfitsScroll:SetScrollChild(outfitsContent)
    
    local ShowNewSetDialog = nil

    -- Dynamic Set List Renderer
    local function RefreshEquipmentSets()
        if not outfitsContent.rows then outfitsContent.rows = {} end
        for _, r in ipairs(outfitsContent.rows) do r:Hide() end
        
        local setIDs = C_EquipmentSet and C_EquipmentSet.GetEquipmentSetIDs and C_EquipmentSet.GetEquipmentSetIDs() or {}
        local yOffset = -2
        
        if #setIDs == 0 then
            local emptyMsg = outfitsContent.emptyMsg
            if not emptyMsg then
                emptyMsg = outfitsContent:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
                emptyMsg:SetPoint("TOP", outfitsContent, "TOP", 0, -30)
                emptyMsg:SetText("|cffaaaaaaNo equipment sets saved.\nClick '+ New Set' above.|r")
                outfitsContent.emptyMsg = emptyMsg
            end
            emptyMsg:Show()
            outfitsContent:SetHeight(100)
            return
        elseif outfitsContent.emptyMsg then
            outfitsContent.emptyMsg:Hide()
        end
        
        for idx, setID in ipairs(setIDs) do
            local name, iconFileID, _, isEquipped, numItems, numEquipped, numInInventory, numLost = C_EquipmentSet.GetEquipmentSetInfo(setID)
            
            local row = outfitsContent.rows[idx]
            if not row then
                row = CreateFrame("Frame", nil, outfitsContent)
                row:SetSize(174, 46)
                
                local rowBg = row:CreateTexture(nil, "BACKGROUND")
                rowBg:SetAllPoints(row)
                row.Bg = rowBg
                
                -- Set Icon Button (Interactive)
                local iconBtn = CreateFrame("Button", nil, row)
                iconBtn:SetSize(32, 32)
                iconBtn:SetPoint("LEFT", row, "LEFT", 4, 0)
                
                local icon = iconBtn:CreateTexture(nil, "ARTWORK")
                icon:SetAllPoints(iconBtn)
                icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
                row.Icon = icon
                
                local iconHl = iconBtn:CreateTexture(nil, "HIGHLIGHT")
                iconHl:SetTexture("Interface\\Buttons\\ButtonHilight-Square")
                iconHl:SetBlendMode("ADD")
                iconHl:SetAllPoints(iconBtn)
                row.IconBtn = iconBtn
                
                -- Set Name
                local nameText = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
                nameText:SetPoint("TOPLEFT", iconBtn, "TOPRIGHT", 6, 2)
                nameText:SetWidth(76)
                nameText:SetJustifyH("LEFT")
                row.NameText = nameText
                
                -- Status / Equipped Text
                local statusText = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
                statusText:SetPoint("TOPLEFT", nameText, "BOTTOMLEFT", 0, -2)
                statusText:SetWidth(76)
                statusText:SetJustifyH("LEFT")
                row.StatusText = statusText
                
                -- Equip Button
                local equipBtn = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
                equipBtn:SetSize(50, 18)
                equipBtn:SetPoint("RIGHT", row, "RIGHT", -4, 9)
                equipBtn:SetText("Equip")
                row.EquipBtn = equipBtn
                
                -- Edit Button
                local editBtn = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
                editBtn:SetSize(25, 16)
                editBtn:SetPoint("RIGHT", row, "RIGHT", -29, -11)
                editBtn:SetText("Edit")
                row.EditBtn = editBtn
                
                -- Delete Button
                local deleteBtn = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
                deleteBtn:SetSize(24, 16)
                deleteBtn:SetPoint("RIGHT", row, "RIGHT", -4, -11)
                deleteBtn:SetText("Del")
                row.DeleteBtn = deleteBtn
                
                outfitsContent.rows[idx] = row
            end
            
            -- Alternating Row Colors
            if idx % 2 == 1 then
                row.Bg:SetColorTexture(0.12, 0.12, 0.12, 0.5)
            else
                row.Bg:SetColorTexture(0.06, 0.06, 0.06, 0.5)
            end
            
            row:ClearAllPoints()
            row:SetPoint("TOPLEFT", outfitsContent, "TOPLEFT", 1, yOffset)
            
            row.Icon:SetTexture(iconFileID or "Interface\\Icons\\INV_Misc_QuestionMark")
            row.NameText:SetText(name or ("Set " .. setID))
            
            if isEquipped then
                row.StatusText:SetText("|cff00ff00Equipped|r")
                row.EquipBtn:Disable()
            else
                local total = numItems or 16
                local eq = numEquipped or 0
                if numLost and numLost > 0 then
                    row.StatusText:SetText(string.format("|cffff4444%d Lost|r", numLost))
                else
                    row.StatusText:SetText(string.format("%d/%d Items", eq, total))
                end
                row.EquipBtn:Enable()
            end
            
            row.IconBtn:SetScript("OnEnter", function(self)
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:SetText("Click to edit icon & name", 1, 1, 1)
                GameTooltip:Show()
            end)
            row.IconBtn:SetScript("OnLeave", function() GameTooltip_Hide() end)
            
            row.IconBtn:SetScript("OnClick", function()
                if ShowNewSetDialog then ShowNewSetDialog(name, iconFileID, setID) end
            end)
            
            row.EditBtn:SetScript("OnClick", function()
                if ShowNewSetDialog then ShowNewSetDialog(name, iconFileID, setID) end
            end)
            
            row.EquipBtn:SetScript("OnClick", function()
                if C_EquipmentSet and C_EquipmentSet.UseEquipmentSet then
                    C_EquipmentSet.UseEquipmentSet(setID)
                end
            end)
            
            row.DeleteBtn:SetScript("OnClick", function()
                if C_EquipmentSet and C_EquipmentSet.DeleteEquipmentSet then
                    StaticPopup_Show("ONEPANEL_CONFIRM_DELETE_SET", name, nil, setID)
                end
            end)
            
            row:Show()
            yOffset = yOffset - 48
        end
        
        outfitsContent:SetHeight(math.abs(yOffset) + 30)
    end
    outfitsView.Refresh = RefreshEquipmentSets
    
    -- Register Delete Set Confirmation Popup
    if not StaticPopupDialogs["ONEPANEL_CONFIRM_DELETE_SET"] then
        StaticPopupDialogs["ONEPANEL_CONFIRM_DELETE_SET"] = {
            text = "Delete equipment set '%s'?",
            button1 = "Delete",
            button2 = "Cancel",
            OnAccept = function(self, data)
                if data and C_EquipmentSet and C_EquipmentSet.DeleteEquipmentSet then
                    C_EquipmentSet.DeleteEquipmentSet(data)
                end
            end,
            timeout = 0,
            whileDead = true,
            hideOnEscape = true,
            preferredIndex = 3,
        }
    end
    
    local function GetDefaultSetIcon()
        local prioritySlots = { 16, 17, 18, 1, 3, 5, 7, 10, 6, 8, 2, 15, 4, 19, 9, 11, 12, 13, 14 }
        for _, slot in ipairs(prioritySlots) do
            local tex = GetInventoryItemTexture("player", slot)
            if tex then
                return tex
            end
        end
        return 134400
    end

    local function GetEquippedSetName()
        local setIDs = C_EquipmentSet and C_EquipmentSet.GetEquipmentSetIDs and C_EquipmentSet.GetEquipmentSetIDs() or {}
        for _, setID in ipairs(setIDs) do
            local name, _, _, isEquipped = C_EquipmentSet.GetEquipmentSetInfo(setID)
            if isEquipped then
                return name
            end
        end
        return nil
    end

    local cachedIconList = nil
    local function GetAvailableIcons()
        if cachedIconList then return cachedIconList end
        cachedIconList = {}
        local seen = {}
        
        local prioritySlots = { 16, 17, 18, 1, 3, 5, 7, 10, 6, 8, 2, 15, 4, 19, 9, 11, 12, 13, 14 }
        for _, slot in ipairs(prioritySlots) do
            local tex = GetInventoryItemTexture("player", slot)
            if tex and not seen[tex] then
                seen[tex] = true
                table.insert(cachedIconList, tex)
            end
        end
        
        local temp = {}
        if GetMacroIcons then pcall(GetMacroIcons, temp) end
        if GetMacroItemIcons then pcall(GetMacroItemIcons, temp) end
        
        for _, id in ipairs(temp) do
            if not seen[id] then
                seen[id] = true
                table.insert(cachedIconList, id)
                if #cachedIconList >= 350 then break end
            end
        end
        
        if #cachedIconList == 0 then
            cachedIconList = { 134400, 132089, 132090, 132091, 132092, 132093 }
        end
        return cachedIconList
    end

    -- New / Edit Equipment Set Modal Dialog (With Embedded Icon Picker Grid)
    ShowNewSetDialog = function(defaultName, defaultIconID, existingSetID)
        local hostFrame = (OnePanel and OnePanel.frame) or _G["OnePanelFrame"] or UIParent
        if not _G["OnePanel_NewSetDialog"] then
            local dlg = CreateFrame("Frame", "OnePanel_NewSetDialog", hostFrame)
            dlg:SetSize(360, 340)
            dlg:SetFrameStrata("DIALOG")
            dlg:SetFrameLevel(1000)
            dlg:SetPoint("TOPRIGHT", hostFrame, "TOPLEFT", -4, 0)
            
            if Utils and Utils.FrameHelper then
                Utils.FrameHelper:ApplyBackdrop(dlg,
                    "Interface\\FrameGeneral\\UI-Background-Marble",
                    "Interface\\Tooltips\\UI-Tooltip-Border",
                    16, 16, { left = 4, right = 4, top = 4, bottom = 4 }
                )
            end
            
            local titleBg = dlg:CreateTexture(nil, "ARTWORK")
            titleBg:SetSize(352, 24)
            titleBg:SetPoint("TOP", dlg, "TOP", 0, -4)
            titleBg:SetColorTexture(0.1, 0.1, 0.1, 0.6)
            
            local dlgTitle = dlg:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
            dlgTitle:SetPoint("CENTER", titleBg, "CENTER", 0, 0)
            dlg.Title = dlgTitle
            
            -- Set Name Input Label & EditBox
            local inputLabel = dlg:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            inputLabel:SetPoint("TOPLEFT", dlg, "TOPLEFT", 16, -34)
            inputLabel:SetText("Enter Set Name:")
            
            local input = CreateFrame("EditBox", "OnePanel_NewSetInput", dlg, "InputBoxTemplate")
            input:SetSize(210, 22)
            input:SetPoint("TOPLEFT", inputLabel, "BOTTOMLEFT", 0, -4)
            input:SetAutoFocus(true)
            dlg.Input = input
            
            -- Currently Selected Icon Preview (Top Right)
            local selLabel = dlg:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
            selLabel:SetPoint("TOPRIGHT", dlg, "TOPRIGHT", -16, -34)
            selLabel:SetText("Selected Icon")
            
            local iconPreview = dlg:CreateTexture(nil, "ARTWORK")
            iconPreview:SetSize(32, 32)
            iconPreview:SetPoint("TOPRIGHT", selLabel, "BOTTOMRIGHT", 0, -2)
            iconPreview:SetTexCoord(0.08, 0.92, 0.08, 0.92)
            dlg.IconPreview = iconPreview
            
            local iconBorder = dlg:CreateTexture(nil, "OVERLAY")
            iconBorder:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
            iconBorder:SetBlendMode("ADD")
            iconBorder:SetSize(32, 32)
            iconBorder:SetPoint("CENTER", iconPreview, "CENTER", 0, 0)
            
            -- Icon Picker Grid Header
            local gridLabel = dlg:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            gridLabel:SetPoint("TOPLEFT", input, "BOTTOMLEFT", 0, -12)
            gridLabel:SetText("Choose an Icon:")
            
            -- Icon Scroll Frame
            local scrollFrame = CreateFrame("ScrollFrame", "OnePanel_NewSetIconScroll", dlg, "UIPanelScrollFrameTemplate")
            scrollFrame:SetPoint("TOPLEFT", gridLabel, "BOTTOMLEFT", 0, -6)
            scrollFrame:SetPoint("BOTTOMRIGHT", dlg, "BOTTOMRIGHT", -32, 42)
            
            local gridContent = CreateFrame("Frame", "OnePanel_NewSetIconGridContent", scrollFrame)
            gridContent:SetSize(300, 400)
            scrollFrame:SetScrollChild(gridContent)
            dlg.GridContent = gridContent
            
            local function PerformSave()
                local setName = (input:GetText() or ""):match("^%s*(.-)%s*$")
                if setName and setName ~= "" then
                    local iconID = dlg.selectedIconID or GetDefaultSetIcon()
                    if dlg.existingSetID then
                        if C_EquipmentSet and C_EquipmentSet.ModifyEquipmentSet then
                            pcall(C_EquipmentSet.ModifyEquipmentSet, dlg.existingSetID, setName, iconID)
                        end
                        if C_EquipmentSet and C_EquipmentSet.SaveEquipmentSet then
                            pcall(C_EquipmentSet.SaveEquipmentSet, dlg.existingSetID, iconID)
                        end
                    else
                        if C_EquipmentSet and C_EquipmentSet.CreateEquipmentSet then
                            C_EquipmentSet.CreateEquipmentSet(setName, iconID)
                        end
                    end
                    if outfitsView and outfitsView.Refresh then outfitsView:Refresh() end
                end
                dlg:Hide()
            end
            
            input:SetScript("OnEnterPressed", PerformSave)
            input:SetScript("OnEscapePressed", function() dlg:Hide() end)
            
            local saveBtn = CreateFrame("Button", "OnePanel_NewSetSaveBtn", dlg, "UIPanelButtonTemplate")
            saveBtn:SetSize(110, 22)
            saveBtn:SetPoint("BOTTOMLEFT", dlg, "BOTTOMLEFT", 30, 12)
            dlg.SaveBtn = saveBtn
            saveBtn:SetScript("OnClick", PerformSave)
            
            local cancelBtn = CreateFrame("Button", "OnePanel_NewSetCancelBtn", dlg, "UIPanelButtonTemplate")
            cancelBtn:SetSize(110, 22)
            cancelBtn:SetPoint("BOTTOMRIGHT", dlg, "BOTTOMRIGHT", -30, 12)
            cancelBtn:SetText("Cancel")
            cancelBtn:SetScript("OnClick", function()
                dlg:Hide()
            end)
        end
        
        -- Hide old template button if it existed from previous session
        if _G["OnePanel_NewSetDialogButton"] then
            _G["OnePanel_NewSetDialogButton"]:Hide()
        end
        
        local dlg = _G["OnePanel_NewSetDialog"]
        dlg:SetParent(hostFrame)
        dlg:ClearAllPoints()
        dlg:SetPoint("TOPRIGHT", hostFrame, "TOPLEFT", -4, 0)
        
        dlg.existingSetID = existingSetID
        dlg.selectedIconID = defaultIconID or GetDefaultSetIcon()
        dlg.IconPreview:SetTexture(dlg.selectedIconID)
        dlg.Input:SetText(defaultName or "")
        dlg.Input:HighlightText()
        
        if existingSetID then
            dlg.Title:SetText("Edit Equipment Set")
            dlg.SaveBtn:SetText("Save Changes")
        else
            dlg.Title:SetText("Save Equipment Set")
            dlg.SaveBtn:SetText("Save Set")
        end
        
        -- Render Embedded Icon Grid
        local icons = GetAvailableIcons()
        local content = dlg.GridContent
        if not content.buttons then content.buttons = {} end
        for _, btn in ipairs(content.buttons) do btn:Hide() end
        
        local btnSize = 34
        local cols = 8
        local spacing = 4
        local startX = 2
        local startY = -2
        
        for idx, iconID in ipairs(icons) do
            local btn = content.buttons[idx]
            if not btn then
                btn = CreateFrame("Button", nil, content)
                btn:SetSize(btnSize, btnSize)
                
                local tex = btn:CreateTexture(nil, "ARTWORK")
                tex:SetAllPoints(btn)
                tex:SetTexCoord(0.08, 0.92, 0.08, 0.92)
                btn.Tex = tex
                
                local selBdr = btn:CreateTexture(nil, "OVERLAY")
                selBdr:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
                selBdr:SetBlendMode("ADD")
                selBdr:SetAllPoints(btn)
                selBdr:Hide()
                btn.SelectedBorder = selBdr
                
                local hl = btn:CreateTexture(nil, "HIGHLIGHT")
                hl:SetTexture("Interface\\Buttons\\ButtonHilight-Square")
                hl:SetBlendMode("ADD")
                hl:SetAllPoints(btn)
                
                content.buttons[idx] = btn
            end
            
            local col = (idx - 1) % cols
            local row = math.floor((idx - 1) / cols)
            btn:ClearAllPoints()
            btn:SetPoint("TOPLEFT", content, "TOPLEFT", startX + col * (btnSize + spacing), startY - row * (btnSize + spacing))
            
            btn.Tex:SetTexture(iconID)
            if iconID == dlg.selectedIconID then
                btn.SelectedBorder:Show()
            else
                btn.SelectedBorder:Hide()
            end
            
            btn:SetScript("OnClick", function()
                dlg.selectedIconID = iconID
                dlg.IconPreview:SetTexture(iconID)
                for _, b in ipairs(content.buttons) do
                    if b.Tex:GetTexture() == iconID then
                        b.SelectedBorder:Show()
                    else
                        b.SelectedBorder:Hide()
                    end
                end
            end)
            btn:Show()
        end
        
        local totalRows = math.ceil(#icons / cols)
        content:SetHeight(totalRows * (btnSize + spacing) + 12)
        dlg:Show()
    end
    
    newSetBtn:SetScript("OnClick", function()
        ShowNewSetDialog("")
    end)
    saveCurrentBtn:SetScript("OnClick", function()
        local name = GetEquippedSetName()
        ShowNewSetDialog(name or "")
    end)
    
    -- Register Equipment Set Events for Auto Refresh
    local eqEventFrame = CreateFrame("Frame", "OnePanel_EquipmentSet_EventFrame", outfitsView)
    eqEventFrame:RegisterEvent("EQUIPMENT_SETS_CHANGED")
    eqEventFrame:RegisterEvent("EQUIPMENT_SWAP_FINISHED")
    eqEventFrame:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
    eqEventFrame:SetScript("OnEvent", function()
        if outfitsView and outfitsView.Refresh then
            pcall(outfitsView.Refresh)
        end
    end)
    
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

        local showFlyout = (targetTabId == "outfits")
        if container.slots then
            for _, slotBtn in pairs(container.slots) do
                if slotBtn.FlyoutArrow then
                    slotBtn.FlyoutArrow:SetShown(showFlyout)
                end
            end
        end
        if not showFlyout and _G["OnePanel_EquipmentFlyout"] then
            _G["OnePanel_EquipmentFlyout"]:Hide()
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
            if self.RefreshPlayerModel then self:RefreshPlayerModel() end
        elseif event == "UNIT_MODEL_CHANGED" or event == "UNIT_PORTRAIT_UPDATE" or event == "UPDATE_SHAPESHIFT_FORM" or event == "UPDATE_SHAPESHIFT_FORMS" then
            if arg1 == "player" or arg1 == nil then
                if self.RefreshPlayerModel then self:RefreshPlayerModel() end
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
    container:RegisterEvent("UPDATE_SHAPESHIFT_FORM")
    container:RegisterEvent("UPDATE_SHAPESHIFT_FORMS")
    container:RegisterEvent("ITEM_LOCK_CHANGED")
    container:HookScript("OnHide", function()
        if _G["OnePanel_NewSetDialog"] then
            _G["OnePanel_NewSetDialog"]:Hide()
        end
        if _G["OnePanel_EquipmentFlyout"] then
            _G["OnePanel_EquipmentFlyout"]:Hide()
        end
        if container.slots then
            for _, slotBtn in pairs(container.slots) do
                if slotBtn.FlyoutArrow then
                    slotBtn.FlyoutArrow:Hide()
                end
            end
        end
    end)
    container:HookScript("OnShow", function()
        if subPanel and subPanel.activeTab then
            SwitchSubTab(subPanel.activeTab)
        end
    end)
    
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
            if container and container.RefreshPlayerModel then
                container:RefreshPlayerModel()
            elseif container and container.Model then
                container.Model:SetUnit("player")
            end
            if container and container.UpdateEquipment then
                container:UpdateEquipment()
            end
            if container and container.UpdateRaceBackgroundArt then
                container:UpdateRaceBackgroundArt()
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
            if _G["OnePanel_NewSetDialog"] then
                _G["OnePanel_NewSetDialog"]:Hide()
            end
            if _G["OnePanel_EquipmentFlyout"] then
                _G["OnePanel_EquipmentFlyout"]:Hide()
            end
        end
    })
end

local eventFrame = CreateFrame("Frame", "OnePanel_Character_EventFrame")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:SetScript("OnEvent", function(self, event)
    RegisterPlugin()
    self:UnregisterEvent("PLAYER_LOGIN")
end)
