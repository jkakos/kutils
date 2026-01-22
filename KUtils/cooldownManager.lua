local _, addon = ...
-----------------------------------------------------------------------
-- ICONS
-----------------------------------------------------------------------
-- Decide whether to show a viewer given the viewer and combat state
local function ShouldShowIcon(viewer)
    if addon.DISPLAY_CDM_OUTSIDE_COMBAT then
        return true
    elseif addon.inCombat then
        return true
    else
        return viewer == BuffIconCooldownViewer
    end
end

local function EnforceIconVisibility(button, viewer)
    local show = ShouldShowIcon(viewer)

    if show then
        button:Show()
    else
        button:Hide()
    end
end

-- Modify the cooldown manager viewers that display icons. This will
-- reposition and resize icons on a row-by-row basis. A border will
-- also be added to each icon for a cleaner look.
function addon:LayoutIcons(viewer, buttons)
    local buttons = buttons or viewer:GetItemFrames()
    if not buttons then return end

    local config
    if viewer == EssentialCooldownViewer then
        config = addon.essentialConfig
    elseif viewer == UtilityCooldownViewer then
        config = addon.utilityConfig
    elseif viewer == BuffIconCooldownViewer then
        config = addon.buffIconConfig
    else
        return  -- unknown viewer
    end

    viewer:SetPointOverride("TOP", UIParent, "TOP", addon.baseUIPosition.x, addon.baseUIPosition.y)

    for i, button in ipairs(buttons) do
        button:SetScale(1)
        if viewer == BuffIconCooldownViewer then
            button:SetTimerShown(false)
        end
    end

    local activeButtons = buttons

    -- Reposition buff icons when they're active so they become centered by default
    if (viewer == BuffIconCooldownViewer) then
       activeButtons = {}
       for _, button in ipairs(buttons) do
           if button:IsShown() then
               table.insert(activeButtons, button)
           end
       end
    end

    local rowLimit        = config.rowLimit
    local iconSize        = config.iconSize
    local spacing         = config.spacing
    local xOffset         = config.xOffset
    local yOffset         = config.yOffset
    local borderThickness = config.borderThickness

    local viewerWidth = viewer:GetWidth()
    local numIcons = #activeButtons
    local totalAllowedIcons, cumulRowLimit = addon:GetMaxIcons(rowLimit)
    local iconsPerRow = addon:GetIconsPerRow(numIcons, rowLimit, totalAllowedIcons, cumulRowLimit)
    local xLeft = addon:GetRowXLeft(iconsPerRow, iconSize, spacing, viewerWidth)
    local rowIdx = 1


    for i, button in ipairs(activeButtons) do
        -- Hide any icons beyond the defined limits
        if i > totalAllowedIcons then
            button:Hide()
            button:SetParent(nil)  -- prevent the icon from displaying again
        else
            button:SetParent(viewer)  -- ensure the icon has a parent because of frame recycling

            -- Update the row index
            if i > (cumulRowLimit[rowIdx] or 0) then
                rowIdx = rowIdx + 1
            end

            -- Update icon position
            local idxInRow = (i-1) - (cumulRowLimit[rowIdx-1] or 0)
            local xNew = addon:GetRowX(xLeft[rowIdx], idxInRow, iconSize[rowIdx], spacing) + xOffset
            local yNew = addon:GetRowY(rowIdx, iconSize, spacing) + yOffset

            button:ClearAllPoints()
            button:SetPoint("TOPLEFT", viewer, "TOPLEFT", xNew, yNew)
            button:SetSize(iconSize[rowIdx], iconSize[rowIdx])

            -- -- Show or hide icons
            if ShouldShowIcon(viewer) then
                button:Show()
            else
                button:Hide()
            end

            -- Add a black border to the icons
            if not button._innerBorder then
                addon:AddInnerBorder(button, borderThickness, 0, 0, 0, 1)
            end

            -- Add a black background to hide gaps between icon corner and border
            if not button._background then
                addon:AddIconBackground(button, 0, 0, 0, 1)
            end
        end
    end
end

-----------------------------------------------------------------------
-- BUFF BARS
-----------------------------------------------------------------------
-- Position buff bars
function addon:LayoutBuffBars(viewer)
    local config    = addon.buffBarConfig
    local yOffset   = addon:GetResourceBarOffset(nil, addon.currentSpec)
    local barWidth  = config.barWidth
    local barHeight = config.barHeight
    local spacing   = config.spacing
    local maxBars   = config.maxBars

    viewer:ClearAllPoints()
    viewer:SetPointOverride("BOTTOM", UIParent, "TOP", addon.baseUIPosition.x, addon.baseUIPosition.y)

    -- Initial style pass and setting the bar order
    for _, entry in ipairs({viewer:GetChildren()}) do
        if entry:IsShown() and addon.buffBarOrder[entry] == nil then
            local _, _, _, _, yInitial = entry:GetPoint()
            addon.buffBarOrder[entry] = yInitial or -500
            entry:SetSize(barWidth, 100)  -- keep the edit mode box large enough to see
        end
    end

    -- Collect active bars
    local active = {}
    for _, entry in ipairs({viewer:GetChildren()}) do
        if entry.Bar then
            addon:SetBuffBarPosition(entry)
        end

        if entry:IsShown() then
            table.insert(active, entry)
        end
    end

    -- Sort active according to the cooldown manager order
    table.sort(active, function(a, b)
        local ya = addon.buffBarOrder[a] or -500
        local yb = addon.buffBarOrder[b] or -500
       return ya > yb
    end)

    -- Show and position the allowed number of bars
    local y = yOffset
    for i, entry in ipairs(active) do
        if i <= maxBars then
            entry:Show()
            entry:ClearAllPoints()
            entry:SetPoint("BOTTOM", viewer, "BOTTOM", 0, y)
            y = y + barHeight + spacing -- + addon.buffBarConfig.yOffset
        else
            entry:Hide()
        end
    end
end

function addon:SetBuffBarPosition(entry)
    local bar = entry.Bar
    if not bar then return end

    local config    = addon.buffBarConfig
    local barWidth  = config.barWidth
    local barHeight = config.barHeight

    bar:ClearAllPoints()
    bar:SetPoint("BOTTOM", entry, "BOTTOM", 0, 0)
    bar:SetSize(barWidth, barHeight)
end

-- Apply visual adjustments to buff bars
function addon:StyleBuffBar(entry)
    if entry._addonStyled then return end
    entry._addonStyled = true

    local bar = entry.Bar
    if not bar then return end

    local config          = addon.buffBarConfig
    local barWidth        = config.barWidth
    local barHeight       = config.barHeight
    local spacing         = config.spacing
    local borderThickness = config.borderThickness
    local fontSize        = config.fontSize
    local newBarTexture   = config.barTexture

    addon:SetBuffBarPosition(entry)

    if bar._borderFrame then
        bar._borderFrame:SetAllPoints(bar)  -- keeps the border aligned
    end
    local bgTexture, sparkTexture, nameText, timerText, barTexture = bar:GetRegions()

    -- Background texture
    if bgTexture and bgTexture:GetObjectType() == "Texture" then
        local w, h = barTexture:GetSize()
        bgTexture:SetVertexColor(0.2, 0.2, 0.2, 1)
        bgTexture:SetTexture("Interface\\Tooltips\\UI-Tooltip-Background")
        bgTexture:ClearAllPoints()
        bgTexture:SetPoint("CENTER", barTexture:GetParent(), "CENTER")  -- parent of barTexture is the bar frame
        bgTexture:SetSize(w, h)
        addon:AddBarInnerBorder(bgTexture, borderThickness, 0, 0, 0, 1)
    end

    -- Texture 2: Spark
    if sparkTexture and sparkTexture:GetObjectType() == "Texture" then
        -- sparkTexture:SetVertexColor(1, 1, 1, 1)
        sparkTexture:SetAlpha(0)
    end

    -- Spell name text
    if nameText and nameText:GetObjectType() == "FontString" then
        nameText:SetFont("Fonts\\FRIZQT__.TTF", fontSize) --, "THINOUTLINE")
        addon:AddFakeTextOutline(nameText, 1)
        -- nameText:SetShadowColor(0, 0, 0, 1)
        -- nameText:SetShadowOffset(1, -1)
        nameText:SetTextColor(1, 1, 1, 1)  -- blue
        nameText:ClearAllPoints()
        nameText:SetPoint("CENTER", 0, 1)
    end

    -- Duration timer text
    if timerText and timerText:GetObjectType() == "FontString" then
        timerText:SetAlpha(0)
        -- timerText:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
        -- timerText:SetTextColor(1, 1, 1, 1)  -- red
        -- timerText:ClearAllPoints()
        -- timerText:SetPoint("RIGHT", -2, 0)
    end

    -- Bar texture
    if barTexture and barTexture:GetObjectType() == "Texture" then
        barTexture:SetTexture(newBarTexture)
        addon:ColorBarTexture(barTexture)
    end
end

-- Apply coloring to buff bars (updated for specs)
function addon:ColorBarTexture(barTexture, r, g, b, a)
    if not barTexture then return end

    if r and g and b then
        a = a or 1
        barTexture:SetVertexColor(r, g, b, a)
    else
        barTexture:SetVertexColor(addon:GetSpecColor(nil, addon.currentSpec))
    end
end

-----------------------------------------------------------------------
-- CAST BAR
-----------------------------------------------------------------------
-- Apply visual adjustments to the cast bar
function addon:StyleCastBar()
    local bar = PlayerCastingBarFrame
    if not bar then return end

    local config          = addon.castBarConfig
    local barWidth        = config.barWidth
    local barHeight       = config.barHeight
    local borderThickness = config.borderThickness
    local fontSize        = config.fontSize
    local textLength      = config.textLength
    local barTexture      = config.barTexture

    -- Only needs to run once
    if not bar._addonStyled then
        bar._addonStyled = true
        if bar.Border then bar.Border:Hide() end

        addon:AddIconBackground(bar, 0.086, 0.086, 0.086, 1)
        bar.Background:Hide()

        addon:AddBarInnerBorder(bar, borderThickness, 0, 0, 0, 1, true)

        if not bar.TimeText then
            bar.TimeText = bar:CreateFontString(nil, "OVERLAY")
            bar.TimeText:SetFontObject(GameFontHighlightSmall)
            bar.TimeText:SetPoint("RIGHT", bar, 0, 0)
            bar.TimeText:SetJustifyH("LEFT")
            bar.TimeText:SetWidth(30)
            bar.TimeText:SetFont("Fonts\\FRIZQT__.TTF", fontSize) --, "THINOUTLINE")
        end
    end

    -- Remove Blizzard art
    if bar.Icon then bar.Icon:Hide() end
    bar.InterruptGlow:Hide()  -- hide red spell interrupt glow
    bar.TextBorder:Hide()  -- hide the lower texture that normally shows the cast name

    -- Size
    bar:SetSize(barWidth, barHeight)

    -- Texture
    local tex = bar:GetStatusBarTexture()
        if tex and tex:GetTexture() ~= addon.castBarConfig.barTexture then
            tex:SetTexture(addon.castBarConfig.barTexture)

            if addon.castBarInterrupted then
                addon:ColorBarTexture(tex, 0.7, 0, 0, 1)  -- color red if spell interrupted
            else
                addon:ColorBarTexture(tex)
            end
        end

    -- Spell name (left)
    bar.Text:ClearAllPoints()
    bar.Text:SetPoint("LEFT", bar, 4, 0)
    bar.Text:SetJustifyH("LEFT")
    bar.Text:SetFont("Fonts\\FRIZQT__.TTF", fontSize) --, "THINOUTLINE")
end

function addon:PositionCastBar()
    if InCombatLockdown() then return end
    local xOffset = addon.castBarConfig.xOffset
    local yOffset = addon.castBarConfig.yOffset

    PlayerCastingBarFrame:ClearAllPoints()
    PlayerCastingBarFrame:SetPoint("TOP", UIParent, "TOP", addon.baseUIPosition.x + xOffset, addon.baseUIPosition.y + yOffset)
end

-----------------------------------------------------------------------
-- HOOKS
-----------------------------------------------------------------------
-- Decide when to show or hide icons
function addon:HookButtonVisibility(button, viewer)
    if button._addonVisHooked then return end
    button._addonVisHooked = true

    button:HookScript("OnShow", function(self)
        EnforceIconVisibility(self, viewer)
    end)
end

-- Change icon swipe colors when active or on cooldown
function addon:HookIconCooldownColor(button)
    if button._addonCooldownColorHooked then return end
    button._addonCooldownColorHooked = true

    -- Do not desaturate when on cooldown
    local inHook = false  -- avoid infinite recursion
    hooksecurefunc(button.Icon, "SetDesaturated", function(self, desat)
        if inHook then return end
        inHook = true
        self:SetDesaturated(false)
        inHook = false
    end)

    -- Color of swipe texture when aura is active
    hooksecurefunc(button, "RefreshActive", function(self)
        local cd = self.Cooldown
        if not cd then return end

        if self.auraInstanceID then
            -- cd:SetSwipeColor(unpack(addon.AURA_ACTIVE_SWIPE_COLOR))
            local r, g, b, a = addon:GetSpecColor()
            cd:SetSwipeColor(r, g, b, 0.7)
            cd:SetDrawEdge(true)
            cd:SetReverse(true)
        else
            cd:SetSwipeColor(unpack(addon.BUTTON_COOLDOWN_SWIPE_COLOR))
            -- cd:SetDrawEdge(true)
            cd:SetReverse(false)
            -- cd:SetHideCountdownNumbers(true)
        end
    end)
end

-- Set font of cooldown timers
function addon:AppylCooldownTimerFont(button)
    if not button or not button.Cooldown then return end
    if button._addonTimerFontHooked then return end
    button._addonTimerFontHooked = true

    local regions = {button.Cooldown:GetRegions()}

    for _, region in ipairs(regions) do
        if region:IsObjectType("FontString") then
            -- region:ClearAllPoints()
            -- region:SetPoint("BOTTOM", button.Cooldown, "CENTER", 0, 0)
            region:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
            break
        end
    end
end

-- Set font of charges for icons with charges
function addon:ApplyChargeFont(button)
    if button._addonChargeFontHooked then return end
    button._addonChargeFontHooked = true

    if button and button.ChargeCount and button.ChargeCount.Current then
        local chargeText = button.ChargeCount.Current
        chargeText:ClearAllPoints()
        chargeText:SetPoint("BOTTOMRIGHT", button.ChargeCount, "BOTTOMRIGHT", 1, 0)
        chargeText:SetFont("Fonts\\FRIZQT__.TTF", 14, "OUTLINE")
    end
end

-- Set font of number of applications for icons that can stack
function addon:ApplyApplicationsFont(button)
    if button._addonApplicationsHooked then return end
    button._addonApplicationsHooked = true

    if button and button.Applications and button.Applications.Applications then
        local stacks = button.Applications.Applications
        stacks:ClearAllPoints()
        stacks:SetPoint("CENTER", button.Applications, "CENTER", 0, 0)
        stacks:SetFont("Fonts\\FRIZQT__.TTF", 18, "OUTLINE")
    end
end

-- Make sure the button glow matches the icon size
function addon:SetButtonGlowSize(button)
    if not button then return end

    local alert = button.SpellActivationAlert
    if not alert then return end

    local width, height = button:GetSize()
    local multiplier = 1.4
    alert:SetSize(width * multiplier, height * multiplier)
end

-- Hide button glows out of combat
function addon:HideButtonGlow(button)
    if not button then return end

    local alert = button.SpellActivationAlert
    if alert then
        if not addon.inCombat then alert:Hide() end
    end
end

-- Essential Icons
function addon:HookEssentialCooldownViewer()
    hooksecurefunc(EssentialCooldownViewer, "RefreshLayout", function(self)
        addon:LayoutIcons(self)

        local buttons = self:GetItemFrames()
        if buttons then
            for _, button in ipairs(buttons) do
                addon:HookIconCooldownColor(button, viewer)
                addon:HookButtonVisibility(button, viewer)
                addon:ApplyChargeFont(button)
                addon:AppylCooldownTimerFont(button)
                addon:SetButtonGlowSize(button)
                addon:HideButtonGlow(button)
            end
        end
    end)
end

-- Utility Icons
function addon:HookUtilityCooldownViewer()
    local buttons = UtilityCooldownViewer:GetItemFrames()
    if not buttons then return end

    hooksecurefunc(UtilityCooldownViewer, "RefreshLayout", function(self)
        addon:LayoutIcons(self)

        local buttons = self:GetItemFrames()
        if buttons then
            for _, button in ipairs(buttons) do
                addon:HookIconCooldownColor(button)
                addon:HookButtonVisibility(button, viewer)
                addon:ApplyChargeFont(button)
            end
        end
    end)
end

-- Buff Icons
function addon:HookBuffIconCooldownViewer()
    local viewer = BuffIconCooldownViewer
    if not viewer then return end

    hooksecurefunc(viewer, "RefreshLayout", function(self)
        local buttons = self:GetItemFrames()
        if not buttons then return end

        for _, button in ipairs(buttons) do
            if not button._addonHooked then
                button._addonHooked = true
                button:HookScript("OnShow", function() addon:LayoutIcons(self) end)
                button:HookScript("OnHide", function() addon:LayoutIcons(self) end)
                -- addon:HookIconCooldownColor(button)
                addon:ApplyChargeFont(button)
                addon:ApplyApplicationsFont(button)
            end
        end

        addon:LayoutIcons(self)
    end)
end

-- Buff Bars
function addon:HookBuffBarCooldownViewer()
    hooksecurefunc(BuffBarCooldownViewer, "RefreshLayout", function(self)
        addon:LayoutBuffBars(self)

        for _, entry in ipairs({self:GetChildren()}) do
            if not entry._addonHooked then
                entry._addonHooked = true
                entry:HookScript("OnShow", function() addon:LayoutBuffBars(self) end)
                entry:HookScript("OnHide", function() addon:LayoutBuffBars(self) end)
            end

            addon:StyleBuffBar(entry)

            if entry.Bar then
                local bar = entry.Bar
                local _, _, _, _, barTexture = bar:GetRegions()
                if barTexture then
                    addon:ColorBarTexture(barTexture)
                end
            end
        end
    end)
end

-- Action bar button glows
hooksecurefunc(ActionButtonSpellAlertManager, "ShowAlert", function(_, button)
    local IsAssistedCombatAction = C_ActionBar.IsAssistedCombatAction
    local action = button.action
    if not action then
        -- don't hide glows from buttons that don't have actions (PTR issue reporter)
        return
    end
    local spellType, id = GetActionInfo(action)
    -- only check spell and macro glows
    if id and (spellType == "spell" or spellType == "macro") then
        if C_ActionBar.IsAssistedCombatAction(action) then
            -- hide matched glows on the Single-Button Assistant button
            if button.AssistedCombatRotationFrame and button.AssistedCombatRotationFrame.SpellActivationAlert then
                button.AssistedCombatRotationFrame.SpellActivationAlert:Hide()
            end
        elseif button.SpellActivationAlert then
            -- hide matched glows on regular action bars
            button.SpellActivationAlert:Hide()
        end
    end
end)

-- Apply viewer hooks
function addon:HookCooldownViewers()
    self:HookEssentialCooldownViewer()
    self:HookUtilityCooldownViewer()
    self:HookBuffIconCooldownViewer()
    self:HookBuffBarCooldownViewer()
end

-----------------------------------------------------------------------
-- FRAMES
-----------------------------------------------------------------------
-- Apply hooks when addon loads
local f = CreateFrame("Frame")
f:RegisterEvent("ADDON_LOADED")
f:SetScript("OnEvent", function(_, _, addonName)
    if addonName ~= "KUtils" then return end
    addon:HookCooldownViewers()
end)

-- Store current player spec
local specFrame = CreateFrame("Frame")
specFrame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
specFrame:RegisterEvent("PLAYER_ENTERING_WORLD")

specFrame:SetScript("OnEvent", function(_, event, unit)
    if event == "PLAYER_SPECIALIZATION_CHANGED" and unit ~= "player" then return end
    addon.currentSpec = C_SpecializationInfo.GetSpecialization()
end)

-- If hiding outside combat, hide the designated viewers
local iconViewers = {EssentialCooldownViewer, UtilityCooldownViewer}
local combatFrame = CreateFrame("Frame")
combatFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
combatFrame:RegisterEvent("PLAYER_REGEN_ENABLED")

combatFrame:SetScript("OnEvent", function(_, event)
    addon.inCombat = (event == "PLAYER_REGEN_DISABLED")

    -- Hide icons if necessary
    if not addon.DISPLAY_CDM_OUTSIDE_COMBAT then
        for _, viewer in ipairs(iconViewers) do
            addon:LayoutIcons(viewer)
        end
    end

    local buttons = EssentialCooldownViewer:GetItemFrames()
    if buttons then
        for _, button in ipairs(buttons) do
            addon:HideButtonGlow(button)
        end
    end
end)

-- Hook the cast bar
local castBarFrame = CreateFrame("Frame")
castBarFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
castBarFrame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
castBarFrame:RegisterEvent("UNIT_SPELLCAST_START")
castBarFrame:RegisterEvent("UNIT_SPELLCAST_CHANNEL_START")
castBarFrame:RegisterEvent("UNIT_SPELLCAST_CHANNEL_STOP")
castBarFrame:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
castBarFrame:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED")
castBarFrame:RegisterEvent("UNIT_SPELLCAST_FAILED")
castBarFrame:RegisterEvent("UNIT_SPELLCAST_STOP")

castBarFrame:SetScript("OnEvent", function(_, _, unit)
    if unit and unit ~= "player" then return end
    local bar = PlayerCastingBarFrame
    if not bar then return end

    -- Style and position the cast bar
    addon:PositionCastBar()
    addon:StyleCastBar()

    if not bar._addonHooked then
        bar._addonHooked = true

        -- Reposition on show
        bar:HookScript("OnShow", function()
            addon:PositionCastBar()
        end)

        -- Update timer text
        bar:HookScript("OnUpdate", function(self)
            if not self.TimeText or not self:IsShown() then return end

            if self.casting then
                self.TimeText:SetFormattedText("%.1f", self.maxValue - self.value)
            elseif self.channeling then
                self.TimeText:SetFormattedText("%.1f", self.value)
            else
                self.TimeText:SetText("")
            end
        end)

        -- Update spell text and ensure it doesn't run into the timer text
        hooksecurefunc(PlayerCastingBarFrame.Text, "SetText", function(fs, text)
            if fs._addonUpdating then return end
            if not text then return end

            local trimmed = addon:CastBarCustomText(text, addon.castBarConfig.textLength)
            if trimmed == text then return end

            fs._addonUpdating = true
            fs:SetText(trimmed)
            fs._addonUpdating = nil
        end)

        -- Reapply texture any time it updates
        hooksecurefunc(PlayerCastingBarFrame, "SetStatusBarTexture", function(self)
            local tex = self:GetStatusBarTexture()
            if tex and tex:GetTexture() ~= addon.castBarConfig.barTexture then
                tex:SetTexture(addon.castBarConfig.barTexture)
            end
        end)

        -- Hide cast spark
        hooksecurefunc(PlayerCastingBarFrame, "ShowSpark", function(self)
            self:HideSpark()
        end)

        -- Recolor the cast bar if a spell has been interruppted
        hooksecurefunc(PlayerCastingBarFrame, "PlayInterruptAnims", function(self)
            addon.castBarInterrupted = true
        end)

        hooksecurefunc(PlayerCastingBarFrame, "StopInterruptAnims", function(self)
            addon.castBarInterrupted = false
        end)
    end
end)