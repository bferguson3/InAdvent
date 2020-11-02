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
