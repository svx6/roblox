return {
    Name = "pull", Category = "combat", Permission = 1, Aliases = {"drag", "yoink"},
    Execute = function(BotEnv, args, executor, restArgs)
        if not args[2] then BotEnv.RespondError("Usage: pull <player>"); return end
        local targets = BotEnv.GetMultipleTargets(args[2], executor)
        if #targets == 0 then BotEnv.RespondError("Player not found"); return end
        for _, t in ipairs(targets) do
            task.spawn(function() BotEnv.BringPlayer(t) end)
            BotEnv.Respond("Pulling " .. t.Name)
        end
    end,
}
