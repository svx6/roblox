return {
    Name = "magnet", Category = "combat", Permission = 1, Aliases = {"unmagnet", "attract"},
    Execute = function(BotEnv, args, executor, restArgs)
        if not args[2] or args[1]:lower() == "unmagnet" then
            BotEnv.SetFlag("IsMagnetOn", false); BotEnv.DisconnectSafe("Magnet"); BotEnv.Respond("Magnet OFF"); return
        end
        local t = BotEnv.GetSmartTarget(args[2], executor)
        if not t then BotEnv.RespondError("Player not found"); return end
        BotEnv.SetFlag("IsMagnetOn", true); BotEnv.DisconnectSafe("Magnet")
        local conn = BotEnv.RunService.Heartbeat:Connect(function()
            pcall(function()
                if not BotEnv.GetFlag("IsMagnetOn") then BotEnv.DisconnectSafe("Magnet"); return end
                task.spawn(function() pcall(function() BotEnv.BringPlayer(t) end) end)
            end)
        end)
        BotEnv.TrackConnection("Magnet", conn)
        BotEnv.Respond("Magnet ON -> " .. t.Name)
    end,
}
