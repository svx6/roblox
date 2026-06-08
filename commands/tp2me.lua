return {
    Name = "tp2me",
    Category = "movement",
    Permission = 1,
    Aliases = {},
    Execute = function(BotEnv, args, executor, restArgs)
        local wt = nil
        if not args[2] then BotEnv.RespondError("need a target", wt) return end
        local target = BotEnv.GetSmartTarget(args[2], executor)
        if not target then BotEnv.RespondError("cant find " .. args[2], wt) return end
        local executorHRP = BotEnv.GetHRP(executor)
        if executorHRP then
            BotEnv.BringPlayer(target, executorHRP.CFrame)
            BotEnv.Respond("bringing " .. target.Name .. " to you", wt)
        else
            BotEnv.RespondError("your character not loaded", wt)
        end
    end,
}
