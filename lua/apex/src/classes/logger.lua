local SIM  = ac.getSim()
local SESSION = ac.getSession(0)
local CPHYS = ac.getCarPhysics(0)
local CAR  = ac.getCar(0)

local OSpreciseClock = os.preciseClock
local OSdate  = os.date
local OStime  = os.time
local Tconcat = table.concat
local STRformat = string.format
local toSTR = tostring
local toNUM = tonumber
local Mexp  = math.exp
local Mabs  = math.abs


--- Telemetry data recording component
---@class ApexLogger
ApexLogger = class('ApexLogger', class.NoInitialize)



-- CHANNELS metadata ==================================================================================================================================

-- Recollect and records in-real-time car physics data at multiple simultaneous frequencies. Each rate group is independently sampled 
-- and stored per-lap as .csv file.
-- Rate dispatch: the logger checks timestamps once per rate bucket, then iterates all enabled groups within that bucket
-- minimizing overhead to 4 timestamp checks per tick.

ApexLogger.channelsPreOrder = {}
ApexLogger.channelsPreOrder["session"] = {
    "airtemp",
    "airdens",
    "roadtemp",
    "roadgrip",
    "winddir",
    "windspeed",
    "raceflagtype",
    "weatherType",
}

ApexLogger.channelsPreOrder["car_info"] = {
    "lastsectortime",
    "fuellevel",
    "brakebias",
    "invalidlap",
    "ebsetting",
    
    "tiregripfl",
    "tiregripfr",
    "tiregriprl",
    "tiregriprr",
    
    "virtualkmfl",
    "virtualkmfr",
    "virtualkmrl",
    "virtualkmrr",
    
    "damagefront",
    "damageright",
    "damagerear",
    "damageleft",
    
    "tyresCompound",
    "racePosition",
    "engineLifeLeft",
    "gearboxDamage",
    "oilTemperature",
    "waterTemperature",
    "absMode",
    "tcMode",
    "tc2Mode",
    "fuelMap",
    "relplankwear",
}

ApexLogger.channelsPreOrder["tires"] = {
    "tirepressfl",
    "tirepressfr",
    "tirepressrl",
    "tirepressrr",
    "tiresurfdirtfl",
    "tiresurfdirtfr",
    "tiresurfdirtrl",
    "tiresurfdirtrr",
    
    "tiretmpcorefl",
    "tiretmpcorefr",
    "tiretmpcorerl",
    "tiretmpcorerr",
    "tiretmpinnerfl",
    "tiretmpinnerfr",
    "tiretmpinnerrl",
    "tiretmpinnerrr",
    "tiretmpmiddlefl",
    "tiretmpmiddlefr",
    "tiretmpmiddlerl",
    "tiretmpmiddlerr",
    "tiretmpouterfl",
    "tiretmpouterfr",
    "tiretmpouterrl",
    "tiretmpouterrr",
    
    "tyreGrainfl",
    "tyreGrainfr",
    "tyreGrainrl",
    "tyreGrainrr",
    "tyreBlisterfl",
    "tyreBlisterfr",
    "tyreBlisterrl",
    "tyreBlisterrr",
    
    "braketempfl",
    "braketempfr",
    "braketemprl",
    "braketemprr",
}

ApexLogger.channelsPreOrder["dyn"] = {
    "posnorm",
    "numtiresout",
    "drivetrainTorque",
    "drivetrainPower",
    "drivetrainspeed",
}

ApexLogger.channelsPreOrder["ext_elec"] = {
    "drsavail",
    "drsact",
    "erscharging",
    "kersdeployed",
    "kersinput",
    "kerscharge",
}

ApexLogger.channelsPreOrder["aero"] = {
    "aerodrag",
    "aeroDownforceFront",
    "aeroDownforceRear",
}

ApexLogger.channelsPreOrder["sim_info"] = {
    "ffbPure",
    "ffbFinal",
    "fps",
    "physicsLate",
    "cpuTime",
}

ApexLogger.channelsPreOrder["input"] = {
    "clutch",
    "absactive",
    "tcactive",
    "speed",
    "laptime",
    "lapdistance",
    "lapcount",

    "throttle",
    "brake",
    "handbrake",
    "steerAngle",
    "steerTorque",
    "gear",
    "rpm",
    
    "brakeTorqueFL",
    "brakeTorqueFR",
    "brakeTorqueRL",
    "brakeTorqueRR",
    "turboboost",
}

ApexLogger.channelsPreOrder["gps"] = {
    "posx",
    "posy",
    "posz",
    
    "velx",
    "vely",
    "velz",

    "carHeading",
    "pitchrate",
    "pitchangle",
    "rollrate",
    "rollangle",
    "yawrate",
}

ApexLogger.channelsPreOrder["tires_dyn"] = {
    "wheelspeedFL",
    "wheelspeedFR",
    "wheelspeedRL",
    "wheelspeedRR",
    "ndslipfl",
    "ndslipfr",
    "ndsliprl",
    "ndsliprr",
    "tireloadfl",
    "tireloadfr",
    "tireloadrl",
    "tireloadrr",
    "tireloadedradfl",
    "tireloadedradfr",
    "tireloadedradrl",
    "tireloadedradrr",

    "tireslipanglefl",
    "tireslipanglefr",
    "tireslipanglerl",
    "tireslipanglerr",
    "tireslipratiofl",
    "tireslipratiofr",
    "tireslipratiorl",
    "tireslipratiorr",

    "tirelongforcefl",
    "tirelongforcefr",
    "tirelongforcerl",
    "tirelongforcerr",
    "tirelatforcefl",
    "tirelatforcefr",
    "tirelatforcerl",
    "tirelatforcerr",
}

ApexLogger.channelsPreOrder["gforce"] = {
    "cgaccellat",
    "cgaccellong",
    "cgaccelvert",
}

ApexLogger.channelsPreOrder["susp"] = {
    "rideheightfront",
    "rideheightrear",
    "cgheight",
    "susptravelfl",
    "susptravelfr",
    "susptravelrl",
    "susptravelrr",
    "tirealignntrqfl",
    "tirealignntrqfr",
    "tirealignntrqrl",
    "tirealignntrqrr",
    "damperTravelFL",
    "damperTravelFR",
    "damperTravelRL",
    "damperTravelRR",
    "damperTravelHF",
    "damperTravelHR",
    "caster",
    "camberfl",
    "camberfr",
    "camberrl",
    "camberrr",
    "toefl",
    "toefr",
    "toerl",
    "toerr",
}


-- Initialization ===========================================================================================

function ApexLogger:initialize()
    self.app      = getApexApp()
    self.appUI    = getApexUI()
    self.helpers  = getApexHelpers()
    self.aero     = getApexAero()
    self.udpSender = getApexUDP()
    
    self.LOG     = false
    self.logging = false
    
    self.stint = {
        isInRace     = SIM.raceSessionType == ac.SessionType.Race,
        isOnline     = CAR.sessionID ~= -1,
        noRestart    = false,
        lapCounter   = 1,
        prevLapCount = CAR.lapCount,
        lapTable     = {},
        carOnTrack   = false,
        hotlapStarted = false,
        lastCancel   = 0,
    }
    
    self.currentDataRate = 30
    self.rates = {}
    self:setRates()
    
    self:resetStint()
    self.stint.noRestart = false
end


-- Stint management ==============================================================

function ApexLogger:resetStint()
    self.LOG     = false
    self.logging = false
    self.stint.hotlapStarted = false
    self.stint.isInRace = false
    
    if (SIM.raceSessionType == ac.SessionType.Race) and (SESSION.overtimeMs < 0) then
        self.stint.isInRace = true
    end
    
    self.stint.isOnline  = CAR.sessionID ~= -1
    self.stint.lapTable  = {}
    self.stint.carOnTrack = false
    self.stint.lapCounter  = 1
    self.stint.prevLapCount = CAR.lapCount
end

function ApexLogger:cancelStint()
    if not self.logging then return end
    self.logging = false
    self:resetStint()
    self.stint.lastCancel = os.preciseClock()
    self.appUI.updateUIlog("LOG: stint cancelled", self.appUI.colors.MID_GREY)
    self.helpers.notify(self.app.name, self.app.icons.ok, "Stint cancelled")
end


-- Data rate management ===========================================================

--- Build the rates table, called on init and on session start
function ApexLogger:setRates()
    self.currentDataRate = self.app.settings.dataRate
    local userRate = self.currentDataRate
    local t = OSpreciseClock()

    self.rates = {
        [1] = { delay = 1, lastUpdt = t, groups = {"session", "car_info"} },
        [10] = { delay = 0.1, lastUpdt = t, groups = {"tires", "dyn", "ext_elec", "aero", "sim_info"} },
        [30] = { delay = 1/30, lastUpdt = t, groups = {"input", "gps", "tires_dyn", "gforce"} },
        [userRate] = { delay = 1/userRate - 0.007, lastUpdt = t, groups = {"susp"} },
    }
    -- If userRate collides with a fixed rate (e.g. 30), merge groups rather than overwrite.
    -- In practice DATA_RATES starts at 25 so this only matters for edge cases.
    if userRate == 1 then
        for _, g in ipairs({"susp"}) do
            table.insert(self.rates[1].groups, g)
        end
        self.rates[userRate] = nil  -- remove duplicate key
    elseif userRate == 10 then
        for _, g in ipairs({"susp"}) do
            table.insert(self.rates[10].groups, g)
        end
        self.rates[userRate] = nil
    elseif userRate == 30 then
        for _, g in ipairs({"susp"}) do
            table.insert(self.rates[30].groups, g)
        end
        self.rates[userRate] = nil
    end
end

function ApexLogger:setChannelOrder()
    self.LOG.channelOrder = {}
    for _, g in ipairs({"session", "car_info", "tires", "dyn", "ext_elec", "aero", "sim_info", "input", "gps", "tires_dyn", "gforce", "susp"}) do
        self.LOG.channelOrder[g] = ApexLogger.channelsPreOrder[g]
    end
end


-- Lap management =======================================================================

--- Create new lap data table and optionally report previous lap time
function ApexLogger:newLap(report)
    if report == nil then report = true end
    if self.LOG == false then return end
    self.stint.lapTable = {}

    if (self.stint.lapCounter > 1) and report then
        local lap = self.stint.lapCounter - 1
        local txt
        if not self.stint.isInRace then
            if lap == 1 then
                txt = STRformat("outlap - %s %s",
                    self.helpers.time_to_string(CAR.previousLapTimeMs / 1000),
                    CAR.isLastLapValid and '' or '*')
            else
                txt = STRformat("lap %s - %s %s", lap - 1,
                    self.helpers.time_to_string(CAR.previousLapTimeMs / 1000),
                    CAR.isLastLapValid and '' or '*')
            end
        else
            txt = STRformat("lap %s - %s %s", lap,
                self.helpers.time_to_string(CAR.previousLapTimeMs / 1000),
                CAR.isLastLapValid and '' or '*')
        end
        self.appUI.updateUIlog(txt, self.appUI.colors.GREY)
    end
end

--- Save the current lap data as .csv file
function ApexLogger:saveLap(lapIndex, signal)
    lapIndex = lapIndex or self.stint.lapCounter
    if self.LOG == false then return end

    local str = Tconcat(self.stint.lapTable, "\n")
    local lapPath = ac.dirname() .. "\\laps\\lap_" .. lapIndex .. ".csv"
    self.LOG.lapFiles[#self.LOG.lapFiles + 1] = lapPath
    self.stint.lapCounter = self.stint.lapCounter + 1
    io.saveAsync(lapPath, str)
    
    --- signal HUD: lap was just saved
    --- end-of-stint in-lap is skipped (signal=false)
    if signal ~= false then
        self.app.lapSavedAt = OSpreciseClock()
    end
end



-- Logging START/STOP =====================================================================================

--- check if current log has enough data to be worth saving
function ApexLogger:isLogValid()
    if self.LOG == false then return false end
    if self.stint.isInRace or self.app.settings.forceRaceMode then return true end
    if SIM.raceSessionType == ac.SessionType.Drift then return true end
    if SIM.raceSessionType == ac.SessionType.Drag then return true end
    if table.getn(self.LOG.lapTimes) <= 1 then return false end
    return true
end

--- start a new logging stint
function ApexLogger:start()
    self:setRates()
    local date = OSdate("%d/%m/%Y")
    local time = OSdate("%X")
    local datetime = date .. " " .. time
    local simDateObj = OSdate("!*t", SIM.timestamp)
    local simDateTime = simDateObj.day .. "/" .. simDateObj.month .. "/" .. simDateObj.year .. " " .. simDateObj.hour .. ":" .. simDateObj.min .. ":" .. simDateObj.sec
    
    self.LOG = {
        date         = date,
        time         = time,
        simDateTime  = simDateTime,
        event = {
            name         = self.app.name,
            datetime     = datetime,
            driver       = self.app.settings.driver,
            vehicle      = ac.getCarID(0),
            venue        = self.app.trackLayout,
            shortcomment = self.app.car.tyresAvail[CAR.compoundIndex + 1],
            session      = self.app.sessionName .. " (" .. self.currentDataRate .. "Hz)",
            comment      = self.app.cspVersion .. " / " .. self.app.name .. " v" .. self.app.version,
        },
        lapFiles      = {},
        lapTimes      = {},
        dataRate      = self.currentDataRate,
        channelOrder  = {},
        detailData    = self.app.detailData,
        tyresAvail    = self.app.car.tyresAvail,
        trackId       = ac.getTrackID(),
        trackLayout   = ac.getTrackLayout(),
        trackLength   = SIM.trackLengthM,
    }
    
    self:setChannelOrder()
    
    self.appUI.updateUIlog("LOG: local logging started", self.appUI.colors.GREEN)
    
    self.logging = true
    self:newLap()
    for _, rateData in pairs(self.rates) do
        rateData.lastUpdt = 0
    end
    
    --- toast notification when app window is completely hidden (very handy)
    local appWin = ac.accessAppWindow('IMGUI_LUA_' .. self.app.name .. '_' .. self.app.id)
    if appWin and not appWin:visible() then
        self.helpers.notify(self.app.name, self.app.icons.ok, 'Local lap logging started ' .. self.currentDataRate .. 'Hz')
    end
end

--- Stop logging and export the stint
---@param args table {console: boolean, toast: boolean}
function ApexLogger:stop(args)
    if args == nil then args = { console = true, toast = true } end
    
    if not self.logging then
        self:resetStint()
        return
    end
    
    self.logging = false
    
    if not self:isLogValid() then
        self:resetStint()
        self.LOG = false
        self.appUI.updateUIlog("LOG: invalid stint", self.appUI.colors.ORANGE)
        if args.toast and (os.preciseClock() - self.stint.lastCancel > 5) then
            self.helpers.notify(self.app.name, self.app.icons.ok, 'No full lap, stint not saved')
        end
        return
    end

    self:saveLap(self.stint.lapCounter, false)  -- Save in-lap
    self.LOG.event.driver  = self.app.settings.driver
    self.LOG.csp           = self.app.cspVersion

    if self.stint.isInRace then
        table.insert(self.app.detailData, {
            type = "String", id = "Start Lap", value = "2"
        })
    end

    self.LOG.mathItems = self.app.mathItems
    table.insert(self.LOG.mathItems, {
        name = "FFB Steer Assist", value = CAR.ffbSteerAssist,
    })

    local log_json = JSON.stringify(self.LOG)
    local jsonPath = ac.dirname() .. "\\laps\\log.json"
    local numLaps  = #self.LOG.lapTimes - 1

    self.LOG = false
    self:resetStint()

    if args.console then
        io.saveAsync(jsonPath, log_json, function()
            local msg
            if self.app.settings.forceRaceMode then
                msg = "Saved log"
            else
                msg = "Saved " .. numLaps .. " laps"
            end
            self.appUI.updateUIlog(msg, self.appUI.colors.GREEN)
            if args.toast then
                self.helpers.notify(self.app.name, self.app.icons.ok, msg)
            end
        end)
    else
        io.save(jsonPath, log_json)
        self.appUI.updateUIlog("LOG: logged laps saved at:", self.appUI.colors.BLUE)
    end
end



-- Channel RECORDING =====================================================================================

--- Check which rate groups need updating this tick
function ApexLogger:shouldUpdateChannels(dt)
    local t = OSpreciseClock()
    local groups = self.app.settings.channelGroups
    --- One timestamp check per rate (4 checks max), then iterate groups within.
    for rate, rateData in pairs(self.rates) do
        if t - rateData.lastUpdt >= rateData.delay then
            rateData.lastUpdt = t
            for _, groupId in ipairs(rateData.groups) do
                if not (groups and groups[groupId] == false) then
                    self:updateChannels(groupId, rate)
                end
            end
        end
    end
end

--- Record one sample of all channels in the given group.
--- Line format: "#groupId#;sessionTimeLeft;val1;val2;..."
---@param groupId string  the group identifier
---@param rate    number  numeric rate this group runs at
function ApexLogger:updateChannels(groupId, rate)
    local lineTable
    local ts = SIM.sessionTimeLeft

    if groupId == "session" then
        lineTable = {
            "#session#", ts,
            SIM.ambientTemperature,
            CPHYS.airDensity > 0 and CPHYS.airDensity or 1.225 * Mexp(-CAR.altitude / 8500),
            SIM.roadTemperature,
            SIM.roadGrip,
            SIM.windDirectionDeg,
            SIM.windSpeedKmh,
            SIM.raceFlagType,
            SIM.weatherType,
        }

    elseif groupId == "car_info" then
        lineTable = {
            "#car_info#", ts,
            CAR.currentSector == 0 and CAR.lastSplits[#CAR.lastSplits - 1] or CAR.previousSectorTime,
            CAR.fuel,
            CAR.brakeBias,
            CAR.isLapValid and 0 or 1,
            CAR.currentEngineBrakeSetting,
            
            CAR.wheels[0].tyreWear,
            CAR.wheels[1].tyreWear,
            CAR.wheels[2].tyreWear,
            CAR.wheels[3].tyreWear,
            CAR.wheels[0].tyreVirtualKM,
            CAR.wheels[1].tyreVirtualKM,
            CAR.wheels[2].tyreVirtualKM,
            CAR.wheels[3].tyreVirtualKM,
            
            CAR.damage[0],
            CAR.damage[3],
            CAR.damage[1],
            CAR.damage[2],
            
            CAR.compoundIndex,
            CAR.racePosition,
            CAR.engineLifeLeft,
            CAR.gearboxDamage,
            CAR.oilTemperature,
            CAR.waterTemperature,
            CAR.absMode,
            CAR.tractionControlMode,
            CAR.tractionControl2,
            CAR.fuelMap,
            CAR.maxRelativePlankWear,
        }

    elseif groupId == "tires" then
        lineTable = {
            "#tires#", ts,
            CAR.wheels[0].tyrePressure,
            CAR.wheels[1].tyrePressure,
            CAR.wheels[2].tyrePressure,
            CAR.wheels[3].tyrePressure,
            CAR.wheels[0].surfaceDirt,
            CAR.wheels[1].surfaceDirt,
            CAR.wheels[2].surfaceDirt,
            CAR.wheels[3].surfaceDirt,
            
            CAR.wheels[0].tyreCoreTemperature,
            CAR.wheels[1].tyreCoreTemperature,
            CAR.wheels[2].tyreCoreTemperature,
            CAR.wheels[3].tyreCoreTemperature,
            CAR.wheels[0].tyreOutsideTemperature,
            CAR.wheels[1].tyreInsideTemperature,
            CAR.wheels[2].tyreOutsideTemperature,
            CAR.wheels[3].tyreInsideTemperature,
            CAR.wheels[0].tyreMiddleTemperature,
            CAR.wheels[1].tyreMiddleTemperature,
            CAR.wheels[2].tyreMiddleTemperature,
            CAR.wheels[3].tyreMiddleTemperature,
            CAR.wheels[0].tyreInsideTemperature,
            CAR.wheels[1].tyreOutsideTemperature,
            CAR.wheels[2].tyreInsideTemperature,
            CAR.wheels[3].tyreOutsideTemperature,
            
            CAR.wheels[0].tyreGrain,
            CAR.wheels[1].tyreGrain,
            CAR.wheels[2].tyreGrain,
            CAR.wheels[3].tyreGrain,
            CAR.wheels[0].tyreBlister,
            CAR.wheels[1].tyreBlister,
            CAR.wheels[2].tyreBlister,
            CAR.wheels[3].tyreBlister,
            
            CAR.wheels[0].discTemperature,
            CAR.wheels[1].discTemperature,
            CAR.wheels[2].discTemperature,
            CAR.wheels[3].discTemperature,
        }

    elseif groupId == "dyn" then
        lineTable = {
            "#dyn#", ts,
            CAR.splinePosition,
            CAR.wheelsOutside,
            CAR.drivetrainTorque,
            CAR.drivetrainPower,
            CAR.drivetrainSpeed,
        }

    elseif groupId == "ext_elec" then
        lineTable = {
            "#ext_elec#", ts,
            CAR.drsAvailable and 1 or 0,
            CAR.drsActive and 1 or 0,
            CAR.mguhChargingBatteries and 1 or 0,
            CAR.kersCurrentKJ,
            CAR.kersInput,
            CAR.kersCharge,
        }

    elseif groupId == "aero" then
        self.aero.stepWings(self.app)   -- will be called only if aero group is enabled
        lineTable = {
            "#aero#", ts,
            self.aero.data.drag,
            self.aero.data.downforceFront,
            self.aero.data.downforceRear,
        }

    elseif groupId == "sim_info" then
        lineTable = {
            "#sim_info#", ts,
            CAR.ffbPure,
            CAR.ffbFinal,
            SIM.fps,
            SIM.physicsLate,
            SIM.cpuTime,
        }

    elseif groupId == "input" then
        lineTable = {
            "#input#", ts,
            CAR.clutch,
            CAR.absInAction and 1 or 0,
            CAR.tractionControlInAction and 1 or 0,
            CAR.speedKmh,
            CAR.lapTimeMs,
            CAR.drivenInRace,
            CAR.lapCount,

            CAR.gas,
            CAR.brake,
            CAR.handbrake,
            CAR.steer,
            CAR.steerTorque,
            CAR.gear,
            CAR.rpm,
            
            CPHYS.wheels[0].brakeTorque,
            CPHYS.wheels[1].brakeTorque,
            CPHYS.wheels[2].brakeTorque,
            CPHYS.wheels[3].brakeTorque,
            
            CAR.turboBoost,
        }

    elseif groupId == "gps" then
        lineTable = {
            "#gps#", ts,
            CAR.position.x,
            CAR.position.z,     -- posy (remapped: AC Z -> world Y)
            CAR.position.y,     -- posz (remapped: AC Y -> world Z)
            CAR.localVelocity.z,  -- velx
            CAR.localVelocity.x,  -- vely
            CAR.localVelocity.y,  -- velz
            CAR.compass,        -- carHeading
            CAR.localAngularVelocity.z,  -- pitchrate
            CAR.look.y,                  -- pitchangle
            CAR.localAngularVelocity.x,  -- rollrate
            CAR.side.y,                  -- rollangle
            CAR.localAngularVelocity.y,  -- yawrate
        }

    elseif groupId == "tires_dyn" then
        lineTable = {
            "#tires_dyn#", ts,
            CAR.wheels[0].angularSpeed,
            CAR.wheels[1].angularSpeed,
            CAR.wheels[2].angularSpeed,
            CAR.wheels[3].angularSpeed,
            CAR.wheels[0].ndSlip,
            CAR.wheels[1].ndSlip,
            CAR.wheels[2].ndSlip,
            CAR.wheels[3].ndSlip,
            CAR.wheels[0].load,
            CAR.wheels[1].load,
            CAR.wheels[2].load,
            CAR.wheels[3].load,
            CAR.wheels[0].tyreLoadedRadius,
            CAR.wheels[1].tyreLoadedRadius,
            CAR.wheels[2].tyreLoadedRadius,
            CAR.wheels[3].tyreLoadedRadius,
            
            CAR.wheels[0].slipAngle,
            CAR.wheels[1].slipAngle,
            CAR.wheels[2].slipAngle,
            CAR.wheels[3].slipAngle,
            CAR.wheels[0].slipRatio,
            CAR.wheels[1].slipRatio,
            CAR.wheels[2].slipRatio,
            CAR.wheels[3].slipRatio,
            
            CAR.wheels[0].fx,
            CAR.wheels[1].fx,
            CAR.wheels[2].fx,
            CAR.wheels[3].fx,
            CAR.wheels[0].fy,
            CAR.wheels[1].fy,
            CAR.wheels[2].fy,
            CAR.wheels[3].fy,
        }

    elseif groupId == "gforce" then
        lineTable = {
            "#gforce#", ts,
            CAR.acceleration.x,
            CAR.acceleration.z,
            CAR.acceleration.y,
        }

    elseif groupId == "susp" then
        lineTable = {
            "#susp#", ts,
            CAR.rideHeight[0],
            CAR.rideHeight[1],
            CAR.cgHeight,
            CAR.wheels[0].suspensionTravel,
            CAR.wheels[1].suspensionTravel,
            CAR.wheels[2].suspensionTravel,
            CAR.wheels[3].suspensionTravel,
            CAR.wheels[0].mz,
            CAR.wheels[1].mz,
            CAR.wheels[2].mz,
            CAR.wheels[3].mz,
            
            self.app.pyBuffer.damperTravelFL,
            self.app.pyBuffer.damperTravelFR,
            self.app.pyBuffer.damperTravelRL,
            self.app.pyBuffer.damperTravelRR,
            self.app.pyBuffer.damperTravelHF,
            self.app.pyBuffer.damperTravelHR,
            CAR.caster,
            CAR.wheels[0].camber,
            CAR.wheels[1].camber,
            CAR.wheels[2].camber,
            CAR.wheels[3].camber,
            CAR.wheels[0].toeIn,
            CAR.wheels[1].toeIn,
            CAR.wheels[2].toeIn,
            CAR.wheels[3].toeIn,
        }
    end
    if not lineTable then return end

    --- store the line
    if self.logging then
        self.stint.lapTable[#self.stint.lapTable + 1] = Tconcat(lineTable, ";")
    end
    self.udpSender.send(lineTable, groupId, rate)
end




-- Logger step function  ==============================================================================================

function ApexLogger:step(dt)
    --- New lap detection:
    if self.logging and (CAR.lapCount > self.stint.prevLapCount) then
        table.insert(self.LOG.lapTimes, CAR.previousLapTimeMs / 1000)
        self:saveLap()
        self:newLap()
        self.stint.prevLapCount = CAR.lapCount > 0 and CAR.lapCount
            or SESSION.leaderboard[CAR.racePosition - 1].laps
    end
    
    if SIM.isInMainMenu then
        if self.logging then
            if self.app.settings.forceRaceMode then
                self:cancelStint()
            else
                self:shouldUpdateChannels()
                self:stop({console = true, toast = true})
            end
        end
        return
    end
    
    if SIM.isLookingAtSessionResults then
        if self.logging then self:stop({console = false, toast = false}) end
        return
    end
    
    --- Finished race detection:
    if self.stint.isInRace then
        if CAR.isRaceFinished
            or (not self.stint.isOnline and not SIM.isTimedRace and (SESSION.laps > 0 and SESSION.leaderboard[CAR.racePosition - 1].laps >= SESSION.laps))
            or (SIM.isTimedRace and SESSION.overtimeMs > 0)
            or CAR.isRetired
            or (SIM.raceFlagType == ac.FlagType.Stop)
            or (SIM.raceFlagType == ac.FlagType.Finished) then
            if self.logging then
                setTimeout(function()
                    self:stop({console = true, toast = true})
                end, 1, 'apex.race.save')
                self.app.settings.enable = false
            end
            return
        end
    end

    -- Race-end cases
    if (CAR.isInPitlane and (CAR.isRaceFinished or (SIM.raceFlagType == ac.FlagType.Finished)))
        or (self.stint.isInRace and not SIM.isTimedRace and SIM.sessionTimeLeft > 0)
        or (self.stint.isInRace and CAR.isRetired)
        or (SIM.raceFlagType == ac.FlagType.Stop) then
        if self.logging then self:stop({console = false, toast = true}) end
        return
    end

    -- Back to pits and pitstops
    if CAR.isInPit then
        if not self.stint.isInRace and not self.app.settings.forceRaceMode then
            if self.logging then
                self:shouldUpdateChannels()
                self:stop({console = true, toast = true})
            end
            return
        end
        -- race pit stops
        if self.stint.isInRace then
            if SIM.raceFlagType == ac.FlagType.Finished then
                if self.logging then self:stop({console = false, toast = false}) end
                return
            end
            if (self.stint.lapCounter > 1) and (SIM.raceFlagType ~= ac.FlagType.Finished) then
                self.helpers.notify(self.app.name, self.app.icons.ok, 'Race pitstop')
            end
        end
        if self.app.settings.forceRaceMode and not self.logging then
            return
        end
    end

    -- Start new log when leaving pit:
    if (self.stint.carOnTrack == false) and not CAR.isRaceFinished then
        if SIM.raceSessionType ~= self.app.sessionType then
            self.app.updateSession()
        end
        
        if SIM.isTimedRace and (SIM.timeToSessionStart > 0) then return end
        
        self.stint.startTime   = SIM.sessionTimeLeft + CAR.lapTimeMs
        self.stint.carOnTrack  = true
        if not self.stint.noRestart then
            self.stint.prevLapCount = CAR.lapCount
            if self.app.settings.enable then
                self:start()
            end
        else
            self.app.settings.enable = false
        end
        
        if self.stint.isInRace then
            self.stint.noRestart = true
        end
    end

    -- Hotlap fix: enable logger on late start (when on track)
    if not self.logging and self.stint.carOnTrack and self.app.settings.enable and not self.stint.noRestart then
        self.stint.startTime = SIM.sessionTimeLeft + CAR.lapTimeMs
        self.stint.prevLapCount = CAR.lapCount
        self:start()
    end

    -- Hotlap first-lap detection:
    if self.LOG == false then
        if self.app.settings.udpEnable then
            self:shouldUpdateChannels()
        end
        return
    end
    if self.app.spawnStart == 'HOTLAP_START' and CAR.lapCount == 0 then
        if not self.stint.hotlapStarted and CAR.lapTimeMs > 0 and CAR.lapTimeMs < 50 then
            self.stint.hotlapStarted = true
            table.insert(self.LOG.lapTimes,
                (Mabs(SIM.sessionTimeLeft - self.stint.startTime) / 1000)
                - (CAR.lapTimeMs / 1000) - dt)
            self:saveLap()
            self:newLap(false)
            self.appUI.updateUIlog("LOG: hotlap started", self.appUI.colors.GREY)
            return
        end
    end
    
    self:shouldUpdateChannels()
end

function ApexLogger:destroy()
    self = nil
end

return ApexLogger
