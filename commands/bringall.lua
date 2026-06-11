return {
    Name = "bringall", Category = "combat", Permission = 2, Aliases = {"pullall", "bringeveryone"},
    Execute = function(BotEnv, args, executor, restArgs)
        local targets = BotEnv.GetMultipleTargets("all", executor)
        if #targets == 0 then BotEnv.RespondError("No targets"); return end
        for _, t in ipairs(targets) do
            task.spawn(function() pcall(function() BotEnv.BringPlayer(t) end) end)
        end
        BotEnv.Respond("Bringing " .. #targets .. " players")
    end,
}
