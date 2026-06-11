return {
    Name = "platform", Category = "utility", Permission = 1, Aliases = {"plat", "unplatform", "unplat"},
    Execute = function(BotEnv, args, executor, restArgs)
        local cmd = args[1]:lower()
        if cmd == "unplatform" or cmd == "unplat" then
            pcall(function()
                local p = BotEnv.GetFlag("PlatformPart")
                if p then pcall(function() p:Destroy() end); BotEnv.SetFlag("PlatformPart", nil) end
                for _, obj in ipairs(game:GetService("Workspace"):GetChildren()) do
                    if obj.Name == "BotPlatform" then obj:Destroy() end
                end
            end)
            BotEnv.Respond("Platform removed"); return
        end
        local hrp = BotEnv.GetBotHRP(); if not hrp then BotEnv.RespondError("No character"); return end
        pcall(function()
            local existing = game:GetService("Workspace"):FindFirstChild("BotPlatform")
            if existing then existing:Destroy() end
        end)
        local p = Instance.new("Part")
        p.Name = "BotPlatform"; p.Size = Vector3.new(20, 1, 20); p.Anchored = true; p.Material = Enum.Material.Neon
        p.BrickColor = BrickColor.new("Really black"); p.Transparency = 0.3
        p.Position = hrp.Position - Vector3.new(0, 3, 0); p.Parent = game:GetService("Workspace")
        BotEnv.SetFlag("PlatformPart", p)
        BotEnv.Respond("Platform created")
    end,
}
