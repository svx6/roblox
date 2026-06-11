return {
    Name = "rejoin", Category = "admin", Permission = 3, Aliases = {"rj"},
    Execute = function(BotEnv, args, executor, restArgs)
        BotEnv.Respond("Rejoining...")
        task.wait(0.5)
        pcall(function()
            if BotEnv.TeleportService then
                BotEnv.TeleportService:Teleport(game.PlaceId, BotEnv.LocalPlayer)
            end
        end)
    end,
}
