return {
    Name = "spin", Category = "utility", Permission = 1, Aliases = {"unspin", "rotate"},
    Execute = function(BotEnv, args, executor, restArgs)
        local mode = args[2] and args[2]:lower() or nil
        local spd = tonumber(args[2]) or tonumber(args[3]) or BotEnv.SpinSpeed
        local isOn = BotEnv.GetFlag("IsSpinning")
        local function startSpin()
            BotEnv.SetFlag("IsSpinning", true); BotEnv.DisconnectSafe("Spin")
            local hrp = BotEnv.GetBotHRP(); if not hrp then return end
            local bav = Instance.new("BodyAngularVelocity"); bav.AngularVelocity = Vector3.new(0, spd, 0); bav.MaxTorque = Vector3.new(0, math.huge, 0); bav.P = 9999; bav.Name = "BotSpin"; bav.Parent = hrp
            local conn = BotEnv.RunService.Heartbeat:Connect(function()
                if not BotEnv.GetFlag("IsSpinning") then BotEnv.DisconnectSafe("Spin"); pcall(function() local h = BotEnv.GetBotHRP(); if h then local s = h:FindFirstChild("BotSpin"); if s then s:Destroy() end end end); return end
            end)
            BotEnv.TrackConnection("Spin", conn)
            BotEnv.Respond("Spin ON (speed:" .. spd .. ")")
        end
        local function stopSpin()
            BotEnv.SetFlag("IsSpinning", false); BotEnv.DisconnectSafe("Spin")
            pcall(function() local h = BotEnv.GetBotHRP(); if h then local s = h:FindFirstChild("BotSpin"); if s then s:Destroy() end end end)
            BotEnv.Respond("Spin OFF")
        end
        if mode == "on" or mode == "1" then startSpin()
        elseif mode == "off" or mode == "0" then stopSpin()
        else if isOn then stopSpin() else startSpin() end end
    end,
}
