-- This exposes the stages and can be used to send custom requests to secondary locations

local hiacLB = 'http://hatinacat.com/leaderboard/'
local eleTDLB = 'http://www.eletd.com/leaderboard/'
local messageCustomComplete = 'Match custom stats were successfully recorded!'

function statCollection:Stage1(payload)

end

function statCollection:Stage2(payload)

end

function statCollection:Stage3(payload)

end

function statCollection:StageCustom(payload)
    payload.matchID = tostring(GameRules:GetMatchID())

    -- Send custom to lb
    self:sendStage('s2_custom.php', payload, function(err, res)

        -- Check if we got an error
        if self:ReturnedErrors(err, res) then
            statCollection:print("Error on sendCustom " .. eleTDLB)
            CustomNetTables:SetTableValue("gameinfo", "game_recorded", {value="failed"})
            return
        end

        -- Tell the user
        statCollection:print(messageCustomComplete .. " [" .. eleTDLB .. ']')
        CustomNetTables:SetTableValue("gameinfo", "game_recorded", {value="recorded"})
    end, eleTDLB)

    -- Send custom to lb hatinacat
    self:sendStage('s2_custom.php', payload, function(err, res)

        -- Check if we got an error
        if self:ReturnedErrors(err, res) then
            statCollection:print("Error on sendCustom " .. hiacLB)
            return
        end

        -- Tell the user
        statCollection:print(messageCustomComplete .. " [" .. hiacLB .. ']')
    end, hiacLB)
end