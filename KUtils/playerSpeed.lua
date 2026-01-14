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
local function GetPlayerSpeed()
	local isGliding, canGlide, forwardSpeed = C_PlayerInfo.GetGlidingInfo()  -- for skyriding
	local baseSpeed = isGliding and forwardSpeed or GetUnitSpeed("player")
	local movementSpeed = baseSpeed * SPEED_NORMALIZATION
	return string.format("Speed: %.1f%%", movementSpeed)
end

-- Create a parent frame
local frame = CreateFrame("Frame", "SpeedTextFrame", UIParent)
frame:SetSize(1, 1)
frame:SetPoint(ANCHOR, UIParent, ANCHOR, X_OFFSET, Y_OFFSET)

-- Create a FontString to display speed text
local text = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
text:SetPoint(ANCHOR, frame, ANCHOR, 0, 0)
text:SetWidth(WIDTH)
text:SetJustifyH(JUSTIFY)
text:SetFont(FONT, FONT_SIZE, FONT_OUTLINE)
text:SetText(GetPlayerSpeed())

-- Update text on timer
C_Timer.NewTicker(UPDATE_INTERVAL, function()
	text:SetText(GetPlayerSpeed())
end)
