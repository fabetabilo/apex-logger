--[[
    App configuration
    - change the app VERSION here and in manifest.ini
    - All modules read from this table
    - DATA_RATES: Supported sampling rates for fast groups (Hz). Real samples are capped by the game FPS
]]

local APP = {
    NAME    = "Apex",
    VERSION = "0.2.4",
    DATA_RATES = {30, 50, 60, 100, 120},
    URL_UPDATE = "https://github.com/fabetabilo/apex-logger/releases",
    URL_DOCS   = "https://fabetabilo.github.io/apex-docs/datalogger/getting-started/",
}

return APP