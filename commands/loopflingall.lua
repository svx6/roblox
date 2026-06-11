return {
    Name = "loopflingall",
    Category = "fling",
    Permission = 1,
    Aliases = {},
    Execute = function(BotEnv, args, executor, restArgs)
        BotEnv.DisconnectSafe("LoopFlingAll")
        BotEnv.DisconnectSafe("LoopFling")
        BotEnv.DisconnectSafe("LoopKill")
        local lastFlingTime = 0
        local flingActive = false
        BotEnv.ActiveConnections.LoopFlingAll = BotEnv.RunService.Heartbeat:Connect(function()
            if flingActive then return end
            local now = tick()
            if (now - lastFlingTime) < BotEnv.LoopFlingDelay then return end
            lastFlingTime = now
            flingActive = true
            task.spawn(function()
                pcall(function()
                    for _, p in ipairs(BotEnv.Players:GetPlayers()) do
                        if p ~= BotEnv.LocalPlayer and BotEnv.IsAlive(p) and BotEnv.GetHRP(p) then
                            BotEnv.ExecuteSmartFling(p)
                        end
                    end
                end)
                flingActive = false
            end)
        end)
        BotEnv.Respond("loopfling all on", nil)
    end,
}
