--[[
    Command: bounce
    Category: combat
    Permission: 1
    Usage: ?bot bounce <player> [power]
    Description: Rapidly launches a target player into the air on loop.
]]
return {
    Name = "bounce", Category = "combat", Permission = 1, Aliases = {"unbounce", "launch"},
    Execute = function(BotEnv, args, executor, restArgs)
        local wt = nil
        if not args[2] then BotEnv.RespondError("need a target", wt) return end
        local targetName = args[2]
        local power = tonumber(args[3]) or 120
        local function doStop()
            BotEnv.DisconnectSafe("Bounce")
            BotEnv.Respond("Bounce OFF")
        end
        if BotEnv.GetFlag("IsBouncing") then
            BotEnv.SetFlag("IsBouncing", false)
            doStop()
            return
        end
        local target = BotEnv.GetSmartTarget(targetName, executor)
        if not target then BotEnv.RespondError("cant find " .. targetName, wt) return end
        BotEnv.SetFlag("IsBouncing", true)
        local interval = 0
        local conn = BotEnv.RunService.Heartbeat:Connect(function(dt)
            if not BotEnv.GetFlag("IsBouncing") then BotEnv.DisconnectSafe("Bounce") return end
            interval = interval + dt
            if interval < 0.35 then return end
            interval = 0
            pcall(function()
                if not target or not target.Parent or not BotEnv.IsAlive(target) then
                    BotEnv.SetFlag("IsBouncing", false)
                    BotEnv.DisconnectSafe("Bounce")
                    return
                end
                local hrp = BotEnv.GetHRP(target)
                if hrp then
                    hrp.AssemblyLinearVelocity = Vector3.new(
                        math.random(-20, 20),
                        power,
                        math.random(-20, 20)
                    )
                end
            end)
        end)
        BotEnv.TrackConnection("Bounce", conn)
        BotEnv.Respond("Bouncing " .. target.Name .. " (power:" .. power .. ")")
    end,
}
