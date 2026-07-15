local CAR  = ac.getCar(0)
local CPHYS = ac.getCarPhysics(0)

local tabData = {}

local appState, appUI

--- Initialize with app references
---@param state table appMain
---@param ui table UI helpers module
tabData.init = function(state, ui)
    appState = state
    appUI    = ui
end

-- ===============================================================
-- Data Tab Draw
-- ===============================================================

tabData.draw = function()
    ui.pushStyleVar(ui.StyleVar.IndentSpacing, 12)
    
    ui.text("Track Info")
    ui.offsetCursorY(5)

    ui.pushStyleColor(ui.StyleColor.Text, appUI.colors.GREY)
    ui.text("Track ID")
    ui.popStyleColor()
    
    ui.sameLine(175)
    
    ui.text(appState.trackLayout or ac.getTrackID())
    
    ui.offsetCursorY(5)
    ui.separator()
    ui.offsetCursorY(5)
    
    ui.text("Car Data")
    ui.offsetCursorY(5)
    
    -- Todo: future relevant car data ~ ----------------------------------
    
    -- Math items (computed values):
    if appState.mathItems then
        for _, item in ipairs(appState.mathItems) do
            ui.pushStyleColor(ui.StyleColor.Text, appUI.colors.GREY)
            ui.text(item.name)
            ui.popStyleColor()
            
            ui.sameLine(175)
            
            ui.text(tostring(item.value))
            
            ui.sameLine(275)
            
            ui.pushStyleColor(ui.StyleColor.Text, appUI.colors.MID_GREY)
            ui.text(item.unit or "")
            ui.popStyleColor()
        end
    end
    
    ui.offsetCursorY(5)
    
    ui.separator()
    ui.offsetCursorY(5)
    ui.text("CSP Data")
    ui.offsetCursorY(5)
    
    ui.pushStyleColor(ui.StyleColor.Text, appUI.colors.GREY)
    ui.text("CSP Aeromap")
    ui.popStyleColor()
    
    ui.sameLine(175)

    if appState.car.hasAeromap then
        ui.pushStyleColor(ui.StyleColor.Text, appUI.colors.GREEN)
        ui.text("Detected")
    else
        ui.pushStyleColor(ui.StyleColor.Text, appUI.colors.MID_GREY)
        ui.text("Not available")
    end
    ui.popStyleColor()

    ui.pushStyleColor(ui.StyleColor.Text, appUI.colors.GREY)
    ui.text("Encrypted aero")
    ui.popStyleColor()
    
    ui.sameLine(175)
    
    ui.text(appState.car.aeroEncrypted and "Yes" or "No")

    ui.popStyleVar()
end

return tabData
