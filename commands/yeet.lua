return {
    Name = "yeet",
    Category = "fling",
    Permission = 1,
    Aliases = {},
    Execute = function(BotEnv, args, executor, restArgs)
        local wt = nil
        if not args[2] then BotEnv.RespondError("need a target", wt) return end
        local target = BotEnv.GetSmartTarget(args[2], executor)
        if not target then BotEnv.RespondError("cant find " .. args[2], wt) return end
        task.spawn(function()
            local waitStart = tick()
            while BotEnv.GetFlag("IsFlingBusy") do
                task.wait(0.05)
                if tick() - waitStart > 10 then return end
            end
            BotEnv.SetFlag("IsFlingBusy", true)
            pcall(function()
                if not target or not target.Parent or not BotEnv.IsAlive(target) then BotEnv.SetFlag("IsFlingBusy", false) return end
                local targetHRP = BotEnv.GetHRP(target)
                local botHRP = BotEnv.GetBotHRP()
                local botHum = BotEnv.GetBotHumanoid()
                if not targetHRP or not botHRP or not botHum then BotEnv.SetFlag("IsFlingBusy", false) return end
                local savedPos = botHRP.CFrame
                botHum:ChangeState(Enum.HumanoidStateType.Physics)
                local lookDir = targetHRP.CFrame.LookVector
                local yeetDir = (Vector3.new(lookDir.X, 3, lookDir.Z)).Unit
                local bv = Instance.new("BodyVelocity")
                bv.Velocity = yeetDir * BotEnv.FlingPower * 3
                bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
                bv.P = 9999
                bv.Parent = botHRP
                local bav = Instance.new("BodyAngularVelocity")
                bav.AngularVelocity = Vector3.new(BotEnv.FlingPower, BotEnv.FlingPower * 2, BotEnv.FlingPower)
                bav.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
                bav.P = 9999
                bav.Parent = botHRP
                local angles = {
                    CFrame.new(0, -3, 0), CFrame.new(1, -2, 0), CFrame.new(-1, -2, 0),
                    CFrame.new(0, -2, 1), CFrame.new(0, -2, -1), CFrame.new(0, -4, 0),
                    CFrame.new(2, -3, 0), CFrame.new(-2, -3, 0),
                }
                for i = 1, 50 do
                    if not target or not target.Parent then break end
                    if not BotEnv.IsAlive(target) then break end
                    local tHRP = BotEnv.GetHRP(target)
                    if not tHRP then break end
                    local cBotHRP = BotEnv.GetBotHRP()
                    if not cBotHRP then break end
                    cBotHRP.CFrame = tHRP.CFrame * angles[(i % #angles) + 1]
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
            end)
            BotEnv.SetFlag("IsFlingBusy", false)
        end)
        BotEnv.Respond("yeeted " .. target.Name, wt)
    end,
}
