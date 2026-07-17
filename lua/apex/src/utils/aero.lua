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

return aero
