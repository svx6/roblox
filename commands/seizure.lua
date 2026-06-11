return {
    Name = "seizure", Category = "combat", Permission = 1, Aliases = {"sez", "shake"},
    Execute = function(BotEnv, args, executor, restArgs)
        if not args[2] then BotEnv.RespondError("Usage: seizure <player>"); return end
        local t = BotEnv.GetSmartTarget(args[2], executor)
        if not t then BotEnv.RespondError("Player not found"); return end
        task.spawn(function()
            pcall(function()
                local hrp = BotEnv.GetBotHRP(); if not hrp then return end
                local sp = hrp.CFrame
                BotEnv.PreFling()
                for i = 1, 120 do
                    local th = BotEnv.GetHRP(t); if not th then break end
                    local cb = BotEnv.GetBotHRP(); if not cb then break end
                    local shake = Vector3.new(math.random(-8,8), math.random(-8,8), math.random(-8,8))
                    cb.CFrame = th.CFrame * CFrame.new(shake.X, shake.Y, shake.Z)
                    cb.AssemblyLinearVelocity = shake * BotEnv.FlingPower * 0.001
                    BotEnv.RunService.Heartbeat:Wait()
                end
                BotEnv.PostFling(sp)
            end)
        end)
        BotEnv.Respond("Seizure on " .. t.Name)
    end,
}
