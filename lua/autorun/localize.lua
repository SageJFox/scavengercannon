AddCSLuaFile()

--Localize a Scav string, replacing any instances of %#% with the second, etc. arguments
--Can add a false to prevent the next token from being localized
ScavLocalize = function(...)
	local arg = {...}
	local substr = tostring(table.remove(arg, 1))
	local strang = CLIENT and language.GetPhrase(substr) or substr
	local i = 0
	local rep = true
	for _, v in ipairs(arg) do
		if isbool(v) then
			rep = v
			continue
		else
			i = i + 1
		end
		strang = string.Replace(strang, "%" .. i .. "%", (CLIENT and rep) and language.GetPhrase(tostring(v)) or tostring(v))
		rep = true
	end
	return strang
end

if SERVER then return end

--ScavLocalize, but returns a vararg with colordata for use with chat.AddText
--Provide a color with a valid hex format like %#RRGGBB% OR use named variables such as:
-- %TEAMCOLOR% to get the local player's team color (or player color on non-team modes)
-- %PERCENT% to get a percent sign
ScavLocalizeColor = function(...)
	local arg = {...}
	local substr = tostring(table.remove(arg, 1))
	local strang = language.GetPhrase(substr)
	local rawtab = string.Explode("%%%%?", strang, true)
	local tcol = team.GetColor(LocalPlayer():Team())
	if LocalPlayer():Team() == TEAM_UNASSIGNED or LocalPlayer():Team() == TEAM_CONNECTING or LocalPlayer():Team() == TEAM_SPECTATOR then
		local pcol = LocalPlayer():GetPlayerColor()
		tcol.r = pcol[1] * 255
		tcol.g = pcol[2] * 255
		tcol.b = pcol[3] * 255
	end
	--handle the rest of our arguments
	local inserttab = {}
	local i = 0
	local rep = true
	for _, v in ipairs(arg) do
		if isbool(v) then
			rep = v
			continue
		else
			i = i + 1
		end
		table.insert(inserttab, rep and language.GetPhrase(tostring(v)) or tostring(v))
		rep = true
	end
	--put it all together
	local tab = {}
	for _, v in ipairs(rawtab) do
		if not v or v == "" then continue end
		
		if v == "PERCENT" then
			table.insert(tab, "%")
			continue
		end
		if v == "TEAMCOLOR" then
			table.insert(tab, tcol)
			continue
		end
		--a color (but don't try to convert "#1" to hex)
		local start, ending = string.find(v, "^#[%dA-Fa-f]+$")
		if start and ending - start >= 3 then
			table.insert(tab, HexToColor(v))
			continue
		end
		--our insert tokens (do what we can to avoid catching unexpected lone numbers)
		local insert = tonumber(v)
		if insert and insert == math.floor(insert) and insert > 0 and insert <= #inserttab then
			table.insert(tab, inserttab[insert])
			continue
		end
		table.insert(tab, v)
	end

	return unpack(tab)
end