return {
    Name = "trail", Category = "utility", Permission = 1, Aliases = {"untrail", "breadcrumb"},
    Execute = function(BotEnv, args, executor, restArgs)
        local isOn = BotEnv.GetFlag("IsTrailing")
        if isOn then
            BotEnv.SetFlag("IsTrailing", false); BotEnv.DisconnectSafe("Trail")
            for _, pt in ipairs(BotEnv.TrailParts) do pcall(function() pt:Destroy() end) end
            BotEnv.TrailParts = {}
            BotEnv.Respond("Trail OFF")
        else
            BotEnv.SetFlag("IsTrailing", true); BotEnv.DisconnectSafe("Trail")
            local lastPos = nil
            local conn = BotEnv.RunService.Heartbeat:Connect(function()
                pcall(function()
                    if not BotEnv.GetFlag("IsTrailing") then BotEnv.DisconnectSafe("Trail"); return end
                    local hrp = BotEnv.GetBotHRP(); if not hrp then return end
                    if not lastPos or (hrp.Position - lastPos).Magnitude > 3 then
                        lastPos = hrp.Position
                        local p = Instance.new("Part")
                        p.Size = Vector3.new(1, 1, 1); p.Position = hrp.Position - Vector3.new(0, 3, 0)
                        p.Anchored = true; p.CanCollide = false; p.Material = Enum.Material.Neon
                        p.BrickColor = BrickColor.Random(); p.Transparency = 0.3; p.Shape = Enum.PartType.Ball
                        p.Name = "BotTrail"; p.Parent = game:GetService("Workspace")
                        BotEnv.TrailParts[#BotEnv.TrailParts+1] = p
                        if #BotEnv.TrailParts > 100 then
                            pcall(function() BotEnv.TrailParts[1]:Destroy() end)
                            table.remove(BotEnv.TrailParts, 1)
                        end
                        task.delay(15, function() pcall(function() p:Destroy() end) end)
                    end
                end)
            end)
            BotEnv.TrackConnection("Trail", conn)
            BotEnv.Respond("Trail ON")
        end
    end,
}
