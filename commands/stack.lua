return {
    Name = "stack", Category = "movement", Permission = 1, Aliases = {"unstack", "sit"},
    Execute = function(BotEnv, args, executor, restArgs)
        if not args[2] or args[1]:lower() == "unstack" then
            BotEnv.DisconnectSafe("Stack"); BotEnv.Respond("Stack OFF"); return
        end
        local t = BotEnv.GetSmartTarget(args[2], executor, true)
        if not t then BotEnv.RespondError("Player not found"); return end
        BotEnv.DisconnectSafe("Stack")
        local conn = BotEnv.RunService.Heartbeat:Connect(function()
            pcall(function()
                local bh = BotEnv.GetBotHRP(); local th = BotEnv.GetHRP(t)
                if not bh or not th then return end
                bh.CFrame = th.CFrame * CFrame.new(0, 3, 0)
            end)
        end)
        BotEnv.TrackConnection("Stack", conn)
        BotEnv.Respond("Stacking on " .. t.Name)
    end,
}
