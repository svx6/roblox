--[[
    Command: auramode
    Category: fx
    Permission: 1
    Usage: ?bot auramode <player>
    Aliases: gojo, shadow, domain, gojomode, shadowmode, domainexpansion, infinity
    Description: GOJO SHADOW STANCE — bot locks 2.5 studs directly behind the
                 target player, matching their exact orientation (like Gojo
                 standing behind Yuji). Triggers a Domain Expansion void burst
                 on activation. Type again or without args to stop.
]]

return {
    Name        = "auramode",
    Category    = "fx",
    Permission  = 1,
    Aliases     = {"gojo", "shadow", "domain", "gojomode", "shadowmode", "domainexpansion", "infinity", "auraall", "modeaura", "botaura", "glowmode"},
    Description = "Gojo Shadow Stance — bot follows 2.5 studs behind target like Gojo (toggle)",
    Execute = function(BotEnv, args, executor, restArgs)
        local isOn = BotEnv.GetFlag("IsGojoShadow")

        -- ─── OFF ──────────────────────────────────────────────────────────────
        if isOn then
            BotEnv.SetFlag("IsGojoShadow", false)
            BotEnv.SetFlag("GojoTarget", nil)
            BotEnv.DisconnectSafe("GojoShadow_Follow")
            BotEnv.DisconnectSafe("GojoShadow_FX")

            if BotEnv.GojoFXParts then
                for _, p in ipairs(BotEnv.GojoFXParts) do
                    pcall(function() p:Destroy() end)
                end
                BotEnv.GojoFXParts = {}
            end

            BotEnv.Respond("🌑 Gojo Shadow OFF")
            return
        end

        -- Resolve target — args[2] or last used target
        local targetName = args[2]
        local target
        if targetName then
            target = BotEnv.GetSmartTarget(targetName, executor)
            if not target then
                BotEnv.RespondError("Can't find player: " .. targetName)
                return
            end
        else
            -- no arg: try executor as default target
            target = executor
        end

        local botHRP = BotEnv.GetBotHRP()
        if not botHRP then BotEnv.RespondError("Bot character not loaded"); return end

        -- ─── ON ───────────────────────────────────────────────────────────────
        BotEnv.SetFlag("IsGojoShadow", true)
        BotEnv.SetFlag("GojoTarget", target)
        BotEnv.GojoFXParts = {}
        local ws = game:GetService("Workspace")

        -- ── Domain Expansion intro: void sphere blasts outward then shrinks ────
        task.spawn(function()
            pcall(function()
                -- Phase 1: expand a dark sphere from bot position
                local void = Instance.new("Part")
                void.Size        = Vector3.new(0.1, 0.1, 0.1)
                void.Shape       = Enum.PartType.Ball
                void.Material    = Enum.Material.Neon
                void.Color       = Color3.new(0.02, 0, 0.08)   -- near-black purple
                void.Transparency = 0.0
                void.CanCollide  = false
                void.Anchored    = true
                void.CastShadow  = false
                void.Name        = "GojoVoid"
                void.Parent      = ws
                local hrp = BotEnv.GetBotHRP()
                if hrp then void.Position = hrp.Position end

                -- Expand to 40 studs
                for step = 1, 20 do
                    task.wait(0.025)
                    if not (void and void.Parent) then break end
                    local s = step * 2
                    void.Size = Vector3.new(s, s, s)
                    void.Transparency = step / 20 * 0.95
                    void.Color = Color3.fromHSV(0.78, 1, math.clamp(step / 20, 0, 1))
                end

                -- Shockwave rings bursting outward (3 rings, staggered)
                for r = 1, 3 do
                    task.wait(0.08)
                    task.spawn(function()
                        if not BotEnv.GetFlag("IsGojoShadow") then return end
                        local ring = Instance.new("Part")
                        ring.Size        = Vector3.new(1, 0.06, 1)
                        ring.Material    = Enum.Material.Neon
                        ring.CanCollide  = false
                        ring.Anchored    = true
                        ring.CastShadow  = false
                        ring.Transparency = 0.1
                        ring.Color       = Color3.fromHSV(0.78 + r * 0.05, 1, 1)
                        local h2 = BotEnv.GetBotHRP()
                        ring.CFrame = h2 and CFrame.new(h2.Position) or CFrame.new(0, 0, 0)
                        ring.Name  = "GojoRing" .. r
                        ring.Parent = ws

                        for step = 1, 28 do
                            task.wait(0.02)
                            if not (ring and ring.Parent) then break end
                            local s = step * 1.3
                            ring.Size = Vector3.new(s, 0.05, s)
                            ring.Transparency = step / 28
                        end
                        pcall(function() if ring and ring.Parent then ring:Destroy() end end)
                    end)
                end

                pcall(function() if void and void.Parent then void:Destroy() end end)
            end)
        end)

        -- ── Persistent FX: 3 vertical "cursed energy" rings at different planes
        local function MakePlaneRing(name)
            local p = Instance.new("Part")
            p.Size        = Vector3.new(4, 0.05, 4)
            p.Material    = Enum.Material.Neon
            p.CanCollide  = false
            p.Anchored    = true
            p.CastShadow  = false
            p.Transparency = 0.55
            p.Color       = Color3.fromHSV(0.78, 1, 1)
            p.Name        = name
            p.Parent      = ws
            BotEnv.GojoFXParts[#BotEnv.GojoFXParts + 1] = p
            return p
        end

        local ring1 = MakePlaneRing("GojoPlane1")  -- horizontal disc
        local ring2 = MakePlaneRing("GojoPlane2")  -- 90° tilt
        local ring3 = MakePlaneRing("GojoPlane3")  -- 45° tilt
        local fxT   = 0

        -- FX loop: spinning rings around bot
        local fxConn = BotEnv.RunService.Heartbeat:Connect(function(dt)
            pcall(function()
                if not BotEnv.GetFlag("IsGojoShadow") then
                    BotEnv.DisconnectSafe("GojoShadow_FX"); return
                end
                fxT = fxT + dt
                local hrp = BotEnv.GetBotHRP()
                if not hrp then return end
                local pos = hrp.Position + Vector3.new(0, 0.8, 0)

                local sz = 4.2 + math.sin(fxT * 2) * 0.5

                -- ring1: horizontal (XZ plane), slow spin — use CFrame.Angles
                if ring1 and ring1.Parent then
                    ring1.CFrame = CFrame.new(pos) * CFrame.Angles(0, fxT * 1.2, 0)
                    ring1.Size   = Vector3.new(sz, 0.04, sz)
                    ring1.Color  = Color3.fromHSV((0.78 + fxT * 0.04) % 1, 1, 1)
                end
                -- ring2: vertical (YZ plane), opposite spin
                if ring2 and ring2.Parent then
                    ring2.CFrame = CFrame.new(pos) * CFrame.Angles(math.pi / 2, -fxT * 0.9, 0)
                    ring2.Size   = Vector3.new(sz * 0.85, 0.04, sz * 0.85)
                    ring2.Color  = Color3.fromHSV((0.82 + fxT * 0.04) % 1, 1, 1)
                end
                -- ring3: diagonal
                if ring3 and ring3.Parent then
                    ring3.CFrame = CFrame.new(pos) * CFrame.Angles(math.pi / 4, fxT * 1.5, math.pi / 4)
                    ring3.Size   = Vector3.new(sz * 0.70, 0.04, sz * 0.70)
                    ring3.Color  = Color3.fromHSV((0.74 + fxT * 0.06) % 1, 1, 1)
                end
            end)
        end)
        BotEnv.TrackConnection("GojoShadow_FX", fxConn)

        -- ── Shadow Follow: lock bot 2.5 studs behind target every frame ───────
        local OFFSET   = 2.5   -- studs behind target
        local OFFSET_Y = 0     -- same vertical level

        local followConn = BotEnv.RunService.Heartbeat:Connect(function()
            pcall(function()
                if not BotEnv.GetFlag("IsGojoShadow") then
                    BotEnv.DisconnectSafe("GojoShadow_Follow"); return
                end

                local t = BotEnv.GetFlag("GojoTarget")
                if not t or not t.Parent then
                    BotEnv.SetFlag("IsGojoShadow", false)
                    BotEnv.DisconnectSafe("GojoShadow_Follow")
                    BotEnv.DisconnectSafe("GojoShadow_FX")
                    return
                end

                local tHRP = BotEnv.GetHRP(t)
                local bHRP = BotEnv.GetBotHRP()
                if not tHRP or not bHRP then return end

                -- Positive Z in CFrame local space = directly behind
                -- Multiply target CFrame by offset so we inherit their rotation
                local shadowCF = tHRP.CFrame * CFrame.new(0, OFFSET_Y, OFFSET)
                bHRP.CFrame = shadowCF
            end)
        end)
        BotEnv.TrackConnection("GojoShadow_Follow", followConn)

        BotEnv.Respond("🌀 DOMAIN EXPANSION — shadowing " .. target.Name .. " | ?bot auramode to stop")
    end,
}
