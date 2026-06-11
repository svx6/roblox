return {
    Name = "scatter", Category = "combat", Permission = 2, Aliases = {"sctr"},
    Execute = function(BotEnv, args, executor, restArgs)
        local targets = BotEnv.GetMultipleTargets("all", executor)
        if #targets == 0 then BotEnv.RespondError("No targets"); return end
        task.spawn(function()
            for _, t in ipairs(targets) do
                task.spawn(function()
                    pcall(function()
                        local hrp = BotEnv.GetBotHRP(); if not hrp then return end
                        local sp = hrp.CFrame
                        local th = BotEnv.GetHRP(t); if not th then return end
                        BotEnv.PreFling()
                        local bm = BotEnv.GetBotHumanoid(); if bm then bm:ChangeState(Enum.HumanoidStateType.Physics) end
                        local dir = Vector3.new(math.random()-0.5, 0.5, math.random()-0.5).Unit
                        for i = 1, 40 do
                            local cb = BotEnv.GetBotHRP(); if not cb then break end
                            local tt = BotEnv.GetHRP(t); if not tt then break end
                            cb.CFrame = tt.CFrame
                            cb.AssemblyLinearVelocity = dir * BotEnv.FlingPower
                            BotEnv.RunService.Heartbeat:Wait()
                        end
                        BotEnv.PostFling(sp)
                    end)
                end)
                task.wait(0.3)
            end
        end)
        BotEnv.Respond("Scattering " .. #targets .. " players")
    end,
}
