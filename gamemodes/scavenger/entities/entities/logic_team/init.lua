ENT.Type = "point"
ENT.Base = "base_point"

ENT.Team = TEAM_UNASSIGNED

function ENT:Initialize()
end

local outputs = {
	"OutputPlayer"
}

function ENT:KeyValue(key, value)
	if table.HasValue(outputs, key) then
		self:StoreOutput(key, value)
	end
end

function ENT:Input(name, value, activator)
	name = string.lower(name)
	if name == "dooutput" then
		for _, pl in pairs(team.GetPlayers(self.Team)) do
			self:TriggerOutput("OutputPlayer", pl)
		end
	end
end