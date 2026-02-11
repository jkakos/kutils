local _, addon = ...

-- Decide when to show or hide icons
function addon:HookButtonVisibility(button, viewer)
    if button._addonVisHooked then return end
    button._addonVisHooked = true

    button:HookScript("OnShow", function(self)
        addon:EnforceVisibility(self, viewer)
    end)
end

-- Remove desaturation on cooldown and set cooldown swipe properties
function addon:HookCooldownSwipeStyle(button)
    if button._addonCooldownSwipeHooked then return end
    button._addonCooldownSwipeHooked = true

    hooksecurefunc(button.Icon, "SetDesaturated", function(self, desat)
        if self._addonInDesatHook then return end
        addon:StyleCooldownDesaturate(self)
    end)

    hooksecurefunc(button, "RefreshActive", function(self)
        addon:StyleCooldownSwipe(self)
    end)
end

-- Define which config flags trigger which functions
local hookMap = {
    hookCooldownSwipe      = "HookCooldownSwipeStyle",
    hookButtonVisibility   = "HookButtonVisibility",
    styleChargeFont        = "StyleChargeFont",
    styleCooldownTimerFont = "StyleCooldownTimerFont",
    styleApplicationsFont  = "StyleApplicationsFont",
    setGlowSize            = "SetButtonGlowSize",
}

-- Apply icon hooks
local function SetUpIconViewerHooks(viewer, config, buttonHookScripts)
    hooksecurefunc(viewer, "RefreshLayout", function(self)
        local buttons = self:GetItemFrames()
        if not buttons then return end

        addon:LayoutIcons(self)

        for _, button in ipairs(buttons) do
            if not button._addonHooked then
                button._addonHooked = true

                -- Apply hooks based on hookMap flags
                for flag, funcName in pairs(hookMap) do
                    if config[flag] and addon[funcName] then
                        addon[funcName](addon, button, self)
                    end
                end

                -- Handle functions with additional parameters
                if config.addInnerBorder then
                    addon:AddIconInnerBorder(button, config.borderThickness, config.borderColor)
                end
                if config.addBackground then
                    addon:AddIconBackground(button, config.backgroundColor)
                end

                -- Apply button hookscripts
                if buttonHookScripts then
                    for script, func in pairs(buttonHookScripts) do
                        button:HookScript(script, func)
                    end
                end
            end
        end
    end)
end

-- Essential Icons
local function HookEssentialCooldownViewer()
    SetUpIconViewerHooks(EssentialCooldownViewer, addon.essentialConfig)
end

-- Utility Icons
local function HookUtilityCooldownViewer()
    SetUpIconViewerHooks(UtilityCooldownViewer, addon.utilityConfig)
end

-- Buff Icons
local function HookBuffIconCooldownViewer()
    local buttonHookScripts = {
        OnShow = function() addon:LayoutIcons(BuffIconCooldownViewer) end,
        OnHide = function() addon:LayoutIcons(BuffIconCooldownViewer) end,
    }
    SetUpIconViewerHooks(BuffIconCooldownViewer, addon.buffIconConfig, buttonHookScripts)
end

-- Buff Bars
local function HookBuffBarCooldownViewer()
    hooksecurefunc(BuffBarCooldownViewer, "RefreshLayout", function(self)
        addon:LayoutBuffBars(self)

        for _, entry in ipairs({self:GetChildren()}) do
            if not entry._addonHooked then
                entry._addonHooked = true
                addon:StyleBuffBar(entry)
                entry:HookScript("OnShow", function() addon:LayoutBuffBars(self) end)
                entry:HookScript("OnHide", function() addon:LayoutBuffBars(self) end)
            end

            if entry.Bar then
                local bar = entry.Bar
                local _, _, _, _, barTexture = bar:GetRegions()
                if barTexture then
                    addon:ColorBarTexture(barTexture)
                end
            end
        end
    end)
end

-- Hide spell glows on the action bars
hooksecurefunc(ActionButtonSpellAlertManager, "ShowAlert", function(_, button)
    local action = button.action
    if not action then return end

    local spellType, id = GetActionInfo(action)

    if id and (spellType == "spell" or spellType == "macro") then
        if C_ActionBar.IsAssistedCombatAction(action) then
            -- Hide matched glows on the Single-Button Assistant button
            local alert = button.AssistedCombatRotationFrame and button.AssistedCombatRotationFrame.SpellActivationAlert
            if alert then alert:Hide() end
        elseif button.SpellActivationAlert then
            -- Hide matched glows on regular action bars
            button.SpellActivationAlert:Hide()
        end
    end
end)

-- Hook the cast bar
local function HookCastBar()
    local bar = PlayerCastingBarFrame
    if not bar or bar._addonHooksApplied then return end
    bar._addonHooksApplied = true

    -- Style and position the cast bar
    addon:LayoutCastBar()
    addon:StyleCastBar()

    -- Reposition on show
    bar:HookScript("OnShow", function()
        addon.castBarInterrupted = false
        addon:LayoutCastBar()
        addon:StyleCastBar()
    end)

    -- Update timer text
    bar:HookScript("OnUpdate", function(self) addon:StyleCastBarTimerText(self) end)

    -- Update spell text and ensure it doesn't run into the timer text
    hooksecurefunc(bar.Text, "SetText", function(fontstring, text)
        if fontstring._addonUpdating then return end
        if not text then return end
        addon:StyleCastBarSpellText(fontstring, text)
    end)

    -- Reapply texture any time it updates
    hooksecurefunc(bar, "SetStatusBarTexture", function(self) addon:StyleCastBarTexture(self) end)

    -- Hide cast spark
    hooksecurefunc(bar, "ShowSpark", function(self)
        if self.Spark then self.Spark:Hide() end
        if self.StandardGlow then self.StandardGlow:Hide() end
        if self.ChannelShadow then self.ChannelShadow:Hide() end
    end)

    -- Recolor the cast bar if a spell has been interruppted
    hooksecurefunc(bar, "PlayInterruptAnims", function(self)
        addon.castBarInterrupted = true
        addon:StyleCastBarTexture(self)
    end)
    hooksecurefunc(bar, "StopInterruptAnims", function(self)
        addon.castBarInterrupted = false
        addon:StyleCastBarTexture(self)
    end)
end

-- Apply hooks
function addon:ApplyHooks()
    HookEssentialCooldownViewer()
    HookUtilityCooldownViewer()
    HookBuffIconCooldownViewer()
    HookBuffBarCooldownViewer()
    HookCastBar()
end
