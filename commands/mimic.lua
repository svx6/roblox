return {
    Name = "mimic", Category = "movement", Permission = 1, Aliases = {"unmimic", "copy", "mirror"},
    Execute = function(BotEnv, args, executor, restArgs)
        if not args[2] or args[1]:lower() == "unmimic" then
            BotEnv.DisconnectSafe("Mimic"); BotEnv.SetFlag("IsMimicking", false); BotEnv.Respond("Mimic OFF"); return
        end
        local t = BotEnv.GetSmartTarget(args[2], executor, true)
        if not t then BotEnv.RespondError("Player not found"); return end
        BotEnv.DisconnectSafe("Mimic"); BotEnv.SetFlag("IsMimicking", true)
        local offset = nil
        pcall(function()
            local bh = BotEnv.GetBotHRP(); local th = BotEnv.GetHRP(t)
            if bh and th then offset = bh.Position - th.Position end
        end)
        offset = offset or Vector3.new(5, 0, 0)
        local conn = BotEnv.RunService.Heartbeat:Connect(function()
            pcall(function()
                if not BotEnv.GetFlag("IsMimicking") then BotEnv.DisconnectSafe("Mimic"); return end
                local bh = BotEnv.GetBotHRP(); local th = BotEnv.GetHRP(t)
                if not bh or not th then return end
                bh.CFrame = th.CFrame + offset
            end)
        end)
        BotEnv.TrackConnection("Mimic", conn)
        BotEnv.Respond("Mimicking " .. t.Name)
    end,
}
