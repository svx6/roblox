return {
    Name = "clean", Category = "admin", Permission = 3, Aliases = {"cleanup", "fullclean", "purge"},
    Execute = function(BotEnv, args, executor, restArgs)
        BotEnv.FullCleanup()
        BotEnv.Respond("Full cleanup done")
    end,
}
