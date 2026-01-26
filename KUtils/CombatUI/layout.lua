local _, addon = ...

----------------------------------------------------------------------------------------
-- ICONS
----------------------------------------------------------------------------------------
function addon:LayoutIcons(viewer, buttons)
    local buttons = buttons or viewer:GetItemFrames()
    if not buttons then return end

    local config = (viewer == EssentialCooldownViewer and addon.essentialConfig) or
                   (viewer == UtilityCooldownViewer   and addon.utilityConfig) or
                   (viewer == BuffIconCooldownViewer  and addon.buffIconConfig)

    if not config then return end

    viewer:ClearAllPoints()
    viewer:SetPointOverride("TOP", UIParent, "TOP", addon.BASE_UI_POS.x, addon.BASE_UI_POS.y)

    wipe(addon.entryTable)
    for _, button in ipairs(buttons) do
        button:SetScale(1)
        if viewer == BuffIconCooldownViewer then button:SetTimerShown(false) end
        if viewer ~= BuffIconCooldownViewer or button:IsShown() then
            table.insert(addon.entryTable, button)
        end
    end

    local viewerWidth = viewer:GetWidth()
    local numIcons = #addon.entryTable
    local totalAllowedIcons, cumulRowLimit = addon:GetMaxIcons(config.rowLimit)
    local iconsPerRow = addon:GetIconsPerRow(numIcons, config.rowLimit, totalAllowedIcons, cumulRowLimit)
    local xLeft = addon:GetRowXLeft(iconsPerRow, config.iconSize, config.spacing, viewerWidth)
    local rowIdx = 1

    for i, button in ipairs(addon.entryTable) do
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
            local xNew = addon:GetRowX(xLeft[rowIdx], idxInRow, config.iconSize[rowIdx], config.spacing) + config.xOffset
            local yNew = addon:GetRowY(rowIdx, config.iconSize, config.spacing) + config.yOffset

            button:ClearAllPoints()
            button:SetPoint("TOPLEFT", viewer, "TOPLEFT", xNew, yNew)
            button:SetSize(config.iconSize[rowIdx], config.iconSize[rowIdx])

            -- Show or hide icons
            addon:EnforceVisibility(button, viewer)
        end
    end
end

----------------------------------------------------------------------------------------
-- BUFF BARS
----------------------------------------------------------------------------------------
local function SetBuffBarPosition(entry, viewer, y)
    local bar = entry.Bar
    if not bar then return end

    entry.Bar:ClearAllPoints()
    entry.Bar:SetPoint("BOTTOM", entry, "BOTTOM", 0, 0)

    entry:ClearAllPoints()
    entry:SetPoint("BOTTOM", viewer, "BOTTOM", 0, y)
end

function addon:LayoutBuffBars(viewer)
    local entries = {viewer:GetChildren()}
    if not entries then return end

    local config  = addon.buffBarConfig
    local yOffset = addon:GetResourceBarOffset(nil, addon.currentSpec)

    viewer:ClearAllPoints()
    viewer:SetPointOverride("BOTTOM", UIParent, "TOP", addon.BASE_UI_POS.x, addon.BASE_UI_POS.y)

    wipe(addon.entryTable)
    for _, entry in ipairs(entries) do
        if entry:IsShown() then
            table.insert(addon.entryTable, entry)

            -- Store bar order
            if addon.buffBarOrder[entry] == nil then
                local _, _, _, _, yInitial = entry:GetPoint()
                addon.buffBarOrder[entry] = yInitial or 200
            end
        end
    end

    -- Sort active according to the cooldown manager order
    table.sort(addon.entryTable, function(a, b)
        local ya = addon.buffBarOrder[a] or -500
        local yb = addon.buffBarOrder[b] or -500
        return ya > yb
    end)

    -- Show and position the allowed number of bars
    local y = yOffset
    for i, entry in ipairs(addon.entryTable) do
        if i <= config.maxBars then
            entry:Show()
            SetBuffBarPosition(entry, viewer, y)
            y = y + config.barHeight + config.spacing
        else
            entry:Hide()
        end
    end
end

----------------------------------------------------------------------------------------
-- CAST BAR
----------------------------------------------------------------------------------------
function addon:LayoutCastBar()
    if InCombatLockdown() then return end
    local config = addon.castBarConfig
    local bar = PlayerCastingBarFrame
    local x = addon.BASE_UI_POS.x + config.xOffset
    local y = addon.BASE_UI_POS.y + config.yOffset

    bar:ClearAllPoints()
    bar:SetPoint("TOP", UIParent, "TOP", x, y)
end
