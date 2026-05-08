DEFINE_BASECLASS("gamemode_base")

--GAMEMODE INFO

GM.Name		= "Scavenger Deathmatch"
GM.Author	= "Ghor"

--EXTERNAL FILES

if SERVER then
	include("loader.lua")
end

include("enum.lua")
AddCSLuaFile("enum.lua")

include("GNWVar.lua")
AddCSLuaFile("GNWVar.lua")

function GM:GetMode()
	return self:GetGNWVar("mode") or 0
end

include("stats.lua")
AddCSLuaFile("stats.lua")

include("weapons.lua")
AddCSLuaFile("weapons.lua")

include("player.lua")
AddCSLuaFile("player.lua")

include("teams.lua")
AddCSLuaFile("teams.lua")

include("rounds.lua")
AddCSLuaFile("rounds.lua")

include("character.lua")

local modetranslate = {
	[SDM_MODE_DM] = "scav.mode.dm",
	[SDM_MODE_DM_TEAM] = "scav.mode.tdm",
	[SDM_MODE_CTF] = "scav.mode.ctf",
	[SDM_MODE_CELLCONTROL] = "scav.mode.cell",
	[SDM_MODE_HOARD] = "scav.mode.hoard",
	[SDM_MODE_SURVIVAL] = "scav.mode.survive",
	[SDM_MODE_CAPTURE] = "scav.mode.cap",
	[SDM_MODE_CUSTOM] = "scav.mode.custom"
}

function GM:Initialize()
	
end

function GM:GetModeName()
	local mode = self:GetMode()
	return ScavLocalize(modetranslate[mode])
end



if SERVER then --include server files, send client files
	AddCSLuaFile("vgui/commoncontrols.lua")
	AddCSLuaFile("vgui/scoreboard.lua")
	AddCSLuaFile("vgui/mainmenu.lua")
	AddCSLuaFile("vgui/teamsmenu.lua")
	AddCSLuaFile("HUD.lua")
	util.AddNetworkString("scav_gm_vote")
	util.AddNetworkString("sdm_game_mods")

	local sendallmods = function(pl)
		for k, v in pairs(GAMEMODE.Loader.data.gamevars) do
			local _, _, k = string.find(k, "sdm_main_mod_(.+)")
			if not k then continue end

			net.Start("sdm_game_mods")
				net.WriteString(k)
				net.WriteBool(v or false)
			if pl then net.Send(pl) else net.Broadcast() end
		end
	end

	hook.Add("OnGLoaderSpawn", "sdm_game_mods", function()
		sendallmods()
		hook.Add("PlayerInitialSpawn", "sdm_game_mods", sendallmods)
	end)

	net.Receive("sdm_game_mods", function()
		local pl = net.ReadPlayer()
		if not IsValid(pl) then return end
		local gamevar = net.ReadString()
		if gamevar == "" then return end

		local mod = GAMEMODE:GetGameMod(gamevar)
		net.Start("sdm_game_mods")
			net.WriteString(gamevar)
			net.WriteBool(mod or false)
		net.Send(pl)
	end)

else --include client files
	include("vgui/commoncontrols.lua")
	include("vgui/scoreboard.lua")
	include("vgui/mainmenu.lua")
	include("vgui/teamsmenu.lua")
	include("HUD.lua")

	net.Receive("scav_gm_vote", function()
		LocalPlayer():PrintMessage(HUD_PRINTTALK, ScavLocalize("scav.map.timeup"))
	end)

	function GM:AddDeathNotice(attacker, attackerteam, inflictor, victim, victimteam) return end
	function GM:DrawDeathNotice(x, y) return end

	GM.gamevars = {}

	net.Receive("sdm_game_mods", function()
		local name = net.ReadString()
		local setting = net.ReadBool()
		GAMEMODE.gamevars[name] = setting
	end)

	function GM:GetGameMod(var)
		if not isstring(var) or var == "" then return end
		if self.gamevars[var] ~= nil then return self.gamevars[var] end

		net.Start("sdm_game_mods")
			net.WritePlayer(LocalPlayer())
			net.WriteString(var)
		net.SendToServer()
	end
end

if CLIENT then return end

function GM:Think()
	if self:IsRoundInProgress() then return end
	if self:GetGNWFloat("MapEndTime") >= CurTime() then return end
	if GetGlobalFloat("sdm_votedeadline") ~= 0 then return end

	net.Start("scav_gm_vote")
	net.Broadcast()
	
	for _, v in pairs(player.GetHumans()) do
		v:ConCommand("sdm_vote")
	end
	ScavData.SetVotingDeadline(30)
end
