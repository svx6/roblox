return {
    Name = "stare", Category = "movement", Permission = 1, Aliases = {"unstare", "lookat", "face"},
    Execute = function(BotEnv, args, executor, restArgs)
        if not args[2] or args[1]:lower() == "unstare" then
            BotEnv.DisconnectSafe("Stare"); BotEnv.Respond("Stare OFF"); return
        end
        local t = BotEnv.GetSmartTarget(args[2], executor, true)
        if not t then BotEnv.RespondError("Player not found"); return end
        BotEnv.DisconnectSafe("Stare")
        local conn = BotEnv.RunService.Heartbeat:Connect(function()
            pcall(function()
                local bh = BotEnv.GetBotHRP(); local th = BotEnv.GetHRP(t)
                if not bh or not th then return end
                bh.CFrame = CFrame.new(bh.Position, Vector3.new(th.Position.X, bh.Position.Y, th.Position.Z))
            end)
        end)
        BotEnv.TrackConnection("Stare", conn)
        BotEnv.Respond("Staring at " .. t.Name)
    end,
}
