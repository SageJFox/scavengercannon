local weps = {
	"weapon_backuppistol",
	"weapon_blackholegun",
	"weapon_alchemygun"
}

function GM:GetValidWeapons()
	return weps
end

if CLIENT then
	hook.Add("InitPostEntity", "wepslots", function()
		for _, v in pairs(weps) do
			local SWEP = weapons.GetStored(v)
			SWEP.Slot = 1
			SWEP.SlotPos = 0
		end
	end)
else
	function GM:PlayerLoadout(pl)
		local wep = string.lower(pl:GetInfo("sdm_w2"))
		pl:Give(table.HasValue(weps, wep) and wep or "weapon_backuppistol")
		pl:Give("scav_gun")
		pl:SelectWeapon("scav_gun")
	end
end