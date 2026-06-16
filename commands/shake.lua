--[[
    Command: shake
    Category: combat
    Permission: 1
    Usage: ?bot shake <player>
    Description: Teleports the bot rapidly all around a target to disorient them.
]]
return {
    Name = "shake", Category = "combat", Permission = 1, Aliases = {"unshake", "jitter"},
    Execute = function(BotEnv, args, executor, restArgs)
        local wt = nil
        if not args[2] then BotEnv.RespondError("need a target", wt) return end
        local targetName = args[2]
        if BotEnv.GetFlag("IsShaking") then
            BotEnv.SetFlag("IsShaking", false)
            BotEnv.DisconnectSafe("Shake")
            BotEnv.Respond("Shake OFF")
            return
        end
        local target = BotEnv.GetSmartTarget(targetName, executor)
        if not target then BotEnv.RespondError("cant find " .. targetName, wt) return end
        BotEnv.SetFlag("IsShaking", true)
        BotEnv.DisconnectSafe("Annoy")
        BotEnv.DisconnectSafe("Follow")
        BotEnv.DisconnectSafe("Orbit")
        local conn = BotEnv.RunService.Heartbeat:Connect(function()
            if not BotEnv.GetFlag("IsShaking") then BotEnv.DisconnectSafe("Shake") return end
            pcall(function()
                if not target or not target.Parent or not BotEnv.IsAlive(target) then
                    BotEnv.SetFlag("IsShaking", false)
                    BotEnv.DisconnectSafe("Shake")
                    return
                end
                local botHRP = BotEnv.GetBotHRP()
                local targetHRP = BotEnv.GetHRP(target)
                if botHRP and targetHRP then
                    local rx = math.random(-8, 8)
                    local rz = math.random(-8, 8)
                    local ry = math.random(-4, 4)
                    botHRP.CFrame = targetHRP.CFrame * CFrame.new(rx, ry, rz)
                end
            end)
        end)
        BotEnv.TrackConnection("Shake", conn)
        BotEnv.Respond("Shaking around " .. target.Name)
    end,
}
