-- Constants
local SPEED_NORMALIZATION = 100 / 7
local WIDTH = 150                   -- max text width
local ANCHOR = "BOTTOMLEFT"         -- frame anchor point
local X_OFFSET = 5                  -- offset from frame anchor point
local Y_OFFSET = 5
local JUSTIFY = "LEFT"              -- text justification
local FONT = "Fonts\\FRIZQT__.TTF"
local FONT_SIZE = 14
local FONT_OUTLINE = "OUTLINE"
local UPDATE_INTERVAL = 0.1         -- seconds

-- Create function to get player speed
local function UpdatePlayerSpeed(text)
	local isGliding, canGlide, forwardSpeed = C_PlayerInfo.GetGlidingInfo()  -- for skyriding
	local baseSpeed = isGliding and forwardSpeed or GetUnitSpeed("player")
	if issecretvalue(baseSpeed) then
		text:SetText("Speed secret")
		return
	end
	local movementSpeed = baseSpeed * SPEED_NORMALIZATION
	text:SetText(string.format("Speed: %.1f%%", movementSpeed))
end

-- Create a parent frame
local frame = CreateFrame("Frame", "SpeedTextFrame", UIParent)
frame:SetSize(1, 1)
frame:SetPoint(ANCHOR, UIParent, ANCHOR, X_OFFSET, Y_OFFSET)
frame:RegisterEvent("PLAYER_STARTED_MOVING")
frame:RegisterEvent("PLAYER_STOPPED_MOVING")

-- Create a FontString to display speed text
local text = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
text:SetPoint(ANCHOR, frame, ANCHOR, 0, 0)
text:SetWidth(WIDTH)
text:SetJustifyH(JUSTIFY)
text:SetFont(FONT, FONT_SIZE, FONT_OUTLINE)

-- Update speed text on a timer while the player is moving
local speedTicker
frame:SetScript("OnEvent", function(self, event)
	if event == "PLAYER_STARTED_MOVING" then
		if not speedTicker then
			speedTicker = C_Timer.NewTicker(UPDATE_INTERVAL, function()
				UpdatePlayerSpeed(text)
			end)
		end
	elseif event == "PLAYER_STOPPED_MOVING" then
		if speedTicker then
			speedTicker:Cancel()
			speedTicker = nil
		end
		C_Timer.After(UPDATE_INTERVAL, function()
			UpdatePlayerSpeed(text)
		end)
	end
end)

UpdatePlayerSpeed(text)
