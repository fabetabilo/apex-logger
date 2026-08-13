--[[
    App configuration
    - change the app VERSION here and in manifest.ini
    - All modules read from this table
]]

local APP = {
    NAME    = "Apex",
    VERSION = "0.2",
    
    -- Supported data sampling rates (Hz):
    DATA_RATES = {25, 30, 50, 75, 100, 150},
    
    URL_UPDATE = "https://github.com/repo/releases",
    URL_DOCS   = "https://github.com/repo/wiki",
}

return APP