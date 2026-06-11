return {
    Name = "fogend", Category = "utility", Permission = 1, Aliases = {"fog", "nofog", "clearfog", "setfog"},
    Execute = function(BotEnv, args, executor, restArgs)
        local val = tonumber(args[2])
        if not val then
            pcall(function() game:GetService("Lighting").FogEnd = 1000000; game:GetService("Lighting").FogStart = 0 end)
            BotEnv.Respond("Fog cleared")
        else
            pcall(function() game:GetService("Lighting").FogEnd = val; game:GetService("Lighting").FogStart = 0 end)
            BotEnv.Respond("Fog: " .. val)
        end
    end,
}
