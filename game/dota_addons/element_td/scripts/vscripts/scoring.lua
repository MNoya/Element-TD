-- scoring.lua
-- manages custom games scoring such as wave clearing, bonus and total score
if not Scoring then
	Scoring = {}
	Scoring.__index = Scoring

	SCORING_OBJECTS = {}
end

ScoringObject = createClass({
		constructor = function( self, playerID )
			self.playerID = playerID
			self.totalScore = 0
			self.cleanWaves = 0
			self.under30 = 0
			self.cleanWavesStreak = 0
			self.under30Streak = 0
		end
	},
{}, nil)

SCORING_WAVE_CLEAR = 0
SCORING_WAVE_LOST = 1
SCORING_GAME_CLEAR = 2 
SCORING_BOSS_WAVE_CLEAR = 3
SCORING_GAME_FINISHED = 4

function ScoringObject:UpdateScore( const , wave )
	local scoreTable = {}
	local processed = {}
	local playerData = GetPlayerData(self.playerID)
	wave = wave or playerData.completedWaves

	if ( const == SCORING_WAVE_CLEAR ) then
		scoreTable = self:GetWaveCleared( wave )
		table.insert(processed, {'Wave ' .. wave .. ' cleared!', '#FFF0F5'} )
	elseif ( const == SCORING_WAVE_LOST ) then
		scoreTable = self:GetWaveLost()
		table.insert(processed, {'Game over! Lost on wave ' .. playerData.completedWaves + 1, '#FFF0F5'} )

	-- Completed wave 55/30, waiting for boss wave (not in express)
	elseif ( const == SCORING_GAME_CLEAR ) then
		scoreTable = self:GetGameCleared()
		if EXPRESS_MODE then
			table.insert(processed, {'#scoring_game_completed', '#FFF0F5'} )
		else
			table.insert(processed, {'#scoring_game_clear', '#FFF0F5'} )
		end

	-- Finished at least 1 boss wave, waiting for the next
	elseif (const == SCORING_BOSS_WAVE_CLEAR ) then
		local bossWaveCleared = playerData.bossWaves - 1
		scoreTable = self:GetBossWaveCleared( bossWaveCleared, true) -- Get boss score
		table.insert(processed, {'Boss Wave '..bossWaveCleared..' cleared!', '#FFF0F5'} )
		table.insert(processed, {'&nbsp;&nbsp;&nbsp;&nbsp;Boss Wave ' .. bossWaveCleared .. ' bonus: ' .. comma_value(scoreTable['frogBonus']), '#00FFFF'} )
	
	-- Final message (not in express)
	elseif ( const == SCORING_GAME_FINISHED ) then
		scoreTable = self:GetGameCleared()

		table.insert(processed, {'#scoring_game_completed', '#FFF0F5'} )
	else
		return false
	end

	if scoreTable['frogKills'] and scoreTable['frogKills'] > 0 then
		table.insert(processed, {'&nbsp;&nbsp;&nbsp;&nbsp;'..scoreTable['frogKills']..' Frogs killed!', '#01A2FF'} )
	end

	-- Process Score Table keeping ordering below
	if scoreTable['clearBonus'] then
		table.insert(processed, {'&nbsp;&nbsp;&nbsp;&nbsp;Wave ' .. wave .. ' clear bonus: ' .. comma_value(scoreTable['clearBonus']), '#00FFFF'} )
	end
	if scoreTable['cleanBonus'] then
		if scoreTable['cleanBonus'] ~= 0 then
			table.insert(processed, {'&nbsp;&nbsp;&nbsp;&nbsp;Clean bonus: ' .. GetPctString(scoreTable['cleanBonus']), '#00FF00'} )
		else
			table.insert(processed, {'&nbsp;&nbsp;&nbsp;&nbsp;'..playerData.waveObjects[wave].leaks .. ' Lives lost', '#FF0000'} )
		end
	end
	if scoreTable['speedBonus'] then
		local speedColor = '#FFFF00'
		if scoreTable['speedBonus'] < 0 then
			speedColor = '#FF0000'
		end
		table.insert(processed, {'&nbsp;&nbsp;&nbsp;&nbsp;Speed bonus: ' .. GetPctString(scoreTable['speedBonus']), speedColor} )
	end
	if scoreTable['cleanWaves'] then
		table.insert(processed, {'&nbsp;&nbsp;&nbsp;&nbsp;Clean waves: ' .. scoreTable['cleanWaves'], '#00FFFF'})
	end
	if scoreTable['under30'] then
		table.insert(processed, {'&nbsp;&nbsp;&nbsp;&nbsp;Under 30 waves: ' .. scoreTable['under30'], '#FFFF00'} )
	end
	if scoreTable['networthBonus'] and EXPRESS_MODE then
		table.insert(processed, {'&nbsp;&nbsp;&nbsp;&nbsp;Networth bonus: '.. GetPctString(scoreTable['networthBonus']), '#00FFFF'} )
	end
	--[[if scoreTable['bossBonus'] and scoreTable['bossBonus'] > 0 and not EXPRESS_MODE then
		table.insert(processed, {'&nbsp;&nbsp;&nbsp;&nbsp;Boss bonus: '.. GetPctString(scoreTable['bossBonus']), '#33CC33' })
	end]]
	if scoreTable['difficultyBonus'] then
		local diffColor = '#00FF00'
		if scoreTable['difficultyBonus'] == 1 then
			diffColor = '#C0C0C0' --Hard: Silver/Grey
		elseif scoreTable['difficultyBonus'] == 2 then
			diffColor = '#FFA500' --Very Hard: Gold/Orange
		elseif scoreTable['difficultyBonus'] == 3 then
			diffColor = '#FF0000' --Insane: Red
		end
		if (scoreTable['difficultyBonus'] ~= 0) or const == SCORING_GAME_CLEAR or const == SCORING_GAME_FINISHED then
			table.insert(processed, {'&nbsp;&nbsp;&nbsp;&nbsp;'..GetPlayerDifficulty( self.playerID ).difficultyName .. ' difficulty: '.. GetPctString(scoreTable['difficultyBonus']), diffColor } )
		end
	end
	if scoreTable['chaosBonus'] and scoreTable['chaosBonus'] ~= 0 then
		table.insert(processed, {'&nbsp;&nbsp;&nbsp;&nbsp;Chaos bonus: '.. GetPctString(scoreTable['chaosBonus']), '#FF00FF' } )
	end
	if scoreTable['endlessBonus'] and scoreTable['endlessBonus'] ~= 0 then
		table.insert(processed, {'&nbsp;&nbsp;&nbsp;&nbsp;Rush bonus: '.. GetPctString(scoreTable['endlessBonus']), '#D4880F' } )
	end
	if scoreTable['totalScore'] then
		table.insert(processed, {'&nbsp;&nbsp;&nbsp;&nbsp;Total score: ' .. comma_value(scoreTable['totalScore']), '#FF8C00'})
		if const == SCORING_WAVE_LOST or const == SCORING_GAME_CLEAR or const == SCORING_GAME_FINISHED then
			self.totalScore = scoreTable['totalScore']
		else
			self.totalScore = self.totalScore + scoreTable['totalScore']
		end
		print("Score updated for player [" .. self.playerID .. "] : " .. self.totalScore)
	end
	--PrintTable(processed)

	if (const == SCORING_GAME_BOSS_CLEAR) then -- Delay Screen
		Timers:CreateTimer(1.2, function()
		self:ShowScore(processed)
			CustomGameEventManager:Send_ServerToAllClients("SetTopBarPlayerScore", {playerId=self.playerID, score=comma_value( self.totalScore )} )
			CustomGameEventManager:Send_ServerToPlayer( PlayerResource:GetPlayer(self.playerID), "etd_update_score", { score = comma_value( self.totalScore ) } )			
		end)
	else
		self:ShowScore(processed)
		CustomGameEventManager:Send_ServerToAllClients("SetTopBarPlayerScore", {playerId=self.playerID, score=comma_value( self.totalScore )} )
		CustomGameEventManager:Send_ServerToPlayer( PlayerResource:GetPlayer(self.playerID), "etd_update_score", { score = comma_value( self.totalScore ) } )
	end
	return true
end

function ScoringObject:ShowScore( table )
	local delay = 0.0
	for i,v in pairs(table) do
		Timers:CreateTimer(delay, function()
			if i == 1 then
				self:Display({text=v[1], style={color=v[2], ['font-size']="22px"}, duration=10.2-(0.2*(i-1))})
			else
				self:Display({text=v[1], style={color=v[2]}, duration=10.2-(0.2*(i-1))})
			end
		end)
		delay = delay + 0.2
	end
	Timers:CreateTimer(10, function()
		self:ClearDisplay()
	end)
end

-- Displays the score using the panorama ui
function ScoringObject:Display( table )
	local player = PlayerResource:GetPlayer(self.playerID)
	CustomGameEventManager:Send_ServerToPlayer(player, "scoring_notification", {text=table.text, duration=table.duration, class=table.class, style=table.style, continue=table.continue} )
end

function ScoringObject:ClearDisplay()
	local player = PlayerResource:GetPlayer(self.playerID)
	local count = 50
	CustomGameEventManager:Send_ServerToPlayer(player, "scoring_remove_notification", {count=count} )
end

function GetPctString( number )
	local percent = round(number * 100)
	local processed = percent
	if percent >= 0 then
		processed = '+' .. percent
	end
	return processed .. '%'
end

-- Adds thousands comma to number
function comma_value( number )
	local formatted = number
	while true do  
		formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
		if (k==0) then
			break
		end
	end
	return formatted
end

-- Returns WaveClearBonus, CleanBonus/Lives lost/SpeedBonus/TotalScore for the round.
function ScoringObject:GetWaveCleared( wave )
	local playerData = GetPlayerData( self.playerID )
	local waveClearScore = self:GetWaveClearBonus( wave )
	local time = playerData.waveObjects[wave].endTime - playerData.waveObjects[wave].startTime
	local speedBonus = self:GetSpeedBonus( time )
	local difficultyBonus = self:GetDifficultyBonus()
	local chaosBonus = self:GetCreepOrderBonus()
	local endlessBonus = self:GetEndlessBonus()
	local leaks = playerData.waveObjects[wave] and playerData.waveObjects[wave].leaks or 0
	local cleanBonus = self:GetCleanBonus( leaks == 0 )
	local totalScore = math.ceil(waveClearScore * (1 + cleanBonus + speedBonus + difficultyBonus) * (1 + chaosBonus + endlessBonus))

	return { clearBonus = waveClearScore, cleanBonus = cleanBonus, speedBonus = speedBonus, difficultyBonus = difficultyBonus, chaosBonus = chaosBonus, endlessBonus = endlessBonus, totalScore = totalScore }
end

function ScoringObject:GetBossWaveCleared( bossWave )
	local playerData = GetPlayerData( self.playerID )
	local bossBonus = self:GetBossBonus(bossWave-1)
	local waveClearScore = 3000 * bossBonus --100 per kill * 0.10 every wave past the first
	local difficultyBonus = self:GetDifficultyBonus()
	local endlessBonus = self:GetEndlessBonus()
	local frogKills = playerData.iceFrogKills
	local totalScore = math.ceil(waveClearScore * (1 + difficultyBonus) * (1 + endlessBonus))

	return { frogBonus = waveClearScore, difficultyBonus = difficultyBonus, frogKills = frogKills, endlessBonus = endlessBonus, totalScore = totalScore }
end

-- Returns amount of clean waves and waves under 30 as well as total score
function ScoringObject:GetWaveLost()
	local score = self.totalScore
	local clean = self.cleanWaves
	local under30 = self.under30

	return { cleanWaves = clean, under30 = under30, totalScore = score }
end

-- Total Score, BossBonus, DifficultyBonus, TotalScore after bonus
function ScoringObject:GetGameCleared()
	local playerData = GetPlayerData( self.playerID )
	local score = self.totalScore
	local values = {}
	local totalScore = 0
	local networthBonus = 0
	local extraFrogScore = 0 --Killed but didn't finish the wave
	local frogKills = 0 --Total
	if playerData.iceFrogKills then
		frogKills = playerData.iceFrogKills
		local remainder = frogKills % 30
		extraFrogScore = remainder * 100 * self:GetBossBonus(playerData.bossWaves-1) * self:GetDifficultyBonus()
	end

	if EXPRESS_MODE then
		networthBonus = self:GetNetworthBonus()
	end

	totalScore = math.ceil((score+extraFrogScore) * (networthBonus + 1))

	return { networthBonus = networthBonus, frogKills = frogKills, totalScore = totalScore }
end

-- takes leaks (lives) per wave (1.20 multiplier)
function ScoringObject:GetCleanBonus( bool )
	local bonus = 0
	if bool then
		self.cleanWaves = self.cleanWaves + 1
		bonus = 0.2 + (self.cleanWavesStreak * 0.02)
		self.cleanWavesStreak = self.cleanWavesStreak + 1
	else -- End streak
		self.cleanWavesStreak = 0
	end
	return bonus
end

-- takes time in seconds (30s multiplier 1, each second < 30 multiplier +0.02, above 30> -0.01)
function ScoringObject:GetSpeedBonus( time )
	local bonus = 1
	if time > 30 then
		bonus = bonus - ( time - 30 )*0.01
		self.under30Streak = 0
	elseif time < 30 then
		self.under30 = self.under30 + 1
		bonus = bonus + ( 30 - time )*0.02 + (self.under30Streak * 0.01)
		self.under30Streak = self.under30Streak + 1
	elseif time == 30 then -- End Streak
		self.under30Streak = 0
	end
	return bonus - 1
end

-- takes wave (Score = wave * CreepCount)
function ScoringObject:GetWaveClearBonus( wave )
	local bonus = wave * CREEPS_PER_WAVE
	return bonus
end

-- Express Only: (Player Networth/Base Networth/2)
-- Base Networth: 	Normal=88170
--					Hard=96060
--					VeryHard=110790
--					Insane=127770
function ScoringObject:GetNetworthBonus()

	local difficulty = GetPlayerDifficulty( self.playerID ).difficultyName
	local playerNetworth = GetPlayerNetworth( self.playerID )
	local baseWorth = 88170

	if ( difficulty == "Hard" ) then
		baseWorth = 96060
	elseif ( difficulty == "VeryHard" ) then
		baseWorth = 110790
	elseif ( difficulty == "Insane" ) then
		baseWorth = 127770
	end
	return (playerNetworth/baseWorth/2)
end

-- Creep order bonus
function ScoringObject:GetCreepOrderBonus()
	local bonus = 0
	if GameSettings.order == "Chaos" then
		bonus = 0.25 -- x1.25
	end
	return bonus
end

-- Wave mode bonus
function ScoringObject:GetEndlessBonus()
	local bonus = 0
	if GameSettings:GetEndless() == "Endless" then
		bonus = 0.5 -- x1.5
	end
	return bonus
end

-- Classic Only: 1 + 0.10 per wave, applies only to the boss kills
function ScoringObject:GetBossBonus( waves )
	local bonus = 1
	if waves >= 0 then
		bonus = 1+waves*0.10
	end
	return bonus
end

-- Normal (1x), Hard (2x), Very Hard (3x), Insane (4x)
function ScoringObject:GetDifficultyBonus()
	local bonus = 0 -- Normal
	local difficulty = GetPlayerDifficulty( self.playerID ).difficultyName
	if ( difficulty == "Hard" ) then
		bonus = 1
	elseif ( difficulty == "VeryHard" ) then
		bonus = 2
	elseif ( difficulty == "Insane" ) then
		bonus = 3
	end
	return bonus
end

----------------------------------------------------
