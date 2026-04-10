local PLAYER = FindMetaTable("Player")

AddCSLuaFile()
DEFINE_BASECLASS("gamemode_base")

--local PLAYER = {} --todo: player class definition shouldn't be adding to Player metatable

if CLIENT then
	--recreated convars from sandbox
	CreateConVar("cl_playercolor", "0.24 0.34 0.41", {FCVAR_ARCHIVE, FCVAR_USERINFO, FCVAR_DONTRECORD}, "The value is a Vector - so between 0-1 - not between 0-255")
	CreateConVar("cl_weaponcolor", "0.30 1.80 2.10", {FCVAR_ARCHIVE, FCVAR_USERINFO, FCVAR_DONTRECORD}, "The value is a Vector - so between 0-1 - not between 0-255")
	CreateConVar("cl_playerskin", "0", {FCVAR_ARCHIVE, FCVAR_USERINFO, FCVAR_DONTRECORD}, "The skin to use, if the model has any")
	CreateConVar("cl_playerbodygroups", "0", {FCVAR_ARCHIVE, FCVAR_USERINFO, FCVAR_DONTRECORD}, "The bodygroups to use, if the model has any")

	local pcolor = Vector(GetConVar("cl_playercolor"):GetString())
	local wcolor = Vector(GetConVar("cl_weaponcolor"):GetString())

	cvars.AddChangeCallback("cl_playercolor", function(convar, oldval, newval)
		pcolor = Vector(GetConVar(convar):GetString())
	end)

	cvars.AddChangeCallback("cl_weaponcolor", function(convar, oldval, newval)
		wcolor = Vector(GetConVar(convar):GetString())
	end)

	function PLAYER:GetPlayerColor()
		local t = self:Team()
		return team.IsReal(t) and team.GetColorVector(t) or pcolor
	end

	function PLAYER:GetWeaponColor()
		local t = self:Team()
		return team.IsReal(t) and team.GetColorVector(t) or wcolor
	end
end


function PLAYER:IsSpectator()
	return (not team.IsReal(self:Team(), true) or (not self:Alive() and (self:Lives() == 0)))
end

--lives

function PLAYER:Lives()
	return self:GetNWInt("lives")
end

function PLAYER:AddLives(add)
	local a = tonumber(add)
	if a == 0 then return end 
	if not a then return ErrorNoHaltWithStack("Warning! Tried to add non-number '" .. tostring(add) .. "' to " .. self:Nick() .. "'s lives!") end

	local lives = self:Lives()
	--player lives < 0 means the player isn't using lives, don't add them
	if lives < 0 then return end

	self:SetLives(math.max(0, math.Round(lives + a)))
end

function PLAYER:SetLives(lives)
	local l = tonumber(lives)
	if not l then return ErrorNoHaltWithStack("Warning! Tried to set " .. self:Nick() .. "'s lives to non-number '" .. tostring(lives) .. "'!") end

	self:SetNWInt("lives", math.max(-1, math.Round(l)))
end

if SERVER then
	function GM:PlayerUse(pl, ent)
		return pl:Alive()
	end
	
	function GM:PlayerInitialSpawn(pl)
		pl:SetLives(-1)
		gamemode.Call("PlayerJoinTeam", pl, TEAM_SPECTATOR)
		self:SendPlayerTeams(pl)
		pl:KillSilent()
	end

	--helper function, returns default if var matches a noset value (noset can be a function that takes var, return true to use default)
	local function setifnotnoset(var, noset, default)
		if isfunction(noset) then
			return noset(var) and default or var
		end
		return var == noset and default or var
	end

	local function not_positive(a)
		return a <= 0
	end

	--Set player's health regen rate, in amt per second. Can be negative to apply a health drain.
	function PLAYER:SetHealthRegen(amt)
		self.hpregenrate = amt
		local regenname = tostring(self) .. "_hpregen"

		if self.hpregenrate == 0 then
			timer.Remove(regenname)
			return
		end

		local function hpregen()
			if not IsValid(self) or not self:Alive() or self.hpregenrate == 0 then return timer.Remove(regenname) end

			local change = self.hpregenrate > 0 and 1 or -1
			local newhp = self:Health() + change
			if newhp <= 0 then return self:Kill() end

			timer.Create(regenname, 1 / math.abs(self.hpregenrate), 1, hpregen)
			self:SetHealth(math.min(newhp, self:GetMaxHealth()))
		end

		timer.Create(regenname, 1 / math.abs(self.hpregenrate), 1, hpregen)
	end

	--Set player's armor regen rate, in amt per second. Can be negative to apply an armor drain.
	function PLAYER:SetArmorRegen(amt)
		self.armorregenrate = amt
		local regenname = tostring(self) .. "_armorregen"

		if self.armorregenrate == 0 then
			timer.Remove(regenname)
			return
		end

		local function armorregen()
			if not IsValid(self) or not self:Alive() or self.armorregenrate == 0 then return timer.Remove(regenname) end

			local change = self.armorregenrate > 0 and 1 or -1
			local newarmor = self:Armor() + change

			timer.Create(regenname, 1 / math.abs(self.armorregenrate), 1, armorregen)
			self:SetArmor(math.max(0, math.min(newarmor, self:GetMaxArmor())))
		end

		timer.Create(regenname, 1 / math.abs(self.armorregenrate), 1, armorregen)
	end

	function GM:PlayerSpawn(pl, transition)

		player_manager.SetPlayerClass(pl, "player_sdm")
		BaseClass.PlayerSpawn(self, pl, transition)

		if pl:Team() == TEAM_SPECTATOR then
			pl:SetMoveType(MOVETYPE_NOCLIP)
			pl:Spectate(OBS_MODE_ROAMING)
			pl:KillSilent()
			return true
		end
		pl:UnSpectate()

		pl:SetCharacterFromModel()
		pl:SetChargeRateDelayed(5, 1)
		pl:SetEnergy(pl:GetMaxEnergy())
		pl:SetWalkSpeed(250)
		pl:SetRunSpeed(400)
		pl:SetStepSize(24)
		pl:SetJumpPower(275)

		local teamrules = team.GetInfoEnt(pl:Team())
		if not IsValid(teamrules) then return end

		pl:SetMaxHealth(setifnotnoset(teamrules:GetMaxHealth(), not_positive, 100))
		pl:SetHealth(setifnotnoset(teamrules:GetStartingHealth(), not_positive, 100))
		pl:SetHealthRegen(teamrules:GetHealthRegen())
		pl:SetMaxArmor(setifnotnoset(teamrules:GetMaxArmor(), not_positive, 100))
		pl:SetArmor(setifnotnoset(teamrules:GetStartingArmor(), not_positive, 0))
		pl:SetArmorRegen(teamrules:GetArmorRegen())

		pl:SetMaxEnergy(setifnotnoset(teamrules:GetMaxEnergy(), not_positive, 100), true)
		pl:SetEnergy(setifnotnoset(teamrules:GetStartingEnergy(), not_positive, 100), true)
		pl:SetChargeRate(setifnotnoset(teamrules:GetEnergyRegen(), not_positive, 5), true)
	end
	
	function GM:PlayerCanSpawn(pl)
		local pteam = pl:Team()
		if not team.IsReal(pteam, true) then return false end

		local ctime = CurTime()
		local spawndelay = (pl.NextSpawnTime or 0) - ctime
		local enoughlives = pl:Lives() ~= 0

		local teamrules = team.GetInfoEnt(pteam)
		--if we're using pooled lives, or the player is on a team not using lives but came from one that did before, we don't actually care what their lives count is
		if IsValid(teamrules) then
			local teamlives = teamrules:GetLives()
			local pooled = teamrules:GetPooledLives()
			if teamlives <= 0 then enoughlives = (not pooled) end
			if pooled and teamlives > 0 then enoughlives = true end
		end
		return spawndelay <= 0 and enoughlives
	end

	function GM:PlayerDeathThink(pl)
		if not self:PlayerCanSpawn(pl) then return false end

		return BaseClass:PlayerDeathThink(pl)
	end
	
	local spawnpoints
	
	function GM:GenerateSpawnPointList()
		spawnpoints = ents.FindByClass("info_sdm_spawn")
	end
	
	hook.Add("OnGLoaderSpawn", "RefreshSpawnPoints", function()
		gamemode.Call("GenerateSpawnPointList")
	end)
	
	function GM:ShuffleSpawnPointList()
		table.Shuffle(spawnpoints)
	end
	
	function GM:PlayerSelectSpawn(pl)
		table.Shuffle(spawnpoints)
		for _, v in pairs(spawnpoints) do
			if v:PlayerCanSpawn(pl) then
				return v
			end
		end
		for _, v in pairs(spawnpoints) do
			v:SpawnFrag()
			--if not v:PlayerCanSpawn(pl) then continue end
			return v
		end
		--MsgAll("WARNING! NO VALID SPAWN POINTS!")
	end
	
	hook.Add("PlayerInitialSpawn", "AddDashValues", function(pl)
		pl.LastDirection = 0
		pl.LastDirectionPress = 0
		pl.Dashing = false
		pl.DashHitGround = 0
		pl.LastAttack = 0
	end)
else
	hook.Add("InitPostEntity", "AddDashValues", function()
		local pl = LocalPlayer()
		pl.LastDirection = 0
		pl.LastDirectionPress = 0
		pl.Dashing = false
		pl.DashHitGround = 0
		pl.LastAttack = 0
	end)
end


function GM:KeyRelease(pl, key)
	if pl:Alive() and ((key == IN_ATTACK) or (key == IN_ATTACK2)) and not pl:KeyDown(IN_ATTACK) and not pl:KeyDown(IN_ATTACK2)  then
		pl.Attacking = false
		pl.LastAttack = CurTime()
	end
--[[
	if pl:KeyDown(IN_FORWARD) or pl:KeyDown(IN_BACK) or pl:KeyDown(IN_MOVELEFT) or pl:KeyDown(IN_MOVERIGHT) then
		return
	end
	if (key == IN_FORWARD) or (key == IN_BACK) or (key == IN_MOVELEFT) or (key == IN_MOVERIGHT) then
		pl.LastDirectionRelease = CurTime()
		pl.LastDirection = key
	end
	]]
end

--local dash_value = 500

function GM:KeyPress(pl, key)
	if CLIENT and not IsFirstTimePredicted() then
		return
	end
	if key == IN_SPEED then
		pl.NoSprintUntilNextSprintPress = false
	end
	if pl:Alive() and ((key == IN_ATTACK) or (key == IN_ATTACK2)) then
		pl.Attacking = true
	end
	if pl:Alive() and (key == IN_JUMP) and (pl:GetGroundEntity() ~= NULL) then
		--pl:PlaySDMSound("Jump", false, nil, true, true)
		pl:GetCharacter():HandleJump(pl)
	end
	--[[
	if pl.Dashing then
		return
	end
	local dashscale = CurTime() - pl.DashHitGround
	if (dashscale > 0.5) and (pl:GetGroundEntity() ~= NULL) and (CurTime() - pl.LastDirectionPress < 0.5) and (key == pl.LastDirection) then
		dashscale = math.Min(dashscale, 1)
		pl:SetGroundEntity(NULL)
		--pl:SetVelocity(Vector(0, 0, 10000))
		if pl.LastDirection == IN_FORWARD then
			local vec = pl:GetForward()*dash_value*dashscale
			vec.z = 100
			pl:SetVelocity(vec)
		elseif pl.LastDirection == IN_BACK then
			local vec = pl:GetForward()*dash_value*-1*dashscale
			vec.z = 100
			pl:SetVelocity(vec)
		elseif pl.LastDirection == IN_MOVERIGHT then
			local vec = pl:GetRight()*dash_value*dashscale
			vec.z = 100
			pl:SetVelocity(vec)
		elseif pl.LastDirection == IN_MOVELEFT then
			local vec = pl:GetRight()*dash_value*-1*dashscale
			vec.z = 100
			pl:SetVelocity(vec)
		end
		]]
		--[[
		if CLIENT then
			print("CLIENT: "..tostring(pl)..", "..tostring(pl:GetPos())..", "..CurTime()..", "..tostring(pl:GetVelocity()))
		else
			print("SERVER: "..tostring(pl)..", "..tostring(pl:GetPos())..", "..CurTime()..", "..tostring(pl:GetVelocity()))
		end
		]]
		--[[
		gamemode.Call("DoAnimationEvent", pl, PLAYERANIMEVENT_JUMP)
		if SERVER then
			pl:EmitSound("player/suit_sprint.wav")
		end
		pl.Dashing = true
	end
	]]
	--if pl:KeyDown(IN_FORWARD) or pl:KeyDown(IN_BACK) or pl:KeyDown(IN_MOVELEFT) or pl:KeyDown(IN_MOVERIGHT) then
	--	return
	--end
	--[[
	if (key == IN_FORWARD) or (key == IN_BACK) or (key == IN_MOVELEFT) or (key == IN_MOVERIGHT) then
		pl.LastDirectionPress = CurTime()
		pl.LastDirection = key
	end
	]]
end


if CLIENT then
	function PLAYER:SetVelocity(vel)
		self.ClientVel = self.ClientVel or Vector()
		self.ClientVel = self.ClientVel + vel
	end
end

function GM:OnPlayerHitGround(pl, inwater, onfloater, fallspeed)
	if pl.Dashing then
		pl.Dashing = false
		pl.DashHitGround = CurTime()
	end
	if CLIENT then
		pl.landingtime = CurTime()
		pl.landingspeed = fallspeed
	end
end

function GM:Move(pl, movedata)
	--[[
	if CLIENT then
		if IsFirstTimePredicted() then
			pl.ClientVel2 = nil
		end
		if pl.ClientVel then
			pl.ClientVel2 = pl.ClientVel
			pl.ClientVel = nil
		end
		if pl.ClientVel2 then
			movedata:SetVelocity(movedata:GetVelocity() + pl.ClientVel2)
		end
	end
	local dashrecoverscale = CurTime() - pl.DashHitGround
	if dashrecoverscale < 1 then
		movedata:SetForwardSpeed(movedata:GetForwardSpeed()*dashrecoverscale)
		movedata:SetSideSpeed(movedata:GetSideSpeed()*dashrecoverscale)
	end
	movedata:SetConstraintRadius(2000)
	]]
	--movedata:SetMaxSpeed(2000)
	--movedata:SetMaxClientSpeed(2000)
	local wep = pl:GetActiveWeapon()
	local attacktime = 0
	if IsValid(wep) then
		attacktime = math.max(wep:GetNextPrimaryFire(), wep:GetNextSecondaryFire())
	end
	local ctime = CurTime()
	if pl:Alive() and not pl.NoSprintUntilNextSprintPress and pl:KeyDown(IN_SPEED) and (pl.sprinting or ((ctime - attacktime > 1) and not pl.Attacking)) and pl:GetEnergy() > 20 * FrameTime() then
		if (pl:GetGroundEntity() ~= NULL) then
			if not pl.sprinting then
				if CLIENT then
					pl:EmitSound("player/suit_sprint.wav")
				else
					pl:SprintEnable()
				end
				pl.sprinting = true
			end
			pl:SetEnergy(pl:GetEnergy() - 20 * FrameTime())
		end
		if IsValid(wep) and (attacktime <= ctime) then
			wep:SetNextPrimaryFire(ctime + 1)
			wep:SetNextSecondaryFire(ctime + 1)
		end
	else
		if pl.sprinting and SERVER then pl:SprintDisable() end
		pl.NoSprintUntilNextSprintPress = true
		pl.sprinting = false
	end
	
	return movedata
end

CreateClientConVar("sdm_footsteps_enabled", 1, true, false)
function GM:PlayerFootstep(pl, pos, foot, sound, volume, rf)
	if SERVER then
		return pl:GetCharacter():HandleFootstep(pl, pos, foot, sound, volume, rf)
	else
		if GetConVarNumber("sdm_footsteps_enabled") == 0 then
			return true
		end
		return pl:GetCharacter():HandleFootstep(pl, pos, foot, sound, volume, rf)
		--[[
		if not pl.lastfoot then
			pl.lastfoot = 0
		end
		local model = ScavData.FormatModelname(pl:GetModel())
		local modeltype = PlayerModelTypes[model]
		local volbonus = 0

		pl.lastfoot = 1 - pl.lastfoot
		if PlayerSounds[modeltype] then
			if (pl.lastfoot == 0) and PlayerSounds[modeltype].FootLeft then
				pl:PlaySDMSoundNoQueue("LeftFoot")
				return
			elseif PlayerSounds[modeltype].FootRight then
				pl:PlaySDMSoundNoQueue("RightFoot")
				return
			end
		end
		
		if pl == LocalPlayer() then
			volbonus = 10
		end

		if (model == "models/police.mdl") or (model == "models/player/police.mdl") or (model == "models/player/barney.mdl") then
			pl:EmitSound("npc/metropolice/gear"..math.random(1, 3) + 3*pl.lastfoot..".wav", 30 + volbonus)
		elseif modeltype == PLAYERMODEL_COMBINE then
			pl:EmitSound("npc/combine_soldier/gear"..math.random(1, 3) + 3*pl.lastfoot..".wav", 37 + volbonus)
		end
		if modeltype == PLAYERMODEL_ZOMBIE then
			--if (model == "models/player/zombie_soldier.mdl") then
			--	pl:EmitSound("npc/zombine/gear"..math.random(1, 3)..".wav", 36 + volbonus)
			--else
				pl:EmitSound("npc/zombie/foot"..math.random(1, 3)..".wav", 50 + volbonus)
			--end
		end
		]]
	end
	return true
end

if CLIENT then
	function GM:PlayerDeath(victim, killer, inflictor)
		if IsValid(victim) then
			timer.Simple(0.25, function() self.ScoreBoard:SortPlayerTeam(victim) end)
		end
		if IsValid(killer) and killer:IsPlayer() then
			timer.Simple(0.25, function() self.ScoreBoard:SortPlayerTeam(killer) end)
		end
	end

	net.Receive("sdm_playerdeath", function()
		local v = net.ReadEntity()
		local k = net.ReadEntity()
		--we don't use the inflictor (at the moment), so why bother networking it?
		--local i = net.ReadEntity()
		gamemode.Call("PlayerDeath", v, k, nil)--i)
	end)

	function GM:PlayerDisconnectedTeam(teamid) --Called when a team loses a player to a disconnect
		teamid = tonumber(teamid)
		timer.Simple(0.25, function() self.ScoreBoard:ValidateTeam(teamid) end)
	end

	net.Receive("sdm_disconnect", function()
		local plteam = net.ReadUInt(4) + 1000
		gamemode.Call("PlayerDisconnectedTeam", plteam)
	end)

	function GM:OnPlayerChangedTeam(pl, oldteam, newteam) 
		if IsValid(self.ScoreBoard) then
			timer.Simple(1, function() self.ScoreBoard:UpdatePlayerTeam(pl) end)
		end
	end
	usermessage.Hook("GMOnPlayerChangedTeam", function(um)
		local pl = um:ReadEntity()
		local oldteam = um:ReadShort()
		local newteam = um:ReadShort()
		gamemode.Call("OnPlayerChangedTeam", pl, oldteam, newteam)
	end)

	function GM:HUDDrawTargetID()
		local ent = LocalPlayer():GetEyeTrace().Entity
		if not IsValid(ent) or not ent:IsPlayer() then return false end
		
		local pteam = LocalPlayer():Team()
		local oteam = ent:Team()
		if pteam ~= oteam or pteam == TEAM_UNASSIGNED or oteam == TEAM_SPECTATOR then return false end

		return true
	end

else
	util.AddNetworkString("sdm_disconnect")
	util.AddNetworkString("sdm_playerdeath")

	hook.Add("PlayerDisconnected", "SDMTeamDisconnect", function(pl)
		local plteam = pl:Team()
		if not team.IsReal(plteam, true) then return end
		net.Start("sdm_disconnect")
			net.WriteUInt(plteam - 1000, 4) --save some bits, team enums start at 1001
		net.Broadcast()
		gamemode.Call("PlayerDisconnectedTeam", plteam)
	end)

	function GM:GetFallDamage(ply, vel)
		if self:GetGameVar("sdm_main_mod_falldmg") then
			local dmg = 0
			if vel > 700 then
				dmg = vel * 0.05
			end
			return dmg
		end
	end
	
	--[[function GM:PlayerTraceAttack(pl, dmginfo, dir, trace)
		if SERVER then
			gamemode.Call("ScalePlayerDamage", pl, trace.HitGroup, dmginfo) --this is a redundant call, the engine calls ScalePlayerDamage on its own
		end
		return true
	end]]
	
	function GM:ScalePlayerDamage(pl, hitgroup, dmginfo) 
		if hitgroup == HITGROUP_HEAD then
			dmginfo:ScaleDamage(2)
			if dmginfo:GetAttacker():IsPlayer() then
				umsg.Start("sdm_headshot", dmginfo:GetAttacker())
					umsg.Entity(pl)
					umsg.Vector(dmginfo:GetDamagePosition())
				umsg.End()
			end
		end
	end
	
	GM.ScaleNPCDamage = GM.ScalePlayerDamage

	function PLAYER:AddKills(amt)
		self:AddFrags(amt)
		self:AddScavStat(SCAVSTAT_FRAGS, amt)
		if GAMEMODE:GetMode() == SDM_MODE_DM_TEAM then
			local teamid = self:Team()
			team.AddScore(teamid, amt)
			local limit = team.GetScoreLimit(teamid)
			if limit ~= 0 and team.GetScore(teamid) >= limit then
				GAMEMODE:EndRoundTeam(teamid)
			end
		elseif GAMEMODE:GetMode() == SDM_MODE_DM then
			local limit = team.GetScoreLimit(teamid)
			if limit ~= 0 and self:Frags() >= limit then
				GAMEMODE:EndRoundPlayer(self)
			end
		end
	end

	function PLAYER:AddScore(amt)
		self:AddFrags(amt)
		self:AddScavStat(SCAVSTAT_POINTS, amt)
		if GAMEMODE:GetMode() == SDM_MODE_DM_TEAM or GAMEMODE:GetMode() == SDM_MODE_CTF then
			local teamid = self:Team()
			team.AddScore(teamid, amt)
			local limit = team.GetScoreLimit(teamid)
			if limit ~= 0 and team.GetScore(teamid) >= limit then
				GAMEMODE:EndRoundTeam(teamid)
			end
		elseif GAMEMODE:GetMode() == SDM_MODE_DM then
			local limit = team.GetScoreLimit(teamid)
			if limit ~= 0 and self:Frags() >= limit then
				GAMEMODE:EndRoundPlayer(self)
			end
		end
	end

	function GM:PlayerDeathSound()
		return true
	end
	
	local lastframe = 0
	function GM:DoPlayerDeath(victim, attacker, dmginfo)
		local newframe = true
		local inflictor
		if CurTime() == lastframe then
			newframe = false
		else
			lastframe = CurTime()
		end
		if IsValid(victim.killedby) then
			attacker = victim.killedby
			dmginfo:SetAttacker(attacker)
		end
		if IsValid(victim.killedbyinflictor) then
			inflictor = victim.killedbyinflictor
			dmginfo:SetInflictor(inflictor)
		end	
		local suicide = (attacker == victim)
		local friendlyfire = (IsValid(attacker) and attacker:IsPlayer() and victim:Team() ~= TEAM_UNASSIGNED and attacker:Team() == victim:Team())
		victim.fragsthislife = 0
		victim:AddScavStat(SCAVSTAT_DEATHS, 1)
		victim:AddDeaths(1)
		if not inflictor then
			inflictor = dmginfo:GetInflictor()
		end

		net.Start("sdm_playerdeath")
			net.WriteEntity(victim)
			net.WriteEntity(attacker)
			--net.WriteEntity(inflictor)
		net.Broadcast()

		if (IsValid(attacker) and attacker:IsPlayer()) then

			if suicide then
				attacker:AddScavStat(SCAVSTAT_SUICIDES, 1)
			end
			if suicide or friendlyfire then
				attacker:AddFrags(-1)
			else
				attacker.fragsthislife = (attacker.fragsthislife or 0) + 1
				attacker:GetCharacter():HandleTaunt(attacker, victim, attacker.fragsthislife)
				--[[
				if attacker.fragsthislife%5 == 0 then
					--attacker:PlaySDMSound("KillingSpree")
				elseif math.random(1, 4) == 1 then
					--attacker:PlaySDMSound("Taunt")
				end
				]]
				attacker:AddKills(1)
				if dmginfo:IsDamageType(DMG_BLAST) and IsValid(inflictor) then
					inflictor.BlastKills = (inflictor.BlastKills or 0) + 1
					if inflictor.BlastKills > 2 then
						attacker:AddScavAchievement(SCAVACHIEVEMENT_TRIPLEGIB, 1)
					end
				end
			end
		end

		if ((dmginfo:GetDamage() > 30) and dmginfo:IsExplosionDamage()) or (dmginfo:GetDamage() > 200) and not victim.nogib then
			local gib = ents.Create("scav_gib")
			gib:SetOwner(victim)
			gib:Spawn()
		else
			--victim:PlaySDMSound("Death", true)
			victim:GetCharacter():HandleDeath(victim, attacker, dmginfo)
			victim:CreateRagdoll()
			--victim:Spectate(OBS_MODE_IN_EYE)
			--victim:SpectateEntity(victim:GetRagdollEntity())
		end
		--if IsValid(attacker) then
		--	victim:Spectate(OBS_MODE_DEATHCAM)
		--	victim:SpectateEntity(attacker)
		--end
		victim:SetMoveType(MOVETYPE_NONE)
		
		victim:AddLives(-1)
		local livesleft = (victim:Lives() ~= 0)
		local spawndelay = 5

		local teamrules = team.GetInfoEnt(victim:Team())
		if IsValid(teamrules) then
			--handle pooled lives
			if teamrules:GetPooledLives() then
				local teamlives = teamrules:GetLives() - 1
				teamrules:SetLives(teamlives)
				livesleft = teamlives > 0
			--player might have their lives being tracked from a previous team with lives, while this one doesn't actively use them
			elseif teamrules:GetLives() <= 0 then
				livesleft = true
			end
			spawndelay = teamrules:GetSpawnDelay()
		end

		victim.NextSpawnTime = livesleft and (CurTime() + spawndelay) or math.huge
	end
end

local function GetAheadPlayer(pl1, pl2)
	return GM.teamstuff.sortbyfrags(pl1, pl2) and pl1 or pl2
end

local function GetBehindPlayer(pl1, pl2)
	return GM.teamstuff.sortbyfrags(pl2, pl1) and pl1 or pl2
end

function PLAYER:SeekPlace() --meant to be called when the link has been broken
	local currentnext = self
	local currentprev = self
	for _, v in pairs(PLAYERS) do
		if GetAheadPlayer(self, v) == v then
			if GetBehindPlayer(v, currentnext) == v then
				currentnext = v
			end
		elseif GetBehindPlayer(self, v) == v then
			if GetAheadPlayer(v, currentprev) == v then
				currentprev = v
			end
		end
	end
	currentprev.place_next = self
	currentnext.place_previous = self
	self.place_next = currentnext
	self.place_previous = currentprev
end

function PLAYER:GetPlace(set)
	local place = 1
	local myfrags = self:GetFrags()
	for _, v in pairs(set) do
		if v == self then continue end
		if v == GetAheadPlayer(self, v) then place = place + 1 end
	end

	return place
end

function player.GetByPlace()
	
end

if CLIENT then
	usermessage.Hook("sdm_headshot", function(um)
		local pl = um:ReadEntity()
		local pos = um:ReadVector()
		local edata = EffectData()
		edata:SetOrigin(pos)
		edata:SetEntity(pl)
		util.Effect("ef_sdm_headshot", edata)
	end)
end

local PLAYER_SDM = {}

function PLAYER_SDM:SetModel()
	local cl_playermodel = self.Player:GetInfo("cl_playermodel")
	local modelname = player_manager.TranslatePlayerModel(cl_playermodel)
	util.PrecacheModel(modelname)
	self.Player:SetModel(modelname)

	local skin = self.Player:GetInfoNum("cl_playerskin", 0)
	self.Player:SetSkin(skin)

	local bodygroups = self.Player:GetInfo("cl_playerbodygroups")
	if not bodygroups then bodygroups = "" end

	local groups = string.Explode(" ", bodygroups)
	for i = 0, self.Player:GetNumBodyGroups() - 1 do
		self.Player:SetBodygroup(i, tonumber(groups[i + 1]) or 0)
	end

	self.Player:GetPlayerColor()
	self.Player:GetWeaponColor()
end

player_manager.RegisterClass("player_sdm", PLAYER_SDM, "player_default")