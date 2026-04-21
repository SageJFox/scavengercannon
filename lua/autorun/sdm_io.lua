--specific key words for matching
local targetname_keywords = {
	["!player"] = function(ent, checker, activator, caller) return ent == Entity(1) end,
	["player"] = function(ent, checker, activator, caller) return ent:IsPlayer() end,
	["!caller"] = function(ent, checker, activator, caller) return ent == caller end,
	["!activator"] = function(ent, checker, activator, caller) return ent == activator end,
	["!self"] = function(ent, checker, activator, caller) return ent == checker end,
	["!pvsplayer"] = function(ent, checker, activator, caller)
		if not ent:IsPlayer() then return false end
		local looker = caller
		if not looker then looker = activator or checker end
		if not looker then return targetname_keywords["!player"](ent) end

		return looker:TestPVS(ent)
	end,
	["!picker"] = function(ent, checker, activator, caller)
		if not IsValid(Entity(1)) then return end
		return ent == Entity(1):GetEyeTrace().Entity
	end
}

--sublogic for targetname function
local function targetnamematch(entname, name, checker, activator, caller)
	local activator = activator or ACTIVATOR
	local caller = caller or CALLER
	--technically more robust than Source I/O according to VDC?
	local target = "^" .. string.Replace(name, "*", "[^!*]+") .. "$"
	local match = string.find(entname, name)
	return isnumber(match)
end

--function check for a Source I/O targetname match on a given entity 
function targetname(ent, name, checker, activator, caller)
	if not name or name == "" then return false end
	if not IsValid(ent) then return false end

	if targetname_keywords[name] then return targetname_keywords[name](ent, checker, activator, caller) end
	--to be 100% accurate, should check every entity for targetname matching before trying class name
	--(but chances are great that nobody cares)
	return targetnamematch(ent:GetName(), name, checker, activator, caller) or targetnamematch(ent:GetClass(), name, checker, activator, caller)
end