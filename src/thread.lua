-- InAdvent client thread!
if not lovr then lovr = require "lovr" end 
if not lovr.thread then lovr.thread = require "lovr.thread" end
if not lovr.filesystem then lovr.filesystem = require "lovr.filesystem" end 
if not enet then enet = require "enet" end 
if not json then json = require 'cjson' end
if not action_types then require "src/action_types" end 
if not EGA then local m = lovr.filesystem.load('src/lib.lua'); m() end 
-- Packets 
local packets = require 'src/packets'

local firstUpdate = true
local isConnected = false
local isLoggedIn = false
local isLoggingIn = false
local credentials = 'username1/password'
local lastBroadcast = 99
local clientId 
local lastPing = 99
local pings = {}
local broadcasts = {}
local myPlayerState = {
    pos = { x = 0.0, y = 0.0, z = 0.0 },
    rot = { x = 0.0, y = 0.0, z = 0.0, m = 0.0 },
    lHandPos = { x = 0.0, y = 0.0, z = 0.0 },
    lHandRot = { x = 0.0, y = 0.0, z = 0.0, m = 0.0 },
    lHandObj = '',
    rHandPos = { x = 0.0, y = 0.0, z = 0.0 },
    rHandRot = { x = 0.0, y = 0.0, z = 0.0, m = 0.0 },
    rHandObj = '',
    faceTx = '',
    bodyTx = '',
    action = ''
}
local lastPlayerState = {} 

-- Connect
local host = enet.host_create(nil, 64, 2, 0, 0)
-- Ben's AWS 01:
local server = host:connect("54.196.121.96:33111", 2)
--local server = host:connect("localhost:33111", 2)
-- Thread communication
local toMain = lovr.thread.getChannel('toMain')
local toThread = lovr.thread.getChannel('toThread')
local updatessent = 0

function ProcessEvent(o)
    if o.type == 'login_response' then 
        isLoggingIn = false
        isLoggedIn = true
        print("logged in")
        server:send(json.encode(packets.get_ping))
    elseif o.type == 'ping_response' then
        local v = o.ts
        local thisPing = v - lastPing
        table.insert(pings, thisPing)
        lastPing = v
        isConnected = true
        if clientId ~= o.playerId then 
            clientId = o.playerId 
            toMain:push('GivingClientID')
            toMain:push(clientId)
        end
    elseif o.type == 'state' then
        local v = o.ts
        local thisBroadcast = v - lastBroadcast
        table.insert(broadcasts, thisBroadcast)
        lastBroadcast = v
        currentState = o.data --TODO
        toMain:push('GivingWorldState') 
        toMain:push(json.encode(o.data))
        --printtable(o.data)
        -- Look for 'action' receipt here
    end
end

-- Main loop
while true do 
    
    local msg = toThread:pop()
    if msg ~= nil then 
        if msg == 'tick' then 
            local next = WaitForNext(toThread)
            myPlayerState = json.decode(next)
            if server then 
                local event
                event = host:service()
                if event then
                    if event.data ~= (0 or nil) then     
                        local o = json.decode(event.data)
                        --Do the event
                        ProcessEvent(o)
                    end
                else
                    if not isLoggedIn then
                        isLoggingIn = true
                        local loginPacket = packets.login_request
                        local userCreds = split(credentials, '/')
                        loginPacket.data.username = userCreds[1]
                        loginPacket.data.password = userCreds[2]
                        server:send(json.encode(loginPacket))
                    elseif (myPlayerState.UPDATE_ME or (firstUpdate and isConnected)) and isLoggedIn then 
                        local updatePacket = packets.update_position
                        updatePacket.data = myPlayerState
                        server:send(json.encode(updatePacket))
                        --updatesSent = updatesSent + 1
                        --print('ups sent : ' .. updatesSent)
                    end
                    -- Always send ping, man!
                    --server:send(json.encode(packets.get_ping))
                end
            end
        elseif msg == 'getbc' then 
            local avg = GetAverage(broadcasts)
            print('Average broadcast: ' .. round(avg, 1))
            avg = GetAverage(pings)
            print('Average ping: ' .. round(avg, 1))
        end
    end
end
