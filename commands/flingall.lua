return {
    Name = "flingall",
    Category = "fling",
    Permission = 1,
    Aliases = {},
    Execute = function(BotEnv, args, executor, restArgs)
        task.spawn(function()
            for _, p in ipairs(BotEnv.Players:GetPlayers()) do
                if p ~= BotEnv.LocalPlayer and BotEnv.IsAlive(p) then
                    BotEnv.ExecuteSmartFling(p)
                    task.wait(0.05)
                end
            end
        end)
        BotEnv.Respond("flinging everyone", nil)
    end,
}
