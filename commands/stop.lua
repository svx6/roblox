return {
    Name       = "stop",
    Category   = "system",
    Permission = 1,
    Aliases    = {
        "stopall","reset","off","halt","end","cancel","clear",
        "abort","nuke","pause","shutdown","full","killall","s",
    },

    Execute = function(BotEnv, args, executor, restArgs)

        local mode   = (args[2] or ""):lower()
        local isSoft = (mode == "soft")
        local isHard = (mode == "all" or mode == "hard" or mode == "nuke" or mode == "full")

        local safetySet = {
            NoClip=true, AntiAFK=true, AntiVoid=true,
            God=true, AutoRespawn=true, GodHealth=true,
        }

        local stoppedCount = 0

        local function trackStop(name)
            stoppedCount = stoppedCount + 1
            BotEnv.Console.Log("SYS", "killed: " .. tostring(name))
        end

        local function safeDisconnect(name)
            if safetySet[name] and not isHard then return end
            local c = BotEnv.ActiveConnections[name]
            if c == nil then return end
            pcall(function()
                if type(c) == "userdata" or (type(c) == "table" and type(c.Disconnect) == "function") then
                    c:Disconnect()
                end
            end)
            BotEnv.ActiveConnections[name] = nil
            trackStop(name)
        end

        local knownConnections = {
            "LoopFling","LoopKill","LoopFlingAll","Follow","Orbit","Attach","Annoy",
            "Fly","Spin","Stare","ESP","CoinFarm","Farm","BlackHole","Strobe","Creep",
            "Mimic","Trail","GodKnife","Tornado","Seizure","Dance","FloorFly","Aura",
            "Track","Magnet","AntiSlow","AntiFling","LoopTP","AutoShoot","AutoMurd",
            "WallBang","NoClip","AntiAFK","AntiVoid","God","GodHealth","AutoRespawn",
        }

        for _, name in ipairs(knownConnections) do
            safeDisconnect(name)
        end

        do
            local snapshot = {}
            for k, v in pairs(BotEnv.ActiveConnections) do
                snapshot[k] = v
            end
            for name, conn in pairs(snapshot) do
                if conn ~= nil and (isHard or not safetySet[name]) then
                    if BotEnv.ActiveConnections[name] ~= nil then
                        pcall(function()
                            if type(conn) == "userdata" or (type(conn) == "table" and type(conn.Disconnect) == "function") then
                                conn:Disconnect()
                            end
                        end)
                        BotEnv.ActiveConnections[name] = nil
                        trackStop(name .. "~")
                    end
                end
            end
        end

        local loopFlags = {
            "IsFlying","IsFloorFlying","IsSpinning","IsCoinFarming","IsFarming",
            "IsBlackHole","IsStrobing","IsGodKnife","IsMimicking","IsCreeping",
            "IsTrailing","IsDancing","IsAuraActive","IsTracking","IsFlingBusy",
            "IsMagnetOn","IsLoopTP","IsAutoShoot","IsAutoMurd","IsWallBang",
            "IsAntiFling","IsAntiSlow",
        }
        local safetyFlags = {
            "IsNoClip","IsGodMode","IsAntiAFK","IsAntiVoid","IsAutoRespawn",
        }
        local nilFlags = {
            "FloorFlyTarget","FloorFlyPlatform","TrackTarget","TrackLastPos",
            "LoopTPTarget","AutoShootTarget","AutoMurdTarget","SavedCFrame",
        }

        for _, f in ipairs(loopFlags)  do pcall(function() BotEnv.SetFlag(f, false) end) end
        for _, f in ipairs(nilFlags)   do pcall(function() BotEnv.SetFlag(f, nil)   end) end
        if isHard then
            for _, f in ipairs(safetyFlags) do pcall(function() BotEnv.SetFlag(f, false) end) end
        end

        pcall(function()
            local gyro = BotEnv.GetFlag("FlyBodyGyro")
            if gyro and gyro.Parent then pcall(function() gyro:Destroy() end) end
            BotEnv.SetFlag("FlyBodyGyro", nil)
        end)
        pcall(function()
            local bv = BotEnv.GetFlag("FlyBodyVelocity")
            if bv and bv.Parent then pcall(function() bv:Destroy() end) end
            BotEnv.SetFlag("FlyBodyVelocity", nil)
        end)
        pcall(function()
            local pp = BotEnv.GetFlag("PlatformPart")
            if pp and pp.Parent then pcall(function() pp:Destroy() end) end
            BotEnv.SetFlag("PlatformPart", nil)
        end)
        pcall(function()
            local ffp = BotEnv.GetFlag("FloorFlyPlatform")
            if ffp and ffp.Parent then pcall(function() ffp:Destroy() end) end
            BotEnv.SetFlag("FloorFlyPlatform", nil)
        end)

        pcall(function()
            local hrp = BotEnv.GetBotHRP()
            if not hrp then return end
            for _, obj in ipairs(hrp:GetChildren()) do
                local ok, isMover = pcall(function()
                    return obj:IsA("BodyVelocity")
                        or obj:IsA("BodyGyro")
                        or obj:IsA("BodyAngularVelocity")
                        or obj:IsA("BodyPosition")
                        or obj:IsA("BodyForce")
                        or obj:IsA("VectorForce")
                        or obj:IsA("AlignPosition")
                        or obj:IsA("AlignOrientation")
                        or obj:IsA("LinearVelocity")
                        or obj:IsA("AngularVelocity")
                        or obj:IsA("RodConstraint")
                        or obj:IsA("RopeConstraint")
                        or obj:IsA("BallSocketConstraint")
                        or obj:IsA("HingeConstraint")
                        or obj:IsA("Attachment")
                end)
                if ok and isMover then
                    pcall(function() obj:Destroy() end)
                end
            end
            pcall(function()
                hrp.AssemblyLinearVelocity  = Vector3.zero
                hrp.AssemblyAngularVelocity = Vector3.zero
            end)
        end)

        if isHard then
            task.wait()
            pcall(function()
                local char = BotEnv.LocalPlayer.Character
                if not char then return end
                for _, obj in ipairs(char:GetDescendants()) do
                    pcall(function()
                        if obj:IsA("BasePart") then obj.CanCollide = true end
                    end)
                end
            end)
        end

        pcall(function()
            local char = BotEnv.LocalPlayer.Character
            if not char then return end
            for _, obj in ipairs(char:GetDescendants()) do
                pcall(function()
                    if obj:IsA("Seat") and obj.Name == "FlingSeat" then obj:Destroy() end
                    if obj:IsA("BasePart") and (
                        obj.Name == "BotFreeze"  or obj.Name == "AuraPart" or
                        obj.Name == "TrailPart"  or obj.Name == "BotPlatform"
                    ) then obj:Destroy() end
                end)
            end
            if isHard then
                local ff = char:FindFirstChildOfClass("ForceField")
                if ff then pcall(function() ff:Destroy() end) end
            end
        end)

        pcall(function()
            local ws = BotEnv.Workspace
            if not ws then return end
            local botPartNames = {"FlingSeat","BotFreeze","AuraPart","TrailPart","BotPlatform"}
            for _, partName in ipairs(botPartNames) do
                local limit = 0
                local found = ws:FindFirstChild(partName, true)
                while found and found.Parent and limit < 200 do
                    limit = limit + 1
                    pcall(function() found:Destroy() end)
                    found = ws:FindFirstChild(partName, true)
                end
            end
        end)

        pcall(function()
            for _, part in ipairs(BotEnv.TrailParts) do
                if part and part.Parent then pcall(function() part:Destroy() end) end
            end
            BotEnv.TrailParts = {}
        end)
        pcall(function()
            for _, part in ipairs(BotEnv.AuraParts) do
                if part and part.Parent then pcall(function() part:Destroy() end) end
            end
            BotEnv.AuraParts = {}
        end)
        pcall(function()
            for _, part in ipairs(BotEnv.CageParts) do
                if part and part.Parent then pcall(function() part:Destroy() end) end
            end
            BotEnv.CageParts = {}
        end)
        pcall(function()
            local snap = {}
            for target, parts in pairs(BotEnv.FreezeCages) do snap[target] = parts end
            for _, parts in pairs(snap) do
                for _, part in ipairs(parts) do
                    if part and part.Parent then pcall(function() part:Destroy() end) end
                end
            end
            BotEnv.FreezeCages = {}
        end)
        pcall(function()
            local snap = {}
            for player, objects in pairs(BotEnv.ESPObjects) do snap[player] = objects end
            for _, objects in pairs(snap) do
                pcall(function()
                    if objects.highlight and objects.highlight.Parent then objects.highlight:Destroy() end
                    if objects.billboard and objects.billboard.Parent then objects.billboard:Destroy() end
                    if objects.nameTag   and objects.nameTag.Parent   then objects.nameTag:Destroy()   end
                    if objects.box       and objects.box.Parent       then objects.box:Destroy()       end
                end)
            end
            BotEnv.ESPObjects = {}
        end)
        pcall(function()
            for _, data in ipairs(BotEnv.XRayParts) do
                pcall(function()
                    if data.part and data.part.Parent then
                        data.part.Transparency = type(data.original) == "number" and data.original or 0
                    end
                end)
            end
            BotEnv.XRayParts = {}
        end)

        pcall(function()
            local hum = BotEnv.GetBotHumanoid()
            if not hum then return end
            hum.WalkSpeed  = 16
            hum.JumpPower  = 50
            hum.AutoRotate = true
            if isHard then
                pcall(function() hum:SetStateEnabled(Enum.HumanoidStateType.Dead, true) end)
                hum.MaxHealth = 100
                hum.Health    = 100
            end
            pcall(function() hum:ChangeState(Enum.HumanoidStateType.GettingUp) end)
        end)

        if isHard then
            pcall(function()
                local g = BotEnv.OriginalGravity
                if BotEnv.Workspace and type(g) == "number" and g > 0 then
                    BotEnv.Workspace.Gravity = g
                end
            end)
            pcall(function()
                local L  = BotEnv.Lighting
                local ol = BotEnv.OriginalLighting
                if not L or not ol then return end
                if ol.Ambient        then pcall(function() L.Ambient        = ol.Ambient        end) end
                if ol.Brightness     then pcall(function() L.Brightness     = ol.Brightness     end) end
                if ol.FogEnd         then pcall(function() L.FogEnd         = ol.FogEnd         end) end
                if ol.FogStart       then pcall(function() L.FogStart       = ol.FogStart       end) end
                if ol.ClockTime      then pcall(function() L.ClockTime      = ol.ClockTime      end) end
                if ol.OutdoorAmbient then pcall(function() L.OutdoorAmbient = ol.OutdoorAmbient end) end
            end)
            pcall(function()
                local cam = BotEnv.Workspace and BotEnv.Workspace.CurrentCamera
                if not cam then return end
                local orig = BotEnv.GetFlag("OriginalCameraSubject")
                if orig and orig.Parent then
                    cam.CameraSubject = orig
                else
                    local hum = BotEnv.GetBotHumanoid()
                    if hum then cam.CameraSubject = hum end
                end
                BotEnv.SetFlag("OriginalCameraSubject", nil)
            end)
        end

        pcall(function()
            if type(BotEnv.StopHooks) ~= "table" then return end
            for hookName, hookFn in pairs(BotEnv.StopHooks) do
                if type(hookFn) == "function" then
                    local ok, err = pcall(hookFn, isHard, isSoft)
                    if ok then
                        trackStop(tostring(hookName) .. "(hook)")
                    else
                        BotEnv.Console.Log("ERR", "StopHook fail: " .. tostring(hookName), tostring(err))
                    end
                end
            end
        end)

        pcall(function()
            if type(BotEnv.CommandRegistry) ~= "table" then return end
            for cmdName, cmdModule in pairs(BotEnv.CommandRegistry) do
                if type(cmdModule) == "table" and type(cmdModule.OnStop) == "function" then
                    local ok, err = pcall(cmdModule.OnStop, BotEnv, isHard, isSoft)
                    if ok then
                        trackStop(tostring(cmdName) .. "(OnStop)")
                    else
                        BotEnv.Console.Log("ERR", "OnStop fail: " .. tostring(cmdName), tostring(err))
                    end
                end
            end
        end)

        BotEnv.Console.Log("SYS",
            "STOP done | mode=" .. (mode == "" and "default" or mode) ..
            " | killed=" .. stoppedCount
        )

        local label = isHard and " [HARD]" or isSoft and " [SOFT]" or ""
        BotEnv.Respond("stopped everything" .. label .. " (" .. stoppedCount .. " killed)", nil, false)
    end,
}
