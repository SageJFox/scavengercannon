--info_sdm

ENT.Type ="point"
ENT.Base = "base_point"

--default values
ENT.RoundStartDelay = 3
ENT.RoundTime = 12*60
ENT.PointLimit = 30
ENT.TimeLimit = 20*60

function GAMEMODE:GetInfoEnt()
	return self.InfoEnt or NULL
end

function ENT:Initialize()
	GAMEMODE.InfoEnt = self
end

local modetranslate = {
	["deathmatch"] = SDM_MODE_DM,
	["team_deathmatch"] = SDM_MODE_DM_TEAM,
	["ctf"] = SDM_MODE_CTF,
	["cell_control"] = SDM_MODE_CELLCONTROL,
	["hoard"] = SDM_MODE_HOARD,
	["survival"] = SDM_MODE_SURVIVAL,
	["capture"] = SDM_MODE_CAPTURE,
	["custom"] = SDM_MODE_CUSTOM
}

function ENT:KeyValue(key, value)
	local key = string.lower(key)
	local value = value
	if key == "mode" then
		GAMEMODE:SetGNWVar("mode", modetranslate[string.lower(value)] or 0)
		return
	end

	value = tonumber(value)
	if not value then return end

	if key == "roundstartdelay" then
		self.RoundStartDelay = value
	elseif key == "roundtime" then
		self.RoundTime = value
	elseif key == "timelimit" then
		self.TimeLimit = value
		GAMEMODE:SetGNWFloat("TimeLimit", self.TimeLimit)
	elseif key == "pointlimit" or key == "maxpoints" then
		self.PointLimit = value
	end
end

function ENT:GetScoreLimit()
	return self.PointLimit
end

function ENT:Input(name,value,activator)
	name = string.lower(name)
	if name == "startround" then
		GAMEMODE:StartRound(self.RoundTime, self.RoundStartDelay)
	elseif name == "addroundtime" then
		GAMEMODE:AddRoundTime(tonumber(value))
	elseif name == "endroundplayer" then
		GAMEMODE:EndRoundPlayer(value)
	elseif name == "endroundteam" then
		GAMEMODE:EndRoundTeam(value)
	end
end

local defaultvalues = {}
defaultvalues["RoundTime"] = 30

