return {
    Name = "blackhole", Category = "combat", Permission = 2, Aliases = {"unblackhole", "bh", "vortex"},
    Execute = function(BotEnv, args, executor, restArgs)
        local isOn = BotEnv.GetFlag("IsBlackHole")
        if isOn then
            BotEnv.SetFlag("IsBlackHole", false); BotEnv.DisconnectSafe("BlackHole"); BotEnv.Respond("BlackHole OFF")
        else
            BotEnv.SetFlag("IsBlackHole", true); BotEnv.DisconnectSafe("BlackHole")
            local conn = BotEnv.RunService.Heartbeat:Connect(function()
                pcall(function()
                    if not BotEnv.GetFlag("IsBlackHole") then BotEnv.DisconnectSafe("BlackHole"); return end
                    local bh = BotEnv.GetBotHRP(); if not bh then return end
                    for _, p in ipairs(BotEnv.Players:GetPlayers()) do
                        if p ~= BotEnv.LocalPlayer and BotEnv.IsAlive(p) and not BotEnv.IsTargetProtected(p) then
                            task.spawn(function()
                                pcall(function() BotEnv.BringPlayer(p, bh.CFrame) end)
                            end)
                        end
                    end
                end)
            end)
            BotEnv.TrackConnection("BlackHole", conn)
            BotEnv.Respond("BlackHole ON")
        end
    end,
}
