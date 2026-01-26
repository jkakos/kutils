local _, addon = ...

-- Create a pseudo border around text by adding multiple copies of the text in black
-- behind the text with slight offsets
function addon:AddFakeTextOutline(text, size)
    if text._outline then return end

    local parent = text:GetParent()
    local font, fontSize, flags = text:GetFont()

    local outlineFrame = CreateFrame("Frame", nil, parent)
    outlineFrame:SetAllPoints(parent)
    outlineFrame:SetFrameLevel(parent:GetFrameLevel())

    local outlines = {}
    local offsets = {
        {-size, 0}, {size, 0}, {0, -size}, {0, size},
        {-size, -size}, {-size, size}, {size, -size}, {size, size}
    }

    for i, offset in ipairs(offsets) do
        local fs = outlineFrame:CreateFontString(nil, "OVERLAY", nil, 1)
        fs:SetFont(font, fontSize, flags)
        fs:SetTextColor(0, 0, 0, 1)
        fs:SetPoint(    "TOPLEFT", text,     "TOPLEFT", offset[1], offset[2])
        fs:SetPoint("BOTTOMRIGHT", text, "BOTTOMRIGHT", offset[1], offset[2])
        fs:SetJustifyH(text:GetJustifyH() or "CENTER")
        fs:SetText(text:GetText() or "")
        outlines[i] = fs
    end

    hooksecurefunc(text, "SetText", function(_, t)
        for _, fs in ipairs(outlines) do
            fs:SetText(t or "")
        end
    end)

    text._outline = outlines
end

-- Add fake outline to cast bar text by creating hiding existing text and and
-- recreating it with the outline behind it
local function CreateFakeOutlineCastBarBase(text, container, size, isTimer)
    local font, fontSize, flags = text:GetFont()
    local justify = text:GetJustifyH() or (isTimer and "RIGHT" or "CENTER")
    local outlines = {}
    local offsets = {
        {-size, 0}, {size, 0}, {0, -size}, {0, size},
        {-size, -size}, {-size, size}, {size, -size}, {size, size}
    }

    -- Create outlines
    for i, offset in ipairs(offsets) do
        local fs = container:CreateFontString(nil, "OVERLAY", nil, 1)
        fs:SetFont(font, fontSize, flags)
        fs:SetTextColor(0, 0, 0, 1)
        fs:SetJustifyH(justify)

        if isTimer then
            fs:SetPoint("CENTER", text, "CENTER", offset[1], offset[2])
        else
            fs:SetPoint(    "TOPLEFT", container,     "TOPLEFT", offset[1], offset[2])
            fs:SetPoint("BOTTOMRIGHT", container, "BOTTOMRIGHT", offset[1], offset[2])
        end
        outlines[i] = fs
    end

    -- Recreate text as a top layer
    local frontText = container:CreateFontString(nil, "OVERLAY", nil, 7)
    frontText:SetFont(font, fontSize, flags)
    frontText:SetTextColor(text:GetTextColor())
    frontText:SetJustifyH(justify)

    if isTimer then
        frontText:SetPoint("CENTER", text, "CENTER", 0, 0)
    else
        frontText:SetAllPoints(container)
    end

    -- Sync and hide original text
    text:SetAlpha(0)

    hooksecurefunc(text, "SetAlpha", function(self, alpha)
        if alpha > 0 then self:SetAlpha(0) end
        container:SetAlpha(alpha)
    end)

    local function Sync()
        local t = text:GetText() or ""
        frontText:SetText(t)
        for _, fs in ipairs(outlines) do
            fs:SetText(t)
        end
    end

    hooksecurefunc(text, "SetText", Sync)
    if isTimer then hooksecurefunc(text, "SetFormattedText", Sync) end
    hooksecurefunc(text, "SetShown", function(_, isShown) container:SetShown(isShown) end)

    Sync()
    text._outline = outlines
end

-- Add fake outline to the spell text on the cast bar
function addon:AddFakeTextOutlineCastBarSpell(text, size)
    if text._outline then return end

    local container = CreateFrame("Frame", nil, text:GetParent())
    container:SetAllPoints(text)
    container:SetFrameLevel(text:GetParent():GetFrameLevel() + 5)

    CreateFakeOutlineCastBarBase(text, container, size, false)
end

-- Add fake outline to the timer text on the cast bar
function addon:AddFakeTextOutlineCastBarTimer(text, size)
    if text._outline then return end

    local container = CreateFrame("Frame", nil, text:GetParent())
    container:SetAllPoints(text:GetParent())
    container:SetFrameLevel(text:GetParent():GetFrameLevel() + 15)

    CreateFakeOutlineCastBarBase(text, container, size, true)
end

----------------------------------------------------------------------------------------
-- ICONS
----------------------------------------------------------------------------------------
-- Add an inner border to an icon
function addon:AddIconInnerBorder(button, thickness, color)
    if button._innerBorder then return end
    local border = {}
    local r, g, b, a = unpack(color)
    a = a or 1

    -- Left
    border.left = button:CreateTexture(nil, "OVERLAY")
    border.left:SetColorTexture(r, g, b, a)
    border.left:SetPoint("TOPLEFT", 0, 0)
    border.left:SetPoint("BOTTOMLEFT", 0, 0)
    border.left:SetWidth(thickness)

    -- Right
    border.right = button:CreateTexture(nil, "OVERLAY")
    border.right:SetColorTexture(r, g, b, a)
    border.right:SetPoint("TOPRIGHT", 0, 0)
    border.right:SetPoint("BOTTOMRIGHT", 0, 0)
    border.right:SetWidth(thickness)

    -- Top
    border.top = button:CreateTexture(nil, "OVERLAY")
    border.top:SetColorTexture(r, g, b, a)
    border.top:SetPoint("TOPLEFT", 0, 0)
    border.top:SetPoint("TOPRIGHT", 0, 0)
    border.top:SetHeight(thickness)

    -- Bottom
    border.bottom = button:CreateTexture(nil, "OVERLAY")
    border.bottom:SetColorTexture(r, g, b, a)
    border.bottom:SetPoint("BOTTOMLEFT", 0, 0)
    border.bottom:SetPoint("BOTTOMRIGHT", 0, 0)
    border.bottom:SetHeight(thickness)

    button._innerBorder = border
end

-- Add a black background to an icon to hide the gaps between the rounded icon
-- corners and the added border.
function addon:AddIconBackground(button, color)
    if button._background then return end
    local r, g, b, a = unpack(color)
    a = a or 1

    local bg = button:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(button)
    bg:SetColorTexture(r, g, b, a)
    button._background = bg
end

-- Prevent desaturation of icons on cooldown
function addon:StyleCooldownDesaturate(icon)
    icon._addonInDesatHook = true
    icon:SetDesaturated(false)
    icon._addonInDesatHook = false
end

-- Style cooldown swipe for active auras and normal cooldowns
function addon:StyleCooldownSwipe(button)
    local cd = button.Cooldown
    if not cd then return end

    -- If cooldown of an active aura
    if button.auraInstanceID then
        cd:SetSwipeColor(addon:GetActiveSwipeColor())
        cd:SetDrawEdge(true)
        cd:SetReverse(true)
    -- Normal ability cooldown
    else
        cd:SetSwipeColor(unpack(addon.BUTTON_COOLDOWN_SWIPE_COLOR))
        -- cd:SetDrawEdge(true)
        cd:SetReverse(false)
        -- cd:SetHideCountdownNumbers(true)
    end
end

-- Change cooldown timer font and font size
function addon:StyleCooldownTimerFont(button)
    if not button.Cooldown or button._addonTimerFontHooked then return end

    local regions = {button.Cooldown:GetRegions()}
    for _, region in ipairs(regions) do
        if region:IsObjectType("FontString") then
            -- region:ClearAllPoints()
            -- region:SetPoint("BOTTOM", button.Cooldown, "CENTER", 0, 0)
            region:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
            button._addonTimerFontHooked = true
            break
        end
    end
end

-- Change icon charge number font and font size
function addon:StyleChargeFont(button)
    if not button or button._addonChargeFontHooked then return end

    if button.ChargeCount and button.ChargeCount.Current then
        local chargeText = button.ChargeCount.Current
        chargeText:ClearAllPoints()
        chargeText:SetPoint("BOTTOMRIGHT", button.ChargeCount, "BOTTOMRIGHT", 1, 0)
        chargeText:SetFont("Fonts\\FRIZQT__.TTF", 14, "OUTLINE")
        button._addonChargeFontHooked = true
    end
end

-- Change icon stack number font and font size
function addon:StyleApplicationsFont(button)
    if button.Applications and button.Applications.Applications then
        local stacks = button.Applications.Applications
        stacks:ClearAllPoints()
        stacks:SetPoint("CENTER", button, "CENTER", 0, 0)
        stacks:SetFont("Fonts\\FRIZQT__.TTF", 18, "OUTLINE")
    end
end

-- Set icon glow size based on icon size
function addon:SetButtonGlowSize(button)
    local alert = button.SpellActivationAlert
    if alert then
        local width, height = button:GetSize()
        local multiplier = 1.4
        alert:SetSize(width * multiplier, height * multiplier)
    end
end

-- Hide button glows when out of combat
function addon:HideButtonGlow(button)
    if not button then return end

    local alert = button.SpellActivationAlert
    if alert then
        if not addon.inCombat then alert:Hide() end
    end
end

----------------------------------------------------------------------------------------
-- BARS
----------------------------------------------------------------------------------------
-- Add an inner border to a bar
function addon:AddBarInnerBorder(bar, thickness, color, isCastBar)
    if bar._innerBorder then return end
    isCastBar = isCastBar or false
    local pad = thickness
    local border = {}
    local r, g, b, a = unpack(color)
    a = a or 1


    local frame
    if isCastBar then
        frame = CreateFrame("Frame", nil, bar)
    else
        frame = CreateFrame("Frame", nil, bar:GetParent())
    end

    frame:SetFrameLevel(0)
    frame:SetAllPoints(bar)
    bar._borderFrame = frame

    local function makeTex(frame, anchor1, anchor2, thickness, isVertical)
        local borderPoints = {
            ["TOPLEFT"]      = {-thickness,  thickness},
            ["TOPRIGHT"]     = { thickness,  thickness},
            ["BOTTOMLEFT"]   = {-thickness, -thickness},
            ["BOTTOMRIGHT"]  = { thickness, -thickness},
        }

        local t = frame:CreateTexture(nil, "BACKGROUND")
        t:SetColorTexture(r, g, b, a)
        t:SetPoint(anchor1, unpack(borderPoints[anchor1]))
        t:SetPoint(anchor2, unpack(borderPoints[anchor2]))

        if isVertical then
            t:SetWidth(thickness)
        else
            t:SetHeight(thickness)
        end

        return t
    end

    border.left   = makeTex(frame, "TOPLEFT",    "BOTTOMLEFT",  thickness, true )
    border.right  = makeTex(frame, "TOPRIGHT",   "BOTTOMRIGHT", thickness, true )
    border.top    = makeTex(frame, "TOPLEFT",    "TOPRIGHT",    thickness, false)
    border.bottom = makeTex(frame, "BOTTOMLEFT", "BOTTOMRIGHT", thickness, false)
    bar._innerBorder = border
end

-- Apply coloring to buff bars (updated for specs)
function addon:ColorBarTexture(barTexture, color)
    if not barTexture then return end

    if color then
        local r, g, b, a = unpack(color)
        a = a or 1
        barTexture:SetVertexColor(r, g, b, a)
    else
        barTexture:SetVertexColor(unpack(addon:GetSpecColor(nil, addon.currentSpec)))
    end
end

-- Apply visual adjustments to buff bars
function addon:StyleBuffBar(entry)
    if entry._addonStyled then return end
    entry._addonStyled = true

    local bar = entry.Bar
    if not bar then return end

    local config = addon.buffBarConfig

    -- Bar size
    entry:SetSize(config.barWidth, config.barHeight)
    bar:SetSize(config.barWidth, config.barHeight)

    -- Keep the border aligned
    if bar._borderFrame then
        bar._borderFrame:SetAllPoints(bar)
    end

    local bgTexture, sparkTexture, nameText, timerText, barTexture = bar:GetRegions()

    -- Background texture
    if bgTexture and bgTexture:GetObjectType() == "Texture" then
        local w, h = barTexture:GetSize()
        bgTexture:SetVertexColor(unpack(config.backgroundColor))
        bgTexture:SetTexture("Interface\\Tooltips\\UI-Tooltip-Background")
        bgTexture:ClearAllPoints()
        bgTexture:SetPoint("CENTER", barTexture:GetParent(), "CENTER")  -- parent of barTexture is the bar frame
        bgTexture:SetSize(w, h)
        addon:AddBarInnerBorder(bgTexture, config.borderThickness, config.borderColor)
    end

    -- Spark
    if sparkTexture and sparkTexture:GetObjectType() == "Texture" then
        -- sparkTexture:SetVertexColor(1, 1, 1, 1)
        sparkTexture:SetAlpha(0)
    end

    -- Spell name text
    if nameText and nameText:GetObjectType() == "FontString" then
        nameText:SetFont("Fonts\\FRIZQT__.TTF", config.fontSize) --, "THINOUTLINE")
        addon:AddFakeTextOutline(nameText, 1)
        -- nameText:SetShadowColor(0, 0, 0, 1)
        -- nameText:SetShadowOffset(1, -1)
        nameText:SetTextColor(unpack(config.textColor))
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
        barTexture:SetTexture(config.barTexture)
        addon:ColorBarTexture(barTexture)
    end
end

----------------------------------------------------------------------------------------
-- CAST BAR
----------------------------------------------------------------------------------------
-- Apply visual adjustments to the cast bar
function addon:StyleCastBar()
    local bar = PlayerCastingBarFrame
    if not bar then return end

    local config = addon.castBarConfig

    -- Only needs to run once
    if not bar._addonStyled then
        bar._addonStyled = true
        if bar.Border then bar.Border:Hide() end

        addon:AddIconBackground(bar, config.backgroundColor)
        bar.Background:Hide()
        bar.InterruptGlow:Hide()  -- hide red spell interrupt glow

        addon:AddBarInnerBorder(bar, config.borderThickness, config.borderColor, true)

        if not bar.TimeText then
            bar.TimeText = bar:CreateFontString(nil, "OVERLAY")
            bar.TimeText:SetPoint("RIGHT", bar, 0, 0)
            bar.TimeText:SetJustifyH("LEFT")
            bar.TimeText:SetFont(config.font, config.fontSize)
        end
    end

    -- Remove Blizzard art
    if bar.Icon then bar.Icon:Hide() end
    bar.TextBorder:Hide()  -- hide the lower texture that normally shows the cast name

    -- Size
    bar:SetSize(config.barWidth, config.barHeight)

    -- Texture
    addon:StyleCastBarTexture(bar)

    -- Timer text (right)
    addon:StyleCastBarTimerText(bar)

    -- Spell name (left)
    bar.Text:ClearAllPoints()
    bar.Text:SetPoint("LEFT", bar, 4, 0)
    bar.Text:SetJustifyH("LEFT")
    bar.Text:SetFont(config.font, config.fontSize)
    addon:AddFakeTextOutlineCastBarSpell(bar.Text, 1)
end

-- Format the cast bar timer text
function addon:StyleCastBarTimerText(bar)
    if not bar.TimeText or not bar:IsShown() then return end

    local time = bar.casting and (bar.maxValue - bar.value) or (bar.channeling and bar.value) or 0
    if not (time > 0) then return bar.TimeText:SetText("") end

    local width = (time >= 10) and addon.castBarTimerWideTextWidth or addon.castBarTimerNarrowTextWidth
    bar.TimeText:SetWidth(width)
    bar.TimeText:SetFormattedText("%.1f", time)
    addon:AddFakeTextOutlineCastBarTimer(bar.TimeText, 1)
end

-- Format the cast bar spell text
function addon:StyleCastBarSpellText(fontstring, text)
    local trimmed = addon:TruncateText(text, addon.castBarConfig.textLength)
    if trimmed == text then return end

    fontstring._addonUpdating = true
    fontstring:SetText(trimmed)
    fontstring._addonUpdating = nil
end

-- Style cast bar texture for casts and interrupted casts
function addon:StyleCastBarTexture(bar)
    local tex = bar:GetStatusBarTexture()
    if tex and tex:GetTexture() ~= addon.castBarConfig.barTexture then
        tex:SetTexture(addon.castBarConfig.barTexture)

        if addon.castBarInterrupted then
            addon:ColorBarTexture(tex, addon.castBarConfig.interruptColor)
        else
            addon:ColorBarTexture(tex)
        end
    end
end