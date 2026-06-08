return {
    Name = "annoy",
    Category = "movement",
    Permission = 1,
    Aliases = {},
    Execute = function(BotEnv, args, executor, restArgs)
        local wt = nil
        if not args[2] then BotEnv.RespondError("need a target", wt) return end
        local target = BotEnv.GetSmartTarget(args[2], executor)
        if not target then BotEnv.RespondError("cant find " .. args[2], wt) return end
        BotEnv.DisconnectSafe("Annoy")
        BotEnv.DisconnectSafe("Follow")
        BotEnv.DisconnectSafe("Orbit")
        BotEnv.DisconnectSafe("Attach")
        local lastAnnoyTime = 0
        BotEnv.ActiveConnections.Annoy = BotEnv.RunService.Heartbeat:Connect(function()
            local now = tick()
            if (now - lastAnnoyTime) < BotEnv.AnnoyDelay then return end
            lastAnnoyTime = now
            pcall(function()
                local botHRP = BotEnv.GetBotHRP()
                local targetHRP = BotEnv.GetHRP(target)
                if botHRP and targetHRP and target and target.Parent and BotEnv.IsAlive(target) then
                    local rx = math.random(-3, 3)
                    local rz = math.random(-3, 3)
                    botHRP.CFrame = targetHRP.CFrame * CFrame.new(rx, 0, rz)
                else
                    BotEnv.DisconnectSafe("Annoy")
                end
            end)
        end)
        BotEnv.Respond("annoying " .. target.Name, wt)
    end,
}
