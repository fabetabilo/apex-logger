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

    ui.text("Laps Folder")
    ui.offsetCursorY(5)
    if ui.button("Open laps folder##openLaps", vec2(ui.availableSpaceX(), 22)) then
        os.openInExplorer(ac.dirname() .. "\\laps")
    end
    if ui.itemHovered() then
        appUI.tooltip("Open logged laps folder")
    end
    
    ui.text("Track Information")
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
    
    -- Car data
    if appState.detailData then
        for _, item in ipairs(appState.detailData) do
            ui.pushStyleColor(ui.StyleColor.Text, appUI.colors.GREY)
            ui.text(item.id)
            ui.popStyleColor()
            
            ui.sameLine(175)

            local displayValue
            if item.type == "Numeric" then
                local dps = tonumber(item.dps) or 2
                displayValue = string.format("%." .. dps .. "f", item.value)
            else
                displayValue = tostring(item.value)
            end
            ui.text(displayValue)
            
            ui.sameLine(275)

            ui.pushStyleColor(ui.StyleColor.Text, appUI.colors.MID_GREY)
            ui.text(item.unit or "")
            ui.popStyleColor()
        end
    end

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
