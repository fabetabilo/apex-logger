local SIM = ac.getSim()
local CAR = ac.getCar(0)

local tabLogging = {}

local appState, appUI, appLogger, helpers

--- Initialize with app references
---@param state table appMain
---@param ui table UI helpers module
---@param logger table ApexLogger instance
---@param helpersRef table helpers module
tabLogging.init = function(state, ui, logger, helpersRef)
    appState  = state
    appUI     = ui
    appLogger = logger
    helpers   = helpersRef
end


-- ============================================================================
-- Logging Tab draw
-- ============================================================================

tabLogging.draw = function()
    
    ui.pushStyleVar(ui.StyleVar.IndentSpacing, 12)
    ui.text("Logger Mode")
    ui.offsetCursorY(5)

    -- Local logging enable
    local logColor = appState.settings.enable and appUI.colors.WHITE
    ui.pushStyleColor(ui.StyleColor.FrameBg, rgbm(0.2, 0.2, 0.2, 1))
    ui.pushStyleColor(ui.StyleColor.CheckMark, logColor)

    if ui.checkbox("LOG", appState.settings.enable) then
        appState.settings.enable = not appState.settings.enable
        if not appState.settings.enable and appLogger and appLogger.logging then
            appLogger:cancelStint()
        end
        appState.saveSettings()
    end
    ui.popStyleColor(2)
    appUI.tooltip("Enable local lap logging")

    --- log mode status indicator square
    ui.sameLine(ui.windowWidth() - 40)
    local stateColor, stateText = appUI.getStatusColorAndText(appState, appLogger)
    local boxSize = 22 -- standard UI frame height
    local p = ui.getCursor()
    
    ui.dummy(vec2(boxSize, boxSize))
    ui.drawRectFilled(p, p + vec2(boxSize, boxSize), stateColor, 0) -- 0px for no rounded borders
    if ui.itemHovered() then
        appUI.tooltip("LOG status: " .. stateText)
    end

    -- TX live telemetry enable
    local txColor = appState.settings.udpEnable and appUI.colors.WHITE
    ui.pushStyleColor(ui.StyleColor.FrameBg, rgbm(0.2, 0.2, 0.2, 1))
    ui.pushStyleColor(ui.StyleColor.CheckMark, txColor)

    if ui.checkbox("TX", appState.settings.udpEnable) then
        appState.settings.udpEnable = not appState.settings.udpEnable
        appState.saveSettings()
        if appLogger and appLogger.udpSender then
            appLogger.udpSender.configure(appState.settings)
        end
    end
    ui.popStyleColor(2)
    appUI.tooltip("Enable live UDP telemetry")

    -- Python companion status and session general info
    if not appState.pyAppLoaded then
        ui.pushStyleColor(ui.StyleColor.Text, appUI.colors.ORANGE)
        ui.text(ui.Icons.Warning .. " Python buffer not loaded")
        ui.popStyleColor()
        appUI.tooltip("Requires session restart")
    else
        ui.pushStyleColor(ui.StyleColor.Text, appUI.colors.MID_GREY)
        ui.text(appState.sessionName .. " at " .. (appState.trackLayout or ac.getTrackID()))
        ui.popStyleColor()
    end
    
    -- Clear Console button
    ui.sameLine(ui.windowWidth() - 115)
    if ui.button("Clear Console##clearLog") then
        appUI.resetUIlog()
    end
    appUI.tooltip("Clear UI console log")

    ui.separator()

    -- UI Log 
    appUI.drawUIlog(ui.availableSpaceY() - 4)
end

return tabLogging
