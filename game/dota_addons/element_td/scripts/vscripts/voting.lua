-- voting.lua
-- manages the voting that takes place at the start of the game

local gameSettingsKV = LoadKeyValues("scripts/kv/gamesettings.kv");

PLAYERS_NOT_VOTED = {};

VOTE_RESULTS = {};
VOTE_RESULTS.gamemode = {};
VOTE_RESULTS.difficulty = {};
VOTE_RESULTS.elements = {};
VOTE_RESULTS.order = {};
VOTE_RESULTS.length = {};

PLAYER_DIFFICULTY_CHOICES = {};

function StartVoteTimer()
	for _,v in pairs(players) do --add all players to the list of players that have not voted yet
		PLAYERS_NOT_VOTED[v:GetPlayerID()] = 1;
	end

	GameRules:SendCustomMessage("<font color='#70EA72'>Voting has begun!</font>", 0, 0);

	local loops = 60;
	Timers:CreateTimer("VoteThinker", {
		callback = function()
			loops = loops - 1;
			FireGameEvent("etd_update_vote_timer", {time = loops});
			if loops == 0 then
				Log:info("Vote timer ran out");
				FinalizeVotes(); --time has run out, finalize votes
				return nil;
			end
			return 1;
		end
	});
end

function GetWinningDifficulty()
	local totalWeight, totalVotes = 0, 0;
	local winner = "Normal";

	for df, votes in pairs(VOTE_RESULTS.difficulty) do
		totalWeight = totalWeight + (tonumber(gameSettingsKV.Difficulty[df].VoteWeight) * votes);
		totalVotes = totalVotes + votes;
	end

	local average = math.floor((totalWeight / totalVotes) + 0.5);

	print("Total number of votes: " .. totalVotes);
	print("Average: " .. average);

	for df, data in pairs(gameSettingsKV.Difficulty) do
		if tonumber(data.VoteWeight) == average then
			winner = df;
			break;
		end
	end

	print("Winning difficulty: " .. winner);
	return winner;
end

function AddVote(option, choice)
	if not option[choice] then
		option[choice] = 1;
	else
		option[choice] = option[choice] + 1;
	end
end

function GetWinningChoice(option)
	local winners = {};
	local highestVotes = 0;

	for k, v in pairs(option) do
		if v >= highestVotes then
			highestVotes = v;
			winner = k;
			table.insert(winners, k);
		end
	end

	return winners[math.random(#winners)];
end

-- calculate which settings won the vote
function FinalizeVotes()
	
	Log:info("All players have finished voting");
	Timers:RemoveTimer("VoteThinker");
	FireGameEvent("etd_toggle_vote_dialog", {visible = false});

	for _,v in pairs(PLAYERS_NOT_VOTED) do 
		AddVote(VOTE_RESULTS.gamemode, "Competitive");
		AddVote(VOTE_RESULTS.difficulty, "Normal");
		AddVote(VOTE_RESULTS.elements, "AllPick");
		AddVote(VOTE_RESULTS.order, "Normal");
		AddVote(VOTE_RESULTS.length, "Normal");
	end

	local gamemode = GetWinningChoice(VOTE_RESULTS.gamemode);
	local difficulty;
	if gamemode == "Competitive" or gamemode == "Extreme" then
		difficulty = GetWinningDifficulty();
		for _, ply in pairs(players) do
    		GameSettings:SetDifficulty(ply:GetPlayerID(), difficulty);
    	end
    else
		for _, ply in pairs(players) do
    		GameSettings:SetDifficulty(ply:GetPlayerID(), PLAYER_DIFFICULTY_CHOICES[ply:GetPlayerID()]);
    	end
	end
	
	local elements = GetWinningChoice(VOTE_RESULTS.elements);
	local order = GetWinningChoice(VOTE_RESULTS.order);
	local length = GetWinningChoice(VOTE_RESULTS.length);

	print("\n----------");
	print("Vote Results:");
	print("Gamemode: " .. gamemode);
	print("Elements: " .. elements);
	print("Order: " .. order);
	print("Length: " .. length);
	print("----------\n");

	GameSettings:SetCreepOrder(order);
	GameSettings:SetGameLength(length);
	GameSettings:SetElementOrder(elements);

	for k, ply in pairs(players) do 
		local data = {playerID = ply:GetPlayerID(), gamemode = gamemode, difficulty = PLAYER_DIFFICULTY_CHOICES[ply:GetPlayerID()], elements = elements, order = order, length = length};
		FireGameEvent("etd_vote_results", data);
		FireGameEvent("etd_update_wave_info", {playerID = ply:GetPlayerID(), nextWave = GameSettings:GetGameLength().Wave, nextWaveCreep = WAVE_CREEPS[GameSettings:GetGameLength().Wave]});
	end

	Log:trace("Creating post vote timer");
	Timers:CreateTimer("PostVoteTimer", {
		endTime = 1,
		callback = function()
			for _, ply in pairs(players) do
				StartBreakTime(ply:GetPlayerID(), GameSettings.length.PregameTime);
			end
		end
	});
end

-- the command that allows users to vote
-- gets called from ActionScript in vote_menu.as
Convars:RegisterCommand("etd_player_voted", (function(name, voteData)

	voteData = JSON:decode(DecodeBase64(voteData));
	local playerID = voteData.playerID;
	local playerName = GetPlayerName(playerID);

	if not PLAYERS_NOT_VOTED[playerID] then
		Log:warn(playerName .. " attempted to vote again!"); -- this should never happen
	else
		Log:info(playerName .. " has voted!");
		GameRules:SendCustomMessage("<font color='" .. playerColors[playerID] .."'>" .. playerName .. "</font> has voted!", 0, 0);
		PLAYERS_NOT_VOTED[playerID] = nil;
		PLAYER_DIFFICULTY_CHOICES[playerID] = voteData.difficultyVote;

		AddVote(VOTE_RESULTS.gamemode, voteData.gamemodeVote);
		AddVote(VOTE_RESULTS.difficulty, voteData.difficultyVote);
		AddVote(VOTE_RESULTS.elements, voteData.elementsVote);
		AddVote(VOTE_RESULTS.order, voteData.orderVote);
		AddVote(VOTE_RESULTS.length, voteData.lengthVote);

		--check to see if all players have finished voting
		local count = 0;
		for k, v in pairs(PLAYERS_NOT_VOTED) do
			count = count + 1;
		end
		if count == 0 then
			FinalizeVotes(); -- all players have finished voting
		end
	end

end), "", 0);