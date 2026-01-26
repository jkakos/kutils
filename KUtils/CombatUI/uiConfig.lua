local _, addon = ...

addon.DISPLAY_CDM_OUTSIDE_COMBAT  = false
addon.VIEWERS_TO_HIDE             = {EssentialCooldownViewer, UtilityCooldownViewer}
addon.BAR_WIDTH                   = 238
addon.SPACING                     = 2
addon.PRIMARY_RESOURCE_HEIGHT     = 16
addon.SECONDARY_RESOURCE_HEIGHT   = 12

addon.AURA_ACTIVE_SWIPE_COLOR     = {0, 0, 0, 0.7}
addon.BUTTON_COOLDOWN_SWIPE_COLOR = {0, 0, 0, 0.8}
addon.GLOBAL_COOLDOWN_SWIPE_COLOR = {0, 0, 0, 0.5}

addon.BASE_UI_POS = {
    x = 0,
    y = -1080/2 - 181 -- a bit lower than the center of the screen, from the top
}

-- Whether primary/secondary resource bars are hidden for each class/spec
addon.PRIMARY_RESOURCE_HIDDEN = {
    ["Druid"]        = {false, false, false, false},
    ["Mage"]         = {false,  true,  true},
    ["Monk"]         = {false, false, false},
    ["Death Knight"] = {false, false, false},
}
addon.SECONDARY_RESOURCE_HIDDEN = {
    ["Druid"]        = { true, false, false, false},
    ["Mage"]         = {false,  true,  true},
    ["Monk"]         = {false,  true, false},
    ["Death Knight"] = {false, false, false},
}

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

    local hidePrimary   = false
    local hideSecondary = false
    local offset = addon.PRIMARY_RESOURCE_HEIGHT + addon.SECONDARY_RESOURCE_HEIGHT + 1

    if addon.PRIMARY_RESOURCE_HIDDEN[className] and addon.PRIMARY_RESOURCE_HIDDEN[className][specId] then
        hidePrimary = true
    end
    if addon.SECONDARY_RESOURCE_HIDDEN[className] and addon.SECONDARY_RESOURCE_HIDDEN[className][specId] then
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

-- Set the icon highlight color when an aura is active
function addon:GetActiveSwipeColor()
    -- return addon.AURA_ACTIVE_SWIPE_COLOR
    local r, g, b = unpack(addon:GetSpecColor(nil, addon.currentSpec))
    return r, g, b, 0.7
end

-- Base settings for any icons
local function CreateIconConfig(overrides)
    local config = {
        -- Standard icon settings
        spacing         = addon.SPACING,
        xOffset         = 0,
        borderThickness = 2,
        borderColor     = {0, 0, 0, 1},
        backgroundColor = {0, 0, 0, 1},
        -- Function flags
        hookCooldownSwipe      = true,
        hookButtonVisibility   = true,
        styleChargeFont        = true,
        styleCooldownTimerFont = true,
        styleApplicationsFont  = false,
        addInnerBorder         = true,
        addBackground          = true,
        hideGlow               = false,
        setGlowSize            = false,
    }

    if overrides then
        for k, v in pairs(overrides) do
            config[k] = v
        end
    end

    return config
end

----------------------------------------------------------------------------------------
-- COOLDOWN VIEWER AND CAST BAR CONFIGURATIONS
----------------------------------------------------------------------------------------
addon.essentialConfig = CreateIconConfig({
    rowLimit    = {5, 6},
    iconSize    = {38, 30},
    yOffset     = 0,
    hideGlow    = true,
    setGlowSize = true,
})
addon.buffBarConfig = {
    barWidth        = addon.BAR_WIDTH,
    barHeight       = 6,
    spacing         = 1,
    xOffset         = 0,
    borderThickness = 1,
    borderColor     = {0, 0, 0, 1},
    backgroundColor = {0.2, 0.2, 0.2, 1},
    textColor       = {1, 1, 1, 1},
    maxBars         = 2,
    fontSize        = 10,
    barTexture      = "Interface\\AddOns\\KUtils\\Textures\\Statusbar_Clean"
}
addon.buffIconConfig = CreateIconConfig({
    rowLimit               = {6},
    iconSize               = {32},
    hookButtonVisibility   = false,
    styleCooldownTimerFont = false,
    styleApplicationsFont  = true,
})
addon.castBarConfig = {
    barWidth        = addon.BAR_WIDTH,
    barHeight       = 18,
    xOffset         = 0,
    borderThickness = 2,
    borderColor     = {0, 0, 0, 1},
    backgroundColor = {0.086, 0.086, 0.086, 1},
    interruptColor  = {0.7, 0, 0, 1},
    font            = "Fonts\\FRIZQT__.TTF",
    fontSize        = 12,
    textLength      = 25,
    barTexture      = "Interface\\AddOns\\KUtils\\Textures\\Statusbar_Clean"
}
addon.castBarConfig["yOffset"] = -(
    addon.essentialConfig.iconSize[1]
    + addon.essentialConfig.iconSize[2]
    + addon.SPACING * 2
    + addon.castBarConfig.borderThickness
)
addon.utilityConfig = CreateIconConfig({
    rowLimit = {5, 5},
    iconSize = {30, 30},
    yOffset  = addon.castBarConfig.yOffset
               - (addon.castBarConfig.barHeight
               + addon.castBarConfig.borderThickness
               + addon.SPACING),
    styleApplicationsFont = true,
})

addon.buffBarConfig["yOffset"] = addon:GetResourceBarOffset()
addon.buffIconConfig["yOffset"] = addon:GetBuffIconBarOffset()