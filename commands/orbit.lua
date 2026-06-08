--[[
    Command: orbit
    Category: movement
    Permission: 1 (user)
    Usage: ?bot orbit <player> [radius]
]]
return {
    Name = "orbit",
    Category = "movement",
    Permission = 1,
    Aliases = {},
    Description = "Orbit around a player with optional custom radius",
    Execute = function(BotEnv, args, executor, restArgs)
        local wt = nil
        if not args[2] then BotEnv.RespondError("need a target", wt) return end
        local target = BotEnv.GetSmartTarget(args[2], executor)
        if not target then BotEnv.RespondError("cant find " .. args[2], wt) return end
        local customRadius = tonumber(args[3]) or BotEnv.OrbitRadius
        BotEnv.DisconnectSafe("Follow")
        BotEnv.DisconnectSafe("Orbit")
        BotEnv.DisconnectSafe("Attach")
        BotEnv.DisconnectSafe("Annoy")
        BotEnv.DisconnectSafe("Creep")
        BotEnv.DisconnectSafe("Mimic")
        local angle = 0
        BotEnv.ActiveConnections.Orbit = BotEnv.RunService.Heartbeat:Connect(function(dt)
            pcall(function()
                local targetHRP = BotEnv.GetHRP(target)
                local botHRP = BotEnv.GetBotHRP()
                if targetHRP and botHRP and target and target.Parent and BotEnv.IsAlive(target) then
                    angle = angle + (dt * BotEnv.OrbitSpeed)
                    local x = math.cos(angle) * customRadius
                    local z = math.sin(angle) * customRadius
                    botHRP.CFrame = CFrame.new(targetHRP.Position + Vector3.new(x, 2, z), targetHRP.Position)
                else
                    BotEnv.DisconnectSafe("Orbit")
                end
            end)
        end)
        BotEnv.Respond("orbiting " .. target.Name, wt)
    end,
}
