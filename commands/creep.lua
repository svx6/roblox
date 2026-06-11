return {
    Name = "creep", Category = "movement", Permission = 1, Aliases = {"uncreep", "stalk"},
    Execute = function(BotEnv, args, executor, restArgs)
        if not args[2] or args[1]:lower() == "uncreep" then
            BotEnv.DisconnectSafe("Creep"); BotEnv.SetFlag("IsCreeping", false); BotEnv.Respond("Creep OFF"); return
        end
        local t = BotEnv.GetSmartTarget(args[2], executor, true)
        if not t then BotEnv.RespondError("Player not found"); return end
        BotEnv.DisconnectSafe("Creep"); BotEnv.SetFlag("IsCreeping", true)
        local conn = BotEnv.RunService.Heartbeat:Connect(function()
            pcall(function()
                if not BotEnv.GetFlag("IsCreeping") then BotEnv.DisconnectSafe("Creep"); return end
                local bh = BotEnv.GetBotHRP(); local th = BotEnv.GetHRP(t)
                if not bh or not th then return end
                local behind = th.CFrame * CFrame.new(0, 0, 5)
                bh.CFrame = CFrame.new(behind.Position, th.Position)
            end)
        end)
        BotEnv.TrackConnection("Creep", conn)
        BotEnv.Respond("Creeping behind " .. t.Name)
    end,
}
