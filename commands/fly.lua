return {
    Name = "fly", Category = "movement", Permission = 1, Aliases = {"unfly", "flight"},
    Execute = function(BotEnv, args, executor, restArgs)
        local mode = args[2] and args[2]:lower() or nil
        local spd = tonumber(args[2]) or tonumber(args[3]) or BotEnv.FlySpeed
        local isOn = BotEnv.GetFlag("IsFlying")
        local function startFly()
            local hrp = BotEnv.GetBotHRP(); if not hrp then BotEnv.RespondError("No character"); return end
            BotEnv.SetFlag("IsFlying", true)
            local bg = hrp:FindFirstChild("FlyGyro") or Instance.new("BodyGyro")
            bg.Name = "FlyGyro"; bg.MaxTorque = Vector3.new(math.huge, math.huge, math.huge); bg.P = 9999; bg.Parent = hrp
            local bv = hrp:FindFirstChild("FlyVelocity") or Instance.new("BodyVelocity")
            bv.Name = "FlyVelocity"; bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge); bv.Velocity = Vector3.zero; bv.Parent = hrp
            BotEnv.SetFlag("FlyBodyGyro", bg); BotEnv.SetFlag("FlyBodyVelocity", bv)
            BotEnv.DisconnectSafe("Fly")
            local cam = game:GetService("Workspace").CurrentCamera
            local conn = BotEnv.RunService.Heartbeat:Connect(function()
                pcall(function()
                    if not BotEnv.GetFlag("IsFlying") then BotEnv.DisconnectSafe("Fly"); return end
                    local h = BotEnv.GetBotHRP(); if not h then return end
                    local g = h:FindFirstChild("FlyGyro"); local v = h:FindFirstChild("FlyVelocity")
                    if not g or not v then return end
                    g.CFrame = cam.CFrame
                    local mv = Vector3.zero
                    local uis = BotEnv.UserInputService
                    if uis:IsKeyDown(Enum.KeyCode.W) then mv = mv + cam.CFrame.LookVector end
                    if uis:IsKeyDown(Enum.KeyCode.S) then mv = mv - cam.CFrame.LookVector end
                    if uis:IsKeyDown(Enum.KeyCode.A) then mv = mv - cam.CFrame.RightVector end
                    if uis:IsKeyDown(Enum.KeyCode.D) then mv = mv + cam.CFrame.RightVector end
                    if uis:IsKeyDown(Enum.KeyCode.Space) then mv = mv + Vector3.new(0,1,0) end
                    if uis:IsKeyDown(Enum.KeyCode.LeftShift) then mv = mv - Vector3.new(0,1,0) end
                    v.Velocity = mv.Magnitude > 0 and mv.Unit * spd or Vector3.zero
                end)
            end)
            BotEnv.TrackConnection("Fly", conn)
            BotEnv.Respond("Fly ON (speed:" .. spd .. ")")
        end
        local function stopFly()
            BotEnv.DisconnectSafe("Fly"); BotEnv.SetFlag("IsFlying", false)
            pcall(function() local h = BotEnv.GetBotHRP(); if h then local g = h:FindFirstChild("FlyGyro"); if g then g:Destroy() end; local v = h:FindFirstChild("FlyVelocity"); if v then v:Destroy() end end end)
            BotEnv.Respond("Fly OFF")
        end
        if mode == "on" or mode == "1" then startFly()
        elseif mode == "off" or mode == "0" then stopFly()
        else if isOn then stopFly() else startFly() end end
    end,
}
