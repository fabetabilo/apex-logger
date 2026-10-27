--[[
    App configuration
    - change the app VERSION here and in manifest.ini
    - All modules read from this table
    - DATA_RATES: Supported sampling rates for fast groups (Hz). Real samples are capped by the game FPS
    - TX_PROTOCOL: UDP packet format version, bump it when the packet layout or a group's channel order changes
]]

local APP = {
    NAME    = "Apex",
    VERSION = "0.2.6",
    DATA_RATES = {30, 50, 60, 100, 120},
    TX_PROTOCOL = 1,
    URL_UPDATE = "https://github.com/fabetabilo/apex-logger/releases",
    URL_DOCS   = "https://fabetabilo.github.io/apex-docs/datalogger/getting-started/",
}

return APP