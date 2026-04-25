AddCSLuaFile()

if not CLIENT then return end

local PANEL = {}
	PANEL.LastRefreshTime = 0
	PANEL.m_bgColor = Color(50, 50, 50, 255)
	PANEL.LabelColor = Color(210, 210, 210, 16)
	function PANEL:Init()
		self:SetTitle("")
		self.Title = vgui.Create("DLabel", self)
			self.Title:SetText("#scav.vote.title")
			self.Title:SetFont("DermaLarge")
			self.Title:SetTextColor(self.LabelColor)
			self.Title:SizeToContents()
		self:MakePopup()
		self.VotedSettingsLabel = vgui.Create("DLabel", self)
			self.VotedSettingsLabel:SetFont("Scav_MenuLarge")
			self.VotedSettingsLabel:SetText("#scav.vote.settings.voted")
			self.VotedSettingsLabel:SizeToContents()
		self.FilesLabel = vgui.Create("DLabel", self)
			self.FilesLabel:SetFont("Scav_MenuLarge")
			self.FilesLabel:SetText("#scav.vote.settings.all")
			self.FilesLabel:SizeToContents()
		self.Time = vgui.Create("DLabel", self)
			self.Time:SetText("")
			self.Time:SetFont("Scav_MenuLarge")
			--self.Time:SetTextColor(self.LabelColor)
			self.Time:SizeToContents()
		self:Refresh()
	end
	
	local function votedrowselect(self, line)
		self:GetParent().MapInfo:SetMap(self:GetLine(line):GetValue(1), self:GetLine(line):GetValue(2))
		self:GetParent().MapInfo:SetVisible(true)
		local filename = self:GetLine(line):GetValue(1) .. "/" .. self:GetLine(line):GetValue(2)
		if not ScavData.AllSettingsFiles[filename] then
			RunConsoleCommand("sdm_vote_requestmap", filename)
		end
		surface.PlaySound("buttons/button9.wav")
	end
	
	local deadline = 0
	
	local function RebuildVotedSettings(panel)
		deadline = GetGlobalFloat("sdm_votedeadline", 0)
		panel.settings = panel.settings or {}
		local settingswithvotes = {}
		local players = player.GetHumans()
		for _, pl in ipairs(players) do
			local filename = pl:GetNWString("sdm_vote")
			if filename ~= "" then
				settingswithvotes[filename] = true
			end
		end
		for k, v in pairs(panel.settings) do
			if v:IsValid() then
				if not settingswithvotes[k] then
					panel:RemoveLine(v:GetID())
					panel.settings[k] = nil
				else
					v:SetValue(3, 0)
				end
			end
		end
		for _, pl in ipairs(players) do
			local filename = pl:GetNWString("sdm_vote")
			if filename ~= "" then
				if not panel.settings[filename] or not panel.settings[filename]:IsValid() then
					local mapandsetting = string.Explode("/", filename)
					local map = mapandsetting[1]
					local setting = mapandsetting[2]
					panel.settings[filename] = panel:AddLine(map, setting, 1)
				else
					panel.settings[filename]:SetValue(3, panel.settings[filename]:GetValue(3) + 1)
				end
			end
		end
	end
	
	net.Receive("UpdateSDMVotes", function() if SDM_VOTEMENU:IsValid() then SDM_VOTEMENU.VotedSettings:Rebuild() end end)
	
	function PANEL:Refresh()
		if self.MapInfo and self.MapInfo:IsValid() then
			self.MapInfo:Remove()
		end
		if self.VotedSettings and self.VotedSettings:IsValid() then
			self.VotedSettings:Remove()
		end
		if self.Files and self.Files:IsValid() then
			self.Files:Remove()
		end
		self.MapInfo = vgui.Create("SDM_VoteMenuSettingInfo", self)
			self.MapInfo:SetVisible(false)
		self.VotedSettings = vgui.Create("DListView", self)
			self.VotedSettings.OnRowSelected = votedrowselect
				self.VotedSettings.ColMap = self.VotedSettings:AddColumn("#scav.vote.map")
				self.VotedSettings.ColSetting = self.VotedSettings:AddColumn("#scav.vote.settings")
				self.VotedSettings.ColVotes = self.VotedSettings:AddColumn("#scav.vote.votes")
			self.VotedSettings:SetMultiSelect(false)
			self.VotedSettings.Rebuild = RebuildVotedSettings
			self.VotedSettings:Rebuild()
		self.Files = vgui.Create("SDM_VoteMenuMapContainer", self)
			self.Files:SetMultiSelect(false)
		self:InvalidateLayout()
	end

	function PANEL:InvalidateLayout()
		self.Title:SetPos(12, 10)
		self.VotedSettingsLabel:SetPos(32, 48)
		self.VotedSettings:SetPos(48, 64)
		local votedsettingwidth = self:GetWide() / 3 - 64
		self.VotedSettings:SetSize(votedsettingwidth, self:GetTall() / 3 - 64)
			self.VotedSettings.ColVotes:SizeToChildren(true, false)
			self.VotedSettings.ColVotes:SetMaxWidth(self.VotedSettings.ColVotes:GetWide() + 1)
		self.FilesLabel:SetPos(32, self:GetTall() / 3 + 16)
		self.Files:SetPos(48, self:GetTall() / 3 + 32)
		self.Files:SetSize(self:GetWide() / 3 - 64, self:GetTall() - 32 - self.Files.y)
		self.MapInfo:SetSize(self:GetWide() - 64 - (self.Files.x + self.Files:GetWide()), self:GetTall() - 64 - 32)
		self.MapInfo:SetPos((self.Files.x + self.Files:GetWide()) + 32, 64)
		self.Time:AlignBottom(12)
		self.Time:AlignRight(8)
	end
	
	function PANEL:AutoSetup()
		self:SetSize(ScrW() - 64, ScrH() - 64)
		self:SetPos(32, 32)
		self:InvalidateLayout()
	end
	
	function PANEL:Think()
		if self.LastRefreshTime + 2 < CurTime() then
			self.VotedSettings:Rebuild()
			self.LastRefreshTime = CurTime()
		end

		self.Time:SetText(deadline == 0 and "" or ScavLocalize("scav.vote.deadline", tostring(math.max(math.floor(deadline - CurTime()), 0))))
		if deadline == 0 then return end
		self.Time:SizeToContents()
		self.Time:AlignRight(8)
	end

	vgui.Register("SDM_VoteMenu", PANEL, "DFrame")


local PANEL = {}

	function PANEL:Init()
		self:SetSize(16, 16)
		self:SetText("")
		self.Star = true
	end

	function PANEL:TestHover(x, y)
		local w, h = self:GetWide() / 2, self:GetTall() / 2
		local r = math.min(w, h)
		local x, y = self:ScreenToLocal(x, y)
		local x1, y1 = w - r, h - r
		local x2, y2 = w + r, h + r
		if x < x1 or y < y1 or x > x2 or y > y2 then return false end
	end

	vgui.Register("DStar", PANEL, "DCheckBox")


local PANEL = {}

	function PANEL:Init()
		self:AddColumn("#scav.vote.map")
		self:AddColumn("#scav.vote.settings")
		local faves = self:AddColumn("#scav.vote.favorite")
		
		local maps = ScavData.GetValidMaps()
		for _, v in pairs(maps) do
			local split = string.Split(v, "/")
			local box = vgui.Create("DStar")
				--todo: real system lawl
				box:SetChecked(math.random(0, 1))
				box:SetSkin("sg_menu")
				--re-sort
				box.OnChange = function(self, check)
					local parent = self:GetParent()
					if not IsValid(parent) then return end
					parent:SetSortValue(3, check and -1 or 1)
				end
			local line = self:AddLine(split[1], split[2], box)
				--initial sort
				line:SetSortValue(3, box:GetChecked() and -1 or 1)
		end
		faves:SizeToChildren(true, false)
		faves:SetMaxWidth(faves:GetWide() + 1)
	end

	function PANEL:OnRowSelected(line)
		self:GetParent().MapInfo:SetMap(self:GetLine(line):GetValue(1), self:GetLine(line):GetValue(2))
		self:GetParent().MapInfo:SetVisible(true)
		local filename = self:GetLine(line):GetValue(1) .. "/" .. self:GetLine(line):GetValue(2)
		if not ScavData.AllSettingsFiles[filename] then
			RunConsoleCommand("sdm_vote_requestmap", filename)
		end
		surface.PlaySound("buttons/button9.wav")
	end
	
	function PANEL:AutoSize()
		self:SetSize(128, 200)
	end
	
	vgui.Register("SDM_VoteMenuMapContainer", PANEL, "DListView")

local PANEL = {}
	
	function PANEL:SetDesc(text)
		self.text = text
		self:SetText(text)
	end
	
	function PANEL:GetDesc()
		return self.text or ""
	end
	
	vgui.Register("SDM_VoteMenuDescLabel", PANEL, "DLabel")
	
local PANEL = {}

	--INFO
		--MaxPlayers (char)
		--Mode (string)
			--Point Limit (long)
			--Time Limit (float)
		--TeamPlay (bool)
			--Max Teams (char)
			--Friendly Fire (bool)
		--Damage Scale (float)
		--Rounds before vote(char)
		--Author Summary (string)
		--think about adding support for rotations

	PANEL.infovalid = true
	
	local function votebuttonpress(panel)
		surface.PlaySound("buttons/button4.wav")
		RunConsoleCommand("sdm_vote_submit", panel:GetParent().FileName or "..")
		--print(panel:GetParent().FileName)
	end
	
	local clearcache_instructions = "Clear the cache of generated map backgrounds. Specify a map name(s) or leave blank to clear all."
	local clearcache_instructions_displayed = false

	concommand.Add("sdm_vote_clearcache", function(ply, cmd, args, argstr)
		local has_args = #args > 0
		--if they're giving us arguments they *probably* know how this works, otherwise...
		clearcache_instructions_displayed = clearcache_instructions_displayed or has_args

		--...for our first call, give them instructions, rather than just do it (maybe they're just trying console stuff out)
		if not clearcache_instructions_displayed then
			print(clearcache_instructions)
			clearcache_instructions_displayed = true
			return
		end

		--track files deleted to report to user at the end
		local files = 0
		local size = 0

		local _, dirs = file.Find("scavdata/maps/*", "DATA")
		--if user gave us their list of maps, use that instead
		dirs = has_args and args or dirs
		for _, dir in ipairs(dirs) do
			local dir = "scavdata/maps/" .. dir .. "/bkg.png"

			if file.Exists(dir, "DATA") then
				size = size + file.Size(dir, "DATA")
				file.Delete(dir)
				files = files + 1
			end
		end
		print("Cleared " .. files .. " files, freeing " .. string.NiceSize(size) .. "!")
	end, nil, clearcache_instructions)

	function PANEL:Init() --before I'M visible there should be some sort of label instructing the player to select a map
		self.MapBG = vgui.Create("DImage", self)
			self.Paint = function() return end
			self.MapBG:SetImageColor(Color(128, 128, 128, 255))
			--override map background material. if we get a map thumbnail, generate a background or use a cached one
			self.MapBG.SetMaterial = function(self, mat)
				if isstring(mat) then return end
				self.m_Material = mat
				--find our map name
				local map = string.Split(mat:GetName(), "/")[3]

				local bkg_path = "scavdata/maps/" .. (map or "?")
				local full_path = "data/" .. bkg_path .. "/bkg.png"
				local bkg_exists = file.Exists(full_path, "GAME")
				--we have a cached background, use it
				if bkg_exists then
					self.m_Material = Material(full_path, "ignorez smooth 1")
				end

				if not self.m_Material then return end

				local Texture = self.m_Material:GetTexture("$basetexture")

				--no map found in provided material (must be missing thumbnail, use default)
				if not map then
					self.m_Material = Material("gui/noicon.png", "ignorez smooth 1 noclamp")
					--we don't want it thinking this is a valid thumbnail texture
					Texture = false
				end

				--valid thumbnail that hasn't been made into a background yet
				if Texture and not bkg_exists then
					--settings for saving out generated file
					local cap = {}
						cap.format = "png"
						cap.x = 0
						cap.y = 0
						cap.w = Texture:Width()
						cap.h = Texture:Height()
					
					self.ActualWidth = cap.w
					self.ActualHeight = cap.h

					--actual processing of the thumbnail, give it a moderate blur
					render.BlurRenderTarget(Texture, 8, 8, 0)

					--annoyingly, having console open causes render.Capture to return nil
					local bkg_gen = render.Capture(cap)
					if bkg_gen then
						--successful generation, cache and use it
						--note if it failed, that we still use the raw thumbnail as a background
						file.CreateDir(bkg_path)
						file.Write(bkg_path .. "/bkg.png", bkg_gen)
						self.m_Material = Material(full_path, "ignorez smooth 1")
					end
				else
					--generation failed or wasn't needed, we still want our SetMaterial call to properly update our internal vars
					self.ActualWidth = Texture and Texture:Width() or self.m_Material:Width()
					self.ActualHeight = Texture and Texture:Height() or self.m_Material:Height()
				end
			end
			--and override drawing, too. as a treat
			--todo: make this its own function for the derma?
			self.MapBG.Paint = function(self, w, h)
				--todo maybe: paint alpha with the tree so we don't have to worry about changes to the skin?
				--self:PaintAt(0, 0, w or self:GetWide(), h or self:GetTall())
				--self.tex.Tree(0, 0, w, h, self.m_bgColor)

				self:LoadMaterial()

				if not self.m_Material then return true end

				surface.SetMaterial(self.m_Material)
				surface.SetDrawColor(self.m_Color.r, self.m_Color.g, self.m_Color.b, self.m_Color.a)
				local R = 3 --border's 4 pixels, ensure we don't have a gap
				local TL, BL, TR, BR = 2, 7, 10, 3
				local x, y = 0, 0
				local u, v = 1, 1
				--set up tiling for generic background
				if string.find(self.m_Material:GetName(), "gui/noicon") then
					u, v = w / 128, h / 128
				end
				surface.DrawPoly({
					{
						["x"] = x + R,
						["y"] = y + R + TL,
						["u"] = 0,
						["v"] = 0 + TL / h * v
					},
					{
						["x"] = x + R + TL,
						["y"] = y + R,
						["u"] = 0 + TL / w * u,
						["v"] = 0
					},
					{
						["x"] = x + w - R - TR,
						["y"] = y + R,
						["u"] = u - TR / w * u,
						["v"] = 0
					},
					{
						["x"] = x + w - R,
						["y"] = y + R + TR,
						["u"] = u,
						["v"] = 0 + TR / h * v
					},
					{
						["x"] = x + w - R,
						["y"] = y + h - R - BR,
						["u"] = u,
						["v"] = v - BR / h * v
					},
					{
						["x"] = x + w - R - BR,
						["y"] = y + h - R,
						["u"] = u - BR / h * u,
						["v"] = v
					},
					{
						["x"] = x + R + BL,
						["y"] = y + h - R,
						["u"] = 0 + BL / h * u,
						["v"] = v
					},
					{
						["x"] = x + R,
						["y"] = y + h - R - BL,
						["u"] = 0,
						["v"] = v - BL / h * v
					}
				})
				--if CurTime() % 2 <= 1 then surface.DrawTexturedRect(x + R, y + R, w - 2 * R, h - 2 * R) end

				SKIN.tex.Window.Normal(0, 0, w, h)
				SKIN.tex.Tree_Shadow(0, 0, w, h, color_white)
			end
		self.DescriptionLabels = {}
		self.MapLabel = vgui.Create("DLabel", self)
			self.MapLabel:SetFont("Scav_HUDNumber3")
			self.MapLabel:SetPos(32, 16)
			self.MapLabel:SizeToContents()
		self.MapIcon = vgui.Create("DImage", self)
			self.MapIcon:SetSize(200, 200)
			self.MapIcon:SetPos(32, 64)
		--what the hell, here too
		self.MapIcon.Paint = function(self, w, h)
			local R = 4
			self:PaintAt(R, R, (w or self:GetWide()) - 2 * R, (h or self:GetTall()) - 2 * R)
			SKIN.tex.Panels.Preview(0, 0, w, h)
		end
		self.SettingNameLabel = self:AddDescriptionLabel()
		self.AuthorNameLabel = self:AddDescriptionLabel()
		self.ModeLabel = self:AddDescriptionLabel()
		self.TeamsLabel = self:AddDescriptionLabel()
		self.FriendlyFireLabel = self:AddDescriptionLabel()
		self.PointLimitLabel = self:AddDescriptionLabel()
		self.TimeLimitLabel = self:AddDescriptionLabel()
		self.DamageScaleLabel = self:AddDescriptionLabel()
		self.ModifierLabel = self:AddDescriptionLabel()
			self.ModifierLabel:SetFont("Scav_MenuLarge")
			self.ModifierLabel.ForcedY = 48
			self.ModifierLabel:SetWrap(true)
		--self.MapLabelBar = vgui.Create("DVerticalDivider", self)
		--	self.MapLabelBar:SetPos(0, self.MapLabel.y + self.MapLabel:GetTall())
		self.VoteButton = vgui.Create("DButton", self)
		self.VoteButton:SetFont("Scav_HUDNumber5")
		self.VoteButton:SetText("#scav.vote.button")
		self.VoteButton.DoClick = votebuttonpress
			--buttons/button5.wav
		--self.initialized = true
	end
	
	function PANEL:AddDescriptionLabel()
		local index = table.insert(self.DescriptionLabels, vgui.Create("SDM_VoteMenuDescLabel", self))
			self.DescriptionLabels[index]:SetDesc("")
			self.DescriptionLabels[index]:SetVisible(false)
			self.DescriptionLabels[index]:SetFont("Scav_HUDNumber")
		return self.DescriptionLabels[index]
	end
	
	function PANEL:DescriptionLabelSetText(label, text)
		label.text = text
		label:SetText(text)
	end
	
	function PANEL:DoSetup()
		self.VoteButton:SetPos(32, self:GetTall() - 52)
		self.VoteButton:SetSize(self:GetWide() - 64, 48)
		self.MapBG:SetPos(0, 0)
		self.MapBG:SetSize(self:GetWide(), self:GetTall())
		local accumulatedy = 0
		for k, v in ipairs(self.DescriptionLabels) do
			if v:GetDesc() ~= "" then
				v:SetPos(self.MapIcon.x, self.MapIcon.y + self.MapIcon:GetTall() + 16 + accumulatedy)
				if not v.ForcedY then
					v:SizeToContents()
				else
					v:SetSize(self:GetWide() - 64, v.ForcedY)
				end
				v:SetVisible(true)
				accumulatedy = accumulatedy + math.Max(24, v:GetTall())
			else
				v:SetVisible(false)
			end
		end

	end
	
	function PANEL:InvalidateLayout()

		--self.MapLabelBar:SetSize(self:GetWide(), 4)
	end

	local modetranslate = {
		["deathmatch"]		= "scav.mode.dm",
		["team_deathmatch"]	= "scav.mode.tdm",
		["ctf"] 			= "scav.mode.ctf",
		["cell_control"] 	= "scav.mode.cell",
		["hoard"] 			= "scav.mode.hoard",
		["survival"] 		= "scav.mode.survive",
		["capture"]			= "scav.mode.cap",
		["custom"]			= "scav.mode.custom"
	}
	
	function PANEL:SetMap(mapname, settingsfile)
		local mapicon = Material("maps/thumb/" .. mapname .. ".png", "ignorez smooth 1")
		if mapicon:IsError() then mapicon = Material("vgui/nomapicon") end
		self.MapIcon:SetMaterial(mapicon)
		self.MapBG:SetMaterial(mapicon)

		self.MapLabel:SetText(ScavLocalize("scav.config.title", false, mapname, false, string.gsub(settingsfile, "%.txt", "")))
		self.MapLabel:SizeToContents()
		self.FileName = mapname .. "/" .. settingsfile
		--print(self.FileName)
		local mapinfo = ScavData.AllSettingsFiles[mapname .. "/" .. settingsfile]
		if mapinfo then
			self.infovalid = true
			--Setting Name
			local sname = mapinfo:GetName()
			self.SettingNameLabel:SetDesc((sname and sname ~= "") and sname or "#scav.config.unknown")
			--Author Name
			local author = mapinfo:GetAuthor()
			local anon = (not author or author == "")
			self.AuthorNameLabel:SetDesc(ScavLocalize("scav.config.author", anon, anon and "scav.config.author.anon" or author))
			--mode
			self.ModeLabel:SetDesc(ScavLocalize("scav.config.mode", modetranslate[mapinfo:GetMode()]))
			--teams
			if mapinfo:GetMaxTeams() == 0 then
				self.TeamsLabel:SetDesc("")
				self.FriendlyFireLabel:SetDesc("")
			else
				self.TeamsLabel:SetDesc(ScavLocalize("scav.config.teams", mapinfo:GetMaxTeams()))
				self.FriendlyFireLabel:SetDesc(ScavLocalize("scav.config.friendlyfire", "scav.config." .. tostring(mapinfo:GetFriendlyFire())))
			end
			--point limit
			local plimit = mapinfo:GetPointLimit()
			self.PointLimitLabel:SetDesc(ScavLocalize("scav.config.limit.points", plimit == 0 and "scav.config.0" or plimit))
			--time limit
			local tlimit = mapinfo:GetTimeLimit()
			self.TimeLimitLabel:SetDesc(ScavLocalize("scav.config.limit.time", tlimit == 0 and "scav.config.0" or string.FormattedTime(tlimit, ScavLocalize("scav.score.time.format"))))
			
			--Damage Scale
			local dscale = mapinfo:GetDamageScale()
			self.DamageScaleLabel:SetDesc(dscale == 1 and "" or ScavLocalize("scav.config.scale.damage", false, dscale))
			--Mods
			local modlist = mapinfo:GetModString()
			if modlist == "" then
				self.ModifierLabel:SetDesc("")
			else
				local tab = string.Explode(", ", modlist)
				for k, v in ipairs(tab) do
					tab[k] = ScavLocalize("scav.config.mod." .. v)
				end
				modlist = table.concat(tab, ScavLocalize("scav.config.mods.sep"))
				self.ModifierLabel:SetDesc(ScavLocalize("scav.config.mods", false, modlist))
			end
		else
			self.infovalid = false
			self.waitingmapname = mapname
			self.waitingsettingsname = settingsfile
			for _, v in ipairs(self.DescriptionLabels) do
				v:SetDesc("")
			end
		end
		self:DoSetup()
	end
	
	function PANEL:Think()
		if not self.infovalid then
			self:SetMap(self.waitingmapname, self.waitingsettingsname)
		end
	end
	
	function PANEL:Close()
		self:Remove()
		gui.EnableScreenClicker(false)
	end
	
	vgui.Register("SDM_VoteMenuSettingInfo", PANEL, "DPanel")

SDM_VOTEMENU = NULL

concommand.Add("sdm_vote", function(pl, cmd, args)
	RunConsoleCommand("sdm_vote_requestfiles")
	if SDM_VOTEMENU:IsValid() then return end
	
	local votemenu = vgui.Create("SDM_VoteMenu")
	votemenu:SetSkin("sg_menu")
	votemenu:AutoSetup()
	SDM_VOTEMENU = votemenu
end)

concommand.Add("sdm_vote_close", function(pl, cmd, args)
	if SDM_VOTEMENU:IsValid() then
		SDM_VOTEMENU:Close()
	end
end)
