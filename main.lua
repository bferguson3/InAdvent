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

function lovr.load()
    local defaultVert = lovr.filesystem.read('default.vert');
    local defaultFrag = lovr.filesystem.read('default.frag');

    shader = lovr.graphics.newShader(defaultVert, defaultFrag, 
        { flags = { uniformScale = true } }
    );

    host = enet.host_create()
    server = host:connect("127.0.0.1:8888")

    lovr.headset.setClipDistance(0.1, 100.0);
end

serverTick = 0.05

function lovr.update(dT)
    deltaTime = dT;
    
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
        local go = { HeadX = p.x, HeadY = p.y, HeadZ = p.z }
        server:send(b64.enc(json.encode(go)));
    end
    if server then 
        local event = host:service()
        if event then 
            print('Event: ' .. event.type)
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

    lovr.graphics.sphere(0, 1, -3);

    lovr.graphics.setShader();
    lovr.graphics.print('Hello World', 0, 1, -3);

    lovr.graphics.reset();
end

function lovr.quit()

end