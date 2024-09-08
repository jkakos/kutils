local function loadCVars()
    SetCVar("raidOptionDisplayMainTankAndAssist", 0)
    SetCVar("autoLootDefault", 1)
end

local CVarLoader = CreateFrame("Frame")
CVarLoader:RegisterEvent("PLAYER_ENTERING_WORLD")
CVarLoader:SetScript(
    "OnEvent", 
    function(self, event)
        if event == "PLAYER_ENTERING_WORLD" then
            loadCVars()
        end
    end
)

local function toggleCastBar(frame)
    if frame.isShown then
        PlayerCastingBarFrame:UnregisterAllEvents()
        frame.isShown = false
    else
        PlayerCastingBarFrame:RegisterAllEvents()
        frame.isShown = true
        
    end
end

local castBarFrame = CreateFrame("Frame")
castBarFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
castBarFrame:SetScript(
    "OnEvent",
    function(self, event)
        if event == "PLAYER_ENTERING_WORLD" then
            self.isShown = true
            toggleCastBar(self)            
        end
    end
)

SLASH_KUCASTBAR1 = "/kucastbar"
SlashCmdList["KUCASTBAR"] = function(msg)
    toggleCastBar(castBarFrame)
    if castBarFrame.isShown then
        print("Cast bar enabled")
    else
        print("Cast bar disabled")
    end
end