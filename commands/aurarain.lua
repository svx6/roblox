--[[
    Command: aurarain
    Category: aura
    Permission: 1
    Usage: ?bot aurarain
    Aliases: glowrain, aurastorm, meteoraura
    Description: Spawns a constant rain of rainbow neon orbs falling from
                 above the bot, each fading out as they hit the floor.
                 Looks like a magical meteor shower around you.
]]

return {
    Name = "aurarain",
    Category = "aura",
    Permission = 1,
    Aliases = {"glowrain", "aurastorm", "meteoraura"},
    Description = "Spawns a rainbow meteor shower of neon orbs falling around the bot",
    Execute = function(BotEnv, args, executor, restArgs)
        local isOn = BotEnv.GetFlag("IsAuraRain")

        if isOn then
            BotEnv.SetFlag("IsAuraRain", false)
            BotEnv.DisconnectSafe("AuraRain")
            if BotEnv.AuraRainParts then
                for _, p in ipairs(BotEnv.AuraRainParts) do pcall(function() p:Destroy() end) end
                BotEnv.AuraRainParts = {}
            end
            BotEnv.Respond("🌑 Aura Rain OFF")
            return
        end

        BotEnv.SetFlag("IsAuraRain", true)
        BotEnv.AuraRainParts = {}
        local ws = game:GetService("Workspace")
        local spawnTimer = 0
        local SPAWN_INTERVAL = 0.07   -- seconds between new drops
        local MAX_DROPS = 80
        local hue = 0

        local conn = BotEnv.RunService.Heartbeat:Connect(function(dt)
            pcall(function()
                if not BotEnv.GetFlag("IsAuraRain") then BotEnv.DisconnectSafe("AuraRain"); return end
                local hrp = BotEnv.GetBotHRP(); if not hrp then return end

                spawnTimer = spawnTimer + dt
                if spawnTimer < SPAWN_INTERVAL then return end
                spawnTimer = 0

                -- cap parts
                if #BotEnv.AuraRainParts > MAX_DROPS then
                    pcall(function()
                        local old = BotEnv.AuraRainParts[1]
                        if old and old.Parent then old:Destroy() end
                    end)
                    table.remove(BotEnv.AuraRainParts, 1)
                end

                -- spawn a new raindrop
                hue = (hue + 0.04) % 1
                local offX = math.random(-5, 5)
                local offZ = math.random(-5, 5)
                local startY = hrp.Position.Y + 8 + math.random(0, 4)

                local drop = Instance.new("Part")
                drop.Size        = Vector3.new(0.3, 0.5, 0.3)
                drop.Shape       = Enum.PartType.Ball
                drop.Material    = Enum.Material.Neon
                drop.CanCollide  = false
                drop.Anchored    = false   -- let physics pull it down
                drop.CastShadow  = false
                drop.Transparency = 0.15
                drop.Color        = Color3.fromHSV(hue, 1, 1)
                drop.Position     = Vector3.new(
                    hrp.Position.X + offX,
                    startY,
                    hrp.Position.Z + offZ
                )
                drop.Name         = "AuraRainDrop"
                drop.Parent       = ws
                -- give it downward velocity
                drop.AssemblyLinearVelocity = Vector3.new(
                    math.random(-2, 2),
                    -28 - math.random(0, 10),
                    math.random(-2, 2)
                )
                BotEnv.AuraRainParts[#BotEnv.AuraRainParts + 1] = drop

                -- fade and destroy after 2.5 s
                task.delay(2.5, function()
                    pcall(function()
                        for step = 1, 10 do
                            task.wait(0.15)
                            if drop and drop.Parent then
                                drop.Transparency = drop.Transparency + 0.085
                            end
                        end
                        if drop and drop.Parent then drop:Destroy() end
                    end)
                end)
            end)
        end)
        BotEnv.TrackConnection("AuraRain", conn)
        BotEnv.Respond("🌧️ Aura Rain ON — rainbow meteor shower!")
    end,
}
