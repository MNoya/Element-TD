function GrowModel( event )
    local caster = event.caster
    local ability = event.ability
    local level = tostring(event.Level)

    Timers:CreateTimer(function() 
        local model = caster:FirstMoveChild()
        while model ~= nil do
            if model:GetClassname() == "dota_item_wearable" then
                if not string.match(model:GetModelName(), "tree") then
                    local new_model_name = string.gsub(model:GetModelName(),"1",level)
                    model:SetModel(new_model_name)
                end
            end
            model = model:NextMovePeer()
        end
    end)
end
