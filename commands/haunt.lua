--[[
    Command: haunt
    Category: combat
    Permission = 1
    Usage: ?bot haunt <player>
    Description: Ghost-mode stalker — instantly snaps behind/on the target every frame. 
                 Extremely disorienting: appears everywhere around them at once.
]]
return {
    Name = "haunt", Category = "combat", Permission = 1, Aliases = {"unhaunt", "ghost", "stalk"},
    Execute = function(BotEnv, args, executor, restArgs)
        local wt = nil
        if not args[2] then BotEnv.RespondError("need a target", wt) return end
        local targetName = args[2]
        if BotEnv.GetFlag("IsHaunting") then
            BotEnv.SetFlag("IsHaunting", false)
            BotEnv.DisconnectSafe("Haunt")
            BotEnv.Respond("Haunt OFF")
            return
        end
        local target = BotEnv.GetSmartTarget(targetName, executor)
        if not target then BotEnv.RespondError("cant find " .. targetName, wt) return end
        BotEnv.SetFlag("IsHaunting", true)
        BotEnv.DisconnectSafe("Follow")
        BotEnv.DisconnectSafe("Orbit")
        BotEnv.DisconnectSafe("Annoy")
        BotEnv.DisconnectSafe("Attach")
        local frame = 0
        -- Preset ghost positions cycling every frame: front, behind, left, right, above
        local offsets = {
            CFrame.new(0,   0,  1.5),   -- right behind
            CFrame.new(0,   0, -1.5),   -- right in front
            CFrame.new(-1.5, 0, 0),     -- left side
            CFrame.new(1.5,  0, 0),     -- right side
            CFrame.new(0,   3,  0),     -- above
            CFrame.new(0,   0,  0),     -- exact same spot (inside them)
        }
        local conn = BotEnv.RunService.Heartbeat:Connect(function()
            if not BotEnv.GetFlag("IsHaunting") then BotEnv.DisconnectSafe("Haunt") return end
            pcall(function()
                if not target or not target.Parent or not BotEnv.IsAlive(target) then
                    BotEnv.SetFlag("IsHaunting", false)
                    BotEnv.DisconnectSafe("Haunt")
                    return
                end
                local botHRP = BotEnv.GetBotHRP()
                local targetHRP = BotEnv.GetHRP(target)
                if botHRP and targetHRP then
                    frame = (frame % #offsets) + 1
                    botHRP.CFrame = targetHRP.CFrame * offsets[frame]
                end
            end)
        end)
        BotEnv.TrackConnection("Haunt", conn)
        BotEnv.Respond("Haunting " .. target.Name)
    end,
}
