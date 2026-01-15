-----------------------------------------------------------------------
-- ICONS
-----------------------------------------------------------------------
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
        if viewer ~= UtilityCooldownViewer then
            button:SetTimerShown(false)
        end
    end

    local activeButtons = buttons
    if (viewer == BuffIconCooldownViewer) or (viewer == UtilityCooldownViewer) then
        activeButtons = {}
        for _, button in ipairs(buttons) do
            if button.isActive then
                table.insert(activeButtons, button)
            else
                button:Hide()
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
        else
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

            if not addon.DISPLAY_CDM_OUTSIDE_COMBAT then
                if addon.inCombat then
                    button:Show()
                elseif viewer ~= BuffIconCooldownViewer then
                    button:Hide()
                end
            else
                button:Show()
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

    for _, entry in ipairs({viewer:GetChildren()}) do
        if entry.auraInstanceID and not addon.buffBarOrder[entry] then
            local _, _, _, _, yInitial = entry:GetPoint()
            addon.buffBarOrder[entry] = yInitial
            entry:ClearAllPoints()
            entry:SetPoint("BOTTOM", viewer, "BOTTOM", 0, 0)
            entry:SetSize(barWidth, 100)
        end
    end

    -- Collect active bars
    local active = {}
    for i, entry in ipairs({viewer:GetChildren()}) do
        if entry.isActive then
            table.insert(active, entry)
        end
    end

    -- Sort active according to the cooldown manager order
    table.sort(active, function(a, b)
        return addon.buffBarOrder[a] > addon.buffBarOrder[b]
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

    bar:ClearAllPoints()
    bar:SetPoint("BOTTOM", entry, "BOTTOM", 0, 0)
    bar:SetSize(barWidth, barHeight)
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
        nameText:SetPoint("CENTER", 0, 0)
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
        -- barTexture:SetTexture("Interface\\Tooltips\\UI-Tooltip-Background")
        barTexture:SetTexture(newBarTexture)
        addon:ColorBarTexture(barTexture)
        -- barTexture:SetVertexColor(addon:GetSpecColor(UnitClass("player"), C_SpecializationInfo.GetSpecialization()))
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
            addon:ColorBarTexture(tex, 1, 0, 0, 1)  -- color red if spell interrupted
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
-- Show or hide the borders and backgrounds if an icon is shown or hidden.
function addon:HookButtonVisibility(button)
    if button._addonVisHooked then return end
    button._addonVisHooked = true

    button:HookScript("OnShow", function(self)
        if self._innerBorder then
            for _, tex in ipairs(self._innerBorder) do tex:Show() end
        end
        if self._background then
            self._background:Show()
        end
    end)

    button:HookScript("OnHide", function(self)
        if self._innerBorder then
            for _, tex in ipairs(self._innerBorder) do tex:Hide() end
        end
        if self._background then
            self._background:Hide()
        end
    end)
end

-- Change icon swipe colors when active or on cooldown
function addon:HookIconCooldownColor(button)
    if button._addonCooldownColorHooked then return end
    button._addonCooldownColorHooked = true

    -- Do not desaturate when on cooldown
    hooksecurefunc(button.Icon, "SetDesaturated", function(self, desat)
        if desat then self:SetDesaturated(false) end
    end)

    local cd = button.Cooldown or button.cooldown
    if cd and not cd._addonHooked then
        cd._addonHooked = true

        -- Color of swipe texture when aura is active or on cooldown
        hooksecurefunc(cd, "SetCooldown", function(self, start, duration)
            -- Aura is active
            if (button.auraInstanceID) and (duration > 1.5) then
                self:SetSwipeColor(unpack(addon.AURA_ACTIVE_SWIPE_COLOR))
                self:SetReverse(true)
                self:SetDrawEdge(true)
            -- Aura is on global cooldown
            elseif not (button.auraInstanceID) and (duration <= 1.5) then
                self:SetSwipeColor(unpack(addon.GLOBAL_COOLDOWN_SWIPE_COLOR))
                self:SetReverse(false)
            -- Aura is on cooldown
            else
                self:SetSwipeColor(unpack(addon.BUTTON_COOLDOWN_SWIPE_COLOR))
                self:SetReverse(false)
                self:SetDrawEdge(true)
            end
        end)
    end
end

-- Helper function that sets which viewers should be hidden in combat
function addon:ShouldHideViewer(viewer)
    if addon.DISPLAY_CDM_OUTSIDE_COMBAT then
        return false
    end

    return (
        (viewer == EssentialCooldownViewer)
        or (viewer == UtilityCooldownViewer)
    ) and not addon.inCombat
end

-- Essential Icons
function addon:HookEssentialCooldownViewer()
    hooksecurefunc(EssentialCooldownViewer, "RefreshLayout", function(self)
        local buttons = self:GetItemFrames()
        if buttons then
            for _, button in ipairs(buttons) do
                addon:HookIconCooldownColor(button)
            end
        end

        addon:LayoutIcons(self)
    end)
end

-- Utility Icons
function addon:HookUtilityCooldownViewer()
    local buttons = UtilityCooldownViewer:GetItemFrames()
    if not buttons then return end

    hooksecurefunc(UtilityCooldownViewer, "RefreshLayout", function(self)
        local buttons = self:GetItemFrames()
        if buttons then
            for _, button in ipairs(buttons) do
                if not button._addonHooked then
                    button._addonHooked = true
                    addon:HookIconCooldownColor(button)
                end
            end
        end

        addon:LayoutIcons(self)
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
                addon:HookIconCooldownColor(button)
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
if not addon.DISPLAY_CDM_OUTSIDE_COMBAT then
    local iconViewers = {EssentialCooldownViewer, UtilityCooldownViewer}
    local combatFrame = CreateFrame("Frame")
    combatFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
    combatFrame:RegisterEvent("PLAYER_REGEN_ENABLED")

    combatFrame:SetScript("OnEvent", function(_, event)
        addon.inCombat = (event == "PLAYER_REGEN_DISABLED")

        for _, viewer in ipairs(iconViewers) do
            addon:LayoutIcons(viewer)
        end
    end)
end

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