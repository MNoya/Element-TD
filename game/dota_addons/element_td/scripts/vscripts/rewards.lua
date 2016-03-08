if not Rewards then
    Rewards = class({})
end

function Rewards:Load()
    Rewards.players = {}

    local req = CreateHTTPRequest('GET', 'http://www.eletd.com/reward_data.js')
    
    -- Send the request
    req:Send(function(res)
        if res.StatusCode ~= 200 or not res.Body then
            print("[Rewards] Failed to contact rewards server.")
            return
        end

        -- Try to decode the result
        local obj, pos, err = json.decode(res.Body, 1, nil)

        -- Feed the result into our callback
        if err then
            print("[Rewards] Error in response : " .. err)
            return
        end

        if obj and obj.players then
            for _,v in pairs(obj.players) do
                local data = {}
                data.tier = v.reward
                if v.choice and v.choice ~= "" then
                    data.choice = v.choice
                end
                CustomNetTables:SetTableValue("rewards", v.steamID, data)
            end
        end
    end)
end