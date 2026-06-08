--[[
    Command: tp
    Category: movement
    Permission: 1 (user)
    Usage: ?bot tp <player>
    Aliases: teleport
]]
return {
    Name = "tp",
    Category = "movement",
    Permission = 1,
    Aliases = {"teleport"},
    Description = "Teleport to a player",
    Execute = function(BotEnv, args, executor, restArgs)
        local wt = nil
        if not args[2] then BotEnv.RespondError("need a target", wt) return end
        local target = BotEnv.GetSmartTarget(args[2], executor)
        if not target then BotEnv.RespondError("cant find " .. args[2], wt) return end
        local targetHRP = BotEnv.GetHRP(target)
        local botHRP = BotEnv.GetBotHRP()
        if targetHRP and botHRP then
            botHRP.CFrame = targetHRP.CFrame * CFrame.new(0, 0, 3)
            BotEnv.Respond("tp'd to " .. target.Name, wt)
        else
            BotEnv.RespondError("character not loaded", wt)
        end
    end,
}
