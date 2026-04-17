AddCSLuaFile()

ENT.Type = "point"
ENT.Base = "base_point"

local TeamEnts = TeamEnts or {}

function team.GetInfoEnt(teamnumber)
	return TeamEnts[teamnumber] or NULL
end

function team.PrintName(teamnumber)
	local self = team.GetInfoEnt(teamnumber)
	local name = IsValid(self) and self:GetTeamName() or ""
	if not name or name == "" then name = team.GetName(teamnumber) end
	return ScavLocalize(name)
end

function ENT:Initialize()
	TeamEnts[self:GetTeam()] = self
end

function ENT:SetupDataTables()
	self:NetworkVar("Int",		"Team")
	self:NetworkVar("Int",		"PointLimit")
	self:NetworkVar("Bool",		"Joinable")
	self:NetworkVar("Int",		"DeathTeam")
	self:NetworkVar("Float",	"SpawnDelay")
	self:NetworkVar("Int",		"MaxHealth")
	self:NetworkVar("Int",		"StartingHealth")
	self:NetworkVar("Float",	"HealthRegen")
	self:NetworkVar("Int",		"MaxArmor")
	self:NetworkVar("Int",		"StartingArmor")
	self:NetworkVar("Float",	"ArmorRegen")
	self:NetworkVar("Int",		"MaxEnergy")
	self:NetworkVar("Int",		"StartingEnergy")
	self:NetworkVar("Float",	"EnergyRegen")
	self:NetworkVar("Int",		"Lives")
	self:NetworkVar("Bool",		"PooledLives")
	self:NetworkVar("String",	"TeamName")
end

if CLIENT then return end

function ENT:KeyValue(key, value)
	key = string.lower(key)
	if key == "team" then
		value = team.ToTeamID(value)
		self:SetTeam(value)
	elseif key == "spawndelay" or key == "respawntine" then
		self:SetSpawnDelay(tonumber(value))
	elseif key == "deathteam" then
		value = team.ToTeamID(value)
		self:SetDeathTeam(value)
	elseif key == "pointlimit" then
		self:SetPointLimit(tonumber(value))
	elseif key == "joinable" then
		self:SetJoinable(tobool(value))
	elseif key == "maxhealth" then
		self:SetMaxHealth(tonumber(value))
	elseif key == "startinghealth" then
		self:SetStartingHealth(tonumber(value))
	elseif key == "healthregen" then
		self:SetHealthRegen(tonumber(value))
	elseif key == "maxarmor" then
		self:SetMaxArmor(tonumber(value))
	elseif key == "startingarmor" then
		self:SetStartingArmor(tonumber(value))
	elseif key == "armorregen" then
		self:SetArmorRegen(tonumber(value))
	elseif key == "maxenergy" then
		self:SetMaxEnergy(tonumber(value))
	elseif key == "startingenergy" then
		self:SetStartingEnergy(tonumber(value))
	elseif key == "energyregen" then
		self:SetEnergyRegen(tonumber(value))
	elseif key == "lives" then
		self:SetLives(tonumber(value))
	elseif key == "pooledlives" then
		self:SetPooledLives(tobool(value))
	elseif key == "teamname" then
		self:SetTeamName(string.Trim(string.Left(value, 255)))
	end
end

function ENT:Input(name, value, activator)
	name = string.lower(name)
	if name == "addpoints" then
		team.AddPoints(self:GetTeam(), tonumber(value))
	elseif name == "setspawndelay" then
		self:SetSpawnDelay(tonumber(value))
	elseif name == "setdeathteam" then
		self:SetDeathTeam(tonumber(value))
	elseif name == "setpointlimit" then
		self:SetPointLimit(tonumber(value))
	elseif name == "setmaxhealth" then
		self:SetMaxHealth(tonumber(value))
	elseif name == "setstartinghealth" then
		self:SetStartingHealth(tonumber(value))
	elseif key == "sethealthregen" then
		self:SetHealthRegen(tonumber(value))
	elseif name == "setmaxarmor" then
		self:SetMaxArmor(tonumber(value))
	elseif name == "setstartingarmor" then
		self:SetStartingArmor(tonumber(value))
	elseif key == "setarmorregen" then
		self:SetArmorRegen(tonumber(value))
	elseif name == "setmaxenergy" then
		self:SetMaxEnergy(tonumber(value))
	elseif name == "setstartingenergy" then
		self:SetStartingEnergy(tonumber(value))
	elseif key == "setenergyregen" then
		self:SetEnergyRegen(tonumber(value))
	elseif key == "addlives" then
		self:SetLives(self:GetLives() + tonumber(value))
	end
end

function ENT:UpdateTransmitState()
	return TRANSMIT_ALWAYS
end

function ENT:GetScoreLimit()
	local pointlimit = self:GetPointLimit()
	return pointlimit ~= 0 and pointlimit or GAMEMODE:GetInfoEnt():GetScoreLimit()
end

hook.Add("PostPlayerDeath", "SDMDoTeamSwitch", function(victim, attacker, inflictor)
	local teament = team.GetInfoEnt(victim:Team())
	if not IsValid(teament) then return end

	local deathteam = teament:GetDeathTeam()
	if deathteam == 0 then return end
	-- -1 for "use attacker's team"
	if deathteam == -1 then deathteam = attacker:Team() end

	if not team.GetAllTeams()[deathteam] then return ErrorNoHaltWithStack("Team #" .. tostring(deathteam) .. " not valid!") end

	GAMEMODE:PlayerJoinTeam(victim, deathteam)
end)

hook.Add("SetTeamPoints", "SDMDoPointCheck", function(team, oldpoints, newpoints)
	local teament = team.GetInfoEnt(team)
	if not IsValid(teament) then return end

	local ginfoent = GAMEMODE:GetInfoEnt()
	local checkvalue = IsValid(ginfoent) and ginfoent.PointLimit or 0
	local pointlimit = teament:GetPointLimit()
	--Use info_sdm_team point limit if it's positive
	if pointlimit > 0 then checkvalue = pointlimit end

	if checkvalue > 0 and newpoints > checkvalue then
		GAMEMODE:RoundEndTeam(team)
	end
end)
