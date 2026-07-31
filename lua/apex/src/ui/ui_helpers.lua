local SIM = ac.getSim()
local CAR = ac.getCar(0)

local OSpreciseClock = os.preciseClock

local uiHelpers = {}

-- App color palette RGBA
uiHelpers.colors = {
    RED       = rgbm(0.77, 0.08, 0.08, 1),
    ORANGE    = rgbm(1, 0.65, 0.2, 1),
    YELLOW    = rgbm(1, 0.9, 0.1, 1),
    WHITE     = rgbm(1, 1, 1, 1),            -- Default text
    DARK_GREY = rgbm(0.3, 0.3, 0.3, 1),      -- Disabled states
    MID_GREY  = rgbm(0.55, 0.55, 0.55, 1),   -- Secondary text
    GREY      = rgbm(0.7, 0.7, 0.7, 1),      -- Subtle text
    GREEN     = rgbm(0.15, 0.7, 0.25, 1),
    BLUE      = rgbm(0.25, 0.57, 0.95, 1),
    PURPLE    = rgbm(0.72, 0.45, 0.94, 1),
    
    TAB_ACTIVE_BG   = rgbm(0.77, 0.08, 0.08, 1),
    TAB_INACTIVE_BG = rgbm(0.15, 0.15, 0.15, 1),
    TAB_HOVER_BG    = rgbm(0.25, 0.25, 0.25, 1),
    TAB_TEXT        = rgbm(0.9, 0.9, 0.9, 1),
}


-- In-app UI Log ================================================================
-- a scrollable list of timestamped colored messages shown on the Logging tab
uiHelpers.UIlog = {}
uiHelpers.UIlogMaxLines = 30

--- Adds a timestamped message to the UI log
---@param msg string message text
---@param color rgbm color for the message
uiHelpers.updateUIlog = function(msg, color)
    if msg == nil then msg = '' end
    if color == nil then color = uiHelpers.colors.GREY end
    local entry = {
        time  = os.date("%X"),
        msg   = msg,
        color = color,
    }
    table.insert(uiHelpers.UIlog, 1, entry)
    if #uiHelpers.UIlog > uiHelpers.UIlogMaxLines then
        table.remove(uiHelpers.UIlog)
    end
end

--- Clear all messages from the UI log
uiHelpers.resetUIlog = function()
    uiHelpers.UIlog = {}
end

--- Draws the scrollable UI Log list with ImGui
---@param height number available height for the log area
uiHelpers.drawUIlog = function(height)
    ui.pushStyleVar(ui.StyleVar.ItemSpacing, vec2(2, 1))
    ui.beginChild("uiLog", vec2(ui.availableSpaceX(), height), false)
    for _, entry in ipairs(uiHelpers.UIlog) do
        ui.pushStyleColor(ui.StyleColor.Text, uiHelpers.colors.MID_GREY)
        ui.text(entry.time)
        ui.popStyleColor()
        ui.sameLine(60)
        ui.pushStyleColor(ui.StyleColor.Text, entry.color)
        ui.text(entry.msg)
        ui.popStyleColor()
    end
    ui.endChild()
    ui.popStyleVar()
end


-- Tooltip =================================================================

--- Show a tooltip on hover for the previous ImGui item
---@param text string tooltip text
uiHelpers.tooltip = function(text)
    if ui.itemHovered() then
        ui.setTooltip(text)
    end
end

-- Window app header =========================================================
--- Builds the window title with current app and car in-track status
---@param appState table main app state
---@param logger table logger instance
---@return string title
uiHelpers.getTitle = function(appState, logger)
    local parts = { appState.name .. " Settings" }

    if not appState.settings.enable then
        parts[#parts + 1] = "inactive"
    else
        local mode = logger and logger.logging and "logging" or "active"
        local rate = logger and logger.currentDataRate or appState.settings.dataRate
        parts[#parts + 1] = mode .. " (" .. rate .. "Hz)"

        if CAR.isInPitlane or CAR.isInPit then
            parts[#parts + 1] = "in pit"
        else
            parts[#parts + 1] = "on track"
        end

        if appState.settings.forceRaceMode then
            parts[#parts + 1] = "RM"
        end
        
        if appState.settings.udpEnable then
            parts[#parts + 1] = "TX"
        end
    end

    return table.concat(parts, " | ")
end


-- TAB BAR ==================================================================
local tabScrollOffset = 0

--- Draw a single tabbar section with colored active indicator
---@param tabs table array of {name: string} entries
---@param currentTab number current selected tab index
---@return number selected tab index
uiHelpers.drawTabBar = function(tabs, currentTab)
    local selectedTab = currentTab
    local tabHeight = 20
    local padding = 24
    local spacing = 2
    
    -- calculate total width needed for all tabs; responsiveness if u want o:
    local totalWidth = 0
    local tabWidths = {}
    for i, tab in ipairs(tabs) do
        local w = ui.measureText(tab.name).x + padding
        tabWidths[i] = w
        totalWidth = totalWidth + w
    end
    totalWidth = totalWidth + (#tabs - 1) * spacing
    
    local availWidth = ui.availableSpaceX()
    local showNav = totalWidth > availWidth
    local navWidth = 40
    local clipWidth = showNav and (availWidth - navWidth) or availWidth
    
    -- clamp scroll offset
    local maxScroll = math.max(0, totalWidth - clipWidth)
    if tabScrollOffset < -maxScroll then tabScrollOffset = -maxScroll end
    if tabScrollOffset > 0 then tabScrollOffset = 0 end
    
    ui.pushStyleVar(ui.StyleVar.FrameRounding, 0)
    ui.pushStyleVar(ui.StyleVar.ItemSpacing, vec2(0, 0))
    
    local p = ui.getCursor()
    
    -- draw navigation arrows when needed
    if showNav then
        ui.setCursor(p + vec2(clipWidth, 0))
        ui.pushStyleColor(ui.StyleColor.Button, uiHelpers.colors.TAB_INACTIVE_BG)
        ui.pushStyleColor(ui.StyleColor.Text, uiHelpers.colors.TAB_TEXT)
        if ui.button("<##scrollLeft", vec2(navWidth / 2, tabHeight)) then
            tabScrollOffset = math.min(0, tabScrollOffset + 50)
        end
        ui.sameLine(0, 0)
        if ui.button(">##scrollRight", vec2(navWidth / 2, tabHeight)) then
            tabScrollOffset = math.max(-maxScroll, tabScrollOffset - 50)
        end
        ui.popStyleColor(2)
        ui.setCursor(p)
    end

    -- clip and draw tabs
    ui.pushClipRect(p, p + vec2(clipWidth, tabHeight), true)
    ui.setCursor(p + vec2(tabScrollOffset, 0))

    for i, tab in ipairs(tabs) do
        local isActive = (i == currentTab)
        if isActive then
            ui.pushStyleColor(ui.StyleColor.Button, uiHelpers.colors.RED)
            ui.pushStyleColor(ui.StyleColor.ButtonHovered, uiHelpers.colors.RED)
            ui.pushStyleColor(ui.StyleColor.ButtonActive, uiHelpers.colors.RED)
            ui.pushStyleColor(ui.StyleColor.Text, uiHelpers.colors.WHITE)
        else
            ui.pushStyleColor(ui.StyleColor.Button, uiHelpers.colors.TAB_INACTIVE_BG)
            ui.pushStyleColor(ui.StyleColor.ButtonHovered, uiHelpers.colors.TAB_HOVER_BG)
            ui.pushStyleColor(ui.StyleColor.ButtonActive, uiHelpers.colors.TAB_HOVER_BG)
            ui.pushStyleColor(ui.StyleColor.Text, uiHelpers.colors.TAB_TEXT)
        end

        if ui.button(tab.name .. "##tab" .. i, vec2(tabWidths[i], tabHeight)) then
            selectedTab = i
        end
        ui.popStyleColor(4)

        if i < #tabs then
            ui.sameLine(0, spacing)
        end
    end

    ui.popClipRect()
    ui.popStyleVar(2)

    -- move cursor below tabs and draw red horizontal line, vec2(availWidth, 1) <- 1 px (can be 2,4,6,etc)
    ui.setCursor(p + vec2(0, tabHeight))
    ui.drawRectFilled(ui.getCursor(), ui.getCursor() + vec2(availWidth, 1), uiHelpers.colors.RED)
    ui.offsetCursorY(7) -- spacing below the line

    return selectedTab
end


-- App status helper ======================================================================

--- Get current app status color and text
---@param appState table main app state
---@param logger table logger instance
---@return rgbm color, string text
uiHelpers.getStatusColorAndText = function(appState, logger)
    local color = uiHelpers.colors.DARK_GREY
    local stateText = "Inactive"

    if appState.settings.enable then
        if logger and logger.logging then
            if logger.stint.isInRace then
                color = uiHelpers.colors.GREEN
                stateText = "Logging race"
            else
                -- logging practice or hotlap session
                color = uiHelpers.colors.GREEN
                stateText = "Logging"
            end
        else
            color = uiHelpers.colors.YELLOW
            stateText = "Active and waiting for stint"
        end
    end

    return color, stateText
end

return uiHelpers