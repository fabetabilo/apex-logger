-- module LOADING
local APP_CFG    = require("cfg/app")
local helpers    = require("src/utils/helpers")
local carDataMod = require("src/utils/car_data")
local aero       = require("src/utils/aero")
local appUI      = require("src/ui/ui_helpers")
local tabLogging = require("src/ui/tab_logging")
local tabData    = require("src/ui/tab_data")
local tabSettings = require("src/ui/tab_settings")
local tabAbout   = require("src/ui/tab_about")

require("src/classes/logger")

-- AC refs
local SIM     = ac.getSim()
local SESSION = ac.getSession(0)
local CPHYS   = ac.getCarPhysics(0)
local CAR     = ac.getCar(0)

local OSpreciseClock = os.preciseClock

-- app STATE
local appMain = {
    name    = APP_CFG.NAME,
    id      = string.lower(APP_CFG.NAME),
    version = APP_CFG.VERSION,
    folderPattern = APP_CFG.FOLDER_PATTERN,
    filePattern   = APP_CFG.FILE_PATTERN,
    urlUpdate = APP_CFG.URL_UPDATE,
    urlDocs   = APP_CFG.URL_DOCS,
    cspVersion = (ac.getPatchVersion() or "?") .. " (" .. (ac.getPatchVersionCode() or "?") .. ")",
    
    sessionName = "",
    sessionType = -1,
    trackLayout = "",
    spawnStart  = "",

    car = {
        hasAeromap    = false,
        aeroEncrypted = false,
        wheelBase     = 0,
        cogLocation   = 0,
        tyresAvail    = {},
    },
    detailData = {},
    mathItems  = {},
    
    pyAppLoaded = false,
    pyBuffer = {
        aeroDrag           = 0,
        aeroDownforceFront = 0,
        aeroDownforceRear  = 0,
        damperTravelFL = 0,
        damperTravelFR = 0,
        damperTravelRL = 0,
        damperTravelRR = 0,
        damperTravelHF = 0,
        damperTravelHR = 0,
    },
    
    icons = {
        ok      = "at:assets/icons/info.png",
        warning = "at:assets/icons/warn.png",
    },
    
    settings = {},
    settingsPath = "",
}


-- Settings ===========================================================
local ACDocuments = ac.getFolder(ac.FolderID.ACDocuments)
local driverName = ac.getDriverName(0) or "Player"

local defaultSettings = {
    enable          = false,
    driver          = driverName,
    drivers         = { driverName },
    dataRate        = 50,
    autoLoggingOffRace = false,
    forceRaceMode   = false,
}

-- settings persistence
appMain.settingsPath = ACDocuments .. "/apps/" .. appMain.id .. "/settings.json"

local function loadSettings()
    local path = appMain.settingsPath
    if io.fileExists(path) then
        local data = io.load(path)
        if data and data ~= "" then
            local parsed = JSON.parse(data)
            if parsed then
                -- merge with the defaults preserving new keys
                for k, v in pairs(defaultSettings) do
                    if parsed[k] == nil then
                        parsed[k] = v
                    end
                end

                appMain.settings = parsed
                return
            end
        end
    end
    -- if no valid settings, use defaults copy via JSON round-trip
    appMain.settings = JSON.parse(JSON.stringify(defaultSettings))
end

appMain.saveSettings = function()
    local jsonStr = helpers.jsonPretty(appMain.settings)
    io.saveAsync(appMain.settingsPath, jsonStr)
end


-- Python buffer management =======================================================
local function getPyBuffer()
    if not appMain.pyAppLoaded then return end
    -- from apex.py: "ac.ext_storeLua('apex.pySerialData')"
    local rawData = ac.load(appMain.id .. '.pySerialData')
    if rawData == nil or rawData == '' then return end
    
    local vals = rawData:split(',')
    if #vals < 9 then return end
    
    appMain.pyBuffer.aeroDrag           = tonumber(vals[1]) or 0
    appMain.pyBuffer.aeroDownforceFront = tonumber(vals[2]) or 0
    appMain.pyBuffer.aeroDownforceRear  = tonumber(vals[3]) or 0
    appMain.pyBuffer.damperTravelFL     = tonumber(vals[4]) or 0
    appMain.pyBuffer.damperTravelFR     = tonumber(vals[5]) or 0
    appMain.pyBuffer.damperTravelRL     = tonumber(vals[6]) or 0
    appMain.pyBuffer.damperTravelRR     = tonumber(vals[7]) or 0
    appMain.pyBuffer.damperTravelHF     = tonumber(vals[8]) or 0
    appMain.pyBuffer.damperTravelHR     = tonumber(vals[9]) or 0
end


-- Session management ================================================
appMain.updateSession = function()
    appMain.sessionName = helpers.getSessionType()
    appMain.sessionType = SIM.raceSessionType
    
    local layout = ac.getTrackLayout()
    if layout and layout ~= "" then
        appMain.trackLayout = ac.getTrackID() .. "-" .. layout
    else
        appMain.trackLayout = ac.getTrackID()
    end
end


-- ~ global functions used by logger to avoid circular requires
function getApexApp()     return appMain end
function getApexUI()      return appUI end
function getApexHelpers() return helpers end
function getApexAero()    return aero end


-- APP initialization =============================================
local appLogger = nil
local currentTab = 1

local tabs = {
    { name = "Logging" },
    { name = "Data" },
    { name = "Settings" },
    { name = "About" },
}

local function initApp()
    loadSettings()

    -- always require manual activation at session start
    appMain.settings.enable = false

    carDataMod.init(helpers)
    appMain.detailData, appMain.mathItems = carDataMod.getDetailData(appMain)
    appMain.car.tyresAvail = helpers.getTyresList()
    
    appMain.updateSession()
    appMain.spawnStart = ac.getSessionSpawnSet(SIM.currentSessionIndex) or ""

    appMain.car.hasAeromap = aero.hasAeromap(appMain.pyBuffer, appMain.car)
    if not appMain.car.aeroEncrypted then
        aero.loadAeroData(appMain.car)
    end
    
    appLogger = ApexLogger()
    appLogger:initialize()
    
    -- initialize UI tabs with its references
    tabLogging.init(appMain, appUI, appLogger, helpers)
    tabData.init(appMain, appUI)
    tabSettings.init(appMain, appUI, appLogger, helpers, APP_CFG)
    tabAbout.init(appMain, appUI)
    
    appMain.pyAppLoaded = ac.isPythonAppActive('apex')
    
    -- auto-off logging for race:
    if appMain.settings.autoLoggingOffRace
        and SIM.raceSessionType == ac.SessionType.Race then
        appMain.settings.enable = false
    end

    -- ensures lap directory exists for lap data files
    local lapsDir = ac.dirname() .. "\\laps"
    if not io.dirExists(lapsDir) then
        io.createDir(lapsDir)
    end
    
    -- clean old lap files:
    helpers.cleanLapsFiles(lapsDir, appLogger)
    
    appUI.updateUIlog(appMain.name .. " initialized", appUI.colors.MID_GREY)
    ac.log("Apex initialized")
end

initApp()


-- ============================================================================
-- AC functions
-- ============================================================================

--- app main UI render function
function script.main(dt)
    local title = appUI.getTitle(appMain, appLogger)
    ac.setWindowTitle('apex', title)
    
    currentTab = appUI.drawTabBar(tabs, currentTab)
    
    if currentTab == 1 then
        tabLogging.draw()
    elseif currentTab == 2 then
        tabData.draw()
    elseif currentTab == 3 then
        tabSettings.draw()
    elseif currentTab == 4 then
        tabAbout.draw()
    end
end

--- physics update function (which must be called at physics tick rate)
function script.update(dt)
    -- physics step logic
    if not appMain.settings.enable then return end
    
    getPyBuffer()
    
    if appLogger then
        appLogger:step(dt)
    end

end

--- session reset handler (called on teleport, restart, and others)
function script.reset()
    if appLogger and appLogger.logging then
        if appMain.settings.forceRaceMode then
            -- don't cancel in Race mode
        else
            appLogger:cancelStint()
        end
    end
end

--- session start handler
ac.onSessionStart(function(sessionType, sessionIndex)
    appMain.updateSession()
    appMain.sessionType = sessionType

    -- auto-off mode for race:
    if appMain.settings.autoLoggingOffRace and sessionType == ac.SessionType.Race then
        appMain.settings.enable = false
    end

    if appLogger then
        appLogger:resetStint()
        appLogger:setDatarates()
    end
end)

--- release handler (app closing)
ac.onRelease(function()
    if appLogger and appLogger.logging then
        appLogger:stop({ console = false, toast = false })
    end
    appMain.saveSettings()
end)
