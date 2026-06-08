return {
    Name = "unlooptp",
    Category = "movement",
    Permission = 1,
    Aliases = {},
    Execute = function(BotEnv, args, executor, restArgs)
        BotEnv.SetFlag("IsLoopTP", false)
        BotEnv.SetFlag("LoopTPTarget", nil)
        BotEnv.DisconnectSafe("LoopTP")
        BotEnv.Respond("looptp off", nil)
    end,
}
