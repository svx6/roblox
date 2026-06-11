return {
    Name = "savepos", Category = "movement", Permission = 1, Aliases = {"save", "markpos", "checkpoint"},
    Execute = function(BotEnv, args, executor, restArgs)
        local hrp = BotEnv.GetBotHRP()
        if not hrp then BotEnv.RespondError("No character"); return end
        BotEnv.SetFlag("SavedCFrame", hrp.CFrame)
        local pos = hrp.Position
        BotEnv.Respond("Saved: " .. math.floor(pos.X) .. ", " .. math.floor(pos.Y) .. ", " .. math.floor(pos.Z))
    end,
}
