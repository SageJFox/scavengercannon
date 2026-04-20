ENT.Type = "point"
ENT.Base = "base_point"
ENT.Disabled = false
--default values
ENT.Radius = 100

function ENT:Initialize()
	self.TouchingEnts = {}
end

local outputs =
{
	"OnStartTouch",
	"OnEndTouch",
	"OnTouching",
	"OnNotTouching",
	"OnToucherKilled",
}

function ENT:KeyValue(key, value)
	local key = string.lower(key)
	if key == "radius" then
		self.Radius = tonumber(value)
	elseif key == "startdisabled" then
		self:SetEnabled(not tobool(value))
	end

	if table.HasValue(outputs, key) then
		self:StoreOutput(key, value)
	end
end

function ENT:SetEnabled(state)
	local disabled = not tobool(state)
	self.Disabled = disabled
	self.TouchingEnts = disabled and {} or self.TouchingEnts
end

function ENT:EntPassesFilter(ent)
	if not IsValid(ent) then return false end
	if ent:IsPlayer() and not ent:Alive() then return false end
	if IsValid(ent:GetParent()) then return false end

	return ent:GetSolid() ~= 0
end

function ENT:Think()
	if self.Disabled then return end

	local sphereents = ents.FindInSphere(self:GetPos(), self.Radius)
	for _, v in pairs(sphereents) do
		if table.HasValue(self.TouchingEnts, v) or not self:EntPassesFilter(v) then continue end

		self:TriggerOutput("OnStartTouch", v, self)
		table.insert(self.TouchingEnts, v)
	end
	for k, v in ipairs(self.TouchingEnts) do
		if not IsValid(v) then continue end

		if not table.HasValue(sphereents, v) then
			self:TriggerOutput("OnEndTouch", v, self)
		elseif v:IsPlayer() and not v:Alive() then
			self:TriggerOutput("OnToucherKilled", v, self)
		end
	end
	local numtouch = #self.TouchingEnts
	if numtouch == 0 then return end
	
	for i = numtouch, 1, -1 do
		if not IsValid(self.TouchingEnts[i]) then
			self:TriggerOutput("OnToucherKilled", self, self)
			table.remove(self.TouchingEnts, i)
		elseif not table.HasValue(sphereents, self.TouchingEnts[i]) then
			self:TriggerOutput("OnEndTouch", self.TouchingEnts[i], self)
			table.remove(self.TouchingEnts, i)
		end
	end
end

function ENT:TouchTest()
	if self.Disabled then return end
	if #self.TouchingEnts == 0 then return self:TriggerOutput("OnNotTouching", self, self) end

	for _, v in ipairs(self.TouchingEnts) do
		self:TriggerOutput("OnTouching", v, self)
	end
end

function ENT:Input(name, value, activator)
	local name = string.lower(name)
	if name == "enable" then
		self:SetEnabled(true)
	elseif name == "disable" then
		self:SetEnabled(false)
	elseif name == "toggle" then
		self:SetEnabled(self.Disabled)
	end
end
