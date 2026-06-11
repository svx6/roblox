return {
    Name = "view", Category = "info", Permission = 1, Aliases = {"spectate", "watch", "unview", "unspectate", "unwatch"},
    Execute = function(BotEnv, args, executor, restArgs)
        local cmd = args[1]:lower()
        if cmd == "unview" or cmd == "unspectate" or cmd == "unwatch" then
            BotEnv.UnviewPlayer(); BotEnv.Respond("Unviewed"); return
        end
        if not args[2] then BotEnv.UnviewPlayer(); BotEnv.Respond("Unviewed"); return end
        local t = BotEnv.GetSmartTarget(args[2], executor, true)
        if not t then BotEnv.RespondError("Player not found"); return end
        BotEnv.ViewPlayer(t)
        BotEnv.Respond("Viewing " .. t.Name)
    end,
}
