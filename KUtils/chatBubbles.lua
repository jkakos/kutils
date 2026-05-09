local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("SCENARIO_UPDATE")
frame:RegisterEvent("SCENARIO_COMPLETED")

-- Disable chat bubbles in delves
frame:SetScript("OnEvent", function(_, event)
    C_Timer.After(5, function()
        local name, instanceType, difficultyID, difficultyName = GetInstanceInfo()
        if difficultyName == "Delves" then
            SetCVar("chatBubbles", 0)
        else
            SetCVar("chatBubbles", 1)
        end
    end)
end)
