local tabTools = {}

local appState, appUI
local exportStatus = nil
local exportedFile = ""
local exportError  = nil

--- Initialize with app references
---@param state table appMain
---@param ui table UI helpers module
tabTools.init = function(state, ui)
    appState = state
    appUI    = ui
end

--- Export current track borders, centerline, sectors to JSON
local function exportTrack()
    exportStatus = nil
    exportedFile = ""
    exportError  = nil

    if not ac.hasTrackSpline() then
        exportStatus = "error"
        exportError  = "No AI spline found for this track"
        if appUI and appUI.updateUIlog then
            appUI.updateUIlog("Track exporter: " .. exportError, appUI.colors.ORANGE)
        end
        return
    end

    local sim = ac.getSim()
    local length = sim.trackLengthM

    if length <= 0 or length > 80000 then
        exportStatus = "error"
        exportError  = "Invalid track length: " .. tostring(length)
        if appUI and appUI.updateUIlog then
            appUI.updateUIlog("Track exporter: " .. exportError, appUI.colors.ORANGE)
        end
        return
    end

    local trackId = ac.getTrackID()
    local layout  = ac.getTrackLayout()

    -- Sample step: balance precision vs file size
    local step = 2
    if length > 15000 then
        step = 3
    elseif length < 3000 then
        step = 1
    end

    local center = {}
    local left   = {}
    local right  = {}

    for i = 0, math.floor(length), step do
        local progress = i / length

        local c = ac.trackProgressToWorldCoordinate(progress)
        center[#center + 1] = {
            math.floor(c.x * 100 + 0.5) / 100,
            math.floor(c.z * 100 + 0.5) / 100
        }

        local l = ac.trackCoordinateToWorld(vec3(-1, 0, progress))
        left[#left + 1] = {
            math.floor(l.x * 100 + 0.5) / 100,
            math.floor(l.z * 100 + 0.5) / 100
        }

        local r = ac.trackCoordinateToWorld(vec3(1, 0, progress))
        right[#right + 1] = {
            math.floor(r.x * 100 + 0.5) / 100,
            math.floor(r.z * 100 + 0.5) / 100
        }
    end

    -- Sector positions (normalized 0-1)
    local sectors = {}
    local splits = sim.lapSplits
    if splits and splits[0] ~= nil then
        for i = 0, #splits - 1 do
            sectors[#sectors + 1] = math.floor(splits[i] * 10000 + 0.5) / 10000
        end
    end

    -- Bounding box from all border points
    local minX, maxX = math.huge, -math.huge
    local minZ, maxZ = math.huge, -math.huge
    for i = 1, #left do
        minX = math.min(minX, left[i][1], right[i][1])
        maxX = math.max(maxX, left[i][1], right[i][1])
        minZ = math.min(minZ, left[i][2], right[i][2])
        maxZ = math.max(maxZ, left[i][2], right[i][2])
    end

    -- Start/finish direction for auto-rotation hint
    local p0 = ac.trackProgressToWorldCoordinate(0)
    local p1 = ac.trackProgressToWorldCoordinate(math.min(100, length) / length)
    local startAngle = math.deg(math.atan2(p1.z - p0.z, p1.x - p0.x))

    local data = {
        trackId = trackId,
        layout = layout,
        lengthM = math.floor(length + 0.5),
        sampleStepM = step,
        pointCount = #center,
        startAngleDeg = math.floor(startAngle * 10 + 0.5) / 10,
        bounds = {
            minX = math.floor(minX * 100 + 0.5) / 100,
            maxX = math.floor(maxX * 100 + 0.5) / 100,
            minZ = math.floor(minZ * 100 + 0.5) / 100,
            maxZ = math.floor(maxZ * 100 + 0.5) / 100
        },
        sectors = sectors,
        center = center,
        left = left,
        right = right
    }

    local outputFolder = ac.dirname() .. "\\tracks\\"
    if not io.dirExists(outputFolder) then
        io.createDir(outputFolder)
    end

    local layoutSuffix = (layout ~= nil and layout ~= "") and ("-" .. layout) or ""
    local fileName = string.format("%s%s.json", trackId, layoutSuffix)
    local fullPath = outputFolder .. fileName

    local json = JSON.stringify(data)
    local saved = false
    if io.save then
        saved = io.save(fullPath, json)
    end
    if saved == false then
        local f = io.open(fullPath, "w")
        if f then
            f:write(json)
            f:close()
            saved = true
        end
    end

    if saved == false then
        exportStatus = "error"
        exportError  = "Failed to write JSON file"
        if appUI and appUI.updateUIlog then
            appUI.updateUIlog("Track exporter: failed writing " .. fileName, appUI.colors.ORANGE)
        end
        return
    end

    exportedFile = fileName
    exportStatus = "success"
    ac.log("[TrackExporter] OK: " .. fileName .. " (" .. #center .. " points)")
    if appUI and appUI.updateUIlog then
        appUI.updateUIlog("Track exporter: exported " .. fileName, appUI.colors.GREEN)
    end
end


-- ===================================================================
-- Tools Tab Draw
-- ==================================================================

tabTools.draw = function()
    ui.offsetCursorY(5)
    ui.text("Track Exporter")
    ui.offsetCursorY(5)

    ui.pushStyleColor(ui.StyleColor.Text, appUI.colors.GREY)
    ui.text("Track ID")
    ui.popStyleColor()

    ui.sameLine(175)

    ui.text(appState.trackLayout or ac.getTrackID())

    ui.offsetCursorY(15)
    ui.separator()
    ui.offsetCursorY(15)
    
    if ui.button("Export track data##exportTrack", vec2(ui.availableSpaceX(), 22)) then
        exportTrack()
    end
    if ui.itemHovered() then
        ui.setMouseCursor(ui.MouseCursor.Hand)
        appUI.tooltip("Generates a JSON file with track borders\nfor use in external dashboards.")
    end
    
    if ui.button("Open track data folder##openTracksFolder", vec2(ui.availableSpaceX(), 22)) then
        local outputFolder = ac.dirname() .. "\\tracks\\"
        if not io.dirExists(outputFolder) then
            io.createDir(outputFolder)
        end
        os.openInExplorer(outputFolder)
    end
    if ui.itemHovered() then
        ui.setMouseCursor(ui.MouseCursor.Hand)
        appUI.tooltip("Open track data folder")
    end
    
    if exportStatus == "success" then
        ui.offsetCursorY(8)
        ui.pushStyleColor(ui.StyleColor.Text, appUI.colors.GREEN)
        ui.text("Exported: " .. exportedFile)
        ui.popStyleColor()
    elseif exportStatus == "error" then
        ui.offsetCursorY(8)
        ui.pushStyleColor(ui.StyleColor.Text, appUI.colors.ORANGE)
        ui.text("✗ " .. (exportError or "Unknown error"))
        ui.popStyleColor()
    end

    ui.offsetCursorY(5)
end

return tabTools
