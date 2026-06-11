return {
    Name = "xray", Category = "utility", Permission = 1, Aliases = {"unxray", "wallhack", "seethrough"},
    Execute = function(BotEnv, args, executor, restArgs)
        if #BotEnv.XRayParts > 0 then
            for _, d in ipairs(BotEnv.XRayParts) do pcall(function() d.part.Transparency = d.original end) end
            BotEnv.XRayParts = {}
            BotEnv.Respond("XRay OFF")
        else
            for _, obj in ipairs(game:GetService("Workspace"):GetDescendants()) do
                pcall(function()
                    if obj:IsA("BasePart") and obj.Transparency < 0.5 then
                        local size = obj.Size.X * obj.Size.Y * obj.Size.Z
                        if size > 50 and not obj:IsDescendantOf(BotEnv.LocalPlayer.Character or game) then
                            local isChar = false
                            for _, p in ipairs(BotEnv.Players:GetPlayers()) do
                                if p.Character and obj:IsDescendantOf(p.Character) then isChar = true; break end
                            end
                            if not isChar then
                                BotEnv.XRayParts[#BotEnv.XRayParts+1] = {part = obj, original = obj.Transparency}
                                obj.Transparency = 0.7
                            end
                        end
                    end
                end)
            end
            BotEnv.Respond("XRay ON (" .. #BotEnv.XRayParts .. " parts)")
        end
    end,
}
