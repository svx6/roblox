return {
    Name = "freeze", Category = "combat", Permission = 1, Aliases = {"frz", "unfreeze", "unfrz", "thaw"},
    Execute = function(BotEnv, args, executor, restArgs)
        if not args[2] then BotEnv.RespondError("Usage: freeze <player>"); return end
        local targets = BotEnv.GetMultipleTargets(args[2], executor)
        if #targets == 0 then BotEnv.RespondError("Player not found"); return end
        for _, t in ipairs(targets) do
            if BotEnv.FreezeCages[t] then
                BotEnv.UnfreezePlayerAdvanced(t); BotEnv.Respond("Unfroze " .. t.Name)
            else
                BotEnv.FreezePlayerAdvanced(t); BotEnv.Respond("Froze " .. t.Name)
            end
        end
    end,
}
