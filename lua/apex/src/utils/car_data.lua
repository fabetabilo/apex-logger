local CAR   = ac.getCar(0)
local CPHYS = ac.getCarPhysics(0)

local Mabs = math.abs

local carData = {}

local helpers

---@param helpersRef table
carData.init = function(helpersRef)
    helpers = helpersRef
end

--- Collects static car data from .ini files
---@param appState table main app state (appMain)
---@return table detailData, table mathItems
carData.getDetailData = function(appState)
    local fromCarData = {}
    local lookFor = {
        suspensions = {
            { channelName = 'carwheelbase',   section = "BASIC", key = "WHEELBASE" },
            { channelName = 'carcogloc',      section = "BASIC", key = "CG_LOCATION" },
        },
        engine = {
            { channelName = 'maxTurboBoost', section = "TURBO_0",     key = "MAX_BOOST" },
            { channelName = 'maxRPM',        section = "ENGINE_DATA", key = "LIMITER" },
        },
        ers = {
            { channelName = 'maxErsPerLap', section = "KINETIC", key = "MAX_KJ_PER_LAP" },
        }
    }

    local iniFile
    for ini, data in pairs(lookFor) do
        iniFile = ac.INIConfig.carData(0, ini .. '.ini')
        for _, value in pairs(data) do
            if not fromCarData[value.channelName] then fromCarData[value.channelName] = {} end
            local v = iniFile:get(value.section, value.key, nil)
            if v ~= nil then
                fromCarData[value.channelName] = tonumber(v[1])
            else
                -- encrypted .ini; use -1
                fromCarData[value.channelName] = -1
            end
        end
    end

    fromCarData['maxErsPerLap']   = fromCarData['maxErsPerLap'] > 0 and fromCarData['maxErsPerLap'] or 0
    fromCarData['maxTurboBoost']  = fromCarData['maxTurboBoost'] > 0 and fromCarData['maxTurboBoost'] or 0

    appState.car.wheelBase    = fromCarData['carwheelbase']
    appState.car.cogLocation  = fromCarData['carcogloc']

    -- Fallback for encrypted cars: computes wheelbase from wheel positions
    if appState.car.wheelBase == -1 then
        local posFL = CAR.wheels[ac.Wheel.FrontLeft].position
        local posFR = CAR.wheels[ac.Wheel.FrontRight].position
        local posF  = vec3((posFL.x + posFR.x) / 2, (posFL.y + posFR.y) / 2, (posFL.z + posFR.z) / 2)
        local posRL = CAR.wheels[ac.Wheel.RearLeft].position
        local posRR = CAR.wheels[ac.Wheel.RearRight].position
        local posR  = vec3((posRL.x + posRR.x) / 2, (posRL.y + posRR.y) / 2, (posRL.z + posRR.z) / 2)
        appState.car.wheelBase = Mabs(tonumber(string.format("%.3f", helpers.distance3d(posF, posR))))
    end

    -- Fallback for encrypted cars: approximates COG from wheel loads
    if appState.car.cogLocation == -1 then
        local loadF = CAR.wheels[ac.Wheel.FrontLeft].load + CAR.wheels[ac.Wheel.FrontRight].load
        local loadR = CAR.wheels[ac.Wheel.RearLeft].load + CAR.wheels[ac.Wheel.RearRight].load
        appState.car.cogLocation = Mabs(tonumber(string.format("%.3f", loadF / (loadF + loadR))))
    end
    
    -- detail data array (car values):
    local detailData = {
        { type = "Numeric", id = "Vehicle Wheelbase",   value = appState.car.wheelBase,   unit = "m",  dps = "3" },
        { type = "Numeric", id = "Vehicle COG",         value = appState.car.cogLocation, unit = "%",  dps = "3" },
        { type = "Numeric", id = "Fuel Tank Capacity",  value = CAR.maxFuel,              unit = "l",  dps = "2" },
        { type = "Numeric", id = "Vehicle Weight",      value = CAR.mass,                 unit = "kg", dps = "2" },
    }
    
    local mathItems = {
        { name = "Max rpm",         value = fromCarData['maxRPM'] ~= -1 and fromCarData['maxRPM'] or CAR.rpmLimiter, unit = "rpm" },
        { name = "Max Turbo Boost", value = fromCarData['maxTurboBoost'], unit = "KJ" },
    }

    -- gear ratios:
    local gDecay = 0
    for i = 0, #CPHYS.gearRatios - 1 do
        if CPHYS.gearRatios[i] > 0 then
            table.insert(detailData, {
                type = "Numeric",
                id   = "Gear " .. tostring(i - gDecay + 1),
                value = CPHYS.gearRatios[i],
                unit = "",
                dps  = "2"
            })
        else
            gDecay = gDecay + 1
        end
    end
    table.insert(detailData, {
        type = "Numeric",
        id   = "Diff Ratio",
        value = CPHYS.finalRatio,
        unit = "",
        dps  = "2"
    })

    return detailData, mathItems
end

return carData
