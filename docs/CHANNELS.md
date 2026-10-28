## Channels

> Document aligned with version `0.2.6` of the logger.

Reference for every channel Apex Datalogger records. Values are written raw, exactly as CSP reports them, with no unit conversion.

### Sampling rates

| Rate | Groups |
|---|---|
| 1 Hz | `session`, `car_info` |
| 10 Hz | `tires`, `dyn`, `ext_elec`, `aero`, `sim_info` |
| Selectable: 30, 50, 60, 100 or 120 Hz | `input`, `gps`, `tires_dyn`, `gforce`, `susp` |

CSP updates car data once per rendered frame, so the real rate of the fast groups is capped by the game FPS. `effectiveRates` in the JSON shows what was actually recorded.

### Conventions

- **Wheels:** wheel suffixes are `fl`, `fr`, `rl`, `rr`, which map to CSP wheel indices 0, 1, 2 and 3.
- **Unit marks:**
  - No mark: the unit is documented in the CSP SDK.
  - `*`: inferred from Assetto Corsa conventions and checked against recorded ranges.
  - `?`: unverified.
- **Unit names:**
  - `0–1` is a ratio.
  - `flag` is `0` / `1` (boolean)
  - `index` is a setting or enum code.
  - `—` means unitless.

### Channels

### `session` (1 Hz)

| Channel | Source (CSP) | Description | Unit |
|---|---|---|---|
| `airtemp` | `SIM.ambientTemperature` | Ambient air temperature | °C* |
| `airdens` | `CPHYS.airDensity` | Air density, affected by slipstream | kg/m³* |
| `roadtemp` | `SIM.roadTemperature` | Road temperature, can vary in shadows if the CSP option is enabled | °C* |
| `roadgrip` | `SIM.roadGrip` | Track grip | 0–1 |
| `winddir` | `SIM.windDirectionDeg` | Wind direction in world space, track heading included | deg |
| `windspeed` | `SIM.windSpeedKmh` | Wind speed | km/h |
| `raceflagtype` | `SIM.raceFlagType` | Flag shown to the driver (`ac.FlagType`) | index |
| `weatherType` | `SIM.weatherType` | Weather type (`ac.WeatherType`) | index |


### `car_info` (1 Hz)

| Channel | Source (CSP) | Description | Unit |
|---|---|---|---|
| `lastsectortime` | `CAR.previousSectorTime`, or the last entry of `CAR.lastSplits` while in the first sector | Time of the previous sector | ms |
| `fuellevel` | `CAR.fuel` | Remaining fuel | l |
| `brakebias` | `CAR.brakeBias` | Brake bias, front share | 0–1* |
| `invalidlap` | `CAR.isLapValid`, inverted | `1` when the current lap is invalid | flag |
| `ebsetting` | `CAR.currentEngineBrakeSetting` | Engine brake setting | index |
| `tiregripfl` `tiregripfr` `tiregriprl` `tiregriprr` | `CAR.wheels[i].tyreWear` | Tyre wear, 0 = new | 0–1 |
| `virtualkmfl` `virtualkmfr` `virtualkmrl` `virtualkmrr` | `CAR.wheels[i].tyreVirtualKM` | Virtual tyre distance; resets on tyre change, and its rate depends on tyre usage | km |
| `damagefront` | `CAR.damage[0]` | Front damage, as collision speed | km/h |
| `damageright` | `CAR.damage[3]` | Right damage, as collision speed | km/h |
| `damagerear` | `CAR.damage[1]` | Rear damage, as collision speed | km/h |
| `damageleft` | `CAR.damage[2]` | Left damage, as collision speed | km/h |
| `tyresCompound` | `CAR.compoundIndex` | Selected compound, an index into `tyresAvail` in the JSON | index |
| `racePosition` | `CAR.racePosition` | Race position, 1 = first | — |
| `engineLifeLeft` | `CAR.engineLifeLeft` | Engine life: 1000 when new, breaks at 0 | — |
| `gearboxDamage` | `CAR.gearboxDamage` | Gearbox damage: 0 when new, 1 when broken | 0–1 |
| `oilTemperature` | `CAR.oilTemperature` | Oil temperature | °C* |
| `waterTemperature` | `CAR.waterTemperature` | Water temperature, an approximation by original AC | °C |
| `absMode` | `CAR.absMode` | ABS setting, 0 = off | index |
| `tcMode` | `CAR.tractionControlMode` | Traction control setting, 0 = off | index |
| `tc2Mode` | `CAR.tractionControl2` | Second traction control setting | index* |
| `fuelMap` | `CAR.fuelMap` | Fuel map preset | index |
| `relplankwear` | `CAR.maxRelativePlankWear` | Highest relative plank wear, 0 if not available | 0–1 |

### `tires` (10 Hz)

| Channel | Source (CSP) | Description | Unit |
|---|---|---|---|
| `tirepressfl` `tirepressfr` `tirepressrl` `tirepressrr` | `CAR.wheels[i].tyrePressure` | Dynamic tyre pressure | psi* |
| `tiresurfdirtfl` `tiresurfdirtfr` `tiresurfdirtrl` `tiresurfdirtrr` | `CAR.wheels[i].surfaceDirt` | Dirt coefficient of the surface below the wheel | — |
| `tiretmpcorefl` `tiretmpcorefr` `tiretmpcorerl` `tiretmpcorerr` | `CAR.wheels[i].tyreCoreTemperature` | Tyre core temperature | °C |
| `tiretmpinnerfl` `tiretmpinnerfr` `tiretmpinnerrl` `tiretmpinnerrr` | Left wheels: `tyreOutsideTemperature`; right wheels: `tyreInsideTemperature` | Inner tread temperature, relative to the car | °C |
| `tiretmpmiddlefl` `tiretmpmiddlefr` `tiretmpmiddlerl` `tiretmpmiddlerr` | `CAR.wheels[i].tyreMiddleTemperature` | Middle tread temperature | °C |
| `tiretmpouterfl` `tiretmpouterfr` `tiretmpouterrl` `tiretmpouterrr` | Left wheels: `tyreInsideTemperature`; right wheels: `tyreOutsideTemperature` | Outer tread temperature, relative to the car | °C |
| `tyreGrainfl` `tyreGrainfr` `tyreGrainrl` `tyreGrainrr` | `CAR.wheels[i].tyreGrain` | Tyre graining level | —? |
| `tyreBlisterfl` `tyreBlisterfr` `tyreBlisterrl` `tyreBlisterrr` | `CAR.wheels[i].tyreBlister` | Tyre blistering level | —? |
| `braketempfl` `braketempfr` `braketemprl` `braketemprr` | `CAR.wheels[i].discTemperature` | Brake disc temperature | °C* |

### `dyn` (10 Hz)

| Channel | Source (CSP) | Description | Unit |
|---|---|---|---|
| `numtiresout` | `CAR.wheelsOutside` | Wheels outside the allowed track area | count |
| `drivetrainTorque` | `CAR.drivetrainTorque` | Drivetrain torque | Nm* |
| `drivetrainPower` | `CAR.drivetrainPower` | Drivetrain power; matches torque × engine speed expressed in hp | hp* |
| `drivetrainspeed` | `CAR.drivetrainSpeed` | Speed delivered to the wheels; matches the angular speed of the driven wheels | rad/s* |

### `ext_elec` (10 Hz)

| Channel | Source (CSP) | Description | Unit |
|---|---|---|---|
| `drsavail` | `CAR.drsAvailable` | DRS available | flag |
| `drsact` | `CAR.drsActive` | DRS active | flag |
| `erscharging` | `CAR.mguhChargingBatteries` | MGU-H charging the battery | flag |
| `kersdeployed` | `CAR.kersCurrentKJ` | KERS / ERS energy used in the current lap | kJ* |
| `kersinput` | `CAR.kersInput` | KERS deploy input | 0–1* |
| `kerscharge` | `CAR.kersCharge` | Battery charge | 0–1* |

### `aero` (10 Hz)

| Channel | Source | Description | Unit |
|---|---|---|---|
| `aerodrag` | Aero module | Aerodynamic drag force | N* |
| `aeroDownforceFront` | Aero module | Front downforce | N* |
| `aeroDownforceRear` | Aero module | Rear downforce | N* |

The aero module (`src/utils/aero.lua`) picks a source per car and updates at most every 50 ms:

| Car | Source |
|---|---|
| CSP aeromap | The `apex` Python app (`ac.ext_getDrag`, `ac.ext_getDownforce`) |
| Encrypted, with the Python app | Total downforce from the Python app, split 45% front / 55% rear (estimate) |
| Kunos wings | Sum of the wing `CL` / `CD` × 0.5·ρ·v², with the front/rear balance from wing positions |
| No Python app, or no wings | 0 |

### `sim_info` (10 Hz)

| Channel | Source (CSP) | Description | Unit |
|---|---|---|---|
| `ffbPure` | `CAR.ffbPure` | Force feedback before post-processing | —? |
| `ffbFinal` | `CAR.ffbFinal` | Force feedback sent to the wheel | —? |
| `fps` | `SIM.fps` | Frames per second; caps the real rate of the fast groups | fps |
| `physicsLate` | `SIM.physicsLate` | Late physics steps | count? |
| `cpuTime` | `SIM.cpuTime` | CPU time | ms? |

### `input` (selectable rate)

| Channel | Source (CSP) | Description | Unit |
|---|---|---|---|
| `clutch` | `CAR.clutch` | Clutch travel | 0–1 |
| `absactive` | `CAR.absInAction` | ABS acting | flag |
| `tcactive` | `CAR.tractionControlInAction` | Traction control acting | flag |
| `speed` | `CAR.speedKmh` | Car speed | km/h |
| `posnorm` | `CAR.splinePosition` | Position along the lap: 0 at the start line, 1 at the finish line | 0–1 |
| `laptime` | `CAR.lapTimeMs` | Current lap time | ms |
| `drivenInRace` | `CAR.drivenInRace` | Distance driven; resets every lap in practice and qualifying, accumulates in races | m |
| `lapcount` | `CAR.lapCount` | Completed laps in the session, invalid laps included | count |
| `throttle` | `CAR.gas` | Throttle | 0–1 |
| `brake` | `CAR.brake` | Brake | 0–1 |
| `handbrake` | `CAR.handbrake` | Handbrake | 0–1 |
| `steerAngle` | `CAR.steer` | Steering wheel angle | deg |
| `steerTorque` | `CAR.steerTorque` | Steering torque | ? |
| `gear` | `CAR.gear` | Gear: 0 = neutral, −1 = reverse | index |
| `rpm` | `CAR.rpm` | Engine speed | rpm |
| `brakeTorqueFL` `brakeTorqueFR` `brakeTorqueRL` `brakeTorqueRR` | `CPHYS.wheels[i].brakeTorque` | Brake torque per wheel | Nm* |
| `turboboost` | `CAR.turboBoost` | Turbo boost, from 0 upwards | bar |

### `gps` (selectable rate)

| Channel | Source (CSP) | Description | Unit |
|---|---|---|---|
| `posx` | `CAR.position.x` | World position, X axis | m* |
| `posy` | `CAR.position.z` | World position, horizontal Y axis (AC Z axis) | m* |
| `posz` | `CAR.position.y` | Height (AC Y axis) | m* |
| `velx` | `CAR.localVelocity.z` | Forward velocity, in the car frame | m/s* |
| `vely` | `CAR.localVelocity.x` | Lateral velocity, in the car frame | m/s* |
| `velz` | `CAR.localVelocity.y` | Vertical velocity, in the car frame | m/s* |
| `carHeading` | `CAR.compass` | Heading; recorded range −180 to 180 | deg |
| `pitchrate` | `CAR.localAngularVelocity.z` | Rotation around the forward axis; likely roll rate (see caveats) | rad/s* |
| `pitchangle` | `CAR.look.y` | Sine of the pitch angle relative to the world, track slope included (see caveats) | — |
| `rollrate` | `CAR.localAngularVelocity.x` | Rotation around the lateral axis; likely pitch rate (see caveats) | rad/s* |
| `rollangle` | `CAR.side.y` | Sine of the roll angle relative to the world, track camber included (see caveats) | — |
| `yawrate` | `CAR.localAngularVelocity.y` | Rotation around the vertical axis | rad/s* |

### `tires_dyn` (selectable rate)

| Channel | Source (CSP) | Description | Unit |
|---|---|---|---|
| `wheelspeedFL` `wheelspeedFR` `wheelspeedRL` `wheelspeedRR` | `CAR.wheels[i].angularSpeed` | Wheel angular speed; × loaded radius gives the ground speed | rad/s* |
| `ndslipfl` `ndslipfr` `ndsliprl` `ndsliprr` | `CAR.wheels[i].ndSlip` | Normalized slip | —* |
| `tireloadfl` `tireloadfr` `tireloadrl` `tireloadrr` | `CAR.wheels[i].load` | Vertical tyre load | N |
| `tireloadedradfl` `tireloadedradfr` `tireloadedradrl` `tireloadedradrr` | `CAR.wheels[i].tyreLoadedRadius` | Loaded tyre radius | m* |
| `tireslipanglefl` `tireslipanglefr` `tireslipanglerl` `tireslipanglerr` | `CAR.wheels[i].slipAngle` | Slip angle | deg |
| `tireslipratiofl` `tireslipratiofr` `tireslipratiorl` `tireslipratiorr` | `CAR.wheels[i].slipRatio` | Slip ratio | —* |
| `tirelongforcefl` `tirelongforcefr` `tirelongforcerl` `tirelongforcerr` | `CAR.wheels[i].fx` | Longitudinal tyre force | N* |
| `tirelatforcefl` `tirelatforcefr` `tirelatforcerl` `tirelatforcerr` | `CAR.wheels[i].fy` | Lateral tyre force | N* |

### `gforce` (selectable rate)

| Channel | Source (CSP) | Description | Unit |
|---|---|---|---|
| `cgaccellat` | `CAR.acceleration.x` | Lateral acceleration | G |
| `cgaccellong` | `CAR.acceleration.z` | Longitudinal acceleration | G |
| `cgaccelvert` | `CAR.acceleration.y` | Vertical acceleration, gravity excluded | G |

### `susp` (selectable rate)

| Channel | Source | Description | Unit |
|---|---|---|---|
| `rideheightfront` | `CAR.rideHeight[0]` | Front ride height | m* |
| `rideheightrear` | `CAR.rideHeight[1]` | Rear ride height | m* |
| `cgheight` | `CAR.cgHeight` | Centre of gravity height | m* |
| `susptravelfl` `susptravelfr` `susptravelrl` `susptravelrr` | `CAR.wheels[i].suspensionTravel` | Suspension travel | m* |
| `tirealignntrqfl` `tirealignntrqfr` `tirealignntrqrl` `tirealignntrqrr` | `CAR.wheels[i].mz` | Self-aligning torque | Nm* |
| `damperTravelFL` `damperTravelFR` `damperTravelRL` `damperTravelRR` | Python app: `ac.ext_getDamperTravel(0–3)` × 1000 | Damper travel | mm |
| `damperTravelHF` `damperTravelHR` | Python app: `ac.ext_getDamperTravel(4–5)` × 1000 | Heave damper travel, front and rear | mm |
| `caster` | `CAR.caster` | Caster angle | deg |
| `camberfl` `camberfr` `camberrl` `camberrr` | `CAR.wheels[i].camber` | Camber angle | deg |
| `toefl` `toefr` `toerl` `toerr` | `CAR.wheels[i].toeIn` | Toe angle; front wheels include steering | deg |
