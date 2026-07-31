local SIM = ac.getSim()
local CAR = ac.getCar(0)

local tabSettings = {}

local appState, appUI, appLogger, helpers, APP_CFG

--- Initialize with app references
---@param state table appMain
---@param ui table UI helpers module
---@param logger table ApexLogger instance
---@param helpersRef table helpers module
---@param appCfg table APP config constants
tabSettings.init = function(state, ui, logger, helpersRef, appCfg)
    appState  = state
    appUI     = ui
    appLogger = logger
    helpers   = helpersRef
    APP_CFG   = appCfg
end

-- Data rate sampling management ===============================================
local function drawRateCombo(label, currentRate, callback)
    ui.setNextItemWidth(70)
    ui.combo(label, tostring(currentRate) .. " Hz", function()
        for _, rate in ipairs(APP_CFG.DATA_RATES) do
            if ui.selectable(tostring(rate) .. " Hz", rate == currentRate) then
                callback(rate)
                appState.saveSettings()
            end
        end
    end)
end

-- Driver management =========================================================
local function drawDriverCombo()
    -- calculate width for combo so it stretches while leaving room for buttons
    local buttonSpace = 120 
    ui.setNextItemWidth(ui.availableSpaceX() - buttonSpace)
    
    ui.combo("##driverSel", appState.settings.driver, function()
        for i, name in ipairs(appState.settings.drivers) do
            if ui.selectable(name, name == appState.settings.driver) then
                appState.settings.driver = name
                appState.saveSettings()
            end
        end
    end)
    appUI.tooltip("Select active driver")

    -- add driver button:
    ui.sameLine()
    if ui.button("Add##addDriver") then
        ui.modalPrompt('Add Driver', 'Enter driver name:', '', function(name)
            if not name or name == "" then return end
            local sanitized = helpers.validateDriverName(name)
            if sanitized ~= "" and not table.contains(appState.settings.drivers, sanitized) then
                table.insert(appState.settings.drivers, sanitized)
                appState.settings.driver = sanitized
                appState.saveSettings()
            end
        end)
    end
    appUI.tooltip("Add a new driver")

    -- delete driver button:
    ui.sameLine()
    if ui.button("Delete##delDriver") then
        if #appState.settings.drivers > 1 then
            ui.modalPopup('Delete Driver', 'Delete driver: ' .. appState.settings.driver .. '?', function(okPressed)
                if okPressed then
                    local idx = table.indexOf(appState.settings.drivers, appState.settings.driver)
                    if idx then table.remove(appState.settings.drivers, idx) end
                    appState.settings.driver = appState.settings.drivers[1] or "Driver"
                    appState.saveSettings()
                end
            end)
        end
    end
    appUI.tooltip("Delete current driver")
end


-- ============================================================================
-- Settings tab draw
-- ============================================================================

tabSettings.draw = function()
    ui.pushStyleVar(ui.StyleVar.IndentSpacing, 12)
    
    -- Driver information
    ui.text("Driver Information")
    ui.offsetCursorY(5)
    
    drawDriverCombo()
    
    ui.offsetCursorY(5)
    ui.separator()
    
    -- PYTHON buffer information
    ui.text("Python Buffer")
    ui.offsetCursorY(5)
    
    ui.text("Status")
    ui.sameLine(80)
    
    if appState.pyAppLoaded then
        ui.pushStyleColor(ui.StyleColor.Text, appUI.colors.GREEN)
        ui.text("active")
        ui.popStyleColor()
        appUI.tooltip("Python app is active")
    else
        ui.pushStyleColor(ui.StyleColor.Text, appUI.colors.ORANGE)
        ui.text("inactive")
        ui.popStyleColor()
        appUI.tooltip("Python app is inactive")
    end
    
    ui.offsetCursorY(5)
    ui.separator()
    
    -- Data sampling rates information
    ui.text("Data Sampling")
    ui.offsetCursorY(5)

    drawRateCombo("##rateMain", appState.settings.dataRate, function(rate)
        appState.settings.dataRate = rate
        if appLogger then appLogger:setDatarates() end
    end)
    ui.sameLine()
    ui.text("Rate")
    appUI.tooltip("Choose max data sampling rate")

    ui.offsetCursorY(5)
    ui.separator()
    

    -- MODE options
    ui.text("Mode")
    ui.offsetCursorY(5)

    if ui.checkbox("Auto off logging", appState.settings.autoLoggingOffRace) then
        appState.settings.autoLoggingOffRace = not appState.settings.autoLoggingOffRace
        appState.saveSettings()
        appUI.updateUIlog("Auto off logging mode: " .. (appState.settings.autoLoggingOffRace and "active" or "inactive"), appUI.colors.GREY)
    end
    appUI.tooltip("Automatically disable logging when entering a race session")

    if ui.checkbox("Race Mode", appState.settings.forceRaceMode) then
        appState.settings.forceRaceMode = not appState.settings.forceRaceMode
        appState.saveSettings()
        appUI.updateUIlog("Race mode: " .. (appState.settings.forceRaceMode and "active" or "inactive"), appUI.colors.GREY)
    end
    appUI.tooltip("Forcing race mode will always log, no auto-stop in pit, no restart. Stays recording until session end or disabled.")

    ui.offsetCursorY(5)
    ui.separator()
    
    ui.text("TX UDP Telemetry")
    ui.offsetCursorY(5)
    
    ui.setNextItemWidth(120)
    local newHost, hostChanged = ui.inputText("IP Address", appState.settings.udpHost)
    if hostChanged then
        appState.settings.udpHost = newHost
        appState.saveSettings()
        if appLogger and appLogger.udpSender then
            appLogger.udpSender.configure(appState.settings)
        end
    end
    
    ui.setNextItemWidth(120)
    local newPort, portChanged = ui.inputText("Port", tostring(appState.settings.udpPort), ui.InputTextFlags.CharsDecimal)
    if portChanged then
        appState.settings.udpPort = tonumber(newPort)
        appState.saveSettings()
        if appLogger and appLogger.udpSender then
            appLogger.udpSender.configure(appState.settings)
        end
    end

    ui.offsetCursorY(5)
    ui.separator()
    
    -- Shortcut buttons
    ui.text("Shortcuts")
    ui.offsetCursorY(5)

    if ui.button("Open settings file##openSettings", vec2(ui.availableSpaceX(), 22)) then
        os.openInExplorer(appState.settingsPath)
    end

    ui.popStyleVar()
end

return tabSettings
