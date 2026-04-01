--BIG thanks to Hank Hill for all the sweet SQL work

ScavStats = {}
ScavStats.Stats = {}
ScavStats.Awards = {}
ScavStats.Achievements = {}

local PLAYER = FindMetaTable("Player")

local function RegisterStat(index, name, printname)
	if SERVER then
		sql.Query([[REPLACE INTO ScavStats (StatID, StatName) VALUES (]] .. index .. [[, "]] .. name .. [[");]])
	end
	ScavStats.Stats[index] = {
		["index"] = index,
		["name"] = name,
		["printname"] = printname
	}
end
local function RegisterAward(index, name, printname, icon)
	if SERVER then
		sql.Query([[REPLACE INTO ScavStats (AwardID, AwardName) VALUES (]] .. index .. [[, "]] .. name .. [[");]])
	end
	ScavStats.Awards[index] = {
		["index"] = index,
		["name"] = name,
		["printname"] = printname,
		["icon"] = icon
	}
end
local function RegisterAchievement(index, name, localization, icon, amttoachieve, secret, quiet)
	if SERVER then
		sql.Query([[REPLACE INTO ScavAchievements (AchievementID, AchievementTitle) VALUES (]] .. index .. [[, "]] .. name .. [[");]])
	end
	local index = index or (#ScavStats.Achievements + 1)
	ScavStats.Achievements[index] = {
		["index"] = index,
		["name"] = name,
		["printname"] = localization,
		["icon"] = icon,
		["description"] = localization .. ".desc",
		["amttoachieve"] = amttoachieve or 1,
		["secret"] = secret or false,
		["quiet"] = quiet or false
	}
end

if SERVER then
 
	-- Look for table, if doesn't exist ...
	if not sql.TableExists("ScavStats") then
			sql.Begin()
			local success = sql.Query(
					[[
					CREATE TABLE "ScavPlayers" ("SteamID" TEXT PRIMARY KEY  NOT NULL, "PlayerName" TEXT);
					CREATE TABLE "ScavAchievements" ("AchievementID" INTEGER PRIMARY KEY  NOT NULL, "AchievementName" TEXT NOT NULL );
					CREATE TABLE "ScavAwards" ("AwardID" INTEGER PRIMARY KEY  NOT NULL, "AwardName" TEXT NOT NULL );
					CREATE TABLE "ScavStats" ("StatID" INTEGER PRIMARY KEY  NOT NULL, "StatName" TEXT NOT NULL );
					CREATE TABLE "ScavPlayerAchievements" ("SteamID" TEXT NOT NULL, "AchievementID" INTEGER NOT NULL, "Progress" INTEGER NOT NULL, FOREIGN KEY (SteamID) REFERENCES ScavPlayers(SteamID), FOREIGN KEY (AchievementID) REFERENCES ScavAchievements(AchievementID), PRIMARY KEY (SteamID, AchievementID));
					CREATE TABLE "ScavPlayerAwards" ("SteamID" TEXT NOT NULL, "AwardID" INTEGER NOT NULL, "AwardAmount" INTEGER NOT NULL, FOREIGN KEY(SteamID) REFERENCES ScavPlayers(SteamID), FOREIGN KEY(AwardID) REFERENCES ScavAwards(AwardID), PRIMARY KEY (SteamID, AwardID) );
					CREATE TABLE "ScavPlayerStats" ("SteamID" TEXT NOT NULL, "StatID" INTEGER NOT NULL, "Value" INTEGER NOT NULL, FOREIGN KEY (SteamID) REFERENCES ScavPlayers(SteamID), FOREIGN KEY (StatID) REFERENCES ScavStats(StatID), PRIMARY KEY (SteamID, StatID));
					CREATE INDEX "playerIndex" ON "ScavPlayers" ("SteamID" ASC);
					CREATE INDEX "playerStatIndex" ON "ScavPlayerStats" ("SteamID" DESC, "StatID" DESC);]])
			sql.Commit()
			if success == false then
				print("Scav DM Database initialization error! " .. tostring(sql.LastError()))
			else
				print("Scav DM Database successfully initialized!")
			end
	end

	function PLAYER:AddScavStat(name, amt)
		self.ScavStats[name] = (self.ScavStats[name] or 0) + amt
	end

	function PLAYER:GetScavStat(name, amt)
		return self.ScavStats[name] or 0
	end
	
	function PLAYER:AddScavAward(name, amt)
		self.ScavAwards[name] = (self.ScavAwards[name] or 0) + amt
	end

	function PLAYER:GetScavAward(name, amt)
		return self.ScavAwards[name] or 0
	end

	function PLAYER:AddScavAchievement(name, amt)
		local amttoachieve = ScavStats.Achievements[name].amttoachieve
		local progress = self:GetScavAchievementProgress(name)
		if progress >= amttoachieve then
			return
		end
		if amt + progress >= amttoachieve then
			gamemode.Call("OnPlayerAchieved", self, name)
		end
		self.ScavAchievements[name] = math.min(amt + progress, amttoachieve)
	end
	
	function PLAYER:GetScavAchievementProgress(name)
		return self.ScavAchievements[name] or 0
	end
	
	function PLAYER:HasScavAchievement(name)
		local amttoachieve = ScavStats.Achievements[name].amttoachieve
		local progress = self:GetScavAchievementProgress(name)
		return (progress >= amttoachieve)
	end

	function PLAYER:LoadScavStats()
		self.ScavStatsID = sql.SQLStr(string.gsub(self:SteamID(), ":", "_")) --if you swap this out for the one below then you also have to swap out at the top of PLAYER:CommitScavStats()
		self.ScavStatsNick = sql.SQLStr(self:Nick())
		local id = self.ScavStatsID
		--local id = sql.SQLStr(self:SteamID())
		self.ScavStats = {}
		self.ScavAwards = {}
		self.ScavAchievements = {}
		--Darv's stuff
		--Let's populate those stats first.
		local result = sql.Query([[SELECT StatID, Value FROM ScavPlayerStats WHERE SteamID = "]] .. id .. [[";]])
		if result == false then
			Msg("ERROR LOADING SCAV STATS: " .. tostring(sql.LastError()) .. "\n")
		end
		if result then
			for k, v in pairs(result) do
				local index = tonumber(v['StatID'])
				self.ScavStats[index] = 0
				self:AddScavStat(index, tonumber(v['Value']))
			end
		end
		--Now awards.... 
		local result = sql.Query([[SELECT AwardID, AwardAmount FROM ScavPlayerAwards WHERE SteamID = "]] .. id .. [[";]])
		if result == false then
			Msg("ERROR LOADING SCAV AWARDS: " .. tostring(sql.LastError()) .. "\n")
		end
		if result then
			for k, v in pairs(result) do
				local index = tonumber(v['AwardID'])
				self.ScavAwards[index] = 0
				self:AddScavAward(index, tonumber(v['AwardAmount']))
			end
		end
		--...and achievements.
		result = sql.Query([[SELECT AchievementID, Progress FROM ScavPlayerAchievements WHERE SteamID = "]] .. id .. [[";]])
		if result == false then
			Msg("ERROR LOADING SCAV ACHIEVEMENTS: " .. tostring(sql.LastError()) .. "\n")
		end
		if result then
			for k, v in pairs(result) do
				local index = tonumber(v['AchievementID'])
				self.ScavAchievements[index] = 0
				self:AddScavAchievement(index, tonumber(v['Progress']))
			end
		end
	end
	
	function PLAYER:CommitScavStats()
		local id = self.ScavStatsID
		local nick = self.ScavStatsNick
		--local id = sql.SQLStr(self:SteamID())
		sql.Begin()
		-- Let's force the bastard into the players table/update his nick while we're commiting.
		sql.Query([[REPLACE INTO ScavPlayers (SteamID, PlayerName) VALUES ("]] .. id .. [[", "]] .. nick .. [[");]])
			for k, v in pairs(self.ScavStats) do
				sql.Query([[REPLACE INTO ScavPlayerStats (SteamID, StatID, Value) VALUES("]] .. id .. [[", ]] .. k .. [[, ]] .. v .. [[);]])
			end
			for k, v in pairs(self.ScavAwards) do
				sql.Query([[REPLACE INTO ScavPlayerAwards (SteamID, AwardID, AwardAmount) VALUES("]] .. id .. [[", ]] .. k .. [[, ]] .. v .. [[);]])
			end
			for k, v in pairs(self.ScavAchievements) do
				sql.Query([[REPLACE INTO ScavPlayerAchievements (SteamID, AchievementID, Progress) VALUES("]] .. id .. [[", ]] .. k .. [[, ]] .. v .. [[);]])
			end
		sql.Commit()
		
	end

	local function commitonremove(pl)
		print("committing scav stats for " .. pl.ScavStatsNick .. " (" .. pl.ScavStatsID .. ")...")
		pl:CommitScavStats()
		print("committed.")
	end
	
	hook.Add("PlayerInitialSpawn", "ScavStats", function(pl)
		pl:LoadScavStats()
		pl:CallOnRemove("CommitScavStats", commitonremove, pl)
	end)
	
	--[[
	hook.Add("PlayerDisconnected", "ScavStats", function(pl)
		pl:CommitScavStats()
	end)
	]]
	--[[hook.Add("ShutDown", "ScavStats", function()
		--print("Preparing to commit shutdown scav stats ...")
		--print(tostring(Entity(1), #ents.GetAll(), #player.GetAll()))
		for _, v in pairs(player.GetAll()) do
		--	print("committing scav stats for " .. v:Nick() .. " " .. v:SteamID())
			v:CommitScavStats()
		end
	end)]]
	
	--[[
	hook.Add("EntityRemoved", "ScavStats", function(ent)
		if ent:IsPlayer() then
			--print("Committing scav stats for " .. ent:Nick() .. " " .. ent:SteamID())
			print("Committing scav stats for " .. tostring(ent))
			ent:CommitScavStats()
		end
	end)
	]]
	
	util.AddNetworkString("sdm_achievement")

	function GM:OnPlayerAchieved(pl, index)
		pl:EmitSound("weapons/fx/rics/ric2.wav")
		net.Start("sdm_achievement")
			net.WritePlayer(pl)
			net.WriteUInt(index, 7) -- !!!IMPORTANT!!! This gives a max of 127 achievements, should we ever pass that, this needs changing!
			net.Broadcast()
		print(pl:Nick() .. " has achieved " .. ScavStats.Achievements[index].printname .. "!")
	end
	
else
	net.Receive("sdm_achievement", function()
		local pl = net.ReadPlayer()
		if not IsValid(pl) then return end
		local index = net.ReadUInt(7)
		chat.AddText(ScavLocalize("#scav.achievement", pl:Nick(), ScavStats.Achievements[index].printname))
	end)
end


--DO NOT MESS WITH THESE ENUMS, THEY GO WITH THE DATABASE. IF YOU REMOVE OR CHANGE ANY OF THESE THINGS WILL GET FUCKED UP

SCAVSTAT_PLAYTIME = 1
SCAVSTAT_GAMESPLAYED = 2
SCAVSTAT_WINS = 3
SCAVSTAT_LOSSES = 4
SCAVSTAT_DRAWS = 5
SCAVSTAT_POINTS = 6
SCAVSTAT_FRAGS = 7
SCAVSTAT_DEATHS = 8
SCAVSTAT_SUICIDES = 9
SCAVSTAT_GIBS = 10
SCAVSTAT_HEADSHOTS = 11
SCAVSTAT_DAMAGE = 12
SCAVSTAT_HEALING = 13
SCAVSTAT_KILLSTREAK = 14
SCAVSTAT_POINTSTREAK = 15

sql.Begin()
	RegisterStat(SCAVSTAT_PLAYTIME, "PlayTime", "#scav.stats.time")
	RegisterStat(SCAVSTAT_GAMESPLAYED, "GamesPlayed", "#scav.stats.games")
	RegisterStat(SCAVSTAT_WINS, "Wins", "#scav.stats.games.won")
	RegisterStat(SCAVSTAT_LOSSES, "Losses", "#scav.stats.games.lost")
	RegisterStat(SCAVSTAT_DRAWS, "Draws", "#scav.stats.games.tied")
	RegisterStat(SCAVSTAT_POINTS, "Points", "#scav.stats.points")
	RegisterStat(SCAVSTAT_FRAGS, "Frags", "#scav.stats.kills")
	RegisterStat(SCAVSTAT_DEATHS, "Deaths", "#scav.stats.deaths")
	RegisterStat(SCAVSTAT_SUICIDES, "Suicides", "#scav.stats.deaths.self")
	RegisterStat(SCAVSTAT_GIBS, "Gibs", "#scav.stats.kills.gibs")
	RegisterStat(SCAVSTAT_HEADSHOTS, "Headshots", "#scav.stats.headshots")
	RegisterStat(SCAVSTAT_DAMAGE, "Damage", "#scav.stats.dmg")
	RegisterStat(SCAVSTAT_HEALING, "Healing", "#scav.stats.heal")
	RegisterStat(SCAVSTAT_KILLSTREAK, "KillStreak", "#scav.stats.kills.onelife")
	RegisterStat(SCAVSTAT_POINTSTREAK, "PointStreak", "#scav.stats.points.onelife")

	SCAVACHIEVEMENT_TRIPLEGIB = 1

	RegisterAchievement(SCAVACHIEVEMENT_TRIPLEGIB, "TripleGib", "#scav.achievement.triplegib", icon)

sql.Commit()
