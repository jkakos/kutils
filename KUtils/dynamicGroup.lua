KAKOS.getMaxIcons = function(rowLimit)
    --calculate the number of icons allowed to be displayed
    local totalAllowedIcons = 0  --num total icons to show
    local cumulRowLimit = {}  --cumulative row limits
    
    for i = 1, #rowLimit do        
        totalAllowedIcons = totalAllowedIcons + rowLimit[i]
        cumulRowLimit[i] = totalAllowedIcons
    end
    return totalAllowedIcons, cumulRowLimit
end

KAKOS.getIconsPerRow = function(numIcons, rowLimit, totalAllowedIcons, cumulRowLimit)
    --calculate the number of icons on each row given the total number of icons
    local iconsPerRow = {}
    for i = 1, #rowLimit do
        if (
            numIcons > totalAllowedIcons
            or numIcons - (cumulRowLimit[i-1]
            or 0) > rowLimit[i]
        ) then
            iconsPerRow[i] = rowLimit[i]
        else
            iconsPerRow[i] = numIcons - (cumulRowLimit[i-1] or 0)
        end
    end
    return iconsPerRow
end

KAKOS.getRowXLeft = function(iconsPerRow, iconSize, spacing) 
    --calculate the left position based on the number of icons in the row
    local xLeft = {} --where the left edge of the row will start
    for i = 1, #iconsPerRow do
        local offset = (iconSize[i] + spacing) / 2
        xLeft[i] = -(iconsPerRow[i] * (iconSize[i] + spacing)) / 2 + offset      
    end
    return xLeft   
end

KAKOS.getIconY = function(rowIdx, iconSize, spacing)
    --calculate the vertical position based on the row number
    local y = 0
    
    if rowIdx == 1 then
        return y  --keep starting row ay y = 0
    end
    
    for i = 1, rowIdx do
        y = y - iconSize[i]
    end
    return (
        y - spacing * (rowIdx - 1) + iconSize[1] / 2  + iconSize[rowIdx] / 2
    )
end

KAKOS.growFunc = function(newPositions, activeRegions, rowLimit, iconSize, spacing, zoom)
    --Main grow function for dynamic groups. This will create rows of icons with a
    --number of icons on each row determined by 'rowLimit'.
    --Parameters:
    --  newPositions, activeRegions are passed by WeakAuras for the custom
    --    grow function
    --  rowLimit: table of int, the length determines the number of rows
    --    and the values determine the number of icons on each row
    --  iconSize: table of int, should have the same shape as 'rowLimit'
    --    and each value sets the size of icons on each row
    --  spacing: int, amount of spacing between icons and rows
    --  zoom: float from 0 to 1, sets the zoom on icons (e.g., 0.25 sets 25% zoom) 
    local numIcons = #activeRegions  --num total icons in the group
    
    --find the number of icons that will be on each row
    local totalAllowedIcons, cumulRowLimit = KAKOS.getMaxIcons(rowLimit)
    local iconsPerRow = KAKOS.getIconsPerRow(numIcons, rowLimit, totalAllowedIcons, cumulRowLimit)
    
    --set the left position based on the number of icons in the row
    local xLeft = KAKOS.getRowXLeft(iconsPerRow, iconSize, spacing)
    
    local rowIdx = 1
    for i, regionData in ipairs(activeRegions) do
        local region = regionData.region
        
        --remove visual of any auras exceeding the set limit
        if i > totalAllowedIcons then
            break
        end
        
        --move to next row if necessary
        if i > cumulRowLimit[rowIdx] then
            rowIdx = rowIdx + 1
        end
        
        --place icons going from xLeft to the right using iconSize and spacing
        -- and set the y position based on the row    
        local xNew = (
            xLeft[rowIdx]
            + ((i-1) - (cumulRowLimit[rowIdx-1] or 0)) * (iconSize[rowIdx]
            + spacing)
        )
        local yNew = KAKOS.getIconY(rowIdx, iconSize, spacing)
        
        --update aura parameters
        region:SetWidth(iconSize[rowIdx])
        region:SetHeight(iconSize[rowIdx])        
        region:SetZoom(zoom)
        newPositions[i] = {xNew, yNew}
    end
end