local _, addon = ...

addon.DISPLAY_CDM_OUTSIDE_COMBAT  = false
addon.BAR_WIDTH                   = 238
addon.SPACING                     = 2
addon.PRIMARY_RESOURCE_HEIGHT     = 16
addon.SECONDARY_RESOURCE_HEIGHT   = 12
addon.AURA_ACTIVE_SWIPE_COLOR     = {0, 0, 0, 0.7}
addon.BUTTON_COOLDOWN_SWIPE_COLOR = {0, 0, 0, 0.8}
addon.GLOBAL_COOLDOWN_SWIPE_COLOR = {0, 0, 0, 0.5}

-- Recalculate the yOffset for buff icons based on the resource bar yOffset
function addon:GetBuffIconBarOffset(className, specId)
    local offset = (
        addon.buffBarConfig.yOffset
        + addon.buffBarConfig.maxBars * addon.buffBarConfig.barHeight
        + (addon.buffBarConfig.maxBars - 1) * addon.buffBarConfig.spacing
        + addon.SPACING
        + addon.buffIconConfig.iconSize[1]
        + 1  -- Not sure why, probably something with borders overlapping
    )
    addon.buffIconConfig["yOffset"] = offset

    return offset
end

-- Recalculate the resource bar yOffset depending on which resources are shown for a spec
function addon:GetResourceBarOffset(className, specId)
    if not className then
        className = UnitClass("player")
    end
    if not specId then
        specId = C_SpecializationInfo.GetSpecialization()
    end

    local hidePrimaryResource = {
        ["Druid"]        = {false, false, false, false},
        ["Mage"]         = {false,  true,  true},
        ["Monk"]         = {false, false, false},
        ["Death Knight"] = {false, false, false},
    }
    local hideSecondaryResource = {
        ["Druid"]        = { true, false, false, false},
        ["Mage"]         = {false,  true,  true},
        ["Monk"]         = {false,  true, false},
        ["Death Knight"] = {false, false, false},
    }

    local hidePrimary   = false
    local hideSecondary = false
    local offset = addon.PRIMARY_RESOURCE_HEIGHT + addon.SECONDARY_RESOURCE_HEIGHT + 1

    if hidePrimaryResource[className] and hidePrimaryResource[className][specId] then
        hidePrimary = true
    end
    if hideSecondaryResource[className] and hideSecondaryResource[className][specId] then
        hideSecondary = true
    end

    if hidePrimary and hideSecondary then
        offset = offset - addon.PRIMARY_RESOURCE_HEIGHT - addon.SECONDARY_RESOURCE_HEIGHT + 2
    elseif hideSecondary then
        offset = offset - addon.SECONDARY_RESOURCE_HEIGHT + 1
    end

    offset = offset + 2 * addon.SPACING - 4
    addon.buffBarConfig["yOffset"] = offset
    addon.buffIconConfig["yOffset"] = addon:GetBuffIconBarOffset()

    return offset
end

addon.currentSpec = C_SpecializationInfo.GetSpecialization()
addon.buffBarOrder = {}
addon.inCombat = false

addon.baseUIPosition = {
    x = 0,
    y = -1080/2 - 181 -- a bit lower than the center of the screen, from the top
}
addon.essentialConfig = {
    rowLimit        = {5, 6},
    iconSize        = {38, 30},
    spacing         = addon.SPACING,
    xOffset         = 0,
    yOffset         = 0,
    borderThickness = 2
}
addon.buffBarConfig = {
    barWidth        = addon.BAR_WIDTH,
    barHeight       = 6,
    spacing         = 1,
    xOffset         = 0,
    borderThickness = 1,
    maxBars         = 2,
    fontSize        = 10,
    -- barTexture      = "Interface\\Buttons\\WHITE8X8"
    barTexture      = "Interface\\AddOns\\KUtils\\Textures\\Statusbar_Clean"
    -- barTexture      = "Interface\\AddOns\\KUtils\\Textures\\bar_skyline"
}
addon.buffIconConfig = {
    rowLimit        = {6,},
    iconSize        = {32,},
    spacing         = addon.SPACING,
    xOffset         = 0,
    borderThickness = 2
}

addon.buffBarConfig["yOffset"] = addon.GetResourceBarOffset()
addon.buffIconConfig["yOffset"] = addon.GetBuffIconBarOffset()

addon.castBarConfig = {
    barWidth        = addon.BAR_WIDTH,
    barHeight       = 18,
    xOffset         = 0,
    borderThickness = 2,
    fontSize        = 12,
    textLength      = 25,
    -- barTexture      = "Interface\\AddOns\\KUtils\\Textures\\bar_skyline"
    barTexture      = "Interface\\AddOns\\KUtils\\Textures\\Statusbar_Clean"
}
addon.castBarConfig["yOffset"] = -(
    addon.essentialConfig.iconSize[1]
    + addon.essentialConfig.iconSize[2]
    + addon.SPACING * 2
    + addon.castBarConfig.borderThickness
)
addon.utilityConfig = {
    rowLimit        = {5, 5},
    iconSize        = {30, 30},
    spacing         = addon.SPACING,
    xOffset         = 0,
    yOffset         = addon.castBarConfig.yOffset
                      - (addon.castBarConfig.barHeight
                      + addon.castBarConfig.borderThickness
                      + addon.SPACING),
    borderThickness = 2
}