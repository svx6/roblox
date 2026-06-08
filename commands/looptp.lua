return {
    Name = "looptp",
    Category = "movement",
    Permission = 1,
    Aliases = {},
    Execute = function(BotEnv, args, executor, restArgs)
        local wt = nil
        if not args[2] then BotEnv.RespondError("need a target", wt) return end
        local target = BotEnv.GetSmartTarget(args[2], executor)
        if not target then BotEnv.RespondError("cant find " .. args[2], wt) return end
        BotEnv.DisconnectSafe("LoopTP")
        BotEnv.SetFlag("IsLoopTP", true)
        BotEnv.SetFlag("LoopTPTarget", target)
        BotEnv.ActiveConnections.LoopTP = BotEnv.RunService.Heartbeat:Connect(function()
            pcall(function()
                if not BotEnv.GetFlag("IsLoopTP") or not target or not target.Parent then
                    BotEnv.DisconnectSafe("LoopTP")
                    BotEnv.SetFlag("IsLoopTP", false)
                    return
                end
                local tHRP = BotEnv.GetHRP(target)
                local botHRP = BotEnv.GetBotHRP()
                if tHRP and botHRP then
                    botHRP.CFrame = tHRP.CFrame * CFrame.new(0, 0, 3)
                end
            end)
        end)
        BotEnv.Respond("looptp on " .. target.Name, wt)
    end,
}
