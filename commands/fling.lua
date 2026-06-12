return {
    Name = "fling",
    Aliases = {"fl", "launch"},
    Description = "Fling a player - guaranteed working yeet method",
    Permission = 2,

    Execute = function(BotEnv, args, executor, restArgs)
        local targetName = args[2]
        if not targetName or targetName == "" then
            BotEnv.RespondError("Usage: fling <player>", nil)
            return
        end

        local targets = BotEnv.GetMultipleTargets(targetName, executor)
        if not targets or #targets == 0 then
            BotEnv.RespondError("Player not found: " .. targetName, nil)
            return
        end

        for _, target in ipairs(targets) do
            if not BotEnv.IsAlive(target) then
                BotEnv.RespondError(target.Name .. " is not alive", nil)
            else
                task.spawn(function()
                    -- Wait if another fling is running
                    local waitStart = tick()
                    while BotEnv.GetFlag("IsFlingBusy") do
                        task.wait(0.05)
                        if tick() - waitStart > 10 then return end
                    end
                    BotEnv.SetFlag("IsFlingBusy", true)

                    pcall(function()
                        if not target or not target.Parent or not BotEnv.IsAlive(target) then
                            BotEnv.SetFlag("IsFlingBusy", false)
                            return
                        end

                        local targetHRP = BotEnv.GetHRP(target)
                        local botHRP = BotEnv.GetBotHRP()
                        local botHum = BotEnv.GetBotHumanoid()
                        if not targetHRP or not botHRP or not botHum then
                            BotEnv.SetFlag("IsFlingBusy", false)
                            return
                        end

                        local savedPos = botHRP.CFrame
                        local FlingPower = BotEnv.FlingPower or 99999999

                        -- Heavy mass for maximum physics impact
                        local char = BotEnv.LocalPlayer.Character
                        local origProps = {}
                        if char then
                            for _, pt in ipairs(char:GetDescendants()) do
                                if pt:IsA("BasePart") then
                                    origProps[pt] = pt.CustomPhysicalProperties
                                    pt.CustomPhysicalProperties = PhysicalProperties.new(100, 0, 0, 100, 100)
                                end
                            end
                        end

                        -- Physics mode - same as yeet
                        botHum:ChangeState(Enum.HumanoidStateType.Physics)

                        -- BodyVelocity with max power - same as yeet
                        local bv = Instance.new("BodyVelocity")
                        bv.Velocity = Vector3.new(FlingPower, FlingPower, FlingPower)
                        bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
                        bv.P = 9999
                        bv.Parent = botHRP

                        -- Spin with max power - same as yeet
                        local bav = Instance.new("BodyAngularVelocity")
                        bav.AngularVelocity = Vector3.new(FlingPower, FlingPower * 2, FlingPower)
                        bav.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
                        bav.P = 9999
                        bav.Parent = botHRP

                        -- CFrame offsets to orbit around the target - same as yeet
                        local angles = {
                            CFrame.new(0, -3, 0), CFrame.new(1, -2, 0), CFrame.new(-1, -2, 0),
                            CFrame.new(0, -2, 1), CFrame.new(0, -2, -1), CFrame.new(0, -4, 0),
                            CFrame.new(2, -3, 0), CFrame.new(-2, -3, 0),
                        }

                        -- 60 frames of CFrame slamming into target
                        for i = 1, 60 do
                            if not target or not target.Parent then break end
                            if not BotEnv.IsAlive(target) then break end
                            local tHRP = BotEnv.GetHRP(target)
                            if not tHRP then break end
                            local cBotHRP = BotEnv.GetBotHRP()
                            if not cBotHRP then break end

                            -- Slam directly into target position with offset
                            cBotHRP.CFrame = tHRP.CFrame * angles[(i % #angles) + 1]

                            -- Also set velocity aiming at target for extra impact
                            cBotHRP.AssemblyLinearVelocity = (tHRP.Position - cBotHRP.Position).Unit * FlingPower
                            cBotHRP.AssemblyAngularVelocity = Vector3.new(FlingPower, FlingPower, FlingPower)

                            -- Fire touch if executor supports it
                            pcall(function()
                                if BotEnv.ExecutorInfo.HasFireTouchInterest then
                                    firetouchinterest(cBotHRP, tHRP, 0)
                                    firetouchinterest(cBotHRP, tHRP, 1)
                                end
                            end)

                            BotEnv.RunService.Heartbeat:Wait()
                        end

                        pcall(function() bv:Destroy() end)
                        pcall(function() bav:Destroy() end)

                        -- Restore mass
                        if char then
                            for pt, props in pairs(origProps) do
                                if pt and pt.Parent then
                                    if props then pt.CustomPhysicalProperties = props
                                    else pt.CustomPhysicalProperties = PhysicalProperties.new(0.7, 0.3, 0.5, 1, 1) end
                                end
                            end
                        end

                        -- Return to original position
                        local resetHRP = BotEnv.GetBotHRP()
                        if resetHRP then
                            resetHRP.CFrame = savedPos
                            resetHRP.AssemblyLinearVelocity = Vector3.zero
                            resetHRP.AssemblyAngularVelocity = Vector3.zero
                        end
                        local resetHum = BotEnv.GetBotHumanoid()
                        if resetHum then resetHum:ChangeState(Enum.HumanoidStateType.GettingUp) end
                    end)

                    BotEnv.SetFlag("IsFlingBusy", false)
                end)
            end
        end

        BotEnv.Respond("flinging " .. targetName, nil)
    end,
}
