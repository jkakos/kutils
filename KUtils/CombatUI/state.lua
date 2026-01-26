local _, addon = ...

-- Check if an icon should be visible based on combat state
function addon:GetExpectedVisibility(viewer)
    if addon.DISPLAY_CDM_OUTSIDE_COMBAT then return true end
    if addon.inCombat then return true end

    return viewer == BuffIconCooldownViewer
end

-- Show or hide an icon based on combat state
function addon:EnforceVisibility(button, viewer)
    if addon:GetExpectedVisibility(viewer) then
        button:Show()
    else
        button:Hide()
    end
end

-- If hiding outside combat, hide the designated viewers
local combatFrame = CreateFrame("Frame")
combatFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
combatFrame:RegisterEvent("PLAYER_REGEN_ENABLED")

combatFrame:SetScript("OnEvent", function(_, event)
    addon.inCombat = (event == "PLAYER_REGEN_DISABLED")

    -- Hide icons and glows if necessary
    if not addon.DISPLAY_CDM_OUTSIDE_COMBAT then
        for _, viewer in ipairs(addon.VIEWERS_TO_HIDE) do
            addon:LayoutIcons(viewer)
        end
    elseif not addon.inCombat then
        local buttons = EssentialCooldownViewer:GetItemFrames()
        if buttons then
            for _, button in ipairs(buttons) do
                addon:HideButtonGlow(button)
            end
        end
    end
end)
