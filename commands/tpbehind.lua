return {
    Name = "tpbehind",
    Category = "movement",
    Permission = 1,
    Aliases = {},
    Execute = function(BotEnv, args, executor, restArgs)
        local wt = nil
        if not args[2] then BotEnv.RespondError("need a target", wt) return end
        local target = BotEnv.GetSmartTarget(args[2], executor)
        if not target then BotEnv.RespondError("cant find " .. args[2], wt) return end
        local tHRP = BotEnv.GetHRP(target)
        local botHRP = BotEnv.GetBotHRP()
        if tHRP and botHRP then
            botHRP.CFrame = tHRP.CFrame * CFrame.new(0, 0, 5)
            BotEnv.Respond("tp'd behind " .. target.Name, wt)
        end
    end,
}
