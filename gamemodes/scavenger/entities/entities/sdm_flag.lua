AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_entity"
ENT.Model = "models/flag/flag.mdl"
ENT.ReturnPos = vector_origin
ENT.ReturnAng = angle_zero
ENT.ReturnTime = 10
ENT.mins = Vector(-8, -8, -8)
ENT.maxs = Vector(8, 8, 32)

function ENT:SetupDataTables()
	self:NetworkVar("Entity", "Grabbed") --player carrying us
	self:NetworkVar("Int", "Team")
	self:NetworkVar("Bool", "Enabled")
end

if SERVER then
	util.AddNetworkString("sdm_flag")

	local PLAYER_DIED = "1"

	concommand.Add("sdm_drop_flag", function(pl)
		if not IsValid(pl) then return end
		local self = pl.sdmflag
		if not IsValid(self) then return end

		self:RemoveGrabber(pl)
		pl.sdmflagdropped = self
	end)

	function ENT:AcceptInput(name, activator, caller, data)
		if name == "Skin" then self:SetSkin(tonumber(data)) return true end

		if name == "SetIdle" then self:SetIdleAnim(tostring(data)) return true end

		if name == "ForceReturn" then self:Return(activator) return true end

		if name == "Enable" then self:SetEnabled(true) return true end

		if name == "Disable" then self:SetEnabled(false) return true end

		if name == "Toggle" then self:SetEnabled(not self:GetEnabled()) return true end

		return false
	end

	local outputs =
	{
		"OnGrabbed",
		"OnCapped",
		"OnDropped",
		"OnReturned"
	}

	local LOGIC_OTHER = 1
	local LOGIC_OWN = 2
	local LOGIC_ALL = 3
	local logic = {}
		logic[LOGIC_ALL] =  function(flag, pl) return pl ~= TEAM_CONNECTING and pl ~= TEAM_SPECTATOR end
		logic[LOGIC_OTHER] = function(flag, pl) return logic[LOGIC_ALL](flag, pl) and flag ~= pl end
		logic[LOGIC_OWN] = function(flag, pl) return flag == pl end
		setmetatable(logic,{__index = function() return LOGIC_OTHER end})

	ENT.Logic = logic[LOGIC_OTHER]

	function ENT:KeyValue(key, value)
		if string.lower(key) == "model" or string.lower(key) == "modelname" then
			self.Model = value
		elseif string.lower(key) == "returntime" then
			self.ReturnTime = tonumber(value)
		elseif string.lower(key) == "team" then
			self:SetTeam(team.ToTeamID(value))
		elseif string.lower(key) == "rules" then
			self.Logic = logic[tonumber(value)]
		end

		if table.HasValue(outputs, key) then
			self:StoreOutput(key, value)
		end
	end

	function ENT:UpdateTransmitState()
		return TRANSMIT_ALWAYS
	end

	function ENT:RemoveGrabber(pl, reason)
		local pl = pl
		if not IsValid(pl) then pl = self:GetGrabbed() end

		self:SetGrabbed(NULL)
		self:SetVisible(true)
		self:SetParent()
		self:SetOwner()
		self:SetCollisionBounds(self.mins, self.maxs)

		net.Start("sdm_flag")
			net.WriteEntity(self)
			net.WriteBool(false)
			net.WritePlayer(pl)
		net.Broadcast()

		--todo: drop to ground
		
		if not IsValid(pl) then return end

		if self.ReturnTime >= 0 then
			timer.Create(tostring(self), self.ReturnTime, 1, function()
				if not IsValid(self) then return end
				self:Return(pl)
			end)
		end

		self:TriggerOutput("OnDropped", pl, reason)
		pl.sdmflag = nil
	end

	function ENT:Return(activator)
		self:TriggerOutput("OnReturned", activator)
		local pl = self:GetGrabbed()
		if IsValid(pl) then self:RemoveGrabber(pl) end
		self:SetPos(self.ReturnPos)
		self:SetAngles(self.ReturnAng)
		timer.Remove(tostring(self))
	end

	function ENT:StartTouch(pl)
		--handle respawn triggers (borrowing the entity name from TF2)
		if pl:GetClass() == "func_respawnflag" then
			self:Return(self:GetGrabbed())
			return
		end

		--handle player pickup
		if not self:GetEnabled() then return end
		if not pl:IsPlayer() or not pl:Alive() then return end
		if IsValid(pl.sdmflag) then return end
		if IsValid(self:GetGrabbed()) then return end
		if not self.Logic(self:GetTeam(), pl:Team()) then return end
		--player just dropped us, don't immediately pick back up
		if pl.sdmflagdropped == self then 
			pl.sdmflagdropped = nil
			return
		end

		pl.sdmflag = self
		self:SetGrabbed(pl)
		self:SetVisible(false)
		timer.Remove(tostring(self))
		self:SetParent(pl)
		self:SetOwner(pl)
		--prevents flag from blocking Scav Cannon suck
		self:SetCollisionBounds(vector_origin, vector_origin)

		net.Start("sdm_flag")
			net.WriteEntity(self)
			net.WriteBool(true)
			net.WritePlayer(pl)
		net.Broadcast()

		self:TriggerOutput("OnGrabbed", pl)
	end

	local function flagdropdead(pl, inflictor, attacker)
		local self = pl.sdmflag
		if not IsValid(self) then return end
		
		self:RemoveGrabber(pl, PLAYER_DIED)
	end

	hook.Add("PlayerDeath", "sdm_flag", flagdropdead)
	hook.Add("PlayerSilentDeath", "sdm_flag", flagdropdead)
	hook.Add("EntityRemoved", "sdm_flag", function(pl)
		local self = pl.sdmflag
		if not IsValid(self) then return end
		
		self:RemoveGrabber(pl)
	end)

	hook.Add("PlayerInitialSpawn", "sdm_flag", function(pl)
		for _, v in ipairs(ents.FindByClass("sdm_flag")) do
			local carrier = v:GetGrabbed()
			if not IsValid(carrier) then continue end
			net.Start("sdm_flag")
				net.WriteEntity(v)
				net.WriteBool(true)
				net.WritePlayer(carrier)
			net.Broadcast()
		end
	end)

end

function ENT:Initialize()
	self:SetModel(self.Model)
	self.ReturnPos = self:GetPos()
	self.ReturnAng = self:GetAngles()

	if SERVER then
		self:SetEnabled(true)
		self:SetTrigger(true)
		--self:SetCollisionBounds(self:GetModelBounds())
		self:SetCollisionBounds(self.mins, self.maxs)
		self:UseTriggerBounds(true, 8)
	else
		self:UpdateHUD()
	end
end

function ENT:Think()
	
end

function ENT:RemoveEntity()
	if IsValid(self.carrymdl) then
		self.carrymdl:Remove()
	end
	if SERVER then return end
	self:UpdateHUD()
end

function ENT:SetVisible(set)
	self:SetNoDraw(not set)
	self:DrawShadow(set)
end

if SERVER then return end

local offset = {}
offset.matrix = Matrix()
offset.pos = Vector(-12, -8, 0)
offset.ang = Angle(180, 70, 90)

function ENT:DrawCarried(pl)
	if not IsValid(pl) or not IsValid(self.carrymdl) then return end

	local bone = pl:LookupBone("ValveBiped.Bip01_Spine2")
	pl:CopyBoneMatrix(bone or 0, offset.matrix)
	local pos, ang = LocalToWorld(offset.pos, offset.ang, offset.matrix:GetTranslation(), offset.matrix:GetAngles())
	self.carrymdl:SetPos(pos)
	self.carrymdl:SetAngles(ang)

	self.carrymdl:DrawModel()
end

function ENT:Draw()
	self:DrawModel()
end

function ENT:UpdateHUD()
	if HUD and HUD.Elements and HUD.Elements["flagtracker"] then
		HUD.Elements["flagtracker"].Panel:SetupFlags()
	end
end

--We've been picked up or dropped
net.Receive("sdm_flag", function()
	local self = net.ReadEntity()
	local pickup = net.ReadBool()
	local pl = net.ReadPlayer()
	if not IsValid(self) then return end
	self:SetVisible(not pickup)
	if not IsValid(pl) then return end

	if pickup then
		pl.sdmflag = self
		self.carrymdl = ClientsideModel(self.Model)
		if not IsValid(self.carrymdl) then return end
			self.carrymdl:SetNoDraw(true)
			self.carrymdl:DrawShadow(false)
			self.carrymdl:SetParent(pl)
	else
		pl.sdmflag = nil
		if IsValid(self.carrymdl) then
			self.carrymdl:Remove()
		end
	end
end)

hook.Add("PrePlayerDraw", "sdm_flagdraw", function(pl, studio)
	local self = pl.sdmflag
	if not IsValid(self) then return end

	self:DrawCarried(pl)
end)

--[[hook.Add("InitPostEntity", "sdm_flag", function()

end)]]