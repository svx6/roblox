return {
    Name = "yeet",
    Category = "fling",
    Permission = 1,
    Aliases = {"yoink", "launch", "toss"},
    Execute = function(BotEnv, args, executor, restArgs)
        if not args[2] then BotEnv.RespondError("need a target") return end
        local targets = BotEnv.GetMultipleTargets(args[2], executor)
        if #targets == 0 then BotEnv.RespondError("cant find " .. args[2]) return end
        local FlingPower = BotEnv.FlingPower or 99999999
        task.spawn(function()
            for _, target in ipairs(targets) do
                pcall(function()
                    local waitStart = tick()
                    while BotEnv.GetFlag("IsFlingBusy") do
                        task.wait(0.05)
                        if tick() - waitStart > 10 then return end
                    end
                    BotEnv.SetFlag("IsFlingBusy", true)
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
                    botHum:ChangeState(Enum.HumanoidStateType.Physics)
                    local bv = Instance.new("BodyVelocity")
                    bv.Velocity = Vector3.new(FlingPower * 0.5, FlingPower * 3, FlingPower * 0.5)
                    bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
                    bv.P = 9999
                    bv.Parent = botHRP
                    local bav = Instance.new("BodyAngularVelocity")
                    bav.AngularVelocity = Vector3.new(FlingPower, FlingPower * 2, FlingPower)
                    bav.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
                    bav.P = 9999
                    bav.Parent = botHRP
                    local angles = {
                        CFrame.new(0, -3, 0), CFrame.new(0, -4, 0), CFrame.new(0, -2, 0),
                        CFrame.new(1, -3, 0), CFrame.new(-1, -3, 0), CFrame.new(0, -3, 1),
                        CFrame.new(0, -3, -1), CFrame.new(0, -5, 0),
                    }
                    for i = 1, 60 do
                        if not target or not target.Parent then break end
                        if not BotEnv.IsAlive(target) then break end
                        local tHRP = BotEnv.GetHRP(target)
                        if not tHRP then break end
                        local cBotHRP = BotEnv.GetBotHRP()
                        if not cBotHRP then break end
                        cBotHRP.CFrame = tHRP.CFrame * angles[(i % #angles) + 1]
                        cBotHRP.AssemblyLinearVelocity = Vector3.new(0, FlingPower * 3, 0)
                        cBotHRP.AssemblyAngularVelocity = Vector3.new(FlingPower, FlingPower, FlingPower)
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
                    if char then
                        for pt, props in pairs(origProps) do
                            if pt and pt.Parent then
                                if props then pt.CustomPhysicalProperties = props
                                else pt.CustomPhysicalProperties = PhysicalProperties.new(0.7, 0.3, 0.5, 1, 1) end
                            end
                        end
                    end
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
                task.wait(0.05)
            end
        end)
        BotEnv.Respond("yeeted " .. args[2])
    end,
}
