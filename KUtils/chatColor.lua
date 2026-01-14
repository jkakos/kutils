-- Recolor outgoing whispers and Bnet whispers
local function colorModification(msg, event)
    -- local info
    -- local scale = 0.9
    local r, g, b

    if event == "CHAT_MSG_BN_WHISPER_INFORM" then
        --info = ChatTypeInfo["BN_WHISPER"]
        r, g, b = 0, 215, 255
    else
        --info = ChatTypeInfo["WHISPER"]
        r, g, b = 255, 102, 179
    end

    --[[ r = math.floor(info.r * 255 * scale)
    g = math.floor(info.g * 255 * scale)
    b = math.floor(info.b * 255 * scale) ]]--

    return string.format("|cff%02x%02x%02x%s|r", r, g, b, msg)
end

local function filterOutgoingWhisper(self, event, msg, sender, ...)
    msg = colorModification(msg, event)
    return false, msg, sender, ...
end

ChatFrame_AddMessageEventFilter("CHAT_MSG_WHISPER_INFORM", filterOutgoingWhisper)
ChatFrame_AddMessageEventFilter("CHAT_MSG_BN_WHISPER_INFORM", filterOutgoingWhisper)
