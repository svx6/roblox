return {
    Name = "antifling", Category = "admin", Permission = 2, Aliases = {"unantifling", "af", "nofling"},
    Execute = function(BotEnv, args, executor, restArgs)
        local isOn = BotEnv.GetFlag("IsAntiFling")
        if isOn then
            BotEnv.SetFlag("IsAntiFling", false); BotEnv.DisconnectSafe("AntiFling"); BotEnv.Respond("AntiFling OFF")
        else
            BotEnv.SetFlag("IsAntiFling", true); BotEnv.DisconnectSafe("AntiFling")
            local conn = BotEnv.RunService.Heartbeat:Connect(function()
                pcall(function()
                    if not BotEnv.GetFlag("IsAntiFling") then return end
                    local hrp = BotEnv.GetBotHRP(); if not hrp then return end
                    local vel = hrp.AssemblyLinearVelocity
                    if vel.Magnitude > 200 then
                        hrp.AssemblyLinearVelocity = Vector3.zero
                        hrp.AssemblyAngularVelocity = Vector3.zero
                    end
                    for _, obj in ipairs(hrp:GetChildren()) do
                        if (obj:IsA("BodyVelocity") or obj:IsA("BodyAngularVelocity")) and obj.Name ~= "FlyVelocity" and obj.Name ~= "BotSpin" then
                            pcall(function() obj:Destroy() end)
                        end
                    end
                end)
            end)
            BotEnv.TrackConnection("AntiFling", conn)
            BotEnv.Respond("AntiFling ON")
        end
    end,
}
