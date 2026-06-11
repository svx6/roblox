return {
    Name = "highlight", Category = "utility", Permission = 1, Aliases = {"hl", "unhighlight", "unhl", "glow"},
    Execute = function(BotEnv, args, executor, restArgs)
        if not args[2] then BotEnv.RespondError("Usage: highlight <player>"); return end
        local targets = BotEnv.GetMultipleTargets(args[2], executor, true)
        if #targets == 0 then BotEnv.RespondError("Player not found"); return end
        for _, t in ipairs(targets) do
            local c = BotEnv.GetCharacter(t); if not c then BotEnv.RespondError(t.Name .. " no character"); return end
            local existing = c:FindFirstChildOfClass("Highlight")
            if existing then existing:Destroy(); BotEnv.Respond("Unhighlighted " .. t.Name)
            else
                local col = args[3] and args[3]:lower() or "red"
                local colors = {red=Color3.fromRGB(255,0,0),blue=Color3.fromRGB(0,100,255),green=Color3.fromRGB(0,255,0),yellow=Color3.fromRGB(255,255,0),purple=Color3.fromRGB(180,0,255),pink=Color3.fromRGB(255,100,200),white=Color3.fromRGB(255,255,255),orange=Color3.fromRGB(255,150,0),cyan=Color3.fromRGB(0,255,255)}
                local hl = Instance.new("Highlight"); hl.Adornee = c; hl.FillTransparency = 0.5; hl.OutlineTransparency = 0; hl.FillColor = colors[col] or Color3.fromRGB(255,0,0); hl.OutlineColor = Color3.fromRGB(255,255,255); hl.Parent = c
                BotEnv.Respond("Highlighted " .. t.Name .. " (" .. col .. ")")
            end
        end
    end,
}
