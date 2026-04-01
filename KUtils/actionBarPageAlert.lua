-- Constants
local TEXT_ANCHOR = "CENTER"
local PARENT_ANCHOR = "CENTER"
local X_OFFSET = 0
local Y_OFFSET = 125
local FONT = "Fonts\\FRIZQT__.TTF"
local FONT_SIZE = 36
local FONT_OUTLINE = "THICKOUTLINE"

local frame = CreateFrame("Frame", nil, UIParent)
frame:RegisterEvent("ACTIONBAR_PAGE_CHANGED")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")

local indicator = frame:CreateFontString(nil, "OVERLAY")
indicator:SetFont(FONT, FONT_SIZE, FONT_OUTLINE)
indicator:SetPoint(TEXT_ANCHOR, UIParent, PARENT_ANCHOR, X_OFFSET, Y_OFFSET)
indicator:SetTextColor(1, 1, 1)

frame:SetScript("OnEvent", function(self, event, ...)
    local currentPage = GetActionBarPage()

    if currentPage ~= 1 then
        indicator:SetText("ACTION BAR IS PAGED!")
        indicator:Show()
    else
        indicator:Hide()
    end
end)