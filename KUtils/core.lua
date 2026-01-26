local _, addon = ...

-- (r, g, b) colors to use for each class and spec
local specColors = {
    ["Death Knight"] = {{0.77, 0.12, 0.23}, {0.00, 0.50, 1.00}, {0.40, 0.76, 0.28}},
    ["Demon Hunter"] = {{0.62, 0.62, 1.00}, {0.62, 0.62, 1.00}, {0.62, 0.62, 1.00}},
    ["Druid"]        = {{0.30, 0.52, 1.00}, {1.00, 0.49, 0.04}, {1.00, 0.49, 0.04} , {0.13, 0.68, 0.19}},
    ["Mage"]         = {{0.70, 0.30, 1.00}, {1.00, 0.38, 0.00}, {0.00, 0.50, 1.00}},
    ["Monk"]         = {{0.00, 1.00, 0.60}, {0.00, 1.00, 0.60}, {0.00, 1.00, 0.60}},
    ["Paladin"]      = {{1.00, 0.87, 0.50}, {1.00, 0.87, 0.50}, {1.00, 0.87, 0.50}},
    ["Priest"]       = {{1.00, 1.00, 1.00}, {1.00, 1.00, 1.00}, {0.62, 0.62, 1.00}},
}

-- Get (r, g, b) values to use for a given class spec
function addon:GetSpecColor(className, specId)
    if not className then
        className = UnitClass("player")
    end
    if not specId then
        specId = C_SpecializationInfo.GetSpecialization()
    end

    local color
    if specColors[className] and specColors[className][specId] then
        color = specColors[className][specId]
        return {color[1], color[2], color[3], 1}
    else
        color = C_ClassColor.GetClassColor(className)
        return {color.r, color.g, color.b, 1}
    end
end

-- Command to open the cooldown manager
SLASH_KUCDM1 = "/cdm"
SlashCmdList["KUCDM"] = function()
    -- Check if the window exists and toggle its visibility
    if CooldownViewerSettings then
        if CooldownViewerSettings:IsShown() then
            CooldownViewerSettings:Hide()
        else
            CooldownViewerSettings:Show()
        end
    end
end