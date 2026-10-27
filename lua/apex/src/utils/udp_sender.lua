local APP_CFG = require("cfg/app")

local udpSender = {
    enabled = false,
    socket = nil,
    host = '127.0.0.1',
    port = 9996,
    seq = 0,
}

---@param host string target IP address
---@param port number target port
function udpSender.init(host, port)
    udpSender.host = host
    udpSender.port = tonumber(port)
    udpSender.seq = 0

    if udpSender.socket then
        if udpSender.socket.close then udpSender.socket:close() end
        udpSender.socket = nil
    end
    
    local success, socket = pcall(require, "socket")
    if success and socket and socket.udp then
        udpSender.socket = socket.udp()
        udpSender.socket:setpeername(udpSender.host, udpSender.port)
        
        local appUI = getApexUI and getApexUI()
        if appUI then
            appUI.updateUIlog(string.format("TX: started %s:%d", udpSender.host, udpSender.port), appUI.colors.GREEN)
        end
    else
        -- fallback if ac.net is provided instead
        if ac.net and ac.net.udp then
            udpSender.socket = ac.net.udp(udpSender.host, udpSender.port)
            
            local appUI = getApexUI and getApexUI()
            if appUI then
                appUI.updateUIlog(string.format("TX: active %s:%d", udpSender.host, udpSender.port), appUI.colors.GREEN)
            end
        else
            -- in case of socket module does not exist: we don't explode
            udpSender.enabled = false
            local app = getApexApp and getApexApp()
            if app then app.settings.udpEnable = false end
            
            local appUI = getApexUI and getApexUI()
            if appUI then 
                appUI.updateUIlog("TX: logger mode not available, socket module not found. ", appUI.colors.ORANGE)
            end
        end
    end
end

--- Configure sender state from app settings
---@param settings table appMain.settings
function udpSender.configure(settings)
    udpSender.enabled = settings.udpEnable or false
    udpSender.host = settings.udpHost
    udpSender.port = tonumber(settings.udpPort)
    
    if udpSender.enabled then
        udpSender.init(udpSender.host, udpSender.port)
    else
        udpSender.destroy()
    end
end

--- Send channel data as a UDP packet
--- called by the logger at each updateChannels() call with the line data table
---@param lineTable table group tick: "#groupId#", sessionTimeLeft, then the channel values
---@param groupId string the group identifier (e.g. "input", "gps", "susp")
---@param rate number the data rate in Hz (1, 10, or user Hz)
function udpSender.send(lineTable, groupId, rate)
    if not udpSender.enabled then return end
    if not udpSender.socket then return end

    -- seq restarts with the socket, a gap on the receiver means lost packets
    udpSender.seq = udpSender.seq + 1
    -- Format: APEX|<protocol>|<seq>|<groupId>|<rate>|<clock>|<sessionTimeLeft>|<val1>;<val2>;...
    local payload = string.format("APEX|%d|%d|%s|%d|%f|%s|%s", APP_CFG.TX_PROTOCOL, udpSender.seq, groupId, rate,
        os.preciseClock(), lineTable[2], table.concat(lineTable, ";", 3))
    
    if udpSender.socket.send then
        udpSender.socket:send(payload)
    end
end

--- clean up and close UDP socket
function udpSender.destroy()
    if udpSender.socket then
        if udpSender.socket.close then udpSender.socket:close() end
        udpSender.socket = nil
    end
end

return udpSender