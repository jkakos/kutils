local _, addon = ...

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

-- Truncate text at 'lenLimit' characters.
function addon:TruncateText(text, lenLimit)
    if not text then return "" end

    if string.len(text) > lenLimit then
        return string.sub(text, 1, lenLimit) .. "..."
    else
        return text
    end
end

-- Measure the width of given text with specified font and size
function addon:GetTextWidth(font, fontSize, text)
    local measurer = UIParent:CreateFontString(nil, "OVERLAY")
    measurer:Hide()
    measurer:SetFont(font, fontSize, "THINOUTLINE")
    measurer:SetText(text)

    -- Add a little wiggle room to offset and ensure no truncation
    return math.ceil(measurer:GetStringWidth()) + 4
end

-- Store text widths for single- and two-digit numbers with one decimal place
addon.castBarTimerNarrowTextWidth = addon:GetTextWidth(addon.castBarConfig.font, addon.castBarConfig.fontSize,  "2.2")
addon.castBarTimerWideTextWidth   = addon:GetTextWidth(addon.castBarConfig.font, addon.castBarConfig.fontSize, "22.2")
