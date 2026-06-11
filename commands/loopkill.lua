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
        local flingActive = false
        BotEnv.ActiveConnections.LoopKill = BotEnv.RunService.Heartbeat:Connect(function()
            if flingActive then return end
            local now = tick()
            if (now - lastFlingTime) < BotEnv.LoopFlingDelay then return end
            lastFlingTime = now
            if target and target.Parent and BotEnv.IsAlive(target) and BotEnv.GetHRP(target) then
                flingActive = true
                task.spawn(function()
                    pcall(function() BotEnv.ExecuteSmartFling(target) end)
                    flingActive = false
                end)
            elseif not target or not target.Parent then
                BotEnv.DisconnectSafe("LoopKill")
            end
        end)
        BotEnv.Respond("loopkill on " .. target.Name, wt)
    end,
}
