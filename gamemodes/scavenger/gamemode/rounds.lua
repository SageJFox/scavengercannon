GM:SetGNWVar("RoundInProgress", false)
GM:SetGNWVar("RoundStartTime", 0)
GM:SetGNWVar("RoundEndTime", 0)
GM:SetGNWVar("PreRound", false)

ENDCONDITION_TIME = 0
ENDCONDITION_FRAG = 1
ENDCONDITION_LIVES = 2
ENDCONDITION_CANCELED = 3
ENDCONDITION_CUSTOM = 4

--SetNextRoundStartTime
--CanStartRound


if SERVER then
	local roundinprogress = function()
		return (not GAMEMODE:GetGNWVar("PreRound") and GAMEMODE:IsRoundInProgress())
	end
	hook.Add("Think", "RoundManage", function()
		local self = GAMEMODE
		if roundinprogress() and self:GetGNWVar("RoundEndTime") ~= 0 and CurTime() > self:GetGNWVar("RoundEndTime") then
			self:EndRound(ENDCONDITION_TIME)
		end
	end)

	local teaments = {}
	local teamcount = 0

	hook.Add("Think", "PreLivesManage", function()

		--can't lifethink if we haven't had our teams init yet
		if teamcount == 0 then
			teaments = team.GetInfoEnts()
			teamcount = table.Count(teaments)

			--putting the "gamemode not using lives" check in here, as we only want it running once
			if teamcount > 0 then
				--check through our teams, if one uses lives, get outta here...
				for t, teaminfo in pairs(teaments) do
					if teaminfo:GetPooledLives() then return end
					if teaminfo:GetLives() > 0 then return end
				end
				--...otherwise none of the following logic matters, and we shouldn't waste our time thinkin' it
				hook.Remove("Think", "PreLivesManage")
			end
			return
		end

		--if our game is using lives, end the round if all but one team/player is spent
		hook.Add("Think", "LivesManage", function()
			local self = GAMEMODE

			if not self:HasEnoughPlayersForRound() then return end
			if not roundinprogress() then return end

			local teamsout = {}

			for t, teaminfo in pairs(teaments) do
				local pooled = teaminfo:GetPooledLives()
				local lives = teaminfo:GetLives()
				--team's still got lives, they're still in
				if not pooled and lives <= 0 then continue end

				local stillin = false
				--team may be out of pooled lives, but players could still be living
				if pooled then
					if lives > 0 then continue end
					for _, pl in ipairs(team.GetPlayers(t)) do
						if not pl:Alive() then continue end
						stillin = true 
						break
					end
					if not stillin then teamsout[t] = true continue end
				end
				--a non-pooled team's only out if every player has exhausted their lives and is currently dead
				for _, pl in ipairs(team.GetPlayers(t)) do
					if not pl:Alive() and pl:Lives() == 0 then continue end
					stillin = true 
					break
				end
				if #team.GetPlayers(t) == 0 then stillin = true end --don't let a team drop out before it ever had players
				if not stillin then teamsout[t] = true continue end
			end

			--we still have multiple teams in, no win by lives yet
			local activeteams = teamcount - table.Count(teamsout)
			if activeteams > 1 then return end
			local mode = self:GetMode()

			--if we only have one team in, check if it's a mode that only *has* one team
			if mode == SDM_MODE_DM or mode == SDM_MODE_SURVIVAL then
				local playercount = 0
				for _, pl in ipairs(player.GetAll()) do
					if not team.IsReal(pl:Team(), true) then continue end
					if not pl:Alive() and pl:Lives() == 0 then continue end

					playercount = playercount + 1
				end
				--we've got more than one player left, it ain't over yet
				if playercount > 1 then return end
			end

			
			self:EndRound(ENDCONDITION_LIVES)
		end)

		--we put in our Lives manager, now we can rest
		hook.Remove("Think", "PreLivesManage")
	end)
end

if CLIENT then

	local colmod = {}
	colmod[ "$pp_colour_addr" ]			= 0
	colmod[ "$pp_colour_addg" ]			= 0
	colmod[ "$pp_colour_addb" ]			= 0
	colmod[ "$pp_colour_brightness" ]	= 0
	colmod[ "$pp_colour_contrast" ]		= 1
	colmod[ "$pp_colour_colour" ]		= 1
	colmod[ "$pp_colour_mulr" ]			= 0
	colmod[ "$pp_colour_mulg" ]			= 0
	colmod[ "$pp_colour_mulb" ]			= 0

	local function docolormod()
		if GAMEMODE:IsRoundInProgress() then
			colmod["$pp_colour_addb"] = math.Approach(colmod["$pp_colour_addb"], 0, FrameTime() * 5)
			--colmod["$pp_colour_brightness"] = math.Approach(colmod["$pp_colour_brightness"], 0, FrameTime() / 3)
			colmod["$pp_colour_colour"] = math.Approach(colmod["$pp_colour_colour"], 1, FrameTime() / 3)
			--colmod["$pp_colour_contrast"] = math.Approach(colmod["$pp_colour_contrast"], 1, FrameTime() / 3)
		else
			colmod["$pp_colour_addb"] = math.Approach(colmod["$pp_colour_addb"], 0.1, FrameTime() * 5)
			--colmod["$pp_colour_brightness"] = math.Approach(colmod["$pp_colour_brightness"], -0.37, FrameTime() / 3)
			colmod["$pp_colour_colour"] = math.Approach(colmod["$pp_colour_colour"], 0.2, FrameTime() / 3)
			--colmod["$pp_colour_contrast"] = math.Approach(colmod["$pp_colour_contrast"], 0.94, FrameTime() / 3)
		end
		DrawColorModify(colmod)
	end
	hook.Add("RenderScreenspaceEffects", "RoundColor", docolormod)
end

function GM:SetRoundEndTime(time)
	if SERVER then
		self:SetGNWVar("RoundEndTime", time)
	end
end

function GM:AddRoundTime(time)
	self:SetRoundEndTime(self:GetGNWVar("RoundEndTime") + time)
end

function GM:StartRound(timelimit, delay)
	local timelimit = timelimit or self:GetGNWFloat("TimeLimit")
	local delay = delay or 3
	if not self:IsRoundInProgress() then
		gamemode.Call("OnPreRoundStart", delay)
		game.CleanUpMap()
		gamemode.Call("DoSetup")
		self:SetGNWVar("PreRound", true)
		self:SetGNWVar("RoundInProgress", true)
		self:PreparePlayers()
		for k, v in pairs(self.Teams) do
			team.SetScore(k, 0)
		end
		timer.Simple(delay, function() gamemode.Call("OnRoundStart", timelimit) end)
	end
end

function GM:HasEnoughPlayersForRound()
	return true
end

function GM:OnPreRoundStart(delay)
end

local endroundlogic = {
	[SDM_MODE_DM] = {
		[ENDCONDITION_TIME] = function()
			local winners, highscore = {}, 0
			local losers = player.GetHumans()
			--find our winner(s)
			for _, pl in ipairs(losers) do
				if not team.IsReal(pl:Team(), true) then continue end

				pl:AddScavStat(SCAVSTAT_GAMESPLAYED)
				local score = pl:Frags()
				if score < highscore then continue end

				if score > highscore then
					winners = {pl}
					highscore = score
					continue
				end

				table.insert(winners, pl)
			end
			--award a win, or draws
			local tie = (#winners > 1 or highscore <= 0)
			for _, winner in ipairs(winners) do
				winner:AddScavStat(tie and SCAVSTAT_DRAWS or SCAVSTAT_WINS)
				table.RemoveByValue(losers, winner)
			end
			--womp womp
			for _, loser in ipairs(losers) do
				loser:AddScavStat(highscore <= 0 and SCAVSTAT_DRAWS or SCAVSTAT_LOSSES)
			end
		end,
		[ENDCONDITION_LIVES] = function()
			local winners, losers = {}, {}
			--find our winners (should only be one if this wasn't for a timeout)
			for _, pl in ipairs(player.GetAll()) do
				if not team.IsReal(pl:Team(), true) then continue end
				if pl:Alive() or pl:Lives() > 0 then
					table.insert(winners, pl)
					continue
				end

				if pl:IsBot() then continue end
				table.insert(losers, pl)
			end
			--stats awarding
			--hand out losses, or draws if zero surviving players
			for _, loser in ipairs(losers) do
				loser:AddScavStat(SCAVSTAT_GAMESPLAYED)
				loser:AddScavStat(#winners == 0 and SCAVSTAT_DRAWS or SCAVSTAT_LOSSES)
			end
			--hand out a win, or draws if multiple surviving players
			for _, winner in ipairs(winners) do
				if winner:IsBot() then continue end
				--a winner is you
				winner:AddScavStat(SCAVSTAT_GAMESPLAYED)
				winner:AddScavStat(#winners == 1 and SCAVSTAT_WINS or SCAVSTAT_DRAWS)
			end
		end,
	},
	[SDM_MODE_DM_TEAM] = {
		[ENDCONDITION_TIME] = function()
			local winners, highscore = {}, 0
			local losers = player.GetHumans()
			local tie = false
			--find our winner(s)
			for t, _ in pairs(team.GetAllTeams()) do
				if not team.IsReal(t, true) then continue end
				
				local score = team.GetScore(t)
				if score < highscore then continue end

				if score > highscore then
					winners = team.GetPlayers(t)
					highscore = score
					tie = false
					continue
				end

				table.Add(winners, team.GetPlayers(t))
				tie = true
			end
			--award a win, or draws
			for _, winner in ipairs(winners) do
				--remove first so if it's a bot we don't have to double process it
				table.RemoveByValue(losers, winner)
				if winner:IsBot() then continue end

				winner:AddScavStat(tie and SCAVSTAT_DRAWS or SCAVSTAT_WINS)
				winner:AddScavStat(SCAVSTAT_GAMESPLAYED)
			end
			--womp womp
			for _, loser in ipairs(losers) do
				if loser:IsBot() then continue end
				loser:AddScavStat(highscore <= 0 and SCAVSTAT_DRAWS or SCAVSTAT_LOSSES)
				loser:AddScavStat(SCAVSTAT_GAMESPLAYED)
			end
		end,
	},
	[SDM_MODE_CTF] = {},
	[SDM_MODE_SURVIVAL] = {},
}
endroundlogic[SDM_MODE_DM_TEAM][ENDCONDITION_LIVES] = endroundlogic[SDM_MODE_DM][ENDCONDITION_LIVES]
endroundlogic[SDM_MODE_CTF][ENDCONDITION_TIME] = endroundlogic[SDM_MODE_DM_TEAM][ENDCONDITION_TIME]
endroundlogic[SDM_MODE_CTF][ENDCONDITION_LIVES] = endroundlogic[SDM_MODE_DM_TEAM][ENDCONDITION_LIVES]
endroundlogic[SDM_MODE_SURVIVAL][ENDCONDITION_TIME] = endroundlogic[SDM_MODE_DM][ENDCONDITION_LIVES]
endroundlogic[SDM_MODE_SURVIVAL][ENDCONDITION_LIVES] = endroundlogic[SDM_MODE_DM][ENDCONDITION_LIVES]

function GM:EndRound(endcondition)
	if not self:IsRoundInProgress() then return end
	self:SetGNWVar("RoundEndTime", 0)
	gamemode.Call("OnRoundEnd")

	if endroundlogic[self:GetMode()] and endroundlogic[self:GetMode()][endcondition] then
		endroundlogic[self:GetMode()][endcondition]()
	end

	--reset all players' lives (ensures spectators get to choose a team and respawn)
	for _, pl in ipairs(player.GetAll()) do
		pl:SetLives(-1)
	end
	--reset teams' lives from its template
	for t, teaminfo in pairs(team.GetInfoEnts()) do
		if not teaminfo.TemplateID or not self.Loader or not self.Loader.templates then continue end

		local template = self.Loader.templates[teaminfo.TemplateID]

		if not template or not template.KeyValues or not template.KeyValues.lives then continue end
		local lives = template.KeyValues.lives
		--not using lives, team's lives never changed
		if lives < 0 then continue end

		teaminfo:SetLives(lives)
		--grant this team's players their appropriate lives
		for _, pl in ipairs(team.GetPlayers(t)) do
			pl:SetLives(lives)
		end
	end
end

function GM:EndRoundTeam(winningteam, wincondition)
	if not self:IsRoundInProgress() then return end
	gamemode.Call("OnRoundEnd")

	local winners = team.GetPlayers(winningteam)
	local losers = player.GetHumans()
	for _, winner in ipairs(winners) do
		table.RemoveByValue(losers, winner)
		if winner:IsBot() then continue end
		winner:AddScavStat(SCAVSTAT_GAMESPLAYED)
		winner:AddScavStat(SCAVSTAT_WINS)
	end

	for _, loser in ipairs(losers) do
		if loser:IsBot() then continue end
		loser:AddScavStat(SCAVSTAT_GAMESPLAYED)
		loser:AddScavStat(SCAVSTAT_LOSSES)
	end
end

function GM:EndRoundPlayer(winningplayer, wincondition)
	if not self:IsRoundInProgress() then return end
	gamemode.Call("OnRoundEnd")

	winningplayer:AddScavStat(SCAVSTAT_GAMESPLAYED)
	winningplayer:AddScavStat(SCAVSTAT_WINS)

	local losers = player.GetHumans()
	table.RemoveByValue(losers, winningplayer)
	for _, loser in ipairs(losers) do
		loser:AddScavStat(SCAVSTAT_GAMESPLAYED)
		loser:AddScavStat(SCAVSTAT_LOSSES)
	end
end

function GM:IsRoundInProgress()
	return self:GetGNWVar("RoundInProgress")
end

function GM:PreparePlayers()
	for _, v in pairs(player.GetAll()) do	
		v:SetFrags(0)
		v:SetDeaths(0)
		if not v:IsSpectator() then
			v:KillSilent()
			v:Spawn()
		end
	end
end

if SERVER then
	util.AddNetworkString("sdm_roundstartend")

	function GM:OnRoundStart()
		local ctime = CurTime()
		self:SetGNWVar("RoundStartTime", ctime)
		local timelimit = self:GetGameVar("timelimit")
		if timelimit == 0 then
			self:SetRoundEndTime(0)
		else
			self:SetRoundEndTime(ctime + timelimit)
		end
		self:SetGNWVar("PreRound", false)
		net.Start("sdm_roundstartend")
			net.WriteBool(true)
		net.Broadcast()
		
		--[[for k, v in pairs(player.GetAll()) do
			if not v:IsSpectator() then
				--v:Freeze(false)
			end
		end]]
	end

	function GM:OnRoundEnd()
		self:SetGNWVar("RoundInProgress", false)
		net.Start("sdm_roundstartend")
			net.WriteBool(false)
		net.Broadcast()
		timer.Simple(15, function() self:StartRound() end)
	end
end

function GM:GetInitialTimeLimit()
	return self:GetGNWVar("TimeLimit")
end


--[[if SERVER then
	hook.Add("PlayerSpawn", "PreroundFreeze", function(pl)
		if GAMEMODE:GetGNWVar("PreRound") then
			pl:Freeze(true)
		end
	end)
end]]

hook.Add("Move", "PreroundFreeze", function(pl, movedata)
	if GAMEMODE:GetGNWVar("PreRound") then
		movedata:SetMaxClientSpeed(0)
		movedata:SetMaxSpeed(0)
		movedata:SetForwardSpeed(0)
		movedata:SetSideSpeed(0)
	end
end)

if CLIENT then
	net.Receive("sdm_roundstartend", function()
		gamemode.Call(net.ReadBool() and "OnRoundStart" or "OnRoundEnd")
	end)

	function GM:OnRoundStart()
		surface.PlaySound("ambient/alarms/warningbell1.wav")
	end

	function GM:OnRoundEnd()
		surface.PlaySound("ambient/explosions/explode_8.wav")
	end
end
