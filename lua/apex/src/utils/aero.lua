local CAR   = ac.getCar(0)
local CPHYS = ac.getCarPhysics(0)

local OSpreciseClock = os.preciseClock

local aero = {
    lastUpdt = 0,
    aeromap  = -1,
    refWings = {},
    data     = {},
    wheelbase = 0,
    cogPos   = 0,
}

--- Checks if the current car has CSP aeromap
---@param pyBuffer table Python companion buffer data
---@param carState table appMain.car state
---@return boolean
aero.hasAeromap = function(pyBuffer, carState)
    local aeroINI = ac.INIConfig.carData(0, "aero.ini", ac.INIFormat)
    local header = aeroINI:get("HEADER", 'VERSION', {nil})[1]
    if not header then
        -- encrypted car: check if python buffer app provides any data
        if tonumber(pyBuffer.aeroDownforceFront) > 0 and tonumber(pyBuffer.aeroDownforceRear) > 0 then
            return true
        else
            carState.aeroEncrypted = true
            return false
        end
    end

    local map = aeroINI:get("MAP_0", 'NAME', {nil})[1]
    if map then return true end
    return false
end

--- Loads wing reference data from aero.ini
--- Only reference wings are stored. No aeromap LUT loading (the python app handles that)
---@param carState table appMain.car state
aero.loadAeroData = function(carState)
    aero.wheelbase = carState.wheelBase
    aero.cogPos    = carState.cogLocation
    try(
        function()
            aero.aeromap = false
            
            local aeroINI = ac.INIConfig.carData(0, "aero.ini")
            
            -- wing positions:
            local lastW = 0
            for idx, wing in aeroINI:iterate("WING") do
                local pos = tonumber(aeroINI:get(wing, 'POSITION', {0,0,0})[3])
                if not pos then pos = 0 end
                aero.refWings[wing] = {
                    name  = aeroINI:get(wing, 'NAME', {''})[1],
                    pos   = pos,
                    idx   = idx - 1,
                    isFin = false,
                }
                lastW = idx
            end
            
            -- Fin wings:
            for idx, wing in aeroINI:iterate("FIN") do
                local pos = aeroINI:get(wing, 'POSITION', {0,0,0})
                aero.refWings['WING_' .. idx + lastW - 1] = {
                    name  = aeroINI:get(wing, 'NAME', {''})[1],
                    pos   = tonumber(pos[3]),
                    idx   = idx + lastW - 1,
                    isFin = true,
                }
            end
        end,
        function(err)
            print('aero.loadAeroData ERROR', err)
            aero.aeromap = false
        end
    )
    return aero
end

--- Calculate aerodynamic forces per update tick.
--- handles multiple sources: python buffer, encrypted cars, and standard (no CSP) wings
---@param appState table main app state (for pyBuffer, car state, pyAppLoaded)
aero.stepWings = function(appState)
    if OSpreciseClock() - aero.lastUpdt < 0.05 then return end
    
    -- encrypted aero with python: assume 45% front / 55% rear balance
    if appState.car.aeroEncrypted and appState.pyAppLoaded then
        aero.data = {}
        local downforce = appState.pyBuffer.aeroDownforceRear
        aero.data.downforceFront = downforce * 0.45
        aero.data.downforceRear  = downforce * 0.55
        aero.data.drag = appState.pyBuffer.aeroDrag
        aero.lastUpdt = OSpreciseClock()
        return
    end

    -- for no python companion or no wings:
    if not appState.pyAppLoaded or #CPHYS.wings == 0 then
        aero.data = { drag = 0, downforceFront = 0, downforceRear = 0 }
        aero.lastUpdt = OSpreciseClock()
        return
    end

    -- CSP aeromap car: use python data directly
    if appState.car.hasAeromap then
        aero.data = {
            drag = appState.pyBuffer.aeroDrag,
            downforceFront = appState.pyBuffer.aeroDownforceFront,
            downforceRear  = appState.pyBuffer.aeroDownforceRear,
        }
        aero.lastUpdt = OSpreciseClock()
        return
    end

    -- for standard Kunos aero: calculate from wing coefficients
    aero.data = {
        speedCf = 0.5 * CPHYS.airDensity * CAR.speedMs ^ 2,
        CL = 0, CD = 0,
        Mo_CL = 0, Mo_CD = 0,
        bal = 0
    }

    local wing
    for i = 0, #CPHYS.wings - 1 do
        wing = aero.refWings['WING_' .. i]
        wing.cl = CPHYS.wings[i].cl
        wing.cd = CPHYS.wings[i].cd
        wing.gh = CPHYS.wings[i].groundHeight / 1000

        aero.data.CD    = aero.data.CD + wing.cd
        aero.data.Mo_CD = aero.data.Mo_CD + (wing.cd * (wing.gh - CAR.cgHeight))

        if not wing.isFin then
            aero.data.CL    = aero.data.CL + wing.cl
            aero.data.Mo_CL = aero.data.Mo_CL + (wing.cl * wing.pos)
        end
    end

    -- include drag moment in aero balance
    aero.data.CLf = (aero.data.CL * aero.cogPos) + (aero.data.Mo_CL / aero.wheelbase) - (aero.data.Mo_CD / aero.wheelbase)
    aero.data.CLr = aero.data.CL - aero.data.CLf

    aero.data.downforceFront = aero.data.CLf * aero.data.speedCf
    aero.data.downforceRear  = aero.data.CLr * aero.data.speedCf
    aero.data.drag           = aero.data.CD  * aero.data.speedCf

    aero.lastUpdt = OSpreciseClock()
end

return aero
