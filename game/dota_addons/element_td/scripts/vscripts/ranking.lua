-- ranking.lua
-- managers the fetching and displaying of player ranks
if not Ranking then
	Ranking = {}
	Ranking.__index = Ranking

	RANKING_OBJECTS = {}
end

RankingObject = createClass({
		constructor = function( self, playerID, steamID )
			self.playerID = playerID
			self.steamID = steamID
			self.rank = 0
			self.percentile = 0
			self.leaderboard = 0
			self.sector = GetPlayerData(playerID).sector
		end
	},
{}, nil)

RANKING_URL = "http://hatinacat.com/leaderboard/data_request.php"

-- Generates list of ingame players and fetches their rankings
function requestInGamePlayerRanks( leaderboard )
	leaderboard = leaderboard or 0
	steamIDs = {}
	for k, ply in pairs(playerIDs) do
		steamID = PlayerResource:GetSteamAccountID(ply)
		RANKING_OBJECTS[ply] = RankingObject(ply, steamID)
		table.insert(steamIDs, steamID)
	end

	-- For testing
	local request = RANKING_URL .. "?req=player&ids=" .. table.concat(steamIDs, ",") .. "&lb=" .. leaderboard 
	print('[Ranks] ' .. request)

	-- Generate URL
	local req = CreateHTTPRequest('GET', RANKING_URL)

	-- Add the data
	req:SetHTTPRequestGetOrPostParameter('req', "player")
	req:SetHTTPRequestGetOrPostParameter('ids', table.concat(steamIDs, ","))
	req:SetHTTPRequestGetOrPostParameter('lb', tostring(leaderboard))  


	callback = function(err, res)
		if err then
			print("[Ranks] Error in response : " .. err)
			return
		end

		PrintTable(res)

		if res.result == 1 then
			print("[Ranks] Retrieved player rankings!")
			for i, player in pairs(res.players) do
				local playerID = steamIDToPlayerID(player.steamID)
				if playerID ~= -1 then
					ranking = RANKING_OBJECTS[playerID]
					ranking.rank = player.rank
					ranking.percentile = player.percentile
					ranking.leaderboard = player.leaderboard
				end
			end
			DisplayPlayerRanks()
		else
			print("[Ranks] Malformed request")
		end
	end

	-- Send the request
	req:Send(function(res)
		if res.StatusCode ~= 200 or not res.Body then
			print("[Ranks] Failed to contact ranking server.")
			return
		end

		-- Try to decode the result
		local obj, pos, err = json.decode(res.Body, 1, nil)

		-- Feed the result into our callback
		callback(err, obj)
	end)
end

function steamIDToPlayerID( steamID )
	for i,v in pairs(RANKING_OBJECTS) do
		if tostring(v.steamID) == tostring(steamID) then
			return v.playerID
		end
	end
	return -1
end

function DisplayPlayerRanks()
	print("[Ranks] Displaying Ranks")
	PrintTable(RANKING_OBJECTS)
	CustomGameEventManager:Send_ServerToAllClients( "etd_display_ranks", { data = RANKING_OBJECTS } )
end

function ShowPlayerRanks( toggle )
	CustomGameEventManager:Send_ServerToAllClients( "etd_show_ranks", { toggle = toggle } )
end

----------------------------------------------------
