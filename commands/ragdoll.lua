return {
    Name = "ragdoll", Category = "combat", Permission = 1, Aliases = {"rag"},
    Execute = function(BotEnv, args, executor, restArgs)
        if not args[2] then BotEnv.RespondError("Usage: ragdoll <player>"); return end
        local targets = BotEnv.GetMultipleTargets(args[2], executor)
        if #targets == 0 then BotEnv.RespondError("Player not found"); return end
        for _, t in ipairs(targets) do
            task.spawn(function()
                pcall(function()
                    local hrp = BotEnv.GetBotHRP(); if not hrp then return end
                    local sp = hrp.CFrame
                    local bm = BotEnv.GetBotHumanoid(); if not bm then return end
                    BotEnv.PreFling()
                    bm:ChangeState(Enum.HumanoidStateType.Physics)
                    for i = 1, 30 do
                        local th = BotEnv.GetHRP(t); if not th then break end
                        local cb = BotEnv.GetBotHRP(); if not cb then break end
                        cb.CFrame = th.CFrame * CFrame.new(0, 3, 0)
                        cb.AssemblyLinearVelocity = Vector3.new(0, -BotEnv.FlingPower, 0)
                        BotEnv.RunService.Heartbeat:Wait()
                    end
                    BotEnv.PostFling(sp)
                end)
            end)
            BotEnv.Respond("Ragdolled " .. t.Name)
        end
    end,
}
