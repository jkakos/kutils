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