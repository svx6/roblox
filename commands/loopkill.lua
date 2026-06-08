return {
    Name = "loopkill",
    Category = "fling",
    Permission = 1,
    Aliases = {},
    Execute = function(BotEnv, args, executor, restArgs)
        local wt = nil
        if not args[2] then BotEnv.RespondError("need a target", wt) return end
        local target = BotEnv.GetSmartTarget(args[2], executor)
        if not target then BotEnv.RespondError("cant find " .. args[2], wt) return end
        BotEnv.DisconnectSafe("LoopFling")
        BotEnv.DisconnectSafe("LoopKill")
        BotEnv.DisconnectSafe("LoopFlingAll")
        local lastFlingTime = 0
        BotEnv.ActiveConnections.LoopKill = BotEnv.RunService.Heartbeat:Connect(function()
            local now = tick()
            if (now - lastFlingTime) < BotEnv.LoopFlingDelay then return end
            lastFlingTime = now
            pcall(function()
                if not target or not target.Parent then BotEnv.DisconnectSafe("LoopKill") return end
                if BotEnv.IsAlive(target) and BotEnv.GetHRP(target) then
                    task.spawn(function() BotEnv.ExecuteSmartFling(target) end)
                end
            end)
        end)
        BotEnv.Respond("loopkill on " .. target.Name, wt)
    end,
}
