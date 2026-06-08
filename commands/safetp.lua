return {
    Name = "safetp",
    Category = "movement",
    Permission = 1,
    Aliases = {},
    Execute = function(BotEnv, args, executor, restArgs)
        local wt = nil
        if not args[2] then BotEnv.RespondError("need a target", wt) return end
        local target = BotEnv.GetSmartTarget(args[2], executor)
        if not target then BotEnv.RespondError("cant find " .. args[2], wt) return end
        local botHRP = BotEnv.GetBotHRP()
        if botHRP then
            BotEnv.SetFlag("SavedCFrame", botHRP.CFrame)
            local targetHRP = BotEnv.GetHRP(target)
            if targetHRP then
                botHRP.CFrame = targetHRP.CFrame * CFrame.new(0, 0, 3)
                BotEnv.Respond("safetp to " .. target.Name .. " (use back to return)", wt)
            end
        end
    end,
}
