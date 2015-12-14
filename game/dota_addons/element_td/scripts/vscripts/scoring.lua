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
function ScoringObject:UpdateScore( const )
	local scoreTable = {}
	local processed = {}
	local playerData = GetPlayerData(self.playerID)

	if ( const == SCORING_WAVE_CLEAR ) then
		scoreTable = self:GetWaveCleared()
		table.insert(processed, {'Wave ' .. playerData.completedWaves .. ' cleared!', '#FFF0F5'} )
	elseif ( const == SCORING_WAVE_LOST ) then
		scoreTable = self:GetWaveLost()
		table.insert(processed, {'Game over! Lost on wave ' .. playerData.completedWaves + 1, '#FFF0F5'} )
	elseif ( const == SCORING_GAME_CLEAR ) then
		scoreTable = self:GetGameCleared()
		table.insert(processed, {'Game cleared! Your score ' .. comma_value(self.totalScore), '#FFF0F5'} )
	else
		return false
	end

	-- Process Score Table keeping ordering below
	if scoreTable['clearBonus'] then
		table.insert(processed, {'&nbsp;&nbsp;&nbsp;&nbsp;Wave ' .. playerData.completedWaves .. ' clear bonus: ' .. comma_value(scoreTable['clearBonus']), '#00FFFF'} )
	end
	if scoreTable['cleanBonus'] then
		if scoreTable['cleanBonus'] ~= 0 then
			table.insert(processed, {'&nbsp;&nbsp;&nbsp;&nbsp;Clean bonus: ' .. GetPctString(scoreTable['cleanBonus']), '#00FF00'} )
		else
			table.insert(processed, {'&nbsp;&nbsp;&nbsp;&nbsp;'..playerData.waveObject.leaks .. ' Lives lost', '#FF0000'} )
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
	if scoreTable['bossBonus'] and not EXPRESS_MODE then
		table.insert(processed, {'&nbsp;&nbsp;&nbsp;&nbsp;Boss bonus: '.. GetPctString(scoreTable['bossBonus']), '#00FFFF' })
	end
	if scoreTable['difficultyBonus'] then
		table.insert(processed, {'&nbsp;&nbsp;&nbsp;&nbsp;'..GetPlayerDifficulty( self.playerID ).difficultyName .. ' difficulty: '.. GetPctString(scoreTable['difficultyBonus']), '#00FF00' } )
	end
	if scoreTable['totalScore'] then
		table.insert(processed, {'&nbsp;&nbsp;&nbsp;&nbsp;Total score: ' .. comma_value(scoreTable['totalScore']), '#FF8C00'})
		if const == SCORING_WAVE_LOST or const == SCORING_GAME_CLEAR then
			self.totalScore = scoreTable['totalScore']
		else
			self.totalScore = self.totalScore + scoreTable['totalScore']
		end	
	end
	--PrintTable(processed)
	self:ShowScore(processed)
	CustomGameEventManager:Send_ServerToAllClients("SetTopBarPlayerScore", {playerId=self.playerID, score=comma_value( self.totalScore )} )
	CustomGameEventManager:Send_ServerToPlayer( PlayerResource:GetPlayer(self.playerID), "etd_update_score", { score = comma_value( self.totalScore ) } )
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
function ScoringObject:GetWaveCleared()
	local playerData = GetPlayerData( self.playerID )
	local waveClearScore = self:GetWaveClearBonus( playerData.completedWaves )
	local cleanBonus = self:GetCleanBonus( playerData.waveObject.leaks == 0 )
	local time = playerData.waveObject.endTime - playerData.waveObject.startTime
	local speedBonus = self:GetSpeedBonus( time )
	local totalScore = math.ceil(waveClearScore * (cleanBonus + speedBonus + 1))

	print("Time: "..time)
	return { clearBonus = waveClearScore, cleanBonus = cleanBonus, speedBonus = speedBonus, totalScore = totalScore }
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
	local totalScore = 0
	local networthBonus = 0
	local difficultyBonus = 1
	local bossBonus = 0

	if EXPRESS_MODE then
		networthBonus = self:GetNetworthBonus()
	else
		bossBonus = self:GetBossBonus(playerData.bossWaves-1)
	end
	difficultyBonus = self:GetDifficultyBonus()

	totalScore = math.ceil(score * (networthBonus + difficultyBonus + bossBonus + 1))

	return { networthBonus = networthBonus, difficultyBonus = difficultyBonus, bossBonus = bossBonus, totalScore = totalScore }
end

-- takes leaks (lives) per wave (1.20 multiplier)
function ScoringObject:GetCleanBonus( bool )
	local bonus = 0
	if bool then
		self.cleanWaves = self.cleanWaves + 1
		bonus = 0.2 + (self.cleanWavesStreak * 0.05)
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
	local playerData = GetPlayerData( self.playerID )
	local difficulty = GetPlayerDifficulty( self.playerID ).difficultyName
	local playerNetworth = ElementTD.vPlayerIDToHero[self.playerID]:GetGold()
	local baseWorth = 88170
	for i,v in pairs( playerData.towers ) do
		local tower = EntIndexToHScript( i )
		if tower:GetHealth() == tower:GetMaxHealth() then
			for i=0,16 do
				local ability = tower:GetAbilityByIndex( i )
				if ability then
					local name = ability:GetAbilityName()
					if ( name == "sell_tower_100" ) then
						playerNetworth = playerNetworth + GetUnitKeyValue( tower.class, "TotalCost" )
					elseif ( name == "sell_tower_75" ) then
						playerNetworth = playerNetworth + round( GetUnitKeyValue( tower.class, "TotalCost" ) * 0.75 )
					end
				end
			end
		end
	end
	if ( difficulty == "Hard" ) then
		baseWorth = 96060
	elseif ( difficulty == "VeryHard" ) then
		baseWorth = 110790
	elseif ( difficulty == "Insane" ) then
		baseWorth = 127770
	end
	return (playerNetworth/baseWorth/2)
end

-- Classic Only: 1.05 + 0.01 per additional wave
function ScoringObject:GetBossBonus( waves )
	local bonus = 0.05
	if waves > 0 then
		bonus = bonus + waves*0.01
	end
	return bonus
end

-- Normal (1x), Hard (1.5x), Very Hard (2x), Insane (2.5x)
function ScoringObject:GetDifficultyBonus()
	local bonus = 0 -- Normal
	local difficulty = GetPlayerDifficulty( self.playerID ).difficultyName
	if ( difficulty == "Hard" ) then
		bonus = 0.5
	elseif ( difficulty == "VeryHard" ) then
		bonus = 1
	elseif ( difficulty == "Insane" ) then
		bonus = 1.5
	end
	return bonus
end

----------------------------------------------------
