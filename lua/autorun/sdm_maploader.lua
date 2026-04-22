AddCSLuaFile()

--[[=======================================================================]]--
--		Map Loader
--[[=======================================================================]]--
	
if SERVER then
	CreateConVar("sdm_settingsfile", "default.txt", FCVAR_ARCHIVE)
	CreateConVar("sdm_allowvote", 0, FCVAR_ARCHIVE)
	CreateConVar("sdm_vote_percentage", 0.75, FCVAR_ARCHIVE, "Minimum percentage of voters to force an early server vote and subsequent map change.", 0, 1)
end
	
function ScavData.StartScavDM(map, settingsfile)
	RunConsoleCommand("sdm_settingsfile", settingsfile)
	RunConsoleCommand("gamemode", "scavenger")
	RunConsoleCommand("changelevel", map)
end
	
function ScavData.GetValidMaps()
	if SERVER then
		local _, potentialmaps = file.Find("data/scavdata/maps/*", "GAME")
		local maps = {}
		
		for _, v in pairs(potentialmaps) do
			local files, _ = file.Find("data/scavdata/maps/" .. v .. "/*.txt", "GAME")
			for _, f in ipairs(files) do
				table.insert(maps, v .. "/" .. f)
			end
		end
		return maps
	else
		return ScavData.SettingsFilePaths
	end
end

local loader = {}
ScavData.AllSettingsFiles = {}

function loader.New()
	local newloader = {}
	table.Inherit(newloader, loader)
	return newloader
end

function loader.Get(filename)
	if ScavData.AllSettingsFiles[filename] then
		return ScavData.AllSettingsFiles[filename]
	else
		local newloader = loader.New()
		newloader:Read(filename)
		ScavData.AllSettingsFiles[filename] = newloader
		return newloader
	end
end
		
ScavData.GetSettingsIO = loader.Get --the filename argument is optional, it will automatically load the given file if supplied

--saving net message strings, reusing one with different message codes (client will read the proper info after seeing this code)
local SCAV_VOTE_ENDING = 0
local SCAV_VOTE_ENDED = 1
local SCAV_VOTE_NO = 2
local SCAV_VOTE_CALLED = 3
local SCAV_VOTE_NONECAST = 4

local SCAV_VOTE_BITS = 3

--sending singular (here entirely U)Ints with as few bits as possible
local function bitcount(num)
	if isstring(num) then return (#num + 1) * 8 end
	local bits = 1
	while math.pow(2, bits) < math.abs(num) do
		bits = bits + 1
	end
	return bits
end

if SERVER then
		
	util.AddNetworkString("scv_loader")
	util.AddNetworkString("sdm_maploader_message")
	
	function loader:SendToClient(pl)
		net.Start("scv_loader")
			net.WriteString(self:GetFileName() or "")
			net.WriteString(self:GetName() or "")
			net.WriteString(self:GetAuthor() or "")
			net.WriteString(self:GetMode() or "deathmatch")
			net.WriteInt(self:GetPointLimit() or 0, 32)
			net.WriteFloat(self:GetTimeLimit() or 0)
			net.WriteFloat(self:GetMaxTeams() or 0)
			net.WriteBool(self:GetFriendlyFire() or false)
			net.WriteFloat(self:GetDamageScale() or 1)
			net.WriteString(self:GetModString() or "")
		net.Send(pl)
	end

	util.AddNetworkString("scv_settingsfiles")
	
	function ScavData.SendAllSettingsToClient(pl)
		local maps = ScavData.GetValidMaps()
		net.Start("scv_settingsfiles")
			local filter = RecipientFilter()
			filter:AddPlayer(pl)
			net.WriteTable(maps)
		net.Send(filter)
	end
	
	function ScavData.CloseClientVoteMenus()
		for _, v in ipairs(player.GetHumans()) do
			v:ConCommand("sdm_vote_close")
		end
	end
	
	concommand.Add("sdm_vote_requestfiles", function(pl, cmd, args)
		if not pl.WasSentSDMSettingsList then --doing this so some wise guy can't force the server to constantly stream to him. This concommand can be overwritten if for some reason you're adding new settings files to the server in the middle of a game
			ScavData.SendAllSettingsToClient(pl)
			pl.WasSentSDMSettingsList = true
		end
	end)

	concommand.Add("sdm_vote_requestmap", function(pl, cmd, args)
		local filename = args[1]
		if not filename then filename = game.GetMap() .. "/" .. GetConVar("sdm_settingsfile"):GetString() end
		--not allowed to go back
		if string.find(filename, "..", nil, true) then return false end
		if not string.find(filename, "/") then
			--todo: not just assume that they put a file in and want the current map
			filename = game.GetMap() .. "/" .. filename
		end
		if not file.Exists("data/scavdata/maps/" .. tostring(filename), "GAME") then return false end

		local loader = ScavData.GetSettingsIO(filename)
		loader:SendToClient(pl)
	end)
	
	local mapchangestarted = false
	
	function ScavData.SetVotingDeadline(time)
		if mapchangestarted then return end
		if time < 0 then return end
		SetGlobalFloat("sdm_votedeadline", CurTime() + time)
		net.Start("sdm_maploader_message")
			net.WriteUInt(SCAV_VOTE_ENDING, SCAV_VOTE_BITS)
			net.WriteUInt(time, bitcount(time))
		net.Broadcast()
	end

	local function beginmapchange()
	
		if mapchangestarted then return end
		mapchangestarted = true
		
		local vote = ScavData.GetWinningMapVote()

		if vote == "none" then
			net.Start("sdm_maploader_message")
				net.WriteUInt(SCAV_VOTE_NONECAST, SCAV_VOTE_BITS)
			net.Broadcast()
			mapchangestarted = false
			ScavData.SetVotingDeadline(90)
			for _, pl in ipairs(player.GetHumans()) do
				pl:ConCommand("sdm_vote")
			end
			return
		end

		local mapandsetting = string.Explode("/", vote)
		local map = mapandsetting[1]
		local setting = mapandsetting[2]
		
		ScavData.CloseClientVoteMenus()
		
		net.Start("sdm_maploader_message")
			net.WriteUInt(SCAV_VOTE_ENDED, SCAV_VOTE_BITS)
			net.WriteString(map)
			net.WriteString(setting)
			--when we want our last chat message to show
			local synctime = 4.1 + CurTime()
			net.WriteFloat(synctime)
		net.Broadcast()
		timer.Simple(5.1, function() ScavData.StartScavDM(map, setting) end)
	end			
			
	hook.Add("Think", "sdm_votetimer", function()
		local deadline = GetGlobalFloat("sdm_votedeadline")
		if deadline ~= 0 and deadline <= CurTime() then
			beginmapchange()
		end
	end)
	
	util.AddNetworkString("UpdateSDMVotes")
	util.AddNetworkString("sdm_dispvote")
	
	concommand.Add("sdm_vote_submit", function(pl, cmd, args)
	
		if not GetConVar("sdm_allowvote"):GetBool() and GetConVar("gamemode"):GetString() ~= "scavenger" then
			net.Start("sdm_maploader_message")
				net.WriteUInt(SCAV_VOTE_NO, SCAV_VOTE_BITS)
			net.Broadcast()
			pl:ConCommand("sdm_vote_close")
			return
		end
		
		local filename = args[1]
		
		if string.find(filename, "..", nil, true) or not string.find(filename, "/") then
			return false
		end

		if file.Exists("data/scavdata/maps/" .. tostring(filename), "GAME") then
		
			net.Start("UpdateSDMVotes")
				local rf = RecipientFilter()
				rf:AddAllPlayers()
			net.Send(rf)
			
			if pl.SDMMapVote ~= filename then
			
				pl.SDMMapVote = filename
				pl:SetNWString("sdm_vote", filename)
				
				local mapandsetting = string.Explode("/", filename)
				local map = mapandsetting[1]
				local setting = mapandsetting[2]
				
				net.Start("sdm_dispvote")
					local rf = RecipientFilter()
					rf:AddAllPlayers()
					net.WriteEntity(pl)
					net.WriteString(map)
					net.WriteString(setting)
				net.Send(rf)
				
			end
			
			local players = player.GetHumans()
			local uncast = {}

			for _, v in pairs(players) do
				if ScavData.GetPlayerMapVote(v) ~= "none" then continue end

				table.insert(uncast, v)
			end

			if #uncast == 0 then
				beginmapchange()
			elseif #uncast <= math.floor((#players + player.GetCountConnecting()) * (1 - GetConVar("sdm_vote_percentage"):GetFloat())) and GetGlobalFloat("sdm_votedeadline") == 0 then
				net.Start("sdm_maploader_message")
					net.WriteUInt(SCAV_VOTE_CALLED, SCAV_VOTE_BITS)
					local displaypercent = math.Round(GetConVar("sdm_vote_percentage"):GetFloat() * 100)
					net.WriteUInt(displaypercent, bitcount(displaypercent))
				net.Broadcast()
				for _, v in pairs(uncast) do
					v:ConCommand("sdm_vote")
				end
				ScavData.SetVotingDeadline(30)
			end
			
		else
			MsgAll("Error! Could not load mapsettings file S \"scavdata/maps/" .. filename .. "\"")
		end
	end)
	
	hook.Add("PlayerDisconnect", "updatesdmvotes", function()
		net.Start("UpdateSDMVotes")
			local rf = RecipientFilter()
			rf:AddAllPlayers()
		net.Send(rf)
	end)

else
	--client message decoding
	local messages = {
		[SCAV_VOTE_ENDING] = function(len)
			chat.AddText(ScavLocalizeColor("scav.vote.ending", net.ReadUInt(len)))
		end,
		[SCAV_VOTE_ENDED] = function(len)
			local map = net.ReadString()
			local setting = net.ReadString()
			--in a perfect world this'll always be above 5, but we don't live in a perfect world
			--so do our countdown with whatever we got left after latency ate its chunk
			local synctime = net.ReadFloat() - CurTime()
			--message took too long, we're basically just logging now
			if synctime <= 1 then return chat.AddText(ScavLocalizeColor("scav.vote.ended.notime", false, setting, false, map)) end

			--building the countdown in reverse, starting with the timer for 1 and going up
			local countdown = 1
 			while synctime >= 1 do
				local cdown = countdown
				timer.Simple(synctime, function() chat.AddText(ScavLocalizeColor("scav.vote.ended.count", cdown)) end)
				countdown = countdown + 1
				synctime = synctime - 1
			end
			--the start, and soonest message
			timer.Simple(synctime, function() chat.AddText(ScavLocalizeColor("scav.vote.ended", false, setting, false, map, false, countdown)) end)
		end,
		[SCAV_VOTE_NO] = function(len)
			chat.AddText(ScavLocalizeColor("scav.vote.notallowed"))
		end,
		[SCAV_VOTE_CALLED] = function(len)
			local percent = net.ReadUInt(len)
			chat.AddText(ScavLocalizeColor(percent >= 50 and "scav.vote.called" or "scav.vote.called.minority", percent))
		end,
		[SCAV_VOTE_NONECAST] = function(len)
			chat.AddText(ScavLocalizeColor("scav.vote.ended.none"))
		end,
	}

	net.Receive("sdm_maploader_message", function(len, pl)
		messages[net.ReadUInt(SCAV_VOTE_BITS)](len - SCAV_VOTE_BITS)
	end)


	ScavData.SettingsFilePaths = {}
	
	net.Receive("scv_settingsfiles", function()
	
		local tbl = net.ReadTable()
		
		if tbl then
			ScavData.SettingsFilePaths = tbl
		end
		
		if SDM_VOTEMENU and SDM_VOTEMENU:IsValid() then
			SDM_VOTEMENU:Refresh()
		end
		
	end)
	
	color_green = Color(0, 255, 0, 255)
	color_blue = Color(0, 0, 255, 255)
	net.Receive("sdm_dispvote", function()
		local pl = net.ReadEntity()
		local pcol = pl:GetPlayerColor()
		local col = Color(pcol.r * 255, pcol.g * 255, pcol.b * 255)
		local map = net.ReadString()
		local setting = net.ReadString()
		chat.AddText(ScavLocalizeColor("scav.vote.voted", pl:Nick(), map, setting, col))
	end)
	
	net.Receive("scv_loader", function()
	
		local filename = net.ReadString()
		local obj = loader.New()
		
		if not obj.data then
			obj.data = {}
			obj.data.gamevars = {}
			obj.data.entities = {}
		end
		
		obj:SetFileName(filename)
		obj:SetName(net.ReadString())
		
		obj:SetAuthor(net.ReadString())
		obj:SetMode(net.ReadString())
		obj:SetPointLimit(net.ReadInt(32))
		obj:SetTimeLimit(net.ReadFloat())
		obj:SetMaxTeams(net.ReadFloat())
		obj:SetFriendlyFire(net.ReadBool())
		obj:SetDamageScale(net.ReadFloat())
		obj.modstring = net.ReadString()
		
		ScavData.AllSettingsFiles[filename] = obj
		
	end)
	
end

--READ
		
function loader:Read(filename)
	self.filename = filename
	local filecontents = file.Read("data/scavdata/maps/" .. tostring(filename), "GAME")
	self.data = util.JSONToTable(filecontents)
end

function loader:GetFileName()
	return self.filename
end

function loader:GetName()
	return self.data.gamevars.name
end

function loader:GetAuthor()
	return self.data.gamevars.author
end

function loader:GetMode()
	return self.data.gamevars.mode
end

function loader:GetPointLimit()
	return self.data.gamevars.maxpoints
end

function loader:GetTimeLimit()
	return self.data.gamevars.timelimit
end

function loader:GetTeamPlay()
	return self:GetMaxTeams() > 1
end

function loader:GetMaxTeams()
	if SERVER then
		local foundteams = {}
		
		for _, v in ipairs(self.data.entities) do
			if v.KeyValues.classname ~= "info_sdm_spawn" then continue end
			
			local teamid = ScavData.ColorNameToTeam(v.KeyValues.team)
			
			if teamid == TEAM_UNASSIGNED then continue end
			if table.HasValue(foundteams, teamid) then continue end
			
			table.insert(foundteams, teamid)
		end
		
		self.data.gamevars.maxteams = #foundteams
		
	end
	
	return self.data.gamevars.maxteams
	
end

function loader:GetFriendlyFire()
	return self.data.gamevars.friendlyfire
end

function loader:GetDamageScale()
	return self.data.gamevars.damagescale or 1
end

function loader:GetGravity()
	return self.data.gamevars.gravity or 600
end

function loader:GetPlSpeed()
	return self.data.gamevars.plspeed or 1
end

function loader:GetMod(name)
	return self.data.gamevars["sdm_main_mod_" .. name]
end

function loader:GetModString()

	if SERVER and not self.modstring then
		
		local mods = {}
		
		for k, v in pairs(self.data.gamevars) do
			if v and (string.Left(k, 13) == "sdm_main_mod_") then
				table.insert(mods, string.Right(k, #k - 13))
			end
		end
		
		self.modstring = string.Implode(", ", mods)
		
	end
	
	return self.modstring or ""
	
end
		
--WRITE

function loader:SetFileName(filename) --just to clarify, this should be in the format of "mapnamehere/settingsnamehere"
	self.filename = filename
end

function loader:Write(filename)
	file.Write("data/scavdata/maps/" .. filename, util.TableToJSON(self.data))
end

function loader:SetName(name)
	self.data.gamevars.name = name
end

function loader:SetAuthor(author)
	self.data.gamevars.author = author
end

function loader:SetMode(mode)
	self.data.gamevars.mode = mode
end

function loader:SetPointLimit(limit)
	self.data.gamevars.maxpoints = limit
end

function loader:SetTimeLimit(limit)
	self.data.gamevars.timelimit = limit
end

function loader:SetMaxTeams(maxteams)
	self.data.gamevars.maxteams = maxteams
end

function loader:SetFriendlyFire(ffon)
	self.data.gamevars.friendlyfire = ffon
end

function loader:SetDamageScale(scale)
	self.data.gamevars.damagescale = scale
end

function loader:SetGravity(grav)
	self.data.gamevars.gravity = grav
end

function loader:SetPlSpeed(speed)
	self.data.gamevars.plspeed = speed
end

function loader:SetMod(name, on) --"mods" are boolean-only simple modifiers for the gamemode.
	self.data.gamevars["sdm_main_mod_" .. name] = on
end

if SERVER then
	util.AddNetworkString("sdm_voteset")
end

function ScavData.SetPlayerMapVote(pl, mapsetting, transmitto)
	 pl.SDMMapVote = mapsetting
	 if SERVER then
		util.AddNetworkString("scv_voteset")
		 net.Start("sdm_voteset")
			net.WriteEntity(pl)
			net.WriteString(mapsetting)
		 net.Send(transmitto)
	end
end	

function ScavData.GetPlayerMapVote(pl)
	return pl.SDMMapVote or "none"
end
		
function ScavData.GetWinningMapVote()

	local votes = {}
	
	for _, v in pairs(player.GetHumans()) do
		local name = ScavData.GetPlayerMapVote(v)
		if name ~= "none" then
			votes[name] = (votes[name] or 0) + 1
		end
	end
	
	local highvotename
	local highvotecount = 0
	
	for votename, votecount in pairs(votes) do
	
		if not highvotename then
			highvotename = votename
		end
		
		if votecount > highvotecount then
			highvotename = votename
			highvotecount = votecount
		end
		
	end
	
	if highvotecount == 0 then
		return "none"
	else
		return highvotename
	end
	
end

hook.Add("PlayerInitialSpawn", "NetworkSDMMapVotes", function(pl)
	for _, v in pairs(player.GetHumans()) do
		ScavData.SetPlayerMapVote(pl, ScavData.GetPlayerMapVote(v), pl)
	end
end)

if CLIENT then
	net.Receive("sdm_voteset", function()
		local pl = net.ReadEntity()
		if IsValid(pl) then
			ScavData.SetPlayerMapVote(pl, net.ReadString())
		end
	end)
end
