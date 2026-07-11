-- module LOADING
local APP_CFG    = require("cfg/app")

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
}

local function initApp()
    ac.log("Apex initialized")
end

initApp()


-- ============================================================================
-- AC functions
-- ============================================================================

--- app main UI render function
function script.main(dt)
    ac.setWindowTitle('apex', appMain.name .. ' v' .. appMain.version)
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
