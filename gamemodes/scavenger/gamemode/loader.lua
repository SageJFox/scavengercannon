local blacklist = {}
if file.Exists("data/scavdata/gloader_blacklist.txt", "GAME") then 
	table.Add(blacklist, string.Split(file.Read("data/scavdata/gloader_blacklist.txt", "GAME"), "\n"))
end

local oneof = {}
oneof["env_fog_controller"] = true

local function CleanUpNulls(tab)
	local nulls = {}
	for k,v in pairs(tab) do
		if v == NULL then
			table.insert(nulls, k)
		end
	end
	local numnulls = #nulls
	for i=0,numnulls do
		table.remove(tab,nulls[numnulls-i])
	end
end

--unfilled indices return and empty table instead of nil
local meta = {}
meta.__index = meta

function NewGLoader(path)
	local gloader = {}
	setmetatable(gloader,meta)
	gloader.ents = {}
	gloader:LoadFile(path)
	return gloader
end

--only first argument necessary, others are just to speed up subsequent calls if we encounter a problem
function meta:LoadFile(path, map, config)
	local map = map or string.match(path, "^data/scavdata/maps/([^/]+)/")
	local config = config or string.match(path, "^data/scavdata/maps/[^/]+/([^/]+)")
	local default = config == "default.txt"
	self.filepath = path
	local read = file.Read(path, "GAME")
	local tab = {}
	if not read and not default then
		ErrorNoHalt("Warning! Config file '", path, "' not found! Attempting to load 'default.txt' for ", map, "!\n") 
		return self:LoadFile("data/scavdata/maps/" .. map .. "/default.txt", map, "default.txt")
	end
	if read then
		tab = util.JSONToTable(read)
	else
		ErrorNoHalt("Warning! No default config present for ", map, "!\n")
		--todo: actually handle this lmao
	end
	if not tab then
		ErrorNoHalt("Warning! Could not parse '", path, "'! File may be corrupted!", not default and "" or " Attempting to load 'default.txt'!\n")
		if not default then
			return self:LoadFile("data/scavdata/maps/" .. map .. "/default.txt", map, "default.txt")
		end
		--todo: actually handle this lmao
		tab = {}
	end
	self.data = tab
	self.templates = tab.entities or {}
	self:VerifyGame()
	--PrintTable(self.templates)
end

--generic template copying, gets the shared data
local copytotemplate = function(ent, template)
	local template = template or {}
	template.KeyValues = template.KeyValues or {}
	template.Outputs = template.Outputs or {}

	template.pos = template.pos or ent:GetPos()
	template.ang =template.ang or ent:GetAngles()
	template.material = template.material or ent:GetMaterial()
	template.skin =template.skin or ent:GetSkin()

	if template.KeyValues.classname == "sdm_prop_spawn" then
		template.KeyValues.spawnclass = template.KeyValues.spawnclass or ent:GetClass()
		template.KeyValues.lifetime = template.KeyValues.lifetime or 0
		template.KeyValues.skin = template.KeyValues.skin or template.skin
		--estimate a reasonable respawn time based on weight
		template.KeyValues.delay = template.KeyValues.delay or math.min(25, math.max(5, math.Round(math.Remap(IsValid(ent:GetPhysicsObject()) and ent:GetPhysicsObject():GetMass() or 0, 15, 500, 10, 20), 1)))
	else
		template.KeyValues.classname = template.KeyValues.classname or ent:GetClass()
	end
	template.KeyValues.modelname = template.KeyValues.modelname or ent:GetModel()

	return template
end

function meta:VerifyGame()
	--most of this isn't properly hooked up for now, just sorta thoughts for the future
	--for now, we're working on just making a game spawnable (and maybe even fun!) when a config file is completely absent
	local spawns = {}
	--local needspawns = {}
	local teams = {}
	local needteams = {}
	local control = {}
	local props = {}
	--gather base info
	for _, v in ipairs(self.templates) do
		if not v.KeyValues then continue end
		local classname = string.lower(v.KeyValues.classname or v.ClassName)
		if not classname then continue end

		if classname == "sdm_prop_spawn" then
			table.insert(props, v)
			continue
		end
		if classname == "info_sdm_team" then
			table.insert(teams, v)
			--table.insert(needspawns, v.KeyValues.team)
			continue
		end
		if classname == "info_sdm_spawn" then
			table.insert(spawns, v)
			--table.insert(needteams, v.KeyValues.team)
			continue
		end
		if classname == "info_sdm" then
			table.insert(control, v)
			continue
		end
	end

	--for now, we have a pretty simple test: if we don't have spawns, we don't have a game on this map

	--SPAWNING
	if #spawns > 0 then return end

	--Default spawnpoints present in maps, and determining what team they're for

	--these initial potential spawnpoints are capable of being set to different teams
	--so we might as well use that for ourselves, so default doesn't have to be *just* regular DM
	local spawnpoints = {
		--TF2
		["info_player_teamspawn"] = {
			["Team"] = function(spawn)
				local kv = spawn:GetKeyValues()
				if not kv.TeamNum then return end
				--podium spawn
				if kv.MatchSummary and tonumber(kv.MatchSummary) > 0 then return end

				if not kv.TeamNum then return "unassigned" end
				local t = tonumber(kv.TeamNum)
				if not t then return "unassigned" end
				if t == 0 then return "unassigned" end
				if t == 2 then return "red" end
				if t == 3 then return "blue" end
			end,
		},
		--misc.
		["ins_spawnpoint"] = {
			["Team"] = function(spawn)
				local kv = spawn:GetKeyValues()
				if not kv.TeamNum then return end

				if not kv.TeamNum then return "unassigned" end
				local t = tonumber(kv.TeamNum)
				if not t then return "unassigned" end
				if t == 0 then return "unassigned" end
				if t == 2 then return "blue" end --Security
				if t == 3 then return "red" end --Insurgents
			end
		},
		["dys_spawn_point"] = {
			["Team"] = function(spawn)
				local kv = spawn:GetKeyValues()
				if not kv.Team then return end

				if not kv.Team then return "unassigned" end
				local t = tonumber(kv.Team)
				if not t then return "unassigned" end
				if t == 0 then return "unassigned" end
				if t == 2 then return "red" end --Punks
				if t == 3 then return "blue" end --Corps
			end
		},
	}

	--neutral spawnpoints, possibly ideal for DM
	local spawnpoints_neutral = {
		"info_player_start",
		"gmod_player_start",
		--HL2:DM
		"info_player_deathmatch",
		--Portal 2
		"info_coop_spawn",
		--misc.
		"aoc_spawnpoint",
		"info_player_coop",
		--L4D/2
		"info_survivor_position",
		"info_survivor_rescue",
	}
	local tellmywifeisaidhello = function(ent) return "unassigned" end

	for _, v in ipairs(spawnpoints_neutral) do
		spawnpoints[v] = { ["Team"] = tellmywifeisaidhello }
	end

	--strictly one team spawnpoints, generally most ideal for TDM but y'know, maps be weird
	local spawnpoints_red = {
		"info_player_rebel",
		--CS:S
		"info_player_terrorist",
		--DoD:S
		"info_player_allies",
		--misc.
		"info_player_pirate",
		"diprip_start_team_red",
		"info_player_red",
		"info_player_human",
		--Black Mesa
		"info_player_marine",
	}
	local redhead = function(ent) return "red" end

	for _, v in ipairs(spawnpoints_red) do
		spawnpoints[v] = { ["Team"] = redhead }
	end

	local spawnpoints_blue = {
		--HL2:DM
		"info_player_combine",
		--CS:S
		"info_player_counterterrorist",
		--DoD:S
		"info_player_axis",
		--misc.
		"info_player_viking",
		"diprip_start_team_blue",
		"info_player_blue",
		--Black Mesa
		"info_player_scientist",
	}
	local blueboi = function(ent) return "blue" end

	for _, v in ipairs(spawnpoints_blue) do
		spawnpoints[v] = { ["Team"] = blueboi }
	end

	--if we're using green team, it's either a 3-team deal or it could be a humans vs zombies situation
	local spawnpoints_green = {
		"info_player_knight",
		"info_player_zombie",
	}
	local meangreen = function(ent) return "green" end

	for _, v in ipairs(spawnpoints_green) do
		spawnpoints[v] = { ["Team"] = meangreen }
	end

	local spawnmodels = {
		["unassigned"] = "models/humans/group02/male_07.mdl",
		["red"] = "models/humans/group02/male_07.mdl",
		["blue"] = "models/combine_super_soldier.mdl",
		["green"] = "models/zombie/classic.mdl",
	}

	--PROPS
	local sdm_prop_spawns = {
		["prop_physics"] = true,
		["prop_physics_multiplayer"] = true,
		["prop_ragdoll"] = true,
	}
	local validprop = function(ent)
		if not IsValid(ent:GetPhysicsObject()) then return false end
		local classname = ent:GetClass()
		if sdm_prop_spawns[classname] then return true end
		if ent:IsWeapon() then return true end
		if string.find(classname, "^item_") then return true end

		return false
	end
	
	local team_locales = {}
	for _, v in ents.Iterator() do
		local classname = v:GetClass()

		if spawnpoints[classname] then
			local t = spawnpoints[classname].Team(v)
			needteams[t] = true
			team_locales[t] = team_locales[t] or v
			team_locales[1] = team_locales[1] or v
			local template = {}
				template.KeyValues = {}
					template.KeyValues.classname = "info_sdm_spawn"
					template.KeyValues.team = t
					template.KeyValues.modelname = spawnmodels[t]
			table.insert(spawns, copytotemplate(v, template))
			table.insert(self.templates, template)
			continue
		end
		--prop spawns (most processing handled up in copytotemplate)
		if validprop(v) then
			local template = {}
				template.KeyValues = {}
					template.KeyValues.classname = "sdm_prop_spawn"
					template.KeyValues.spawnclass = "prop_physics"
			table.insert(props, copytotemplate(v, template))
			table.insert(self.templates, template)
			v:Remove()
		end

	end
	--making our teams
	for k, _ in pairs(needteams) do
		local template = {}
			template.KeyValues = {}
				template.KeyValues.classname = "info_sdm_team"
				template.KeyValues.modelname = "models/props_wasteland/medbridge_post01.mdl"
				template.KeyValues.team = k
				template.KeyValues.joinable = 1
		teams[k] = copytotemplate(team_locales[1], template)
		table.insert(self.templates, template)
	end

	if not self.data.gamevars then
		self.data.gamevars = {}
	end

	--and finally, the gamemode (currently just based on teams)
	--todo: base gamemode on map name and/or certain entities being present?
	local mode = "deathmatch"
	if table.Count(teams) > 1 then
		mode = "team_deathmatch"
	end
	if self.data.gamevars.mode then
		mode = self.data.gamevars.mode
	else
		self.data.gamevars.mode = mode
	end

	local maxpoints = 15 --todo: inversely proportional to map size? proportional to maxplayers? proportional to spawns available?
	if self.data.gamevars.maxpoints then
		maxpoints = self.data.gamevars.maxpoints
	else
		self.data.gamevars.maxpoints = maxpoints
	end

	local timelimit = 0
	if self.data.gamevars.timelimit then
		timelimit = self.data.gamevars.timelimit
	else
		self.data.gamevars.timelimit = timelimit
	end

	local template = {}
		template.KeyValues = {}
			template.KeyValues.classname = "info_sdm"
			template.KeyValues.targetname = "info_sdm"
			template.KeyValues.mode = mode
			template.KeyValues.modelname = "models/props_lab/monitor01a.mdl"
			template.KeyValues.timelimit = timelimit
			template.KeyValues.maxpoints = maxpoints
	table.insert(self.templates, copytotemplate(team_locales[1], template))

end

function meta:ParseGameVars()
	local gamevars = self.data.gamevars
	if not gamevars then return end

	for k, v in pairs(gamevars) do
		local result = hook.Call("GameVar", GAMEMODE, k, v)
		if result == nil then continue end

		gamevars[k] = result --You can override gamevars from GM:GameVar by returning non-nil. Mainly useful for enforcing a data type.
	end
end

function meta:Spawn(filter) --accepts TemplateID filter, TemplateID member is assigned to all entities upon spawn to refer back to.
	filter = filter or {}
	CleanUpNulls(self.ents)
	local spawnedents = {}
	if self.templates then
		for k, template in pairs(self.templates) do
			local classname = string.lower(template.KeyValues.classname or template.ClassName)

			if table.HasValue(filter,k) then
				--do nothing
			elseif not table.HasValue(blacklist,classname) then
				local override = template.KeyValues.override
				if oneof[classname] and override then
					local otherent = ents.FindByClass(classname)[1]
					if IsValid(otherent) then
						otherent:Remove()
					end
				end
				if override then
					local ent = ents.FindByClass(classname)[1]
					if not ent.WrittenTo then
						for key,value in pairs(template.KeyValues) do
							ent:SetKeyValue(key,value)
						end
						for outputindex,outputinfo in pairs(template.Outputs) do
							local values = string.Explode(",",outputinfo)
							ent:AddEntOutput(values[1],values[2],values[3],values[4],values[5],values[6])
						end
					end
				else
					local ent = ents.Create(classname)
					if ent:IsValid() then
						ent.TemplateID = k
						ent:SetPos(template.pos)
						ent:SetAngles(template.ang)
						ent:SetMaterial(template.material)
						for key,value in pairs(template.KeyValues) do
							key = string.lower(key)
							ent:SetKeyValue(key,value)
							if key == "team" then
								ent.team = team.ToTeamID(value)
							elseif key == "parentname" then
								ent.parentname = value
							elseif key == "modelname" then
								ent:SetKeyValue("model",value)
							end
						end
						for outputindex,outputinfo in pairs(template.Outputs) do
							local values = string.Explode(",",outputinfo)
							ent:AddEntOutput(values[1],values[2],values[3],values[4],values[5],values[6])
						end
						ent.NoScav = tobool(template.KeyValues.noscav)
						ent:Spawn()
						if ent:GetPhysicsObject():IsValid() and tobool(template.KeyValues.physfrozen) then
							ent:GetPhysicsObject():EnableMotion(false)
						end
						table.insert(spawnedents,ent)
					end
				end
			else
				MsgAll("GLOADER WARNING!!! ATTEMPTED TO SPAWN BLACKLISTED ENTITY CLASS: \""..string.upper(classname).."\" FROM FILE \""..string.upper(self.filepath).."\"")
			end
		end
	end
	for _, v in pairs(spawnedents) do
		if not v.parentname then continue end

		local parent = ents.FindByName(v.parentname)[1]
		if not parent then continue end

		v:SetParent(parent)
	end
	table.Merge(self.ents, spawnedents)
	gamemode.Call("OnGLoaderSpawn")
	return spawnedents
end

function meta:Cleanup(filter) --takes entity filter
	filter = filter or {}
	for _, ent in pairs(self.ents) do
		if table.HasValue(filter, ent) then continue end
		ent:Remove()
	end
	CleanUpNulls(self.ents)
end

function meta:GetEntityTemplates()
	return self.templates
end

function meta:FindEntTemplatesByClass(classname,exact)
	classname = string.lower(classname)
	local tab = {}
	for k,template in pairs(self.templates) do
		local cname = string.lower(template.KeyValues.classname)
		if (exact and (classname == cname)) or (not exact and string.find(cname,classname)) then
			table.insert(tab,template)
		end
	end
	return tab
end

local GM = GM or GAMEMODE
function GM:OnGLoaderSpawn()
end
