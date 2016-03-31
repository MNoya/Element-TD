-- should be like wave.lua, but for co-op mode

WaveCoop = createClass({
		constructor = function(self, waveNumber)
			self.waveNumber = waveNumber
			self.creepsRemaining = CREEPS_PER_WAVE_COOP
			self.creeps = {}
			self.startTime = 0
			self.endTime = 0
			self.leaks = 0
			self.kills = 0
			self.callback = nil
		end
	},
{}, nil)

function WaveCoop:GetWaveNumber()
	return self.waveNumber
end

function WaveCoop:GetCreeps()
	return self.creeps
end

function WaveCoop:SetOnCompletedCallback(func)
	self.callback = func
end

function WaveCoop:OnCreepKilled(index)
	-- TODO 
end

function WaveCoop:RegisterCreep(index)
	if not self.creeps[index] then
		self.creeps[index] = index
	else
		Log:warn("Attemped to register creep " .. index .. " which is already register!")
	end
end

function WaveCoop:SpawnWave()
	-- TODO
end