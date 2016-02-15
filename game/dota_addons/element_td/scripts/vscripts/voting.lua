-- voting.lua
-- manages the voting that takes place at the start of the game

local gameSettingsKV = LoadKeyValues("scripts/kv/gamesettings.kv")

if not PLAYERS_NOT_VOTED then

	PLAYERS_NOT_VOTED = {}

	VOTE_RESULTS = {}
	VOTE_RESULTS.gamemode = {}
	VOTE_RESULTS.difficulty = {}
	VOTE_RESULTS.elements = {}
	VOTE_RESULTS.endless = {}
	VOTE_RESULTS.order = {}
	VOTE_RESULTS.length = {}

	PLAYER_DIFFICULTY_CHOICES = {}
	PLAYER_RANDOM_CHOICES = {}
end

function StartVoteTimer()
	for _,v in pairs(players) do --add all players to the list of players that have not voted yet
		PLAYERS_NOT_VOTED[v:GetPlayerID()] = 1
	end

	CustomGameEventManager:Send_ServerToAllClients("etd_populate_vote_table", gameSettingsKV )

	GameRules:SendCustomMessage("#etd_voting", 0, 0)

	local loops = 60
	Timers:CreateTimer("VoteThinker", {
		callback = function()
			loops = loops - 1
			CustomGameEventManager:Send_ServerToAllClients("etd_update_vote_timer", { time = loops } )
			if loops == 30 then
				EmitAnnouncerSound("announcer_ann_custom_timer_sec_30")
			elseif loops == 5 then
				EmitAnnouncerSound("announcer_ann_custom_timer_sec_05")
			elseif loops == 0 then
				Log:info("Vote timer ran out")
				FinalizeVotes() --time has run out, finalize votes
				return nil
			end
			return 1
		end
	})
end

function GetWinningDifficulty()
	local totalWeight, totalVotes = 0, 0
	local winner = "Normal"

	for df, votes in pairs(VOTE_RESULTS.difficulty) do
		totalWeight = totalWeight + (tonumber(gameSettingsKV.Difficulty[df].VoteWeight) * votes)
		totalVotes = totalVotes + votes
	end

	local average = round(totalWeight / totalVotes)

	print("Total number of votes: " .. totalVotes)
	print("Average: " .. average)

	for df, data in pairs(gameSettingsKV.Difficulty) do
		if tonumber(data.VoteWeight) == average then
			winner = df
			break
		end
	end

	print("Winning difficulty: " .. winner)
	return winner
end

function AddVote(option, choice)
	if not option[choice] then
		option[choice] = 1
	else
		option[choice] = option[choice] + 1
	end
end

function GetWinningChoice(option)
	local highestVotes = 0

	for k, v in pairs(option) do
		if v > highestVotes then
			highestVotes = v
			winner = k
		end
	end

	return winner
end

-- Index to String from gamesettings.kv
function GetVotingString(index, sub)
	local settable = gameSettingsKV[sub]
	for k,v in pairs(settable) do
		if v['Index'] == index then
			return k
		end
	end
end

-- calculate which settings won the vote
function FinalizeVotes()
	Log:info("All players have finished voting")
	Timers:RemoveTimer("VoteThinker")
	CustomGameEventManager:Send_ServerToAllClients( "etd_toggle_vote_dialog", {visible = false} )

	for _,v in pairs(PLAYERS_NOT_VOTED) do 
		AddVote(VOTE_RESULTS.gamemode, "Competitive")
		AddVote(VOTE_RESULTS.difficulty, "Normal")
		AddVote(VOTE_RESULTS.elements, "AllPick")
		AddVote(VOTE_RESULTS.endless, "Normal")
		AddVote(VOTE_RESULTS.order, "Normal")
		AddVote(VOTE_RESULTS.length, "Normal")
	end

	local gamemode = GetWinningChoice(VOTE_RESULTS.gamemode)
	GameSettings:SetGamemode(gamemode)

	local difficulty
	if gamemode == "Competitive" then
		difficulty = GetWinningDifficulty()
		for _, plyID in pairs(playerIDs) do
    		GameSettings:SetDifficulty(plyID, difficulty)
    	end
    else
    	-- Each player in their own difficulty
		for _, plyID in pairs(playerIDs) do
   			GameSettings:SetDifficulty(plyID, PLAYER_DIFFICULTY_CHOICES[plyID])
    	end
	end
	
	local elements = GetWinningChoice(VOTE_RESULTS.elements)
	local endless = GetWinningChoice(VOTE_RESULTS.endless)
	local order = GetWinningChoice(VOTE_RESULTS.order)
	local length = GetWinningChoice(VOTE_RESULTS.length)

	statCollection:setFlags({Difficulty = difficulty})
	statCollection:setFlags({Elements = elements})
	statCollection:setFlags({Endless = endless})
	statCollection:setFlags({Order = order})
	statCollection:setFlags({Length = length})
	statCollection:sendStage2()

	print("\n----------")
	print("Vote Results:")
	print("Gamemode: " .. gamemode)
	print("Elements: " .. elements)
	print("Endless: " .. endless)
	print("Order: " .. order)
	print("Length: " .. length)
	print("----------\n")

	GameSettings:SetGameLength(length)
	GameSettings:SetEndless(endless)
	GameSettings:SetCreepOrder(order)
	GameSettings:SetElementOrder(elements)

	-- If the Random vote didn't win, apply Random to every player that selected it anyway. 
	-- They are also able to do this by typing -random before picking an element
	if elements == "AllPick" then
		for _, playerID in pairs(playerIDs) do
			if PLAYER_RANDOM_CHOICES[playerID] == 1 then
				GameSettings:EnableRandomForPlayer(playerID)
			end
		end
	end	

	for k, plyID in pairs(playerIDs) do
		local data = {playerID = plyID, gamemode = gamemode, difficulty = GetPlayerData(plyID).difficulty.difficultyName, elements = elements, endless = endless, order = order, length = length}
		local ply = PlayerResource:GetPlayer(plyID)
		if ply then
			CustomGameEventManager:Send_ServerToPlayer( ply, "etd_vote_results", data )
			CustomGameEventManager:Send_ServerToPlayer( ply, "etd_next_wave_info", { nextWave = GameSettings:GetGameLength().Wave, nextAbility1 = creepsKV[WAVE_CREEPS[GameSettings:GetGameLength().Wave]].Ability1, nextAbility2 = creepsKV[WAVE_CREEPS[GameSettings:GetGameLength().Wave]].Ability2 } )
		end
	end

	Log:trace("Creating post vote timer")
	Timers:CreateTimer("PostVoteTimer", {
		endTime = 1,
		callback = function()
		    START_GAME_TIME = GameRules:GetGameTime()
			for _, plyID in pairs(playerIDs) do
				StartBreakTime(plyID, GameSettings.length.PregameTime)
				EmitAnnouncerSound("announcer_announcer_count_battle_30")
			end
		end
	})
end

function ElementTD:OnPlayerVoted( table )
	--voteData = JSON:decode(DecodeBase64(voteData))
	local playerID = tonumber(table.PlayerID)
	local playerName = GetPlayerName(playerID)

	if not PLAYERS_NOT_VOTED[playerID] then
		Log:warn(playerName .. " attempted to vote again!") -- this should never happen
	else
		Log:info(playerName .. " has voted!")
		GameRules:SendCustomMessage("<font color='" .. playerColors[playerID] .."'>" .. playerName .. "</font> has voted!", 0, 0)
		PLAYERS_NOT_VOTED[playerID] = nil
		PLAYER_DIFFICULTY_CHOICES[playerID] = table.data.difficultyVote
		PLAYER_RANDOM_CHOICES[playerID] = table.data.elementsVote

		local difficultyVote = table.data.difficultyVote -- 0 to 3
		local randomVote = table.data.elementsVote -- 0 or 1 if Random was selected
		local endlessVote = table.data.endlessVote -- 0 or 1 if Endless was selected
		local orderVote = table.data.orderVote -- 0 or 1 if Chaos was selected
		local expressVote = table.data.lengthVote -- 0 or 1 if Express was selected

		-- Convert to strings on gamesettings
		local difficultyString = GetVotingString(difficultyVote, "Difficulty")
		local randomString = GetVotingString(randomVote, "ElementModes")
		local endlessString = GetVotingString(endlessVote, "HordeMode")
		local orderString = GetVotingString(orderVote, "CreepOrder")
		local expressString = GetVotingString(expressVote, "GameLength")

		AddVote(VOTE_RESULTS.gamemode, "Competitive") -- Always Competitive
		AddVote(VOTE_RESULTS.difficulty, difficultyString)
		AddVote(VOTE_RESULTS.elements, randomString)
		AddVote(VOTE_RESULTS.endless, endlessString)
		AddVote(VOTE_RESULTS.order, orderString)
		AddVote(VOTE_RESULTS.length, expressString)

		local data = {playerID = playerID, difficulty = difficultyString, elements = randomString, endless = endlessString, order = orderString, length = expressString}
		CustomGameEventManager:Send_ServerToAllClients( "etd_vote_display", data )

		--check to see if all players have finished voting
		local count = 0
		for k, v in pairs(PLAYERS_NOT_VOTED) do
			count = count + 1
		end
		if count == 0 then
			FinalizeVotes() -- all players have finished voting
		end
	end
end
