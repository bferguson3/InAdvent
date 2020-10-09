-- InAdvent

local enet = require 'enet'
local json = require 'json'
local b64 = require 'base64'

shader = nil;
camera = nil;
view = nil;
p = {
    x = 0.0, y = 0.0, z = 0.0, 
    rot = -math.pi/2,
    h = 1.7
};
deltaTime = 0.0;
host = nil
server = nil

loginRequest = {
    message_type = 'login', 
    data = {
        player_username = "user",
        password = "password"
    }
}

function lovr.load()
    local defaultVert = lovr.filesystem.read('default.vert');
    local defaultFrag = lovr.filesystem.read('default.frag');

    shader = lovr.graphics.newShader(defaultVert, defaultFrag, 
        { flags = { uniformScale = true } }
    );

    host = enet.host_create()
    server = host:connect("174.99.126.77:9521")
    server:send(json.encode(loginRequest))

    p_body = lovr.graphics.newModel('p_body.glb')
    p_head = lovr.graphics.newModel('p_head.glb')
    sword1 = lovr.graphics.newModel('sword1.glb')

    texChain = lovr.graphics.newTexture('chainmail.png')
    texChain:setFilter('nearest')
    texFace1 = lovr.graphics.newTexture('face1.png')
    texFace1:setFilter('nearest')
    texSwd1 = lovr.graphics.newTexture('sword1.png')
    texSwd1:setFilter('nearest')

    lovr.headset.setClipDistance(0.1, 100.0);
end

serverTick = 0.05
gameTime = 0.0

function lovr.update(dT)
    deltaTime = dT;
    gameTime = gameTime + dT;

    -- VIEW
    camera = lovr.math.newMat4():lookAt(
        vec3(p.x, p.y + p.h, p.z),
        vec3(p.x + math.cos(p.rot), 
             p.y + p.h, 
             p.z + math.sin(p.rot)));
    view = lovr.math.newMat4(camera):invert();

    -- CLIENT
    serverTick = serverTick - dT 
    if serverTick < 0 then 
        serverTick = serverTick + 0.05
        --local go = loginRequest
        --server:send(json.encode(go));
    end
    if server then 
        local event = host:service()
        if event then 
            print('Event: ' .. event.type)
            if event.data ~= 0 then 
                print(event.data)
            end
        end
    end
end

function lovr.mirror()
    lovr.graphics.clear();
    lovr.graphics.transform(view);
    lovr.draw();
end

function lovr.draw()
    lovr.graphics.setShader(shader);

    --lovr.graphics.sphere(0, 1, -3);
    shader:send('curTex', texChain)
    p_body:draw(0, p.h - 0.25, -5)
    shader:send('curTex', texFace1)
    p_head:draw(0, p.h + 0, -5)
    shader:send('curTex', texSwd1)
    sword1:draw(-1, 1, -5, 1, gameTime*4, 1, 0, 0)

    lovr.graphics.setShader();
    lovr.graphics.print('ima fk uup', 2, 3, -6);

    lovr.graphics.reset();
end

function lovr.quit()

end