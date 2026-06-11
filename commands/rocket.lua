return {
    Name = "rocket", Category = "combat", Permission = 1, Aliases = {"rkt", "launch"},
    Execute = function(BotEnv, args, executor, restArgs)
        if not args[2] then BotEnv.RespondError("Usage: rocket <player>"); return end
        local targets = BotEnv.GetMultipleTargets(args[2], executor)
        if #targets == 0 then BotEnv.RespondError("Player not found"); return end
        for _, t in ipairs(targets) do
            task.spawn(function()
                pcall(function()
                    local hrp = BotEnv.GetBotHRP(); if not hrp then return end
                    local sp = hrp.CFrame
                    BotEnv.PreFling()
                    local bm = BotEnv.GetBotHumanoid(); if bm then bm:ChangeState(Enum.HumanoidStateType.Physics) end
                    for i = 1, 60 do
                        local th = BotEnv.GetHRP(t); if not th then break end
                        local cb = BotEnv.GetBotHRP(); if not cb then break end
                        cb.CFrame = th.CFrame * CFrame.new(0, -1, 0)
                        cb.AssemblyLinearVelocity = Vector3.new(0, BotEnv.FlingPower, 0)
                        cb.AssemblyAngularVelocity = Vector3.new(BotEnv.FlingPower, 0, BotEnv.FlingPower)
                        BotEnv.RunService.Heartbeat:Wait()
                    end
                    BotEnv.PostFling(sp)
                end)
            end)
            BotEnv.Respond("Rocketed " .. t.Name)
        end
    end,
}
