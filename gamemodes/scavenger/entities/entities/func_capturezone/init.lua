ENT.Type ="brush"
ENT.Base = "base_brush"
ENT.Enabled = true
ENT.TeamNum = 0

function ENT:AcceptInput(name, activator, caller, data)
	if name == "Enable" then self:SetEnabled(true) return true end

	if name == "Disable" then self:SetEnabled(false) return true end

	if name == "Toggle" then self:Toggle() return true end

	return false
end

local outputs =
{
	--[["OnGrabbed",
	"OnCapped",
	"OnDropped",
	"OnReturned"]]
}

function ENT:KeyValue(key, value)
	local k = string.lower(key)
	if k == "enabled" then
		self.Enabled = tobool(value)
	elseif k == "team" or k == "teamnum" then
		self:SetTeam(value)
	elseif k == "rules" then
		self.Logic = logic[tonumber(value)]
	elseif k == "denydrop" then
		self.DenyDrop = tobool(value)
	end

	if table.HasValue(outputs, key) then
		self:StoreOutput(key, value)
	end
end

function ENT:GetEnabled()
	return self.Enabled
end

function ENT:SetEnabled(enable)
	local enable = enable
	if enable == nil then enable = true end
	self.Enabled = tobool(enable)
end

function ENT:Enable()
	self.Enabled = true
end

function ENT:Disable()
	self.Enabled = false
end

function ENT:Toggle()
	self.Enabled = not self.Enabled
end

function ENT:Team()
	return self.TeamNum
end

function ENT:SetTeam(t)
	local t = t
	if isstring(t) and (string.lower(t) == "none" or string.lower(t) == "all") then
		t = 0
	end
	--translate TF2
	if t == "2" then t = "red" end
	if t == "3" then t = "blue" end

	self.TeamNum = team.ToTeamID(t or 0)
end

function ENT:StartTouch(pl)
	if not pl:IsPlayer() or not pl:Alive() then return end
	local t = pl:Team()
	if not self:GetEnabled() then return end
	if t ~= self:Team() and self:Team() ~= 0 then return end

	local flag = pl.sdmflag
	if not IsValid(flag) then return end
	flag:Capture()
end