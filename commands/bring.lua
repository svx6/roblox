--[[
    Command: bring
    Category: movement
    Permission: 1 (user)
    Usage: ?bot bring <player|all|others>
]]
return {
    Name = "bring",
    Category = "movement",
    Permission = 1,
    Aliases = {},
    Description = "Bring a player to the bot's position",
    Execute = function(BotEnv, args, executor, restArgs)
        local wt = nil
        if not args[2] then BotEnv.RespondError("need a target", wt) return end
        local targets = BotEnv.GetMultipleTargets(args[2], executor)
        if #targets == 0 then BotEnv.RespondError("cant find " .. args[2], wt) return end
        for _, target in ipairs(targets) do
            BotEnv.BringPlayer(target)
            task.wait(0.05)
        end
        BotEnv.Respond("bringing", wt)
    end,
}
