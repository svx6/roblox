--[[
    Command: follow
    Category: movement
    Permission: 1 (user)
    Usage: ?bot follow <player>
]]
return {
    Name = "follow",
    Category = "movement",
    Permission = 1,
    Aliases = {},
    Description = "Follow a player at a set distance",
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
        BotEnv.ActiveConnections.Follow = BotEnv.RunService.Heartbeat:Connect(function()
            pcall(function()
                local targetHRP = BotEnv.GetHRP(target)
                local botHRP = BotEnv.GetBotHRP()
                if targetHRP and botHRP and target and target.Parent and BotEnv.IsAlive(target) then
                    local dir = (botHRP.Position - targetHRP.Position)
                    if dir.Magnitude > 0 then
                        local offset = dir.Unit * BotEnv.FollowDistance
                        botHRP.CFrame = CFrame.new(targetHRP.Position + offset, targetHRP.Position)
                    end
                else
                    BotEnv.DisconnectSafe("Follow")
                end
            end)
        end)
        BotEnv.Respond("following " .. target.Name, wt)
    end,
}
