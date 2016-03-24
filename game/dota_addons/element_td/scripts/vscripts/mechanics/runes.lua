--[[ 
      Fire Nature 
    Water    Earth 
      Dark Light
--]]
RUNES = {
    ["water"] = { model = "models/props_gameplay/rune_doubledamage01.vmdl", animation = "rune_doubledamage_anim" },
    ["fire"] = { model = "models/props_gameplay/rune_haste01.vmdl", animation = "rune_haste_idle" },
    ["nature"] = { model = "models/props_gameplay/rune_regeneration01.vmdl", animation = "rune_regeneration_anim" },
    ["earth"] = { model = "models/props_gameplay/rune_illusion01.vmdl", animation = "rune_illusion_idle" },
    ["light"] = { model = "models/props_gameplay/rune_arcane.vmdl", animation = "rune_arcane_idle" },
    ["dark"] = { model = "models/props_gameplay/rune_invisibility01.vmdl", animation = "rune_invisibility_idle" }
}

function UpdateRunes(playerID)
    local summoner = GetPlayerData(playerID).summoner
    local origin = summoner:GetAbsOrigin()
    local angle = 360/6
    local rotate_pos = origin + Vector(1,0,0) * 70
    summoner.runes = summoner.runes or {[2]={["fire"] = {}}, [1]={["nature"] = {}}, [6]={["earth"] = {}}, [5]={["light"] = {}}, [4]={["dark"] = {}}, [3]={["water"] = {}}}

    for i=1,6 do
        for element,value in pairs(summoner.runes[i]) do
            local level = GetPlayerElementLevel(playerID, element)
            if level > 0 then
                local position = RotatePosition(origin, QAngle(0, angle*i, 0), rotate_pos)
                if not value.level then
                    summoner.runes[i][element].props = CreateRune( element, position, level )
                elseif value.level ~= level then
                    ClearRunes(summoner.runes[i][element].props)
                    summoner.runes[i][element].props = CreateRune( element, position, level )
                end
                summoner.runes[i][element].level = level
            end
        end
    end
end

function CreateRune( element, position, level )
    local angle = 360/level
    local distance = level == 1 and 0 or 20
    local rotate_pos = position + Vector(1,0,0) * distance
    local props = {}

    for i=1,level do
        local rune = SpawnEntityFromTableSynchronous("prop_dynamic", {model = RUNES[element].model, DefaultAnim = RUNES[element].animation})
        local pos = RotatePosition(position, QAngle(0, angle*(i-1), 0), rotate_pos)
        rune:SetModelScale(1-level*0.1)
        rune:SetAbsOrigin(pos)

        table.insert(props, rune)
    end

    return props
end

function ClearRunes( propsTable )
    for k,v in pairs(propsTable) do
        v:RemoveSelf()
    end
end

function ClearAllRunes( summoner )
    for _,v1 in pairs(summoner.runes) do
         for _,v2 in pairs(v1) do
             for key,runes in pairs(v2) do
                if key=="props" then
                    ClearRunes(runes)
                end
             end
         end
     end
     summoner.runes = {[2]={["fire"] = {}}, [1]={["nature"] = {}}, [6]={["earth"] = {}}, [5]={["light"] = {}}, [4]={["dark"] = {}}, [3]={["water"] = {}}}
end