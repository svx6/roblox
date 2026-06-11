return {
    Name = "giant", Category = "utility", Permission = 1, Aliases = {"big", "grow", "tiny", "small", "shrink", "unsize", "resetsize"},
    Execute = function(BotEnv, args, executor, restArgs)
        local cmd = args[1]:lower()
        local scale = 5
        if cmd == "tiny" or cmd == "small" or cmd == "shrink" then scale = 0.3
        elseif cmd == "unsize" or cmd == "resetsize" then scale = 1
        else scale = tonumber(args[2]) or 5 end
        pcall(function()
            local c = BotEnv.LocalPlayer.Character; if not c then return end
            local hum = c:FindFirstChildOfClass("Humanoid"); if not hum then return end
            local desc = hum:FindFirstChildOfClass("HumanoidDescription")
            if desc then
                desc.HeightScale = scale; desc.WidthScale = scale; desc.DepthScale = scale; desc.HeadScale = scale
                pcall(function() hum:ApplyDescription(desc) end)
            else
                for _, v in ipairs(hum:GetChildren()) do
                    if v:IsA("NumberValue") and (v.Name:find("Scale") or v.Name == "BodyHeightScale" or v.Name == "BodyWidthScale" or v.Name == "BodyDepthScale" or v.Name == "HeadScale") then
                        v.Value = scale
                    end
                end
            end
        end)
        BotEnv.Respond("Size: " .. scale .. "x")
    end,
}
