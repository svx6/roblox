--[[
    Command: goto
    Category: movement
    Permission: 1 (user)
    Usage: ?bot goto <player>
    Aliases: walk
]]
return {
    Name = "goto",
    Category = "movement",
    Permission = 1,
    Aliases = {"walk"},
    Description = "Walk to a player using Humanoid:MoveTo",
    Execute = function(BotEnv, args, executor, restArgs)
        local wt = nil
        if not args[2] then BotEnv.RespondError("need a target", wt) return end
        local target = BotEnv.GetSmartTarget(args[2], executor)
        if not target then BotEnv.RespondError("cant find " .. args[2], wt) return end
        local targetHRP = BotEnv.GetHRP(target)
        local botHum = BotEnv.GetBotHumanoid()
        if targetHRP and botHum then
            botHum:MoveTo(targetHRP.Position)
            BotEnv.Respond("walking to " .. target.Name, wt)
        else
            BotEnv.RespondError("character not loaded", wt)
        end
    end,
}
