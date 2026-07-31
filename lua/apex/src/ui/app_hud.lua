-- HUD app subwindow status to show real-time logger status indicators
--  Indicators:
--      TX:  blinks while UDP is active (settings.udpEnable == true)
--      LOG: solid dot while logger is recording laps (appLogger.logging == true), also shows the standby status of the logger

local statusHud = {}

local _app = nil
local _logger = nil

--- blink state for indicator:
local _blinkTimer = 0
local _blinkOn = true
local _blinkPeriod = 0.5  -- seconds per half-cycle (total cycle = 1s)

local IMG_BG = "apps/lua/apex/assets/img/hud_bg.png"
local IMG_DESIGN = "apps/lua/apex/assets/img/design.png"
local FONT = ui.DWriteFont("Archivo SemiExpanded:/assets/fonts;Weight=Medium")

-- colors
local C = {
    BG        = rgbm(0, 0, 0, 0.65),
    GREEN     = rgbm(9 / 255, 207 / 255, 46 / 255, 1.0),
    GREEN_DIM = rgbm(5 / 255, 100 / 255, 22 / 255, 1.0),
    YELLOW    = rgbm(255 / 255, 228 / 255, 0 / 255, 1.0),
    GREY      = rgbm(98 / 255, 98 / 255, 98 / 255, 0.70),
    LABEL     = rgbm(209 / 255, 209 / 255, 209 / 255, 1.0),
    LABEL_DIM = rgbm(1, 1, 1, 0.35),
}


---@param appMain table  global app state
---@param appLogger table  logger instance (may be nil at init time)
function statusHud.init(appMain, appLogger)
    _app = appMain
    _logger = appLogger
end

--- update the logger reference if appLogger is reassigned
---@param appLogger table
function statusHud.setLogger(appLogger)
    _logger = appLogger
end

function statusHud.on_open()
end

function statusHud.on_close()
end


-- Hud main render; called in every frame while the window is open
---@param dt number delta time in seconds
function statusHud.main(dt)
    if _app == nil then return end
    
    --- update blink timer
    _blinkTimer = _blinkTimer + dt
    if _blinkTimer >= _blinkPeriod then
        _blinkTimer = _blinkTimer - _blinkPeriod
        _blinkOn = not _blinkOn
    end
    
    local udpActive = _app.settings and _app.settings.udpEnable or false
    local logging = _logger and _logger.logging or false
    
    local winSize = ui.windowSize()
    local W = winSize.x
    local H = winSize.y
    local tl = vec2(0, 0)
    local br = vec2(W, H)
    local center = vec2(W / 2, H / 2)
    
    --- stretch both images to completely fill the window corners
    -- using drawImageQuad forces stretching regardless of aspect ratio (temp)
    ui.drawImageQuad(
        IMG_BG,
        tl,          -- top-left
        vec2(W, 0),  -- top-right
        br,          -- bottom-right
        vec2(0, H),  -- bottom-left
        C.BG         -- color tint
    )
    ui.drawImageQuad(
        IMG_DESIGN,
        tl,
        vec2(W, 0),
        br,
        vec2(0, H)
    )

    --- layout
    --- note: vertical center for dots; text rendered at centerY, so half of font height (~7px)
    local dotRadius  = 5  -- px, indicators circle radius
    local dotMarginL = 22 -- px from left edge to dot center
    local labelGap   = 7  -- px between dot right edge and label text
    local blockGap   = 18 -- px between blocks
    local centerY = math.floor(H / 2)
    local textOffY = centerY - 7
    
    -- TX indicator
    local txDotP = vec2(dotMarginL, centerY)
    local txDotColor
    if udpActive then
        txDotColor = _blinkOn and C.GREEN or C.GREEN_DIM
    else
        txDotColor = C.GREY
    end
    ui.drawCircleFilled(txDotP, dotRadius, txDotColor, 16)
    
    local txLabelColor = udpActive and C.LABEL or C.LABEL_DIM
    ui.pushStyleColor(ui.StyleColor.Text, txLabelColor)
    ui.setCursor(vec2(dotMarginL + dotRadius + labelGap, textOffY))
    ui.text("TX")
    ui.popStyleColor()
    
    local txTextW = ui.measureText("TX").x
    
    -- LOG indicator
    local logDotX = dotMarginL + dotRadius + labelGap + txTextW + blockGap
    local logDotP = vec2(logDotX, centerY)
    
    local appEnabled = _app.settings and _app.settings.enable or false
    
    local logDotColor
    local logLabelColor
    if logging then
        logDotColor = C.GREEN
        logLabelColor = C.LABEL
    elseif appEnabled then
        logDotColor = _blinkOn and C.YELLOW or C.GREY
        logLabelColor = C.LABEL
    else
        logDotColor = C.GREY
        logLabelColor = C.LABEL_DIM
    end
    ui.drawCircleFilled(logDotP, dotRadius, logDotColor, 16)

    ui.pushStyleColor(ui.StyleColor.Text, logLabelColor)
    ui.setCursor(vec2(logDotX + dotRadius + labelGap, textOffY))
    ui.text("LOG")
    ui.popStyleColor()
end

return statusHud