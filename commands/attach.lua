--[[
    Command: attach
    Category: movement
    Permission: 1 (user)
    Usage: ?bot attach <player>
]]
return {
    Name = "attach",
    Category = "movement",
    Permission = 1,
    Aliases = {},
    Description = "Attach to a player (stick to their position)",
    Execute = function(BotEnv, args, executor, restArgs)
        local wt = nil
        if not args[2] then BotEnv.RespondError("need a target", wt) return end
        local target = BotEnv.GetSmartTarget(args[2], executor)
        if not target then BotEnv.RespondError("cant find " .. args[2], wt) return end
        BotEnv.DisconnectSafe("Follow")
        BotEnv.DisconnectSafe("Orbit")
        BotEnv.DisconnectSafe("Attach")
        BotEnv.DisconnectSafe("Annoy")
        BotEnv.DisconnectSafe("Creep")
        BotEnv.DisconnectSafe("Mimic")
        BotEnv.ActiveConnections.Attach = BotEnv.RunService.Heartbeat:Connect(function()
            pcall(function()
                local targetHRP = BotEnv.GetHRP(target)
                local botHRP = BotEnv.GetBotHRP()
                if targetHRP and botHRP and target and target.Parent and BotEnv.IsAlive(target) then
                    botHRP.CFrame = targetHRP.CFrame
                else
                    BotEnv.DisconnectSafe("Attach")
                end
            end)
        end)
        BotEnv.Respond("attached to " .. target.Name, wt)
    end,
}
