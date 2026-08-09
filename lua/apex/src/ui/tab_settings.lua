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
        if appLogger then appLogger:setRates() end
    end)
    ui.sameLine()
    ui.text("Rate")
    appUI.tooltip("Choose max data sampling rate")

    ui.offsetCursorY(5)
    ui.separator()
    
    -- Channel group selection
    ui.text("Channel Groups")
    ui.offsetCursorY(5)

    local cg = appState.settings.channelGroups
    if cg then
        ui.pushStyleColor(ui.StyleColor.Text, appUI.colors.MID_GREY)
        ui.text("1 Hz")
        ui.popStyleColor()
        ui.indent(12)
        if ui.checkbox("Session##cg_session", cg.session ~= false) then
            cg.session = not (cg.session ~= false)
            appState.saveSettings()
        end
        appUI.tooltip("Ambient conditions: air, road temp, grip, wind, weather and session flags")
        
        if ui.checkbox("Car Info##cg_car_info", cg.car_info ~= false) then
            cg.car_info = not (cg.car_info ~= false)
            appState.saveSettings()
        end
        appUI.tooltip("Fuel, ABS, TC modes, tire wear, damage, engine, gearbox health, temps")
        ui.unindent(12)
        
        
        ui.offsetCursorY(3)
        ui.pushStyleColor(ui.StyleColor.Text, appUI.colors.MID_GREY)
        ui.text("10 Hz")
        ui.popStyleColor()
        ui.indent(12)
        if ui.checkbox("Tires & Brakes##cg_tires", cg.tires ~= false) then
            cg.tires = not (cg.tires ~= false)
            appState.saveSettings()
        end
        appUI.tooltip("Tire temps, pressures, grain, blisters and brake temps")
        
        if ui.checkbox("Car Dynamics##cg_dyn", cg.dyn ~= false) then
            cg.dyn = not (cg.dyn ~= false)
            appState.saveSettings()
        end
        appUI.tooltip("Drivetrain info: torque, power and speed")

        if ui.checkbox("Ext. Electronics##cg_ext_elec", cg.ext_elec ~= false) then
            cg.ext_elec = not (cg.ext_elec ~= false)
            appState.saveSettings()
        end
        appUI.tooltip("Extended Electronics: DRS, ERS/KERS deploy, charge and input info")

        if ui.checkbox("Aerodynamic##cg_aero", cg.aero ~= false) then
            cg.aero = not (cg.aero ~= false)
            appState.saveSettings()
        end
        appUI.tooltip("Aero drag, front and rear downforce")
         
        if ui.checkbox("Sim Info##cg_sim_info", cg.sim_info ~= false) then
            cg.sim_info = not (cg.sim_info ~= false)
            appState.saveSettings()
        end
        appUI.tooltip("Sim health info: FFB, FPS, physics late, CPU time")
        ui.unindent(12)
        
        
        ui.offsetCursorY(3)
        ui.pushStyleColor(ui.StyleColor.Text, appUI.colors.MID_GREY)
        ui.text("30 Hz")
        ui.popStyleColor()
        ui.indent(12)
        if ui.checkbox("Inputs##cg_input", cg.input ~= false) then
            cg.input = not (cg.input ~= false)
            appState.saveSettings()
        end
        appUI.tooltip("Throttle, brake, steer, clutch, gear, rpm, speed, track live pos, lap live data, brake torques, turbo")
        
        if ui.checkbox("GPS##cg_gps", cg.gps ~= false) then
            cg.gps = not (cg.gps ~= false)
            appState.saveSettings()
        end
        appUI.tooltip("World position, local velocity, pitch, roll, yaw rates and angles, and car heading")
        
        if ui.checkbox("Tire Dynamics##cg_tires_dyn", cg.tires_dyn ~= false) then
            cg.tires_dyn = not (cg.tires_dyn ~= false)
            appState.saveSettings()
        end
        appUI.tooltip("Wheel angular speeds, tire loads, loaded radius, tire slip angle & ratio, lateral & longitudinal forces")
        
        if ui.checkbox("G-Force##cg_gforce", cg.gforce ~= false) then
            cg.gforce = not (cg.gforce ~= false)
            appState.saveSettings()
        end
        appUI.tooltip("CG accelerations: lateral, longitudinal, vertical")
        ui.unindent(12)
        
        -- user customizable Hz
        ui.offsetCursorY(3)
        ui.pushStyleColor(ui.StyleColor.Text, appUI.colors.MID_GREY)
        ui.text(tostring(appState.settings.dataRate) .. " Hz (Customizable)")
        ui.popStyleColor()
        ui.indent(12)
        if ui.checkbox("Suspension##cg_susp", cg.susp ~= false) then
            cg.susp = not (cg.susp ~= false)
            appState.saveSettings()
        end
        appUI.tooltip("Ride heights (front and rear), CG height, suspension travel, aligning torques, dampers, caster, camber and toe")
        ui.unindent(12)
    end
    
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
