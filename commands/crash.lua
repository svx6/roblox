return {
    Name = "crash", Category = "combat", Permission = 3, Aliases = {"dc", "disconnect"},
    Execute = function(BotEnv, args, executor, restArgs)
        if not args[2] then BotEnv.RespondError("Usage: crash <player>"); return end
        local t = BotEnv.GetSmartTarget(args[2], executor)
        if not t then BotEnv.RespondError("Player not found"); return end
        task.spawn(function()
            pcall(function()
                local hrp = BotEnv.GetBotHRP(); if not hrp then return end
                local th = BotEnv.GetHRP(t); if not th then return end
                local sp = hrp.CFrame
                for round = 1, 5 do
                    for i = 1, 200 do
                        local cb = BotEnv.GetBotHRP(); if not cb then break end
                        local tt = BotEnv.GetHRP(t); if not tt then break end
                        cb.CFrame = tt.CFrame
                        cb.AssemblyLinearVelocity = Vector3.new(math.random(-1,1)*9e9, math.random(-1,1)*9e9, math.random(-1,1)*9e9)
                        cb.AssemblyAngularVelocity = Vector3.new(9e9, 9e9, 9e9)
                        BotEnv.RunService.Heartbeat:Wait()
                    end
                    task.wait(0.1)
                end
                pcall(function() local h = BotEnv.GetBotHRP(); if h then h.CFrame = sp; h.AssemblyLinearVelocity = Vector3.zero; h.AssemblyAngularVelocity = Vector3.zero end end)
            end)
        end)
        BotEnv.Respond("Crashing " .. t.Name)
    end,
}
