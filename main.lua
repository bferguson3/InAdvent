--
-- InAdvent
--

TARGETING_OCULUS_QUEST = false

if not enet then enet = require 'enet' end 
if not json then json = require 'cjson' end 
if not b64 then b64 = require 'src/base64' end 
if not EGA then local m = lovr.filesystem.load('src/lib.lua'); m() end 
local letters = require 'src/letters'

sin = math.sin
cos = math.cos 
lg = lovr.graphics 

-- Globals
shader = nil
camera = nil
view = nil
p = {
    x = 0.0, y = 0, z = 0.0, 
    rot = -math.pi/2,
    h = 0.0,
    flags = {
        MOVING_FORWARD = false,
        MOVING_BACKWARD = false,
        STRAFE_LEFT = false, 
        STRAFE_RIGHT = false, 
        TURNING_RIGHT = false,
        TURNING_LEFT = false 
    }
}
local leftHand = {
    x = 0, y = 0, z = 0,
    an = 0, ax = 0, ay = 0, az = 0
}
local rightHand = {
    x = 0, y = 0, z = 0,
    an = 0, ax = 0, ay = 0, az = 0
}

if not TARGETING_OCULUS_QUEST then p.y = 1.6 end
deltaTime = 0.0
gameTime = 0.0

serverTick = (1/40) -- 25ms, to target 50ms updates
currentState = {
    players = {}
} ; lastState = { players = {} }
-- world state .data
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
local firstUpdate = false
local toThread 
local toMain 
local channel 
threadCode = lovr.filesystem.read('src/thread.lua')

local headsetState = {
    x = 0, y = 0, z = 0,
    an = 0, ax = 0, ay = 1, az = 0
}

local ori = {
    x = 0, y = 0, z = 0, an = 0, ax = 0, ay = 1, az = 0
}
local hr 

letters_drawables = {}

function InitializeKBDrawables()
    local drawables = letters_drawables
      
      font = lovr.graphics.newFont(16)
      table.insert(drawables, letters.TextField:new{
        position = lovr.math.newVec3(-3, p.y+p.h+2, -5),
        font = font,
        --onReturn = function() drawables[4]:makeKey(); return false; end,
        placeholder = "USERNAME"
      })
      table.insert(drawables, letters.TextField:new{
        position = lovr.math.newVec3(-3, p.y+p.h+1, -5),
        font = font,
        placeholder = "PASSWORD"
      })
      drawables[1]:deselect()
      
      for i, hand in ipairs(letters.hands) do
        table.insert(drawables, hand)
      end
end

function lovr.load()
    
    ori.x, ori.y, ori.z, ori.an, ori.ax, ori.ay, ori.az = lovr.headset.getPose()

    if TARGETING_OCULUS_QUEST then letters.load() end 
    letters.defaultKeyboard = letters.HoverKeyboard
    InitializeKBDrawables()

    -- Setup shaders
    local defaultVert = lovr.filesystem.read('shaders/default.vert')
    local defaultFrag = lovr.filesystem.read('shaders/default.frag')

    shader = lovr.graphics.newShader(defaultVert, defaultFrag, 
        { flags = { uniformScale = true } }
    )

    -- Load models
    p_body = lovr.graphics.newModel('assets/p_body.glb')
    p_head = lovr.graphics.newModel('assets/p_head.glb')
    sword1 = lovr.graphics.newModel('assets/sword1.glb')
    hand = lovr.graphics.newModel('assets/blockyhand.glb')
    gob_a = lg.newModel('assets/goblin-a.glb')

    -- Load textures
    texChain = lovr.graphics.newTexture('assets/chainmail.png')
    texChain:setFilter('nearest')
    texFace1 = lovr.graphics.newTexture('assets/face1.png')
    texFace1:setFilter('nearest')
    texSwd1 = lovr.graphics.newTexture('assets/sword1.png')
    texSwd1:setFilter('nearest')
    texGob_a = lg.newTexture('assets/orc-uv-front.png')
    texGob_a:setFilter('nearest')

	satFont = lovr.graphics.newFont('assets/saturno.ttf')

    -- Just in case!
    lovr.headset.setClipDistance(0.1, 100.0)

    local scr_w, scr_h
    if TARGETING_OCULUS_QUEST then 
        scr_w, scr_h = lovr.headset.getDisplayDimensions()
        GUI = lovr.graphics.newCanvas(scr_w, scr_h, { stereo = true})
    else 
        scr_w, scr_h = 1080, 600 
        GUI = lovr.graphics.newCanvas(scr_w, scr_h, { stereo = false })
    end

    t = lovr.thread.newThread(threadCode)
    toMain = lovr.thread.getChannel('toMain')
    toThread = lovr.thread.getChannel('toThread')
    t:start()

    print('Debug: LOAD completed')
end

local clientId

function GetPoseTable(pose)
    local fx, fy, fz, fan, fax, fay, faz = lovr.headset.getPose(pose)
    local o = { x = fx, y = fy, z = fz, an = fan, ax = fax, ay = fay, az = faz }
    return o
end

local tempv = 0
tickPercent = 0

function lovr.update(dT)
    deltaTime = dT
    gameTime = gameTime + dT
    tickPercent = tickPercent + dT 
    
    headsetState = GetPoseTable('head')
    p.h = headsetState.y

    -- Get pending info from Thread if any 
    local cmsg = toMain:pop()
    if cmsg ~= nil then 
        if cmsg == 'GivingClientID' then 
            clientId = WaitForNext(toMain)
            print(clientId)
        elseif cmsg == 'GivingWorldState' then 
            lastState = currentState 
            currentState = json.decode(WaitForNext(toMain))
            tickPercent = 0
            tempv = tempv + 1
            --print('state' .. tempv)
        end
    end

    -- [[ PLAYER UPDATE ]]

    if TARGETING_OCULUS_QUEST then 
        -- keyboard
        letters.update()
        for i, t in ipairs(letters_drawables) do 
            t:update()
        end    
        -- hands
        for i, hand in ipairs(lovr.headset.getHands()) do
            if hand == 'hand/left' then leftHand = GetPoseTable(hand) elseif 
                hand == 'hand/right' then rightHand = GetPoseTable(hand)
            end 
        end
        --print(lx, ly) -- UP is Y+, DOWN is Y-, LEFT is X-, RIGHT is X+
        --projected: 
        local lx, ly = lovr.headset.getAxis('hand/left', 'thumbstick')
        if ly < -0.5 then p.flags.MOVING_BACKWARD = true else 
            p.flags.MOVING_BACKWARD = false end 
        if ly > 0.5 then p.flags.MOVING_FORWARD = true else 
            p.flags.MOVING_FORWARD = false end 
        if lx < -0.5 then p.flags.STRAFE_LEFT = true else 
            p.flags.STRAFE_LEFT = false end 
        if lx > 0.5 then p.flags.STRAFE_RIGHT = true else 
            p.flags.STRAFE_RIGHT = false end 
        local rx, ry = lovr.headset.getAxis('hand/right', 'thumbstick')
        if rx > 0.5 then p.flags.TURNING_RIGHT = true else 
            p.flags.TURNING_RIGHT = false end 
        if rx < -0.5 then p.flags.TURNING_LEFT = true else 
            p.flags.TURNING_LEFT = false end 
    end

    if not TARGETING_OCULUS_QUEST then
        if p.flags.MOVING_FORWARD then 
            p.z = p.z + (deltaTime * playerSpeed) * math.sin(p.rot)
            p.x = p.x + (deltaTime * playerSpeed) * math.cos(p.rot)
        elseif p.flags.MOVING_BACKWARD then 
            p.z = p.z - (deltaTime * playerSpeed) * math.sin(p.rot)
            p.x = p.x - (deltaTime * playerSpeed) * math.cos(p.rot)
        end
        if p.flags.STRAFE_RIGHT then 
            p.x = p.x + (deltaTime * playerSpeed) * math.cos(p.rot + math.pi/2)
            p.z = p.z + (deltaTime * playerSpeed) * math.sin(p.rot + math.pi/2)
        elseif p.flags.STRAFE_LEFT then 
            p.x = p.x + (deltaTime * playerSpeed) * math.cos(p.rot - math.pi/2)
            p.z = p.z + (deltaTime * playerSpeed) * math.sin(p.rot - math.pi/2)
        end
    else 
        hr = headsetState.an * headsetState.ay
        if hr < -math.pi then hr = hr + math.pi end 
        if hr > math.pi then hr = hr - math.pi end 
        hr = hr * -1
        if p.flags.MOVING_FORWARD then 
            p.z = p.z + (deltaTime * playerSpeed) * math.sin(hr + p.rot)
            p.x = p.x + (deltaTime * playerSpeed) * math.cos(hr + p.rot)
        elseif p.flags.MOVING_BACKWARD then 
            p.z = p.z - (deltaTime * playerSpeed) * math.sin(hr + p.rot)
            p.x = p.x - (deltaTime * playerSpeed) * math.cos(hr + p.rot)
        end
        if p.flags.STRAFE_RIGHT then 
            p.x = p.x + (deltaTime * playerSpeed) 
                * math.cos((hr+p.rot) + math.pi/2)
            p.z = p.z + (deltaTime * playerSpeed) 
                * math.sin((hr+p.rot) + math.pi/2)
        elseif p.flags.STRAFE_LEFT then 
            p.x = p.x + (deltaTime * playerSpeed) 
                 math.cos((hr+p.rot) - math.pi/2)
            p.z = p.z + (deltaTime * playerSpeed) 
                * math.sin((hr+p.rot) - math.pi/2)
        end
    end
    if p.flags.TURNING_RIGHT then 
        p.rot = p.rot + (deltaTime * playerSpeed/2)
    elseif p.flags.TURNING_LEFT then 
        p.rot = p.rot - (deltaTime * playerSpeed/2)
    end
    if p.rot < 0 then p.rot = p.rot + (2*math.pi) end 
    if p.rot > (2*math.pi) then p.rot = p.rot - (2*math.pi) end 
    -- PS updates
    local me = myPlayerState 
    if p.flags.MOVING_BACKWARD or p.flags.MOVING_FORWARD or 
        p.flags.STRAFE_RIGHT or p.flags.STRAFE_LEFT or 
        p.flags.TURNING_LEFT or p.flags.TURNING_RIGHT or 
        TARGETING_OCULUS_QUEST 
        then 
        me.UPDATE_ME = true 
    else 
        me.UPDATE_ME = false 
    end 
    -- Update my state for the thread!
    me.pos.x = round(p.x, 3); me.pos.y = 
        round(p.y + p.h, 3); me.pos.z = round(p.z, 3);
    -- convert rotation to quaternion
    me.rot.m = -p.rot + math.pi/2; 
    -- Hands 
    me.rHandPos.x = round(p.x + rightHand.x, 3); 
    me.rHandPos.y = round(p.y + p.h + rightHand.y, 3);
    me.rHandPos.z = round(p.z + rightHand.z, 3);
    me.rHandRot.m = rightHand.an; me.rHandRot.x = rightHand.ax;
    me.rHandRot.y = rightHand.ay; me.rHandRot.z = rightHand.az;
    
    me.lHandPos.x = round(p.x + leftHand.x, 3); 
    me.lHandPos.y = round(p.y + p.h + leftHand.y, 3);
    me.lHandPos.z = round(p.z + leftHand.z, 3);
    me.lHandRot.m = leftHand.an; me.lHandRot.x = leftHand.ax;
    me.lHandRot.y = leftHand.ay; me.lHandRot.z = leftHand.az;
    
    -- [[ END PLAYER UPDATE ]]

    -- VIEW
    camera = lovr.math.newMat4():lookAt(
        vec3(p.x, p.y, p.z),
        vec3(p.x + math.cos(p.rot), 
             p.y, 
             p.z + math.sin(p.rot)))
    view = lovr.math.newMat4(camera):invert()

    -- CLIENT service called right before draw()    
	serverTick = serverTick - deltaTime 
	if serverTick < 0 then 
		serverTick = serverTick + (1/40)
        toThread:push('tick')
        toThread:push(json.encode(myPlayerState))
	end

end

--Input

if not TARGETING_OCULUS_QUEST then 
    include 'src/input.lua'

    function lovr.mirror()
        lg.clear()
        lovr.draw()
    end
end
--

local worldGUI = {}
local HmdGUI = {}

function lovr.draw()
    -- DAY
    --lg.clear(1/3, 1/3, 1, 1)
    -- NIGHT
    lg.clear(EGA(1))

    if TARGETING_OCULUS_QUEST then 
        letters.draw()
        for i,t in ipairs(letters_drawables) do 
            t:draw()
        end
    end

    if not TARGETING_OCULUS_QUEST then 
        hand:draw(0, 2, -3)
    else 
        -- p.rot is visual world rotation (p.rot, 0, 1, 0)
        hand:draw(rightHand.x, rightHand.y, rightHand.z, 0.1, 
            rightHand.an, rightHand.ax, rightHand.ay, rightHand.az)
        hand:draw(leftHand.x, leftHand.y, leftHand.z, 0.1, 
            leftHand.an, leftHand.ax, leftHand.ay, leftHand.az)
    end

    lovr.graphics.transform(view)
    lovr.graphics.setShader(shader)

    -- sword
    shader:send('curTex', texSwd1)
    sword1:draw(-1, 1, -5, 1, gameTime*4, 1, 0, 0)

    -- ground plane
    lovr.graphics.setShader()
    lovr.graphics.setColor(EGA(2))
    lovr.graphics.plane('fill', 0, 0, 0, 20, 20, math.pi/2, 1, 0, 0)
    lovr.graphics.setColor(EGA(15))

	--lovr.graphics.setShader()
	lovr.graphics.setFont(satFont)
    lovr.graphics.print('ima fk uup\npoing!', 2, 3, -6)

    --[[ DRAW CURRENTSTATE ]]
    local cs = lastState
    for k,v in pairs(cs.players) do 
        if k then 
            if (v.pos) then 
                lg.setShader(shader)
                if tonumber(k) ~= clientId then 
                    -- Draw body
                    shader:send('curTex', texChain) -- TODO 
                    local np = currentState.players[k].pos 
                    -- (Smooth!)
                    local newv = lovr.math.newVec3(v.pos.x, v.pos.y, v.pos.z)
                        :lerp(lovr.math.newVec3(np.x, np.y, np.z), tickPercent*5)
                    p_body:draw(newv.x, newv.y - 0.25, newv.z, 0.33, v.rot.m)
                    -- Draw head
                    shader:send('curTex', texFace1) -- TODO
                    p_head:draw(newv.x, newv.y, newv.z, 0.25, v.rot.m)
                    
                    hand:draw(v.rHandPos.x, v.rHandPos.y, v.rHandPos.z, 0.2, 
                        v.rHandRot.m, v.rHandRot.x, v.rHandRot.y, v.rHandRot.z)
                    hand:draw(v.lHandPos.x, v.lHandPos.y, v.lHandPos.z, 0.2, 
                        v.lHandRot.m, v.lHandRot.x, v.lHandRot.y, v.lHandRot.z)
                end
                lg.setShader() -- clientId
                lg.print(k, v.pos.x, v.pos.y + 1, v.pos.z, 0.6, v.rot.m)
            end
        end
    end

    -- DRAW GOBBO
    lg.setShader(shader)
    shader:send('curTex', texGob_a)
    gob_a:draw(0, 0, -5)
    lg.setShader()

    -- Draw gui
    worldGUI:draw()
    HmdGUI:draw()
    
end

function worldGUI:draw()
    --[[ World-rotation agnostic GUI]]
    local guipos = { x = p.x + 2.0 * math.cos(p.rot), 
    z = p.z + 2.0 * math.sin(p.rot), 
    y = p.h }
    lg.print('GUI test', 
    guipos.x, guipos.y, guipos.z, 0.2, -p.rot-math.pi/2)
end

function HmdGUI:draw()
    --[[ HMD-oriented GUI]]
    if TARGETING_OCULUS_QUEST then 
        local gpos2 = { x = p.x + 2.0 * math.cos(hr + p.rot - 0.2),
            y = p.h + 1,
            z = p.z + 2.0 * math.sin(hr + p.rot - 0.2) }
        lg.print('HP: 10 / 10\nMP: 2 / 2\nLv: 1\nXP: 0 / 1000', 
            gpos2.x, gpos2.y, gpos2.z, 0.1, -(hr+p.rot)-math.pi/2,
            0, 1, 0, 0, 'left')
    else 
        local gpos2 = { x = p.x + 2.0 * math.cos(p.rot - 0.8),
        y = p.h + 0.6,
        z = p.z + 2.0 * math.sin(p.rot - 0.8) }
        lg.print('HP: 10 / 10\nMP: 2 / 2\nLv: 1\nXP: 0 / 1000', 
            gpos2.x, gpos2.y, gpos2.z, 0.1, -(p.rot)-math.pi/2, 
            0, 1, 0, 0, 'left')
    end
end

function lovr.quit()

	toThread:push('getbc')
	
end