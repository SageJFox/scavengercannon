ENT.Type ="point"
DEFINE_BASECLASS("point_proximity_trigger")
ENT.Teams = {}

local outputs =
{
	"OnCapped",
}

function ENT:KeyValue(key, value)
	local k = string.lower(key)
	if k == "team" then
		self:SetTeam(value)
	end

	if table.HasValue(outputs, key) then
		self:StoreOutput(key, value)
	end

	BaseClass.KeyValue(self, key, value)
end

function ENT:Team(t)
	return self.Teams[t] or false
end

local validate = function(teams)
	if isstring(teams) then
		return string.Split(string.lower(teams), " ")
	elseif isnumber(teams) then
		return {teams}
	elseif istable(teams) then
		return teams
	end
	return {}
end

function ENT:SetTeam(teams, unset)
	local set = not unset or nil
	local teamlist = validate(teams)
	
	for _, t in ipairs(teamlist) do
		if t == "none" or t == "all" then
			for id, _ in pairs(team.GetAllTeams()) do
				if not team.IsReal(id, true) then continue end
				self.Teams[id] = set
			end
			return
		end

		t = tonumber(t) or team.ToTeamID(t)
		if not team.IsReal(t, true) then continue end
		self.Teams[t] = set
	end
end

function ENT:UnsetTeam(teams)
	self:SetTeam(teams, true)
end

function ENT:ClearTeams()
	self:UnsetTeam("all")
end

function ENT:EntPassesFilter(pl)
	if not self:GetEnabled() then return end
	--needs to be a player on one of our teams
	if not pl:IsPlayer() or not pl:Alive() then return end
	if not self:Team(pl:Team()) then return end
	--gotta be carrying a flag
	local flag = pl.sdmflag
	if not IsValid(flag) then return end
	--flag must match whitelist/not match blacklist
	if self.target and targetname(flag, self.target) == self.excludetarget then return end

	flag:Capture()
	self:TriggerOutput("OnCapped", pl, flag)
end