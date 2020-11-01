--
-- InAdvent
--

local enet = require 'enet'
local json = require 'json'
local b64 = require 'base64'
local m = lovr.filesystem.load('lib.lua'); m()

-- Globals
player_flags = {
    MOVING_FORWARD = false,
    MOVING_BACKWARD = false,
    STRAFE_LEFT = false, 
    STRAFE_RIGHT = false, 
    TURNING_RIGHT = false,
    TURNING_LEFT = false 
}
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

serverTick = (1/40) -- 25ms, to target 50ms updates
currentState = {} -- world state .data
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

local playerSpeed = 5.0

local thread 
local channel 
threadCode = lovr.filesystem.read('thread.lua')

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

	satFont = lovr.graphics.newFont('saturno.ttf')

    -- Just in case!
    lovr.headset.setClipDistance(0.1, 100.0)

    t = lovr.thread.newThread(threadCode)
    channel = lovr.thread.getChannel('chan')
    t:start()

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

    -- keyboard for desktop
    if player_flags.MOVING_FORWARD then 
        p.z = p.z + (deltaTime * playerSpeed) * math.sin(p.rot)
        p.x = p.x + (deltaTime * playerSpeed) * math.cos(p.rot)
    elseif player_flags.MOVING_BACKWARD then 
        p.z = p.z - (deltaTime * playerSpeed) * math.sin(p.rot)
        p.x = p.x - (deltaTime * playerSpeed) * math.cos(p.rot)
    end
    if player_flags.STRAFE_RIGHT then 
        p.x = p.x + (deltaTime * playerSpeed) * math.cos(p.rot + math.pi/2)
        p.z = p.z + (deltaTime * playerSpeed) * math.sin(p.rot + math.pi/2)
    elseif player_flags.STRAFE_LEFT then 
        p.x = p.x + (deltaTime * playerSpeed) * math.cos(p.rot - math.pi/2)
        p.z = p.z + (deltaTime * playerSpeed) * math.sin(p.rot - math.pi/2)
    end
    if player_flags.TURNING_RIGHT then 
        p.rot = p.rot + (deltaTime * playerSpeed/2)
    elseif player_flags.TURNING_LEFT then 
        p.rot = p.rot - (deltaTime * playerSpeed/2)
    end
    if player_flags.MOVING_BACKWARD or player_flags.MOVING_FORWARD or player_flags.STRAFE_RIGHT or player_flags.STRAFE_LEFT or player_flags.TURNING_LEFT or player_flags.TURNING_RIGHT then 
        myPlayerState.UPDATE_ME = true 
    else myPlayerState.UPDATE_ME = false end 

    -- Update my state for the thread!
    myPlayerState.pos.x = round(p.x, 3); myPlayerState.pos.y = round(p.y, 3); myPlayerState.pos.z = round(p.z, 3);

	-- CLIENT service called right before draw()
	serverTick = serverTick - deltaTime 
	if serverTick < 0 then 
		serverTick = serverTick + (1/40)
        channel:push('tick')
        channel:push(json.encode(myPlayerState))
	end
    --coroutine.resume(serviceCall)

end

function lovr.keypressed(key, scancode, rep)
    if key == 'w' then 
        player_flags.MOVING_FORWARD = true
    elseif key == 's' then 
        player_flags.MOVING_BACKWARD = true
    elseif key == 'd' then 
        player_flags.STRAFE_RIGHT = true 
    elseif key == 'a' then 
        player_flags.STRAFE_LEFT = true 
    elseif key == 'right' then 
        player_flags.TURNING_RIGHT = true 
    elseif key == 'left' then 
        player_flags.TURNING_LEFT = true 
    end
end

function lovr.keyreleased(key, sc, r)
    if key == 'w' then 
        player_flags.MOVING_FORWARD = false
    elseif key == 's' then 
        player_flags.MOVING_BACKWARD = false 
    elseif key == 'd' then 
        player_flags.STRAFE_RIGHT = false 
    elseif key == 'a' then 
        player_flags.STRAFE_LEFT = false 
    elseif key == 'right' then 
        player_flags.TURNING_RIGHT = false
    elseif key == 'left' then 
        player_flags.TURNING_LEFT = false 
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
    lovr.graphics.setColor(0, 1, 0, 1)
    lovr.graphics.plane('fill', 0, 0, 0, 20, 20, math.pi/2, 1, 0, 0)
    lovr.graphics.setColor(1, 1, 1, 1)

	lovr.graphics.setShader()
	lovr.graphics.setFont(satFont)
    lovr.graphics.print('ima fk uup\npoing!', 2, 3, -6)

    lovr.graphics.reset()
end

function lovr.quit()

	channel:push('getbc')
	
end