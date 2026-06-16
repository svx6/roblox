--[[
    Command: dizzy
    Category: combat
    Permission: 1
    Usage: ?bot dizzy <player> [radius] [speed]
    Description: Orbits a target extremely fast in very tight circles to disorient them.
]]
return {
    Name = "dizzy", Category = "combat", Permission = 1, Aliases = {"undizzy", "whirl"},
    Execute = function(BotEnv, args, executor, restArgs)
        local wt = nil
        if not args[2] then BotEnv.RespondError("need a target", wt) return end
        local targetName = args[2]
        local radius = tonumber(args[3]) or 1.5
        local speed = tonumber(args[4]) or 35
        if BotEnv.GetFlag("IsDizzy") then
            BotEnv.SetFlag("IsDizzy", false)
            BotEnv.DisconnectSafe("Dizzy")
            BotEnv.Respond("Dizzy OFF")
            return
        end
        local target = BotEnv.GetSmartTarget(targetName, executor)
        if not target then BotEnv.RespondError("cant find " .. targetName, wt) return end
        BotEnv.SetFlag("IsDizzy", true)
        BotEnv.DisconnectSafe("Follow")
        BotEnv.DisconnectSafe("Orbit")
        BotEnv.DisconnectSafe("Annoy")
        BotEnv.DisconnectSafe("Attach")
        local angle = 0
        local conn = BotEnv.RunService.Heartbeat:Connect(function(dt)
            if not BotEnv.GetFlag("IsDizzy") then BotEnv.DisconnectSafe("Dizzy") return end
            pcall(function()
                if not target or not target.Parent or not BotEnv.IsAlive(target) then
                    BotEnv.SetFlag("IsDizzy", false)
                    BotEnv.DisconnectSafe("Dizzy")
                    return
                end
                local targetHRP = BotEnv.GetHRP(target)
                local botHRP = BotEnv.GetBotHRP()
                if targetHRP and botHRP then
                    angle = angle + (dt * speed)
                    local x = math.cos(angle) * radius
                    local z = math.sin(angle) * radius
                    -- Rapidly oscillate height too for extra chaos
                    local y = math.sin(angle * 2.5) * 1.2
                    botHRP.CFrame = CFrame.new(
                        targetHRP.Position + Vector3.new(x, y, z),
                        targetHRP.Position
                    )
                end
            end)
        end)
        BotEnv.TrackConnection("Dizzy", conn)
        BotEnv.Respond("Dizzying " .. target.Name .. " (r:" .. radius .. " spd:" .. speed .. ")")
    end,
}
