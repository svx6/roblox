return {
    Name = "serverhop", Category = "admin", Permission = 3, Aliases = {"hop", "newserver", "sh"},
    Execute = function(BotEnv, args, executor, restArgs)
        BotEnv.Respond("Server hopping...")
        task.wait(0.5)
        pcall(function()
            if BotEnv.TeleportService then
                local servers = nil
                pcall(function()
                    local doReq = type(request) == "function" and request or (type(http_request) == "function" and http_request or nil)
                    if doReq then
                        local r = doReq({Url = "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=25", Method = "GET"})
                        if r and r.Body then servers = BotEnv.HttpService:JSONDecode(r.Body) end
                    end
                end)
                if servers and servers.data then
                    for _, srv in ipairs(servers.data) do
                        if srv.id ~= game.JobId and srv.playing < srv.maxPlayers then
                            BotEnv.TeleportService:TeleportToPlaceInstance(game.PlaceId, srv.id, BotEnv.LocalPlayer)
                            return
                        end
                    end
                end
                BotEnv.TeleportService:Teleport(game.PlaceId, BotEnv.LocalPlayer)
            end
        end)
    end,
}
