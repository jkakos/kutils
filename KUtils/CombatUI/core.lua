local _, addon = ...

addon.entryTable = {} -- Hold entries from cooldown viewers when positioning entries
addon.buffBarOrder = {}  -- Get initial ordering of buff bars
addon.currentSpec = C_SpecializationInfo.GetSpecialization()
addon.inCombat = false

-- Apply hooks when addon loads
local f = CreateFrame("Frame")
f:RegisterEvent("ADDON_LOADED")
f:RegisterEvent("PLAYER_ENTERING_WORLD")
f:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")

f:SetScript("OnEvent", function(_, event, arg1)
    if event == "ADDON_LOADED" and arg1 == "KUtils" then
        addon:ApplyHooks()
        f:UnregisterEvent("ADDON_LOADED")
    elseif event == "PLAYER_ENTERING_WORLD" or (event == "PLAYER_SPECIALIZATION_CHANGED" and arg1 == "player") then
        addon.currentSpec = C_SpecializationInfo.GetSpecialization()
    end
end)
