return {
    Name = "tpall", Category = "combat", Permission = 2, Aliases = {"teleportall", "tpeveryone"},
    Execute = function(BotEnv, args, executor, restArgs)
        local targets = BotEnv.GetMultipleTargets("all", executor)
        if #targets == 0 then BotEnv.RespondError("No targets"); return end
        local hrp = BotEnv.GetBotHRP(); if not hrp then BotEnv.RespondError("No character"); return end
        for _, t in ipairs(targets) do
            task.spawn(function()
                pcall(function()
                    for i = 1, 60 do
                        local th = BotEnv.GetHRP(t); local bh = BotEnv.GetBotHRP()
                        if not th or not bh then break end
                        bh.CFrame = th.CFrame; BotEnv.RunService.Heartbeat:Wait()
                        bh = BotEnv.GetBotHRP(); if bh then bh.CFrame = hrp.CFrame end
                    end
                end)
            end)
            task.wait(0.2)
        end
        BotEnv.Respond("TPing " .. #targets .. " players to you")
    end,
}
