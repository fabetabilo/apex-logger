-- module LOADING
local APP_CFG    = require("cfg/app")
local helpers    = require("src/utils/helpers")
local appUI      = require("src/ui/ui_helpers")
local tabSettings = require("src/ui/tab_settings")
local tabAbout   = require("src/ui/tab_about")

-- AC refs
local SIM     = ac.getSim()
local SESSION = ac.getSession(0)
local CPHYS   = ac.getCarPhysics(0)
local CAR     = ac.getCar(0)

-- app STATE
local appMain = {
    name    = APP_CFG.NAME,
    id      = string.lower(APP_CFG.NAME),
    version = APP_CFG.VERSION,
    
    settings = {},
}

-- APP initialization =============================================
local appLogger = nil
local currentTab = 1

local tabs = {
    { name = "Settings" },
    { name = "About" },
}

local function initApp()
    tabSettings.init(appMain, appUI, appLogger, helpers, APP_CFG)
    tabAbout.init(appMain, appUI)
    ac.log("Apex initialized")
end

initApp()


-- ============================================================================
-- AC functions
-- ============================================================================

--- app main UI render function
function script.main(dt)
    local title = appMain.name .. ' v' .. appMain.version
    ac.setWindowTitle('apex', title)
    
    currentTab = appUI.drawTabBar(tabs, currentTab)
    
    if currentTab == 1 then
        tabSettings.draw()
    elseif currentTab == 2 then
        tabAbout.draw()
    end
end

--- physics update function (which must be called at physics tick rate)
function script.update(dt)
    -- physics step logic
end

--- session reset handler (called on teleport, restart, and others)
function script.reset()
end

--- session start handler
ac.onSessionStart(function(sessionType, sessionIndex)
end)

--- release handler (app closing)
ac.onRelease(function()
end)
