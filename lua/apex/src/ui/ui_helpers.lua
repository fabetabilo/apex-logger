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

-- Tooltip =================================================================

--- Show a tooltip on hover for the previous ImGui item
---@param text string tooltip text
uiHelpers.tooltip = function(text)
    if ui.itemHovered() then
        ui.setTooltip(text)
    end
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


return uiHelpers