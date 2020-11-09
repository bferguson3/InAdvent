local packets = {
    
    login_request = {
        message_type = 'login', 
        data = {
            username = "user",
            password = "password"
        }
    },

    pong = {
        message_type = "pong",
        data = {}
    },

    get_ping = { 
        message_type = "get_ping",
        data = {}
    },

    start_action = {
        message_type = "start_action",
        data = action_types.melee_swing
    },

    update_position = {
        message_type = "update",
        data = {}
    }

}
return packets;