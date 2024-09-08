KAKOS.getSpecColor = function(className, specId)
    --get (r, g, b) values to use for a given class spec
    specColors = {
	    ["Druid"] = {{0.30, 0.52, 1.00}, {1.00, 0.49, 0.04}, {1.00, 0.49, 0.04}, {0.13, 0.68, 0.19}},
        ["Mage"] = {{0.7, 0.3, 1.0}, {1.00, 0.38, 0.00}, {0.0, 0.5, 1.0}},
		["Monk"] = {{0.0, 1.0, 0.6}, {0.0, 1.0, 0.6}, {0.0, 1.0, 0.6}},
		["Death Knight"] = {{0.77, 0.12, 0.23}, {0.0, 0.5, 1.0}, {0.4, 0.76, 0.28}},
    }
    return unpack(specColors[className][specId])
end

KAKOS.castBarCustomText = function(spellName, lenLimit)
    --Show the name of the cast on the cast bar truncated at 'lenLimit' characters.
    if spellName then
        if string.len(spellName) > lenLimit then
            return string.sub(spellName, 1, lenLimit) .. "..."
        else
            return spellName
        end
    else
        return ""
    end
end

KAKOS.sendMsg = function(...)
	--This accepts any number of strings as inputs. This can be used to input a
	--sequence of "/way x y" to make many TomTom waypoints at once.
	local messages = {...}
	for i, msg in ipairs(messages) do
		ChatFrame_OpenChat("")
		local edit = ChatEdit_GetActiveWindow();
		edit:SetText(msg)
		ChatEdit_SendText(edit,1)
		ChatEdit_DeactivateChat(edit)
	end
end