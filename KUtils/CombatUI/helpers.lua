_, addon = ...

-- Calculate the horizontal position based on the leftmost edge
function addon:GetRowX(xLeft, idxInRow, iconSize, spacing)
    return xLeft + idxInRow * (iconSize + spacing)
end

-- Calculate the vertical position based on the row number
function addon:GetRowY(rowIdx, iconSize, spacing)
    local y = 0

    for i = 1, rowIdx - 1 do
        y = y - iconSize[i] - spacing
    end

    return y
end

-- Calculate the left position based on the number of icons in the row
function addon:GetRowXLeft(iconsPerRow, iconSize, spacing, width)
    local xLeft = {} -- where the left edge of the row will start
    local width = width or 0
    for i, count in ipairs(iconsPerRow) do
        local rowWidth = count * iconSize[i] + (count - 1) * spacing

        -- handle shift from WeakAuras
        local offset = 0
        if width == 0 then
            offset = (iconSize[i] + spacing) / 2
        end

        xLeft[i] = (width - rowWidth) / 2 + offset
    end
    return xLeft
end

-- Calculate the number of icons allowed to be displayed
function addon:GetMaxIcons(rowLimit)
    local totalAllowedIcons = 0  --num total icons to show
    local cumulRowLimit = {}  --cumulative row limits

    for i = 1, #rowLimit do
        totalAllowedIcons = totalAllowedIcons + rowLimit[i]
        cumulRowLimit[i] = totalAllowedIcons
    end
    return totalAllowedIcons, cumulRowLimit
end

-- Calculate the number of icons on each row given the total number of icons
function addon:GetIconsPerRow(numIcons, rowLimit, totalAllowedIcons, cumulRowLimit)
    local iconsPerRow = {}
    for i = 1, #rowLimit do
        if (
            numIcons > totalAllowedIcons
            or numIcons - (cumulRowLimit[i-1]
            or 0) > rowLimit[i]
        ) then
            iconsPerRow[i] = rowLimit[i]
        else
            iconsPerRow[i] = numIcons - (cumulRowLimit[i-1] or 0)
        end
    end
    return iconsPerRow
end

-- Add an inner border to an icon
function addon:AddInnerBorder(button, thickness, r, g, b, a)
    if button._innerBorder then return end
    local border = {}
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
function addon:AddIconBackground(button, r, g, b, a)
    if button._background then return end
    a = a or 1

    local bg = button:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(button)
    bg:SetColorTexture(r, g, b, a)
    button._background = bg
end

-- Add an inner border to a bar
function addon:AddBarInnerBorder(bar, thickness, r, g, b, a, isCastBar)
    if bar._innerBorder then return end
    isCastBar = isCastBar or false
    local pad = thickness
    local border = {}


    local frame
    if isCastBar then
        frame = CreateFrame("Frame", nil, bar)
    else
        frame = CreateFrame("Frame", nil, bar:GetParent())
    end

    -- local frame = CreateFrame("Frame", nil, bar:GetParent())
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

    -- -- Left
    -- border.left:SetPoint("TOPLEFT", -pad, pad)
    -- border.left:SetPoint("BOTTOMLEFT", -pad, -pad)
    -- border.left:SetWidth(thickness)

    -- -- Right
    -- border.right:SetPoint("TOPRIGHT", pad, pad)
    -- border.right:SetPoint("BOTTOMRIGHT", pad, -pad)
    -- border.right:SetWidth(thickness)

    -- -- Top
    -- border.top:SetPoint("TOPLEFT", -pad, pad)
    -- border.top:SetPoint("TOPRIGHT", pad, pad)
    -- border.top:SetHeight(thickness)

    -- -- Bottom
    -- border.bottom:SetPoint("BOTTOMLEFT", -pad, -pad)
    -- border.bottom:SetPoint("BOTTOMRIGHT", pad, -pad)
    -- border.bottom:SetHeight(thickness)

    bar._innerBorder = border
end

-- Create a pseudo border around text by adding multiple copies of the text in black
-- behind the text with slight offsets
function addon:AddFakeTextOutline(text, size)
    if text._outline then return end

    local parent = text:GetParent()
    local font, fontSize, flags = text:GetFont()

    local outlineFrame = CreateFrame("Frame", nil, parent)
    outlineFrame:SetAllPoints(parent)
    outlineFrame:SetFrameLevel(parent:GetFrameLevel() + 0.5)

    local outlines = {}
    local offsets = {{-size, 0}, {size, 0}, {0, -size}, {0, size}}

    for i, o in ipairs(offsets) do
        local fs = outlineFrame:CreateFontString(nil, "OVERLAY")
        fs:SetDrawLayer("OVERLAY", 1)
        fs:SetFont(font, fontSize, flags)
        fs:SetTextColor(0, 0, 0, 1)
        fs:SetPoint("CENTER", text, o[1], o[2])
        fs:SetText(text:GetText() or "")
        outlines[i] = fs
    end

    -- Keep outline text in sync
    hooksecurefunc(text, "SetText", function(_, t)
        for _, fs in ipairs(outlines) do
            fs:SetText(t or "")
        end
    end)

    text._outline = outlines
end

-- Get (r, g, b) values to use for a given class spec
function addon:GetSpecColor(className, specId)
    if not className then
        className = UnitClass("player")
    end
    if not specId then
        specId = C_SpecializationInfo.GetSpecialization()
    end

    local specColors = {
        ["Death Knight"] = {{0.77, 0.12, 0.23}, {0.00, 0.50, 1.00}, {0.40, 0.76, 0.28}},
        ["Demon Hunter"] = {{0.62, 0.62, 1.00}, {0.62, 0.62, 1.00}, {0.62, 0.62, 1.00}},
        ["Druid"]        = {{0.30, 0.52, 1.00}, {1.00, 0.49, 0.04}, {1.00, 0.49, 0.04} , {0.13, 0.68, 0.19}},
        ["Mage"]         = {{0.70, 0.30, 1.00}, {1.00, 0.38, 0.00}, {0.00, 0.50, 1.00}},
        ["Monk"]         = {{0.00, 1.00, 0.60}, {0.00, 1.00, 0.60}, {0.00, 1.00, 0.60}},
        ["Paladin"]      = {{1.00, 0.87, 0.50}, {1.00, 0.87, 0.50}, {1.00, 0.87, 0.50}},
        ["Priest"]       = {{1.00, 1.00, 1.00}, {1.00, 1.00, 1.00}, {0.62, 0.62, 1.00}},
    }

    if specColors[className] and specColors[className][specId] then
        return unpack(specColors[className][specId])
    else
        color = C_ClassColor.GetClassColor(className)
        return color.r, color.g, color.b, 1
    end
end

-- Show the name of the cast on the cast bar truncated at 'lenLimit' characters.
function addon:CastBarCustomText(spellName, lenLimit)
    if spellName then
        if string.len(spellName) > lenLimit then
            return string.sub(spellName, 1, lenLimit) .. "..."
        else
            return spellName
        end
    else
        return ""
    end
end