return {
    Name = "respawn", Category = "utility", Permission = 1, Aliases = {"rspwn", "rs"},
    Execute = function(BotEnv, args, executor, restArgs)
        pcall(function()
            local h = BotEnv.GetBotHumanoid()
            if h then h.Health = 0 end
        end)
        BotEnv.Respond("Respawning...")
    end,
}
