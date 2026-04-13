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