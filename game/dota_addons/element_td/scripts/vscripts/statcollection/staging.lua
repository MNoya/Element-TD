-- This exposes the stages and can be used to send custom requests to secondary locations

local hiacLB = 'http://hatinacat.com/leaderboard/'
local eleTDLB = 'http://www.eletd.com/leaderboard/'
local messageCustomComplete = 'Match custom stats were successfully recorded!'
local messageCustomFailed = 'Match custom stats could not be recorded.'
local gameRecordedTimeout = 20

local function UpdateGameRecorded(state, message, style)
    CustomNetTables:SetTableValue("gameinfo", "game_recorded", {
        value = state,
        message = message
    })
    CustomGameEventManager:Send_ServerToAllClients("etd_game_recorded", {
        value = state,
        message = message
    })

    if message and Notifications and Notifications.BottomToAll then
        Notifications:BottomToAll({
            text = message,
            duration = 8,
            style = style
        })
    end
end

function statCollection:Stage1(payload)

end

function statCollection:Stage2(payload)

end

function statCollection:Stage3(payload)

end

function statCollection:StageCustom(payload)
    payload.matchID = tostring(GameRules:Script_GetMatchID())
    local timeoutMessage = 'Match recording timed out after ' .. gameRecordedTimeout .. ' seconds.'
    local requestFinished = false
    local requestTimedOut = false

    Timers:CreateTimer(gameRecordedTimeout, function()
        if requestFinished then
            return
        end

        requestTimedOut = true
        statCollection:print(timeoutMessage .. " [" .. hiacLB .. ']')
        UpdateGameRecorded("failed", timeoutMessage, { color = "#FF6666" })
    end)

    -- Send custom to lb hatinacat
    self:sendStage('s2_custom.php', payload, function(err, res)
        if requestFinished then
            return
        end
        requestFinished = true

        -- Check if we got an error
        if self:ReturnedErrors(err, res) then
            statCollection:print("Error on sendCustom " .. hiacLB)
            if not requestTimedOut then
                UpdateGameRecorded("failed", messageCustomFailed, { color = "#FF6666" })
            end
            return
        end

        -- Tell the user
        statCollection:print(messageCustomComplete .. " [" .. hiacLB .. ']')
        UpdateGameRecorded("recorded")
    end, hiacLB)

    Saves:SavePasses()
end
