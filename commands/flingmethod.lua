return {
    Name = "flingmethod",
    Category = "fling",
    Permission = 1,
    Aliases = {},
    Execute = function(BotEnv, args, executor, restArgs)
        local wt = nil
        local method = tonumber(args[2]) or 0
        if method < 0 or method > #BotEnv.FlingMethods then
            BotEnv.Respond("methods: 0=auto 1=slam 2=multiangle 3=burst 4=collision 5=seat", wt)
        else
            BotEnv.SetFlag("PreferredFlingMethod", method)
            BotEnv.Respond("fling method set to " .. (method == 0 and "auto" or tostring(method)), wt)
        end
    end,
}
