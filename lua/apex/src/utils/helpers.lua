local SIM = ac.getSim()
local CAR = ac.getCar(0)

-- CSP 0.3 breaks json with {pretty = true}, so we use the bundled lib: 
-- Credits and more information about the lib in the json.lua package file
local jsonUtils = require("assets/libs/json")

-- local pointer aliases for performance:
local STRformat    = string.format
local Mabs         = math.abs
local Mfloor       = math.floor
local OSpreciseClock = os.preciseClock

local helpers = {}

-- ============================================================================
-- AC utility helpers
-- ============================================================================

--- Get session type string, for example: Practice.offline, Race.online, among others
---@return string
helpers.getSessionType = function()
    local sessionType = table.indexOf(ac.SessionType, SIM.raceSessionType)
    if CAR.sessionID ~= -1 then
        return sessionType .. ".online"
    else
        return sessionType .. ".offline"
    end
end

--- Get user input mode as readable string
---@return string "Wheel"|"Gamepad"|"Keyboard"|"Unknown"
helpers.getInputMode = function()
    if SIM.inputMode == ac.UserInputMode.Wheel then return "Wheel"
    elseif SIM.inputMode == ac.UserInputMode.Gamepad then return "Gamepad"
    elseif SIM.inputMode == ac.UserInputMode.Keyboard then return "Keyboard"
    end
    return "Unknown"
end

--- Get available tyre compound names for the current car
---@return table list of tyre names
helpers.getTyresList = function()
    for _, v in pairs(ac.getSetupSpinners()) do
        if v.name == "COMPOUND" then
            return v.items
        end
    end
    return {ac.getTyresName(0, -1)}
end

--- Try to open the CSP lua debug console
helpers.openLuaDebug = function()
    local luadebugWin = ac.accessAppWindow("IMGUI_CSP_LUA_DEBUG")
    if luadebugWin == nil then return end
    luadebugWin:setVisible(true)
end

--- Get imgui window internal name for ac.AppWindowAccessor
---@param name string display name
---@return string|boolean internal name or false
helpers.getWindowName = function(name)
    local wins = ac.getAppWindows()
    for _, v in pairs(wins) do
        if v.title == name then
            return v.name
        end
    end
    return false
end

--- Set the python companion app as active in AC's python.ini (requires restart)
---@param appName string
helpers.setPythonAppActive = function(appName)
    appName = appName or 'apex'
    local iniAppName = string.upper(appName)
    local iniPath = ac.getFolder(ac.FolderID.ACDocuments) .. "\\cfg\\python.ini"
    local iniPython = ac.INIConfig.load(iniPath)
    local iniActive = iniPython:get(iniAppName, 'ACTIVE', -1)
    if iniActive < 1 then
        iniPython:set(iniAppName, 'ACTIVE', 1)
        iniPython:save()
    end
end

-- String & format helpers ====================================

--- Sanitize a name for use as filename (removes special chars, reserved names)
---@param name string
---@return string sanitized name
helpers.validateDriverName = function(name)
    local sanitized = name:gsub('[^%w%s]', '')
    sanitized = sanitized:match("^%s*(.-)%s*$")
    sanitized = sanitized:gsub('[%c]', '')
    sanitized = sanitized:gsub('[%.%s]+$', '')

    local reserved = {
        ["CON"] = true, ["PRN"] = true, ["AUX"] = true, ["NUL"] = true,
        ["COM1"] = true, ["COM2"] = true, ["COM3"] = true, ["COM4"] = true,
        ["COM5"] = true, ["COM6"] = true, ["COM7"] = true, ["COM8"] = true, ["COM9"] = true,
        ["LPT1"] = true, ["LPT2"] = true, ["LPT3"] = true, ["LPT4"] = true,
        ["LPT5"] = true, ["LPT6"] = true, ["LPT7"] = true, ["LPT8"] = true, ["LPT9"] = true,
    }
    if reserved[sanitized:upper()] then
        sanitized = "Driver_" .. sanitized
    end

    return sanitized
end

--- Convert an already-validated driver name into a filesystem-safe path replacing spaces with "_"
---@param name string
---@return string
helpers.sanitizeForPath = function(name)
    if not name or name == "" then return "unknown" end
    return name:gsub("%s+", "_")
end

--- Convert seconds to readable lap time string, example: "1:23.456"
---@param time_s number seconds
---@return string
helpers.time_to_string = function(time_s)
    if time_s == nil or time_s == 0 then return "--.---" end
    local minutes = Mfloor(time_s / 60)
    time_s = time_s - minutes * 60
    if minutes > 0 then
        return STRformat("%d:%06.3f", minutes, time_s)
    else
        return STRformat("0:%06.3f", time_s)
    end
end

--- JSON prettifier, which uses bundled json library
---@param obj any table to serialize
---@return string pretty JSON
helpers.jsonPretty = function(obj)
    return jsonUtils:encode_pretty(obj)
end

--- Get 3D distance between two vec3 points
---@param pt1 vec3
---@param pt2 vec3
---@return number
helpers.distance3d = function(pt1, pt2)
    local dx = pt2.x - pt1.x
    local dy = pt2.y - pt1.y
    local dz = pt2.z - pt1.z
    return math.sqrt(dx * dx + dy * dy + dz * dz)
end

--- Shallow copy of an array table
---@param list table
---@return table
helpers.copyList = function(list)
    local copy = {}
    for i, v in ipairs(list) do copy[i] = v end
    return copy
end

-- File operations =================================================

--- Delete orphan lap .csv files of the older per-lap format, not referenced by any log_*.json.
--- Stint files need no cleanup: invalid or cancelled stints delete their .csv when they end,
--- and a stint .csv without its .json (game crash) is kept so its data can be recovered.
---@param lapFolder string path to laps directory
helpers.cleanLapsFiles = function(lapFolder)
    try(
        function()
            local keep = {}
            local function keepFiles(lapFiles)
                for _, path in ipairs(lapFiles or {}) do
                    keep[path:match("[^\\/]+$")] = true
                end
            end

            local unreadable = false
            io.scanDir(lapFolder, "log_*.json", function(fileName)
                local jsonlog = JSON.parse(io.load(lapFolder .. "\\" .. fileName) or "")
                if type(jsonlog) == "table" then
                    keepFiles(jsonlog.lapFiles)
                else
                    unreadable = true
                end
            end)
            -- never delete laps an unreadable log may reference
            if unreadable then return end

            local orphans = {}
            io.scanDir(lapFolder, "lap_*.csv", function(fileName)
                if not keep[fileName] then
                    orphans[#orphans + 1] = lapFolder .. "\\" .. fileName
                end
            end)
            for _, fPath in ipairs(orphans) do
                io.deleteFile(fPath)
            end
        end,
        function(err)
            -- silently ignore cleanup errors
        end
    )
end

--- Recursively clean empty folders from root path
---@param rootPath string
helpers.cleanEmptyFolders = function(rootPath)
    io.scanDir(rootPath, "*", function(name, attr)
        local fullPath = rootPath .. "/" .. name
        if attr.isDirectory then
            helpers.cleanEmptyFolders(fullPath)
        end
    end)

    local isEmpty = true
    io.scanDir(rootPath, "*", function(name, attr)
        isEmpty = false
    end)

    if isEmpty then
        io.deleteDir(rootPath)
    end
end

-- ============================================================================
-- Toast Notifications
-- ============================================================================

--- Show a toast notification in-game while running
---@param icon any AC icon (e.g. ui.Icons.Flag)
---@param msg string message
---@param buttonIcon any optional button icon
---@param buttonTitle string optional button text
---@param buttonCallback function optional button handler
helpers.notify = function(appName, icon, msg, buttonIcon, buttonTitle, buttonCallback)
    if not icon or not msg then return end
    buttonTitle = buttonTitle or ''

    if buttonIcon then
        ui.toast(icon, appName .. ': ' .. msg):button(buttonIcon, buttonTitle, buttonCallback)
    else
        ui.toast(icon, appName .. ': ' .. msg)
    end
end

return helpers
