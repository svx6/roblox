return {
    Name = "kill",
    Category = "fling",
    Permission = 1,
    Aliases = {},
    Execute = function(BotEnv, args, executor, restArgs)
        local wt = nil
        if not args[2] then BotEnv.RespondError("need a target", wt) return end
        local targets = BotEnv.GetMultipleTargets(args[2], executor)
        if #targets == 0 then BotEnv.RespondError("cant find " .. args[2], wt) return end
        task.spawn(function()
            for _, target in ipairs(targets) do
                BotEnv.ExecuteSmartFling(target)
                task.wait(0.05)
            end
        end)
        BotEnv.Respond("killing", wt)
    end,
}
