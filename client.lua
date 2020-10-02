local client = {}

local ResponseMessageType = {
    Login = "login_response",
    Lobby = "lobby",
    JoinedLobby = "joined_lobby",
    PlayerLeft = "player_left",
    PlayerData = "player_data",
    LobbyList = "lobby_list",
    Ping = "ping",
    LobbyFull = "lobby_full",
    StartGame = "start_game",
    PlayerIdleDrop = "player_idle_drop",
    GameState = "game_state",
    LobbyUpdate = "lobby_update",
    Error = "error",
};

pongRequest = {
    message_type = 'pong'
}
login_obj = {
    message_type = 'login',
    data = {
        player_username = '',
        password = ''
    }
}
--hostaddr = 'localhost:9521';--'18.224.63.67:9521';--

--last_message_received = "";
--last_message_type_sent = "";

----------------------
-- SERVER SHIT
-----------------------
local response_object = nil;

function client.process_event(event)
    if event then
        ObjectPrint(event)
        if event.type == "receive" then
            response_object = json.decode(event.data);
            if (response_object.type ~= 'ping') then
                print('received packet of type: ' .. response_object.type);
            end
            if response_object.type then
                if response_object.type == ResponseMessageType.Ping then
                    send_to_server(pongRequest);
                elseif response_object.type == ResponseMessageType.Login then
                    if response_object.value == "true" then
                        cur_client_id = response_object.clientId;
                    else
                        print('login failed')
                    end
                elseif response_object.type == ResponseMessageType.Error then
                    print(response_object.error);
                end -- end response_object.type switch
            --else
                --last_message_received = response_object.response_text or "";
            end
        --elseif event.data then
        --    last_message_received = event.data;
        end
    end
end

function ObjectPrint(object)
    for k,v in pairs(object) do
        if type(v) ~= 'table' then print(k, v);
        else for o,p in pairs(v) do print(k); print(o,p); end end;
    end
end

function client.send_to_server(game_object)
    local go = json.encode(game_object);
    print(go)
    server:send(go);
    --messages_sent = messages_sent + 1;
end

return client