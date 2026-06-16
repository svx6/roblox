--[[
    Command: push
    Category: combat
    Permission: 1
    Usage: ?bot push <player> [force]
    Description: Repeatedly shoves a target in random directions.
]]
return {
    Name = "push", Category = "combat", Permission = 1, Aliases = {"unpush", "shove"},
    Execute = function(BotEnv, args, executor, restArgs)
        local wt = nil
        if not args[2] then BotEnv.RespondError("need a target", wt) return end
        local targetName = args[2]
        local force = tonumber(args[3]) or 80
        if BotEnv.GetFlag("IsPushing") then
            BotEnv.SetFlag("IsPushing", false)
            BotEnv.DisconnectSafe("Push")
            BotEnv.Respond("Push OFF")
            return
        end
        local target = BotEnv.GetSmartTarget(targetName, executor)
        if not target then BotEnv.RespondError("cant find " .. targetName, wt) return end
        BotEnv.SetFlag("IsPushing", true)
        local timer = 0
        local conn = BotEnv.RunService.Heartbeat:Connect(function(dt)
            if not BotEnv.GetFlag("IsPushing") then BotEnv.DisconnectSafe("Push") return end
            timer = timer + dt
            if timer < 0.25 then return end
            timer = 0
            pcall(function()
                if not target or not target.Parent or not BotEnv.IsAlive(target) then
                    BotEnv.SetFlag("IsPushing", false)
                    BotEnv.DisconnectSafe("Push")
                    return
                end
                local botHRP = BotEnv.GetBotHRP()
                local targetHRP = BotEnv.GetHRP(target)
                if not botHRP or not targetHRP then return end
                -- Teleport bot right next to the target, then apply push velocity
                botHRP.CFrame = targetHRP.CFrame * CFrame.new(
                    math.random(-2, 2), 0, math.random(-2, 2)
                )
                -- Push in random horizontal direction + small upward component
                local angle = math.random() * math.pi * 2
                local pushDir = Vector3.new(
                    math.cos(angle) * force,
                    force * 0.3,
                    math.sin(angle) * force
                )
                targetHRP.AssemblyLinearVelocity = pushDir
            end)
        end)
        BotEnv.TrackConnection("Push", conn)
        BotEnv.Respond("Pushing " .. target.Name .. " (force:" .. force .. ")")
    end,
}
