

function TEAM_SetColor(numTeam, tblColor) team.SetUp(numTeam, team.GetName(numTeam), tblColor) end
function TEAM_SetName(numTeam, strName) team.SetUp(numTeam, strName, team.GetColor(numTeam)) end
TEAM_SetColor(TEAM_CONNECTING, color_white)
TEAM_SetColor(TEAM_UNASSIGNED, Color(100, 100, 100, 255))
TEAM_SetColor(TEAM_SPECTATOR, Color(150, 150, 150, 100))

TEAM_SetColor(TEAM_RED, Color(155, 40, 40, 255))
TEAM_SetColor(TEAM_BLUE, Color(32, 92, 140, 255))
TEAM_SetColor(TEAM_GREEN, Color(181, 230, 29, 255))
TEAM_SetColor(TEAM_YELLOW, Color(255, 255, 0, 255))
TEAM_SetColor(TEAM_ORANGE, Color(255, 128, 16, 255))
TEAM_SetColor(TEAM_PURPLE, Color(120, 32, 196, 255))
TEAM_SetColor(TEAM_BROWN, Color(128, 64, 0, 255))
TEAM_SetColor(TEAM_TEAL, Color(0, 255, 172, 255))

TEAM_SetName(TEAM_SPECTATOR, "#scav.team.spectate")
TEAM_SetName(TEAM_RED, "#scav.team.red")
TEAM_SetName(TEAM_BLUE, "#scav.team.blue")
TEAM_SetName(TEAM_GREEN, "#scav.team.green")
TEAM_SetName(TEAM_YELLOW, "#scav.team.yellow")
TEAM_SetName(TEAM_ORANGE, "#scav.team.orange")
TEAM_SetName(TEAM_PURPLE, "#scav.team.purple")
TEAM_SetName(TEAM_BROWN, "#scav.team.brown")
TEAM_SetName(TEAM_TEAL, "#scav.team.teal")

for t, v in pairs(team.GetAllTeams()) do
	local tcol = team.GetColor(t)
	v.ColorVector = Vector(tcol.r / 255, tcol.g / 255, tcol.b / 255)
end

function team.GetColorVector(t)
	if not team.Valid(t) then return vector_origin end
	return team.GetAllTeams()[t].ColorVector
end

GM.Teams = {}
	GM.Teams[TEAM_UNASSIGNED] = false
	GM.Teams[TEAM_RED] = false
	GM.Teams[TEAM_BLUE] = false
	GM.Teams[TEAM_GREEN] = false
	GM.Teams[TEAM_YELLOW] = false
	GM.Teams[TEAM_ORANGE] = false
	GM.Teams[TEAM_PURPLE] = false
	GM.Teams[TEAM_BROWN] = false
	GM.Teams[TEAM_TEAL] = false

function team.Joinable(teamid)
	if not team.GetInfoEnt then return true end
	local ent = team.GetInfoEnt(teamid)
	if not IsValid(ent) or not ent:GetJoinable() then return false end

	return true
end


local teamnametoindex = {}
	teamnametoindex["unassigned"] = TEAM_UNASSIGNED
	teamnametoindex["spectators"] = TEAM_SPECTATOR
	teamnametoindex["red"] = TEAM_RED
	teamnametoindex["blue"] = TEAM_BLUE
	teamnametoindex["green"] = TEAM_GREEN
	teamnametoindex["yellow"] = TEAM_YELLOW
	teamnametoindex["orange"] = TEAM_ORANGE
	teamnametoindex["purple"] = TEAM_PURPLE
	teamnametoindex["brown"] = TEAM_BROWN
	teamnametoindex["teal"] = TEAM_TEAL

function team.ToTeamID(name)
	if type(name) == "number" then return name end
	
	return teamnametoindex[string.lower(name)] or MsgAll("ERROR! Unknown team: " .. tostring(name))
end

function team.IsReal(t, unassigned)
	if t == TEAM_UNASSIGNED then return tobool(unassigned) end
	if t == TEAM_CONNECTING then return false end
	if t == TEAM_SPECTATOR then return false end
	return team.Valid(t)
end
	
if CLIENT then
	local function ReceiveTeams(um) --receives the playable teams from the server
		GAMEMODE.Teams[TEAM_UNASSIGNED] = um:ReadBool()
		GAMEMODE.Teams[TEAM_RED] = um:ReadBool()
		GAMEMODE.Teams[TEAM_BLUE] = um:ReadBool()
		GAMEMODE.Teams[TEAM_GREEN] = um:ReadBool()
		GAMEMODE.Teams[TEAM_YELLOW] = um:ReadBool()
		GAMEMODE.Teams[TEAM_ORANGE] = um:ReadBool()
		GAMEMODE.Teams[TEAM_PURPLE] = um:ReadBool()
		GAMEMODE.Teams[TEAM_BROWN] = um:ReadBool()
		GAMEMODE.Teams[TEAM_TEAL] = um:ReadBool()
	end
	usermessage.Hook("sdm_teams", ReceiveTeams)
end

function GM:SendPlayerTeams(pl)
	umsg.Start("sdm_teams", pl)
		umsg.Bool(team.Joinable(TEAM_UNASSIGNED))
		umsg.Bool(team.Joinable(TEAM_RED))
		umsg.Bool(team.Joinable(TEAM_BLUE))
		umsg.Bool(team.Joinable(TEAM_GREEN))
		umsg.Bool(team.Joinable(TEAM_YELLOW))
		umsg.Bool(team.Joinable(TEAM_ORANGE))
		umsg.Bool(team.Joinable(TEAM_PURPLE))
		umsg.Bool(team.Joinable(TEAM_BROWN))
		umsg.Bool(team.Joinable(TEAM_TEAL))
	umsg.End()
end

if CLIENT then
	GM.Teams = {}
		GM.Teams[TEAM_UNASSIGNED] = false
		GM.Teams[TEAM_RED] = false
		GM.Teams[TEAM_BLUE] = false
		GM.Teams[TEAM_GREEN] = false
		GM.Teams[TEAM_YELLOW] = false
		GM.Teams[TEAM_ORANGE] = false
		GM.Teams[TEAM_PURPLE] = false
		GM.Teams[TEAM_BROWN] = false
		GM.Teams[TEAM_TEAL] = false
	local function ReceiveTeams(um) --receives the playable teams from the server
		GAMEMODE.Teams[TEAM_UNASSIGNED] = um:ReadBool()
		GAMEMODE.Teams[TEAM_RED] = um:ReadBool()
		GAMEMODE.Teams[TEAM_BLUE] = um:ReadBool()
		GAMEMODE.Teams[TEAM_GREEN] = um:ReadBool()
		GAMEMODE.Teams[TEAM_YELLOW] = um:ReadBool()
		GAMEMODE.Teams[TEAM_ORANGE] = um:ReadBool()
		GAMEMODE.Teams[TEAM_PURPLE] = um:ReadBool()
		GAMEMODE.Teams[TEAM_BROWN] = um:ReadBool()
		GAMEMODE.Teams[TEAM_TEAL] = um:ReadBool()
	end
	usermessage.Hook("sdm_teams", ReceiveTeams)
end

function team.GetSpawnTime(teamid)
	return 10
end

function GM:UpdateTeams()
	for k, v in pairs(player.GetAll()) do
		self:SendPlayerTeams(v)
	end
end

function GM:SendPlayerInfo(pl)
	--[[
	for k, v in pairs(InitCVars) do
		umsg.Start("sdm_cvar", pl)
			umsg.String(k)
			umsg.String(v)
		umsg.End()
	end
	umsg.Start("sdm_subgm", pl)
		umsg.String(s_file.gamevars.mode)
	umsg.End()
	]]
	GM:SendPlayerTeams(pl)
	--[[
	umsg.Start("sync_roundstart", pl)
		umsg.Long(game_roundendtime)
	umsg.End()]]
end
	
TeamScores = {}

function team.SetScore(teamid, score) --I overwrote this, I don't remember why other than the original version not working
	GAMEMODE:SetGNWVar("TeamScore" .. teamid, score)
	TeamScores[teamid] = score
end

function team.AddScore(teamid, score)
	team.SetScore(teamid, team.GetScore(teamid) + score)
end

function team.GetScore(teamid)
	if not teamid then
		return
	end
	if not TeamScores[teamid] then
		TeamScores[teamid] = 0
	end
	if SERVER then
		return TeamScores[teamid]
	end
	if CLIENT then
		return GAMEMODE:GetGNWVar("TeamScore" .. teamid)
	end
end

function team.GetScoreLimit(teamid)
	local infoent = team.GetInfoEnt(teamid)
	return IsValid(infoent) and infoent:GetScoreLimit() or (IsValid(GAMEMODE:GetInfoEnt()) and GAMEMODE:GetInfoEnt():GetScoreLimit() or 0)
end

function team.GetWins(teamid)
	return GAMEMODE:GetGNWShort("TeamWins" .. teamid)
end

function team.AddWin(teamid)
	GAMEMODE:SetGNWShort("TeamWins" .. teamid, team.GetWins(teamid) + 1)
end

function GM:PlayerJoinTeam(pl, teamid)
	local oldteam = pl:Team()
	pl:SetFrags(0)
	pl:SetDeaths(0)
	if teamid == TEAM_SPECTATOR then
		pl:Spectate(OBS_MODE_ROAMING)
	elseif pl:Team() == TEAM_SPECTATOR then
		--pl:UnSpectate()
	end
	pl:SetTeam(teamid)
	gamemode.Call("OnPlayerChangedTeam", pl, oldteam, teamid)
end

local SWAPPED = 0
local NO_COOLDOWN = 1
local NO_UNJOINABLE = 2
local NO_YOURLIVES = 3
local NO_TEAMLIVES = 4
local NO_THEIRLIVES = 5

if SERVER then
	util.AddNetworkString("sdm_plchangedteam")

	--helper for sending a localized message on the client
	local function displayinchat(pl, oldteam, newteam, reason)
		net.Start("sdm_plchangedteam")
			net.WriteEntity(pl)
			net.WriteUInt(oldteam, 10)
			net.WriteUInt(newteam, 10)
			net.WriteUInt(reason, 3)
		if reason == SWAPPED then
			net.Broadcast()
		else
			net.Send(pl)
		end
	end

	function GM:PlayerRequestTeam(pl, teamid)
		if pl:Team() == teamid then
			return
		end
		if not pl.NextTeamswitch then
			pl.NextTeamswitch = 0
		end
		-- This team isn't joinable
		if (teamid ~= TEAM_SPECTATOR) and (pl.NextTeamswitch > CurTime()) then
			--using "old team" as our time remaining for the message
			displayinchat(pl, math.ceil(pl.NextTeamswitch - CurTime()), teamid, NO_COOLDOWN)
			return
		end
		if (not GAMEMODE:PlayerCanJoinTeam(pl, teamid)) then
			-- Messages here should be outputted by this function
			return
		end
		if pl:Team() ~= TEAM_SPECTATOR then
			local wasalive = pl:Alive()
			if wasalive then pl:Kill() end
			pl.NextSpawnTime = CurTime() + team.GetSpawnTime(teamid)
			-- don't lose a life for team swapping
			local teamrules = team.GetInfoEnt(pl:Team())
			if IsValid(teamrules) and wasalive and teamid ~= TEAM_SPECTATOR then
				if not teamrules:GetPooledLives() then
					pl:AddLives(1)
				else
					teamrules:SetLives(teamrules:GetLives() + 1)
				end
			end
		else
			--pl:Kill()
			pl:KillSilent()
		end
		self:PlayerJoinTeam(pl, teamid)
	end

	function GM:PlayerCanJoinTeam(pl, teamid)
		if teamid == TEAM_SPECTATOR then return true end
		if not team.Joinable(teamid) then displayinchat(pl, 0, teamid, NO_UNJOINABLE) return false end
		
		
		--Handle lives
		--[[A player having negative lives means they aren't using the lives system on their current team.
		However, players could be switching to a team that does use lives, or from one that does to one that doesn't.
		Players could also switch from a team that doesn't use pooled lives to one that does, or vice versa.
		There's a lot of potential permutations. Generally, we don't want players gaming the system for more lives than they should'a had.]]

		local playerlives = pl:Lives()
		--player has no lives, it's always a no
		if playerlives == 0 then displayinchat(pl, 0, teamid, NO_YOURLIVES) return false end
		

		local teamrules = team.GetInfoEnt(teamid)
		--shouldn't happen, but y'know
		if not IsValid(teamrules) then return true end
		
		local teamlives = teamrules:GetLives()
		local lifepool = teamrules:GetPooledLives()
		local curteam = pl:Team()
		local curteamrules = team.GetInfoEnt(curteam)
		local curteamlives = IsValid(curteamrules) and curteamrules:GetLives() or 0
		local curteampool = IsValid(curteamrules) and curteamrules:GetPooledLives() or false
		
		--player's current team uses pooled lives, don't let them leave if it's out of lives
		if curteampool then
			if curteamlives <= 0 then
				displayinchat(pl, curteam, teamid, NO_TEAMLIVES)
				return false
			--give the player the lower of their lives or their new team's lives
			elseif teamlives > 0 and playerlives > 0 then
				pl:SetLives(math.min(teamlives, playerlives))
			end
			return true
		end

		--other team has lives, give player the lower of the two counts (unless they didn't use lives before, then give them this team's count)
		if teamlives > 0 then
			pl:SetLives(playerlives < 0 and teamlives or math.min(teamlives, playerlives))
			return true
		end

		if lifepool then
			displayinchat(pl, curteam, teamid, NO_THEIRLIVES)
		end
		return not lifepool
	end


	function GM:OnPlayerChangedTeam(pl, oldteam, newteam)
		if (oldteam == newteam) then
			return
		end

		if (newteam ~= TEAM_SPECTATOR) then
			pl.NextTeamswitch = CurTime() + 10
		end
		displayinchat(pl, oldteam, newteam, SWAPPED)
	end
else
	net.Receive("sdm_plchangedteam", function()
		local pl = net.ReadEntity()
		if not IsValid(pl) then return end

		local oldteam = net.ReadUInt(10)
		local newteam = net.ReadUInt(10)
		local swapped = net.ReadUInt(3)
		local oldteamname = team.PrintName(oldteam)
		local newteamname = team.PrintName(newteam)

		if swapped == SWAPPED then
			if newteam == TEAM_SPECTATOR then
				chat.AddText(ScavLocalizeColor("scav.team.select.spectate", pl:Name(), team.GetColor(oldteam)))
			elseif oldteam == TEAM_SPECTATOR then
				local dm = (newteam == TEAM_UNASSIGNED)
				chat.AddText(ScavLocalizeColor(dm and "scav.team.select.dm" or "scav.team.select.join", pl:Name(), dm and pl:GetPlayerColor():ToColor() or newteamname, team.GetColor(newteam)))
			else
				chat.AddText(ScavLocalizeColor("scav.team.select.switch", pl:Name(), newteamname, oldteamname, team.GetColor(newteam), team.GetColor(oldteam)))
			end
			
			gamemode.Call("OnPlayerChangedTeam", pl, oldteam, newteam)
		--Rest of these are failure messages
		elseif swapped == NO_COOLDOWN then
			chat.AddText(ScavLocalizeColor("scav.team.select.cooldown", oldteam, team.GetColor(oldteam)))
		elseif swapped == NO_UNJOINABLE then
			chat.AddText(ScavLocalizeColor("scav.team.select.nojoin", newteamname, team.GetColor(newteam)))
		elseif swapped == NO_YOURLIVES then
			chat.AddText(ScavLocalizeColor("scav.team.select.nolives"))
		else
			local t = (swapped == NO_TEAMLIVES)
			chat.AddText(ScavLocalizeColor("scav.team.select.nolives.team", t and oldteamname or newteamname, team.GetColor(t and oldteam or newteam)))
		end
	end)
end

GM.teamstuff = {}
function GM.teamstuff.sortbyfrags(a, b)
	if not IsValid(a) or not IsValid(b) then return end
	--Most frags
	if a:Frags() ~= b:Frags() then return (a:Frags() > b:Frags()) end
	--Fewest deaths
	if a:Deaths() ~= b:Deaths() then return (a:Deaths() < b:Deaths()) end
	--Slot order
	return (a:EntIndex() < b:EntIndex())
end

SortPlayersByScore = GM.teamstuff.sortbyfrags

function GM:GetTeamPlayersByPlace(n_team)
	self.teamstuff.scoresort[n_team] = team.GetPlayers(n_team)
	table.sort(self.teamstuff.scoresort[n_team], SortPlayersByScore)
	return self.teamstuff.scoresort[n_team]
end

function team.GetSortedPlayers(teamnum)
	local players = team.GetPlayers(teamnum)
	table.sort(players, SortPlayersByScore)
	return players
end

function team.SetLives(lives) --this function sets how many lives a team's players spawn with
end

