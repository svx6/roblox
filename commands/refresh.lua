return {
    Name = "refresh", Category = "utility", Permission = 1, Aliases = {"re", "ref"},
    Execute = function(BotEnv, args, executor, restArgs)
        pcall(function()
            local hrp = BotEnv.GetBotHRP()
            local pos = hrp and hrp.CFrame or nil
            local h = BotEnv.GetBotHumanoid()
            if h then h.Health = 0 end
            if pos then
                local conn; conn = BotEnv.LocalPlayer.CharacterAdded:Connect(function(c)
                    pcall(function()
                        conn:Disconnect()
                        task.wait(0.5)
                        local newHRP = c:WaitForChild("HumanoidRootPart", 5)
                        if newHRP then newHRP.CFrame = pos end
                    end)
                end)
            end
        end)
        BotEnv.Respond("Refreshing...")
    end,
}
