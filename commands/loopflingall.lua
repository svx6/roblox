return {
    Name = "loopflingall",
    Category = "fling",
    Permission = 1,
    Aliases = {},
    Execute = function(BotEnv, args, executor, restArgs)
        BotEnv.DisconnectSafe("LoopFlingAll")
        BotEnv.DisconnectSafe("LoopFling")
        BotEnv.DisconnectSafe("LoopKill")
        local lastFlingTime = 0
        local flingActive = false
        local FlingPower = BotEnv.FlingPower or 99999999
        BotEnv.ActiveConnections.LoopFlingAll = BotEnv.RunService.Heartbeat:Connect(function()
            if flingActive then return end
            local now = tick()
            if (now - lastFlingTime) < BotEnv.LoopFlingDelay then return end
            lastFlingTime = now
            flingActive = true
            task.spawn(function()
                pcall(function()
                    for _, p in ipairs(BotEnv.Players:GetPlayers()) do
                        if p ~= BotEnv.LocalPlayer and BotEnv.IsAlive(p) and BotEnv.GetHRP(p) then
                            pcall(function()
                                -- Wait if busy
                                local waitStart = tick()
                                while BotEnv.GetFlag("IsFlingBusy") do
                                    task.wait(0.05)
                                    if tick() - waitStart > 10 then return end
                                end
                                BotEnv.SetFlag("IsFlingBusy", true)

                                if not p or not p.Parent or not BotEnv.IsAlive(p) then
                                    BotEnv.SetFlag("IsFlingBusy", false)
                                    return
                                end

                                local targetHRP = BotEnv.GetHRP(p)
                                local botHRP = BotEnv.GetBotHRP()
                                local botHum = BotEnv.GetBotHumanoid()
                                if not targetHRP or not botHRP or not botHum then
                                    BotEnv.SetFlag("IsFlingBusy", false)
                                    return
                                end

                                local savedPos = botHRP.CFrame
                                botHum:ChangeState(Enum.HumanoidStateType.Physics)

                                local bv = Instance.new("BodyVelocity")
                                bv.Velocity = Vector3.new(FlingPower, FlingPower, FlingPower)
                                bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
                                bv.P = 9999
                                bv.Parent = botHRP

                                local bav = Instance.new("BodyAngularVelocity")
                                bav.AngularVelocity = Vector3.new(FlingPower, FlingPower * 2, FlingPower)
                                bav.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
                                bav.P = 9999
                                bav.Parent = botHRP

                                local angles = {
                                    CFrame.new(0, -3, 0), CFrame.new(1, -2, 0), CFrame.new(-1, -2, 0),
                                    CFrame.new(0, -2, 1), CFrame.new(0, -2, -1), CFrame.new(0, -4, 0),
                                    CFrame.new(2, -3, 0), CFrame.new(-2, -3, 0),
                                }

                                for i = 1, 50 do
                                    if not p or not p.Parent then break end
                                    if not BotEnv.IsAlive(p) then break end
                                    local tHRP = BotEnv.GetHRP(p)
                                    if not tHRP then break end
                                    local cBotHRP = BotEnv.GetBotHRP()
                                    if not cBotHRP then break end
                                    cBotHRP.CFrame = tHRP.CFrame * angles[(i % #angles) + 1]
                                    cBotHRP.AssemblyLinearVelocity = (tHRP.Position - cBotHRP.Position).Unit * FlingPower
                                    cBotHRP.AssemblyAngularVelocity = Vector3.new(FlingPower, FlingPower, FlingPower)
                                    BotEnv.RunService.Heartbeat:Wait()
                                end

                                pcall(function() bv:Destroy() end)
                                pcall(function() bav:Destroy() end)

                                local resetHRP = BotEnv.GetBotHRP()
                                if resetHRP then
                                    resetHRP.CFrame = savedPos
                                    resetHRP.AssemblyLinearVelocity = Vector3.zero
                                    resetHRP.AssemblyAngularVelocity = Vector3.zero
                                end
                                local resetHum = BotEnv.GetBotHumanoid()
                                if resetHum then resetHum:ChangeState(Enum.HumanoidStateType.GettingUp) end

                                BotEnv.SetFlag("IsFlingBusy", false)
                            end)
                        end
                    end
                end)
                flingActive = false
            end)
        end)
        BotEnv.Respond("loopfling all on", nil)
    end,
}
