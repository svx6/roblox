return {
    Name = "esp", Category = "utility", Permission = 1, Aliases = {"unesp", "playeresp", "espon", "espoff"},
    Execute = function(BotEnv, args, executor, restArgs)
        local mode = args[2] and args[2]:lower() or nil
        local hasESP = next(BotEnv.ESPObjects) ~= nil
        local function createESP()
            for _, p in ipairs(BotEnv.Players:GetPlayers()) do
                if p ~= BotEnv.LocalPlayer and not BotEnv.ESPObjects[p] then
                    pcall(function()
                        local c = BotEnv.GetCharacter(p); if not c then return end
                        local hl = Instance.new("Highlight"); hl.Adornee = c; hl.FillTransparency = 0.7; hl.OutlineTransparency = 0; hl.FillColor = Color3.fromRGB(255, 0, 0); hl.OutlineColor = Color3.fromRGB(255, 255, 0); hl.Parent = c
                        local bb = Instance.new("BillboardGui"); bb.Adornee = c:FindFirstChild("Head") or c:FindFirstChild("HumanoidRootPart"); bb.Size = UDim2.new(0, 200, 0, 50); bb.StudsOffset = Vector3.new(0, 3, 0); bb.AlwaysOnTop = true; bb.Parent = c
                        local tl = Instance.new("TextLabel"); tl.Size = UDim2.new(1, 0, 1, 0); tl.BackgroundTransparency = 1; tl.TextColor3 = Color3.fromRGB(255, 255, 255); tl.TextStrokeTransparency = 0; tl.TextStrokeColor3 = Color3.fromRGB(0, 0, 0); tl.Font = Enum.Font.GothamBold; tl.TextScaled = true; tl.Text = p.Name; tl.Parent = bb
                        BotEnv.ESPObjects[p] = {highlight = hl, billboard = bb}
                    end)
                end
            end
            BotEnv.DisconnectSafe("ESP")
            local conn = BotEnv.RunService.Heartbeat:Connect(function()
                pcall(function()
                    for p, objs in pairs(BotEnv.ESPObjects) do
                        if not p or not p.Parent then
                            pcall(function() if objs.highlight then objs.highlight:Destroy() end; if objs.billboard then objs.billboard:Destroy() end end)
                            BotEnv.ESPObjects[p] = nil
                        else
                            local hrp = BotEnv.GetHRP(p); local bhrp = BotEnv.GetBotHRP()
                            if hrp and bhrp and objs.billboard then
                                local dist = math.floor((hrp.Position - bhrp.Position).Magnitude)
                                local hum = BotEnv.GetHumanoid(p)
                                local hp = hum and math.floor(hum.Health) or 0
                                for _, child in ipairs(objs.billboard:GetChildren()) do
                                    if child:IsA("TextLabel") then child.Text = p.Name .. " [" .. dist .. "m] HP:" .. hp end
                                end
                            end
                        end
                    end
                    for _, p in ipairs(BotEnv.Players:GetPlayers()) do
                        if p ~= BotEnv.LocalPlayer and not BotEnv.ESPObjects[p] then
                            pcall(function()
                                local c = BotEnv.GetCharacter(p); if not c then return end
                                local hl = Instance.new("Highlight"); hl.Adornee = c; hl.FillTransparency = 0.7; hl.OutlineTransparency = 0; hl.FillColor = Color3.fromRGB(255, 0, 0); hl.OutlineColor = Color3.fromRGB(255, 255, 0); hl.Parent = c
                                local bb = Instance.new("BillboardGui"); bb.Adornee = c:FindFirstChild("Head") or c:FindFirstChild("HumanoidRootPart"); bb.Size = UDim2.new(0, 200, 0, 50); bb.StudsOffset = Vector3.new(0, 3, 0); bb.AlwaysOnTop = true; bb.Parent = c
                                local tl = Instance.new("TextLabel"); tl.Size = UDim2.new(1, 0, 1, 0); tl.BackgroundTransparency = 1; tl.TextColor3 = Color3.fromRGB(255, 255, 255); tl.TextStrokeTransparency = 0; tl.TextStrokeColor3 = Color3.fromRGB(0, 0, 0); tl.Font = Enum.Font.GothamBold; tl.TextScaled = true; tl.Text = p.Name; tl.Parent = bb
                                BotEnv.ESPObjects[p] = {highlight = hl, billboard = bb}
                            end)
                        end
                    end
                end)
            end)
            BotEnv.TrackConnection("ESP", conn)
        end
        local function removeESP()
            BotEnv.DisconnectSafe("ESP")
            for p, objs in pairs(BotEnv.ESPObjects) do
                pcall(function() if objs.highlight then objs.highlight:Destroy() end; if objs.billboard then objs.billboard:Destroy() end end)
            end
            BotEnv.ESPObjects = {}
        end
        if mode == "on" or mode == "1" then createESP(); BotEnv.Respond("ESP ON")
        elseif mode == "off" or mode == "0" then removeESP(); BotEnv.Respond("ESP OFF")
        else if hasESP then removeESP(); BotEnv.Respond("ESP OFF") else createESP(); BotEnv.Respond("ESP ON") end end
    end,
}
