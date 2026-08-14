local tabAbout = {}

-- module references (set during init)
local appState, appUI

--- Initialize with the app module references
---@param state table appMain
---@param ui table UI helpers module
tabAbout.init = function(state, ui)
    appState = state
    appUI    = ui
end

-- ============================================================================
-- About Tab draw
-- ============================================================================

--- Draw the about tab contents
tabAbout.draw = function()
    ui.pushStyleVar(ui.StyleVar.IndentSpacing, 12)
    
    ui.offsetCursorY(5)
    
    ui.pushStyleColor(ui.StyleColor.Text, appUI.colors.GREY)
    ui.text("Version")
    ui.popStyleColor()
    
    ui.sameLine(175)
    ui.text(appState.name .. " v" .. appState.version)
    
    -- CSP Version
    ui.pushStyleColor(ui.StyleColor.Text, appUI.colors.GREY)
    ui.text("CSP")
    ui.popStyleColor()
    
    ui.sameLine(175)
    ui.pushStyleColor(ui.StyleColor.Text, appUI.colors.MID_GREY)
    ui.text(appState.cspVersion)
    ui.popStyleColor()
    
    ui.offsetCursorY(15)
    ui.separator()
    ui.offsetCursorY(15)
    
    -- buttons
    if ui.button("Check for Update##checkUpdate", vec2(ui.availableSpaceX(), 22)) then
        if appState.urlUpdate then
            os.openURL(appState.urlUpdate, false)
        end
    end
    if ui.itemHovered() then
        ui.setMouseCursor(ui.MouseCursor.Hand)
        appUI.tooltip("Check for available updates")
    end

    if ui.button("Documentation##openDocs", vec2(ui.availableSpaceX(), 22)) then
        if appState.urlDocs then
            os.openURL(appState.urlDocs, false)
        end
    end
    if ui.itemHovered() then
        ui.setMouseCursor(ui.MouseCursor.Hand)
        appUI.tooltip("Open documentation page")
    end

    ui.offsetCursorY(15)
    ui.image("assets/icons/apex_logo.png", vec2(980, 275) * 0.2)

    ui.popStyleVar()
end

return tabAbout
