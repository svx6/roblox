return {
    Name = "stop", Category = "admin", Permission = 1, Aliases = {"stopall", "stoploop", "stopallloops", "reset"},
    Execute = function(BotEnv, args, executor, restArgs)
        BotEnv.StopAllLoops()
        BotEnv.Respond("All loops stopped")
    end,
}
