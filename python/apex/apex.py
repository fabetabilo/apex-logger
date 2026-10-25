"""
Apex python app
Reads CSP additional telemetry data (aero, dampers) and shares it with the Lua app via ac.ext_storeLua()
"""

import ac, acsys


appName = "apex"

def acMain(ac_version):
    return appName

ac.log('Apex python buffer initialized')


# About rate update =======================================================================================
#
# acUpdate runs once per rendered frame, and the Lua app reads the latest stored values on every update.
# "rate" must stay below the period of the highest sampling rate in the Lua app (cfg/app.lua -> DATA_RATES,
# 120Hz = 0.0083), so the stored values are always fresh when Lua samples. Updating faster is harmless.

deltaL = 1
rate = 0.0065

def acUpdate(dt):
    global deltaL

    if deltaL + dt > rate:
        vals = [
            # drag, downforce front and rear
            ac.ext_getDrag(),
            ac.ext_getDownforce(0),
            ac.ext_getDownforce(1),
            # damper travel (mm): FL, FR, RL, RR, HF, HR
            ac.ext_getDamperTravel(0) * 1000,
            ac.ext_getDamperTravel(1) * 1000,
            ac.ext_getDamperTravel(2) * 1000,
            ac.ext_getDamperTravel(3) * 1000,
            ac.ext_getDamperTravel(4) * 1000,
            ac.ext_getDamperTravel(5) * 1000
        ]
        # -- store for lua app to be read via "ac.load('apex.pySerialData')"
        ac.ext_storeLua('apex.pySerialData', ",".join(map(str, vals)))
        
        deltaL = 0
    
    deltaL += dt
