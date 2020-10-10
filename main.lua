--
-- InAdvent
--

local enet = require 'enet'
local json = require 'json'
local b64 = require 'base64'
local m = lovr.filesystem.load('lib.lua'); m()

-- Globals
shader = nil
camera = nil
view = nil
p = {
    x = 0.0, y = 0.0, z = 0.0, 
    rot = -math.pi/2,
    h = 1.7
}
deltaTime = 0.0
gameTime = 0.0

-- Network defs
host = nil
server = nil
clientId = nil
serverTick = (1/40) -- 25ms, to target 50ms updates
pings = {}
lastPing = 0

loginRequest = {
    message_type = 'login', 
    data = {
        player_username = "user",
        password = "password"
    }
}

pong = {
    message_type = "pong",
    data = {}
}

get_ping = { 
    message_type = "get_ping",
    data = {}
}
--

function lovr.load()

    -- Setup shaders
    local defaultVert = lovr.filesystem.read('default.vert')
    local defaultFrag = lovr.filesystem.read('default.frag')

    shader = lovr.graphics.newShader(defaultVert, defaultFrag, 
        { flags = { uniformScale = true } }
    )

    -- Load models
    p_body = lovr.graphics.newModel('p_body.glb')
    p_head = lovr.graphics.newModel('p_head.glb')
    sword1 = lovr.graphics.newModel('sword1.glb')

    -- Load textures
    texChain = lovr.graphics.newTexture('chainmail.png')
    texChain:setFilter('nearest')
    texFace1 = lovr.graphics.newTexture('face1.png')
    texFace1:setFilter('nearest')
    texSwd1 = lovr.graphics.newTexture('sword1.png')
    texSwd1:setFilter('nearest')

    -- Just in case!
    lovr.headset.setClipDistance(0.1, 100.0)

    -- Connect
    host = enet.host_create()
    -- Ben's AWS 01:
    server = host:connect("54.196.121.96:33111")
    
end

function lovr.update(dT)
    deltaTime = dT
    gameTime = gameTime + dT

    -- VIEW
    camera = lovr.math.newMat4():lookAt(
        vec3(p.x, p.y + p.h, p.z),
        vec3(p.x + math.cos(p.rot), 
             p.y + p.h, 
             p.z + math.sin(p.rot)))
    view = lovr.math.newMat4(camera):invert()

    -- CLIENT
    serverTick = serverTick - dT 
    if serverTick < 0 then 
        if clientId == nil then serverTick = serverTick + 3.0 end
        serverTick = serverTick + (1/40)
        if server then
            if clientId == nil then 
                server:send(json.encode(loginRequest))    
            end
            local event = host:service()
            if event then 
                if event.data ~= 0 then     
                    --client.process(event)
                    local o = json.decode(event.data)
                    if o.type == 'login_response' then 
                        clientId = o.clientId 
                        serverTick = (1/40)
                        print(event.data)
                    elseif o.type == 'ping_response' then
                        local thisPing = o.value - lastPing
                        table.insert(pings, thisPing)
                        lastPing = o.value
                    end
                end
            else
                server:send(json.encode(get_ping))
            end
        end
    end
end

function lovr.mirror()
    lovr.graphics.clear()
    lovr.graphics.transform(view)
    lovr.draw()
end

function lovr.draw()
    lovr.graphics.setShader(shader)

    --lovr.graphics.sphere(0, 1, -3)
    shader:send('curTex', texChain)
    p_body:draw(0, p.h - 0.25, -5)
    shader:send('curTex', texFace1)
    p_head:draw(0, p.h + 0, -5)
    shader:send('curTex', texSwd1)
    sword1:draw(-1, 1, -5, 1, gameTime*4, 1, 0, 0)

    lovr.graphics.setShader()
    lovr.graphics.print('ima fk uup', 2, 3, -6)

    lovr.graphics.reset()
end

function lovr.quit()
    -- Print average ping!
    local avg = 0
    for i=1,#pings do 
        if pings[i] > 999 then pings[i] = 999 end
        avg = avg + pings[i]
    end
    avg = avg / #pings 
    print('Average ping: ' .. round(avg, 1))
    --
end