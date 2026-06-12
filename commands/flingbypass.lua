-- flingbypass.lua
-- Method 10: Anti-Fling Bypass
--
-- How the target anti-fling script works:
--   · Every Heartbeat: sets CustomPhysicalProperties to (0,0,0,0,0), zeroes
--     Velocity/RotVelocity on the target's HRP, sets CanCollide = false.
--   · task.wait(1) inside the heartbeat = a full second gap every cycle.
--
-- Bypass strategy:
--   1. We use AssemblyLinearVelocity / AssemblyAngularVelocity instead of the
--      legacy Velocity property — the anti-fling only zeros Velocity, not Assembly*.
--   2. We set OUR OWN mass to 100 (heavy) so even a zero-mass target still gets
--      physics impulse from collision.
--   3. We spam CFrame overlap at sub-frame intervals to guarantee physics contact
--      before the anti-fling heartbeat can fire again.
--   4. We re-apply our BodyVelocity + BodyAngularVelocity every frame to overcome
--      any force the anti-fling places on the target.
--   5. We never rely on the target's CanCollide — we use firetouchinterest() if
--      available to force touch events regardless of collision state.

return {
    Name = "flingbypass",
    Aliases = {"fb", "bypassfling", "afbypass"},
    Description = "Fling a player with anti-fling bypass (method 10)",
    Permission = 2,

    Execute = function(BotEnv, args, executor, restArgs)
        local targetName = args[2]
        if not targetName or targetName == "" then
            BotEnv.RespondError("Usage: flingbypass <player>", nil)
            return
        end

        local targets = BotEnv.GetMultipleTargets(targetName, executor)
        if not targets or #targets == 0 then
            BotEnv.RespondError("Player not found: " .. targetName, nil)
            return
        end

        local RunService  = BotEnv.RunService
        local Workspace   = BotEnv.Workspace
        local FlingPower  = BotEnv.FlingPower or 99999999
        local hasFTI      = BotEnv.ExecutorInfo and BotEnv.ExecutorInfo.HasFireTouchInterest

        local function DoBypassFling(target)
            if not BotEnv.IsAlive(target) then return false end

            -- Wait for fling lock
            local ws = BotEnv.safeTick()
            while BotEnv.GetFlag("IsFlingBusy") do
                task.wait(0.05)
                if BotEnv.safeTick() - ws > 2 then return false end
            end
            BotEnv.SetFlag("IsFlingBusy", true)

            local killed = false
            local ok = pcall(function()
                local bh = BotEnv.GetBotHRP()
                local bm = BotEnv.GetBotHumanoid()
                if not bh or not bm then return end

                local savedPos = bh.CFrame

                -- ── Phase 1: PreFling + max-mass setup ──────────────────
                BotEnv.PreFling()
                bm:ChangeState(Enum.HumanoidStateType.Physics)

                local char = BotEnv.LocalPlayer.Character
                local origProps = {}

                -- Make ourselves extremely heavy so zero-mass target still gets hit
                pcall(function()
                    if char then
                        for _, pt in ipairs(char:GetDescendants()) do
                            if pt:IsA("BasePart") then
                                origProps[pt] = pt.CustomPhysicalProperties
                                -- density=100, friction=0, elasticity=0, fd=100, ed=100
                                pt.CustomPhysicalProperties = PhysicalProperties.new(100, 0, 0, 100, 100)
                            end
                        end
                    end
                end)

                -- Attach strong body movers
                local bv = Instance.new("BodyVelocity")
                bv.Velocity    = Vector3.new(FlingPower, FlingPower, FlingPower)
                bv.MaxForce    = Vector3.new(math.huge, math.huge, math.huge)
                bv.P           = 99999
                bv.Parent      = bh

                local ba = Instance.new("BodyAngularVelocity")
                ba.AngularVelocity = Vector3.new(FlingPower, FlingPower, FlingPower)
                ba.MaxTorque       = Vector3.new(math.huge, math.huge, math.huge)
                ba.P               = 99999
                ba.Parent          = bh

                -- ── Phase 2: Overlap spam at sub-frame rate ─────────────
                local iterations = 140  -- ~2.3 seconds at 60fps
                for i = 1, iterations do
                    if not target or not target.Parent then break end
                    if not BotEnv.IsAlive(target) then killed = true; break end

                    local th = BotEnv.GetHRP(target)
                    if not th then break end
                    local cb = BotEnv.GetBotHRP()
                    if not cb then break end

                    -- Alternate between direct overlap and tight orbital
                    if i % 4 == 0 then
                        cb.CFrame = th.CFrame
                        cb.AssemblyLinearVelocity = Vector3.new(
                            math.random(-1,1) * FlingPower,
                            math.random(-1,1) * FlingPower,
                            math.random(-1,1) * FlingPower
                        )
                    elseif i % 4 == 1 then
                        local ang = i * 1.2
                        cb.CFrame = th.CFrame * CFrame.new(
                            math.cos(ang) * 0.4,
                            math.sin(i * 0.7) * 0.4,
                            math.sin(ang) * 0.4
                        )
                        cb.AssemblyLinearVelocity = (th.Position - cb.Position).Unit * FlingPower
                    elseif i % 4 == 2 then
                        cb.CFrame = th.CFrame * CFrame.new(
                            math.random() * 0.6 - 0.3,
                            math.random() * 0.6 - 0.3,
                            math.random() * 0.6 - 0.3
                        )
                        cb.AssemblyLinearVelocity = Vector3.new(
                            (math.random()-0.5) * FlingPower * 2,
                            (math.random()-0.5) * FlingPower * 2,
                            (math.random()-0.5) * FlingPower * 2
                        )
                    else
                        cb.CFrame = th.CFrame * CFrame.new(0, 0.5, 0)
                        cb.AssemblyLinearVelocity = Vector3.new(0, -FlingPower, 0)
                    end

                    cb.AssemblyAngularVelocity = Vector3.new(
                        FlingPower, FlingPower, FlingPower
                    )

                    if i % 6 == 0 then
                        bv.Velocity = Vector3.new(
                            math.random(-1,1) * FlingPower,
                            math.random(-1,1) * FlingPower,
                            math.random(-1,1) * FlingPower
                        )
                        ba.AngularVelocity = Vector3.new(
                            math.random(-1,1) * FlingPower,
                            math.random(-1,1) * FlingPower,
                            math.random(-1,1) * FlingPower
                        )
                    end

                    if hasFTI then
                        pcall(function()
                            firetouchinterest(cb, th, 0)
                            firetouchinterest(cb, th, 1)
                        end)
                        local tChar = BotEnv.GetCharacter(target)
                        if tChar then
                            for _, part in ipairs(tChar:GetDescendants()) do
                                if part:IsA("BasePart") and part ~= th then
                                    pcall(function()
                                        firetouchinterest(cb, part, 0)
                                        firetouchinterest(cb, part, 1)
                                    end)
                                end
                            end
                        end
                    end

                    if i % 10 == 0 then
                        pcall(BotEnv.ApplyAntiGravity)
                    end

                    RunService.Heartbeat:Wait()
                end

                -- Cleanup body movers
                pcall(function() bv:Destroy() end)
                pcall(function() ba:Destroy() end)

                -- Restore our physical properties
                pcall(function()
                    if char then
                        for pt, props in pairs(origProps) do
                            if pt and pt.Parent then
                                if props then
                                    pt.CustomPhysicalProperties = props
                                else
                                    pt.CustomPhysicalProperties = PhysicalProperties.new(0.7, 0.3, 0.5, 1, 1)
                                end
                            end
                        end
                    end
                end)

                -- ── Phase 3: PostFling ───────────────────────────────────
                BotEnv.PostFling(savedPos)

                if not killed then
                    killed = not BotEnv.IsAlive(target)
                end
            end)

            BotEnv.SetFlag("IsFlingBusy", false)

            -- Record result in stats system if flingmethod loaded it
            if type(BotEnv._FlingRecordResult) == "function" then
                pcall(BotEnv._FlingRecordResult, 10, killed)
            end

            return killed
        end

        -- Execute for each target
        for _, target in ipairs(targets) do
            task.spawn(function()
                local killed = DoBypassFling(target)
                if killed then
                    BotEnv.Respond("Bypass fling: " .. target.Name .. " sent", nil, true)
                else
                    BotEnv.Respond("Bypass fling: " .. target.Name .. " survived (strong anti-fling)", nil, true)
                end
            end)
        end
    end,
}
