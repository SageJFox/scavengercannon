--Firemodes largely related to the Day of Defeat series. Can have other games' props defined!

local eject = "brass"
util.PrecacheModel("models/scav/shells/shell_large.mdl")
util.PrecacheModel("models/scav/shells/shell_medium.mdl")
util.PrecacheModel("models/scav/shells/shell_small.mdl")

local dodsshelleject = function(self,shellsize)
	if not game.SinglePlayer() and CLIENT then
		if not self.Owner:GetViewModel() then return end
		local size = shellsize or "large"
		local attach = self.Owner:GetViewModel():GetAttachment(self.Owner:GetViewModel():LookupAttachment(eject))
		if attach == nil then
			attach = self:GetAttachment(self:LookupAttachment(eject))
		end
		if attach then
			local brass = ents.CreateClientProp("models/scav/shells/shell_"..size..".mdl")
			if IsValid(brass) then
				brass:SetPos(attach.Pos)
				brass:SetAngles(attach.Ang)
				brass:SetCollisionGroup(COLLISION_GROUP_DEBRIS)
				brass:AddCallback("PhysicsCollide",function(ent,data)
					if ( data.Speed > 50 ) then ent:EmitSound(Sound("Weapon.Shell")) end
				end)
				brass:Spawn()
				brass:DrawShadow(false)
				local angShellAngles = self.Owner:EyeAngles()
				--angShellAngles:RotateAroundAxis(Vector(0,0,1),90)
				local vecShellVelocity = self.Owner:GetAbsVelocity()
				vecShellVelocity = vecShellVelocity + angShellAngles:Right() * math.Rand( 50, 70 )
				vecShellVelocity = vecShellVelocity + angShellAngles:Up() * math.Rand( 100, 150 )
				vecShellVelocity = vecShellVelocity + angShellAngles:Forward() * 25
				local phys = brass:GetPhysicsObject()
				if IsValid(phys) then
					phys:SetVelocity(vecShellVelocity)
					phys:SetAngleVelocity(angShellAngles:Forward()*1000)
				end
				timer.Simple(10,function() if IsValid(brass) then brass:Remove() end end)
			end
		end
	elseif game.SinglePlayer() and SERVER then
		if not self.Owner:GetViewModel() then return end
		local size = shellsize or "large"
		local attach = self.Owner:GetViewModel():GetAttachment(self.Owner:GetViewModel():LookupAttachment(eject))
		if attach then
			local brass = ents.Create("prop_physics")
			if IsValid(brass) then
				brass:SetModel("models/scav/shells/shell_"..size..".mdl")
				brass:PhysicsInit(SOLID_VPHYSICS)
				brass:SetPos(attach.Pos)
				brass:SetAngles(attach.Ang)
				brass:SetCollisionGroup(COLLISION_GROUP_DEBRIS)
				brass:AddCallback("PhysicsCollide",function(ent,data)
					if ( data.Speed > 50 ) then ent:EmitSound(Sound("Weapon.Shell")) end
				end)
				brass:Spawn()
				brass:DrawShadow(false)
				brass.NoScav = true
				-- if CLIENT then
				-- 	brass:SetupBones()
				-- end
				local angShellAngles = self.Owner:EyeAngles()
				--angShellAngles:RotateAroundAxis(Vector(0,0,1),90)
				local vecShellVelocity = self.Owner:GetAbsVelocity()
				vecShellVelocity = vecShellVelocity + angShellAngles:Right() * math.Rand( 50, 70 )
				vecShellVelocity = vecShellVelocity + angShellAngles:Up() * math.Rand( 100, 150 )
				vecShellVelocity = vecShellVelocity + angShellAngles:Forward() * 25
				local phys = brass:GetPhysicsObject()
				if IsValid(phys) then
					phys:SetVelocity(vecShellVelocity)
					phys:SetAngleVelocity(angShellAngles:Forward()*1000)
				end
				timer.Simple(10,function() if IsValid(brass) then brass:Remove() end end)
			end
		end
	end
end

local WALK_SPEED = 20000
local PRONE_SPEED = 800 --900 would be crouching with walk key held

--[[==============================================================================================
	--.30 cal
==============================================================================================]]--
		
		local tab = {}
			tab.Name = "#scav.scavcan.30cal"
			tab.anim = ACT_VM_FIDGET
			tab.chargeanim = ACT_VM_RECOIL1
			tab.Level = 2
			local identify = {}
			tab.Identify = setmetatable(identify, {__index = function() return 0 end} )
			tab.MaxAmmo = 300
			tab.ChargeAttack = function(self,item)
				if self.Owner:KeyDown(IN_ATTACK) then
					local bullet = {}
						bullet.Num = 1
						if self.Owner:GetVelocity():LengthSqr() < WALK_SPEED then
							if self.Owner:Crouching() and self.Owner:GetVelocity():LengthSqr() < PRONE_SPEED then 
								bullet.Spread = Vector(0.1,0.1,0) --"true" spread for bipod is .01 in DoD, but this player has a lot more freedom of movement
								if CLIENT then self.Owner:SetEyeAngles((vector_up*0.01+self:GetAimVector()):Angle()) end
							else
								bullet.Spread = Vector(0.2,0.2,0)
								if CLIENT then self.Owner:SetEyeAngles((vector_up*0.05+self:GetAimVector()):Angle()) end
							end
						else
							bullet.Spread = Vector(0.3,0.3,0)
							if CLIENT then self.Owner:SetEyeAngles((vector_up*0.05+self:GetAimVector()):Angle()) end
						end
						bullet.Tracer = 1
						bullet.Force = 5
						bullet.Damage = 85
						bullet.TracerName = "ef_scav_tr_b"
						bullet.Src = self.Owner:GetShootPos()
						bullet.Dir = self:GetAimVector()
					self.Owner:ScavViewPunch(Angle(-0.7,math.Rand(-0.4,0.4),0),0.2,true)
					if SERVER or not game.SinglePlayer() then
						self.Owner:FireBullets(bullet)
					end
					self:MuzzleFlash2()
					self.Owner:SetAnimation(PLAYER_ATTACK1)
					self.Owner:EmitSound("Weapon_30cal.Shoot")
					dodsshelleject(self)
					if SERVER then
						--self:SetBlockPoseInstant(1,4)
						self:SetPanelPoseInstant(0.25,2)
						self:TakeSubammo(item,1)
					end
				end
				local continuefiring = self:ProcessLinking(item) and self:StopChargeOnRelease()
				if not continuefiring then
					if SERVER then
						self:SetChargeAttack()
						self:SetBarrelRestSpeed(0)
					end
				end
				return 0.1
			end
			tab.FireFunc = function(self,item)
				self:SetChargeAttack(tab.ChargeAttack,item)
				if SERVER then
					self:SetBarrelRestSpeed(1000)	
				end								
				return false
			end
			if SERVER then
				ScavData.CollectFuncs["models/weapons/w_30cal.mdl"] = function(self,ent) return {{ScavData.FormatModelname(ent:GetModel()),150,0}} end
				ScavData.CollectFuncs["models/weapons/w_30calpr.mdl"] = function(self,ent) return {{ScavData.FormatModelname("models/weapons/w_30cal.mdl"),150,0}} end
				ScavData.CollectFuncs["models/weapons/w_30calsr.mdl"] = ScavData.CollectFuncs["models/weapons/w_30calpr.mdl"]
			end
			tab.Cooldown = 0
		ScavData.RegisterFiremode(tab,"models/weapons/w_30cal.mdl")
		
--[[==============================================================================================
	--BAR
==============================================================================================]]--
		
		local tab = {}
			tab.Name = "#scav.scavcan.bar"
			tab.anim = ACT_VM_FIDGET
			tab.chargeanim = ACT_VM_RECOIL1
			tab.Level = 2
			tab.MaxAmmo = 60
			tab.ChargeAttack = function(self,item)
				if self.Owner:KeyDown(IN_ATTACK) then
					local bullet = {}
						bullet.Num = 1
						if self.Owner:GetVelocity():LengthSqr() < WALK_SPEED then
							if self.Owner:Crouching() and self.Owner:GetVelocity():LengthSqr() < PRONE_SPEED then
								bullet.Spread = Vector(0.02,0.02,0)
							else
								bullet.Spread = Vector(0.025,0.025,0)
							end
						else
							bullet.Spread = Vector(0.125,0.125,0)
						end
						bullet.Tracer = 1
						bullet.Force = 5
						bullet.Damage = 50
						bullet.TracerName = "ef_scav_tr_b"
						bullet.Src = self.Owner:GetShootPos()
						bullet.Dir = self:GetAimVector()
						self.Owner:ScavViewPunch(Angle(-0.7,math.Rand(-0.4,0.4),0),0.2,true)
						if CLIENT then self.Owner:SetEyeAngles((vector_up*0.05+self:GetAimVector()):Angle()) end
					if SERVER or not game.SinglePlayer() then
						self.Owner:FireBullets(bullet)
					end
					self:MuzzleFlash2()
					self.Owner:SetAnimation(PLAYER_ATTACK1)
					self.Owner:EmitSound("Weapon_Bar.Shoot")
					dodsshelleject(self)
					if SERVER then
						self:SetPanelPoseInstant(0.125,2)
						self:TakeSubammo(item,1)
					end
				end
				local continuefiring = self:ProcessLinking(item) and self:StopChargeOnRelease()
				if not continuefiring then
					if SERVER then
						self:SetChargeAttack()
						self:SetBarrelRestSpeed(0)
					end
				end
				return 0.12
			end
			tab.FireFunc = function(self,item)
				self:SetChargeAttack(tab.ChargeAttack,item)
				if SERVER then
					self:SetBarrelRestSpeed(500)	
				end								
				return false
			end
			if SERVER then
				ScavData.CollectFuncs["models/weapons/w_bar.mdl"] = function(self,ent) return {{ScavData.FormatModelname(ent:GetModel()),20,0}} end
			end
			tab.Cooldown = 0
		ScavData.RegisterFiremode(tab,"models/weapons/w_bar.mdl")

--[[==============================================================================================
	--C96
==============================================================================================]]--
		
		local tab = {}
			tab.Name = "#scav.scavcan.c96"
			tab.anim = ACT_VM_FIDGET
			tab.chargeanim = ACT_VM_RECOIL1
			tab.Level = 2
			tab.MaxAmmo = 60
			tab.ChargeAttack = function(self,item)
				if self.Owner:KeyDown(IN_ATTACK) then
					local bullet = {}
						bullet.Num = 1
						bullet.Spread = self.Owner:GetVelocity():LengthSqr() < WALK_SPEED and Vector(0.065,0.065,0) or Vector(0.165,0.165,0)
						bullet.Tracer = 1
						bullet.Force = 5
						bullet.Damage = 40
						bullet.TracerName = "ef_scav_tr_b"
						bullet.Src = self.Owner:GetShootPos()
						bullet.Dir = self:GetAimVector()
					self.Owner:ScavViewPunch(Angle(-0.7,math.Rand(-0.4,0.4),0),0.2,true)
					if CLIENT then self.Owner:SetEyeAngles((vector_up*0.05+self:GetAimVector()):Angle()) end
					if SERVER or not game.SinglePlayer() then
						self.Owner:FireBullets(bullet)
					end
					self:MuzzleFlash2()
					self.Owner:SetAnimation(PLAYER_ATTACK1)
					self.Owner:EmitSound("Weapon_C96.Shoot")
					dodsshelleject(self,"small")
					if SERVER then
						self:TakeSubammo(item,1)
					end
				end
				local continuefiring = self:ProcessLinking(item) and self:StopChargeOnRelease()
				if not continuefiring then
					if SERVER then
						self:SetChargeAttack()
						self:SetBarrelRestSpeed(0)
					end
				end
				return 0.065
			end
			tab.FireFunc = function(self,item)
				self:SetChargeAttack(tab.ChargeAttack,item)
				if SERVER then
					self:SetBarrelRestSpeed(250)	
				end								
				return false
			end
			if SERVER then
				ScavData.CollectFuncs["models/weapons/w_c96.mdl"] = function(self,ent) return {{ScavData.FormatModelname(ent:GetModel()),20,0}} end
			end
			tab.Cooldown = 0
		ScavData.RegisterFiremode(tab,"models/weapons/w_c96.mdl")

--[[==============================================================================================
	--Kar 98
==============================================================================================]]--
		
		local tab = {}
			tab.Name = "#scav.scavcan.kar98"
			tab.anim = ACT_VM_SECONDARYATTACK
			tab.Level = 2
			local identify = {}
			tab.Identify = setmetatable(identify, {__index = function() return 0 end} )
			tab.MaxAmmo = 15
			tab.FireFunc = function(self,item)
				local bullet = {}
					bullet.Num = 1
					bullet.Spread = self.Owner:GetVelocity():LengthSqr() < WALK_SPEED and Vector(0.014,0.014,0) or Vector(0.164,0.164,0)
					bullet.Tracer = 1
					bullet.Force = 5
					bullet.Damage = 110
					bullet.TracerName = "ef_scav_tr_b"
					bullet.Src = self.Owner:GetShootPos()
					bullet.Dir = self:GetAimVector()
				self.Owner:ScavViewPunch(Angle(-3,math.Rand(-0.2,0.2),0),0.4,true)
				if CLIENT then self.Owner:SetEyeAngles((vector_up*0.05+self:GetAimVector()):Angle()) end
				if SERVER or not game.SinglePlayer() then
					self.Owner:FireBullets(bullet)
				end
				self:MuzzleFlash2()
				self.Owner:SetAnimation(PLAYER_ATTACK1)
				self.Owner:EmitSound("Weapon_Kar.Shoot")
				timer.Simple(.375,function()
					if SERVER then
						self.Owner:EmitSound("Weapon_K98.BoltBack1")
						timer.Simple(.2,function() self.Owner:EmitSound("Weapon_K98.BoltBack2") end)
						timer.Simple(.6,function() self.Owner:EmitSound("Weapon_K98.BoltForward2") end)
					end
					dodsshelleject(self)
				end)
				if SERVER then
					return self:TakeSubammo(item,1)
				end
			end
			if SERVER then
				ScavData.CollectFuncs["models/weapons/w_k98.mdl"] = function(self,ent) return {{ScavData.FormatModelname(ent:GetModel()),5,0}} end
				ScavData.CollectFuncs["models/weapons/w_k98s.mdl"] = function(self,ent) return {{ScavData.FormatModelname(ent:GetModel()),5,0}} end
			end
			tab.Cooldown = 1.6
		ScavData.RegisterFiremode(tab,"models/weapons/w_k98.mdl")
		ScavData.RegisterFiremode(tab,"models/weapons/w_k98s.mdl")

--[[==============================================================================================
	--M1 Carbine
==============================================================================================]]--
		
		local tab = {}
			tab.Name = "#scav.scavcan.carbine"
			tab.anim = ACT_VM_RECOIL1
			tab.Level = 2
			tab.MaxAmmo = 45
			tab.FireFunc = function(self,item)
				local bullet = {}
					bullet.Num = 1
					bullet.Spread = self.Owner:GetVelocity():LengthSqr() < WALK_SPEED and Vector(0.019,0.019,0) or Vector(0.119,0.119,0)
					bullet.Tracer = 1
					bullet.Force = 5
					bullet.Damage = 40
					bullet.TracerName = "ef_scav_tr_b"
					bullet.Src = self.Owner:GetShootPos()
					bullet.Dir = self:GetAimVector()
				self.Owner:ScavViewPunch(Angle(-3,math.Rand(-0.2,0.2),0),0.4,true)
				if CLIENT then self.Owner:SetEyeAngles((vector_up*0.05+self:GetAimVector()):Angle()) end
				if SERVER or not game.SinglePlayer() then
					self.Owner:FireBullets(bullet)
				end
				self:MuzzleFlash2()
				self.Owner:SetAnimation(PLAYER_ATTACK1)
				self.Owner:EmitSound("Weapon_Carbine.Shoot")
				self.nextfireearly = CurTime()+0.1
				dodsshelleject(self,"medium")
				if SERVER then
					return self:TakeSubammo(item,1)
				end
			end
			if SERVER then
				ScavData.CollectFuncs["models/weapons/w_m1carb.mdl"] = function(self,ent) return {{ScavData.FormatModelname(ent:GetModel()),15,0}} end
			end
			tab.Cooldown = 0.3
		ScavData.RegisterFiremode(tab,"models/weapons/w_m1carb.mdl")

--[[==============================================================================================
	--M1 Garand
==============================================================================================]]--
		
		util.PrecacheModel("models/scav/shells/garand_clip.mdl")
		local tab = {}
			tab.Name = "#scav.scavcan.garand"
			tab.anim = ACT_VM_RECOIL1
			tab.Level = 2
			tab.MaxAmmo = 24
			tab.FireFunc = function(self,item)
				local bullet = {}
						bullet.Num = 1
						bullet.Spread = self.Owner:GetVelocity():LengthSqr() < WALK_SPEED and Vector(0.014,0.014,0) or Vector(0.114,0.114,0)
						bullet.Tracer = 1
						bullet.Force = 5
						bullet.Damage = 80
						bullet.TracerName = "ef_scav_tr_b"
						bullet.Src = self.Owner:GetShootPos()
						bullet.Dir = self:GetAimVector()
					self.Owner:ScavViewPunch(Angle(-3,math.Rand(-0.2,0.2),0),0.4,true)
					if CLIENT then self.Owner:SetEyeAngles((vector_up*0.05+self:GetAimVector()):Angle()) end
					if SERVER or not game.SinglePlayer() then
						self.Owner:FireBullets(bullet)
					end
					self:MuzzleFlash2()
					self.Owner:SetAnimation(PLAYER_ATTACK1)
					self.Owner:EmitSound("Weapon_Garand.Shoot")
					self.nextfireearly = CurTime()+0.37
					dodsshelleject(self)
					if (item.subammo <= 1 and SERVER) or (item.subammo <= 0 and CLIENT) then --garand ping
						timer.Simple(0.025,function()
							self.Owner:EmitSound("Weapon_Garand.ClipDing")
							if not game.SinglePlayer() and CLIENT then
								local ping = ents.CreateClientProp("models/scav/shells/garand_clip.mdl")
								local attach = self.Owner:GetViewModel():GetAttachment(self.Owner:GetViewModel():LookupAttachment(eject))
								if attach then
									ping:SetPos(attach.Pos)
									ping:SetAngles(attach.Ang)
									ping:Spawn()
									local angShellAngles = self.Owner:EyeAngles()
									local vecShellVelocity = self.Owner:GetAbsVelocity()
									vecShellVelocity = vecShellVelocity + angShellAngles:Right() * math.Rand( 50, 70 );
									vecShellVelocity = vecShellVelocity + angShellAngles:Up() * math.Rand( 200, 250 );
									vecShellVelocity = vecShellVelocity + angShellAngles:Forward() * 25;
									local phys = ping:GetPhysicsObject()
									if IsValid(phys) then
										phys:SetVelocity(vecShellVelocity)
										phys:SetAngleVelocity(angShellAngles:Forward()*1000)
									end
									timer.Simple(10,function() if IsValid(ping) then ping:Remove() end end)
								end
							elseif game.SinglePlayer() and SERVER then
								local ping = ents.Create("prop_physics")
								local attach = self.Owner:GetViewModel():GetAttachment(self.Owner:GetViewModel():LookupAttachment(eject))
								if attach then
									ping:SetModel("models/scav/shells/garand_clip.mdl")
									ping:PhysicsInit(SOLID_VPHYSICS)
									ping:SetPos(attach.Pos)
									ping:SetAngles(attach.Ang)
									ping:Spawn()
									ping:DrawShadow(false)
									ping.NoScav = true
									if CLIENT then
										ping:SetupBones()
									end
									local angShellAngles = self.Owner:EyeAngles()
									local vecShellVelocity = self.Owner:GetAbsVelocity()
									vecShellVelocity = vecShellVelocity + angShellAngles:Right() * math.Rand( 50, 70 );
									vecShellVelocity = vecShellVelocity + angShellAngles:Up() * math.Rand( 200, 250 );
									vecShellVelocity = vecShellVelocity + angShellAngles:Forward() * 25;
									local phys = ping:GetPhysicsObject()
									if IsValid(phys) then
										phys:SetVelocity(vecShellVelocity)
										phys:SetAngleVelocity(angShellAngles:Forward()*1000)
									end
									timer.Simple(10,function() if IsValid(ping) then ping:Remove() end end)
								end
							end
						end)
					end
					if SERVER then return self:TakeSubammo(item,1) end
				end
			if SERVER then
				ScavData.CollectFuncs["models/weapons/w_garand.mdl"] = function(self,ent) return {{ScavData.FormatModelname(ent:GetModel()),8,0}} end
			end
			tab.Cooldown = 0.74
		ScavData.RegisterFiremode(tab,"models/weapons/w_garand.mdl")

--[[==============================================================================================
	--M1903 Springfield
==============================================================================================]]--
		
		local tab = {}
			tab.Name = "#scav.scavcan.springfield"
			tab.anim = ACT_VM_SECONDARYATTACK
			tab.Level = 2
			tab.MaxAmmo = 15
			tab.FireFunc = function(self,item)
				local bullet = {}
					bullet.Num = 1
					bullet.Spread = self.Owner:GetVelocity():LengthSqr() < WALK_SPEED and Vector(0.06,0.06,0) or Vector(0.16,0.16,0)
					bullet.Tracer = 1
					bullet.Force = 5
					bullet.Damage = 120
					bullet.TracerName = "ef_scav_tr_b"
					bullet.Src = self.Owner:GetShootPos()
					bullet.Dir = self:GetAimVector()
				self.Owner:ScavViewPunch(Angle(-3,math.Rand(-0.2,0.2),0),0.4,true)
				if CLIENT then self.Owner:SetEyeAngles((vector_up*0.05+self:GetAimVector()):Angle()) end
				if SERVER or not game.SinglePlayer() then
					self.Owner:FireBullets(bullet)
				end
				self:MuzzleFlash2()
				self.Owner:SetAnimation(PLAYER_ATTACK1)
				self.Owner:EmitSound("Weapon_Springfield.Shoot")
				timer.Simple(.5,function()
					if CLIENT then
						self.Owner:EmitSound("Weapon_K98.BoltBack1")
						timer.Simple(.2,function() self.Owner:EmitSound("Weapon_K98.BoltBack2") end)
						timer.Simple(.6,function() self.Owner:EmitSound("Weapon_K98.BoltForward2") end)
					end
					dodsshelleject(self)
				end)
				if SERVER then
					return self:TakeSubammo(item,1)
				end
			end
			if SERVER then
				ScavData.CollectFuncs["models/weapons/w_spring.mdl"] = function(self,ent) return {{ScavData.FormatModelname(ent:GetModel()),5,0}} end
			end
			tab.Cooldown = 1.85
		ScavData.RegisterFiremode(tab,"models/weapons/w_spring.mdl")

--[[==============================================================================================
	--M1911
==============================================================================================]]--
		
		local tab = {}
			tab.Name = "#scav.scavcan.m1911"
			tab.anim = ACT_VM_PRIMARYATTACK
			tab.Level = 2
			local identify = {}
			tab.Identify = setmetatable(identify, {__index = function() return 0 end} )
			tab.MaxAmmo = 21
			tab.FireFunc = function(self,item)
				local bullet = {}
						bullet.Num = 1
						bullet.Spread = self.Owner:GetVelocity():LengthSqr() < WALK_SPEED and Vector(0.055,0.055,0) or Vector(0.155,0.155,0)
						bullet.Tracer = 1
						bullet.Force = 5
						bullet.Damage = 40
						bullet.TracerName = "ef_scav_tr_b"
				self.Owner:ScavViewPunch(Angle(-0.5,math.Rand(-0.2,0.2),0),0.2)
				if CLIENT then self.Owner:SetEyeAngles((vector_up*0.05+self:GetAimVector()):Angle()) end
				bullet.Src = self.Owner:GetShootPos()
				bullet.Dir = self:GetAimVector()
				if SERVER or not game.SinglePlayer() then
					self.Owner:FireBullets(bullet)
				end
				self:MuzzleFlash2()
				self.Owner:SetAnimation(PLAYER_ATTACK1)
				self.Owner:EmitSound("Weapon_Colt.Shoot")
				self.nextfireearly = CurTime()+0.1
				dodsshelleject(self,"small")
				if SERVER then
					return self:TakeSubammo(item,1)
				end
			end
			tab.OnArmed = function(self,item,olditemname)
				end
			if SERVER then
				ScavData.CollectFuncs["models/weapons/w_colt.mdl"] = function(self,ent) return {{ScavData.FormatModelname(ent:GetModel()),7,0}} end
				ScavData.CollectFuncs["models/player/american_assault.mdl"] = function(self,ent) return {{"models/weapons/w_colt.mdl",7,0}} end
			end
			tab.Cooldown = 0.3
		ScavData.RegisterFiremode(tab,"models/weapons/w_colt.mdl")

--[[==============================================================================================
	--MG42
==============================================================================================]]--
		
		if SERVER then util.AddNetworkString("scv_setheat") end
		--PrecacheParticleSystem("grenadetrail")

		local tab = {}
			tab.Name = "#scav.scavcan.mg42"
			tab.anim = ACT_VM_FIDGET
			tab.chargeanim = ACT_VM_IDLE
			tab.Level = 2
			local identify = {}
			tab.Identify = setmetatable(identify, {__index = function() return 0 end} )
			tab.MaxAmmo = 500
			tab.Heat = 0
			tab.Overheated = false
			--tab.Particle = nil
			local function mgcooloff(self,item)
				if item then
					local tbl = item:GetFiremodeTable()
					if not (self:ProcessLinking(item) and self:StopChargeOnRelease()) then
						if tbl.Heat > 0 then
							if SERVER then
								tbl.Heat = math.max(0,tbl.Heat - 1)
								net.Start("scv_setheat")
									net.WriteEntity(self)
									net.WriteInt(tbl.Heat, 8)
									net.WriteBool(tbl.Overheated)
								net.Send(self.Owner)
							elseif IsFirstTimePredicted() then
								net.Receive("scv_setheat", function()
									local self = net.ReadEntity()
									--fuck you if you think we're getting an error here
									if IsValid(self) and
										self.inv and
										self.inv.items and
										#self.inv.items > 0 and
										self.inv.items[1] and
										ScavData.models[self.inv.items[1].ammo] and
										ScavData.models[self.inv.items[1].ammo].Name == "#scav.scavcan.mg42" then
											self.inv.items[1]:GetFiremodeTable().Heat = net.ReadInt(8)
											--item.Heat = self.inv.items[1]:GetFiremodeTable().Heat
											self.inv.items[1]:GetFiremodeTable().Overheated = net.ReadBool()
											--item.Overheated = self.inv.items[1]:GetFiremodeTable().Overheated
									end
								end)
							end
							timer.Simple(0.05, function() mgcooloff(self,item) end)
						else
							tbl.Overheated = false
							--[[if CLIENT and IsValid(tab.Particle) then
								tab.Particle:StopEmission(true,false)
							end]]
						end
						--print(tbl.Heat .. " " .. tostring(tbl.Overheated))
					end
					if SERVER then
						self:SetBlockPoseInstant(tbl.Heat/100)
					end
				end
			end
			tab.ChargeAttack = function(self,item)
				if self.Owner:KeyDown(IN_ATTACK) then
					local tbl = item:GetFiremodeTable()
					if SERVER then
						if tbl.Heat >= 100 then
							tbl.Heat = 100
							tbl.Overheated = true
						end
						net.Start("scv_setheat")
							net.WriteEntity(self)
							net.WriteInt(tbl.Heat, 8)
							net.WriteBool(tbl.Overheated)
						net.Send(self.Owner)
					else
						net.Receive("scv_setheat", function()
							local self = net.ReadEntity()
							--or here
							if IsValid(self) and
								self.inv and
								self.inv.items and
								#self.inv.items > 0 and
								self.inv.items[1] and
								ScavData.models[self.inv.items[1].ammo] and
								ScavData.models[self.inv.items[1].ammo].Name == "#scav.scavcan.mg42" then 
									self.inv.items[1]:GetFiremodeTable().Heat = net.ReadInt(8)
									--item.Heat = self.inv.items[1]:GetFiremodeTable().Heat
									self.inv.items[1]:GetFiremodeTable().Overheated = net.ReadBool()
									--item.Overheated = self.inv.items[1]:GetFiremodeTable().Overheated
							end
						end)
						--if tbl.Overheated == true then
							--if IsValid(tbl.Particle) then
							--	tbl.Particle:Restart()
							--else
							--	tbl.Particle = CreateParticleSystem(self,"grenadetrail",PATTACH_POINT_FOLLOW,0,0)
							--end
						--end
					end
					if not tbl.Overheated then
						tbl.Heat = math.min(100,tbl.Heat + 1)
						local bullet = {}
							bullet.Num = 1
							if self.Owner:GetVelocity():LengthSqr() < WALK_SPEED then
								if self.Owner:Crouching() and self.Owner:GetVelocity():LengthSqr() < PRONE_SPEED then
									bullet.Spread = Vector(0.1,0.1,0) --"true" spread for bipod is .025 in DoD, but this player has a lot more freedom of movement and can aim anywhere
									if CLIENT then self.Owner:SetEyeAngles((vector_up*0.01+self:GetAimVector()):Angle()) end
								else
									bullet.Spread = Vector(0.2,0.2,0)
									if CLIENT then self.Owner:SetEyeAngles((vector_up*0.05+self:GetAimVector()):Angle()) end
								end
							else
								bullet.Spread = Vector(0.3,0.3,0)
								if CLIENT then self.Owner:SetEyeAngles((vector_up*0.05+self:GetAimVector()):Angle()) end
							end
							bullet.Tracer = 1
							bullet.Force = 5
							bullet.Damage = 85
							bullet.TracerName = "ef_scav_tr_b"
							bullet.Src = self.Owner:GetShootPos()
							bullet.Dir = self:GetAimVector()
						--self.Owner:ScavViewPunch(Angle(-5,math.Rand(-0.2,0.2),0),0.5,true) --TODO: DoD:S viewpunch
						self.Owner:ScavViewPunch(Angle(-0.7,math.Rand(-0.4,0.4),0),0.2,true)
						if SERVER or not game.SinglePlayer() then
							self.Owner:FireBullets(bullet)
						end
						self:MuzzleFlash2()
						self.Owner:SetAnimation(PLAYER_ATTACK1)
						dodsshelleject(self)
						if SERVER then
							self.Owner:EmitSound("Weapon_Mg42.Shoot")
							self:SetPanelPoseInstant(0.25,2)
							self:TakeSubammo(item,1)
						end
					end
					if SERVER then
						self:SetBlockPoseInstant(tbl.Heat/100)
					--elseif not IsValid(tab.Particle) then
					--	tab.Particle = CreateParticleSystem(self,"grenadetrail",PATTACH_POINT_FOLLOW,0,0)
					--end
					end
				end
				local continuefiring = self:ProcessLinking(item) and self:StopChargeOnRelease()
				if not continuefiring then
					timer.Simple(0.25, function() mgcooloff(self,item) end)
					if SERVER then
						self:SetChargeAttack()
						self:SetBarrelRestSpeed(0)
					end
				end
				return 0.05
			end
			tab.FireFunc = function(self,item)
				self:SetChargeAttack(tab.ChargeAttack,item)
				if SERVER then
					self:SetBarrelRestSpeed(1000)
				end
				return false
			end
			if SERVER then
				ScavData.CollectFuncs["models/weapons/w_mg42bd.mdl"] = function(self,ent) return {{ScavData.FormatModelname(ent:GetModel()),250,0}} end
				ScavData.CollectFuncs["models/weapons/w_mg42bu.mdl"] = function(self,ent) return {{ScavData.FormatModelname(ent:GetModel()),250,0}} end
				ScavData.CollectFuncs["models/weapons/w_mg42pr.mdl"] = function(self,ent) return {{ScavData.FormatModelname("models/weapons/w_mg42bd.mdl"),250,0}} end
				ScavData.CollectFuncs["models/weapons/w_mg42sr.mdl"] = ScavData.CollectFuncs["models/weapons/w_mg42pr.mdl"]
			else
				--Add cooldown bar to the existing status screen
				tab.ScreenAdd = function(self, item)
					local item2 = self.inv.items[1]:GetFiremodeInfo()
					if item2 then
						surface.SetDrawColor(0,0,0)
						surface.DrawOutlinedRect(75,78,106,14,2)
						surface.DrawRect(78,81,item2.Heat,8)
					end
				end
			end
			tab.Cooldown = 0
		ScavData.RegisterFiremode(tab,"models/weapons/w_mg42bd.mdl")
		ScavData.RegisterFiremode(tab,"models/weapons/w_mg42bu.mdl")
		
--[[==============================================================================================
	--MP40
==============================================================================================]]--
		
		local tab = {}
			tab.Name = "#scav.scavcan.mp40"
			tab.anim = ACT_VM_FIDGET
			tab.chargeanim = ACT_VM_RECOIL1
			tab.Level = 2
			tab.MaxAmmo = 96
			tab.ChargeAttack = function(self,item)
				if self.Owner:KeyDown(IN_ATTACK) then
					local bullet = {}
						bullet.Num = 1
						bullet.Spread = self.Owner:GetVelocity():LengthSqr() < WALK_SPEED and Vector(0.055,0.055,0) or Vector(0.155,0.155,0)
						bullet.Tracer = 1
						bullet.Force = 5
						bullet.Damage = 40
						bullet.TracerName = "ef_scav_tr_b"
						bullet.Src = self.Owner:GetShootPos()
						bullet.Dir = self:GetAimVector()
					self.Owner:ScavViewPunch(Angle(-0.5,math.Rand(-0.2,0.2),0),0.1,true)
					if CLIENT then self.Owner:SetEyeAngles((vector_up*0.05+self:GetAimVector()):Angle()) end
					if SERVER or not game.SinglePlayer() then
						self.Owner:FireBullets(bullet)
					end
					self:MuzzleFlash2()
					self.Owner:SetAnimation(PLAYER_ATTACK1)
					self.Owner:EmitSound("Weapon_MP40.Shoot")
					dodsshelleject(self,"small")
					if SERVER then
						self:TakeSubammo(item,1)
					end
				end
				local continuefiring = self:ProcessLinking(item) and self:StopChargeOnRelease()
				if not continuefiring then
					if SERVER then
						self:SetChargeAttack()
						self:SetBarrelRestSpeed(0)
					end
				end
				return 0.09
			end
			tab.FireFunc = function(self,item)
				self:SetChargeAttack(tab.ChargeAttack,item)
				if SERVER then
					self:SetBarrelRestSpeed(250)	
				end								
				return false
			end
			if SERVER then
				ScavData.CollectFuncs["models/weapons/w_mp40.mdl"] = function(self,ent) return {{ScavData.FormatModelname(ent:GetModel()),32,0}} end
			end
			tab.Cooldown = 0
		ScavData.RegisterFiremode(tab,"models/weapons/w_mp40.mdl")

--[[==============================================================================================
	--MP44
==============================================================================================]]--
		
		local tab = {}
			tab.Name = "#scav.scavcan.mp44"
			tab.anim = ACT_VM_FIDGET
			tab.chargeanim = ACT_VM_RECOIL1
			tab.Level = 2
			tab.MaxAmmo = 90
			tab.ChargeAttack = function(self,item)
				if self.Owner:KeyDown(IN_ATTACK) then
					local bullet = {}
						bullet.Num = 1
						bullet.Spread = self.Owner:GetVelocity():LengthSqr() < WALK_SPEED and Vector(0.025,0.025,0) or Vector(0.125,0.125,0)
						bullet.Tracer = 1
						bullet.Force = 5
						bullet.Damage = 50
						bullet.TracerName = "ef_scav_tr_b"
						bullet.Src = self.Owner:GetShootPos()
						bullet.Dir = self:GetAimVector()
					self.Owner:ScavViewPunch(Angle(-0.5,math.Rand(-0.2,0.2),0),0.1,true)
					if CLIENT then self.Owner:SetEyeAngles((vector_up*0.05+self:GetAimVector()):Angle()) end
					if SERVER or not game.SinglePlayer() then
						self.Owner:FireBullets(bullet)
					end
					self:MuzzleFlash2()
					self.Owner:SetAnimation(PLAYER_ATTACK1)
					self.Owner:EmitSound("Weapon_MP44.Shoot")
					dodsshelleject(self,"medium")
					if SERVER then
						self:TakeSubammo(item,1)
					end
				end
				local continuefiring = self:ProcessLinking(item) and self:StopChargeOnRelease()
				if not continuefiring then
					if SERVER then
						self:SetChargeAttack()
						self:SetBarrelRestSpeed(0)
					end
				end
				return 0.12
			end
			tab.FireFunc = function(self,item)
				self:SetChargeAttack(tab.ChargeAttack,item)
				if SERVER then
					self:SetBarrelRestSpeed(250)	
				end								
				return false
			end
			if SERVER then
				ScavData.CollectFuncs["models/weapons/w_mp44.mdl"] = function(self,ent) return {{ScavData.FormatModelname(ent:GetModel()),30,0}} end
			end
			tab.Cooldown = 0
		ScavData.RegisterFiremode(tab,"models/weapons/w_mp44.mdl")

--[[==============================================================================================
	--P38
==============================================================================================]]--
		
		local tab = {}
			tab.Name = "#scav.scavcan.p38"
			tab.anim = ACT_VM_PRIMARYATTACK
			tab.Level = 2
			tab.MaxAmmo = 24
			tab.FireFunc = function(self,item)
				local bullet = {}
					bullet.Num = 1
					bullet.Spread = self.Owner:GetVelocity():LengthSqr() < WALK_SPEED and Vector(0.055,0.055,0) or Vector(0.155,0.155,0)
					bullet.Tracer = 1
					bullet.Force = 5
					bullet.Damage = 40
					bullet.TracerName = "ef_scav_tr_b"
					bullet.Src = self.Owner:GetShootPos()
					bullet.Dir = self:GetAimVector()
				self.Owner:ScavViewPunch(Angle(-0.5,math.Rand(-0.2,0.2),0),0.2)
				if CLIENT then self.Owner:SetEyeAngles((vector_up*0.05+self:GetAimVector()):Angle()) end
				if SERVER or not game.SinglePlayer() then
					self.Owner:FireBullets(bullet)
				end
				self:MuzzleFlash2()
				self.Owner:SetAnimation(PLAYER_ATTACK1)
				self.Owner:EmitSound("Weapon_Luger.Shoot")
				self.nextfireearly = CurTime()+0.1
				dodsshelleject(self,"small")
				if SERVER then
					return self:TakeSubammo(item,1)
				end
			end
			if SERVER then
				ScavData.CollectFuncs["models/weapons/w_p38.mdl"] = function(self,ent) return {{ScavData.FormatModelname(ent:GetModel()),8,0}} end
			end
			tab.Cooldown = 0.3
		ScavData.RegisterFiremode(tab,"models/weapons/w_p38.mdl")

--[[==============================================================================================
	--Tommy Gun
==============================================================================================]]--
		
		local tab = {}
			tab.Name = "#scav.scavcan.tommy"
			tab.anim = ACT_VM_FIDGET
			tab.chargeanim = ACT_VM_RECOIL1
			tab.Level = 2
			tab.MaxAmmo = 90
			tab.ChargeAttack = function(self,item)
				if self.Owner:KeyDown(IN_ATTACK) then
					local bullet = {}
						bullet.Num = 1
						bullet.Spread = self.Owner:GetVelocity():LengthSqr() < WALK_SPEED and Vector(0.055,0.055,0) or Vector(0.155,0.155,0)
						bullet.Tracer = 1
						bullet.Force = 5
						bullet.Damage = 40
						bullet.TracerName = "ef_scav_tr_b"
						bullet.Src = self.Owner:GetShootPos()
						bullet.Dir = self:GetAimVector()
					self.Owner:ScavViewPunch(Angle(-0.5,math.Rand(-0.2,0.2),0),0.1,true)
					if CLIENT then self.Owner:SetEyeAngles((vector_up*0.05+self:GetAimVector()):Angle()) end
					if SERVER or not game.SinglePlayer() then
						self.Owner:FireBullets(bullet)
					end
					self:MuzzleFlash2()
					self.Owner:SetAnimation(PLAYER_ATTACK1)
					self.Owner:EmitSound("Weapon_Thompson.Shoot")
					dodsshelleject(self,"small")
					if SERVER then
						self:TakeSubammo(item,1)
					end
				end
				local continuefiring = self:ProcessLinking(item) and self:StopChargeOnRelease()
				if not continuefiring then
					if SERVER then
						self:SetChargeAttack()
						self:SetBarrelRestSpeed(0)
					end
				end
				return 0.085
			end
			tab.FireFunc = function(self,item)
				self:SetChargeAttack(tab.ChargeAttack,item)
				if SERVER then
					self:SetBarrelRestSpeed(500)	
				end								
				return false
			end
			if SERVER then
				ScavData.CollectFuncs["models/weapons/w_thompson.mdl"] = function(self,ent) return {{ScavData.FormatModelname(ent:GetModel()),30,0}} end
			end
			tab.Cooldown = 0
		ScavData.RegisterFiremode(tab,"models/weapons/w_thompson.mdl")
