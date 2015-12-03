JSON = require("util/json");
require("util/base64");

playerColors = {
    [0] = "#3375FF", [1] = "#66FFBF", [2] = "#BF00BF", [3] = "#F3F00B", [4] = "#FF6B00", --radiant
    [5] = "#FE86C2", [6] = "#FE86C2", [7] = "#65D9F7", [8] = "#008321", [9] = "#A46900"  --dire 
};

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

function dist2D(v1, v2)
    return math.sqrt(math.pow(v1.x - v2.x, 2) + math.pow(v1.y - v2.y, 2));
end

function round(num)
    return math.floor(num + 0.5);
end

-- converts a Vector object to a stringS
function vectorToS(v)
    return "["..v.x..", "..v.y..", "..v.z.."]";
end

function GetPlayer(id)
    return PlayerResource:GetPlayer(id);
end

function split(str, pat)
   local t = {}  -- NOTE: use {n = 0} in Lua-5.0
   local fpat = "(.-)" .. pat
   local last_end = 1
   local s, e, cap = str:find(fpat, 1)
   while s do
      if s ~= 1 or cap ~= "" then
     table.insert(t,cap)
      end
      last_end = e+1
      s, e, cap = str:find(fpat, last_end)
   end
   if last_end <= #str then
      cap = str:sub(last_end)
      table.insert(t, cap)
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

function ShowMessage(playerID, msg, duration)
    local messageData = {
        msg = msg,
        playerID = playerID
    };
    FireGameEvent("etd_show_message", messageData);

    Timers:CreateTimer("ShowMessage"..playerID, {
        endTime = duration,
        callback = function()
            local data = {
                msg = "",
                playerID = playerID
            };
            
            FireGameEvent("etd_show_message", data);
        end
    });
end

function ShowWarnMessage(playerID, msg)
    local messageData = {
        msg = msg,
        playerID = playerID
    };
    FireGameEvent("etd_warn_message", messageData);
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
    local level = level or 1;
    unit:AddAbility(ability);
    local ability_ent = unit:FindAbilityByName(ability)
    ability_ent:SetLevel(level);
    return ability_ent;
end

function AreaOfTriangle(a, b, c)
    local one = a.x * (b.y - c.y); -- ax(by-cy)
    local two = b.x * (c.y - a.y); -- bx(bc-ay)
    local three = c.x * (a.y - b.y); -- cx(ay-by)
    return math.abs((one + two + three) / 2);
end

function GetCreepsInArea(center, radius)
    local creeps = Entities:FindAllByClassnameWithin("npc_dota_creature", center, radius);
    for k, v in pairs(creeps) do
        if v:GetTeam() ~= DOTA_TEAM_NOTEAM then
            creeps[k] = nil;
        end
    end
    return creeps;
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