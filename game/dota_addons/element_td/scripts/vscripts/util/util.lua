JSON = require("util/json")
require("util/base64")

playerColors = {
    [0] = "#65D413",
    [1] = "#FF6C00",
    [2] = "#C54DA8",
    [3] = "#8C2AF4",
    [4] = "#006400",
    [5] = "#ADD8E6",
    [6] = "#F3C909",
    [7] = "#FF3455",
}

defeatAnnouncer = {
    [0] = "announcer_ann_custom_defeated_06", -- Blue
    [1] = "announcer_ann_custom_defeated_01", -- Teal
    [2] = "announcer_ann_custom_defeated_05", -- Purple
    [3] = "announcer_ann_custom_defeated_02", -- Yellow
    [4] = "announcer_ann_custom_defeated_04", -- Orange
    [5] = "announcer_ann_custom_defeated_03", -- Pink
    [6] = "announcer_ann_custom_defeated_07", -- Olive
    [7] = "announcer_ann_custom_defeated_09", -- Cyan
    [8] = "announcer_ann_custom_defeated_10", -- Green
    [9] = "announcer_ann_custom_defeated_08", -- Brown
    [10] = "announcer_ann_custom_defeated_11", -- Grey
    [11] = "announcer_ann_custom_defeated_12", -- Silver
    [12] = "announcer_ann_custom_defeated_13", -- Red
}

-- PLAYER COLORS
m_TeamColors = {}
m_TeamColors[DOTA_TEAM_GOODGUYS] = { 101, 212, 19 }  --  Green (Summer) #65D413
m_TeamColors[DOTA_TEAM_BADGUYS] = { 255, 108, 0 }   --  Orange (Autumn) #FF6C00
m_TeamColors[DOTA_TEAM_CUSTOM_1] = { 197, 77, 168 }  --  Pink (Temple) #C54DA8
m_TeamColors[DOTA_TEAM_CUSTOM_2] = { 140, 42, 244 }  --  Purple (Mines) #8C2AF4
m_TeamColors[DOTA_TEAM_CUSTOM_3] = { 0, 100, 0 } -- Dark Green (Ruins) #006400
m_TeamColors[DOTA_TEAM_CUSTOM_4] = { 173, 216, 230 } --  Light Blue (Winter) #ADD8E6
m_TeamColors[DOTA_TEAM_CUSTOM_5] = { 243, 201, 9 }   --  Yellow (Desert) #F3C909
m_TeamColors[DOTA_TEAM_CUSTOM_6] = { 255, 52, 85 }   --  Red (Lava) #FF3455

PlayerColors = {}
PlayerColors[0] = { 101, 212, 19 }  --  Green #65D413
PlayerColors[1] = { 1, 162, 255}    --  Blue #01A2FF
PlayerColors[2] = { 243, 201, 9 }   --  Yellow #F3C909
PlayerColors[3] = { 255, 52, 85 }   --  Red #FF3455

sectorNames = {}
sectorNames[-1] = "None"
sectorNames[0] = "Summer"
sectorNames[1] = "Autumn"
sectorNames[2] = "Temple"
sectorNames[3] = "Mines"
sectorNames[4] = "Ruins"
sectorNames[5] = "Winter"
sectorNames[6] = "Desert"
sectorNames[7] = "Lava"

function PrintTable(t, indent, done)
    if type(t) ~= "table" then return end

    done = done or {}
    done[t] = true
    indent = indent or 0

    local l = {}
    for k, v in pairs(t) do
        table.insert(l, k)
    end

    table.sort(l)
    for k, v in ipairs(l) do
        local value = t[v]

        if type(value) == "table" and not done[value] then
            done [value] = true
            print(string.rep ("   ", indent)..v..":")
            PrintTable (value, indent + 2, done)
        elseif type(value) == "userdata" and not done[value] then
            done [value] = true
            print(string.rep ("   ", indent)..v..":")
            local v = getmetatable(value);
            if v  then
                PrintTable(v.__index or v, indent + 2, done)
            end
        else
            print(string.rep ("   ", indent)..tostring(v)..": "..tostring(value))
        end
    end
end

function tablelength(T)
  local count = 0
  for _ in pairs(T) do count = count + 1 end
  return count
end

function tableconcat(T, c)
    local s = ""
    for _,v in pairs(T) do 
        if s ~= "" then
            s = s..c..v
        else
            s = v
        end
    end
    return s
end

function round(num)
    return math.floor(num + 0.5);
end

-- converts a Vector object to a string
function vectorToS(v)
    return "["..v.x..", "..v.y..", "..v.z.."]";
end

function GetPlayer(id)
    return PlayerResource:GetPlayer(id);
end

function split(inputstr, sep)
    if sep == nil then
            sep = "%s"
    end
    local t={} ; i=1
    for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
            t[i] = str
            i = i + 1
    end
    return t
end

--randomly orders a table with numeric indices
function shuffle(array)
    math.randomseed(Time());
    local length, new, old = #array, {}, {};
    for k, v in pairs(array) do table.insert(old, v); end
    for i = 1, length, 1 do
        local newLength = #old;
        local ind = math.random(newLength);
        local obj = old[ind];
        table.remove(old, ind);
        table.insert(new, obj);
    end
    return new;
end

function RandomPositionInCircle(origin, radius)
    local hyp = math.random(1, radius);
    local angle = math.random(0, 360);
    local refAngle;

    if angle <= 90 then refAngle = angle; 
    elseif angle > 90 and angle <= 180 then refAngle = 180 - angle; 
    elseif angle > 180 and angle <= 270 then refAngle = angle - 180; 
    elseif angle > 270 then refAngle = 360 - angle; end

    local topAngle = 90 - refAngle;
    local xLength = (math.sin(math.rad(topAngle)) * hyp) / math.sin(math.rad(90));
    xLength = math.floor(xLength + 0.5);
    if angle > 90 and angle < 270 then xLength = -xLength; end

    local yLength = math.sqrt((hyp ^ 2) - (xLength ^ 2));
    yLength = math.floor(yLength + 0.5);
    if angle > 180 then yLength = -yLength; end

    return Vector(origin.x + xLength, origin.y + yLength, origin.z);
end

function AddAbility(unit, ability, level)
    local level = level or 1
    local ability_ent = unit:AddAbility(ability)
    ability_ent:SetLevel(level)
    return ability_ent
end

function GetCreepsInArea(center, radius)
    local creeps = FindUnitsInRadius(0, center, nil, radius, 
                        DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_INVULNERABLE, FIND_ANY_ORDER, false)
    for k, v in pairs(creeps) do
        if v:GetTeam() ~= DOTA_TEAM_NEUTRALS then
            creeps[k] = nil;
        end
    end
    return creeps;
end

function IsValidAlive( entity )
    return IsValidEntity(entity) and entity:IsAlive()
end

function DrawTowerRangeIndicator(keys)
    local target = keys.target;
    if IsTower(target) then
        local pos = target:GetAbsOrigin();
        pos.z = pos.z + 64;
        DebugDrawCircle(pos, Vector(0, 175, 17), 1, target:GetAttackRange(), false, 10);
        DebugDrawText(target:GetOrigin(), "Range: " .. target:GetAttackRange(), true, 10);
    end
end

-- Takes a vector
function rgbToHex(vColor)
    local hexadecimal = '#'
    local rgb = {vColor.x, vColor.y, vColor.z}

    for key, value in pairs(rgb) do
        local hex = ''

        while(value > 0)do
            local index = math.fmod(value, 16) + 1
            value = math.floor(value / 16)
            hex = string.sub('0123456789ABCDEF', index, index) .. hex           
        end

        if(string.len(hex) == 0)then
            hex = '00'

        elseif(string.len(hex) == 1)then
            hex = '0' .. hex
        end

        hexadecimal = hexadecimal .. hex
    end

    return hexadecimal
end

function firstToUpper(str)
    return (str:gsub("^%l", string.upper))
end

function tableContains(list, element)
    if list == nil then return false end
    for i=1,#list do
        if list[i] == element then
            return true
        end
    end
    return false
end