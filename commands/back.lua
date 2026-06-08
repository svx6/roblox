return {
    Name = "back",
    Category = "movement",
    Permission = 1,
    Aliases = {},
    Execute = function(BotEnv, args, executor, restArgs)
        local wt = nil
        local saved = BotEnv.GetFlag("SavedCFrame")
        if saved then
            local botHRP = BotEnv.GetBotHRP()
            if botHRP then botHRP.CFrame = saved BotEnv.SetFlag("SavedCFrame", nil) BotEnv.Respond("returned to saved position", wt) end
        else
            BotEnv.RespondError("no saved position (use safetp first)", wt)
        end
    end,
}
