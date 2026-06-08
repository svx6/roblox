return {
    Name = "tpcoords",
    Category = "movement",
    Permission = 1,
    Aliases = {},
    Execute = function(BotEnv, args, executor, restArgs)
        local wt = nil
        local x = tonumber(args[2])
        local y = tonumber(args[3])
        local z = tonumber(args[4])
        if not x or not y or not z then BotEnv.RespondError("need x y z coords", wt) return end
        local botHRP = BotEnv.GetBotHRP()
        if botHRP then botHRP.CFrame = CFrame.new(x, y, z) BotEnv.Respond("tp'd to coords", wt) end
    end,
}
