ENT.Type = "anim"
ENT.Base = "base_anim"

function ENT:SetupDataTables()
	self:DTVar("Bool", "AbsSkyPath")
	self:DTVar("Int", "Precipitation")
	self.dt.AbsSkyPath = false
end

PrecacheParticleSystem("sdm_rain1")

function ENT:Initialize()
	self:SetNoDraw(true)
	self:DrawShadow(false)
	self:SetSolid(SOLID_NONE)
	if CLIENT then
		--Entity(0):StopParticles()
		self.PrecipitationFlags = self:GetFlagTable(self.dt.Precipitation)
		if self.PrecipitationFlags[1] then
			ParticleEffect("sdm_rain1", vector_origin, angle_zero, self)
		end	
	else
		self.dt.Precipitation = self.Precipitation
	end
end

function ENT:GetFlagTable(number)
	local str = math.IntToBin(number)
	local tab = {}
	for i=1, #str do
		tab[i] = tobool(string.Left(string.Right(str, i), 1))
	end
	return tab
end

function ENT:Think()
	if CLIENT then
		local nwsky = self:GetNetworkedString("skyname")
		if self.OldSkyName ~= nwsky then
			self:SetSky(nwsky)
		end
	end
end
