return {
    Name = "tornado", Category = "combat", Permission = 1, Aliases = {"torn", "cyclone"},
    Execute = function(BotEnv, args, executor, restArgs)
        if not args[2] then BotEnv.RespondError("Usage: tornado <player>"); return end
        local t = BotEnv.GetSmartTarget(args[2], executor)
        if not t then BotEnv.RespondError("Player not found"); return end
        task.spawn(function()
            pcall(function()
                local hrp = BotEnv.GetBotHRP(); if not hrp then return end
                local sp = hrp.CFrame
                BotEnv.PreFling()
                local bm = BotEnv.GetBotHumanoid(); if bm then bm:ChangeState(Enum.HumanoidStateType.Physics) end
                for i = 1, 200 do
                    local th = BotEnv.GetHRP(t); if not th then break end
                    local cb = BotEnv.GetBotHRP(); if not cb then break end
                    local angle = i * 0.3
                    local radius = 3 + math.sin(i * 0.1) * 2
                    local height = (i / 200) * 50
                    cb.CFrame = th.CFrame * CFrame.new(math.cos(angle) * radius, height, math.sin(angle) * radius)
                    cb.AssemblyLinearVelocity = Vector3.new(math.cos(angle) * BotEnv.FlingPower * 0.01, BotEnv.FlingPower * 0.005, math.sin(angle) * BotEnv.FlingPower * 0.01)
                    cb.AssemblyAngularVelocity = Vector3.new(0, BotEnv.FlingPower * 0.01, 0)
                    BotEnv.RunService.Heartbeat:Wait()
                end
                BotEnv.PostFling(sp)
            end)
        end)
        BotEnv.Respond("Tornado on " .. t.Name)
    end,
}
