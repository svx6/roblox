return {
    Name = "cage", Category = "combat", Permission = 1, Aliases = {"uncage", "box", "trap"},
    Execute = function(BotEnv, args, executor, restArgs)
        if not args[2] then BotEnv.RespondError("Usage: cage <player>"); return end
        local targets = BotEnv.GetMultipleTargets(args[2], executor)
        if #targets == 0 then BotEnv.RespondError("Player not found"); return end
        for _, t in ipairs(targets) do
            if BotEnv.FreezeCages[t] then
                BotEnv.UnfreezePlayerAdvanced(t); BotEnv.Respond("Uncaged " .. t.Name)
            else
                BotEnv.FreezePlayerAdvanced(t); BotEnv.Respond("Caged " .. t.Name)
            end
        end
    end,
}
